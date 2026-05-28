import src.timetracking as timetracking
import argparse
import sys

from src.ticket import Ticket
from src.contact import Contact


def run_incremental():
    """Daily incremental mode: uses last_run_timestamp -> now."""
    start_time = timetracking.load_previous_timestamp()
    end_time = timetracking.get_current_timestamp()

    print(f'[incremental] syncing from {start_time} to {end_time}')

    Ticket.sync_to_edw(start_time, end_time)
    Contact.sync_to_edw(start_time, end_time)

    timetracking.stamp_most_recent_runtime(end_time)


def run_custom(start_date, end_date):
    """Custom date range mode: user-provided start and end dates."""
    start_time = timetracking.parse_cli_date(start_date)
    end_time = timetracking.parse_cli_date(end_date)

    print(f'[custom] syncing from {start_time} to {end_time}')

    Ticket.sync_to_edw(start_time, end_time)
    Contact.sync_to_edw(start_time, end_time)


def main():
    parser = argparse.ArgumentParser(
        description='ServiceHub data integration into EDW',
        formatter_class=argparse.RawTextHelpFormatter,
    )
    parser.add_argument(
        '--mode',
        choices=['incremental', 'custom'],
        default='incremental',
        help='incremental: daily run using last timestamp (default)\ncustom: use --start_date and --end_date',
    )
    parser.add_argument(
        '--start_date',
        type=str,
        help='Start date for custom mode (YYYY-MM-DD or YYYY-MM-DD HH:MM:SS)',
    )
    parser.add_argument(
        '--end_date',
        type=str,
        help='End date for custom mode (YYYY-MM-DD or YYYY-MM-DD HH:MM:SS)',
    )

    args = parser.parse_args()

    if args.mode == 'custom':
        if not args.start_date or not args.end_date:
            parser.error('custom mode requires both --start_date and --end_date')
        run_custom(args.start_date, args.end_date)
    else:
        run_incremental()


if __name__ == '__main__':
    main()
