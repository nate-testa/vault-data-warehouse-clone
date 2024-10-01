import os
import time
import pysftp
import pendulum
import pandas as pd
from datetime import datetime, timedelta
from airflow import DAG
from sqlalchemy import create_engine
from airflow.hooks.base_hook import BaseHook
from airflow.hooks.mssql_hook import MsSqlHook
from airflow.operators.email_operator import EmailOperator
from airflow.operators.dummy_operator import DummyOperator
from airflow.operators.python_operator import PythonOperator
from vault_edw_HTML_format import get_sp_error_data_HTML, get_HTML_on_vault_format
from airflow.models import Variable

to_email = "itdatateam@vault.insurance"
# to_email = "alberto.valbuena@vault.insurance"
cc_email = ""

ENVIRONMENT = Variable.get("environment")
HOME_PATH = os.path.expanduser('~')
LOCAL_FOLDER_PATH = HOME_PATH + "/airflow/tmp_files/livevox_reports"

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

    column_mapping = {
        'Client ID':'Client_ID'
        ,'Call Center Name':'Call_Center_Name'
        ,'Call Center_ID':'Call_Center_ID'
        ,'LV Client Name':'LV_Client_Name'
        ,'Service Name':'Service_Name'
        ,'Service Type':'Service_Type'
        ,'Service ID':'Service_ID'
        ,'Transaction Type':'Transaction_Type'
        ,'Answer Type':'Answer_Type'
        ,'Session ID':'Session_ID'
        ,'Transaction ID':'Transaction_ID'
        ,'Phone Dialed':'Phone_Dialed'
        ,'Account Number':'Account_Number'
        ,'Original Account Number':'Original_Account_Number'
        ,'Client Name':'Client_Name'
        ,'first name':'First_name'
        ,'last name':'Last_name'
        ,'CallConnectTimeCT':'CallConnectTimeCT'
        ,'Call End Time':'Call_End_Time'
        ,'Call Duration':'Call_Duration'
        ,'IVR Duration':'IVR_Duration'
        ,'Hold Time':'Hold_Time'
        ,'Transfer Duration':'Transfer_Duration'
        ,'Last Key Pressed':'Last_Key_Pressed'
        ,'Filename':'Filename'
        ,'Agent Logon Id':'Agent_Logon_Id'
        ,'Agent Full Name':'Agent_Full_Name'
        ,'Agent Team':'Agent_Team'
        ,'Talk Time':'Talk_Time'
        ,'Wrap Time':'Wrap_Time'
        ,'Agent Hold Time':'Agent_Hold_Time'
        ,'Livevox Result':'Livevox_Result'
        ,'RESULTCODE':'RESULTCODE'
        ,'RESULTID':'RESULTID'
        ,'Agent Desktop Outcome':'Agent_Desktop_Outcome'
        ,'Result Category':'Result_Category'
        ,'custom outcome 1':'Custom_outcome_1'
        ,'custom outcome 2':'Custom_outcome_2'
        ,'custom outcome 3':'Custom_outcome_3'
        ,'input payment amount':'Input_payment_amount'
        ,'Zip':'Zip'
        ,'Caller ID':'Caller_ID'
        ,'Phone Number':'Phone_Number'
        ,'Campaign Id':'Campaign_Id'
        ,'CampaignType':'CampaignType'
        ,'Call Direction':'Call_Direction'
        ,'Interaction Type':'Interaction_Type'
        ,'AgentSkillName':'AgentSkillName'
        ,'create_ts':'create_ts'
        ,'source_file_name':'source_file_name'
    }

    try:
        # Azure SQL Connection
        mssql_hook = MsSqlHook(mssql_conn_id='Vault_EDW')
        conn = mssql_hook.get_conn()
        
        # Load file into a DataFrame
        df = pd.read_csv(file_path)

        # Add new columns
        df['create_ts'] = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        df['source_file_name'] = file_path.split('/')[-1]

        # Rename columns in dataframe
        df = df.rename(columns=column_mapping)

        # print(f"Number of records in DataFrame: {df.shape[0]}")
        # print(df.describe())
        # print("\nDataFrame statistics:")
        # print(df.describe())
        # print("\nDataFrame info:")
        # print(df.info())

        # Load DF into table
        engine = create_engine(mssql_hook.get_uri())
        df.to_sql('stage_livevox', engine, schema='edw_stage', if_exists='append', index=False)

        print("Data loaded successfully into Azure SQL Server.")

    except Exception as e:
        print("An error occurred:", e)
        raise e

    finally:
        conn.close()

