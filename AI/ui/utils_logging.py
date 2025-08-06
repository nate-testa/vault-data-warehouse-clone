import os
import logging
from logging.handlers import TimedRotatingFileHandler
from datetime import datetime, timedelta
import glob

log_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "logs")
os.makedirs(log_dir, exist_ok=True)

# Log retention parameters
LOG_RETENTION_DAYS = 1  # Change this value to adjust retention

# Track when cleanup was last performed to avoid excessive cleanup calls
_last_cleanup_file = os.path.join(log_dir, ".last_cleanup")

def cleanup_old_logs():
    """Automatically remove log files older than LOG_RETENTION_DAYS"""
    try:
        # Check if cleanup was already performed today
        today = datetime.now().date()
        if os.path.exists(_last_cleanup_file):
            with open(_last_cleanup_file, 'r') as f:
                last_cleanup_str = f.read().strip()
                if last_cleanup_str:
                    last_cleanup = datetime.fromisoformat(last_cleanup_str).date()
                    if last_cleanup >= today:
                        return  # Cleanup already done today
        
        cutoff_date = datetime.now() - timedelta(days=LOG_RETENTION_DAYS)
        log_pattern = os.path.join(log_dir, "ui_*.log*")
        
        removed_files = 0
        for log_file in glob.glob(log_pattern):
            file_stat = os.stat(log_file)
            file_date = datetime.fromtimestamp(file_stat.st_mtime)
            
            if file_date < cutoff_date:
                os.remove(log_file)
                removed_files += 1
        
        # Update last cleanup timestamp
        with open(_last_cleanup_file, 'w') as f:
            f.write(datetime.now().isoformat())
                
    except Exception as e:
        # Silently handle cleanup errors to avoid disrupting logging
        pass

# Perform cleanup only once per day
cleanup_old_logs()

# Log rotation: daily, keep LOG_RETENTION_DAYS worth of logs
log_file = os.path.join(log_dir, f"ui_{datetime.now().strftime('%Y%m%d')}.log")
file_handler = TimedRotatingFileHandler(
    log_file,
    when="midnight",
    interval=1,
    backupCount=LOG_RETENTION_DAYS,
    encoding="utf-8"
)

# Define formatters
log_formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(filename)s:%(lineno)d - %(message)s')

# Apply formatters
file_handler.setFormatter(log_formatter)

# Console logging for development/debug
stream_handler = logging.StreamHandler()
stream_handler.setFormatter(log_formatter)

logger = logging.getLogger("ui")
logger.setLevel(logging.INFO)
logger.addHandler(file_handler)
logger.addHandler(stream_handler)
logger.propagate = False
