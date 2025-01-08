import os
import boto3
import logging
import sys
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
    
# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def download_file_from_s3(bucket, key, local_path):
    s3 = boto3.client('s3')
    try:
        s3.download_file(bucket, key, local_path)
        logging.info(f"Successfully downloaded {key} from {bucket} to {local_path}")
    except boto3.exceptions.S3UploadFailedError as e:
        logging.error(f"Failed to download file from S3: {str(e)}")
        sys.exit(1)
    except Exception as e:
        logging.error(f"An unexpected error occurred: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    config = load_config()

    if len(sys.argv) != 2:
        logging.error("Usage: python script.py <base_filename_without_extension>")
        sys.exit(1)

    bucket_name = config['Buckets']['bucket_name_source']
    base_filename = sys.argv[1]  # Takes the base filename from command-line argument
    object_key = f"{base_filename}.json"  # Appends '.json' to the base filename for S3 object key
    local_filename = f"{base_filename}.json"  # Appends '.json' for the local filename

    # Construct full local path (adjust the path as per your OS and user folder structure)
    local_path = get_local_path(config['Paths']['files_directory'], base_filename, local_filename)

    # Download the file
    download_file_from_s3(bucket_name, object_key, local_path)