def process_sftp_files():
    """
    Function to process call detail report files from SFTP and load them into EDW.
    """

    if ENVIRONMENT == 'PRODUCTION':

        # Create local folder path
        create_directory_if_not_exists(LOCAL_FOLDER_PATH)

        # vacuum to tmp folder
        delete_old_files(LOCAL_FOLDER_PATH,30)

        # SFTP Connection
        sftp_conn_id = 'Vault_livevox_sftp_reports'
        sftp_hook = BaseHook.get_connection(sftp_conn_id)
        sftp_username = sftp_hook.login
        sftp_password = sftp_hook.password
        sftp_path = '/ftpOut/'

        # Azure SQL Connection
        mssql_hook = MsSqlHook(mssql_conn_id='Vault_EDW')

        # Get the last loaded date
        last_loaded_date = mssql_hook.get_first("SELECT edw_core.fn_get_last_source_extract_ts('py_call_detail_report') as last_loaded_date")[0]
        print(f"*** Last loaded date: {last_loaded_date}")

        # Filter files on SFTP and sort by modification date
        print(f"*** Start Loading Files")
        with pysftp.Connection(sftp_hook.host, username=sftp_username, password=sftp_password) as sftp:
            file_list = sftp.listdir_attr(sftp_path)
            file_list.sort(key=lambda x: x.st_mtime, reverse=False)  # Sort by modification date
            for file_attr in file_list:
                file_name = file_attr.filename
                if 'Vault_Call_Detail_Report_' in file_name and file_name.endswith('.txt'):
                    file_date = datetime.fromtimestamp(file_attr.st_mtime)  # Convert timestamp to datetime
                    if file_date > last_loaded_date:    
                        # Process files and load into Azure SQL
                        print(f">>> Loading File: {file_name}")
                        # Download file
                        local_file_path = f'{LOCAL_FOLDER_PATH}/{file_name}'
                        sftp.get(sftp_path + file_name, local_file_path)

                        # Load file into Azure SQL
                        load_file_into_tbl(local_file_path)

                        # Update date in control table
                        mssql_hook.run(f"UPDATE edw_core.tetl_control SET last_source_extract_ts = '{file_date}' WHERE process_nm = 'py_call_detail_report'")
                        print(f"File Loaded <<<")
    else:
        print(f"**** Environment: [{ENVIRONMENT}] is not authorized to process livevox call_detail_report files.")



args = {
    'owner': 'airflow',
    'retries': 0,
    'retry_delay':timedelta(minutes=1),
    'on_failure_callback': on_failure_callback,
}

with DAG(
    dag_id='vault_livevox_load_call_detail_report',
    catchup=False,
    max_active_runs=1,
    default_args=args,
    start_date=pendulum.datetime(2024, 9, 30, tz="America/New_York"),
    schedule_interval='0 5 * * *', # At 05:00 every day
    # schedule_interval=None,
    tags=["call detail report dag", "vault"],
) as dag:
    

    start = DummyOperator(
        task_id='start',
    )
    
    load_call_detail_report = PythonOperator(
        task_id='load_call_detail_report',
        python_callable=process_sftp_files,
        dag=dag,
    )
 
    end = DummyOperator(
        task_id='end',
    )

start >> load_call_detail_report >> end
