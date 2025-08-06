import logging
from pathlib import Path
from datetime import datetime

LOG_DIR = Path(__file__).parent / "logs"
LOG_DIR.mkdir(exist_ok=True)

# Daily log file: ui_streamlit_YYYYMMDD.log
LOG_FILE = LOG_DIR / f"ui_streamlit_{datetime.now().strftime('%Y%m%d')}.log"

formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(filename)s:%(lineno)d - %(message)s')

file_handler = logging.FileHandler(LOG_FILE, encoding="utf-8")
file_handler.setFormatter(formatter)

stream_handler = logging.StreamHandler()
stream_handler.setFormatter(formatter)

logger = logging.getLogger("ui_streamlit")
logger.setLevel(logging.INFO)
logger.handlers.clear()
logger.addHandler(file_handler)
# logger.addHandler(stream_handler)
