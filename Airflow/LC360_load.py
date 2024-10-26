import os
import json
import time
import pendulum
import paramiko
import logging
from datetime import datetime, timedelta
from airflow import DAG
from airflow.models import Variable
from airflow.hooks.base_hook import BaseHook
from airflow.hooks.mssql_hook import MsSqlHook
from airflow.providers.sftp.hooks.sftp import SFTPHook
from airflow.operators.email_operator import EmailOperator
from airflow.operators.dummy_operator import DummyOperator
from airflow.operators.python_operator import PythonOperator
from vault_edw_HTML_format import get_sp_error_data_HTML, get_HTML_on_vault_format

# to_email = "itdatateam@vault.insurance"
to_email = "alberto.valbuena@vault.insurance"
cc_email = ""

ENVIRONMENT = Variable.get("environment")
HOME_PATH = os.path.expanduser('~')
LOCAL_FOLDER_PATH = HOME_PATH + "/airflow/tmp_files/lc360"

def create_directory_if_not_exists(directory_path):
    if not os.path.exists(directory_path):
        os.makedirs(directory_path)
        return f"The directory {directory_path} was created."
    else:
        return f"The directory {directory_path} already exists."


def delete_old_files(folder_path, retention_days=30):
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


def on_failure_callback(context):

    task_instance = context['task_instance']
    error_info = str(context.get('exception'))
    task_type = task_instance.task.__class__.__name__
    html_content_body = ''
    
    if task_type == "MsSqlOperator":
        task_name = task_instance.task_id
        sp_name = []
        # extract only the task name (remove the TaskGroup Name)
        if task_name.rfind('.') != -1:
            sp_name.append(task_name[task_name.rfind('.') + 1:])
        else:
            sp_name.append(task_instance.task_id)
        html_content_body = get_sp_error_data_HTML(sp_name, f"Task: {task_instance.task_id}<br><br>Error Description: {error_info}")
    else:
        html_content_body = get_HTML_on_vault_format(f"Task: {task_instance.task_id}<br><br>Error Description: {error_info}",'')
    
    email = EmailOperator(
        task_id='send_email_on_failure',
        to=to_email,
        subject=f"Airflow - Error on Task: {task_instance.task_id} - DAG: {task_instance.dag_id}",
        html_content=html_content_body
    )
    email.execute(context)

def load_file_into_tbl(file_path):

    try:
        # Azure SQL Connection
        mssql_hook = MsSqlHook(mssql_conn_id='Vault_EDW')
        conn = mssql_hook.get_conn()
        
        # Load json file
        with open(file_path, "r") as f:
            json_file = f.read()

        # Generate columns
        json_data = json.loads(json_file)
        policy_number = json_data.get("PolicyNumber")
        source_file_name = file_path.split('/')[-1]

        # Insert row
        query = f"INSERT INTO edw_stage.stage_lc360 (policy_no, inspection_data, created_ts, source_file_name) VALUES (%s, %s, GETDATE(), %s)"
        mssql_hook.run(query, parameters=(policy_number, json.dumps(json_data), source_file_name))

        print("Data loaded successfully into Azure SQL Server.")

    except Exception as e:
        print("An error occurred:", e)
        raise e

    finally:
        conn.close()

def get_files_to_download(sftp_conn_id, sftp_path, last_loaded_date):
    """
    Get a list of files to download from the SFTP server.
    """
    # Create SFTPHook
    sftp_hook = SFTPHook(ftp_conn_id=sftp_conn_id)

    # Establish SFTP connection
    with sftp_hook.get_conn() as sftp:
        file_list = sftp.listdir_attr(sftp_path)
        file_list.sort(key=lambda x: x.st_mtime, reverse=False)  # Sort by modification date

        files_to_download = []
        for file_attr in file_list:
            file_name = file_attr.filename
            if file_name.endswith('.json'):
                file_date = datetime.fromtimestamp(file_attr.st_mtime)
                if file_date > last_loaded_date:
                    files_to_download.append((file_name, file_date))

    sftp_hook.close_conn()

    return files_to_download

