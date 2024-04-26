import argparse
import logging
import time
import datetime
import os
import configparser

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
log_filename = get_local_path(config['General']['logs'], 'FixJson', f'FixJson_{current_time}.log')
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

def fix_json_file(source_path, target_path):
    """Fixes the JSON file by ensuring proper commas between JSON objects."""
    try:
        with open(source_path, 'r', encoding='utf-8') as infile, \
             open(target_path, 'w', encoding='utf-8') as outfile:
            # Write the opening bracket
            outfile.write('[')
            previous_line = infile.readline()
            for line in infile:
                # logger.info(line)
                # Check if the current line starts a new object
                if line.strip() == '{' and previous_line.strip() == '}':
                    # Add a comma between objects
                    # $outfile.write(previous_line.rstrip() + ',\n')
                    outfile.write(previous_line.rstrip() + ',')
                else:
                    outfile.write(previous_line)
                previous_line = line
            # Write the last line
            outfile.write(previous_line)
            # Write the closing bracket
            outfile.write(']')
        logger.info(f"JSON file {source_path} has been fixed and saved to {target_path}.")
    except Exception as e:
        logger.error(f"Failed to fix JSON file: {str(e)}")
        raise

def main():
    parser = argparse.ArgumentParser(description="Fix a JSON file with improperly separated JSON objects.")
    parser.add_argument('filename', help="The base filename of the JSON to process")
    args = parser.parse_args()
    
    source_path = get_local_path(config['Paths']['converted_directory'], args.filename, f'{args.filename}-transformed.json')
    logger.info(f"Source path {source_path}.")
    target_path = get_local_path(config['Paths']['converted_directory'], args.filename, f'{args.filename}-transformed-comma.json')

    start_time = time.time()
    fix_json_file(source_path, target_path)
    end_time = time.time()
    elapsed_time = end_time - start_time
    logger.info(f"Total processing time: {elapsed_time:.2f} seconds.")

if __name__ == "__main__":
    main()