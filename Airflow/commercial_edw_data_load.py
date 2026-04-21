import pendulum
from datetime import timedelta
from airflow import DAG
from airflow.utils.task_group import TaskGroup
from airflow.operators.python import PythonOperator
from airflow.operators.email import EmailOperator
from airflow.operators.empty import EmptyOperator
from airflow.operators.trigger_dagrun import TriggerDagRunOperator
from airflow.providers.microsoft.mssql.hooks.mssql import MsSqlHook
from airflow.providers.microsoft.mssql.operators.mssql import MsSqlOperator
from vault_edw_HTML_format import get_sp_success_data_HTML, get_sp_error_data_HTML, get_HTML_on_vault_format, get_vault_data_HTML

to_email = "itdatateam@vault.insurance"
# to_email = "hernando.gonzalez.garcia@vault.insurance, alberto.valbuena@vault.insurance"
cc_email = ""


def check_tcommercial_reconciliation_and_send_email(**kwargs):
    sql_qry = """
                SELECT transaction_start_dt,transaction_end_dt,source_record_ct,source_amt,target_record_ct,target_amt,datamart_nm, source_system_nm 
                FROM edw_commercial.tcommercial_reconciliation
                WHERE cast(update_ts as date) =cast(getdate() as date)
                AND status_desc = 'Failure'
              """
    mssql_hook = MsSqlHook(mssql_conn_id='Vault_EDW')
    result = mssql_hook.get_first(sql_qry)
    if result is not None:
        EmailOperator(
            task_id='send_email_tcommercial_reconciliation',
            to=to_email,
            subject='Airflow - Report - tcommercial_reconciliation Errors',
            html_content=get_vault_data_HTML(sql_qry,'There are reconciliation errors. Please review the details below.'),
            dag=kwargs['dag'],
        ).execute(context=kwargs)

def check_snapsheet_edw_commercial_claim_loss_reconciliation_and_send_email(**kwargs):
    sql_qry = """
                SELECT * FROM edw_temp.commercial_snapsheet_edw_claim_loss_reconciliation
              """
    mssql_hook = MsSqlHook(mssql_conn_id='Vault_EDW')
    result = mssql_hook.get_first(sql_qry)
    if result is not None:
        EmailOperator(
            task_id='send_email_snapsheet_edw_commercial_claim_loss_reconciliation',
            to=to_email,
            subject='Airflow - Report - commercial_snapsheet_edw_claim_loss_reconciliation Errors',
            html_content=get_vault_data_HTML(sql_qry,'There are reconciliation errors on table edw_temp.commercial_snapsheet_edw_claim_loss_reconciliation. Please review the details below.'),
            dag=kwargs['dag'],
        ).execute(context=kwargs)

