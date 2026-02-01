import shared.timetracking as timetracking

from objects.customer import Customer
from objects.producer import Producer
from objects.policy import Policy
from objects.broker import Broker
from objects.quote import Quote
from objects.parent_child_note import ParentChildNotes
from objects.quote_note import QuoteNote
from shared.error_reporter import ErrorReporter
from shared.logger import get_logger
import constants
import os

logger = get_logger(__name__)

def run():
    # Get the singleton error reporter instance
    # Note: This must be the same instance used by hubspot.py
    error_reporter = ErrorReporter()
    
    logger.info("Starting HubSpot Integration")

    try:
        Producer.sync_to_hubspot()         # contacts
        Customer.sync_to_hubspot()         # contacts
        Policy.sync_to_hubspot()           # policies
        Broker.sync_to_hubspot()           # companies
        Quote.sync_to_hubspot()            # deals
        QuoteNote.sync_to_hubspot()        # notes
        ParentChildNotes.sync_to_hubspot() # notes


        Producer.associate_records()
        Customer.associate_records()
        Broker.associate_records()


        now = timetracking.get_current_timestamp()
        timetracking.stamp_most_recent_runtime(now)
        
        logger.info("HubSpot Integration completed successfully")
        
    except Exception as e:
        logger.error(f"Critical error during HubSpot Integration: {e}", exc_info=True)
        error_reporter.add_error('CRITICAL_ERROR', f'Execution failed: {str(e)}', {'exception': str(e)})
    
    finally:
        # Finalize and generate report
        error_reporter.finalize()
        
        # Get report mode from constants (default to 'both')
        report_mode = getattr(constants, 'EMAIL_REPORT_MODE', 'both')
        
        # Save report to file for Airflow to pick up
        report_path = os.path.join(constants.log_folder_path, 'latest_execution_report.html')
        error_reporter.save_report(report_path, report_mode)
        logger.info(f"Execution report saved to: {report_path} (mode: {report_mode})")
        
        # Also save a timestamped version for history
        timestamp = error_reporter.start_time.strftime('%Y%m%d_%H%M%S')
        history_path = os.path.join(constants.log_folder_path, f'execution_report_{timestamp}.html')
        error_reporter.save_report(history_path, report_mode)
        logger.info(f"Execution report archived to: {history_path}")
        
        # Print summary to console
        status, status_icon = error_reporter.get_status()
        print(f"\n{status_icon} Execution Status: {status}")
        print(f"Duration: {error_reporter.get_duration()}")
        print(f"Records Processed: {error_reporter.get_total_processed()}")
        print(f"Errors: {len(error_reporter.errors)}")
        print(f"Warnings: {len(error_reporter.warnings)}")
        print(f"Report: {report_path}\n")


if __name__ == '__main__' :
    run()
