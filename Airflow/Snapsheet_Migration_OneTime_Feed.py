import pendulum
from datetime import datetime, timedelta
from airflow import DAG
from airflow.models import Variable
from airflow.utils.task_group import TaskGroup
from airflow.hooks.mssql_hook import MsSqlHook
from airflow.operators.mssql_operator import MsSqlOperator
from airflow.operators.email_operator import EmailOperator
from airflow.operators.dummy_operator import DummyOperator
from airflow.operators.python import PythonOperator, BranchPythonOperator
from vault_edw_HTML_format import get_sp_success_data_HTML, get_sp_error_data_HTML, get_HTML_on_vault_format, get_vault_data_HTML
from snapsheet_api_post import process_claims, process_financial_transactions, process_notes
from snapsheet_api_post import claims_qry, financial_transactions_qry, notes_qry
from snapsheet_api_patch import exposure_status, claim_status, exposure_adjuster, claim_catastrophe
from snapsheet_api_patch import update_exposure_status_qry, update_claim_status_qry, update_exposure_adjuster_qry, update_claim_catastrophe_qry


to_email = "itdatateam@vault.insurance"
# to_email = "alberto.valbuena@vault.insurance"
cc_email = ""

ENVIRONMENT = Variable.get("environment")

claims_queries = [
            [claims_qry.replace('and 1=1', 'and id between 1 and 3300')],
            [claims_qry.replace('and 1=1', 'and id between 3301 and 6600')],
            [claims_qry.replace('and 1=1', 'and id > 6600')],
        ] 

notes_queries = [
            [notes_qry.replace('and 1=1', 'and id between 1 and 40000')],
            [notes_qry.replace('and 1=1', 'and id between 40001 and 80000')],
            [notes_qry.replace('and 1=1', 'and id > 80000')],
        ]

financial_transactions_queries = [
            [financial_transactions_qry.replace('and 1=1', 'and financial_transaction_id between 1 and 50000')],
            [financial_transactions_qry.replace('and 1=1', 'and financial_transaction_id between 50001 and 100000')],
            [financial_transactions_qry.replace('and 1=1', 'and financial_transaction_id > 100000')],
        ]


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
    if ENVIRONMENT == 'PRODUCTION':
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
    else:
        result = 'continue_task'

    return result

