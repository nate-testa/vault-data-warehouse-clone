import json
import decimal
import logging
import argparse
import os
import ijson
import datetime
import time
import configparser

def load_config():
    """Load configuration from a file."""
    config = configparser.ConfigParser()
    config.read('config.ini')
    return config

def get_local_path(directory, base_filename, full_filename, is_dir=False):
    """
    Construct a full local path using os.path.join, ensure the directory exists, 
    and optionally create the directory structure if required.
    """
    # Further construct the path if needed
    if is_dir:
        # Construct the base path
        full_path = directory + base_filename
        
        # Construct the full directory path
        if full_filename:
            full_path = os.path.join(full_path, full_filename)

            # Check and create the full directory path if it doesn't exist
            if not os.path.exists(full_path):
                os.makedirs(full_path)  # This will create the directory and any intermediate directories
                
        # logger.info('Dir: ' + full_path)
        return full_path
    else:
        # Construct the base path
        full_path = directory + base_filename
        
        # Check and create the base directory if it doesn't exist
        if not os.path.exists(full_path):
            os.makedirs(full_path)  # This will create the directory and any intermediate directories
        
        full_path = os.path.join(full_path, full_filename)
        # logger.info('NoDir: ' + full_path)
        return full_path

config = load_config()

# Setup logging
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

stream_handler = logging.StreamHandler()
current_time = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
log_filename = get_local_path(config['General']['logs'], 'SplitJson', f'SplitJson_{current_time}.log')
file_handler = logging.FileHandler(log_filename)

formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
stream_handler.setFormatter(formatter)
file_handler.setFormatter(formatter)

logger.addHandler(stream_handler)
logger.addHandler(file_handler)

# Custom JSON Encoder that handles Decimal types
class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, decimal.Decimal):
            return float(obj)  # or str(obj) to convert decimal to string if precision is critical
        return super(DecimalEncoder, self).default(obj)

def split_json_into_smaller_files(input_filename, output_dir, max_size=16777216):
    # Check file size first
    input_size = os.path.getsize(input_filename)
    if input_size <= max_size:
        output_file_path = os.path.join(output_dir, f'part_1.json')
        shutil.copy(input_filename, output_file_path)
        logger.info(f"Moved {input_filename} to {output_file_path}, size: {input_size} bytes")
        return

    file_number = 1
    current_size = 0
    output_file_path = os.path.join(output_dir, f'part_{file_number}.json')
    # logger.info(output_file_path)

    try:
        with open(input_filename, 'r', encoding='utf-8') as input_file:
            objects = ijson.items(input_file, 'item')
            current_file = open(output_file_path, 'w', encoding='utf-8')
            current_file.write('[')

            for obj in objects:
                obj_json = json.dumps(obj, cls=DecimalEncoder)  # Use custom encoder
                obj_str = f"{obj_json},\n"
                obj_size = len(obj_str.encode('utf-8'))

                if current_size + obj_size > max_size:
                    current_file.write(']')
                    current_file.close()
                    logger.info(f"Created {output_file_path}, size: {current_size} bytes")

                    file_number += 1
                    current_size = 0
                    output_file_path = os.path.join(output_dir, f'part_{file_number}.json')
                    current_file = open(output_file_path, 'w', encoding='utf-8')
                    current_file.write('[')

                current_file.write(obj_str)
                current_size += obj_size

            current_file.write(']')
            current_file.close()
            logger.info(f"Created {output_file_path}, size: {current_size} bytes")

    except MemoryError:
        logger.error("MemoryError occurred while processing the JSON file.")
        raise
    except Exception as e:
        logger.error(f"An error occurred while processing the JSON file: {e}")

def main():
    parser = argparse.ArgumentParser(description="Split a large JSON file into smaller parts while maintaining JSON structure.")
    parser.add_argument('filename', help="The filename of the large JSON file.")
    args = parser.parse_args()
    
    source_path = get_local_path(config['Paths']['converted_directory'], args.filename, f'{args.filename}-transformed-comma.json')
    output_dir = get_local_path(config['Paths']['converted_directory'], args.filename, f'{args.filename}_split/', True)

    start_time = time.time()
    try:
        split_json_into_smaller_files(source_path, output_dir)
    except MemoryError:
        logger.error("MemoryError occurred. The file may be too large to process.")
    end_time = time.time()

    elapsed_time = end_time - start_time
    logger.info(f"Completed splitting JSON into smaller parts.")
    logger.info(f"Total processing time: {elapsed_time:.2f} seconds.")

if __name__ == "__main__":
    main()