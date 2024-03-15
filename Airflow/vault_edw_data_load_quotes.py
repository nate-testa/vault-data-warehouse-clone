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
from airflow.operators.dagrun_operator import TriggerDagRunOperator
from airflow.providers.microsoft.azure.operators.data_factory import AzureDataFactoryRunPipelineOperator
from vault_edw_HTML_format import get_sp_success_data_HTML, get_sp_error_data_HTML, get_HTML_on_vault_format, get_vault_data_HTML

to_email = "sandeep.gundreddy@vault.insurance, architha.gudimalla@vault.insurance, yunus.mohammed@vault.insurance, tuba.mohsin@vault.insurance, rushin.shah@vault.insurance, hernando.gonzalez.garcia@vault.insurance, alberto.valbuena@vault.insurance"
# to_email = "hernando.gonzalez.garcia@vault.insurance, alberto.valbuena@vault.insurance"
cc_email = ""


def check_treconciliation_and_send_email(**kwargs):
    sql_qry = """
                SELECT transaction_start_dt,transaction_end_dt,source_record_ct,source_amt,target_record_ct,target_amt,datamart_nm, source_system_nm 
                FROM edw_core.treconciliation
                WHERE cast(update_ts as date) =cast(getdate() as date)
                AND status_desc = 'Failure'
              """
    mssql_hook = MsSqlHook(mssql_conn_id='Vault_EDW')
    result = mssql_hook.get_first(sql_qry)
    if result is not None:
        EmailOperator(
            task_id='send_email_treconciliation',
            to=to_email,
            subject='Airflow - Report - Reconciliation Errors',
            html_content=get_vault_data_HTML(sql_qry,'There are reconciliation errors. Please review the details below.'),
            dag=kwargs['dag'],
        ).execute(context=kwargs)

