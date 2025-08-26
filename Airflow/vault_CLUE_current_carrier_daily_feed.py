import os
import pendulum
from datetime import timedelta
from airflow import DAG
from airflow.utils.task_group import TaskGroup
from airflow.providers.microsoft.mssql.hooks.mssql import MsSqlHook
from airflow.providers.microsoft.mssql.operators.mssql import MsSqlOperator
from airflow.operators.email import EmailOperator
from airflow.operators.empty import EmptyOperator
from airflow.operators.python import PythonOperator, BranchPythonOperator
from vault_edw_HTML_format import get_sp_success_data_HTML, get_sp_error_data_HTML, get_HTML_on_vault_format
from clue_current_carrier_txt_generation import generate_Current_Carrier_txt_file_and_encrypt, SFTPUploadClueCurrent_CarrierFileOperator

to_email = "itdatateam@vault.insurance"
# to_email = "alberto.valbuena@vault.insurance"
cc_email = ""

HOME_PATH = os.path.expanduser('~')
FOLDER_PATH = HOME_PATH + "/airflow/tmp_files/clue"

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

def current_carrier_executed_today(**kwargs):
    sql_qry = """
                SELECT process_nm, status_desc
                FROM edw_core.tetl_audit
                WHERE process_nm = 'sp_policy_current_carrier_auto_pr01_feed'
                AND status_desc = 'Success'
                AND CAST(process_start_ts AS DATE) = CAST(GETDATE() AS DATE)
              """
    mssql_hook = MsSqlHook(mssql_conn_id='Vault_EDW')
    result = mssql_hook.get_first(sql_qry)
    if result is not None:
        result = 'skip_task'
    else:
        result = 'continue_task'

    return result

args = {
    'owner': 'airflow',
    'retries': 0,
    'retry_delay':timedelta(minutes=1),
    'on_failure_callback': on_failure_callback,
}

with DAG(
    dag_id='vault_CLUE_current_carrier_daily_feed',
    catchup=False,
    max_active_runs=1,
    default_args=args,
    start_date=pendulum.datetime(2024, 3, 29, tz="America/New_York"),
    # schedule_interval='0 4 * * *', # At 04:00 every day
    schedule_interval=None,
    tags=["CLUE current carrier dag", "vault"],
) as dag:
    

    start = EmptyOperator(
        task_id='start',
    )

    end = EmptyOperator(
        task_id='end',
        trigger_rule='none_failed',
    )

    skip_task = EmptyOperator(
        task_id='skip_task',
    )

    continue_task = EmptyOperator(
        task_id='continue_task',
    )

    clue_current_carrier_executed_today = BranchPythonOperator(
        task_id='clue_current_carrier_executed_today',
        python_callable=current_carrier_executed_today,
        dag=dag,
    )

    with TaskGroup("CLUE_Current_Carrier_group") as CLUE_Current_Carrier_group:

        CLUE_current_carrier_group_items = [
            'sp_policy_current_carrier_auto_np01_feed',
            'sp_policy_current_carrier_auto_sj01_feed',
            'sp_policy_current_carrier_auto_pr01_feed',
            'sp_policy_current_carrier_auto_vr01_feed'
        ]
        
        operators = []
        for item in CLUE_current_carrier_group_items:
            operator = MsSqlOperator(
                task_id=item,
                mssql_conn_id='Vault_EDW',
                sql=f"EXEC edw_core.{item}",
                database="vault_edw",
                autocommit=True,
            )
            operators.append(operator) 

        generate_clue_current_carrier_txt_file = PythonOperator(
            task_id='generate_clue_current_carrier_txt_file',
            python_callable=generate_Current_Carrier_txt_file_and_encrypt,
            dag=dag,
        )

        upload_clue_current_carrier_txt_to_sftp = SFTPUploadClueCurrent_CarrierFileOperator(
            task_id='upload_clue_current_carrier_txt_to_sftp',
            sftp_conn_id='Vault_CLUE_sftp',
            dag=dag,
        )

        send_clue_current_carrier_email = EmailOperator(
            task_id='send_clue_current_carrier_email',
            to=to_email,
            subject='Airflow - CLUE current_carrier process completed successfully',
            html_content=get_sp_success_data_HTML(CLUE_current_carrier_group_items, 'The Clue current_carrier process finished successfully.'),
        )

        for i in range(len(operators) - 1):
            operators[i].set_downstream(operators[i + 1])

        operators[-1].set_downstream(generate_clue_current_carrier_txt_file)
        generate_clue_current_carrier_txt_file.set_downstream(upload_clue_current_carrier_txt_to_sftp)
        upload_clue_current_carrier_txt_to_sftp.set_downstream(send_clue_current_carrier_email)


start.set_downstream(clue_current_carrier_executed_today)
clue_current_carrier_executed_today.set_downstream([continue_task, skip_task])
skip_task.set_downstream(end)
continue_task.set_downstream(CLUE_Current_Carrier_group)
CLUE_Current_Carrier_group.set_downstream(end)