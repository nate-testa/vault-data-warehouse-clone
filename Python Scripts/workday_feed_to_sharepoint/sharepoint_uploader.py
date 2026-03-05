import datetime
import pandas as pd
import asyncio
import pyodbc
import os
import tempfile
import psutil
import numpy as np
from io import BytesIO
from azure.identity import ClientSecretCredential
from msgraph import GraphServiceClient
from queries import QUERIES

class SharePointUploader:
    def __init__(self, config_manager, logger):
        self.cfg = config_manager
        self.logger = logger
        
        # SharePoint Config from config.yml
        sharepoint_config = self.cfg.config.get('sharepoint', {})
        self.site_hostname = sharepoint_config.get('site_hostname', 'vaultinsurance.sharepoint.com')
        self.site_path = sharepoint_config.get('site_path', '/sites/IT')
        self.site_url = f'https://{self.site_hostname}{self.site_path}'
        
        # Determine folder path based on environment
        # Priority: 1) .env file (ENVIRONMENT=...), 2) config.yml (environment.name), 3) default 'UAT'
        env_from_dotenv = os.getenv('ENVIRONMENT')
        env_from_config = self.cfg.config.get('environment', {}).get('name', 'UAT')
        
        if env_from_dotenv:
            environment = env_from_dotenv.upper()
            env_source = ".env file"
        else:
            environment = env_from_config.upper()
            env_source = "config.yml"
        
        # Get folder path from config based on environment
        folder_paths = sharepoint_config.get('folder_paths', {})
        env_key = environment.lower()
        
        if env_key == 'production':
            self.base_folder_path = folder_paths.get('production', 'Data Warehouse/Workday/Vault IT Data Files/00_Month-End')
            self.logger.info(f"Environment: {environment} (from {env_source}) → Using PRODUCTION folder path")
        else:
            # Use 'uat' for both UAT and DEV, or fallback to 'dev' if specified
            self.base_folder_path = folder_paths.get(env_key, folder_paths.get('uat', 'Data Warehouse/Workday/Vault IT Data Files/Test_Folder'))
            self.logger.info(f"Environment: {environment} (from {env_source}) → Using TEST folder path")
        
        self.logger.info(f"SharePoint folder: {self.base_folder_path}")
        
        # Memory optimization settings
        memory_config = self.cfg.config.get('memory', {})
        self.chunk_size = memory_config.get('chunk_size', 10000)
        self.processing_mode = memory_config.get('processing_mode', 'local_persist')
        self.local_output_dir = memory_config.get('local_output_dir', 'files')
        self.keep_on_failure = memory_config.get('keep_local_on_failure', True)
        self.keep_backup = memory_config.get('keep_local_backup', False)
        
        # Migration/record limit settings
        migration_config = self.cfg.config.get('migration', {})
        self.load_all = migration_config.get('load_all', True)
        self.record_limit = migration_config.get('record_limit', 10000)
        self.use_date_filter = migration_config.get('use_date_filter', True)
        
        # Create local output directory if using local_persist mode
        if self.processing_mode == 'local_persist':
            script_dir = os.path.dirname(os.path.abspath(__file__))
            self.local_dir = os.path.join(script_dir, self.local_output_dir)
            os.makedirs(self.local_dir, exist_ok=True)
            self.logger.info(f"Local output directory: {self.local_dir}")
        
        self.logger.info(f"Processing mode: {self.processing_mode}, chunk_size={self.chunk_size}")
        if not self.load_all:
            self.logger.info(f"Record limiting enabled: {self.record_limit} rows per query")
        if not self.use_date_filter:
            self.logger.info(f"Date filtering DISABLED - will load all dates")
    
    def _init_results_tracking(self):
        """Initialize results tracking for summary report"""
        return {
            'successful': [],
            'failed': [],
            'total_rows': 0,
            'total_files': 0,
            'total_source_rows': 0  # Track source row count
        }

    def log_memory_usage(self, context=""):
        """Log current memory usage"""
        try:
            process = psutil.Process()
            mem_info = process.memory_info()
            mem_mb = mem_info.rss / 1024 / 1024
            self.logger.info(f"Memory usage {context}: {mem_mb:.2f} MB")
        except Exception as e:
            self.logger.debug(f"Could not get memory info: {e}")
    
    def format_dataframe(self, df, filename):
        """
        Format dataframe to match original template specifications:
        1. Convert float columns to int if they contain whole numbers
        2. Ensure date columns are in YYYY-MM-DD format
        """
        # Make a copy to avoid modifying the original
        df = df.copy()
        
        # Convert numeric columns that are whole numbers to integers
        # This removes the .0 suffix (e.g., 26.0 -> 26, -35.0 -> -35)
        for col in df.columns:
            if pd.api.types.is_float_dtype(df[col]):
                # Check if all non-null values are whole numbers
                if df[col].notna().any():
                    non_null = df[col].dropna()
                    if (non_null % 1 == 0).all():
                        # Convert to Int64 (nullable integer type)
                        df[col] = df[col].astype('Int64')
        
        # Ensure date columns are formatted as YYYY-MM-DD
        # TRANSACTION_TS is included here as it stores dates only (not datetime)
        date_columns = ['ACCOUNTING_DATE', 'TRANSACTION_DATE', 'EFFECTIVE_DATE', 'EXPIRATION_DATE',
                       'POLICYEFFECTIVEDATE', 'CLAIMLOSSDATE', 'CLAIMREPORTEDDATE', 'MONTHEND',
                       'CONTRIBCUTOFFDATE', 'SUBSCRIBER_CONTRIBUTION_END_DT', 'TRANSACTION_EFFECTIVE_DATE',
                       'TRANSACTION_TS']
        
        for col in date_columns:
            if col in df.columns:
                # Convert to datetime then format as YYYY-MM-DD
                df[col] = pd.to_datetime(df[col], errors='coerce').dt.strftime('%Y-%m-%d')
                # Replace 'NaT' string with empty string for null dates
                df[col] = df[col].replace('NaT', '')
        
        return df

    def get_target_path(self):
        """Calculates year/month folders based on date"""
        today = datetime.date.today()
        if today.day == 1:
            process = "Month_End"
            target_date = today.replace(day=1) - datetime.timedelta(days=1)
        else:
            process = "Preclose"
            target_date = today
            
        return target_date.strftime("%Y"), target_date.strftime("01 %b %Y"), process, "CSV"

    def run(self):
        """Main entry point - runs async workflow"""
        asyncio.run(self._run_async())
    
    async def _run_async(self):
        """Async workflow for Microsoft Graph API"""
        # 1. Authenticate with Microsoft Graph
        self.logger.info("Authenticating with Microsoft Graph...")
        credential = ClientSecretCredential(
            tenant_id=self.cfg.get('tenant_id'),
            client_id=self.cfg.get('sp_id'),
            client_secret=self.cfg.get('sp_secret')
        )
        graph_client = GraphServiceClient(credentials=credential)
        
        # 2. Get SharePoint Site
        self.logger.info("Connecting to SharePoint site...")
        site = await graph_client.sites.by_site_id(
            f"{self.site_hostname}:{self.site_path}"
        ).get()
        self.logger.info(f"Connected to site: {site.display_name}")
        
        # 3. Get Drive (Document Library)
        drive = await graph_client.sites.by_site_id(site.id).drive.get()
        self.logger.info(f"Using drive: {drive.name}")
        
        # 4. Build folder path
        folders = self.get_target_path()
        folder_path = f"{self.base_folder_path}/{'/'.join(folders)}"
        self.logger.info(f"Target folder path: {folder_path}")
        
        # 5. Connect to Database
        self.logger.info("Connecting to database...")
        db_user = self.cfg.get('db_user')
        db_password = self.cfg.get('db_password')
        db_server = self.cfg.get('db_server')
        db_name = self.cfg.get('db_name')
        
        # Log connection details (without password)
        self.logger.info(f"  Server: {db_server}")
        self.logger.info(f"  Database: {db_name}")
        self.logger.info(f"  User: {db_user}")
        
        # Direct pyodbc connection (same approach as successful test)
        conn_str = (
            f"DRIVER={{ODBC Driver 17 for SQL Server}};"
            f"SERVER={db_server};"
            f"DATABASE={db_name};"
            f"UID={db_user};"
            f"PWD={db_password};"
            f"Connection Timeout=30;"
        )
        
        try:
            conn = pyodbc.connect(conn_str)
            self.logger.info("  ✓ Database connection successful")
        except Exception as db_error:
            self.logger.error(f"  ✗ Database connection failed: {db_error}")
            self.logger.error(f"  Check:")
            self.logger.error(f"    1. Can this VM reach {db_server}?")
            self.logger.error(f"    2. Is SQL Server firewall allowing connections from this IP?")
            self.logger.error(f"    3. Are the credentials correct in Key Vault?")
            self.logger.error(f"    4. Is SQL Server configured for SQL authentication?")
            raise
        
        # 6. Process Queries and Upload
        results = self._init_results_tracking()
        
        try:
            for filename, sql in QUERIES.items():
                results['total_files'] += 1
                self.logger.info(f"Processing {filename}...")
                self.log_memory_usage(f"before {filename}")
                
                try:
                    # Choose processing mode and get row count
                    row_count = 0
                    source_row_count = 0
                    if self.processing_mode == 'local_persist':
                        row_count, source_row_count = await self._process_local_persist(conn, graph_client, drive.id, 
                                                         folder_path, filename, sql)
                    elif self.processing_mode == 'streaming':
                        row_count, source_row_count = await self._process_streaming(conn, graph_client, drive.id, 
                                                      folder_path, filename, sql)
                    elif self.processing_mode == 'in_memory':
                        row_count, source_row_count = await self._process_inmemory(conn, graph_client, drive.id,
                                                     folder_path, filename, sql)
                    else:
                        raise ValueError(f"Unknown processing_mode: {self.processing_mode}")
                    
                    # Track successful result
                    results['successful'].append({
                        'filename': filename,
                        'rows': row_count,
                        'source_rows': source_row_count
                    })
                    results['total_rows'] += row_count
                    results['total_source_rows'] += source_row_count
                    
                    self.log_memory_usage(f"after {filename}")
                    
                except Exception as e:
                    self.logger.error(f"  ✗ Failed {filename}: {e}")
                    import traceback
                    self.logger.error(traceback.format_exc())
                    
                    # Track failed result
                    results['failed'].append({
                        'filename': filename,
                        'error': str(e)
                    })
                    
                    # Continue with next file instead of stopping
                    continue
        finally:
            # Always close the connection
            conn.close()
            self.logger.info("Database connection closed")
            
            # Print summary report
            self._log_summary_report(results)
            
            # Generate HTML report for email
            self._generate_html_report(results)
    
    async def _process_local_persist(self, conn, graph_client, drive_id, folder_path, filename, sql):
        """
        Write file to local directory, upload to SharePoint, delete on success
        Best for: Reliability, resume capability, audit trail
        """
        local_file = os.path.join(self.local_dir, filename)
        
        # Apply record limit if configured
        sql = self._apply_record_limit(sql)
        
        # Log the query being used
        self.logger.info(f"  Query for {filename}:")
        for line in sql.strip().split('\n'):
            self.logger.info(f"    {line}")
        
        try:
            self.logger.info(f"  Writing to local file: {local_file}")
            
            # Read data in chunks and write to local file
            total_rows = 0
            first_chunk = True
            
            for chunk_num, chunk_df in enumerate(pd.read_sql(sql, conn, chunksize=self.chunk_size), 1):
                chunk_rows = len(chunk_df)
                total_rows += chunk_rows
                
                # Format the chunk to match template specifications
                chunk_df = self.format_dataframe(chunk_df, filename)
                
                # Write chunk to local CSV file
                mode = 'w' if first_chunk else 'a'
                chunk_df.to_csv(local_file, mode=mode, index=False, header=first_chunk)
                
                self.logger.info(f"  Chunk {chunk_num}: wrote {chunk_rows} rows (total: {total_rows})")
                first_chunk = False
                
                # Free memory
                del chunk_df
            
            self.logger.info(f"  ✓ Local file created: {total_rows} rows")
            
            # Upload to SharePoint
            self.logger.info(f"  Uploading to SharePoint...")
            with open(local_file, 'rb') as f:
                file_content = f.read()
            
            item_path = f"root:/{folder_path}/{filename}:"
            await graph_client.drives.by_drive_id(drive_id).items.by_drive_item_id(
                item_path
            ).content.put(file_content)
            
            self.logger.info(f"  ✓ Upload successful: {filename}")
            
            # Delete local file on successful upload (unless backup is enabled)
            if not self.keep_backup:
                os.remove(local_file)
                self.logger.info(f"  ✓ Local file deleted: {filename}")
            else:
                self.logger.info(f"  ℹ Local backup kept: {local_file}")
            
            # Return both written rows and source rows (they're the same in this case)
            return total_rows, total_rows
                
        except Exception as e:
            # Keep local file on failure if configured
            if self.keep_on_failure and os.path.exists(local_file):
                self.logger.warning(f"  ⚠ Upload failed, keeping local file: {local_file}")
                self.logger.warning(f"  You can manually upload or retry later")
            raise
    
    async def _process_streaming(self, conn, graph_client, drive_id, folder_path, filename, sql):
        """
        Write to temp file, upload, delete immediately
        Best for: Lowest memory, automatic cleanup
        """
        # Apply record limit if configured
        sql = self._apply_record_limit(sql)
        
        # Log the query being used
        self.logger.info(f"  Query for {filename}:")
        for line in sql.strip().split('\n'):
            self.logger.info(f"    {line}")
        
        temp_file = None
        try:
            # Create temporary file for CSV
            temp_fd, temp_file = tempfile.mkstemp(suffix='.csv', prefix='workday_')
            os.close(temp_fd)
            
            self.logger.info(f"  Using temp file: {temp_file}")
            
            # Read data in chunks and write to temp file
            total_rows = 0
            first_chunk = True
            
            for chunk_num, chunk_df in enumerate(pd.read_sql(sql, conn, chunksize=self.chunk_size), 1):
                chunk_rows = len(chunk_df)
                total_rows += chunk_rows
                
                # Format the chunk to match template specifications
                chunk_df = self.format_dataframe(chunk_df, filename)
                
                mode = 'w' if first_chunk else 'a'
                chunk_df.to_csv(temp_file, mode=mode, index=False, header=first_chunk)
                
                self.logger.info(f"  Chunk {chunk_num}: wrote {chunk_rows} rows (total: {total_rows})")
                first_chunk = False
                
                del chunk_df
            
            self.logger.info(f"  Total rows: {total_rows}")
            
            # Upload file to SharePoint
            with open(temp_file, 'rb') as f:
                file_content = f.read()
            
            item_path = f"root:/{folder_path}/{filename}:"
            await graph_client.drives.by_drive_id(drive_id).items.by_drive_item_id(
                item_path
            ).content.put(file_content)
            
            self.logger.info(f"  ✓ Uploaded {filename} ({total_rows} rows)")
            
            # Return both written rows and source rows (they're the same)
            return total_rows, total_rows
            
        finally:
            # Always clean up temp file
            if temp_file and os.path.exists(temp_file):
                try:
                    os.remove(temp_file)
                    self.logger.debug(f"  Cleaned up temp file")
                except Exception as e:
                    self.logger.warning(f"  Could not delete temp file: {e}")
    
    async def _process_inmemory(self, conn, graph_client, drive_id, folder_path, filename, sql):
        """
        Load all data into memory at once
        Best for: Speed (when sufficient memory available)
        """
        # Apply record limit if configured
        sql = self._apply_record_limit(sql)
        
        # Log the query being used
        self.logger.info(f"  Query for {filename}:")
        for line in sql.strip().split('\n'):
            self.logger.info(f"    {line}")
        
        # Query database using pyodbc connection
        df = pd.read_sql(sql, conn)
        self.logger.info(f"  Retrieved {len(df)} rows")
        
        # Format the dataframe to match template specifications
        df = self.format_dataframe(df, filename)
        
        # Convert to CSV
        buffer = BytesIO()
        df.to_csv(buffer, index=False)
        file_content = buffer.getvalue()
        
        # Upload to SharePoint using Microsoft Graph
        item_path = f"root:/{folder_path}/{filename}:"
        
        await graph_client.drives.by_drive_id(drive_id).items.by_drive_item_id(
            item_path
        ).content.put(file_content)
        
        self.logger.info(f"  ✓ Uploaded {filename}")
        
        # Return both written rows and source rows (they're the same)
        return len(df), len(df)
    
    def _log_summary_report(self, results):
        """Log summary report of all processing results"""
        self.logger.info("")
        self.logger.info("="*80)
        self.logger.info("PROCESSING SUMMARY REPORT")
        self.logger.info("="*80)
        
        # Success section
        if results['successful']:
            self.logger.info("")
            self.logger.info(f"✓ SUCCESSFUL ({len(results['successful'])} files):")
            self.logger.info("-" * 80)
            self.logger.info(f"{'Filename':<45} {'Source Rows':<15} {'Written Rows':<15} {'Status':<10}")
            self.logger.info("-" * 80)
            
            for item in results['successful']:
                source_rows = item.get('source_rows', item['rows'])
                written_rows = item['rows']
                match = "✓" if source_rows == written_rows else "⚠"
                self.logger.info(f"{item['filename']:<45} {source_rows:>10,} rows   {written_rows:>10,} rows   {match}")
            
            self.logger.info("-" * 80)
            self.logger.info(f"{'TOTAL SUCCESSFUL':<45} {results['total_source_rows']:>10,} rows   {results['total_rows']:>10,} rows")
        
        # Failed section
        if results['failed']:
            self.logger.info("")
            self.logger.info(f"✗ FAILED ({len(results['failed'])} files):")
            self.logger.info("-" * 80)
            self.logger.info(f"{'Filename':<50} {'Error':<30}")
            self.logger.info("-" * 80)
            
            for item in results['failed']:
                # Truncate error message to fit
                error_msg = item['error'][:60] + '...' if len(item['error']) > 60 else item['error']
                self.logger.info(f"{item['filename']:<50} {error_msg}")
        
        # Overall summary
        self.logger.info("")
        self.logger.info("="*80)
        success_count = len(results['successful'])
        failed_count = len(results['failed'])
        total_count = results['total_files']
        success_rate = (success_count / total_count * 100) if total_count > 0 else 0
        
        self.logger.info(f"Files Processed: {total_count}")
        self.logger.info(f"Successful: {success_count} ({success_rate:.1f}%)")
        self.logger.info(f"Failed: {failed_count}")
        self.logger.info(f"Total Records Extracted: {results['total_rows']:,}")
        self.logger.info("="*80)
        self.logger.info("")
    
    def _generate_html_report(self, results):
        """Generate HTML report for email notification"""
        try:
            # Calculate summary statistics
            success_count = len(results['successful'])
            failed_count = len(results['failed'])
            total_count = results['total_files']
            success_rate = (success_count / total_count * 100) if total_count > 0 else 0
            
            # Determine overall status
            if failed_count > 0:
                status_icon = "❌"
                status_text = "COMPLETED WITH ERRORS"
                status_color = "#B31B34"
            elif success_count == total_count:
                status_icon = "✅"
                status_text = "SUCCESS"
                status_color = "#28a745"
            else:
                status_icon = "⚠️"
                status_text = "COMPLETED WITH WARNINGS"
                status_color = "#ffc107"
            
            # Build successful files table
            successful_table_rows = ""
            if results['successful']:
                for item in results['successful']:
                    source_rows = item.get('source_rows', item['rows'])
                    written_rows = item['rows']
                    match_status = "✓" if source_rows == written_rows else "⚠"
                    match_color = "#28a745" if source_rows == written_rows else "#ffc107"
                    
                    successful_table_rows += f"""
                    <tr>
                        <td>{item['filename']}</td>
                        <td style="text-align: right;">{source_rows:,}</td>
                        <td style="text-align: right;">{written_rows:,}</td>
                        <td style="text-align: center; color: {match_color}; font-weight: bold;">{match_status}</td>
                    </tr>
                    """
            
            # Build failed files table
            failed_table_rows = ""
            if results['failed']:
                for item in results['failed']:
                    error_msg = item['error'][:100] + '...' if len(item['error']) > 100 else item['error']
                    failed_table_rows += f"""
                    <tr>
                        <td>{item['filename']}</td>
                        <td>{error_msg}</td>
                    </tr>
                    """
            
            # Generate HTML content
            html_content = f"""
            <html>
            <head>
                <style>
                    body {{
                        font-family: 'Segoe UI', Arial, sans-serif;
                        margin: 0;
                        padding: 20px;
                        background-color: #f5f5f5;
                    }}
                    .container {{
                        max-width: 900px;
                        margin: 0 auto;
                        background-color: white;
                        padding: 30px;
                        border-radius: 8px;
                        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
                    }}
                    .header {{
                        text-align: center;
                        margin-bottom: 30px;
                    }}
                    .logo {{
                        width: 150px;
                        height: auto;
                    }}
                    .status {{
                        font-size: 24px;
                        font-weight: bold;
                        color: {status_color};
                        margin: 20px 0;
                    }}
                    .summary {{
                        background-color: #f8f9fa;
                        padding: 20px;
                        border-radius: 6px;
                        margin: 20px 0;
                    }}
                    .summary-item {{
                        display: flex;
                        justify-content: space-between;
                        padding: 8px 0;
                        border-bottom: 1px solid #dee2e6;
                    }}
                    .summary-item:last-child {{
                        border-bottom: none;
                    }}
                    .summary-label {{
                        font-weight: 600;
                        color: #495057;
                    }}
                    .summary-value {{
                        color: #212529;
                    }}
                    table {{
                        width: 100%;
                        border-collapse: collapse;
                        margin: 20px 0;
                    }}
                    th {{
                        background-color: #B31B34;
                        color: white;
                        padding: 12px;
                        text-align: left;
                        font-weight: 600;
                    }}
                    td {{
                        padding: 10px;
                        border: 1px solid #ddd;
                    }}
                    tr:nth-child(even) {{
                        background-color: #f8f9fa;
                    }}
                    .section-title {{
                        font-size: 18px;
                        font-weight: bold;
                        color: #212529;
                        margin: 25px 0 15px 0;
                        padding-bottom: 8px;
                        border-bottom: 2px solid #B31B34;
                    }}
                    .footer {{
                        margin-top: 30px;
                        padding-top: 20px;
                        border-top: 1px solid #dee2e6;
                        color: #6c757d;
                        font-size: 12px;
                    }}
                    .error-section {{
                        background-color: #fff3cd;
                        border-left: 4px solid #ffc107;
                        padding: 15px;
                        margin: 20px 0;
                    }}
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="header">
                        <img src="https://d2j09jzq254cyj.cloudfront.net/vault-logo.png" alt="Vault" class="logo">
                        <div class="status">{status_icon} Workday Feed to SharePoint - {status_text}</div>
                    </div>
                    
                    <div class="summary">
                        <div class="summary-item">
                            <span class="summary-label">Total Files Processed:</span>
                            <span class="summary-value">{total_count}</span>
                        </div>
                        <div class="summary-item">
                            <span class="summary-label">Successful:</span>
                            <span class="summary-value" style="color: #28a745;">{success_count} ({success_rate:.1f}%)</span>
                        </div>
                        <div class="summary-item">
                            <span class="summary-label">Failed:</span>
                            <span class="summary-value" style="color: #dc3545;">{failed_count}</span>
                        </div>
                        <div class="summary-item">
                            <span class="summary-label">Total Source Rows:</span>
                            <span class="summary-value">{results['total_source_rows']:,}</span>
                        </div>
                        <div class="summary-item">
                            <span class="summary-label">Total Rows Written:</span>
                            <span class="summary-value">{results['total_rows']:,}</span>
                        </div>
                    </div>
            """
            
            # Add successful files section
            if results['successful']:
                html_content += f"""
                    <div class="section-title">✓ Successful Files ({success_count})</div>
                    <table>
                        <thead>
                            <tr>
                                <th>Filename</th>
                                <th style="text-align: right;">Source Rows</th>
                                <th style="text-align: right;">Written Rows</th>
                                <th style="text-align: center;">Match</th>
                            </tr>
                        </thead>
                        <tbody>
                            {successful_table_rows}
                        </tbody>
                    </table>
                """
            
            # Add failed files section
            if results['failed']:
                html_content += f"""
                    <div class="error-section">
                        <div class="section-title">✗ Failed Files ({failed_count})</div>
                        <table>
                            <thead>
                                <tr>
                                    <th>Filename</th>
                                    <th>Error</th>
                                </tr>
                            </thead>
                            <tbody>
                                {failed_table_rows}
                            </tbody>
                        </table>
                    </div>
                """
            
            # Add footer
            html_content += """
                    <div class="footer">
                        <p><strong>Vault Data Team</strong></p>
                        <p>This is an auto-generated message. If you have any questions, please reach out to 
                        <a href="mailto:itdatateam@vault.insurance">itdatateam@vault.insurance</a></p>
                        <p>For issues please contact <a href="https://vsc.vaultinsurance.com">Vault Solution Center</a></p>
                    </div>
                </div>
            </body>
            </html>
            """
            
            # Save to logs directory
            script_dir = os.path.dirname(os.path.abspath(__file__))
            logs_dir = os.path.join(script_dir, 'logs')
            report_path = os.path.join(logs_dir, 'latest_execution_report.html')
            
            with open(report_path, 'w', encoding='utf-8') as f:
                f.write(html_content)
            
            self.logger.info(f"HTML report generated: {report_path}")
            
        except Exception as e:
            self.logger.error(f"Failed to generate HTML report: {e}")
            import traceback
            self.logger.error(traceback.format_exc())
    
    def _apply_record_limit(self, sql):
        """
        Apply record limit to SQL query if load_all is False
        Wraps the query with a TOP clause for SQL Server
        """
        if not self.load_all and self.record_limit > 0:
            # Wrap the existing query with SELECT TOP
            limited_sql = f"""
            SELECT TOP {self.record_limit} *
            FROM (
                {sql.strip()}
            ) AS limited_query
            """
            self.logger.info(f"  Record limit applied: TOP {self.record_limit} rows")
            return limited_sql
        return sql