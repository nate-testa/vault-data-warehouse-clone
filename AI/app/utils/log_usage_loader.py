"""
Usage Loader Script

This script reads usage tracking records from JSONL files and loads them
incrementally to Snowflake table {SNOWFLAKE_DATABASE}.APP_CONFIG.APP_USAGE_LOG.

It filters records by timestamp to avoid duplicates and performs batch inserts.

Usage:
    python -m app.utils.log_usage_loader

Cron job (runs every hour at minute 0):
    1. Edit crontab:
       crontab -e
    
    2. Add this line (adjust ENVIRONMENT UAT/PRODUCTION as needed):
       0 * * * * export ENVIRONMENT=PRODUCTION && cd ~/python_scripts/snowflake_ai && .venv/bin/python -m app.utils.log_usage_loader >> ~/python_scripts/snowflake_ai/app/logs/usage/loader.log 2>&1
    
    3. Verify cron was saved:
       crontab -l
    
    4. Check logs:
       tail -f ~/python_scripts/snowflake_ai/app/logs/usage/loader.log
"""

import json
import glob
import os
import sys
from datetime import datetime, timedelta
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from app.config import get_config
from app.utils.database import get_sf_conn
from app.utils.logging import logger


def get_max_timestamp(cursor):
    """
    Get the maximum EVENT_TIMESTAMP from Snowflake table.
    
    Args:
        cursor: Snowflake cursor object
    
    Returns:
        datetime: Maximum timestamp from table, or datetime(1900, 1, 1) if table is empty
    """
    snowflake_db = get_config('SNOWFLAKE_DATABASE')
    query = f"SELECT COALESCE(MAX(EVENT_TIMESTAMP), '1900-01-01 00:00:00') FROM {snowflake_db}.APP_CONFIG.APP_USAGE_LOG"
    cursor.execute(query)
    result = cursor.fetchone()
    max_ts_str = result[0]
    
    # Parse timestamp
    if isinstance(max_ts_str, str):
        max_ts = datetime.fromisoformat(max_ts_str.replace('Z', '+00:00'))
    else:
        max_ts = max_ts_str
    
    logger.info(f"Max timestamp in Snowflake: {max_ts}")
    return max_ts


def read_usage_files(max_timestamp):
    """
    Read usage JSONL files and filter records newer than max_timestamp.
    
    Args:
        max_timestamp (datetime): Only return records newer than this timestamp
    
    Returns:
        list: List of usage records (dicts) that are newer than max_timestamp
    """
    usage_dir = project_root / 'app' / 'logs' / 'usage'
    
    if not usage_dir.exists():
        logger.warning(f"Usage directory does not exist: {usage_dir}")
        return []
    
    new_records = []
    files_processed = 0
    
    # Read all usage JSONL files
    for usage_file in glob.glob(str(usage_dir / 'usage_*.jsonl')):
        files_processed += 1
        logger.info(f"Processing file: {usage_file}")
        
        with open(usage_file, 'r') as f:
            for line_num, line in enumerate(f, 1):
                try:
                    line = line.strip()
                    if not line:
                        continue
                    
                    record = json.loads(line)
                    
                    # Parse timestamp
                    record_ts_str = record.get('timestamp')
                    if not record_ts_str:
                        logger.warning(f"Record in {usage_file}:{line_num} missing timestamp, skipping")
                        continue
                    
                    record_ts = datetime.fromisoformat(record_ts_str.replace('Z', '+00:00'))
                    
                    # Filter by timestamp
                    if record_ts > max_timestamp:
                        new_records.append(record)
                
                except json.JSONDecodeError as e:
                    logger.warning(f"Malformed JSON in {usage_file}:{line_num} - {e}")
                    continue
                except Exception as e:
                    logger.warning(f"Error processing line {line_num} in {usage_file}: {e}")
                    continue
    
    logger.info(f"Processed {files_processed} files, found {len(new_records)} new records")
    return new_records