def snapsheet_api_send_email_status(**kwargs):

    current_date = datetime.now().strftime('%m/%d/%Y')
    
    sql_qry = """
            WITH CombinedData AS (
                SELECT CAST(update_ts AS DATE) AS update_ts, api_status, 'migration_create_claim_api' AS Table_Name FROM edw_stage.migration_create_claim_api WHERE CAST(update_ts AS DATE) = CAST(GETDATE() AS DATE)
                UNION ALL
                SELECT CAST(update_ts AS DATE) AS update_ts, api_status, 'migration_create_note_api' AS Table_Name FROM edw_stage.migration_create_note_api WHERE CAST(update_ts AS DATE) = CAST(GETDATE() AS DATE)
                UNION ALL
                SELECT CAST(update_ts AS DATE) AS update_ts, api_status, 'migration_update_exposure_adjuster_api' AS Table_Name FROM edw_stage.migration_update_exposure_adjuster_api WHERE CAST(update_ts AS DATE) = CAST(GETDATE() AS DATE)
                UNION ALL
                SELECT CAST(update_ts AS DATE) AS update_ts, api_status, 'migration_create_claim_api_update_catastrophe' AS Table_Name FROM edw_stage.migration_create_claim_api_update_catastrophe WHERE CAST(update_ts AS DATE) = CAST(GETDATE() AS DATE)
                UNION ALL
                SELECT CAST(update_ts AS DATE) AS update_ts, api_status, 'migration_create_financial_transaction_api' AS Table_Name FROM edw_stage.migration_create_financial_transaction_api WHERE CAST(update_ts AS DATE) = CAST(GETDATE() AS DATE)
                UNION ALL
                SELECT CAST(update_ts AS DATE) AS update_ts, api_status, 'migration_update_exposure_status_api' AS Table_Name FROM edw_stage.migration_update_exposure_status_api WHERE CAST(update_ts AS DATE) = CAST(GETDATE() AS DATE)
                UNION ALL
                SELECT CAST(update_ts AS DATE) AS update_ts, api_status, 'migration_create_claim_api_update_status' AS Table_Name FROM edw_stage.migration_create_claim_api_update_status WHERE CAST(update_ts AS DATE) = CAST(GETDATE() AS DATE)
            )
            SELECT 
                update_ts,
                api_status,
                Table_Name,
                COUNT(1) AS Row_Count
            FROM CombinedData
            GROUP BY update_ts, api_status, Table_Name
              """
    # mssql_hook = MsSqlHook(mssql_conn_id='Vault_EDW')
    # result = mssql_hook.get_first(sql_qry)

    msg_text = f"The following report provides the status of policies processed on [{current_date}] through the Snapsheet API."
    
    # if result is not None:
    EmailOperator(
        task_id='send_email_snapsheet',
        to=to_email,
        subject='Airflow - Snapsheet API status',
        html_content=get_vault_data_HTML(sql_qry,msg_text),
        dag=kwargs['dag'],
    ).execute(context=kwargs)


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


    with TaskGroup("phase_one") as phase_one:

        phase_one_items = [
            'sp_migration_create_claim_api',
            'sp_migration_create_claim_api_one_time_update',
            'sp_migration_create_claim_api_update_contactinfo'      
        ]

        sp_migration_create_claim_api = MsSqlOperator(
            task_id='sp_migration_create_claim_api',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_migration_create_claim_api",
            database="vault_edw",
            autocommit=True,
        )

        sp_migration_create_claim_api_one_time_update = MsSqlOperator(
            task_id='sp_migration_create_claim_api_one_time_update',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_migration_create_claim_api_one_time_update",
            database="vault_edw",
            autocommit=True,
        )

        if ENVIRONMENT != 'PRODUCTION':

            sp_migration_create_claim_api_update_contactinfo = MsSqlOperator(
                task_id='sp_migration_create_claim_api_update_contactinfo',
                mssql_conn_id='Vault_EDW',
                sql="EXEC edw_core.sp_migration_create_claim_api_update_contactinfo",
                database="vault_edw",
                autocommit=True,
            )

        py_process_claims = PythonOperator.partial(
            task_id='py_process_claims',
            python_callable=process_claims,
            dag=dag,
        ).expand(op_args=claims_queries)

        send_phase_one_email = EmailOperator(
            task_id='send_phase_one_email',
            to=to_email,
            subject='Airflow - snapsheet migration phase one stored procedures executed successfully',
            html_content=get_sp_success_data_HTML(phase_one_items, 'All snapsheet migration stored procedures executed successfully for phase one'),
        )

        if ENVIRONMENT != 'PRODUCTION':
            sp_migration_create_claim_api >> sp_migration_create_claim_api_one_time_update >> sp_migration_create_claim_api_update_contactinfo >> py_process_claims >> send_phase_one_email
        else:
            sp_migration_create_claim_api >> sp_migration_create_claim_api_one_time_update >> py_process_claims >> send_phase_one_email


    check_for_claim_executions = BranchPythonOperator(
            task_id='check_for_claim_executions',
            python_callable=check_claim_executions,
            dag=dag,
        )
    
    send_abort_process_email = EmailOperator(
            task_id='send_abort_process_email',
            to=to_email,
            subject=f"Airflow - Error on DAG: Snapsheet Migration OneTime Feed.",
            html_content=get_HTML_on_vault_format(f"DAG: Snapsheet Migration OneTime Feed.<br><br>Error Description: There are error rows on edw_stage.migration_create_claim_api table",'')
        )
    
    with TaskGroup("phase_two") as phase_two:

        phase_two_items = [
            'sp_migration_create_note_api',
            'sp_migration_update_exposure_adjuster_api',
            'sp_migration_create_claim_api_update_catastrophe',
            'sp_migration_create_financial_transaction_api',
            'sp_migration_create_financial_transaction_api_update_contactinfo',
            'sp_migration_update_exposure_status_api',
            'sp_migration_create_claim_api_update_status'  
        ]

        sp_migration_create_note_api = MsSqlOperator(
            task_id='sp_migration_create_note_api',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_migration_create_note_api",
            database="vault_edw",
            autocommit=True,
        )

        sp_migration_update_exposure_adjuster_api = MsSqlOperator(
            task_id='sp_migration_update_exposure_adjuster_api',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_migration_update_exposure_adjuster_api",
            database="vault_edw",
            autocommit=True,
        )

        sp_migration_create_claim_api_update_catastrophe = MsSqlOperator(
            task_id='sp_migration_create_claim_api_update_catastrophe',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_migration_create_claim_api_update_catastrophe",
            database="vault_edw",
            autocommit=True,
        )

        sp_migration_create_financial_transaction_api = MsSqlOperator(
            task_id='sp_migration_create_financial_transaction_api',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_migration_create_financial_transaction_api",
            database="vault_edw",
            autocommit=True,
        )

        if ENVIRONMENT != 'PRODUCTION':

            sp_migration_create_financial_transaction_api_update_contactinfo = MsSqlOperator(
                task_id='sp_migration_create_financial_transaction_api_update_contactinfo',
                mssql_conn_id='Vault_EDW',
                sql="EXEC edw_core.sp_migration_create_financial_transaction_api_update_contactinfo",
                database="vault_edw",
                autocommit=True,
            )

        sp_migration_update_exposure_status_api = MsSqlOperator(
            task_id='sp_migration_update_exposure_status_api',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_migration_update_exposure_status_api",
            database="vault_edw",
            autocommit=True,
        )

        sp_migration_create_claim_api_update_status = MsSqlOperator(
            task_id='sp_migration_create_claim_api_update_status',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_migration_create_claim_api_update_status",
            database="vault_edw",
            autocommit=True,
        )

        py_process_notes = PythonOperator.partial(
            task_id='py_process_notes',
            python_callable=process_notes,
            dag=dag,
        ).expand(op_args=notes_queries)

        py_exposure_adjuster_update = PythonOperator(
            task_id='py_exposure_adjuster_update',
            python_callable=exposure_adjuster,
            op_kwargs={"qry": update_exposure_adjuster_qry},
            provide_context=True,
            dag=dag,
        )

        py_claim_catastrophe_update = PythonOperator(
            task_id='py_claim_catastrophe_update',
            python_callable=claim_catastrophe,
            op_kwargs={"qry": update_claim_catastrophe_qry},
            provide_context=True,
            dag=dag,
        )
        
        py_process_financial_transactions = PythonOperator.partial(
            task_id='py_process_financial_transactions',
            python_callable=process_financial_transactions,
            dag=dag,
        ).expand(op_args=financial_transactions_queries)

        py_exposure_status_update = PythonOperator(
            task_id='py_exposure_status_update',
            python_callable=exposure_status,
            op_kwargs={"qry": update_exposure_status_qry},
            provide_context=True,
            dag=dag,
        )

        py_claim_status_update = PythonOperator(
            task_id='py_claim_status_update',
            python_callable=claim_status,
            op_kwargs={"qry": update_claim_status_qry},
            provide_context=True,
            dag=dag,
        )

        send_phase_two_email = EmailOperator(
            task_id='send_phase_two_email',
            to=to_email,
            subject='Airflow - snapsheet migration phase two stored procedures executed successfully',
            html_content=get_sp_success_data_HTML(phase_two_items, 'All snapsheet migration stored procedures executed successfully for phase two'),
        )

        py_snapsheet_api_send_email_status = PythonOperator(
            task_id='py_snapsheet_api_send_email_status',
            python_callable=snapsheet_api_send_email_status,
            provide_context=True,
            dag=dag,
        )

        if ENVIRONMENT != 'PRODUCTION':
            sp_migration_create_financial_transaction_api >> sp_migration_create_financial_transaction_api_update_contactinfo >> py_process_financial_transactions >> sp_migration_create_note_api >> py_process_notes >> sp_migration_update_exposure_adjuster_api >> py_exposure_adjuster_update >> sp_migration_create_claim_api_update_catastrophe >> py_claim_catastrophe_update >> sp_migration_update_exposure_status_api >> py_exposure_status_update >> sp_migration_create_claim_api_update_status  >> py_claim_status_update >> send_phase_two_email >> py_snapsheet_api_send_email_status
        else:
            sp_migration_create_financial_transaction_api >> py_process_financial_transactions >> sp_migration_create_note_api >> py_process_notes >> sp_migration_update_exposure_adjuster_api >> py_exposure_adjuster_update >> sp_migration_create_claim_api_update_catastrophe >> py_claim_catastrophe_update >> sp_migration_update_exposure_status_api >> py_exposure_status_update >> sp_migration_create_claim_api_update_status >> py_claim_status_update >> send_phase_two_email >> py_snapsheet_api_send_email_status
            

start >> phase_one >> check_for_claim_executions >> [continue_task, abort_task] 
abort_task >> send_abort_process_email >> end
continue_task >> phase_two >> end

