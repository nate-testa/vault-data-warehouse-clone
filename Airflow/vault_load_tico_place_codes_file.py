import os
import pendulum
import pandas as pd
import requests
from datetime import datetime, timedelta
from airflow import DAG
from sqlalchemy import create_engine
from airflow.hooks.mssql_hook import MsSqlHook
from airflow.operators.email_operator import EmailOperator
from airflow.operators.dummy_operator import DummyOperator
from airflow.operators.python_operator import PythonOperator
from vault_edw_HTML_format import get_sp_error_data_HTML, get_HTML_on_vault_format

to_email = "itdatateam@vault.insurance"
# to_email = "alberto.valbuena@vault.insurance"

HOME_PATH = os.path.expanduser('~')
LOCAL_FOLDER_PATH = HOME_PATH + "/airflow/tmp_files/ticostat"

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

def download_place_codes_file():
    url = "https://www.ticostat.com/ResiDocs/PlaceWeb.csv"
    save_path = LOCAL_FOLDER_PATH + "/PlaceWeb.csv"
    
    try:
        response = requests.get(url)
        response.raise_for_status()  # Check for any errors during download

        with open(save_path, "wb") as file:
            file.write(response.content)
        
        print(f"The file has been downloaded successfully to '{save_path}'.")

    except requests.exceptions.RequestException as e:
        print(f"An error occurred while downloading the file: {e}")

def load_file_into_tbl():
    
    file_path = LOCAL_FOLDER_PATH + "/PlaceWeb.csv"

    column_mapping = {
        'Community':'Community'
        ,'Place Code':'Place_Code'
        ,'County':'County'
        ,'Tdi No.':'Tdi_no'
        ,'Zone':'Zone'
        ,'Terr':'Terr'
        ,'Zip Code ':'Zip_Code'
        ,'create_ts':'create_ts'
    }

    try:
        # Azure SQL Connection
        mssql_hook = MsSqlHook(mssql_conn_id='Vault_EDW')
        conn = mssql_hook.get_conn()
        
        # Load file into a DataFrame
        df = pd.read_csv(file_path)

        # Delete 'Unnamed' columns
        df = df.loc[:, ~df.columns.str.contains('^Unnamed')]

        # Add new columns
        df['create_ts'] = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

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
        df.to_sql('stage_tico_place_code', engine, schema='edw_stage', if_exists='replace', index=False)

        print("Data loaded successfully into Azure SQL Server.")

    except Exception as e:
        print("An error occurred:", e)
        raise e

    finally:
        conn.close()

args = {
    'owner': 'airflow',
    'retries': 0,
    'retry_delay':timedelta(minutes=1),
    'on_failure_callback': on_failure_callback,
}

with DAG(
    dag_id='vault_load_tico_place_codes_file',
    catchup=False,
    max_active_runs=1,
    default_args=args,
    start_date=pendulum.datetime(2024, 9, 30, tz="America/New_York"),
    schedule_interval='0 5 10 * *', # At 05:00 on the 10th day of each month
    # schedule_interval=None,
    tags=["tico dag"],
) as dag:
    

    start = DummyOperator(
        task_id='start',
    )
    
    py_download_tico_file = PythonOperator(
        task_id='py_download_tico_file',
        python_callable=download_place_codes_file,
        dag=dag,
    )

    py_load_tico_file = PythonOperator(
        task_id='py_load_tico_file',
        python_callable=load_file_into_tbl,
        dag=dag,
    )

    send_tico_email = EmailOperator(
            task_id='send_tico_email',
            to=to_email,
            subject='Airflow - Tico Job executed successfully',
            html_content=get_HTML_on_vault_format('The tico place codes file has been loaded successfully',''),
        )
 
    end = DummyOperator(
        task_id='end',
    )

start >> py_download_tico_file >> py_load_tico_file >> send_tico_email >> end

