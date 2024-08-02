import os
import pendulum
from datetime import timedelta
from airflow import DAG
from airflow.utils.task_group import TaskGroup
from airflow.operators.mssql_operator import MsSqlOperator
from airflow.operators.email_operator import EmailOperator
from airflow.operators.dummy_operator import DummyOperator
from airflow.operators.python_operator import PythonOperator
from vault_edw_HTML_format import get_sp_success_data_HTML, get_sp_error_data_HTML, get_HTML_on_vault_format
from redzone_csv_generation import generate_redzone_csv_file, SFTPUploadredzoneOperator

to_email = "itdatateam@vault.insurance"
# to_email = "alberto.valbuena@vault.insurance"
cc_email = ""

HOME_PATH = os.path.expanduser('~')
FOLDER_PATH = HOME_PATH + "/airflow/tmp_files/redzone"

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
    dag_id='vault_redzone_feed',
    catchup=False,
    max_active_runs=1,
    default_args=args,
    start_date=pendulum.datetime(2024, 7, 1, tz="America/New_York"),
    # schedule_interval='0 4 * * *', # At 04:00 every day
    schedule_interval=None,
    tags=["redzone dag", "vault"],
) as dag:
    

    start = DummyOperator(
        task_id='start',
    )

    
    with TaskGroup("redzone_group") as redzone_group:

        redzone_sp_items = [
            'sp_policy_redzone_feed'
        ]

        sp_policy_redzone_feed = MsSqlOperator(
            task_id='sp_policy_redzone_feed',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_policy_redzone_feed",
            database="vault_edw",
            autocommit=True,
        )

        generate_redzone_csv = PythonOperator(
            task_id='generate_redzone_csv',
            python_callable=generate_redzone_csv_file,
            dag=dag,
        )

        upload_redzone_csv_to_sftp = SFTPUploadredzoneOperator(
            task_id='upload_redzone_csv_to_sftp',
            sftp_conn_id='Vault_redzone_sftp',
            dag=dag,
        )

        send_redzone_email = EmailOperator(
            task_id='send_redzone_email',
            to=to_email,
            subject='Airflow - redzone table loaded successfully',
            html_content=get_sp_success_data_HTML(redzone_sp_items, 'The redzone process finished successfully.'),
        )

        sp_policy_redzone_feed >> generate_redzone_csv >> upload_redzone_csv_to_sftp >> send_redzone_email


    end = DummyOperator(
        task_id='end',
    )

start >> redzone_group >> end
