import os
import pendulum
from datetime import timedelta
from airflow import DAG
from airflow.operators.email_operator import EmailOperator
from airflow.operators.dummy_operator import DummyOperator
from airflow.operators.python_operator import PythonOperator
from vault_edw_HTML_format import get_sp_error_data_HTML, get_HTML_on_vault_format
from LC360_file_processing import process_all_files

to_email = "stefanie.vachereau@vault.insurance; architha.gudimalla@vault.insurance; hernando.gonzalez.garcia@vault.insurance; alberto.valbuena@vault.insurance"
# to_email = "alberto.valbuena@vault.insurance"
cc_email = ""


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
    dag_id='vault_LC360_file',
    catchup=False,
    max_active_runs=1,
    default_args=args,
    start_date=pendulum.datetime(2024, 9, 16, tz="America/New_York"),
    # schedule_interval='0 4 * * *', # At 04:00 every day
    schedule_interval=None,
    tags=["LC360 dag", "vault"],
) as dag:
    

    start = DummyOperator(
        task_id='start',
    )
        
    process_lc360_files = PythonOperator(
        task_id='process_lc360_files',
        python_callable=process_all_files,
        dag=dag,
    )

    send_lc360_email = EmailOperator(
            task_id='send_lc360_email',
            to=to_email,
            subject='Airflow - LC360 file processed successfully',
            html_content=get_HTML_on_vault_format('The LC360 file has been processed successfully',''),
        )

    end = DummyOperator(
        task_id='end',
    )

start >> process_lc360_files >> send_lc360_email >> end
