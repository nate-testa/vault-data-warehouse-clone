import os
import pendulum
from datetime import datetime, timedelta
from airflow import DAG
from airflow.models import Variable
from airflow.hooks.mssql_hook import MsSqlHook
from airflow.operators.mssql_operator import MsSqlOperator
from airflow.operators.email_operator import EmailOperator
from airflow.operators.dummy_operator import DummyOperator
from airflow.operators.python import PythonOperator
from vault_edw_HTML_format import get_sp_success_data_HTML, get_sp_error_data_HTML, get_HTML_on_vault_format, get_vault_data_HTML
from snapsheet_api_post import process_financial_transactions, financial_transactions_qry
from snapsheet_api_patch import exposure_status, claim_status, update_exposure_status_qry, update_claim_status_qry

to_email = "itdatateam@vault.insurance"
# to_email = "alberto.valbuena@vault.insurance"
cc_email = ""

HOME_PATH = os.path.expanduser('~')
ENVIRONMENT = Variable.get("environment")


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
    dag_id='Snapsheet_Financial_Transactions_Reprocess',
    catchup=False,
    max_active_runs=1,
    default_args=args,
    start_date=pendulum.datetime(2025, 1, 9, tz="America/New_York"),
    # schedule_interval='0 3 * * *', # At 02:00 every day
    schedule_interval=None,
    tags=["snapsheet dag", "vault"],
) as dag:
    

    start = DummyOperator(
        task_id='start',
    )

    snapsheet_items = [
            'sp_migration_update_exposure_status_api',
            'sp_migration_create_claim_api_update_status'  
        ]
    
    financial_transactions_queries = [
            [financial_transactions_qry.replace('and 1=1', 'and financial_transaction_id between 1 and 50000')],
            [financial_transactions_qry.replace('and 1=1', 'and financial_transaction_id between 50001 and 100000')],
            [financial_transactions_qry.replace('and 1=1', 'and financial_transaction_id > 100000')],
        ]
    
    py_process_financial_transactions = PythonOperator.partial(
            task_id='py_process_financial_transactions',
            python_callable=process_financial_transactions,
            dag=dag,
        ).expand(op_args=financial_transactions_queries)
    
    sp_migration_update_exposure_status_api = MsSqlOperator(
            task_id='sp_migration_update_exposure_status_api',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_migration_update_exposure_status_api",
            database="vault_edw",
            autocommit=True,
        )
    
    py_exposure_status_update = PythonOperator(
            task_id='py_exposure_status_update',
            python_callable=exposure_status,
            op_kwargs={"qry": update_exposure_status_qry},
            provide_context=True,
            dag=dag,
        )
    
    sp_migration_create_claim_api_update_status = MsSqlOperator(
            task_id='sp_migration_create_claim_api_update_status',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_migration_create_claim_api_update_status",
            database="vault_edw",
            autocommit=True,
        )
    
    py_claim_status_update = PythonOperator(
            task_id='py_claim_status_update',
            python_callable=claim_status,
            op_kwargs={"qry": update_claim_status_qry},
            provide_context=True,
            dag=dag,
        )
    
    send_financial_transactions_reprocess_email = EmailOperator(
            task_id='send_financial_transactions_reprocess_email',
            to=to_email,
            subject='Airflow - snapsheet migration Financial Transactions Reprocess stored procedures executed successfully',
            html_content=get_sp_success_data_HTML(snapsheet_items, 'All snapsheet migration Financial Transactions Reprocess stored procedures executed successfully'),
        )
    
    end = DummyOperator(
        task_id='end',
    )

    start >> py_process_financial_transactions >> sp_migration_update_exposure_status_api >> py_exposure_status_update >> sp_migration_create_claim_api_update_status >> py_claim_status_update >> send_financial_transactions_reprocess_email >> end