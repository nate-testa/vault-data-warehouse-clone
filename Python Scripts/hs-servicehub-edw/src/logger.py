from datetime import datetime
import logging
import os
import sys


APP_LOGGER_NAME = 'Vault - ServiceHub EDW'


def setup_applevel_logger(logger_name=APP_LOGGER_NAME, file_name=None):

    def handle_exception(exc_type, exc_value, exc_traceback):
        if issubclass(exc_type, KeyboardInterrupt):
            sys.__excepthook__(exc_type, exc_value, exc_traceback)
            return
        logger.error("Uncaught exception", exc_info=(exc_type, exc_value, exc_traceback))

    logger = logging.getLogger(logger_name)
    logger.setLevel(logging.DEBUG)
    fmt = "%(asctime)s - %(levelname)s - %(name)s - %(module)s - %(lineno)s - %(message)s"
    formatter = logging.Formatter(fmt, datefmt='%b %d %H:%M:%S')

    stream_handler = logging.StreamHandler(sys.stdout)
    stream_handler.setFormatter(formatter)
    stream_handler.setLevel(logging.INFO)

    logger.handlers.clear()
    logger.addHandler(stream_handler)

    sys.excepthook = handle_exception

    if file_name:
        fh = logging.FileHandler(file_name)
        fh.setFormatter(formatter)
        logger.addHandler(fh)

    return logger


def get_logger(module_name):
    return logging.getLogger(APP_LOGGER_NAME).getChild(module_name)


_log_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'logs')
os.makedirs(_log_dir, exist_ok=True)
logger = setup_applevel_logger(
    file_name=os.path.join(_log_dir, f'servicehub_edw_{datetime.now().strftime("%Y-%m-%d--%H-%M-%S")}.log')
)
