import sys
import logging
import os
from datetime import datetime
from config_manager import ConfigManager
from sharepoint_uploader import SharePointUploader

# Ensure logs directory exists
logs_dir = os.path.join(os.path.dirname(__file__), 'logs')
os.makedirs(logs_dir, exist_ok=True)

# Generate log filename with timestamp
log_filename = os.path.join(logs_dir, f'workday_upload_{datetime.now().strftime("%Y%m%d_%H%M%S")}.log')

# Setup logging to both file and console
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(log_filename),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger("WorkdayAutomation")

if __name__ == "__main__":
    logger.info("="*60)
    logger.info("Starting Workday Data Upload Process")
    logger.info(f"Log file: {log_filename}")
    logger.info("="*60)
    
    try:
        # 1. Init Config (loads secrets from Key Vault)
        config = ConfigManager(logger)
        
        # 2. Run Uploader
        uploader = SharePointUploader(config, logger)
        uploader.run()
        
        logger.info("="*60)
        logger.info("Process Completed Successfully")
        logger.info("="*60)
        sys.exit(0)
        
    except Exception as e:
        logger.critical("="*60)
        logger.critical(f"Process Failed: {e}")
        logger.critical("="*60)
        import traceback
        logger.error(traceback.format_exc())
        sys.exit(1)