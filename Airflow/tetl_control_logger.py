import logging
import datetime
from datetime import datetime, timezone
from airflow.providers.microsoft.mssql.hooks.mssql import MsSqlHook

"""
tetl_control_logger.py - Generic functions for logging ETL control information to tetl_control table.
similar to the stored procedure:
- edw_core.sp_upd_tetl_control
"""

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Airflow connection ID
MSSQL_CONN_ID = 'Vault_EDW'


def get_connection():
    """Create and return a connection to the database using the Airflow connection."""
    try:
        # Get connection using MsSqlHook from Airflow
        mssql_hook = MsSqlHook(mssql_conn_id=MSSQL_CONN_ID)
        connection = mssql_hook.get_conn()
        return connection
    except Exception as e:
        logger.error(f"Error connecting to database: {e}")
        raise


def update_tetl_control_table(process_nm: str, last_source_extract_ts: str) -> None:
    """
    Update the tetl_control table with the last source extract timestamp for the given process name.
    """
    try:
        with get_connection() as conn:
            cursor = conn.cursor()

            # Update the tetl_control table using the stored procedure
            query = "EXEC edw_core.sp_upd_tetl_control %s, %s"
            
            cursor.execute(query, (process_nm, last_source_extract_ts))

            conn.commit()
            logger.info(f"Table tetl_control updated successfully. last_source_extract_ts: {last_source_extract_ts}")

    except Exception as e:
        logger.error(f"Error updating tetl_control table: {e}")
        raise


def get_last_source_extract_ts(process_nm: str) -> datetime:
    """
    Retrieve the last source extract timestamp from the tetl_control table for the given process name.
    """
    try:
        with get_connection() as conn:
            cursor = conn.cursor()
            query = """
                SELECT last_source_extract_ts 
                FROM edw_core.tetl_control 
                WHERE process_nm = %s
            """
            cursor.execute(query, (process_nm,))
            result = cursor.fetchone()

            if result and result[0]:
                last_source_extract_ts = result[0]
                # Convert to UTC if not already in UTC
                if last_source_extract_ts.tzinfo is None:
                    last_source_extract_ts = last_source_extract_ts.replace(tzinfo=timezone.utc)
                else:
                    last_source_extract_ts = last_source_extract_ts.astimezone(timezone.utc)
                # Log the last source extract timestamp
                logger.info(f"Last source extract timestamp: {last_source_extract_ts}")
                return last_source_extract_ts
            else: # return default date 2025-01-01
                default_date = datetime(2025, 1, 1, tzinfo=timezone.utc)
                logger.warning("No extract timestamp found. Returning default date: 2025-01-01")
                return default_date

    except Exception as e:
        logger.error(f"Error retrieving extract timestamp: {e}")
        raise

