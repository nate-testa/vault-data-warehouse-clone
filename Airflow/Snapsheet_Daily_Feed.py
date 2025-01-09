import os
import pendulum
from datetime import datetime, timedelta
from airflow import DAG
from airflow.hooks.mssql_hook import MsSqlHook
from airflow.operators.mssql_operator import MsSqlOperator
from airflow.operators.email_operator import EmailOperator
from airflow.operators.dummy_operator import DummyOperator
from airflow.operators.python_operator import PythonOperator
from vault_edw_HTML_format import get_sp_success_data_HTML, get_sp_error_data_HTML, get_HTML_on_vault_format, get_vault_data_HTML
from snapsheet_api_claim_policy_search import process_snapsheet_policies

to_email = "itdatateam@vault.insurance"
# to_email = "alberto.valbuena@vault.insurance"
cc_email = ""

HOME_PATH = os.path.expanduser('~')

def snapsheet_api_policy_send_email(**kwargs):

    current_date = datetime.now().strftime('%m/%d/%Y')
    
    sql_qry = """
                SELECT CAST(update_ts AS DATE) as update_ts, api_status, COUNT(1) as Row_Count 
                FROM edw_integration.claim_policy_search_snapsheet_api 
                WHERE CAST(update_ts AS DATE) = CAST(GETDATE() AS DATE)
                GROUP BY CAST(update_ts AS DATE), api_status
              """
    # mssql_hook = MsSqlHook(mssql_conn_id='Vault_EDW')
    # result = mssql_hook.get_first(sql_qry)

    msg_text = f"The following report provides the status of policies processed on [{current_date}] through the Snapsheet API."
    
    # if result is not None:
    EmailOperator(
        task_id='send_email_snapsheet',
        to=to_email,
        subject='Airflow - Snapsheet Policy API',
        html_content=get_vault_data_HTML(sql_qry,msg_text),
        dag=kwargs['dag'],
    ).execute(context=kwargs)

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
    dag_id='Snapsheet_Daily_Feed',
    catchup=False,
    max_active_runs=1,
    default_args=args,
    start_date=pendulum.datetime(2025, 1, 9, tz="America/New_York"),
    # schedule_interval='0 3 * * *', # At 02:00 every day
    schedule_interval=None,
    tags=["snapsheet daily feed dag", "vault"],
) as dag:
    

    start = DummyOperator(
        task_id='start',
    )

    snapsheet_items = [
            'sp_claim_policy_search_snapsheet_api',
            'sp_claim_policy_webhook_snapsheet_api',
            'sp_claim_policy_webhook_snapsheet_api_update_contactinfo'
        ]

    sp_claim_policy_search_snapsheet_api = MsSqlOperator(
            task_id='sp_claim_policy_search_snapsheet_api',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_claim_policy_search_snapsheet_api",
            database="vault_edw",
            autocommit=True,
        )

    py_process_snapsheet_policies = PythonOperator(
            task_id='py_process_snapsheet_policies',
            python_callable=process_snapsheet_policies,
            provide_context=True,
            dag=dag,
        )

    sp_claim_policy_webhook_snapsheet_api = MsSqlOperator(
            task_id='sp_claim_policy_webhook_snapsheet_api',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_claim_policy_webhook_snapsheet_api",
            database="vault_edw",
            autocommit=True,
        )

    sp_claim_policy_webhook_snapsheet_api_update_contactinfo = MsSqlOperator(
            task_id='sp_claim_policy_webhook_snapsheet_api_update_contactinfo',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_claim_policy_webhook_snapsheet_api_update_contactinfo",
            database="vault_edw",
            autocommit=True,
        )
    
    send_snapsheet_email = EmailOperator(
            task_id='send_snapsheet_email',
            to=to_email,
            subject='Airflow - Snapsheet tables loaded successfully',
            html_content=get_sp_success_data_HTML(snapsheet_items, 'All stored procedures executed successfully for all the Snapsheet tables'),
        )
    
    py_snapsheet_api_policy_send_email = PythonOperator(
            task_id='py_snapsheet_api_policy_send_email',
            python_callable=snapsheet_api_policy_send_email,
            provide_context=True,
            dag=dag,
        )

    end = DummyOperator(
        task_id='end',
    )

start >> sp_claim_policy_search_snapsheet_api >> py_process_snapsheet_policies >> sp_claim_policy_webhook_snapsheet_api >> sp_claim_policy_webhook_snapsheet_api_update_contactinfo >> send_snapsheet_email >> py_snapsheet_api_policy_send_email >> end
