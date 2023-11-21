from airflow import DAG
from airflow.models import BaseOperator
from airflow.providers.sftp.hooks.sftp import SFTPHook
from airflow.providers.microsoft.mssql.hooks.mssql import MsSqlHook
from datetime import datetime
from airflow.models import Variable
import pandas as pd
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

def generate_livevox_csv_file(**kwargs):

    if ENVIRONMENT == 'PRODUCTION':

        # Parameters
        CONN_STR = MsSqlHook(mssql_conn_id="Vault_EDW")
        HOME_PATH = os.path.expanduser('~')
        CSV_FOLDER_PATH = HOME_PATH + "/airflow/tmp_files/livevox"
        CSV_DATE = datetime.now().strftime('%Y%m%d')
        CSV_FILE_NAME = f'Vault_Contacts_{CSV_DATE}.csv'
        # CSV_FILE_NAME = f'TEST_Vau_Cont_{CSV_DATE}.csv'
        QRY = f"""
                SELECT 
                    [ID] as 'ID',
                    [Address_1] as 'Address 1',
                    [Address_2] as 'Address 2',
                    [City] as 'City',
                    [State] as 'State',
                    [Zip_Code] as 'Zip/Postal Code',
                    [Do_Not_Contact] as 'Do Not Contact',
                    [Email_Address] as 'Email Address',
                    [First_Name] as 'First Name',
                    [Last_Name] as 'Last Name',
                    [DOB] as 'DOB',
                    [Payment_Balance] as 'Payment Balance',
                    [Phone_1] as 'Phone 1',
                    [Phone_1_SMS_Consent] as 'Phone 1 SMS Consent',
                    [Phone_2] as 'Phone 2',
                    [Phone_2_SMS_Consent] as 'Phone 2 SMS Consent',
                    [Email_Consent] as 'Email Consent',
                    [SMS] as 'SMS',
                    [Legal_Entity_Name] as 'Legal Entity Name',
                    [Brokerage_Type] as 'Brokerage Type',
                    [Broker_Name_Agent_Name] as 'Broker Name Agent Name',
                    [Broker_Title_Status] as 'Broker Title (Status)',
                    [Broker_Phone] as 'Broker Phone', 
                    [Broker_Email] as 'Broker Email',
                    [VIP] as 'VIP',
                    [Policy_1] as 'Policy 1',
                    [Location_1] as 'Location 1',
                    [Effective_Date_1] as 'Effective Date 1',
                    [Expiration_Date_1] as 'Expiration Date 1',
                    [Status_1] as 'Status 1',
                    [Agency_Code_1] as 'Agency Code 1',
                    [Legal_Entity_Name_1] as 'Legal Entity Name 1',
                    [Policy_2] as 'Policy 2',
                    [Location_2] as 'Location 2',
                    [Effective_Date_2] as 'Effective Date 2',
                    [Expiration_Date_2] as 'Expiration Date 2',
                    [Status_2] as 'Status 2',
                    [Agency_Code_2] as 'Agency Code 2',
                    [Legal_Entity_Name_2] as 'Legal Entity Name 2',
                    [Policy_3] as 'Policy 3',
                    [Location_3] as 'Location 3',
                    [Effective_Date_3] as 'Effective Date 3',
                    [Expiration_Date_3] as 'Expiration Date 3',
                    [Status_3] as 'Status 3',
                    [Agency_Code_3] as 'Agency Code 3',
                    [Legal_Entity_Name_3] as 'Legal Entity Name 3',
                    [Policy_4] as 'Policy 4',
                    [Location_4] as 'Location 4',
                    [Effective_Date_4] as 'Effective Date 4',
                    [Expiration_Date_4] as 'Expiration Date 4',
                    [Status_4] as 'Status 4',
                    [Agency_Code_4] as 'Agency Code 4',
                    [Legal_Entity_Name_4] as 'Legal Entity Name 4',
                    [Contact_Type] as 'Contact Type'
                FROM [edw_integration].[customer_broker_livevox_feed]
                """

        df = CONN_STR.get_pandas_df(QRY)
        create_directory_if_not_exists(CSV_FOLDER_PATH)
        csv_path = os.path.join(CSV_FOLDER_PATH, CSV_FILE_NAME)
        df.to_csv(csv_path, index=False)

        # vacum to tmp folder
        delete_old_files(CSV_FOLDER_PATH,2)

        # set xcom parameters
        csv_local_livevox_file_name = os.path.join(CSV_FOLDER_PATH, CSV_FILE_NAME)
        csv_remote_livevox_file_name = f'/contactImport/{CSV_FILE_NAME}'

        kwargs['ti'].xcom_push(key='csv_local_livevox_file_name', value=csv_local_livevox_file_name)
        kwargs['ti'].xcom_push(key='csv_remote_livevox_file_name', value=csv_remote_livevox_file_name)

        print(f"**** Data written to {csv_path}")
    
    else:
        print(f"**** Environment: [{ENVIRONMENT}] is not authorized to generate LiveVox files.")

class SFTPUploadLiveVoxOperator(BaseOperator):

    def __init__(self, sftp_conn_id, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.sftp_conn_id = sftp_conn_id

    def execute(self, context):
        if ENVIRONMENT == 'PRODUCTION':
            local_filepath = context['ti'].xcom_pull(task_ids='integration_group.generate_livevox_file', key='csv_local_livevox_file_name')
            remote_filepath = context['ti'].xcom_pull(task_ids='integration_group.generate_livevox_file', key='csv_remote_livevox_file_name')
            
            hook = SFTPHook(ftp_conn_id=self.sftp_conn_id)
            self.log.info(f"**** Starting to transfer {local_filepath} to {remote_filepath}")
            hook.store_file(remote_filepath, local_filepath)
            self.log.info(f"**** Finished transferring {local_filepath} to {remote_filepath}")
        else:
            print(f"**** Environment: [{ENVIRONMENT}] is not authorized to send LiveVox files.")

            
