import logging
import pandas as pd
import shutil
import os
from pathlib import Path
from datetime import datetime
from configparser import ConfigParser
from airflow.providers.microsoft.mssql.hooks.mssql import MsSqlHook
from airflow.providers.microsoft.azure.hooks.wasb import WasbHook
from airflow.models import Variable

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def get_config_value(config, section, key):
    """Retrieve a configuration value with error handling."""
    try:
        value = config.get(section, key)
        logging.info(f"Config value for '{key}' in section '{section}': {value}")
        return value
    except Exception as e:
        logging.error(f"Missing or invalid config key: '{key}' in section '{section}' - {e}")
        raise

class Preprocessor:
    def __init__(self, file_path, source_directory, archive_directory):
        self.file_path = file_path
        self.source_directory = Path(source_directory)
        self.archive_directory = Path(archive_directory)
        self.df = None

    def load_data(self):
        try:
            self.df = pd.read_excel(self.file_path)
            logging.info(f"Excel file '{self.file_path}' loaded successfully.")
        except Exception as e:
            logging.error(f"Error loading Excel file '{self.file_path}': {e}")
            raise

    def process_data(self):
        try:
            # Drop unwanted columns
            # self.df.drop(columns=['Fronting Fee Total', 'Underwriting Year Percentage'], inplace=True)

            # Convert 'Reporting Month' to the required date format
            self.df['Reporting Month'] = pd.to_datetime(self.df['Reporting Month'].str.strip(), format='%b %Y', errors='coerce')
            self.df['Reporting Month'] = self.df['Reporting Month'].dt.strftime('%Y-%m-%d 00:00:00.000')

            logging.info(f"Data processing for '{self.file_path}' completed successfully.")
        except Exception as e:
            logging.error(f"Error processing data for '{self.file_path}': {e}")
            raise

    def save_to_csv(self):
        try:
            processed_file_path = self.source_directory / f"{Path(self.file_path).stem}.csv"
            self.df.to_csv(processed_file_path, index=False)
            logging.info(f"Processed data saved to CSV at '{processed_file_path}'.")
            return processed_file_path
        except Exception as e:
            logging.error(f"Error saving to CSV: {e}")
            raise

    def move_original_file(self):
        try:
            target_path = self.archive_directory / Path(self.file_path).name
            os.makedirs(self.archive_directory, exist_ok=True)
            os.rename(self.file_path, target_path)
            logging.info(f"Original Excel file moved to archive: '{target_path}'.")
        except Exception as e:
            logging.error(f"Error moving original file '{self.file_path}': {e}")
            raise

def process_files(use_local_files, config):
    try:
        if use_local_files:
            xlsx_directory = Path(get_config_value(config, 'DEFAULT', 'xlsx_directory'))
            source_directory = Path(get_config_value(config, 'DEFAULT', 'source_directory'))
            archive_directory = Path(get_config_value(config, 'DEFAULT', 'archive_directory'))

            # Ensure directories exist
            os.makedirs(source_directory, exist_ok=True)
            os.makedirs(archive_directory, exist_ok=True)

            files = sorted(xlsx_directory.glob('*.xlsx'))
            if not files:
                logging.info("No local .xlsx files found to process.")
                return

            for file_path in files:
                logging.info(f"Processing local file: {file_path}")
                preprocessor = Preprocessor(file_path, source_directory, archive_directory)

                try:
                    preprocessor.load_data()
                    preprocessor.process_data()
                    preprocessor.save_to_csv()
                    preprocessor.move_original_file()
                except Exception as e:
                    logging.error(f"Error processing local file '{file_path}': {e}")
                    continue

        else:
            # Azure Blob Storage configuration
            wasb_conn_id = 'azure_blob_storage'
            container_name = 'inbound-nfp'
            files_folder = 'files'
            local_processing_dir = Path(get_config_value(config, 'DEFAULT', 'xlsx_directory'))
            archive_folder = Path(get_config_value(config, 'DEFAULT', 'archive_directory'))
            source_directory = Path(get_config_value(config, 'DEFAULT', 'source_directory'))

            wasb_hook = WasbHook(wasb_conn_id=wasb_conn_id)
            blob_service_client = wasb_hook.get_conn()
            container_client = blob_service_client.get_container_client(container_name)

            # List blobs in the container
            blob_list = container_client.list_blobs(name_starts_with=f"{files_folder}/")
            xlsx_files = [blob.name for blob in blob_list if blob.name.endswith('.xlsx')]

            if not xlsx_files:
                logging.info("No .xlsx files found in Azure Blob Storage to process.")
                return

            for blob_name in xlsx_files:
                xls_filename = os.path.basename(blob_name)
                local_file_path = local_processing_dir / xls_filename

                try:
                    # Download file from Azure
                    logging.info(f"Downloading '{blob_name}' from Azure Blob Storage.")
                    blob_client = container_client.get_blob_client(blob_name)
                    os.makedirs(local_processing_dir, exist_ok=True)
                    with open(local_file_path, "wb") as file:
                        file.write(blob_client.download_blob().readall())

                    # Process the downloaded file
                    preprocessor = Preprocessor(local_file_path, source_directory, archive_folder)
                    preprocessor.load_data()
                    preprocessor.process_data()
                    preprocessor.save_to_csv()
                    preprocessor.move_original_file()

                    # Copy into the archive folder, then delete the original
                    archive_blob_name = f"archive/{xls_filename}"
                    archive_blob_client = container_client.get_blob_client(archive_blob_name)
                    archive_blob_client.start_copy_from_url(blob_client.url)
                    container_client.delete_blob(blob_name)
                    logging.info(f"Moved '{blob_name}' to archive in Azure: '{archive_blob_name}'.")

                except Exception as e:
                    logging.error(f"Error processing Azure file '{xls_filename}': {e}")
                    continue

    except Exception as e:
        logging.error(f"Error in process_files: {e}")
        raise


def main():
    current_dir = os.path.dirname(os.path.abspath(__file__))
    config_path = os.path.join(current_dir, 'config.ini')

    # Read the configuration file
    config = ConfigParser()
    config.read(config_path)

    # Set processing mode
    use_local_files = False

    # Process files based on the mode
    process_files(use_local_files, config)


if __name__ == "__main__":
    main()
