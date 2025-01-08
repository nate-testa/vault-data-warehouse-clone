import shutil
import subprocess
import os
import sys
import logging
import configparser
import datetime

def load_config():
    """Load configuration from a file."""
    config = configparser.ConfigParser()
    config.read('config.ini')
    return config
    
def get_local_path(directory, base_filename, full_filename):
    """Construct a full local path using os.path.join and ensure the directory exists."""
    full_path = directory + base_filename
    
    # Check if the directory exists, if not create it
    if not os.path.exists(full_path):
        os.makedirs(full_path)  # This will create the directory and any intermediate directories

    """Construct a full local path using os.path.join for better path handling."""
    return os.path.join(full_path, full_filename)

config = load_config()

# Setup logging
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

# Create handlers
stream_handler = logging.StreamHandler()
current_time = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
log_filename = get_local_path(config['General']['logs'], 'process_logs', f'process_logs_{current_time}.log')
file_handler = logging.FileHandler(log_filename)

# Set level for handlers
stream_handler.setLevel(logging.INFO)
file_handler.setLevel(logging.INFO)

# Create formatter and add it to handlers
formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
stream_handler.setFormatter(formatter)
file_handler.setFormatter(formatter)

# Add handlers to the logger
logger.addHandler(stream_handler)
logger.addHandler(file_handler)

def run_script(script_name, arg):
    """Execute a Python script with a given argument and handle exceptions."""
    try:
        subprocess.run(['python', script_name, arg], check=True)
        logger.info(f"Successfully ran script: {script_name} with argument: {arg}")
    except subprocess.CalledProcessError as e:
        logger.error(f"Script {script_name} failed with a non-zero exit status: {e}")
    except Exception as e:
        logger.error(f"Error running script {script_name}: {e}")

def read_args(file_path):
    """Read arguments from a file and handle file-related errors."""
    try:
        with open(file_path, 'r') as file:
            args = [line.strip() for line in file if line.strip()]
        logger.info(f"Arguments read successfully from {file_path}")
        return args
    except FileNotFoundError:
        logger.error(f"The file {file_path} does not exist.")
        sys.exit(1)
    except Exception as e:
        logger.error(f"Failed to read arguments from {file_path}: {e}")
        sys.exit(1)

def delete_all_contents(directory):
    """Delete all contents of the specified directory, then the directory itself."""
    try:
        for entry in os.listdir(directory):
            path = os.path.join(directory, entry)
            if os.path.isdir(path):
                shutil.rmtree(path)
                logger.info(f"Deleted directory {path}")
            elif os.path.isfile(path) or os.path.islink(path):
                os.unlink(path)
                logger.info(f"Deleted file {path}")
        shutil.rmtree(directory)  # Delete the directory itself after clearing it
        logger.info(f"Deleted base directory {directory}")
    except Exception as e:
        logger.error(f"Failed to delete directory and its contents in {directory}: {e}")

def main():
    # Hardcoded filename for the list of arguments
    # args_file = 'ListFiles.txt'
    args_file = config['Paths']['args_file']
    args_list = read_args(args_file)

    # List of scripts to be run sequentially for each argument
    scripts = ['download_S3.py', 'convertMongoJson.py', 'convertMongoJson_comma.py', 'convertMongoJson_split.py', 'upload_S3_split.py', 'execute_in_snowflake.py']
    # scripts = ['download_S3.py']

    # Path to the directory where files should be deleted
    files_directory = config['Paths']['files_directory']

    for arg in args_list:
        logger.info(f"Processing argument: {arg}")
        for script in scripts:
            run_script(script, arg)
        
        delete_all_contents(files_directory)
    logger.info("Finished processing all arguments.")
    
if __name__ == "__main__":
    main()