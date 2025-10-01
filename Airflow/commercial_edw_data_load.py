import pendulum
from datetime import timedelta
from airflow import DAG
from airflow.utils.task_group import TaskGroup
from airflow.hooks.mssql_hook import MsSqlHook
from airflow.operators.mssql_operator import MsSqlOperator
from airflow.operators.email_operator import EmailOperator
from airflow.operators.dummy_operator import DummyOperator
from airflow.operators.dagrun_operator import TriggerDagRunOperator
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
    dag_id='commercial_edw_data_load',
    catchup=False,
    max_active_runs=1,
    default_args=args,
    start_date=pendulum.datetime(2025, 1, 1, tz="America/New_York"),
    # schedule_interval='0 4 * * *', # At 04:00 every day
    schedule_interval=None,
    tags=["dag commercial tables", "vault"],
) as dag:
    

    start = DummyOperator(
        task_id='start',
    )

    
    with TaskGroup("commercial_policy_group") as commercial_policy_group:

        commercial_policy_group_items = [
            'sp_tcommercial_policy',
            'sp_tcommercial_policy_onetime_litigation',
            'sp_tcommercial_policy_update_cancels',
            'sp_tcommercial_policy_history',
            'sp_tcommercial_policy_history_update',
            'sp_tcommercial_policy_coverage',
            'sp_tcommercial_policy_tower',
            'sp_tcommercial_policy_quota_share',
            'sp_tcommercial_policy_subjectivity',
            'sp_tcommercial_policy_transaction'
        ]

        operators = []
        for item in commercial_policy_group_items:
            operator = MsSqlOperator(
                task_id=item,
                mssql_conn_id='Vault_EDW',
                sql=f"EXEC edw_core.{item}",
                database="vault_edw",
                autocommit=True,
            )
            operators.append(operator)

        send_commercial_policy_email = EmailOperator(
            task_id='send_commercial_policy_email',
            to=to_email,
            subject='Airflow - Commercial policy tables loaded successfully',
            html_content=get_sp_success_data_HTML(commercial_policy_group_items, 'All stored procedures executed successfully for all the Commercial policy tables'),
        )

        for i in range(len(operators) - 1):
            operators[i] >> operators[i + 1]

        operators[-1] >> send_commercial_policy_email

    
    with TaskGroup("commercial_claim_group") as commercial_claim_group:

        commercial_claim_group_items = [
            'sp_tcommercial_claim',
            'sp_tcommercial_claim_feature',
            'sp_tcommercial_claim_task',
            'sp_tcommercial_claim_note'
            ]

        operators = []
        for item in commercial_claim_group_items:
            operator = MsSqlOperator(
                task_id=item,
                mssql_conn_id='Vault_EDW',
                sql=f"EXEC edw_core.{item}",
                database="vault_edw",
                autocommit=True,
            )
            operators.append(operator)       
        
        send_commercial_claim_email = EmailOperator(
            task_id='send_commercial_claim_email',
            to=to_email,
            subject='Airflow - Commercial Claim tables loaded successfully',
            html_content=get_sp_success_data_HTML(commercial_claim_group_items, 'All stored procedures executed successfully for all the Commercial Claim tables'),
        )

        for i in range(len(operators) - 1):
            operators[i] >> operators[i + 1]

        operators[-1] >> send_commercial_claim_email
    

    with TaskGroup("commercial_integration_group") as commercial_integration_group:

        exec_Snapsheet_Commercial_Daily_Feed = TriggerDagRunOperator(
            task_id="exec_Snapsheet_Commercial_Daily_Feed",
            trigger_dag_id="Snapsheet_Commercial_Daily_Feed",
            dag=dag,
        )

        exec_Snapsheet_Commercial_Daily_Feed


    with TaskGroup("commercial_quote_group") as commercial_quote_group:

        commercial_quote_group_items = [
            'sp_tcommercial_quote',
            'sp_tcommercial_quote_update',
            'sp_tcommercial_quote_history_wip',
            'sp_tcommercial_quote_history',
            'sp_tcommercial_quote_history_update',
            'sp_tcommercial_quote_coverage_wip',
            'sp_tcommercial_quote_coverage',
            'sp_tcommercial_quote_tower_wip',
            'sp_tcommercial_quote_tower',
            'sp_tcommercial_quote_quota_share_wip',
            'sp_tcommercial_quote_quota_share',
            'sp_tcommercial_quote_subjectivity_wip',
            'sp_tcommercial_quote_subjectivity',
            'sp_tcommercial_quote_transaction_wip',
            'sp_tcommercial_quote_transaction'
        ]

        operators = []
        for item in commercial_quote_group_items:
            operator = MsSqlOperator(
                task_id=item,
                mssql_conn_id='Vault_EDW',
                sql=f"EXEC edw_core.{item}",
                database="vault_edw",
                autocommit=True,
            )
            operators.append(operator)

        send_commercial_quote_email = EmailOperator(
            task_id='send_commercial_quote_email',
            to=to_email,
            subject='Airflow - Commercial quote tables loaded successfully',
            html_content=get_sp_success_data_HTML(commercial_quote_group_items, 'All stored procedures executed successfully for all the Commercial quote tables'),
        )

        for i in range(len(operators) - 1):
            operators[i] >> operators[i + 1]

        operators[-1] >> send_commercial_quote_email


    with TaskGroup("commercial_datamart_group") as commercial_datamart_group:

        commercial_datamart_group_items = [
            'sp_tcommercial_daily_inforce_policy',
            'sp_tcommercial_policy_update_policy_inforce_in',
            'sp_tcommercial_policy_summary',
            'sp_tcommercial_renewal_summary',
            'sp_tcommercial_broker_summary'
        ]

        operators = []
        for item in commercial_datamart_group_items:
            operator = MsSqlOperator(
                task_id=item,
                mssql_conn_id='Vault_EDW',
                sql=f"EXEC edw_core.{item}",
                database="vault_edw",
                autocommit=True,
            )
            operators.append(operator)

        send_commercial_datamart_group_email = EmailOperator(
            task_id='send_commercial_datamart_group_email',
            to=to_email,
            subject='Airflow - Commercial datamart tables loaded successfully',
            html_content=get_sp_success_data_HTML(commercial_datamart_group_items, 'All stored procedures executed successfully for all the Commercial datamart tables'),
        )

        for i in range(len(operators) - 1):
            operators[i] >> operators[i + 1]

        operators[-1] >> send_commercial_datamart_group_email

    end = DummyOperator(
        task_id='end',
    )


start >> commercial_policy_group >> commercial_claim_group >> commercial_integration_group >> commercial_quote_group >> commercial_datamart_group >> end
