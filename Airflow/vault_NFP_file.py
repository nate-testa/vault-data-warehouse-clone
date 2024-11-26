import os
import pendulum
from datetime import timedelta
from airflow import DAG
from airflow.operators.dummy_operator import DummyOperator
from airflow.operators.bash_operator import BashOperator  # Correct import
from airflow.operators.dagrun_operator import TriggerDagRunOperator
from airflow.models import Variable


default_args = {
    'owner': 'airflow',
    'retries': 0,
    'retry_delay': timedelta(minutes=1),
}

# Define
FOLDER_PATH = Variable.get("NFP_FOLDER_PATH")  # Use absolute path
server = Variable.get("NFP_SERVER")  # Default value for server

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

    pre_process_task = BashOperator(
        task_id='preprocess_task',
        bash_command=f'python3 {FOLDER_PATH}/preProcess.py',
        dag=dag,
    )

    process_task = BashOperator(
        task_id='process_task',
        bash_command=f'python3 {FOLDER_PATH}/process.py --server {server}',
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