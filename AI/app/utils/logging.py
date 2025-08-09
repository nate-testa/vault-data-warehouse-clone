import os
import logging
from logging.handlers import TimedRotatingFileHandler

log_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../logs")
os.makedirs(log_dir, exist_ok=True)

# Log retention parameters
LOG_RETENTION_DAYS = 2  # Change this value to adjust retention

# Use industry standard: TimedRotatingFileHandler
log_file = os.path.join(log_dir, "api.log")
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

logger = logging.getLogger("api")
logger.setLevel(logging.INFO)
logger.addHandler(file_handler)
logger.addHandler(stream_handler)
logger.propagate = False
