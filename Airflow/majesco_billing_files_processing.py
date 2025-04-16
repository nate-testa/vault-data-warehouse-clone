import os
import logging
import pandas as pd
import time
import majesco_billing_mapping
import io
import re
from typing import Union
from pathlib import Path
from datetime import datetime
from airflow.providers.microsoft.mssql.hooks.mssql import MsSqlHook
from airflow.providers.microsoft.azure.hooks.wasb import WasbHook
from airflow.models import Variable


ENVIRONMENT = Variable.get("environment")
HOME_PATH = os.path.expanduser('~')


# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

class MajescoBillingProcessor:
    def __init__(self, csv_filename, table_name):
        # File and directory configurations
        self.csv_filename = csv_filename
        self.table_name = table_name
        self.container_name = 'inbound-majesco-billing'
        self.files_folder = 'Formatted'
        self.archive_folder = 'archive'
        self.local_to_process_dir = HOME_PATH + '/airflow/tmp_files/majesco_billing/to_process'
        self.local_processed_dir = HOME_PATH + '/airflow/tmp_files/majesco_billing/processed_files'
        self.local_file_path = os.path.join(self.local_to_process_dir, self.csv_filename)

        # Airflow connection IDs
        self.wasb_conn_id = 'azure_blob_storage'
        self.mssql_conn_id = 'Vault_EDW'

        # Initialize connections
        self.create_blob_service_client()

    def create_blob_service_client(self):
        wasb_hook = WasbHook(wasb_conn_id=self.wasb_conn_id)
        self.blob_service_client = wasb_hook.get_conn()
        logging.info("Connected to Azure Blob Storage.")

    def get_sql_connection(self):
        mssql_hook = MsSqlHook(mssql_conn_id=self.mssql_conn_id)
        return mssql_hook.get_conn()

    def download_file_from_azure(self):
        try:
            blob_client = self.blob_service_client.get_blob_client(
                container=self.container_name,
                blob=f"{self.files_folder}/{self.csv_filename}"
            )
            os.makedirs(self.local_to_process_dir, exist_ok=True)
            with open(self.local_file_path, "wb") as download_file:
                download_file.write(blob_client.download_blob().readall())
            logging.info(f"Downloaded {self.csv_filename} to {self.local_file_path}.")
        except Exception as e:
            logging.error(f"Error downloading file from Azure: {e}")
            raise

    def read_and_prepare_data(self):
        try:
            # Expected columns mapping
            expected_columns = majesco_billing_mapping.get_mapping(self.table_name)

            # Define data types for each column as object (string)
            dtype_mappings = {col: object for col in expected_columns.keys()}

            # Read the .csv file with parameters to control missing values
            df = pd.read_csv(
                self.local_file_path,
                dtype=dtype_mappings,
                na_values=[''],
                keep_default_na=False  # Disable default NaN handling
            )

            # Verify columns
            missing_columns = [col for col in expected_columns.keys() if col not in df.columns]
            if missing_columns:
                raise Exception(f"Missing columns in the CSV file: {missing_columns}")

            # Rename columns
            df = df.rename(columns=expected_columns)

            # Add 'create_ts' with current date
            df['create_ts'] = datetime.now().strftime('%Y-%m-%d')

            # Reorder columns to match the SQL table
            sql_columns = list(expected_columns.values()) + ['create_ts']
            df = df[sql_columns]

            # List of numeric columns that need to be converted
            numeric_columns = []

            # Handle numeric columns
            for col in numeric_columns:
                df[col] = df[col].replace('', None)
                df[col] = df[col].astype(float).astype(pd.Int64Dtype())

            # Handle float columns
            float_columns = []
            for col in float_columns:
                df[col] = df[col].replace('', None)
                df[col] = df[col].astype(float)

            # Handle datetime columns
            datetime_columns = [
                'create_ts'
            ]
            for col in datetime_columns:
                df[col] = df[col].replace('', None)
                df[col] = pd.to_datetime(df[col], errors='coerce')
                df[col] = df[col].dt.strftime('%Y-%m-%d %H:%M:%S')
                df[col] = df[col].replace('NaT', None)

            logging.info("Data read and prepared successfully.") 
            return df

        except Exception as e:
            logging.error(f"Error reading and preparing data: {e}")
            raise
    
    def insert_data_into_sql_temp_table(self, df):
        try:
            # Create SQLAlchemy engine for inserting data into SQL Server
            mssql_hook = MsSqlHook(mssql_conn_id=self.mssql_conn_id)
            engine = mssql_hook.get_sqlalchemy_engine()

            # Insert dataframe into SQL Server table
            df.to_sql(
                name=self.table_name,
                con=engine,
                schema='edw_stage',
                if_exists='append',
                index=False,
                chunksize=500,
                method='multi'
            )
            logging.info(f"Data inserted into {self.table_name} successfully.")
        except Exception as e:
            logging.error(f"Error inserting data into SQL Server: {e}")
            raise

    def move_local_file(self):
        try:
            processed_file_path = os.path.join(self.local_processed_dir, self.csv_filename)
            os.rename(self.local_file_path, processed_file_path)
            logging.info(f"Moved local file to {processed_file_path}.")
        except Exception as e:
            logging.error(f"Error moving local file: {e}")
            raise

    def move_file_in_azure(self): 
        try:
            source_blob = f"{self.files_folder}/{self.csv_filename}"

            # Generate timestamp
            timestamp = datetime.now().strftime('%Y%m%d%H%M%S')

            # Split the filename into name and extension
            name, ext = os.path.splitext(self.csv_filename)

            # Create new filename with timestamp
            new_filename = f"{name}_{timestamp}{ext}"

            destination_blob = f"{self.archive_folder}/{new_filename}"

            source_blob_client = self.blob_service_client.get_blob_client(
                container=self.container_name,
                blob=source_blob
            )
            destination_blob_client = self.blob_service_client.get_blob_client(
                container=self.container_name,
                blob=destination_blob
            )

            # Start copy operation
            destination_blob_client.start_copy_from_url(source_blob_client.url)
            logging.info(f"Initiated copy of {source_blob} to {destination_blob} in Azure.")

            # Wait for the copy to complete
            while True:
                props = destination_blob_client.get_blob_properties()
                if props.copy.status != 'pending':
                    break
                time.sleep(1)  # Sleep for 1 second before checking again

            if props.copy.status != 'success':
                logging.error(f"Copy failed with status: {props.copy.status}")
                raise Exception(f"Copy failed with status: {props.copy.status}")

            # Delete the source blob
            source_blob_client.delete_blob()
            logging.info(f"Moved file in Azure from {source_blob} to {destination_blob}.")
        except Exception as e:
            logging.error(f"Error moving file in Azure: {e}")
            raise

    def process(self):
        try:
            self.download_file_from_azure()
            df = self.read_and_prepare_data()
            self.insert_data_into_sql_temp_table(df)
            self.move_local_file()
            # self.move_file_in_azure()

            logging.info("Processing completed successfully.")
        except Exception as e:
            logging.error(f"Processing failed: {e}")
            raise

