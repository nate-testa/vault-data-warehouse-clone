"""
Broker Goal Loader

This module reads broker goal data from an Excel file stored in Azure Blob Storage
and loads it into the vault_edw.edw_stage.stage_broker_goal SQL Server table.
"""

import logging
import sys
import pandas as pd
from datetime import datetime
from io import BytesIO
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL, Engine
from airflow.providers.microsoft.azure.hooks.wasb import WasbHook
from config_manager import ConfigManager

def setup_logger() -> logging.Logger:
    """
    Configures and returns a logger instance.

    This setup splits logging streams:
    - INFO and DEBUG messages are sent to sys.stdout (standard output).
    - WARNING, ERROR, and CRITICAL messages are sent to sys.stderr (standard error).
    """
    logger = logging.getLogger("BrokerGoalLoader")
    if not logger.handlers:
        logger.setLevel(logging.INFO)

        formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )

        class InfoFilter(logging.Filter):
            """Filters log records to allow only those below WARNING level."""
            def filter(self, record):
                return record.levelno < logging.WARNING

        stdout_handler = logging.StreamHandler(sys.stdout)
        stdout_handler.setLevel(logging.INFO)
        stdout_handler.setFormatter(formatter)
        stdout_handler.addFilter(InfoFilter())

        stderr_handler = logging.StreamHandler(sys.stderr)
        stderr_handler.setLevel(logging.WARNING)
        stderr_handler.setFormatter(formatter)

        logger.addHandler(stdout_handler)
        logger.addHandler(stderr_handler)

    return logger


