import pendulum
from datetime import timedelta
from airflow import DAG
from airflow.utils.task_group import TaskGroup
from airflow.hooks.mssql_hook import MsSqlHook
from airflow.operators.mssql_operator import MsSqlOperator
from airflow.operators.email_operator import EmailOperator
from airflow.operators.dummy_operator import DummyOperator
from airflow.operators.python_operator import PythonOperator, BranchPythonOperator
from vault_edw_HTML_format import get_sp_success_data_HTML, get_sp_error_data_HTML, get_HTML_on_vault_format, get_vault_data_HTML
from snapsheet_api_post import process_claims


to_email = "itdatateam@vault.insurance"
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

def check_claim_executions(**kwargs):
    sql_qry = """
                SELECT api_status, COUNT(1) as rc 
                FROM edw_stage.migration_create_claim_api 
                WHERE api_status <> 'Success'
                GROUP BY api_status
              """
    mssql_hook = MsSqlHook(mssql_conn_id='Vault_EDW')
    result = mssql_hook.get_first(sql_qry)
    if result is not None:
        result = 'abort_task'
    else:
        result = 'continue_task'

    return result

def execute_process_claims(**kwargs):
    claims_qry = """
        select
            claimNumber, claimType, status, policyNumber, firstOpenedAt, firstClosedAt, openedAt, closedAt, datetimeOfLoss, datetimeOfNotification, fraudScore, fraudLevelIndicator, providerCode, coverageCheck,
         accountCode, lossType, notes, reservation, claimIncidentDetails, emergencyServicesDetail, notifier, notificationMethod, exposures, claimParties, vehicles, financialTransactions
        from edw_stage.migration_create_claim_api
        where api_status  in ('pending')
    """
    process_claims(claims_qry)

args = {
    'owner': 'airflow',
    'retries': 0,
    'retry_delay':timedelta(minutes=1),
    'on_failure_callback': on_failure_callback,
}

with DAG(
    dag_id='Snapsheet_Migration_OneTime_Feed',
    catchup=False,
    max_active_runs=1,
    default_args=args,
    start_date=pendulum.datetime(2024, 7, 1, tz="America/New_York"),
    # schedule_interval='0 4 * * *', # At 04:00 every day
    schedule_interval=None,
    tags=["dag snapsheet onetime migration", "vault"],
) as dag:
    
    snapsheet_migration_group_items = [
        'sp_migration_create_claim_api',
        'sp_migration_create_claim_api_update_contactinfo',
        'sp_migration_create_note_api',
        'sp_migration_create_claim_api_update_catastrophe',
        'sp_migration_update_exposure_adjuster_api',
        'sp_migration_create_financial_transaction_api',
        'sp_migration_create_financial_transaction_api_update_contactinfo',
        'sp_migration_update_exposure_status_api',
        'sp_migration_create_claim_api_update_status'
    ]

    start = DummyOperator(
        task_id='start',
    )

    end = DummyOperator(
        task_id='end',
    )

    abort_task = DummyOperator(
        task_id='abort_task',
    )

    continue_task = DummyOperator(
        task_id='continue_task',
    )

    check_for_claim_executions = BranchPythonOperator(
        task_id='check_for_claim_executions',
        python_callable=check_claim_executions,
        dag=dag,
    )

    operators = []
    for item in snapsheet_migration_group_items:
        operator = MsSqlOperator(
            task_id=item,
            mssql_conn_id='Vault_EDW',
            sql=f"EXEC edw_core.{item}",
            database="vault_edw",
            autocommit=True,
        )
        operators.append(operator)
    
    py_process_claims = PythonOperator(
            task_id='py_process_claims',
            python_callable=execute_process_claims,
            provide_context=True,
            dag=dag,
        )

    send_snapsheet_migration_email = EmailOperator(
        task_id='send_snapsheet_migration_email',
        to=to_email,
        subject='Airflow - snapsheet migration stored procedures executed successfully',
        html_content=get_sp_success_data_HTML(snapsheet_migration_group_items, 'All snapsheet migration stored procedures executed successfully'),
    )

    send_abort_process_email = EmailOperator(
        task_id='send_abort_process_email',
        to=to_email,
        subject=f"Airflow - Error on DAG: Snapsheet Migration OneTime Feed.",
        html_content=get_HTML_on_vault_format(f"DAG: Snapsheet Migration OneTime Feed.<br><br>Error Description: There are error rows on edw_stage.migration_create_claim_api table",'')
    )


start >> operators[0] >> operators[1] >> py_process_claims >> check_for_claim_executions >> [continue_task, abort_task] 
abort_task >> send_abort_process_email >> end
continue_task >> operators[2] >> operators[3] >> operators[4] >> operators[5] >> operators[6] >> operators[7] >> operators[8] >> send_snapsheet_migration_email >> end

