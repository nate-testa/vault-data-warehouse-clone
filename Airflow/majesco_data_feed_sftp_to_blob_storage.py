"""
Majesco SFTP to Azure Blob Storage
This module downloads CSV files from an SFTP server and loads them into Azure Blob Storage
"""

import os
import tempfile
import logging
from datetime import datetime, timezone
from airflow.providers.sftp.hooks.sftp import SFTPHook
from airflow.providers.microsoft.azure.hooks.wasb import WasbHook
from tetl_control_logger import get_last_source_extract_ts, update_tetl_control_table


# Configuration
SFTP_CONN_ID = "Vault_Majesco_sftp"
AZURE_CONN_ID = "azure_blob_storage"
SFTP_REMOTE_PATH = "/ftp/Report/Outbound/"
AZURE_CONTAINER = "inbound-majesco-billing-data-feed"
AZURE_FOLDER = "Raw"
MSSQL_CONN_ID = 'Vault_EDW'

# File patterns to download
FILE_PATTERNS = ["INSTALLMENT*.csv", "INVOICE*.csv", "NOTES*.csv", "OUTPUT*.csv", "PAYMENT*.csv", "TRANSACTION*.csv"]

# Logger
logger = logging.getLogger(__name__)

# Process name for tetl_control table
PROCESS_NAME = "py_majesco_data_feed_sftp_to_blob_storage"


def get_matching_files_from_sftp(sftp_hook, remote_path, patterns, last_extract_ts=None):
    """
    Gets the list of files in SFTP that match the specified patterns with their modification times
    
    Args:
        sftp_hook: SFTP Hook
        remote_path: Remote path in SFTP
        patterns: List of file patterns (e.g.: ["file1*.csv", "file2*.csv"])
        last_extract_ts: datetime object to filter files modified after this timestamp
    
    Returns:
        List of tuples (filename, modification_time) sorted by modification time (oldest first)
    """
    try:
        logger.info(f"Listing files in {remote_path}")
        
        # Get SFTP connection
        sftp_client = sftp_hook.get_conn()
        all_files = sftp_hook.list_directory(remote_path)
        logger.info(f"Files found in SFTP: {len(all_files)}")
        
        matching_files_with_mtime = []
        for pattern in patterns:
            # Convert wildcard pattern to filter
            prefix = pattern.replace("*.csv", "")
            for file in all_files:
                if file.startswith(prefix) and file.endswith(".csv"):
                    # Get file attributes including modification time
                    remote_filepath = os.path.join(remote_path, file)
                    file_attr = sftp_client.stat(remote_filepath)
                    mod_time = datetime.fromtimestamp(file_attr.st_mtime, tz=timezone.utc)
                    
                    # Filter by last_extract_ts if provided
                    if last_extract_ts is None or mod_time > last_extract_ts:
                        matching_files_with_mtime.append((file, mod_time))
                        logger.info(f"File {file} - modification time: {mod_time}")
                    else:
                        logger.info(f"File {file} - skipped (modification time {mod_time} <= last extract {last_extract_ts})")
        
        # Sort by modification time (oldest first)
        matching_files_with_mtime.sort(key=lambda x: x[1])
        
        logger.info(f"Files matching patterns and filters: {len(matching_files_with_mtime)}")
        return matching_files_with_mtime
        
    except Exception as e:
        logger.error(f"Error listing files in SFTP: {str(e)}")
        raise


def download_file_from_sftp(sftp_hook, remote_path, filename, local_path):
    """
    Downloads a file from SFTP to a temporary local directory
    
    Args:
        sftp_hook: SFTP Hook
        remote_path: Remote path in SFTP
        filename: Name of the file to download
        local_path: Local path where to save the file
    
    Returns:
        Full path of the downloaded file
    """
    try:
        remote_filepath = os.path.join(remote_path, filename)
        local_filepath = os.path.join(local_path, filename)
        
        logger.info(f"Downloading {remote_filepath} to {local_filepath}")
        sftp_hook.retrieve_file(remote_filepath, local_filepath)
        logger.info(f"File downloaded successfully: {filename}")
        
        return local_filepath
        
    except Exception as e:
        logger.error(f"Error downloading file {filename}: {str(e)}")
        raise


