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
    dag_id='vault_oneshield_onetime_load',
    catchup=False,
    max_active_runs=1,
    default_args=args,
    start_date=pendulum.datetime(2023, 11, 16, tz="America/New_York"),
    # schedule_interval='0 5 * * 1-5', # At 05:00 every day
    schedule_interval=None, 
    # schedule_interval=datetime.timedelta(hours=6), # Every 6 hours
    tags=["master dag oneshield", "vault"],
) as dag:
    

    start = DummyOperator(
        task_id='start',
    )


    
    with TaskGroup("oneshield_onetime_load_group") as oneshield_onetime_load_group:

        oneshield_onetime_load_group_items = [
            'sp_os_broker',
            'sp_os_customer',
            'sp_os_tpolicy',
            'sp_os_tpolicy_history',
            'sp_os_tpolicy_transaction',
            'sp_os_tcatastrophe',
            'sp_os_tcause_of_loss',
            'sp_os_tclaim',
            'sp_os_tclaim_update',
            'sp_os_tclaim_feature',
            'sp_os_tclaim_transaction',
            'sp_os_claim_policy_search_api'
         ]
        
        sp_os_broker = MsSqlOperator(
            task_id='sp_os_broker',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_os_broker",
            database="vault_edw",
            autocommit=True,
        )

        sp_os_customer = MsSqlOperator(
            task_id='sp_os_customer',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_os_customer",
            database="vault_edw",
            autocommit=True,
        )

        sp_os_tpolicy = MsSqlOperator(
            task_id='sp_os_tpolicy',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_os_tpolicy",
            database="vault_edw",
            autocommit=True,
        )

        sp_os_tpolicy_history = MsSqlOperator(
            task_id='sp_os_tpolicy_history',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_os_tpolicy_history",
            database="vault_edw",
            autocommit=True,
        )

        sp_os_tpolicy_transaction = MsSqlOperator(
            task_id='sp_os_tpolicy_transaction',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_os_tpolicy_transaction",
            database="vault_edw",
            autocommit=True,
        )

        sp_os_tcatastrophe = MsSqlOperator(
            task_id='sp_os_tcatastrophe',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_os_tcatastrophe",
            database="vault_edw",
            autocommit=True,
        )

        sp_os_tcause_of_loss = MsSqlOperator(
            task_id='sp_os_tcause_of_loss',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_os_tcause_of_loss",
            database="vault_edw",
            autocommit=True,
        )

        sp_os_tclaim = MsSqlOperator(
            task_id='sp_os_tclaim',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_os_tclaim",
            database="vault_edw",
            autocommit=True,
        )

        sp_os_tclaim_update = MsSqlOperator(
            task_id='sp_os_tclaim_update',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_os_tclaim_update",
            database="vault_edw",
            autocommit=True,
        )

        sp_os_tclaim_feature = MsSqlOperator(
            task_id='sp_os_tclaim_feature',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_os_tclaim_feature",
            database="vault_edw",
            autocommit=True,
        )

        sp_os_tclaim_transaction = MsSqlOperator(
            task_id='sp_os_tclaim_transaction',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_os_tclaim_transaction",
            database="vault_edw",
            autocommit=True,
        )

        sp_os_claim_policy_search_api = MsSqlOperator(
            task_id='sp_os_claim_policy_search_api',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_os_claim_policy_search_api",
            database="vault_edw",
            autocommit=True,
        )

        send_oneshield_email = EmailOperator(
            task_id='send_oneshield_email',
            to=to_email,
            subject='Airflow - Oneshield tables loaded successfully',
            html_content=get_sp_success_data_HTML(oneshield_onetime_load_group_items, 'All stored procedures executed successfully for all the Oneshield tables'),
        )

        sp_os_broker >> sp_os_customer >> sp_os_tpolicy >> sp_os_tpolicy_history >> sp_os_tpolicy_transaction >> sp_os_tcatastrophe >> sp_os_tcause_of_loss >> sp_os_tclaim >> sp_os_tclaim_update >> sp_os_tclaim_feature >> sp_os_tclaim_transaction >> sp_os_claim_policy_search_api >> send_oneshield_email



    end = DummyOperator(
        task_id='end',
    )


start >> oneshield_onetime_load_group >> end
