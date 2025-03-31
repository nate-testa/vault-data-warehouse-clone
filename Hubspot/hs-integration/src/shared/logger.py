import constants
from datetime import datetime

import logging
import sys



log_folder_path = constants.log_folder_path
today = datetime.today().date()
file_name = f'{log_folder_path}/hs-integration-run-{today}.log'


APP_LOGGER_NAME = 'VAULT - EDW integration'

def setup_applevel_logger(logger_name = APP_LOGGER_NAME, file_name=None):
    def handle_exception(exc_type, exc_value, exc_traceback):
        if issubclass(exc_type, KeyboardInterrupt):
            sys.__excepthook__(exc_type, exc_value, exc_traceback)
            return
        logger.error("Uncaught exception", exc_info=(exc_type, exc_value, exc_traceback))
        
    logger = logging.getLogger(logger_name) 
    logger.setLevel(logging.DEBUG)
    format="%(asctime)s - %(levelname)s - %(name)s - %(module)s - %(lineno)s -  %(message)s"
    formatter = logging.Formatter(format, datefmt='%b %d %H:%M:%S')

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



logger = setup_applevel_logger(file_name=file_name)