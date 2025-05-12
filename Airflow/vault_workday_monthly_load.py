import pendulum
from datetime import datetime, timedelta
from airflow import DAG
from airflow.models import BaseOperator
from airflow.utils.dates import days_ago
from airflow.utils.task_group import TaskGroup
from airflow.hooks.mssql_hook import MsSqlHook
from airflow.operators.mssql_operator import MsSqlOperator
from airflow.operators.email_operator import EmailOperator
from airflow.operators.dummy_operator import DummyOperator
from airflow.operators.python_operator import PythonOperator
from airflow.providers.microsoft.azure.operators.data_factory import AzureDataFactoryRunPipelineOperator
from vault_edw_HTML_format import get_sp_success_data_HTML, get_sp_error_data_HTML, get_HTML_on_vault_format, get_vault_data_HTML

to_email = "itdatateam@vault.insurance"
# to_email = "hernando.gonzalez.garcia@vault.insurance, alberto.valbuena@vault.insurance"
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
    dag_id='vault_workday_monthly_load',
    catchup=False,
    max_active_runs=1,
    default_args=args,
    start_date=pendulum.datetime(2023, 11, 30, tz="America/New_York"),
    schedule_interval='0 5 1 * *', 
    # schedule_interval=None, 
    tags=["master worday monthly", "vault"],
) as dag:
    

    start = DummyOperator(
        task_id='start',
    )


    
    with TaskGroup("vault_workday_monthly_load_group") as vault_workday_monthly_load_group:

        vault_workday_monthly_load_group_items = [
            'sp_policy_workday_unearned_premium_feed',
            'sp_policy_workday_written_premium_feed',
            'sp_policy_workday_ceded_premium_feed',
            'sp_claim_workday_payment',
            'sp_claim_workday_reserve_feed',
            'sp_claim_workday_reserve_feed_itd'
         ]
        
        sp_policy_workday_unearned_premium_feed = MsSqlOperator(
            task_id='sp_policy_workday_unearned_premium_feed',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_policy_workday_unearned_premium_feed",
            database="vault_edw",
            autocommit=True,
        )

        sp_policy_workday_written_premium_feed = MsSqlOperator(
            task_id='sp_policy_workday_written_premium_feed',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_policy_workday_written_premium_feed",
            database="vault_edw",
            autocommit=True,
        )

        sp_policy_workday_ceded_premium_feed = MsSqlOperator(
            task_id='sp_policy_workday_ceded_premium_feed',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_policy_workday_ceded_premium_feed",
            database="vault_edw",
            autocommit=True,
        )

        sp_claim_workday_payment = MsSqlOperator(
            task_id='sp_claim_workday_payment',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_claim_workday_payment",
            database="vault_edw",
            autocommit=True,
        )

        sp_claim_workday_reserve_feed = MsSqlOperator(
            task_id='sp_claim_workday_reserve_feed',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_claim_workday_reserve_feed",
            database="vault_edw",
            autocommit=True,
        )

        sp_claim_workday_reserve_feed_itd = MsSqlOperator(
            task_id='sp_claim_workday_reserve_feed_itd',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_claim_workday_reserve_feed_itd",
            database="vault_edw",
            autocommit=True,
        )

        send_workday_email = EmailOperator(
            task_id='send_workday_email',
            to=to_email,
            subject='Airflow - Workday tables loaded successfully',
            html_content=get_sp_success_data_HTML(vault_workday_monthly_load_group_items, 'All stored procedures executed successfully for all the Workday tables'),
        )

        sp_policy_workday_unearned_premium_feed >> sp_policy_workday_written_premium_feed >> sp_policy_workday_ceded_premium_feed >> sp_claim_workday_payment >> sp_claim_workday_reserve_feed >> sp_claim_workday_reserve_feed_itd >> send_workday_email



    end = DummyOperator(
        task_id='end',
    )


start >> vault_workday_monthly_load_group >> end
