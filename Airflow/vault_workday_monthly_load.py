import os
import pendulum
from datetime import timedelta
from airflow import DAG
from airflow.utils.task_group import TaskGroup
from airflow.operators.python import PythonOperator, BranchPythonOperator
from airflow.operators.email import EmailOperator
from airflow.operators.empty import EmptyOperator
from airflow.operators.bash import BashOperator
from airflow.providers.microsoft.mssql.operators.mssql import MsSqlOperator
from airflow.providers.microsoft.mssql.hooks.mssql import MsSqlHook
from vault_edw_HTML_format import get_sp_success_data_HTML, get_sp_error_data_HTML, get_HTML_on_vault_format, get_vault_data_HTML

to_email = "itdatateam@vault.insurance"
#to_email = "hernando.gonzalez.garcia@vault.insurance, alberto.valbuena@vault.insurance"
cc_email = ""

HOME_PATH = os.path.expanduser('~')
FOLDER_PATH = HOME_PATH + "/python_scripts/workday_feed_to_sharepoint"
BASH_COMMAND = f'bash {FOLDER_PATH}/run_script.sh '

def check_tvalidation_result_and_send_email(**kwargs):
    sql_qry = """
                select 
                    vr.validation_result_sk, vr.validation_sql_sk, vr.process_run_start_ts, vr.process_run_end_ts, 
                    vs.validation_sql_desc, vr.source_value, vr.target_value, vr.status_desc
                from edw_core.tvalidation_result as vr
                inner join edw_core.tvalidation_sql as vs on vr.validation_sql_sk = vs.validation_sql_sk
                where vs.frequency_desc = 'Monthly'
                and vr.status_desc = 'Failure'
                and cast(vr.process_run_start_ts as date) = cast(getdate() as date)
                order by vr.process_run_start_ts desc
              """
    mssql_hook = MsSqlHook(mssql_conn_id='Vault_EDW')
    result = mssql_hook.get_first(sql_qry)
    if result is not None:
        EmailOperator(
            task_id='send_email_tvalidation_result',
            to=to_email,
            subject='Airflow - Report - Workday Validation Errors',
            html_content=get_vault_data_HTML(sql_qry,'There are validation errors. Please review the details below.'),
            dag=kwargs['dag'],
        ).execute(context=kwargs)
        return 'vault_workday_monthly_load_group.skip_sharepoint_feed'
    else:
        return 'vault_workday_monthly_load_group.run_workday_feed_to_sharepoint_script'


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


