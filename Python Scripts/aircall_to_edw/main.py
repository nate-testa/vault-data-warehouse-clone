"""
Aircall to EDW - Main Orchestrator

Fetches call data from the Aircall API and loads it into
the EDW staging table (edw_stage.stage_aircall_list_all_calls).

Usage:
    python main.py                          # Yesterday's calls
    python main.py --from-date 2026-04-01   # From date to yesterday
    python main.py --from-date 2026-04-01 --to-date 2026-04-30  # Date range
"""

import argparse
import json
import os
import sys
import time
from datetime import datetime, timedelta, timezone

from config_manager import ConfigManager, setup_logger, _PROJECT_ROOT, _load_logging_config
from api_client import AircallApiClient
from db_loader import DbLoader


def parse_args():
    parser = argparse.ArgumentParser(
        description='Fetch Aircall calls and load into EDW staging table.'
    )
    parser.add_argument(
        '--from-date',
        type=str,
        default=None,
        help='Start date (YYYY-MM-DD). Defaults to yesterday.'
    )
    parser.add_argument(
        '--to-date',
        type=str,
        default=None,
        help='End date (YYYY-MM-DD). Defaults to yesterday.'
    )
    return parser.parse_args()


def date_to_unix(date_str, end_of_day=False):
    """Convert YYYY-MM-DD string to UNIX timestamp (UTC)."""
    dt = datetime.strptime(date_str, '%Y-%m-%d').replace(tzinfo=timezone.utc)
    if end_of_day:
        dt = dt.replace(hour=23, minute=59, second=59)
    return int(dt.timestamp())


def write_summary_json(summary):
    """Write execution summary as a JSON file in the log directory."""
    log_cfg = _load_logging_config()
    if not log_cfg.get('write_summary_json', True):
        return
    log_dir = os.path.join(_PROJECT_ROOT, log_cfg.get('log_dir', 'log'))
    os.makedirs(log_dir, exist_ok=True)
    ts = datetime.now(timezone.utc).strftime('%Y%m%d_%H%M%S')
    summary_file = os.path.join(log_dir, f'execution_summary_{ts}.json')
    with open(summary_file, 'w') as f:
        json.dump(summary, f, indent=2, default=str)
    return summary_filed


def main():
    start_time = time.time()
    logger = setup_logger()
    args = parse_args()

    logger.info("=" * 60)
    logger.info("Aircall to EDW - Starting")
    logger.info("=" * 60)

    # Resolve date range
    yesterday = (datetime.now(timezone.utc) - timedelta(days=1)).strftime('%Y-%m-%d')
    from_date = args.from_date or yesterday
    to_date = args.to_date or yesterday

    from_ts = date_to_unix(from_date, end_of_day=False)
    to_ts = date_to_unix(to_date, end_of_day=True)

    logger.info(f"Date range: {from_date} to {to_date}")
    logger.info(f"UNIX timestamps: from={from_ts} to={to_ts}")

    # Build summary dict (updated progressively)
    summary = {
        'status': 'STARTED',
        'start_time': datetime.now(timezone.utc).isoformat(),
        'from_date': from_date,
        'to_date': to_date,
        'from_ts': from_ts,
        'to_ts': to_ts,
        'calls_fetched': 0,
        'rows_loaded': 0,
        'elapsed_seconds': 0,
        'error': None,
    }

    try:
        # Initialize configuration
        logger.info("Loading configuration...")
        config_manager = ConfigManager(logger=logger)

        aircall_creds = config_manager.get_aircall_credentials()
        api_config = config_manager.get_aircall_api_config()
        sql_config = config_manager.get_sql_config()
        db_config = config_manager.get_database_config()

        # Initialize API client and test connection
        logger.info("Initializing Aircall API client...")
        api_client = AircallApiClient(
            credentials=aircall_creds,
            api_config=api_config,
            logger=logger
        )

        if not api_client.test_connection():
            logger.error("Aircall API connection test failed. Aborting.")
            summary['status'] = 'FAILED'
            summary['error'] = 'API connection test failed'
            summary['elapsed_seconds'] = round(time.time() - start_time, 1)
            write_summary_json(summary)
            sys.exit(1)

        # Fetch calls from API
        logger.info("Fetching calls from Aircall API...")
        calls = api_client.fetch_all_calls(from_ts=from_ts, to_ts=to_ts)
        summary['calls_fetched'] = len(calls)

        if not calls:
            logger.info("No calls found for the specified date range.")
            logger.info("Aircall to EDW - Completed (no data)")
            summary['status'] = 'SUCCESS'
            summary['elapsed_seconds'] = round(time.time() - start_time, 1)
            write_summary_json(summary)
            sys.exit(0)

        # Load into database
        with DbLoader(sql_config=sql_config, db_config=db_config, logger=logger) as loader:
            df = loader.transform_calls(calls)
            rows_loaded = loader.load(df, from_ts=from_ts, to_ts=to_ts)

        summary['rows_loaded'] = rows_loaded
        summary['status'] = 'SUCCESS'

    except Exception as e:
        logger.error(f"Execution failed: {e}", exc_info=True)
        summary['status'] = 'FAILED'
        summary['error'] = str(e)
        raise
    finally:
        elapsed = time.time() - start_time
        summary['elapsed_seconds'] = round(elapsed, 1)
        summary['end_time'] = datetime.now(timezone.utc).isoformat()
        summary_file = write_summary_json(summary)

        logger.info("=" * 60)
        logger.info("Aircall to EDW - Summary")
        logger.info(f"  Status       : {summary['status']}")
        logger.info(f"  Date range   : {from_date} to {to_date}")
        logger.info(f"  Calls fetched: {summary['calls_fetched']}")
        logger.info(f"  Rows loaded  : {summary['rows_loaded']}")
        logger.info(f"  Elapsed time : {elapsed:.1f}s")
        if summary_file:
            logger.info(f"  Summary JSON : {summary_file}")
        logger.info("=" * 60)


if __name__ == "__main__":
    try:
        main()
    except Exception:
        sys.exit(1)
