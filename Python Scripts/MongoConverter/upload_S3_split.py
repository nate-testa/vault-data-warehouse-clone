import boto3
import logging
import sys
import os
import configparser

# Load config from local
def load_config():
    """Load configuration from a file."""
    config = configparser.ConfigParser()
    config.read('config.ini')
    return config

def get_local_path(directory, base_filename, full_filename):
    """Construct a full local path using os.path.join and ensure the directory exists."""
    full_path = os.path.join(directory, base_filename, full_filename)
    
    # Check if the directory exists, if not create it
    if not os.path.exists(full_path):
        os.makedirs(full_path)  # This will create the directory and any intermediate directories

    """Construct a full local path using os.path.join for better path handling."""
    if full_filename == '':
        return os.path.join(directory, base_filename)
    else:
        return full_path

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
    
def upload_file_to_s3(local_path, bucket, key):
    s3 = boto3.client('s3')
    try:
        s3.upload_file(local_path, bucket, key)
        logging.info(f"Successfully uploaded {local_path} to {bucket}/{key}")
    except boto3.exceptions.S3UploadFailedError as e:
        logging.error(f"Failed to upload file to S3: {str(e)}")
        sys.exit(1)
    except Exception as e:
        logging.error(f"An unexpected error occurred: {str(e)}")
        sys.exit(1)

def create_bucket_if_not_exists(bucket_name):
    s3 = boto3.client('s3')
    try:
        s3.head_bucket(Bucket=bucket_name)
    except s3.exceptions.ClientError as e:
        error_code = int(e.response['Error']['Code'])
        if error_code == 404:
            s3.create_bucket(Bucket=bucket_name)
            logging.info(f"Bucket {bucket_name} created successfully.")
        else:
            raise
            
if __name__ == "__main__":
    config = load_config()
    if len(sys.argv) != 2:
        logging.error("Usage: python script.py <directory_name>")
        sys.exit(1)

    directory_name = sys.argv[1]  # Directory name from command-line argument
    bucket_name = config['Buckets']['bucket_name_target']  # Specify the S3 bucket name

    # Construct the directory path (adjust the path as per your OS and user folder structure)
    directory_path = get_local_path(config['Paths']['converted_directory'], directory_name, f'{directory_name}_split')

    # Create the bucket if it does not exist
    create_bucket_if_not_exists(bucket_name)

    # Upload all files in the specified directory to the S3 bucket
    for filename in os.listdir(directory_path):
        # logging.info(filename)
        if filename.endswith(".json"):
            local_path = os.path.join(directory_path, filename)
            object_key = f"{directory_name}_split/{filename}"  # Constructs the S3 object key
            upload_file_to_s3(local_path, bucket_name, object_key)