def on_workday_sharepoint_success(context):
    """
    Send execution report on successful completion of SharePoint upload
    Reads the HTML report file from the workday_feed_to_sharepoint project
    """
    task_instance = context['task_instance']
    report_path = f'{FOLDER_PATH}/logs/latest_execution_report.html'
    
    try:
        # Read the HTML report file
        with open(report_path, 'r', encoding='utf-8') as f:
            html_content = f.read()
        
        # Determine subject based on content
        if '❌' in html_content or 'FAILED' in html_content or 'ERRORS' in html_content:
            subject = '⚠️ Airflow - Workday SharePoint Upload - Completed with Errors'
        elif '⚠️' in html_content or 'WARNING' in html_content:
            subject = '⚠️ Airflow - Workday SharePoint Upload - Completed with Warnings'
        else:
            subject = '✅ Airflow - Workday SharePoint Upload - Success'
        
    except FileNotFoundError:
        # Fallback if report cannot be read
        html_content = get_HTML_on_vault_format(
            f'<strong>Workday SharePoint Upload Executed</strong><br><br>'
            f'The upload script ran but the execution report was not generated. '
            f'This usually means the script was interrupted or encountered an error before completion.<br><br>'
            f'<strong>Recommended Actions:</strong><br>'
            f'• Check the application log: <code>{FOLDER_PATH}/logs/workday_upload-*.log</code><br>'
            f'• Verify the script completed successfully<br>'
            f'• Check for any Python errors or exceptions<br><br>',
            ''
        )
        subject = 'Airflow - Workday SharePoint Upload - Report Unavailable'
    except Exception as e:
        # Fallback for other errors
        error_msg = str(e)
        html_content = get_HTML_on_vault_format(
            f'Workday SharePoint Upload completed but could not retrieve detailed report.<br><br>'
            f'<strong>Error:</strong> {error_msg}',
            ''
        )
        subject = 'Airflow - Workday SharePoint Upload - Report Unavailable'
    
    # Send email with report
    email = EmailOperator(
        task_id='send_sharepoint_upload_report',
        to=to_email,
        subject=subject,
        html_content=html_content
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
    

    start = EmptyOperator(
        task_id='start',
    )


    
    with TaskGroup("vault_workday_monthly_load_group") as vault_workday_monthly_load_group:

        vault_workday_monthly_load_group_items = [
            'sp_policy_workday_unearned_premium_feed',
            'sp_policy_workday_written_premium_feed',
            'sp_policy_workday_ceded_premium_feed',
            'sp_claim_workday_payment',
            'sp_claim_workday_reserve_feed',
            'sp_claim_workday_reserve_feed_itd',
            'sp_claim_litigation_workday_payment',
            'sp_claim_litigation_workday_reserve_feed',
            'sp_claim_litigation_workday_reserve_feed_itd',
            'sp_tvalidation_result'
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

        sp_claim_litigation_workday_payment = MsSqlOperator(
            task_id='sp_claim_litigation_workday_payment',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_claim_litigation_workday_payment",
            database="vault_edw",
            autocommit=True,
        )

        sp_claim_litigation_workday_reserve_feed = MsSqlOperator(
            task_id='sp_claim_litigation_workday_reserve_feed',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_claim_litigation_workday_reserve_feed",
            database="vault_edw",
            autocommit=True,
        )

        sp_claim_litigation_workday_reserve_feed_itd = MsSqlOperator(
            task_id='sp_claim_litigation_workday_reserve_feed_itd',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_claim_litigation_workday_reserve_feed_itd",
            database="vault_edw",
            autocommit=True,
        )

        sp_tvalidation_result = MsSqlOperator(
            task_id='sp_tvalidation_result',
            mssql_conn_id='Vault_EDW',
            sql="""
                EXEC edw_core.sp_tvalidation_result 
                @in_process_dt = '{{ ds }}', 
                @in_frequency = 'Monthly'
            """,
            database="vault_edw",
            autocommit=True,
        )

        tvalidation_result_email = BranchPythonOperator(
            task_id='tvalidation_result_email',
            python_callable=check_tvalidation_result_and_send_email,
            provide_context=True,
            dag=dag,
        )

        run_workday_feed_to_sharepoint_script = BashOperator(
            task_id='run_workday_feed_to_sharepoint_script',
            bash_command=BASH_COMMAND,
            on_success_callback=on_workday_sharepoint_success,
        )

        skip_sharepoint_feed = EmptyOperator(
            task_id='skip_sharepoint_feed',
        )

        send_workday_email = EmailOperator(
            task_id='send_workday_email',
            to=to_email,
            subject='Airflow - Workday tables loaded successfully',
            html_content=get_sp_success_data_HTML(vault_workday_monthly_load_group_items, 'All stored procedures executed successfully for all the Workday tables'),
            trigger_rule='none_failed_min_one_success',
        )

        sp_policy_workday_unearned_premium_feed >> sp_policy_workday_written_premium_feed >> sp_policy_workday_ceded_premium_feed >> sp_claim_workday_payment >> sp_claim_workday_reserve_feed >> sp_claim_workday_reserve_feed_itd >> sp_claim_litigation_workday_payment >> sp_claim_litigation_workday_reserve_feed >> sp_claim_litigation_workday_reserve_feed_itd >> sp_tvalidation_result >> tvalidation_result_email
        tvalidation_result_email >> run_workday_feed_to_sharepoint_script >> send_workday_email
        tvalidation_result_email >> skip_sharepoint_feed >> send_workday_email



    end = EmptyOperator(
        task_id='end',
    )


start >> vault_workday_monthly_load_group >> end