def upload_file_to_azure(azure_hook, container_name, blob_name, local_filepath):
    """
    Uploads a file to Azure Blob Storage
    
    Args:
        azure_hook: Azure Hook
        container_name: Name of the container in Azure
        blob_name: Name of the blob (full path in Azure)
        local_filepath: Local path of the file to upload
    
    Returns:
        True if upload was successful
    """
    try:
        logger.info(f"Uploading {local_filepath} to Azure: {container_name}/{blob_name}")
        
        azure_hook.load_file(
            file_path=local_filepath,
            container_name=container_name,
            blob_name=blob_name
        )
        
        logger.info(f"File uploaded successfully to Azure: {blob_name}")
        return True
        
    except Exception as e:
        logger.error(f"Error uploading file to Azure {blob_name}: {str(e)}")
        raise


def process_sftp_majesco_files():
    """
    Main function that executes the complete process:
    1. Get last extract timestamp from tetl_control
    2. Connect to SFTP
    3. Download files matching the patterns and modified after last extract
    4. Upload files to Azure Blob Storage (ordered by modification time)
    5. Update tetl_control table if at least one file was processed
    """
    # Get last extract timestamp
    logger.info(f"Getting last extract timestamp for process: {PROCESS_NAME}")
    last_extract_ts = get_last_source_extract_ts(PROCESS_NAME)
    logger.info(f"Last extract timestamp: {last_extract_ts}")
    
    # Create temporary directory for downloaded files
    with tempfile.TemporaryDirectory() as temp_dir:
        logger.info(f"Temporary directory created: {temp_dir}")
        
        try:
            # Connect to SFTP
            logger.info(f"Connecting to SFTP with connection: {SFTP_CONN_ID}")
            sftp_hook = SFTPHook(ftp_conn_id=SFTP_CONN_ID)
            
            # Connect to Azure
            logger.info(f"Connecting to Azure with connection: {AZURE_CONN_ID}")
            azure_hook = WasbHook(wasb_conn_id=AZURE_CONN_ID)
            
            # Get list of files matching the patterns with modification times
            # Files are returned sorted by modification time (oldest first) and filtered by last_extract_ts
            matching_files_with_mtime = get_matching_files_from_sftp(
                sftp_hook, 
                SFTP_REMOTE_PATH, 
                FILE_PATTERNS,
                last_extract_ts
            )
            
            if not matching_files_with_mtime:
                logger.warning("No files found matching the specified patterns and filters")
                return
            
            logger.info(f"Will process {len(matching_files_with_mtime)} files (ordered from oldest to newest)")
            
            # Process each file
            files_processed = 0
            files_failed = 0
            last_processed_mod_time = None
            
            for filename, mod_time in matching_files_with_mtime:
                try:
                    logger.info(f"Processing file: {filename} (modification time: {mod_time})")
                    
                    # Download file from SFTP
                    local_filepath = download_file_from_sftp(
                        sftp_hook,
                        SFTP_REMOTE_PATH,
                        filename,
                        temp_dir
                    )
                    
                    # Generate blob name in Azure (includes Raw folder)
                    blob_name = f"{AZURE_FOLDER}/{filename}"
                    
                    # Upload file to Azure
                    upload_file_to_azure(
                        azure_hook,
                        AZURE_CONTAINER,
                        blob_name,
                        local_filepath
                    )
                    
                    files_processed += 1
                    last_processed_mod_time = mod_time
                    logger.info(f"File processed successfully: {filename}")
                    
                except Exception as e:
                    files_failed += 1
                    logger.error(f"Error processing file {filename}: {str(e)}")
                    # Continue with next file
                    continue
            
            # Update tetl_control table only if at least one file was processed
            if files_processed > 0 and last_processed_mod_time:
                logger.info(f"Updating tetl_control table with last processed modification time: {last_processed_mod_time}")
                # Convert to string format for the update function
                last_source_extract_ts_str = last_processed_mod_time.strftime('%Y-%m-%d %H:%M:%S')
                update_tetl_control_table(PROCESS_NAME, last_source_extract_ts_str)
                logger.info("tetl_control table updated successfully")
            else:
                logger.info("No files were processed successfully, tetl_control table will not be updated")
            
            # Final summary
            logger.info("=" * 60)
            logger.info(f"PROCESSING SUMMARY")
            logger.info(f"Total files found: {len(matching_files_with_mtime)}")
            logger.info(f"Files processed successfully: {files_processed}")
            logger.info(f"Files with errors: {files_failed}")
            logger.info("=" * 60)
            
            if files_failed > 0:
                logger.warning(f"Process completed with {files_failed} errors")
            else:
                logger.info("Process completed successfully")
                
        except Exception as e:
            logger.error(f"Critical error in process: {str(e)}")
            raise


if __name__ == "__main__":
    # For local testing
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    process_sftp_majesco_files()



