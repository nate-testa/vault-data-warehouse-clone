import os
import pendulum
from datetime import timedelta
from airflow import DAG
from airflow.hooks.mssql_hook import MsSqlHook
from airflow.operators.email_operator import EmailOperator
from airflow.operators.dummy_operator import DummyOperator
from airflow.operators.python_operator import PythonOperator
from vault_edw_HTML_format import get_sp_error_data_HTML, get_HTML_on_vault_format, get_vault_data_HTML
from majesco_billing_files_processing import process_all_files

to_email = "itdatateam@vault.insurance"
# to_email = "alberto.valbuena@vault.insurance"
cc_email = ""

def check_majesco_data_and_send_email(**kwargs):
    sql_qry = """
                SELECT 'stage_majesco_adjust_writeoff' AS Table_Name, COUNT(*) AS Rows_Loaded FROM edw_stage.stage_majesco_adjust_writeoff WHERE CAST(create_ts AS DATE) = CAST(GETDATE() AS DATE)
                UNION ALL
                SELECT 'stage_majesco_agency_level_monthly_commission_balance', COUNT(*) FROM edw_stage.stage_majesco_agency_level_monthly_commission_balance WHERE CAST(create_ts AS DATE) = CAST(GETDATE() AS DATE)
                UNION ALL  
                SELECT 'stage_majesco_billing_fee', COUNT(*) FROM edw_stage.stage_majesco_billing_fee WHERE CAST(create_ts AS DATE) = CAST(GETDATE() AS DATE)
                UNION ALL
                SELECT 'stage_majesco_cash_activity', COUNT(*) FROM edw_stage.stage_majesco_cash_activity WHERE CAST(create_ts AS DATE) = CAST(GETDATE() AS DATE)
                UNION ALL
                SELECT 'stage_majesco_commission_disbursement_register', COUNT(*) FROM edw_stage.stage_majesco_commission_disbursement_register WHERE CAST(create_ts AS DATE) = CAST(GETDATE() AS DATE)
                UNION ALL
                SELECT 'stage_majesco_disbursement_register', COUNT(*) FROM edw_stage.stage_majesco_disbursement_register WHERE CAST(create_ts AS DATE) = CAST(GETDATE() AS DATE)
                UNION ALL
                SELECT 'stage_majesco_due_date_aging', COUNT(*) FROM edw_stage.stage_majesco_due_date_aging WHERE CAST(create_ts AS DATE) = CAST(GETDATE() AS DATE)
                UNION ALL
                SELECT 'stage_majesco_policy_level_monthly_commission_balance', COUNT(*) FROM edw_stage.stage_majesco_policy_level_monthly_commission_balance WHERE CAST(create_ts AS DATE) = CAST(GETDATE() AS DATE)
                UNION ALL
                SELECT 'stage_majesco_premium_activity_report', COUNT(*) FROM edw_stage.stage_majesco_premium_activity_report WHERE CAST(create_ts AS DATE) = CAST(GETDATE() AS DATE)
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
            task_id='send_majesco_billing_email',
            to=to_email,
            subject='Airflow - Majesco Billing - Data loaded report',
            html_content=get_vault_data_HTML(sql_qry,'The Majesco Billing files have been processed successfully. Below is the report with the rows loaded by table.'),
            dag=kwargs['dag'],
        ).execute(context=kwargs)
    else:
        print("No rows loaded. No email will be sent.")

def check_majesco_no_loaded_data_and_send_email(**kwargs):
    sql_qry = """
                SELECT 'stage_majesco_adjust_writeoff' AS Table_Name, COUNT(*) AS Rows_Loaded FROM edw_stage.stage_majesco_adjust_writeoff WHERE CAST(create_ts AS DATE) = CAST(GETDATE() AS DATE) HAVING COUNT(1) = 0
                UNION ALL
                SELECT 'stage_majesco_agency_level_monthly_commission_balance', COUNT(*) FROM edw_stage.stage_majesco_agency_level_monthly_commission_balance WHERE CAST(create_ts AS DATE) = CAST(GETDATE() AS DATE) HAVING COUNT(1) = 0
                UNION ALL  
                SELECT 'stage_majesco_billing_fee', COUNT(*) FROM edw_stage.stage_majesco_billing_fee WHERE CAST(create_ts AS DATE) = CAST(GETDATE() AS DATE) HAVING COUNT(1) = 0
                UNION ALL
                SELECT 'stage_majesco_cash_activity', COUNT(*) FROM edw_stage.stage_majesco_cash_activity WHERE CAST(create_ts AS DATE) = CAST(GETDATE() AS DATE) HAVING COUNT(1) = 0
                UNION ALL
                SELECT 'stage_majesco_commission_disbursement_register', COUNT(*) FROM edw_stage.stage_majesco_commission_disbursement_register WHERE CAST(create_ts AS DATE) = CAST(GETDATE() AS DATE) HAVING COUNT(1) = 0
                UNION ALL
                SELECT 'stage_majesco_disbursement_register', COUNT(*) FROM edw_stage.stage_majesco_disbursement_register WHERE CAST(create_ts AS DATE) = CAST(GETDATE() AS DATE) HAVING COUNT(1) = 0
                UNION ALL
                SELECT 'stage_majesco_due_date_aging', COUNT(*) FROM edw_stage.stage_majesco_due_date_aging WHERE CAST(create_ts AS DATE) = CAST(GETDATE() AS DATE) HAVING COUNT(1) = 0
                UNION ALL
                SELECT 'stage_majesco_policy_level_monthly_commission_balance', COUNT(*) FROM edw_stage.stage_majesco_policy_level_monthly_commission_balance WHERE CAST(create_ts AS DATE) = CAST(GETDATE() AS DATE) HAVING COUNT(1) = 0
                UNION ALL
                SELECT 'stage_majesco_premium_activity_report', COUNT(*) FROM edw_stage.stage_majesco_premium_activity_report WHERE CAST(create_ts AS DATE) = CAST(GETDATE() AS DATE) HAVING COUNT(1) = 0
              """
    mssql_hook = MsSqlHook(mssql_conn_id='Vault_EDW')
    results = mssql_hook.get_records(sql_qry)

    if results is not None:
        EmailOperator(
            task_id='send_majesco_billing_warning_email',
            to=to_email,
            subject='Airflow - Majesco Billing - Warning - Data not loaded report',
            html_content=get_vault_data_HTML(sql_qry,'The Majesco Billing files have been processed but some tables were no loaded.'),
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
    dag_id='majesco_billing_data_load',
    catchup=False,
    max_active_runs=1,
    default_args=args,
    start_date=pendulum.datetime(2025, 1, 1, tz="America/New_York"),
    schedule_interval='0 8 * * *', # At 08:00 every day
    # schedule_interval=None,
    tags=["Majesco Billing", "vault"],
) as dag:
    

    start = DummyOperator(
        task_id='start',
    )
        
    process_majesco_billing_files = PythonOperator(
        task_id='process_majesco_billing_files',
        python_callable=process_all_files,
        dag=dag,
    )

    check_data_and_send_email = PythonOperator(
            task_id='check_data_and_send_email',
            python_callable=check_majesco_data_and_send_email,
            provide_context=True,
            dag=dag,
        )
    
    check_no_loaded_data_and_send_email = PythonOperator(
            task_id='check_no_loaded_data_and_send_email',
            python_callable=check_majesco_no_loaded_data_and_send_email,
            provide_context=True,
            dag=dag,
        )

    end = DummyOperator(
        task_id='end',
    )

start >> process_majesco_billing_files >> check_data_and_send_email >> check_no_loaded_data_and_send_email >> end
