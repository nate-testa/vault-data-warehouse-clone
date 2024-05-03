import argparse
import logging
import time
import datetime
import re
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
log_filename = get_local_path(config['General']['logs'], 'ConvertMongoJson', f'ConvertMongoJson_{current_time}.log')
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

def preprocess_json(input_filename, output_filename):
    """Preprocess the JSON file to convert MongoDB extended JSON to standard JSON format."""
    try:
        with open(input_filename, 'r', encoding='utf-8') as file:
            with open(output_filename, 'w', encoding='utf-8') as outfile:
                for line in file:
                    # Convert MongoDB ObjectId and ISODate to a standard string
                    line = re.sub(r'ObjectId\("([^"]+)"\)', r'"\1"', line)
                    line = re.sub(r'ISODate\("([^"]+)"\)', r'"\1"', line)
                    line = re.sub(r'NumberInt\(([^)]+)\)', r'\1', line)
                    line = re.sub(r'NumberLong\(([^)]+)\)', r'\1', line)
                    line = re.sub(r"Decimal\('([^']+?)'\)", r'"\1"', line)
                    line = re.sub(r'"(\d{4}-\d{2}-\d{2})"', r'"\1T00:00:00.000Z"', line)
                    line = re.sub(r'\bNaN\b', 'null', line)
                    line = re.sub(r'\bNone\b', 'null', line)
                    outfile.write(line)
        logger.info("Preprocessing complete.")
    except Exception as e:
        logger.error(f"Failed to preprocess JSON file: {e}")

def process_json_objects(input_filename, output_filename):
    """Processes JSON objects from a file without loading the whole file into memory and saves them."""
    try:
        with open(input_filename, 'r', encoding='utf-8') as input_file:
            with open(output_filename, 'w', encoding='utf-8') as output_file:
                for line in input_file:
                    # Optionally, transform the line here if necessary
                    output_file.write(line)
                    # logger.info(f"Processed line: {line.strip()}")
    except Exception as e:
        logger.error(f"Failed to process JSON file: {e}")

def main():
    parser = argparse.ArgumentParser(description="Convert MongoDB JSON to standard JSON")
    parser.add_argument('filename', help="The base filename of the JSON to process")
    args = parser.parse_args()
    
    source_path = get_local_path(config['Paths']['files_directory'], args.filename, f'{args.filename}.json')
    preprocessed_path = get_local_path(config['Paths']['pre_directory'], args.filename, f'pre_{args.filename}.json')
    target_path = get_local_path(config['Paths']['converted_directory'], args.filename, f'{args.filename}-transformed.json')
    
    start_time = time.time()

    # Preprocess the file to convert MongoDB JSON to a more standard format
    preprocess_json(source_path, preprocessed_path)

    # Process the preprocessed JSON file and save the results
    process_json_objects(preprocessed_path, target_path)

    end_time = time.time()
    elapsed_time = end_time - start_time
    logger.info(f"Successfully processed and saved JSON to {target_path}.")
    logger.info(f"Total processing time: {elapsed_time:.2f} seconds.")
    
if __name__ == "__main__":
    main()