def cleanup_old_usage_files(retention_days=10):
    """
    Delete usage JSONL files older than retention_days.
    
    This function removes old usage log files to prevent disk space issues.
    Files are safe to delete after they've been loaded to Snowflake.
    
    Args:
        retention_days (int): Keep files from the last N days, delete older ones
    
    Returns:
        int: Number of files deleted
    """
    try:
        usage_dir = project_root / 'app' / 'logs' / 'usage'
        
        if not usage_dir.exists():
            logger.warning(f"Usage directory does not exist: {usage_dir}")
            return 0
        
        cutoff_date = datetime.now() - timedelta(days=retention_days)
        deleted_count = 0
        
        for file_path in glob.glob(str(usage_dir / 'usage_*.jsonl')):
            try:
                # Extract date from filename: usage_20251128.jsonl -> 20251128
                file_name = Path(file_path).stem
                date_str = file_name.split('_')[1]
                file_date = datetime.strptime(date_str, '%Y%m%d')
                
                if file_date < cutoff_date:
                    os.remove(file_path)
                    deleted_count += 1
                    logger.info(f"Deleted old usage file: {file_path} (date: {file_date.date()})")
            
            except (IndexError, ValueError) as e:
                logger.warning(f"Could not parse date from filename {file_path}: {e}")
                continue
            except Exception as e:
                logger.error(f"Error deleting file {file_path}: {e}")
                continue
        
        if deleted_count > 0:
            logger.info(f"✅ Cleanup completed: deleted {deleted_count} old usage file(s)")
        else:
            logger.info(f"No old usage files to delete (retention: {retention_days} days)")
        
        return deleted_count
    
    except Exception as e:
        logger.error(f"Error during cleanup: {e}", exc_info=True)
        return 0


def insert_records(cursor, records):
    """
    Batch insert usage records into Snowflake.
    
    Args:
        cursor: Snowflake cursor object
        records (list): List of usage record dicts to insert
    
    Returns:
        int: Number of records successfully inserted
    """
    if not records:
        logger.info("No records to insert")
        return 0
    
    snowflake_db = get_config('SNOWFLAKE_DATABASE')
    insert_query = f"""
        INSERT INTO {snowflake_db}.APP_CONFIG.APP_USAGE_LOG 
        (EVENT_ID, EVENT_TIMESTAMP, USERNAME, MODULE_NAME, ENDPOINT, 
         HTTP_METHOD, ACTION_TYPE, EXECUTION_TIME_MS, STATUS_CODE, IS_SUCCESS)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
    """
    
    # Prepare batch data
    batch_data = []
    for record in records:
        try:
            row = (
                record.get('event_id'),
                record.get('timestamp'),
                record.get('username', 'anonymous'),
                record.get('module', 'unknown'),
                record.get('endpoint', ''),
                record.get('method', 'GET'),
                record.get('action', 'unknown'),
                record.get('exec_time', 0.0),
                record.get('status', 200),
                record.get('success', True)
            )
            batch_data.append(row)
        except Exception as e:
            logger.warning(f"Error preparing record for insert: {e}")
            continue
    
    # Execute batch insert
    try:
        cursor.executemany(insert_query, batch_data)
        logger.info(f"Successfully inserted {len(batch_data)} records")
        return len(batch_data)
    except Exception as e:
        logger.error(f"Error during batch insert: {e}")
        raise


def load_usage_logs():
    """
    Main function to load usage logs to Snowflake.
    
    This function:
    1. Connects to Snowflake
    2. Gets the maximum timestamp from existing records
    3. Reads JSONL files and filters new records
    4. Batch inserts new records
    5. Commits and closes connection
    """
    conn = None
    cursor = None
    
    try:
        # Connect to Snowflake
        logger.info("=== Starting usage log loader ===")
        conn, cursor = get_sf_conn()
        
        # Get max timestamp from Snowflake
        max_timestamp = get_max_timestamp(cursor)
        
        # Read and filter usage files
        new_records = read_usage_files(max_timestamp)
        
        if not new_records:
            logger.info("No new records to load. Exiting.")
            return
        
        # Insert records
        inserted_count = insert_records(cursor, new_records)
        
        # Commit transaction
        conn.commit()
        logger.info(f"✅ Successfully loaded {inserted_count} usage records to Snowflake")
        
        # Cleanup old usage files (after successful load)
        cleanup_old_usage_files(retention_days=10)
        
    except Exception as e:
        logger.error(f"❌ Error loading usage logs: {e}", exc_info=True)
        if conn:
            conn.rollback()
        sys.exit(1)
    
    finally:
        # Close connection
        if cursor:
            cursor.close()
        if conn:
            conn.close()
        logger.info("=== Usage log loader finished ===")


if __name__ == "__main__":
    load_usage_logs()