def check_tcommercial_validation_and_send_email(**kwargs):
    sql_qry = """
                SELECT tr.commercial_validation_result_sk ,ts.commercial_validation_sql_sk ,process_run_start_ts,process_run_end_ts ,ts.commercial_validation_sql_desc , tr.source_value, tr.target_value
                FROM edw_commercial.tcommercial_validation_result AS tr
                INNER JOIN edw_commercial.tcommercial_validation_sql AS ts
                ON tr.commercial_validation_sql_sk = ts.commercial_validation_sql_sk
                WHERE cast(process_run_start_ts as date) = cast(getdate() as date)
                AND status_desc ='failure'
                ORDER BY ts.commercial_validation_sql_desc
              """
    mssql_hook = MsSqlHook(mssql_conn_id='Vault_EDW')
    result = mssql_hook.get_first(sql_qry)
    if result is not None:
        EmailOperator(
            task_id='send_email_tcommercial_validation',
            to=to_email,
            subject='Airflow - Report - Commercial Validation Errors',
            html_content=get_vault_data_HTML(sql_qry,'There are commercial validation errors. Please review the details below.'),
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
    dag_id='commercial_edw_data_load',
    catchup=False,
    max_active_runs=1,
    default_args=args,
    start_date=pendulum.datetime(2025, 1, 1, tz="America/New_York"),
    # schedule_interval='0 4 * * *', # At 04:00 every day
    schedule_interval=None,
    tags=["dag commercial tables", "vault"],
) as dag:
    

    start = EmptyOperator(
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
            'sp_tcommercial_policy_transaction',
            'sp_tcommercial_task',
            'sp_tcommercial_reconciliation'
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
            'sp_tcommercial_claim_payment',
            'sp_tcommercial_claim_transaction',
            'sp_tcommercial_claim_transaction_update',
            'sp_tcommercial_claim_task',
            'sp_tcommercial_claim_note',
            'sp_tcommercial_claim_tag',
            'sp_update_tcommercial_claim',
            'sp_update_tcommercial_claim_feature',
            'sp_tcommercial_reconciliation_claim_snapsheet',
            'sp_tcommercial_reconciliation_snapsheet'
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
        
        tcommercial_reconciliation_email = PythonOperator(
            task_id='tcommercial_reconciliation_email',
            python_callable=check_tcommercial_reconciliation_and_send_email,
            provide_context=True,
            dag=dag,
        )

        snapsheet_edw_commercial_claim_loss_reconciliation_email = PythonOperator(
            task_id='snapsheet_edw_commercial_claim_loss_reconciliation_email',
            python_callable=check_snapsheet_edw_commercial_claim_loss_reconciliation_and_send_email,
            provide_context=True,
            dag=dag,
        )
        
        send_commercial_claim_email = EmailOperator(
            task_id='send_commercial_claim_email',
            to=to_email,
            subject='Airflow - Commercial Claim tables loaded successfully',
            html_content=get_sp_success_data_HTML(commercial_claim_group_items, 'All stored procedures executed successfully for all the Commercial Claim tables'),
        )

        for i in range(len(operators) - 1):
            operators[i] >> operators[i + 1]

        operators[-1] >> tcommercial_reconciliation_email >> snapsheet_edw_commercial_claim_loss_reconciliation_email >> send_commercial_claim_email
    

    with TaskGroup("commercial_integration_group") as commercial_integration_group:

        commercial_integration_group_items = [
            'sp_commercial_claim_renewal_rating_api'
            ]

        operators = []
        for item in commercial_integration_group_items:
            operator = MsSqlOperator(
                task_id=item,
                mssql_conn_id='Vault_EDW',
                sql=f"EXEC edw_core.{item}",
                database="vault_edw",
                autocommit=True,
            )
            operators.append(operator)       

        for i in range(len(operators) - 1):
            operators[i] >> operators[i + 1]

        exec_Snapsheet_Commercial_Daily_Feed = TriggerDagRunOperator(
            task_id="exec_Snapsheet_Commercial_Daily_Feed",
            trigger_dag_id="Snapsheet_Commercial_Daily_Feed",
            dag=dag,
        )

        exec_Snapsheet_Commercial_Daily_Feed >> operators[-1]


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
            'sp_tcommercial_claim_feature_summary',
            'sp_tcommercial_claim_summary',
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


    with TaskGroup("commercial_validation_result_group") as commercial_validation_result_group:

        commercial_validation_result_group_items = [
            'sp_tcommercial_validation_result'
        ]

        operators = []
        for item in commercial_validation_result_group_items:
            operator = MsSqlOperator(
                task_id=item,
                mssql_conn_id='Vault_EDW',
                sql=f"EXEC edw_core.{item}",
                database="vault_edw",
                autocommit=True,
            )
            operators.append(operator)

        tcommercial_validation_email = PythonOperator(
            task_id='tcommercial_validation_email',
            python_callable=check_tcommercial_validation_and_send_email,
            provide_context=True,
            dag=dag,
        )

        send_commercial_validation_email = EmailOperator(
            task_id='send_commercial_validation_email',
            to=to_email,
            subject='Airflow - Commercial validation result tables loaded successfully',
            html_content=get_sp_success_data_HTML(commercial_validation_result_group_items, 'All stored procedures executed successfully for all the commercial validation result tables'),
        )

        for i in range(len(operators) - 1):
            operators[i] >> operators[i + 1]

        operators[-1] >> tcommercial_validation_email >> send_commercial_validation_email
    

    end = EmptyOperator(
        task_id='end',
    )


start >> commercial_policy_group >> commercial_claim_group >> commercial_integration_group >> commercial_quote_group >> commercial_datamart_group >> commercial_validation_result_group >> end