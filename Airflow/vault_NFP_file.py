import os
import pendulum
from datetime import timedelta
from airflow import DAG
from airflow.operators.dummy_operator import DummyOperator
from airflow.operators.python_operator import PythonOperator
from airflow.operators.dagrun_operator import TriggerDagRunOperator

default_args = {
    'owner': 'airflow',
    'retries': 0,
    'retry_delay': timedelta(minutes=1),
}

# Define
HOME_PATH = os.path.expanduser('~')
FOLDER_PATH = os.path.join(HOME_PATH, 'scripts/python/nfp_file')
server = 'azrvaultdatasit001.database.windows.net'  # Default value for server

def run_preprocess():
    preprocess_script = os.path.join(FOLDER_PATH, 'preProcess.py')
    os.system(f'python3 {preprocess_script}')

def run_process(server):
    process_script = os.path.join(FOLDER_PATH, 'process.py')
    command = f'python3 {process_script}'
    if server:
        command += f' --server {server}'
    os.system(command)

with DAG(
    dag_id='nfp_file_processing',
    default_args=default_args,
    start_date=pendulum.datetime(2024, 7, 29, tz="America/New_York"),
    catchup=False,
    max_active_runs=1,
    schedule_interval=None,
) as dag:

    start = DummyOperator(
        task_id='start',
    )

    pre_process_task = PythonOperator(
        task_id='preprocess_task',
        python_callable=run_preprocess,
        dag=dag,
    )

    process_task = PythonOperator(
        task_id='process_task',
        python_callable=run_process,
        op_args=[server],  # Pass the server variable to the function
        dag=dag,
    )

    exec_vault_nfp_monthly_load = TriggerDagRunOperator(
            task_id="exec_vault_nfp_monthly_load",
            trigger_dag_id="vault_nfp_monthly_load",
            dag=dag,
        )

    end = DummyOperator(
        task_id='end',
    )

    start >> pre_process_task >> process_task >> exec_vault_nfp_monthly_load >> end
