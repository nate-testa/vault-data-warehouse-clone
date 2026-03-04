import os
import pendulum
from datetime import timedelta
from typing import cast
from airflow import DAG
from airflow.utils.context import Context
from airflow.providers.microsoft.mssql.hooks.mssql import MsSqlHook
from airflow.operators.email import EmailOperator
from airflow.operators.empty import EmptyOperator
from airflow.operators.python import PythonOperator
from airflow.providers.microsoft.mssql.operators.mssql import MsSqlOperator
from vault_edw_HTML_format import get_sp_error_data_HTML, get_HTML_on_vault_format, get_vault_data_HTML, get_sp_success_data_HTML
from majesco_data_feed_files_processing import process_all_files
from majesco_data_feed_sftp_to_blob_storage import process_sftp_majesco_files

# to_email = "itdatateam@vault.insurance"
to_email = "alberto.valbuena@vault.insurance"
cc_email = ""

def check_majesco_data_and_send_email(**kwargs):
    sql_qry = """
                SELECT 'stage_majesco_transaction_data_feed' AS Table_Name, COUNT(*) AS Rows_Loaded FROM edw_stage.stage_majesco_transaction_data_feed WHERE CAST(create_ts AS DATE) = CAST(GETDATE() AS DATE)
                UNION ALL
                SELECT 'stage_majesco_installment_data_feed', COUNT(*) FROM edw_stage.stage_majesco_installment_data_feed WHERE CAST(create_ts AS DATE) = CAST(GETDATE() AS DATE)
                UNION ALL  
                SELECT 'stage_majesco_payment_data_feed', COUNT(*) FROM edw_stage.stage_majesco_payment_data_feed WHERE CAST(create_ts AS DATE) = CAST(GETDATE() AS DATE)
                UNION ALL
                SELECT 'stage_majesco_output_data_feed', COUNT(*) FROM edw_stage.stage_majesco_output_data_feed WHERE CAST(create_ts AS DATE) = CAST(GETDATE() AS DATE)
                UNION ALL
                SELECT 'stage_majesco_notes_data_feed', COUNT(*) FROM edw_stage.stage_majesco_notes_data_feed WHERE CAST(create_ts AS DATE) = CAST(GETDATE() AS DATE)
                UNION ALL
                SELECT 'stage_majesco_invoice_data_feed', COUNT(*) FROM edw_stage.stage_majesco_invoice_data_feed WHERE CAST(create_ts AS DATE) = CAST(GETDATE() AS DATE)
              """
    mssql_hook = MsSqlHook(mssql_conn_id='Vault_EDW')
    results = mssql_hook.get_records(sql_qry)
    
    print('*** Results from SQL query ***')
    for row in results:
        print(row)

    total_rows_loaded = sum(int(row[1]) for row in results) 
    print(f"Total rows loaded: {total_rows_loaded}")

    if total_rows_loaded != 0:
        EmailOperator(
            task_id='send_majesco_data_feed_email',
            to=to_email,
            subject='Airflow - Majesco Data Feed - Data loaded report',
            html_content=get_vault_data_HTML(sql_qry,'The Majesco Data Feed files have been processed successfully. Below is the report with the rows loaded by table.'),
            dag=kwargs['dag'],
        ).execute(cast(Context, kwargs))
    else:
        print("No rows loaded. No email will be sent.")

def check_majesco_not_loaded_data_and_send_email(**kwargs):
    sql_qry = """
                SELECT 'stage_majesco_transaction_data_feed' AS Table_Name, COUNT(*) AS Rows_Loaded FROM edw_stage.stage_majesco_transaction_data_feed WHERE CAST(create_ts AS DATE) = CAST(GETDATE() AS DATE) HAVING COUNT(1) = 0
                UNION ALL
                SELECT 'stage_majesco_installment_data_feed', COUNT(*) FROM edw_stage.stage_majesco_installment_data_feed WHERE CAST(create_ts AS DATE) = CAST(GETDATE() AS DATE) HAVING COUNT(1) = 0
                UNION ALL  
                SELECT 'stage_majesco_payment_data_feed', COUNT(*) FROM edw_stage.stage_majesco_payment_data_feed WHERE CAST(create_ts AS DATE) = CAST(GETDATE() AS DATE) HAVING COUNT(1) = 0
                UNION ALL
                SELECT 'stage_majesco_output_data_feed', COUNT(*) FROM edw_stage.stage_majesco_output_data_feed WHERE CAST(create_ts AS DATE) = CAST(GETDATE() AS DATE) HAVING COUNT(1) = 0
                UNION ALL
                SELECT 'stage_majesco_notes_data_feed', COUNT(*) FROM edw_stage.stage_majesco_notes_data_feed WHERE CAST(create_ts AS DATE) = CAST(GETDATE() AS DATE) HAVING COUNT(1) = 0
                UNION ALL
                SELECT 'stage_majesco_invoice_data_feed', COUNT(*) FROM edw_stage.stage_majesco_invoice_data_feed WHERE CAST(create_ts AS DATE) = CAST(GETDATE() AS DATE) HAVING COUNT(1) = 0
              """
    mssql_hook = MsSqlHook(mssql_conn_id='Vault_EDW')
    results = mssql_hook.get_records(sql_qry)

    if results:
        EmailOperator(
            task_id='send_majesco_data_feed_warning_email',
            to=to_email,
            subject='Airflow - Majesco Data Feed - Warning - Data not loaded report',
            html_content=get_vault_data_HTML(sql_qry,'The Majesco Data Feed files have been processed but some tables were not loaded.'),
            dag=kwargs['dag'],
        ).execute(cast(Context, kwargs))
        

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
    dag_id='majesco_data_feed_load',
    catchup=False,
    max_active_runs=1,
    default_args=args,
    start_date=pendulum.datetime(2025, 1, 1, tz="America/New_York"),
    # schedule_interval='0 8 * * *', # At 08:00 every day
    schedule_interval=None,
    tags=["Majesco Data Feed", "vault"],
) as dag:
    

    start = EmptyOperator(
        task_id='start',
    )

    copy_files_from_sftp_to_blob_storage = PythonOperator(
        task_id='copy_files_from_sftp_to_blob_storage',
        python_callable=process_sftp_majesco_files,
        dag=dag,
    )
        
    process_majesco_data_feed_files = PythonOperator(
        task_id='process_majesco_data_feed_files',
        python_callable=process_all_files,
        dag=dag,
    )

    check_data_and_send_email = PythonOperator(
            task_id='check_data_and_send_email',
            python_callable=check_majesco_data_and_send_email,
            dag=dag,
        )
    
    check_not_loaded_data_and_send_email = PythonOperator(
            task_id='check_not_loaded_data_and_send_email',
            python_callable=check_majesco_not_loaded_data_and_send_email,
            dag=dag,
        )

    end = EmptyOperator(
        task_id='end',
    )

start.set_downstream(copy_files_from_sftp_to_blob_storage)
copy_files_from_sftp_to_blob_storage.set_downstream(process_majesco_data_feed_files)
process_majesco_data_feed_files.set_downstream(check_data_and_send_email)
check_data_and_send_email.set_downstream(check_not_loaded_data_and_send_email)
check_not_loaded_data_and_send_email.set_downstream(end)