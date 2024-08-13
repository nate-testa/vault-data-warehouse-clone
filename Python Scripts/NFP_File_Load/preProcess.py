import logging
import pandas as pd
from pathlib import Path
from datetime import datetime
from configparser import ConfigParser
import shutil
import os

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

class Preprocessor:
    def __init__(self, file_path, source_directory, archive_directory):
        self.file_path = file_path
        self.source_directory = Path(source_directory)
        self.archive_directory = Path(archive_directory)
        self.df = None

    def load_data(self):
        try:
            self.df = pd.read_excel(self.file_path)
            logging.info("Excel file loaded successfully.")
        except Exception as e:
            logging.error("Error loading Excel file: %s", e)
            raise

    def process_data(self):
        try:
            # Drop the unwanted columns
            self.df.drop(columns=['Fronting Fee Total', 'Underwriting Year Percentage'], inplace=True)

            # Convert 'Reporting Month' to the required date format
            self.df['Reporting Month'] = pd.to_datetime(self.df['Reporting Month'].str.strip(), format='%b %Y', errors='coerce')

            # Now, ensure it's correctly formatted to 'YYYY-MM-DD 00:00:00.000'
            self.df['Reporting Month'] = self.df['Reporting Month'].dt.strftime('%Y-%m-%d 00:00:00.000')

            logging.info("Data processing completed successfully.")
        except Exception as e:
            logging.error("Error processing data: %s", e)
            raise

    def save_to_csv(self):
        try:
            processed_file_path = self.source_directory / (Path(self.file_path).stem + '.csv')
            self.df.to_csv(processed_file_path, index=False)
            logging.info("Processed data saved to CSV successfully.")
            return processed_file_path
        except Exception as e:
            logging.error("Error saving to CSV: %s", e)
            raise

    def move_original_file(self):
        try:
            shutil.move(self.file_path, self.archive_directory / Path(self.file_path).name)
            logging.info("Original Excel file moved to archive directory successfully.")
        except Exception as e:
            logging.error("Error moving original Excel file: %s", e)
            raise

def main():
    # Load configuration
    current_dir = os.path.dirname(os.path.abspath(__file__))
    config_path = os.path.join(current_dir, 'config.ini')

    # Read the configuration file
    config = ConfigParser()
    config.read(config_path)

    xlsx_directory = os.path.join(current_dir, config.get('DEFAULT', 'xlsx_directory')
    source_directory = os.path.join(current_dir, config.get('DEFAULT', 'source_directory'))
    archive_directory = os.path.join(current_dir, config.get('DEFAULT', 'archive_directory'))
    log_directory = os.path.join(current_dir, config.get('DEFAULT', 'log_directory'))

    # Ensure directories exist
    Path(source_directory).mkdir(parents=True, exist_ok=True)
    Path(archive_directory).mkdir(parents=True, exist_ok=True)
    Path(log_directory).mkdir(parents=True, exist_ok=True)

    # Create log file path
    log_file = Path(log_directory) / 'preprocessed_files.log'

    xlsx_directory = Path(xlsx_directory)
    files = sorted(xlsx_directory.glob('*.xlsx'))

    for file_path in files:
        logging.info("Processing file: %s", file_path)

        preprocessor = Preprocessor(file_path, source_directory, archive_directory)

        try:
            preprocessor.load_data()
            preprocessor.process_data()
            processed_file_path = preprocessor.save_to_csv()
            preprocessor.move_original_file()

            # Log the processed file
            with log_file.open('a') as log_f:
                log_f.write(f"{datetime.now()} - Processed file: {file_path.name} to {processed_file_path.name}\n")
        except Exception as e:
            logging.critical("Critical error in preprocessing: %s", e)
            continue

if __name__ == "__main__":
    main()
#main()
