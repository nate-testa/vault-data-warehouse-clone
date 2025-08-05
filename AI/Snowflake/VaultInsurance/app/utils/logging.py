
import os
import logging
from logging.handlers import TimedRotatingFileHandler
from datetime import datetime

log_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../logs")
os.makedirs(log_dir, exist_ok=True)

# Log retention parameters
LOG_RETENTION_DAYS = 1  # Change this value to adjust retention

# Log rotation: daily, keep LOG_RETENTION_DAYS worth of logs
log_file = os.path.join(log_dir, f"vault_ai_api_{datetime.now().strftime('%Y%m%d')}.log")
file_handler = TimedRotatingFileHandler(
    log_file,
    when="midnight",
    interval=1,
    backupCount=LOG_RETENTION_DAYS,
    encoding="utf-8"
)
file_handler.setFormatter(logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(filename)s:%(lineno)d - %(message)s'))

# Console logging for development/debug
stream_handler = logging.StreamHandler()
stream_handler.setFormatter(logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(filename)s:%(lineno)d - %(message)s'))

logger = logging.getLogger("vault_ai_api")
logger.setLevel(logging.INFO)
logger.addHandler(file_handler)
logger.addHandler(stream_handler)
logger.propagate = False
