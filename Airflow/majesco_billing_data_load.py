import os
import pendulum
from datetime import timedelta
from airflow import DAG
from airflow.providers.microsoft.mssql.hooks.mssql import MsSqlHook
from airflow.utils.task_group import TaskGroup
from airflow.operators.email import EmailOperator
from airflow.operators.empty import EmptyOperator
from airflow.operators.python import PythonOperator
from airflow.providers.microsoft.mssql.operators.mssql import MsSqlOperator
from vault_edw_HTML_format import get_sp_error_data_HTML, get_HTML_on_vault_format, get_vault_data_HTML, get_sp_success_data_HTML
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

def check_majesco_not_loaded_data_and_send_email(**kwargs):
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

    if results:
        EmailOperator(
            task_id='send_majesco_billing_warning_email',
            to=to_email,
            subject='Airflow - Majesco Billing - Warning - Data not loaded report',
            html_content=get_vault_data_HTML(sql_qry,'The Majesco Billing files have been processed but some tables were not loaded.'),
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

# Schedule definitions: Weekday vs Weekend
SCHEDULES = {
    "weekday": "0 7 * * 1-5",      # Monday-Friday at 7:00 AM
    "weekend": "30 11 * * 0,6"     # Sunday and Saturday at 11:30 AM
}

# Create DAGs dynamically for each schedule
for schedule_key, cron_expression in SCHEDULES.items():
    dag_id = f'majesco_billing_data_load_{schedule_key}'
    
    dag = DAG(
        dag_id=dag_id,
        catchup=False,
        max_active_runs=1,
        default_args=args,
        start_date=pendulum.datetime(2026, 2, 12, tz="America/New_York"),
        schedule=cron_expression,
        tags=["Majesco Billing", "vault", schedule_key],
    )
    
    with dag:
        
        start = EmptyOperator(
            task_id='start',
        )

        with TaskGroup("policy_group") as policy_group:

            policy_group_items = [
                'sp_tpolicy_billing_paid_in_update'
            ]
            
            operators = []
            for item in policy_group_items:
                operator = MsSqlOperator(
                    task_id=item,
                    mssql_conn_id='Vault_EDW',
                    sql=f"EXEC edw_core.{item}",
                    database="vault_edw",
                    autocommit=True,
                )
                operators.append(operator)

            send_policy_group_email = EmailOperator(
                    task_id='send_policy_group_email',
                    to=to_email,
                    subject='Airflow - Majesco policy tables loaded successfully',
                    html_content=get_sp_success_data_HTML(policy_group_items, 'All stored procedures executed successfully for all the Policy tables'),
                )
            
            for i in range(len(operators) - 1):
                operators[i].set_downstream(operators[i + 1])

            operators[-1].set_downstream(send_policy_group_email)
        

        with TaskGroup("datamart_group") as datamart_group:

            datamart_group_items = [
                'sp_trenewal_summary',
                'sp_trenewal_summary_v1',
                'sp_tbroker_summary',
                'sp_tbroker_summary_v1'
                ]

            operators = []
            for item in datamart_group_items:
                operator = MsSqlOperator(
                    task_id=item,
                    mssql_conn_id='Vault_EDW',
                    sql=f"EXEC edw_core.{item}",
                    database="vault_edw",
                    autocommit=True,
                )
                operators.append(operator)

            send_datamart_group_email = EmailOperator(
                task_id='send_datamart_group_email',
                to=to_email,
                subject='Airflow - Majesco datamart tables loaded successfully',
                html_content=get_sp_success_data_HTML(datamart_group_items, 'All stored procedures executed successfully for all the Majesco datamart tables'),
            )

            for i in range(len(operators) - 1):
                operators[i].set_downstream(operators[i + 1])

            operators[-1].set_downstream(send_datamart_group_email)
            
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
        
        check_not_loaded_data_and_send_email = PythonOperator(
                task_id='check_not_loaded_data_and_send_email',
                python_callable=check_majesco_not_loaded_data_and_send_email,
                provide_context=True,
                dag=dag,
            )

        end = EmptyOperator(
            task_id='end',
        )

        # Set task dependencies
        start.set_downstream(process_majesco_billing_files)
        process_majesco_billing_files.set_downstream(policy_group)
        policy_group.set_downstream(check_data_and_send_email)
        check_data_and_send_email.set_downstream(check_not_loaded_data_and_send_email)
        check_not_loaded_data_and_send_email.set_downstream(datamart_group)
        datamart_group.set_downstream(end)
        
    # Register DAG in globals
    globals()[dag_id] = dag