import constants

from datetime import datetime
import pyodbc


def get_current_timestamp():
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")


def load_previous_timestamp():
    """Read last_source_extract_ts from edw_core.tetl_control for our process."""
    conn = pyodbc.connect(constants.connection_string)
    try:
        cur = conn.cursor()
        cur.execute(
            "SELECT last_source_extract_ts FROM edw_core.tetl_control WHERE process_nm = ?",
            (constants.etl_process_name,)
        )
        row = cur.fetchone()
        if row is None:
            raise RuntimeError(
                f"No row found in edw_core.tetl_control for process_nm='{constants.etl_process_name}'. "
                "Insert a seed row before running incremental mode."
            )
        ts = row.last_source_extract_ts
        return ts.strftime("%Y-%m-%d %H:%M:%S")
    finally:
        conn.close()


def stamp_most_recent_runtime(timestamp):
    """Update last_source_extract_ts and update_ts in edw_core.tetl_control."""
    conn = pyodbc.connect(constants.connection_string)
    try:
        cur = conn.cursor()
        cur.execute(
            "UPDATE edw_core.tetl_control "
            "SET last_source_extract_ts = ?, update_ts = GETDATE() "
            "WHERE process_nm = ?",
            (timestamp, constants.etl_process_name)
        )
        if cur.rowcount == 0:
            raise RuntimeError(
                f"No row updated in edw_core.tetl_control for process_nm='{constants.etl_process_name}'"
            )
        conn.commit()
    finally:
        conn.close()


def format_unix_timestamp(datetime_str):
    dt = datetime.strptime(datetime_str, "%Y-%m-%d %H:%M:%S")
    return int(dt.timestamp()) * 1000


def parse_cli_date(date_str):
    """Parse a date string from CLI args. Supports YYYY-MM-DD or YYYY-MM-DD HH:MM:SS."""
    for fmt in ("%Y-%m-%d %H:%M:%S", "%Y-%m-%d"):
        try:
            return datetime.strptime(date_str, fmt).strftime("%Y-%m-%d %H:%M:%S")
        except ValueError:
            continue
    raise ValueError(f"Invalid date format: '{date_str}'. Use YYYY-MM-DD or YYYY-MM-DD HH:MM:SS")