def table_for_csv(file_name):
    """
    Deduce the target table for a given CSV file name.
    """
    # Strip directory & extension, upper‑case for case‑insensitive match
    stem = Path(file_name).stem.upper()

    # Remove an optional leading date (8 digits) plus optional underscore
    stem = re.sub(r"^\d{6,8}_?", "", stem)

    # Try to find a unique phrase match
    for phrase, table in majesco_billing_mapping.PHRASE_TO_TABLE.items():
        if phrase in stem:
            return table

    # No match found
    raise ValueError(f"Unrecognised file type for '{file_name}'")

def process_all_files():
    try:
        # Azure Blob Storage configuration
        wasb_conn_id = 'azure_blob_storage'
        container_name = 'inbound-majesco-billing'
        files_folder = 'Formatted'

        # Create Azure Blob Service Client
        wasb_hook = WasbHook(wasb_conn_id=wasb_conn_id)
        blob_service_client = wasb_hook.get_conn()
        container_client = blob_service_client.get_container_client(container_name)

        # List blobs in the 'files' folder within the container
        blob_list = container_client.list_blobs(name_starts_with=f'{files_folder}/')

        # Filter for .csv files
        # csv_files = [blob.name for blob in blob_list if blob.name.endswith('.csv')]
        csv_files = [blob.name for blob in blob_list if "01242025" in blob.name.lower()]

        if not csv_files:
            logging.info("No .csv files found in the container.")
            return

        # Process each .csv file
        for blob_name in csv_files:
            # Extract the filename from the blob name
            csv_filename = os.path.basename(blob_name)
            
            # Extract the table name from the file name
            table_name = table_for_csv(csv_filename)

            logging.info(f" **** Processing file: {csv_filename} **** ")

            try:
                # Instantiate the processor and process the file
                processor = MajescoBillingProcessor(csv_filename,table_name)
                processor.process()
            except Exception as e:
                logging.error(f"Error processing file {csv_filename}: {e}")
                raise  # Raise the exception to stop processing further files

    except Exception as e:
        logging.error(f"Error in process_all_files: {e}")
        raise


if __name__ == "__main__":
    process_all_files()
    
    #**Manual Execution**
    # processor = MajescoBillingProcessor('01242025_ADJUST WRITEOFF.csv','stage_majesco_adjust_writeoff')
    # processor.process()
