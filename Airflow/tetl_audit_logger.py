import logging
import datetime
from typing import Optional
from airflow.providers.microsoft.mssql.hooks.mssql import MsSqlHook

"""
tetl_audit_logger.py - Generic functions for logging ETL processes to tetl_audit table.

This module provides functionality to log ETL processes in the tetl_audit table,
similar to the stored procedures:
- edw_core.sp_ins_tetl_audit
- edw_core.sp_upd_tetl_audit
- edw_core.sp_upd_error_tetl_audit
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


def start_etl_process(process_name: str, param_desc: Optional[str] = None) -> int:
    """
    Start an ETL process and log it to tetl_audit.
    """

    try:
        with get_connection() as conn:
            cursor = conn.cursor()

            # Current timestamp for process start
            process_start_ts = datetime.datetime.now()

            # Insert the new audit record
            query = f"""
            INSERT INTO edw_core.tetl_audit
            (process_nm, process_start_ts, status_desc, parameter_desc)
            VALUES (%s, %s, 'Running', %s)
            """
            cursor.execute(query, (process_name, process_start_ts, param_desc))

            # Get the ID of the inserted record
            cursor.execute("SELECT @@IDENTITY")
            etl_audit_sk = cursor.fetchone()[0]

            conn.commit()
            logger.info(f"Audit record inserted for process '{process_name}' with ID {etl_audit_sk}")

            return etl_audit_sk
        
    except Exception as e:
        logger.error(f"Error inserting audit record: {e}")
        raise


def success_etl_process(etl_audit_sk: int, record_count: int, param_desc: Optional[str] = None) -> None:
    """
    update success for an ETL process in tetl_audit.
    """
    try:
        with get_connection() as conn:
            cursor = conn.cursor()

            # Current timestamp for process end
            process_end_ts = datetime.datetime.now()

            # limit parameter description length to 255 characters
            param_desc = param_desc[:255] if param_desc else None

            # Update the audit record
            query = f"""
            UPDATE edw_core.tetl_audit 
            SET process_end_ts = %s, 
                record_ct = %s, 
                status_desc = 'Success',
                parameter_desc = %s
            WHERE etl_audit_sk = %s
            """
            cursor.execute(query, (process_end_ts, record_count, param_desc, etl_audit_sk))

            conn.commit()
            logger.info(f"etl_audit_sk: {etl_audit_sk} updated with status 'Success'")
    except Exception as e:
        logger.error(f"Error updating success audit record: {e}")
        raise        


def failure_etl_process(etl_audit_sk: int, error_msg_desc: Optional[str] = None) -> None:
    """
    update Failure for an ETL process in tetl_audit.
    """
    try:
        with get_connection() as conn:
            cursor = conn.cursor()

            # Current timestamp for process end
            process_end_ts = datetime.datetime.now()

            # limit error message length to 2000 characters
            error_msg_desc = error_msg_desc[:2000] if error_msg_desc else None

            # Update the audit record
            query = f"""
            UPDATE edw_core.tetl_audit 
            SET process_end_ts = %s, 
                status_desc = 'Failure',
                error_message_desc = %s
            WHERE etl_audit_sk = %s
            """
            cursor.execute(query, (process_end_ts, error_msg_desc, etl_audit_sk))

            conn.commit()
            logger.info(f"etl_audit_sk: {etl_audit_sk} updated with status 'Failure'")
    except Exception as e:
        logger.error(f"Error updating failure audit record: {e}")
        raise        

