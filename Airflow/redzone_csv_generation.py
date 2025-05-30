from airflow import DAG
from airflow.models import BaseOperator
from airflow.providers.sftp.hooks.sftp import SFTPHook
from airflow.providers.microsoft.mssql.hooks.mssql import MsSqlHook
from datetime import datetime
from airflow.models import Variable
import time
import os

ENVIRONMENT = Variable.get("environment")

def create_directory_if_not_exists(directory_path):
    if not os.path.exists(directory_path):
        os.makedirs(directory_path)
        return f"The directory {directory_path} was created."
    else:
        return f"The directory {directory_path} already exists."

def delete_old_files(folder_path, retention_days=5):
    now = time.time()
    days = retention_days * 24 * 60 * 60

    files_removed = 0
    # List all files in the directory
    for filename in os.listdir(folder_path):
        file_path = os.path.join(folder_path, filename)
        # Check if it's a file and not a directory
        if os.path.isfile(file_path):
            # Check the file's last modified time
            if now - os.path.getmtime(file_path) > days:
                # If it's greater than retention_days parameter, remove it
                os.remove(file_path)
                files_removed += 1

    return files_removed

def generate_redzone_csv_file(**kwargs):

    # Parameters
    CONN_STR = MsSqlHook(mssql_conn_id="Vault_EDW")
    HOME_PATH = os.path.expanduser('~')
    CSV_FOLDER_PATH = HOME_PATH + "/airflow/tmp_files/redzone"
    CSV_DATE = datetime.now().strftime('%Y%m%d')
    CSV_FILE_NAME = f'Redzone-{CSV_DATE}.profile.csv'
    # CSV_FILE_NAME = f'TEST_Redzone-{CSV_DATE}.profile.csv'
    QRY = f"""
            SELECT 
                [unique_id] AS unique_id,
                [policy_id] AS policy_id,
                [policy_type] AS policy_type,
                [latitude] AS latitude,
                [longitude] AS longitude,
                [address] AS address,
                [city] AS city,
                [county] AS county,
                [state] AS state,
                [zip] AS zip,
                [tiv] AS tiv,
                [insured_name] AS insured_name,
                [insured_phone] AS insured_phone,
                [insured_email] AS insured_email,
                [broker_id] AS broker_id,
                [broker_name] AS broker_name,
                [broker_phone] AS broker_phone,
                [broker_email] AS broker_email,
                [coverage_a] AS coverage_a,
                [coverage_b] AS coverage_b,
                [coverage_c] AS coverage_c,
                [coverage_d] AS coverage_d,
                [gate_code] AS gate_code,
                [effective_dt],
                [new_business_underwriter_nm],
                [renewal_underwriter_nm],
                [bdm_nm],
                wildfire_protection_enrollment_in,
                site_scheduling_contact_nm,
                site_scheduling_phone_no,
                site_scheduling_email,
                emergency_contact_nm,
                emergency_contact_phone_no,
                emergency_contact_email,
                gate_entry_code_required_in
            FROM [edw_integration].[policy_redzone_feed]
            """

    df = CONN_STR.get_pandas_df(QRY)
    create_directory_if_not_exists(CSV_FOLDER_PATH)
    csv_path = os.path.join(CSV_FOLDER_PATH, CSV_FILE_NAME)
    df.to_csv(csv_path, index=False)

    # vacum to tmp folder
    delete_old_files(CSV_FOLDER_PATH,2)

    # set xcom parameters
    csv_local_redzone_file_name = os.path.join(CSV_FOLDER_PATH, CSV_FILE_NAME)
    csv_remote_redzone_file_name = f'/incoming/{CSV_FILE_NAME}'

    kwargs['ti'].xcom_push(key='csv_local_redzone_file_name', value=csv_local_redzone_file_name)
    kwargs['ti'].xcom_push(key='csv_remote_redzone_file_name', value=csv_remote_redzone_file_name)

    print(f"**** Data written to {csv_path}")


class SFTPUploadredzoneOperator(BaseOperator):

    def __init__(self, sftp_conn_id, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.sftp_conn_id = sftp_conn_id

    def execute(self, context):
        if ENVIRONMENT == 'PRODUCTION':
            local_filepath = context['ti'].xcom_pull(task_ids='redzone_group.generate_redzone_csv', key='csv_local_redzone_file_name')
            remote_filepath = context['ti'].xcom_pull(task_ids='redzone_group.generate_redzone_csv', key='csv_remote_redzone_file_name')
            
            hook = SFTPHook(ftp_conn_id=self.sftp_conn_id)
            self.log.info(f"**** Starting to transfer {local_filepath} to {remote_filepath}")
            hook.store_file(remote_filepath, local_filepath)
            self.log.info(f"**** Finished transferring {local_filepath} to {remote_filepath}")
        else:
            print(f"**** Environment: [{ENVIRONMENT}] is not authorized to send redzone files.")

            