def download_file_from_sftp(sftp_conn_name, remote_filepath, local_filepath, block_size=4096):
    """
    Download a file from SFTP server.
    """

     # Create SFTPHook
    sftp_hook = BaseHook.get_connection(sftp_conn_name)
    sftp_host = sftp_hook.host
    sftp_port = sftp_hook.port
    sftp_username = sftp_hook.login
    sftp_password = sftp_hook.password

    # Connect to SFTP server
    transport = paramiko.Transport((sftp_host, sftp_port))
    transport.connect(username=sftp_username, password=sftp_password)
    sftp = paramiko.SFTPClient.from_transport(transport)

    # Get remote file size
    remote_file_size = sftp.stat(remote_filepath).st_size

    # Download file in blocks
    with sftp.file(remote_filepath, 'r') as remote_file, open(local_filepath, 'wb') as local_file:
        bytes_downloaded = 0
        while True:
            block = remote_file.read(block_size)
            if not block:
                break
            local_file.write(block)
            bytes_downloaded += len(block)
            # print(f"Downloaded {bytes_downloaded} bytes of {remote_file_size} bytes")

    # Close SFTP connection
    sftp.close()
    transport.close()

def process_sftp_files():
    """
    Function to process LC360 files from SFTP and load them into EDW.
    """
    # Create local folder path
    create_directory_if_not_exists(LOCAL_FOLDER_PATH)

    # vacuum to tmp folder
    delete_old_files(LOCAL_FOLDER_PATH, 5)

    # SFTP Connection id
    sftp_conn_id = 'Vault_LC360_sftp'

    if ENVIRONMENT != 'PRODUCTION':
        sftp_path = '/Vault/PROD/Export/'
    else:
        sftp_path = '/Vault/UAT/Export/'

    # Azure SQL Connection
    mssql_hook = MsSqlHook(mssql_conn_id='Vault_EDW')

    # Get the last loaded date
    last_loaded_date = mssql_hook.get_first("SELECT edw_core.fn_get_last_source_extract_ts('py_lc360_file') as last_loaded_date")[0]
    print(f"*** Last loaded date: {last_loaded_date}")

    # Filter files on SFTP and sort by modification date
    print(f"*** Start Processing Files")
    
    # Get files to download
    files_to_download = get_files_to_download(sftp_conn_id, sftp_path, last_loaded_date)
    
    # Download and process files
    for file_name, file_date in files_to_download:
        # Download file
        remote_file_path = f'{sftp_path}/{file_name}'
        local_file_path = f'{LOCAL_FOLDER_PATH}/{file_name}'
        print(f">>> Processing File: {file_name}")
        print(f"*Downloading file from SFTP: {remote_file_path}")
        download_file_from_sftp(sftp_conn_id, remote_file_path, local_file_path)
        
        # Load file into Azure SQL
        print(f"*Loading file into EDW table")
        load_file_into_tbl(local_file_path)
        
        # Update date in control table
        mssql_hook.run(f"UPDATE edw_core.tetl_control SET last_source_extract_ts = '{file_date}' WHERE process_nm = 'py_lc360_file'")
        print(f"File Processed <<<")


args = {
    'owner': 'airflow',
    'retries': 0,
    'retry_delay':timedelta(minutes=1),
    'on_failure_callback': on_failure_callback,
}

with DAG(
    dag_id='vault_load_LC360_files',
    catchup=False,
    max_active_runs=1,
    default_args=args,
    start_date=pendulum.datetime(2024, 4, 15, tz="America/New_York"),
    # schedule_interval='0 4 * * *', # At 04:00 every day
    schedule_interval=None,
    tags=["lc360 dag", "vault"],
) as dag:
    

    start = DummyOperator(
        task_id='start',
    )
    
    load_lc360_files = PythonOperator(
        task_id='load_lc360_files',
        python_callable=process_sftp_files,
        dag=dag,
    )
 
    end = DummyOperator(
        task_id='end',
    )

start >> load_lc360_files >> end