def check_tvalidation_and_send_email(**kwargs):
    sql_qry = """
                SELECT tr.validation_result_sk ,ts.validation_sql_sk ,process_run_start_ts,process_run_end_ts ,ts.validation_sql_desc , tr.source_value, tr.target_value 
                FROM edw_core.tvalidation_result AS tr 
                INNER JOIN edw_core.tvalidation_sql AS ts 
                ON tr.validation_sql_sk = ts.validation_sql_sk
                WHERE cast(process_run_start_ts as date) = cast(getdate() as date)
                AND status_desc ='failure'
                ORDER BY 1 DESC
              """
    mssql_hook = MsSqlHook(mssql_conn_id='Vault_EDW')
    result = mssql_hook.get_first(sql_qry)
    if result is not None:
        EmailOperator(
            task_id='send_email_tvalidation',
            to=to_email,
            subject='Airflow - Report - Validation Errors',
            html_content=get_vault_data_HTML(sql_qry,'There are validation errors. Please review the details below.'),
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
    dag_id='vault_edw_data_load_quotes',
    catchup=False,
    max_active_runs=1,
    default_args=args,
    start_date=pendulum.datetime(2023, 10, 25, tz="America/New_York"),
    # schedule_interval='0 4 * * *', # At 04:00 every day
    schedule_interval=None,
    tags=["master dag quote", "vault"],
) as dag:
    

    start = DummyOperator(
        task_id='start',
    )


    
    with TaskGroup("quote_home_group") as quote_home_group:

        quote_home_group_items = ['sp_tquote_home_location','sp_tquote_home_coverage','sp_tquote_home_coverage_update','sp_tquote_home_additional_coverage']

        sp_tquote_home_location = MsSqlOperator(
            task_id='sp_tquote_home_location',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tquote_home_location",
            database="vault_edw",
            autocommit=True,
        )

        sp_tquote_home_coverage = MsSqlOperator(
            task_id='sp_tquote_home_coverage',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tquote_home_coverage",
            database="vault_edw",
            autocommit=True,
        )

        sp_tquote_home_coverage_update = MsSqlOperator(
            task_id='sp_tquote_home_coverage_update',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tquote_home_coverage_update",
            database="vault_edw",
            autocommit=True,
        )

        sp_tquote_home_additional_coverage = MsSqlOperator(
            task_id='sp_tquote_home_additional_coverage',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tquote_home_additional_coverage",
            database="vault_edw",
            autocommit=True,
        )

        send_quote_home_email = EmailOperator(
            task_id='send_quote_home_email',
            to=to_email,
            subject='Airflow - Quote Home tables loaded successfully',
            html_content=get_sp_success_data_HTML(quote_home_group_items, 'All stored procedures executed successfully for all the Quote Home tables'),
        )

        sp_tquote_home_location >> sp_tquote_home_coverage >> sp_tquote_home_coverage_update >> sp_tquote_home_additional_coverage >> send_quote_home_email


    with TaskGroup("quote_collection_group") as quote_collection_group:

        quote_collection_group_items = ['sp_tquote_collection_location','sp_tquote_collection_coverage','sp_tquote_collection_class_type','sp_tquote_collection_scheduled_item']
        
        sp_tquote_collection_location = MsSqlOperator(
            task_id='sp_tquote_collection_location',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tquote_collection_location",
            database="vault_edw",
            autocommit=True,
        )

        sp_tquote_collection_class_type = MsSqlOperator(
            task_id='sp_tquote_collection_class_type',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tquote_collection_class_type",
            database="vault_edw",
            autocommit=True,
        )
        
        sp_tquote_collection_coverage = MsSqlOperator(
            task_id='sp_tquote_collection_coverage',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tquote_collection_coverage",
            database="vault_edw",
            autocommit=True,
        )

        sp_tquote_collection_scheduled_item = MsSqlOperator(
            task_id='sp_tquote_collection_scheduled_item',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tquote_collection_scheduled_item",
            database="vault_edw",
            autocommit=True,
        )

        send_quote_collection_email = EmailOperator(
            task_id='send_quote_collection_email',
            to=to_email,
            subject='Airflow - Quote Collection tables loaded successfully',
            html_content=get_sp_success_data_HTML(quote_collection_group_items, 'All stored procedures executed successfully for all the Quote Collection tables'),
        )

        sp_tquote_collection_location >> sp_tquote_collection_coverage >> sp_tquote_collection_class_type >> sp_tquote_collection_scheduled_item >> send_quote_collection_email


    with TaskGroup("quote_PEL_group") as quote_PEL_group:

        quote_PEL_group_items = ['sp_tquote_pel_location','sp_tquote_pel_driver','sp_tquote_pel_driver_incident','sp_tquote_pel_vehicle','sp_tquote_pel_watercraft','sp_tquote_pel_coverage']

        sp_tquote_pel_location = MsSqlOperator(
            task_id='sp_tquote_pel_location',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tquote_pel_location",
            database="vault_edw",
            autocommit=True,
        )

        sp_tquote_pel_driver = MsSqlOperator(
            task_id='sp_tquote_pel_driver',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tquote_pel_driver",
            database="vault_edw",
            autocommit=True,
        )

        sp_tquote_pel_driver_incident = MsSqlOperator(
            task_id='sp_tquote_pel_driver_incident',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tquote_pel_driver_incident",
            database="vault_edw",
            autocommit=True,
        )
        
        sp_tquote_pel_vehicle = MsSqlOperator(
            task_id='sp_tquote_pel_vehicle',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tquote_pel_vehicle",
            database="vault_edw",
            autocommit=True,
        )

        sp_tquote_pel_watercraft = MsSqlOperator(
            task_id='sp_tquote_pel_watercraft',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tquote_pel_watercraft",
            database="vault_edw",
            autocommit=True,
        )

        sp_tquote_pel_coverage = MsSqlOperator(
            task_id='sp_tquote_pel_coverage',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tquote_pel_coverage",
            database="vault_edw",
            autocommit=True,
        )

        send_quote_PEL_email = EmailOperator(
            task_id='send_quote_PEL_email',
            to=to_email,
            subject='Airflow - Quote PEL tables loaded successfully',
            html_content=get_sp_success_data_HTML(quote_PEL_group_items, 'All stored procedures executed successfully for all the Quote PEL tables'),
        )

        sp_tquote_pel_location >> sp_tquote_pel_driver >> sp_tquote_pel_driver_incident >> sp_tquote_pel_vehicle >> sp_tquote_pel_watercraft >> sp_tquote_pel_coverage >> send_quote_PEL_email


    with TaskGroup("quote_auto_group") as quote_auto_group:

        quote_auto_group_items = ['sp_tquote_auto_vehicle','sp_tquote_auto_garage_location','sp_tquote_auto_vehicle_coverage','sp_tquote_auto_policy_coverage','sp_tquote_auto_driver','sp_tquote_auto_driver_incident']

        sp_tquote_auto_vehicle = MsSqlOperator(
            task_id='sp_tquote_auto_vehicle',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tquote_auto_vehicle",
            database="vault_edw",
            autocommit=True,
        )

        sp_tquote_auto_garage_location = MsSqlOperator(
            task_id='sp_tquote_auto_garage_location',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tquote_auto_garage_location",
            database="vault_edw",
            autocommit=True,
        )

        sp_tquote_auto_vehicle_coverage = MsSqlOperator(
            task_id='sp_tquote_auto_vehicle_coverage',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tquote_auto_vehicle_coverage",
            database="vault_edw",
            autocommit=True,
        )
        
        sp_tquote_auto_policy_coverage = MsSqlOperator(
            task_id='sp_tquote_auto_policy_coverage',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tquote_auto_policy_coverage",
            database="vault_edw",
            autocommit=True,
        )

        sp_tquote_auto_driver = MsSqlOperator(
            task_id='sp_tquote_auto_driver',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tquote_auto_driver",
            database="vault_edw",
            autocommit=True,
        )

        sp_tquote_auto_driver_incident = MsSqlOperator(
            task_id='sp_tquote_auto_driver_incident',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tquote_auto_driver_incident",
            database="vault_edw",
            autocommit=True,
        )

        send_quote_auto_email = EmailOperator(
            task_id='send_quote_auto_email',
            to=to_email,
            subject='Airflow - Quote Auto tables loaded successfully',
            html_content=get_sp_success_data_HTML(quote_auto_group_items, 'All stored procedures executed successfully for all the Quote Auto tables'),
        )

        sp_tquote_auto_vehicle >> sp_tquote_auto_garage_location >> sp_tquote_auto_vehicle_coverage >> sp_tquote_auto_policy_coverage >> sp_tquote_auto_driver >> sp_tquote_auto_driver_incident >> send_quote_auto_email


    with TaskGroup("quote_group") as quote_group:

        quote_group_items = [
            'sp_tquote',
            'sp_tquote_history',
            'sp_tquote_additional_interest',
            'sp_tquote_manuscript',
            'sp_tquote_mortgagee',
            'sp_tquote_loss_history',
            'sp_tquote_status_history',
            'sp_tquote_transaction_status_history',
            'sp_tquote_insured',
            'sp_tquote_history_update',
            'sp_tquote_update'
            ]

        sp_tquote = MsSqlOperator(
            task_id='sp_tquote',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tquote",
            database="vault_edw",
            autocommit=True,
        )

        sp_tquote_history = MsSqlOperator(
            task_id='sp_tquote_history',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tquote_history",
            database="vault_edw",
            autocommit=True,
        )

        sp_tquote_additional_interest = MsSqlOperator(
            task_id='sp_tquote_additional_interest',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tquote_additional_interest",
            database="vault_edw",
            autocommit=True,
        )

        sp_tquote_manuscript = MsSqlOperator(
            task_id='sp_tquote_manuscript',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tquote_manuscript",
            database="vault_edw",
            autocommit=True,
        )

        sp_tquote_mortgagee = MsSqlOperator(
            task_id='sp_tquote_mortgagee',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tquote_mortgagee",
            database="vault_edw",
            autocommit=True,
        )

        sp_tquote_loss_history = MsSqlOperator(
            task_id='sp_tquote_loss_history',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tquote_loss_history",
            database="vault_edw",
            autocommit=True,
        )

        sp_tquote_status_history = MsSqlOperator(
            task_id='sp_tquote_status_history',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tquote_status_history",
            database="vault_edw",
            autocommit=True,
        )

        sp_tquote_transaction_status_history = MsSqlOperator(
            task_id='sp_tquote_transaction_status_history',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tquote_transaction_status_history",
            database="vault_edw",
            autocommit=True,
        )

        sp_tquote_insured = MsSqlOperator(
            task_id='sp_tquote_insured',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tquote_insured",
            database="vault_edw",
            autocommit=True,
        )

        sp_tquote_history_update = MsSqlOperator(
            task_id='sp_tquote_history_update',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tquote_history_update",
            database="vault_edw",
            autocommit=True,
        )

        sp_tquote_update = MsSqlOperator(
            task_id='sp_tquote_update',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tquote_update",
            database="vault_edw",
            autocommit=True,
        )

        send_quote_email = EmailOperator(
            task_id='send_quote_email',
            to=to_email,
            subject='Airflow - Quote Policy tables loaded successfully',
            html_content=get_sp_success_data_HTML(quote_group_items, 'All stored procedures executed successfully for all the Quote Policy tables'),
        )

        sp_tquote >> sp_tquote_history >> sp_tquote_additional_interest >> sp_tquote_manuscript >> sp_tquote_mortgagee >> sp_tquote_loss_history >> sp_tquote_status_history >> sp_tquote_transaction_status_history >> sp_tquote_insured >> sp_tquote_history_update >> sp_tquote_update >> send_quote_email

    with TaskGroup("quote_transaction_group") as quote_transaction_group:

        quote_transaction_group_items = [
            'sp_tquote_transaction'
            ]

        sp_tquote_transaction = MsSqlOperator(
            task_id='sp_tquote_transaction',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tquote_transaction",
            database="vault_edw",
            autocommit=True,
        )

        send_quote_transaction_email = EmailOperator(
            task_id='send_quote_transaction_email',
            to=to_email,
            subject='Airflow - Quote transaction tables loaded successfully',
            html_content=get_sp_success_data_HTML(quote_transaction_group_items, 'All stored procedures executed successfully for all the Quote transaction tables'),
        )

        sp_tquote_transaction >> send_quote_transaction_email

    with TaskGroup("quote_broker_group") as quote_broker_group:

        quote_broker_group_items = [
            'sp_trenewal_summary',
            'sp_tbroker_summary'
            ]

        sp_trenewal_summary = MsSqlOperator(
            task_id='sp_trenewal_summary',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_trenewal_summary",
            database="vault_edw",
            autocommit=True,
        )
        
        sp_tbroker_summary = MsSqlOperator(
            task_id='sp_tbroker_summary',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tbroker_summary",
            database="vault_edw",
            autocommit=True,
        )

        send_quote_broker_email = EmailOperator(
            task_id='send_quote_broker_email',
            to=to_email,
            subject='Airflow - Quote broker tables loaded successfully',
            html_content=get_sp_success_data_HTML(quote_broker_group_items, 'All stored procedures executed successfully for all the Quote broker tables'),
        )

        sp_trenewal_summary >> sp_tbroker_summary >> send_quote_broker_email

    exec_vault_edw_data_load_vendor_reports = TriggerDagRunOperator(
        task_id="exec_vault_edw_data_load_vendor_reports",
        trigger_dag_id="vault_edw_data_load_vendor_reports",
        dag=dag,
    )

    end = DummyOperator(
        task_id='end',
    )


start >> quote_group >> [quote_home_group , quote_PEL_group, quote_auto_group] >> quote_collection_group >> quote_transaction_group >> quote_broker_group >> exec_vault_edw_data_load_vendor_reports >> end
