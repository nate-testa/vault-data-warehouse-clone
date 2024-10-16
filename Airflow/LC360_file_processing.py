import os
import logging
import pandas as pd
import time
from datetime import datetime
from airflow.providers.microsoft.mssql.hooks.mssql import MsSqlHook
from airflow.providers.microsoft.azure.hooks.wasb import WasbHook
from airflow.models import Variable

ENVIRONMENT = Variable.get("environment")
HOME_PATH = os.path.expanduser('~')


# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

class LC360Processor:
    def __init__(self, xls_filename):
        # File and directory configurations
        self.xls_filename = xls_filename
        self.container_name = 'inbound-inspection-manual'
        self.files_folder = 'files'
        self.archive_folder = 'archive'
        self.local_to_process_dir = HOME_PATH + '/airflow/tmp_files/lc360/to_process'
        self.local_processed_dir = HOME_PATH + '/airflow/tmp_files/lc360/processed_files'
        self.local_file_path = os.path.join(self.local_to_process_dir, self.xls_filename)

        # Airflow connection IDs
        self.wasb_conn_id = 'azure_blob_storage'
        self.mssql_conn_id = 'Vault_EDW'

        # Initialize connections
        self.create_blob_service_client()

    def create_blob_service_client(self):
        wasb_hook = WasbHook(wasb_conn_id=self.wasb_conn_id)
        self.blob_service_client = wasb_hook.get_conn()
        logging.info("Connected to Azure Blob Storage.")

    def get_new_connection(self):
        mssql_hook = MsSqlHook(mssql_conn_id=self.mssql_conn_id)
        return mssql_hook.get_conn()

    def download_file_from_azure(self):
        try:
            blob_client = self.blob_service_client.get_blob_client(
                container=self.container_name,
                blob=f"{self.files_folder}/{self.xls_filename}"
            )
            os.makedirs(self.local_to_process_dir, exist_ok=True)
            with open(self.local_file_path, "wb") as download_file:
                download_file.write(blob_client.download_blob().readall())
            logging.info(f"Downloaded {self.xls_filename} to {self.local_file_path}.")
        except Exception as e:
            logging.error(f"Error downloading file from Azure: {e}")
            raise

    def read_and_prepare_data(self):
        try:
            # Expected columns mapping
            expected_columns = {
                'Inspection #': 'inspectionNumber',
                'Policy Number': 'policyNumber',
                'Status': 'status',
                'Inspection Type': 'inspectionType',
                'QA Representative': 'QARepresentative',
                'First Time QA Complete': 'firstTimeQAComplete_dt',
                'Received': 'received_dt',
                'First Field Complete': 'firstFieldComplete_dt',
                'Completed': 'completed_dt',
                'Policy Holder First Name': 'policyHolderFirstName',
                'Policy Holder Last Name': 'policyHolderLastName',
                ' VIP': 'VIP',
                'Effective Date': 'effective_dt',
                'Coverage A In': 'covA_in',
                'Coverage A Out': 'covA_out',
                'Cov. A Diff': 'covA_diff',
                'Coverage B': 'covB',
                'Is Duplicate': 'isDuplicate',
                'Total Account Premium': 'totalAccountPremium',
                'Location Street': 'locationStreet',
                'Location City': 'locationCity',
                'Location State': 'locationState',
                'Location Zip': 'locationZip',
                'Underwriter': 'underwriter',
                'Agency': 'agency',
                'Consultant': 'consultant',
                'Ordered By': 'orderedBy',
                'Inspection Due': 'inspectionDue_dt'
            }

            # Define data types for each column as object (string)
            dtype_mappings = {col: object for col in expected_columns.keys()}

            # Read the .xls file with parameters to control missing values
            df = pd.read_excel(
                self.local_file_path,
                dtype=dtype_mappings,
                na_values=[''],
                keep_default_na=False  # Disable default NaN handling
            )

            # Verify columns
            missing_columns = [col for col in expected_columns.keys() if col not in df.columns]
            if missing_columns:
                raise Exception(f"Missing columns in the Excel file: {missing_columns}")

            # Rename columns
            df = df.rename(columns=expected_columns)

            # Add 'inspection_update_dt' with current date
            df['inspection_update_dt'] = datetime.now().strftime('%Y-%m-%d')

            # Reorder columns to match the SQL table
            sql_columns = [
                'inspection_update_dt',
                'inspectionNumber',
                'policyNumber',
                'status',
                'inspectionType',
                'QARepresentative',
                'firstTimeQAComplete_dt',
                'received_dt',
                'firstFieldComplete_dt',
                'completed_dt',
                'policyHolderFirstName',
                'policyHolderLastName',
                'VIP',
                'effective_dt',
                'covA_in',
                'covA_out',
                'covA_diff',
                'covB',
                'isDuplicate',
                'totalAccountPremium',
                'locationStreet',
                'locationCity',
                'locationState',
                'locationZip',
                'underwriter',
                'agency',
                'consultant',
                'orderedBy',
                'inspectionDue_dt'
            ]
            df = df[sql_columns]

            # Replace True with 1, False with 0 in 'VIP' column
            df['VIP'] = df['VIP'].replace({'True': '1', 'False': '0'})

            # List of numeric columns that need to be converted
            numeric_columns = ['inspectionNumber', 'covA_in', 'covA_out', 'covA_diff', 'covB', 'locationZip']

            # Handle numeric columns
            for col in numeric_columns:
                df[col] = df[col].replace('', None)
                df[col] = df[col].astype(float).astype(pd.Int64Dtype())

            # Handle float columns
            float_columns = ['totalAccountPremium']
            for col in float_columns:
                df[col] = df[col].replace('', None)
                df[col] = df[col].astype(float)

            # Handle datetime columns
            datetime_columns = [
                'firstTimeQAComplete_dt', 'received_dt', 'firstFieldComplete_dt',
                'completed_dt', 'effective_dt', 'inspectionDue_dt'
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
            # Truncate the table first using the Airflow connection
            with self.get_new_connection() as connection:
                with connection.cursor() as cursor:
                    truncate_sql = "TRUNCATE TABLE edw_cat_model.lc360_temp_table"
                    cursor.execute(truncate_sql)
                    connection.commit()
                    logging.info("Table 'edw_cat_model.lc360_temp_table' truncated successfully.")

            # Create SQLAlchemy engine for inserting data into SQL Server
            mssql_hook = MsSqlHook(mssql_conn_id=self.mssql_conn_id)
            engine = mssql_hook.get_sqlalchemy_engine()

            # Insert dataframe into SQL Server table 'edw_cat_model.lc360_temp_table'
            df.to_sql(
                name='lc360_temp_table',
                con=engine,
                schema='edw_cat_model',
                if_exists='append',
                index=False,
                chunksize=500,
                method='multi'
            )
            logging.info("Data inserted into 'edw_cat_model.lc360_temp_table' successfully.")
        except Exception as e:
            logging.error(f"Error inserting data into SQL Server: {e}")
            raise

    def delete_existing_records(self):
        try:
            with self.get_new_connection() as connection:
                with connection.cursor() as cursor:
                    # Get today's date in the format used in inspection_update_dt
                    today_date_str = datetime.now().strftime('%Y-%m-%d')

                    # Delete from Insp_LC360_historical
                    delete_historical_sql = f"""
                        DELETE FROM edw_cat_model.Insp_LC360_historical
                        WHERE inspection_update_dt = '{today_date_str}'
                    """
                    cursor.execute(delete_historical_sql)
                    connection.commit()
                    logging.info(f"Deleted existing records from 'Insp_LC360_historical' for date {today_date_str}.")

                    # Delete from Insp_LC360_cleaned
                    delete_cleaned_sql = f"""
                        DELETE FROM edw_cat_model.Insp_LC360_cleaned
                        WHERE inspection_update_dt = '{today_date_str}'
                    """
                    cursor.execute(delete_cleaned_sql)
                    connection.commit()
                    logging.info(f"Deleted existing records from 'Insp_LC360_cleaned' for date {today_date_str}.")

        except Exception as e:
            logging.error(f"Error deleting existing records: {e}")
            raise

    def insert_historical_data(self):
        try:
            with self.get_new_connection() as connection:
                with connection.cursor() as cursor:
                    insert_historical_sql = """
                        INSERT INTO edw_cat_model.Insp_LC360_historical
                        SELECT * FROM edw_cat_model.lc360_temp_table
                    """
                    cursor.execute(insert_historical_sql)
                    connection.commit()
                    logging.info(f"Data inserted into 'Insp_LC360_historical' successfully. Rows affected: {cursor.rowcount}")
        except Exception as e:
            logging.error(f"Error inserting historical data into table Insp_LC360_historical: {e}")
            raise

    def check_historical_data_count(self):
        try:
            with self.get_new_connection() as connection:
                with connection.cursor() as cursor:
                    count_historical_sql = """
                        SELECT inspection_update_dt, COUNT(*) AS historical
                        FROM edw_cat_model.Insp_LC360_historical ilh
                        GROUP BY inspection_update_dt
                        ORDER BY inspection_update_dt DESC
                    """
                    cursor.execute(count_historical_sql)
                    historical_counts = cursor.fetchall()
                    logging.info("Historical data counts retrieved:")
                    for row in historical_counts:
                        logging.info(f"Date: {row[0]}, Count: {row[1]}")
        except Exception as e:
            logging.error(f"Error checking historical data count: {e}")
            raise

    def insert_historical_into_cleaned(self):
        try:
            with self.get_new_connection() as connection:
                with connection.cursor() as cursor:
                    insert_cleaned_sql = """
                        WITH 
                        latest_inspection_data_set AS (
                            SELECT LEFT(policynumber, CHARINDEX('-', policynumber + '-') - 1) AS base_policy_no, h.* 
                            FROM edw_cat_model.Insp_LC360_historical h
                            WHERE inspection_update_dt = (SELECT MAX(inspection_update_dt) FROM edw_cat_model.Insp_LC360_historical)
                        ),
                        latest_transaction_is_cancel AS (
                            SELECT * 
                            FROM (
                                SELECT DISTINCT 
                                    LAST_VALUE(inspectionNumber) OVER (
                                        PARTITION BY base_policy_no 
                                        ORDER BY completed_dt, inspectionDue_dt 
                                        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
                                    ) AS inspection_no,
                                    LAST_VALUE(inspectionType) OVER (
                                        PARTITION BY base_policy_no 
                                        ORDER BY completed_dt, inspectionDue_dt 
                                        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
                                    ) AS inspection_type
                                FROM latest_inspection_data_set
                            ) a 
                            WHERE a.inspection_type = 'Cancellation'	
                        ),
                        remove_cancels AS (
                            SELECT a.*
                            FROM latest_inspection_data_set a 
                            LEFT JOIN latest_transaction_is_cancel b ON a.inspectionNumber = b.inspection_no
                            WHERE b.inspection_no IS NULL 
                        ),
                        find_latest AS (
                            SELECT DISTINCT 
                                inspection_update_dt, 
                                base_policy_no AS basepolnum,
                                LAST_VALUE(inspectionNumber) OVER (
                                    PARTITION BY base_policy_no 
                                    ORDER BY completed_dt, inspectionDue_dt 
                                    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
                                ) AS inspection_no,
                                LAST_VALUE(inspectionType) OVER (
                                    PARTITION BY base_policy_no 
                                    ORDER BY completed_dt, inspectionDue_dt 
                                    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
                                ) AS inspection_type,
                                LAST_VALUE(status) OVER (
                                    PARTITION BY base_policy_no 
                                    ORDER BY completed_dt, inspectionDue_dt 
                                    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
                                ) AS inspection_status,
                                LAST_VALUE(completed_dt) OVER (
                                    PARTITION BY base_policy_no 
                                    ORDER BY completed_dt, inspectionDue_dt 
                                    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
                                ) AS inspection_completed_dt
                            FROM remove_cancels
                        )
                        INSERT INTO edw_cat_model.Insp_LC360_cleaned (
                            inspection_update_dt, basepolnum, inspection_no, inspection_type, inspection_status, inspection_completed_dt
                        ) 
                        SELECT 
                            inspection_update_dt, 
                            basepolnum, 
                            inspection_no, 
                            inspection_type, 
                            CASE 
                                WHEN inspection_type = 'Cancellation' AND inspection_status = 'Complete' THEN 'Cancelled' 
                                ELSE inspection_status 
                            END AS inspection_status, 
                            inspection_completed_dt
                        FROM find_latest
                    """
                    cursor.execute(insert_cleaned_sql)
                    connection.commit()
                    logging.info(f"Data inserted into 'Insp_LC360_cleaned' successfully. Rows affected: {cursor.rowcount}")
        except Exception as e:
            logging.error(f"Error inserting historical data into cleaned table: {e}")
            raise

    def compare_historical_to_cleaned(self):
            try:
                with self.get_new_connection() as connection:
                    with connection.cursor() as cursor:
                        compare_sql = """
                            WITH 
                            historical AS (
                                SELECT inspection_update_dt, COUNT(*) AS historical
                                FROM edw_cat_model.Insp_LC360_historical ilh 
                                GROUP BY inspection_update_dt 
                            ), 
                            cleaned AS (
                                SELECT inspection_update_dt, COUNT(*) AS cleaned
                                FROM edw_cat_model.Insp_LC360_cleaned ilh  
                                GROUP BY inspection_update_dt 
                            ) 
                            SELECT h.inspection_update_dt, h.historical, c.cleaned, h.historical - c.cleaned AS removed
                            FROM historical h 
                            LEFT JOIN cleaned c ON h.inspection_update_dt = c.inspection_update_dt
                            ORDER BY h.inspection_update_dt DESC
                        """
                        cursor.execute(compare_sql)
                        compare_results = cursor.fetchall()
                        logging.info("Comparison between historical and cleaned data:")
                        for row in compare_results:
                            logging.info(f"Date: {row[0]}, Historical: {row[1]}, Cleaned: {row[2]}, Removed: {row[3]}")
            except Exception as e:
                logging.error(f"Error comparing historical to cleaned data: {e}")
                raise

    def sanity_check_inspection_status(self):
        try:
            with self.get_new_connection() as connection:
                with connection.cursor() as cursor:
                    sanity_check_sql = """
                        WITH 
                        insp_new AS (
                            SELECT * 
                            FROM edw_cat_model.Insp_LC360_cleaned ilc 
                            WHERE inspection_update_dt = (SELECT MAX(inspection_update_dt) FROM edw_cat_model.Insp_LC360_cleaned)
                        ),
                        insp_prior AS (
                            SELECT * 
                            FROM edw_cat_model.Insp_LC360_cleaned ilc 
                            WHERE inspection_update_dt = (
                                SELECT MAX(inspection_update_dt) FROM edw_cat_model.Insp_LC360_cleaned
                                WHERE inspection_update_dt <> (SELECT MAX(inspection_update_dt) FROM edw_cat_model.Insp_LC360_cleaned)
                            )
                        )
                        SELECT 
                            C.basepolnum,
                            C.inspection_update_dt, C.inspection_status, C.inspection_completed_dt, 	
                            B.inspection_update_dt, B.inspection_status, B.inspection_completed_dt
                        FROM insp_prior C
                        LEFT JOIN insp_new B ON C.basepolnum = B.basepolnum
                        WHERE C.inspection_status <> B.inspection_status
                        ORDER BY C.inspection_status, B.inspection_status
                    """
                    cursor.execute(sanity_check_sql)
                    sanity_check_results = cursor.fetchall()
                    logging.info("Sanity check results:")
                    for row in sanity_check_results:
                        logging.info(f"Base Policy: {row[0]}, Prior Date: {row[1]}, Prior Status: {row[2]}, Prior Completed: {row[3]}, "
                                    f"New Date: {row[4]}, New Status: {row[5]}, New Completed: {row[6]}")
        except Exception as e:
            logging.error(f"Error performing sanity check on inspection status: {e}")
            raise

    def move_local_file(self):
        try:
            processed_file_path = os.path.join(self.local_processed_dir, self.xls_filename)
            os.rename(self.local_file_path, processed_file_path)
            logging.info(f"Moved local file to {processed_file_path}.")
        except Exception as e:
            logging.error(f"Error moving local file: {e}")
            raise

    def move_file_in_azure(self): 
        try:
            source_blob = f"{self.files_folder}/{self.xls_filename}"

            # Generate timestamp
            timestamp = datetime.now().strftime('%Y%m%d%H%M%S')

            # Split the filename into name and extension
            name, ext = os.path.splitext(self.xls_filename)

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
            self.delete_existing_records()
            self.insert_historical_data()
            self.check_historical_data_count()
            self.insert_historical_into_cleaned()
            self.compare_historical_to_cleaned()
            self.sanity_check_inspection_status()
            self.move_local_file()
            self.move_file_in_azure()

            logging.info("Processing completed successfully.")
        except Exception as e:
            logging.error(f"Processing failed: {e}")
            raise


def process_all_files():
    try:
        # Azure Blob Storage configuration
        wasb_conn_id = 'azure_blob_storage'
        container_name = 'inbound-inspection-manual'
        files_folder = 'files'

        # Create Azure Blob Service Client
        wasb_hook = WasbHook(wasb_conn_id=wasb_conn_id)
        blob_service_client = wasb_hook.get_conn()
        container_client = blob_service_client.get_container_client(container_name)

        # List blobs in the 'files' folder within the container
        blob_list = container_client.list_blobs(name_starts_with=f'{files_folder}/')

        # Filter for .xlsx files
        xlsx_files = [blob.name for blob in blob_list if blob.name.endswith('.xlsx')]

        if not xlsx_files:
            logging.info("No .xlsx files found in the container.")
            return

        # Process each .xlsx file
        for blob_name in xlsx_files:
            # Extract the filename from the blob name
            xls_filename = os.path.basename(blob_name)

            logging.info(f" **** Processing file: {xls_filename} **** ")

            try:
                # Instantiate the processor and process the file
                processor = LC360Processor(xls_filename)
                processor.process()
            except Exception as e:
                logging.error(f"Error processing file {xls_filename}: {e}")
                raise  # Raise the exception to stop processing further files

    except Exception as e:
        logging.error(f"Error in process_all_files: {e}")
        raise


if __name__ == "__main__":
    process_all_files()
    
    #**Manual Execution**
    # processor = LC360Processor('LC360.ESRI.9.4.24.xlsx')
    # processor.process()