class BrokerGoalLoader:
    """
    Loads broker goal data from Azure Blob Storage Excel file into SQL Server.
    """
    
    def __init__(self):
        """Initializes the loader by setting up the logger and loading configuration."""
        self.logger = setup_logger()
        self.logger.info("Initializing configuration from Azure Key Vault...")
        
        # Load all secrets from Key Vault
        self.config_manager = ConfigManager(logger=self.logger)
        
        # Initialize connection engine as None
        self.sql_engine: Engine | None = None
        
        # Store the processed blob name for archiving
        self.processed_blob_name: str | None = None
        
    def __enter__(self):
        """
        Context manager entry point.
        Establishes database connection.
        """
        self.logger.info("Establishing database connection...")
        sql_config = self.config_manager.get_sql_config()
        self.sql_engine = self._connect_sql_server(sql_config)
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        """
        Context manager exit point.
        Ensures database connection is gracefully closed.
        """
        if self.sql_engine:
            self.sql_engine.dispose()
            self.logger.info("SQL Server connection closed.")

    def _parse_currency(self, value) -> float | None:
        """
        Parse currency values handling both US and European formats.
        
        Args:
            value: Currency value (could be string, float, or numeric)
            
        Returns:
            Float value or None if parsing fails
            
        Examples:
            "$1,234.56" -> 1234.56
            "$5.300.000,00" -> 5300000.00
            "1234,56" -> 1234.56
        """
        if pd.isna(value) or value == '':
            return None
        
        # If already numeric, return as float
        if isinstance(value, (int, float)):
            return float(value)
        
        value = str(value).strip()
        
        # Remove currency symbols
        value = value.replace('$', '').replace('€', '').replace('£', '').strip()
        
        # Detect format: European (1.234.567,89) vs US (1,234,567.89)
        if ',' in value and '.' in value:
            # Both present - determine which is decimal separator
            comma_pos = value.rfind(',')
            dot_pos = value.rfind('.')
            
            if comma_pos > dot_pos:  # European: 1.234,56
                value = value.replace('.', '').replace(',', '.')
            else:  # US: 1,234.56
                value = value.replace(',', '')
        elif ',' in value:
            # Only comma - could be thousands or decimal
            parts = value.split(',')
            if len(parts[-1]) == 2:  # Likely decimal: 1234,56
                value = value.replace(',', '.')
            else:  # Thousands: 1,234 or 1,234,567
                value = value.replace(',', '')
        
        try:
            parsed_value = float(value)
            return parsed_value
        except ValueError:
            self.logger.error(f"Failed to parse currency value: '{value}'")
            return None

    def _connect_sql_server(self, details: dict) -> Engine:
        """
        Creates and tests a SQLAlchemy Engine for SQL Server.

        Args:
            details: A dictionary containing connection parameters.

        Returns:
            A connected and tested SQLAlchemy Engine instance.
        """
        try:
            self.logger.info(f"Connecting to SQL Server: {details['server']}...")
            
            connection_url = URL.create(
                "mssql+pyodbc",
                username=details['username'],
                password=details['password'],
                host=details['server'],
                database=details['database'],
                query={"driver": "ODBC Driver 17 for SQL Server"}
            )
            
            engine = create_engine(connection_url)
            
            # Test the connection
            with engine.connect() as conn:
                conn.execute(text("SELECT 1"))
                
            self.logger.info("Successfully connected to SQL Server.")
            return engine
        
        except Exception as e:
            self.logger.error(f"Failed to connect to SQL Server: {e}")
            raise

    def _get_excel_from_blob(self) -> BytesIO:
        """
        Downloads the Excel file from Azure Blob Storage using Airflow WasbHook.
        Same method as TEST 2 in test_broker_goal_blob.py

        Returns:
            BytesIO object containing the Excel file data.
        """
        try:
            self.logger.info("Connecting to Azure Blob Storage via Airflow WasbHook...")
            
            # Use same connection as NFP project and TEST 2
            wasb_conn_id = 'azure_blob_storage'
            
            # Create WasbHook
            wasb_hook = WasbHook(wasb_conn_id=wasb_conn_id)
            
            # Get blob service client
            blob_service_client = wasb_hook.get_conn()
            
            self.logger.info(f"Connected to storage account: {blob_service_client.account_name}")
            
            container_name = self.config_manager.get_blob_container()
            
            # Get container client
            container_client = blob_service_client.get_container_client(container_name)
            
            folder_name = self.config_manager.get_blob_folder()
            
            # List blobs in the folder to find the Excel file
            self.logger.info(f"Searching for Excel files in {container_name}/{folder_name}...")
            blobs = container_client.list_blobs(name_starts_with=folder_name)
            
            excel_files = []
            non_excel_files = []
            
            for blob in blobs:
                # Skip if it's just the folder itself
                if blob.name == folder_name or blob.name == folder_name + '/':
                    continue
                    
                if blob.name.endswith('.xlsx') or blob.name.endswith('.xls'):
                    excel_files.append(blob.name)
                else:
                    non_excel_files.append(blob.name)
            
            # Warn about non-Excel files
            if non_excel_files:
                self.logger.warning(f"Found {len(non_excel_files)} non-Excel file(s) in folder (will be ignored):")
                for file in non_excel_files:
                    self.logger.warning(f"  - {file}")
            
            if not excel_files:
                raise FileNotFoundError(f"No Excel file (.xlsx or .xls) found in {container_name}/{folder_name}")
            
            if len(excel_files) > 1:
                self.logger.warning(f"Found {len(excel_files)} Excel files, using the first one:")
                for file in excel_files:
                    self.logger.warning(f"  - {file}")
            
            excel_blob = excel_files[0]
            self.logger.info(f"Selected Excel file: {excel_blob}")
            
            # Store the blob name for potential archiving
            self.processed_blob_name = excel_blob
            
            # Download the blob
            blob_client = blob_service_client.get_blob_client(container=container_name, blob=excel_blob)
            download_stream = blob_client.download_blob()
            excel_data = BytesIO(download_stream.readall())
            
            self.logger.info("Successfully downloaded Excel file from Blob Storage.")
            return excel_data
            
        except Exception as e:
            self.logger.error(f"Failed to download Excel file from Blob Storage: {e}")
            raise

    def _read_excel_data(self, excel_data: BytesIO, goal_year: int) -> pd.DataFrame:
        """
        Reads the Excel file and extracts broker goal data.

        Args:
            excel_data: BytesIO object containing the Excel file.
            goal_year: The year for the budget sheet.

        Returns:
            DataFrame with the processed broker goal data.
        """
        try:
            sheet_name = f"{goal_year} Budget"
            self.logger.info(f"Reading sheet: {sheet_name}")
            
            df = pd.read_excel(excel_data, sheet_name=sheet_name, engine='openpyxl')
            
            self.logger.info(f"Read {len(df)} rows from Excel file")
            self.logger.info(f"Columns found: {list(df.columns)}")
            
            # Column mapping: Excel column name -> Database column name
            COLUMN_MAPPING = {
                'Agency Code': 'broker_id',
                'Agency Name': 'broker_nm',
                'HO New Business': 'ho_new_business_premium_amt'
            }
            
            # Flexible column name matching (handle year suffix like "2026 HO New Business")
            actual_columns = {}
            for excel_col_base, db_col in COLUMN_MAPPING.items():
                # Try exact match first
                if excel_col_base in df.columns:
                    actual_columns[db_col] = excel_col_base
                else:
                    # Try fuzzy match (e.g., "2026 HO New Business" matches "HO New Business")
                    matched = [col for col in df.columns if excel_col_base in col]
                    if matched:
                        actual_columns[db_col] = matched[0]
                        self.logger.info(f"Matched '{excel_col_base}' to column '{matched[0]}'")
            
            # Validate required columns exist
            missing_cols = [k for k, v in COLUMN_MAPPING.items() if v not in actual_columns]
            if missing_cols:
                raise ValueError(f"Missing required columns: {missing_cols}. Available columns: {list(df.columns)}")
            
            # Create result DataFrame with mapped columns
            result_df = pd.DataFrame()
            
            # Map broker_id (convert float to int to string to remove .0)
            result_df['broker_id'] = df[actual_columns['broker_id']].apply(lambda x: str(int(float(x))) if pd.notna(x) else '')
            
            # Map broker_nm (as string)
            result_df['broker_nm'] = df[actual_columns['broker_nm']].astype(str)
            
            # Add goal_year (MUST come before ho_new_business_premium_amt to match table schema)
            result_df['goal_year'] = goal_year
            
            # Map and parse premium amount using robust currency parser
            result_df['ho_new_business_premium_amt'] = df[actual_columns['ho_new_business_premium_amt']].apply(self._parse_currency)
            
            # Add timestamp metadata fields
            result_df['create_ts'] = datetime.now()
            result_df['update_ts'] = datetime.now()
            
            self.logger.info(f"Mapped {len(result_df)} rows from Excel")
            
            return result_df
            
        except Exception as e:
            self.logger.error(f"Failed to read Excel data: {e}")
            raise

    def _validate_data(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Validate data quality and remove/log invalid rows.
        
        Args:
            df: DataFrame to validate
            
        Returns:
            Validated DataFrame with invalid rows removed
        """
        try:
            initial_count = len(df)
            self.logger.info(f"Validating {initial_count} rows...")
            
            # Remove rows with empty broker_id
            df = df[df['broker_id'].notna() & (df['broker_id'] != '') & (df['broker_id'] != 'nan')]
            removed_broker_id = initial_count - len(df)
            if removed_broker_id > 0:
                self.logger.warning(f"Removed {removed_broker_id} rows with missing/invalid broker_id")
            
            # Remove rows with empty broker_nm
            current_count = len(df)
            df = df[df['broker_nm'].notna() & (df['broker_nm'] != '') & (df['broker_nm'] != 'nan')]
            removed_broker_nm = current_count - len(df)
            if removed_broker_nm > 0:
                self.logger.warning(f"Removed {removed_broker_nm} rows with missing/invalid broker_nm")
            
            # Validate premium amounts
            current_count = len(df)
            invalid_premium = df[
                (df['ho_new_business_premium_amt'].isna()) |
                (df['ho_new_business_premium_amt'] < 0) |
                (df['ho_new_business_premium_amt'] > 1_000_000_000)  # 1 billion threshold
            ]
            
            if len(invalid_premium) > 0:
                self.logger.warning(f"Found {len(invalid_premium)} rows with invalid premium amounts (null, negative, or > $1B)")
                
                if self.config_manager.should_skip_invalid_rows():
                    df = df[~df.index.isin(invalid_premium.index)]
                    self.logger.warning(f"Skipped {len(invalid_premium)} rows with invalid premium amounts")
                else:
                    self.logger.error("Invalid premium amounts found and skip_invalid_rows=false")
                    raise ValueError(f"Found {len(invalid_premium)} rows with invalid premium amounts")
            
            removed_total = initial_count - len(df)
            if removed_total > 0:
                self.logger.warning(f"⚠️  Removed {removed_total} invalid rows ({initial_count} -> {len(df)})")
            
            self.logger.info(f"✓ Validated {len(df)} rows successfully")
            return df
            
        except Exception as e:
            self.logger.error(f"Data validation failed: {e}")
            raise

    def _load_to_sql(self, df: pd.DataFrame):
        """
        Loads the DataFrame into the SQL Server table.

        Args:
            df: DataFrame containing the broker goal data to load.
        """
        try:
            if self.sql_engine is None:
                raise RuntimeError("Database engine not initialized. Use context manager.")
            
            schema = self.config_manager.get_target_schema()
            table = self.config_manager.get_target_table()
            load_mode = self.config_manager.get_load_mode()
            
            self.logger.info(f"Loading {len(df)} records into {schema}.{table}...")
            self.logger.info(f"Load mode: {load_mode.upper()}")
            
            # Truncate the table first if load_mode is 'truncate'
            if load_mode.lower() == 'truncate':
                with self.sql_engine.begin() as conn:
                    truncate_query = f"TRUNCATE TABLE {schema}.{table}"
                    self.logger.info(f"Executing: {truncate_query}")
                    conn.execute(text(truncate_query))
                    self.logger.info(f"Table {schema}.{table} truncated successfully")
            else:
                self.logger.info(f"Appending data to existing records in {schema}.{table}")
            
            # Ensure column order matches table schema exactly
            column_order = ['broker_id', 'broker_nm', 'goal_year', 'ho_new_business_premium_amt', 'create_ts', 'update_ts']
            df = df[column_order]
            
            # DEBUG: Log DataFrame structure before insertion
            self.logger.info(f"DataFrame shape: {df.shape}")
            self.logger.info(f"DataFrame columns: {list(df.columns)}")
            self.logger.info(f"DataFrame dtypes:\n{df.dtypes}")
            self.logger.info(f"Sample row:\n{df.iloc[0].to_dict()}")
            
            # Load the data (try without method='multi' first to see if that's the issue)
            df.to_sql(
                name=table,
                con=self.sql_engine,
                schema=schema,
                if_exists='append',
                index=False,
                method=None,  # Changed from 'multi' to None - single row inserts
                chunksize=100
            )
            
            self.logger.info(f"Successfully loaded {len(df)} records into {schema}.{table}")
            
        except Exception as e:
            self.logger.error(f"Failed to load data to SQL Server: {e}")
            raise

    def _archive_blob(self):
        """
        Archives the processed Excel file by moving it to the Archived folder.
        """
        try:
            archive_config = self.config_manager.get_archive_config()
            
            if not archive_config['enabled']:
                self.logger.info("Archive is disabled, skipping file archiving.")
                return
            
            if not self.processed_blob_name:
                self.logger.warning("No blob name stored for archiving.")
                return
            
            self.logger.info("Starting file archiving process...")
            
            # Use Airflow WasbHook (same as download)
            wasb_conn_id = 'azure_blob_storage'
            wasb_hook = WasbHook(wasb_conn_id=wasb_conn_id)
            blob_service_client = wasb_hook.get_conn()
            
            container_name = self.config_manager.get_blob_container()
            archive_folder = archive_config['folder']
            
            # Build destination blob name
            original_filename = self.processed_blob_name.split('/')[-1]
            
            if archive_config['add_timestamp']:
                # Add timestamp to filename: file.xlsx -> file_20260116_103025.xlsx
                timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
                name_parts = original_filename.rsplit('.', 1)
                if len(name_parts) == 2:
                    archived_filename = f"{name_parts[0]}_{timestamp}.{name_parts[1]}"
                else:
                    archived_filename = f"{original_filename}_{timestamp}"
            else:
                archived_filename = original_filename
            
            # Ensure archive folder path ends properly
            if not archive_folder.endswith('/'):
                archive_folder = archive_folder + '/'
            
            destination_blob_name = f"{archive_folder}{archived_filename}"
            
            # Get destination blob client
            dest_blob_client = blob_service_client.get_blob_client(
                container=container_name,
                blob=destination_blob_name
            )
            
            self.logger.info(f"Copying {self.processed_blob_name} to {destination_blob_name}...")
            
            # Copy the blob
            source_url = source_blob_client.url
            dest_blob_client.start_copy_from_url(source_url)
            
            # Wait for copy to complete (for small files this is usually instant)
            import time
            max_wait = 30  # seconds
            waited = 0
            while waited < max_wait:
                props = dest_blob_client.get_blob_properties()
                if props.copy.status == 'success':
                    break
                elif props.copy.status == 'failed':
                    raise Exception(f"Copy operation failed: {props.copy.status_description}")
                time.sleep(1)
                waited += 1
            
            self.logger.info(f"✓ File copied to archive folder")
            
            # Delete the original file
            self.logger.info(f"Deleting original file: {self.processed_blob_name}...")
            source_blob_client.delete_blob()
            self.logger.info(f"✓ Original file deleted")
            
            self.logger.info(f"File archived successfully: {destination_blob_name}")
            
        except Exception as e:
            self.logger.error(f"Failed to archive blob: {e}")
            self.logger.warning("Archiving failed, but data was loaded successfully.")
            # Don't raise the exception - archiving failure shouldn't fail the whole process

    def run(self):
        """
        Main execution method that orchestrates the entire process.
        """
        import time
        start_time = time.time()
        
        try:
            # Get year configuration
            year_config = self.config_manager.get_year_config()
            
            if year_config['auto_year']:
                goal_year = datetime.now().year
                self.logger.info(f"Using current year: {goal_year}")
            else:
                goal_year = year_config['year_override']
                self.logger.info(f"Using override year: {goal_year}")
            
            self.logger.info(f"Starting broker goal load process for year {goal_year}...")
            
            # Step 1: Download Excel from Blob Storage
            self.logger.info("Step 1/5: Downloading Excel file from Blob Storage...")
            excel_data = self._get_excel_from_blob()
            
            # Step 2: Read and process Excel data
            self.logger.info("Step 2/5: Reading and processing Excel data...")
            df = self._read_excel_data(excel_data, goal_year)
            
            # Step 3: Validate data quality
            self.logger.info("Step 3/5: Validating data quality...")
            if self.config_manager.should_validate_data():
                df = self._validate_data(df)
            else:
                self.logger.warning("Data validation is disabled in config")
            
            # Step 4: Load data to SQL Server (Critical section)
            self.logger.info("Step 4/5: Loading data to SQL Server...")
            self._load_to_sql(df)
            self.logger.info("✓ Data committed to database")
            
            # Step 5: Archive the processed file (Non-critical section)
            self.logger.info("Step 5/5: Archiving processed file...")
            try:
                self._archive_blob()
            except Exception as e:
                self.logger.error(f"Archive failed: {e}")
                self.logger.warning("⚠️  Data was loaded successfully, but archiving failed")
                # Don't re-raise - archiving is non-critical
            
            elapsed = time.time() - start_time
            self.logger.info(f"✓ Broker goal load process completed successfully in {elapsed:.2f} seconds!")
            
        except Exception as e:
            elapsed = time.time() - start_time
            self.logger.error(f"✗ Broker goal load process failed after {elapsed:.2f} seconds: {e}")
            raise
