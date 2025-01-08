import os
import time
import shutil
import pendulum
from datetime import timedelta
from airflow import DAG
from airflow.operators.email_operator import EmailOperator
from airflow.operators.dummy_operator import DummyOperator
from airflow.operators.python_operator import PythonOperator
from vault_edw_HTML_format import get_sp_error_data_HTML, get_HTML_on_vault_format

to_email = "itdatateam@vault.insurance"
# to_email = "alberto.valbuena@vault.insurance"
cc_email = ""

HOME_PATH = os.path.expanduser('~')
SCHEDULE_LOG_FOLDER = HOME_PATH + "/airflow/logs/scheduler"

def delete_old_folders(folder_path, retention_days=30):
    now = time.time()
    days = retention_days * 24 * 60 * 60

    folders_removed = 0
    # List all directories in the folder
    for folder_name in os.listdir(folder_path):
        folder_full_path = os.path.join(folder_path, folder_name)
        # Check if it is a directory
        if os.path.isdir(folder_full_path):
            # Get the last modification time of the folder
            folder_modification_time = os.path.getmtime(folder_full_path)
            # Check if the folder's modification time is older than retention_days
            if now - folder_modification_time > days:
                # If it is greater than retention_days, remove it
                shutil.rmtree(folder_full_path)
                print (f"deleted folder: {folder_full_path}")
                folders_removed += 1

    return folders_removed

def remove_old_folders_for_schedule_log():
    
    print("**** Start clean up folders process")
    folders_removed = delete_old_folders(SCHEDULE_LOG_FOLDER, 30)
    print(f"folders removed in {SCHEDULE_LOG_FOLDER} : {folders_removed}")
    print("**** End clean up folders process")

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


args = {
    'owner': 'airflow',
    'retries': 0,
    'retry_delay':timedelta(minutes=1),
    'on_failure_callback': on_failure_callback,
}

with DAG(
    dag_id='vault_clean_up_logs_folder',
    catchup=False,
    max_active_runs=1,
    default_args=args,
    start_date=pendulum.datetime(2024, 3, 27, tz="America/New_York"),
    schedule_interval='0 2 * * *', # At 02:00 every day
    # schedule_interval=None,
    tags=["clean up logs", "vault"],
) as dag:
    

    start = DummyOperator(
        task_id='start',
    )

    delete_schedule_log_folders = PythonOperator(
            task_id='delete_schedule_log_folders',
            python_callable=remove_old_folders_for_schedule_log,
            provide_context=True,
            dag=dag,
        )

    end = DummyOperator(
        task_id='end',
    )


start >> delete_schedule_log_folders >> end
