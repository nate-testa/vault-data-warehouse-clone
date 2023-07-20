from datetime import datetime, timedelta
from airflow import DAG
from airflow.utils.dates import days_ago
from airflow.utils.task_group import TaskGroup
from airflow.operators.mssql_operator import MsSqlOperator
from airflow.operators.email_operator import EmailOperator
from airflow.operators.dummy_operator import DummyOperator

to_email = "alberto.valbuena@vault.insurance, hernando.gonzalez.garcia@vault.insurance"
cc_email = ""

def on_failure_callback(context):
    task_instance = context['task_instance']
    error_info = str(context.get('exception'))
    email = EmailOperator(
        task_id='send_email_on_failure',
        to=to_email,
        subject=f"Error on Task: {task_instance.task_id} - DAG: {task_instance.dag_id}",
        html_content=f"Task: {task_instance.task_id}<br><br>Error Description: {error_info}",
    )
    email.execute(context)

args = {
    'owner': 'airflow',
    'retries': 0,
    'retry_delay':timedelta(minutes=1),
    'on_failure_callback': on_failure_callback,
}

with DAG(
    dag_id='master_dag',
    default_args=args,
    start_date=datetime(2023,7,17),
    schedule_interval=None, #datetime.timedelta(hours=6), # Every 6 hours
    tags=["master dag", "vault"],
    default_view='graph',
) as dag:
    
    start = DummyOperator(
        task_id='start',
    )

    with TaskGroup("ADF_group") as ADF_group:
        adf_etl_load_stage = DummyOperator(
            task_id='adf_etl_load_stage',
        )

        send_adf_email = EmailOperator(
            task_id='send_adf_email',
            to=to_email,
            subject='ADF pipeline executed successfully',
            html_content='The Azure Data Factory pipeline xxxxxx executed successfully',
        )

        adf_etl_load_stage >> send_adf_email

    with TaskGroup("home_group") as home_group:

        sp_thome_location = MsSqlOperator(
            task_id='sp_thome_location',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_thome_location",
            database="vault_edw",
        )

        sp_thome_coverage = MsSqlOperator(
            task_id='sp_thome_coverage',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_thome_coverage",
            database="vault_edw",
        )

        sp_tmortgagee = MsSqlOperator(
            task_id='sp_tmortgagee',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tmortgagee",
            database="vault_edw",
        )

        sp_thome_additional_coverage = MsSqlOperator(
            task_id='sp_thome_additional_coverage',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_thome_additional_coverage",
            database="vault_edw",
        )

        send_home_email = EmailOperator(
            task_id='send_home_email',
            to=to_email,
            subject='Home tables loaded successfully',
            html_content='All stored procedures executed successfully for all the Home tables',
        )

        sp_thome_location >> sp_thome_coverage >> sp_tmortgagee >> sp_thome_additional_coverage >> send_home_email



    with TaskGroup("collection_group") as collection_group:
        
        sp_tcollection_location = MsSqlOperator(
            task_id='sp_tcollection_location',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tcollection_location",
            database="vault_edw",
        )

        sp_tcollection_additional_coverage = MsSqlOperator(
            task_id='sp_tcollection_additional_coverage',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tcollection_additional_coverage",
            database="vault_edw",
        )
        
        sp_tcollection_coverage = MsSqlOperator(
            task_id='sp_tcollection_coverage',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tcollection_coverage",
            database="vault_edw",
        )

        sp_tcollection_scheduled_item_detail = MsSqlOperator(
            task_id='sp_tcollection_scheduled_item_detail',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tcollection_scheduled_item_detail",
            database="vault_edw",
        )

        send_collection_email = EmailOperator(
            task_id='send_collection_email',
            to=to_email,
            subject='Collection tables loaded successfully',
            html_content='All stored procedures executed successfully for all the Collection tables',
        )

        sp_tcollection_location >> sp_tcollection_additional_coverage >> sp_tcollection_coverage >> sp_tcollection_scheduled_item_detail >> send_collection_email

    with TaskGroup("PEL_group") as PEL_group:

        sp_tpel_location = MsSqlOperator(
            task_id='sp_tpel_location',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tpel_location",
            database="vault_edw",
        )

        sp_tpel_driver = MsSqlOperator(
            task_id='sp_tpel_driver',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tpel_driver",
            database="vault_edw",
        )

        sp_tpel_driver_incident = MsSqlOperator(
            task_id='sp_tpel_driver_incident',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tpel_driver_incident",
            database="vault_edw",
        )
        
        sp_tpel_vehicle = MsSqlOperator(
            task_id='sp_tpel_vehicle',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tpel_vehicle",
            database="vault_edw",
        )

        sp_tpel_watercraft = MsSqlOperator(
            task_id='sp_tpel_watercraft',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tpel_watercraft",
            database="vault_edw",
        )

        sp_tpel_coverage = MsSqlOperator(
            task_id='sp_tpel_coverage',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tpel_coverage",
            database="vault_edw",
        )

        send_PEL_email = EmailOperator(
            task_id='send_PEL_email',
            to=to_email,
            subject='PEL tables loaded successfully',
            html_content='All stored procedures executed successfully for all the PEL tables',
        )

        sp_tpel_location >> sp_tpel_driver >> sp_tpel_driver_incident >> sp_tpel_vehicle >> sp_tpel_watercraft >> sp_tpel_coverage >> send_PEL_email

    with TaskGroup("policy_transaction") as policy_transaction:

        sp_tpolicy_transaction = MsSqlOperator(
            task_id='sp_tpolicy_transaction',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tpolicy_transaction",
            database="vault_edw",
        )

        send_policy_transaction_email = EmailOperator(
            task_id='send_policy_transaction_email',
            to=to_email,
            subject='Policy_transaction table loaded successfully',
            html_content='The stored procedure that load Policy_transaction table executed successfully',
        )

        sp_tpolicy_transaction >> send_policy_transaction_email

    with TaskGroup("datamart_group") as datamart_group:

        sp_tdaily_inforce_policy = MsSqlOperator(
            task_id='sp_tdaily_inforce_policy',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tdaily_inforce_policy",
            database="vault_edw",
        )

        sp_tpolicy_summary = MsSqlOperator(
            task_id='sp_tpolicy_summary',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tpolicy_summary",
            database="vault_edw",
        )

        sp_titem_summary = MsSqlOperator(
            task_id='sp_titem_summary',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_titem_summary",
            database="vault_edw",
        )

        sp_tcustomer_summary = MsSqlOperator(
            task_id='sp_tcustomer_summary',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tcustomer_summarysp_tcustomer_summary",
            database="vault_edw",
        )

        send_datamart_email = EmailOperator(
            task_id='send_datamart_email',
            to=to_email,
            subject='Datamart tables loaded successfully',
            html_content='All stored procedures executed successfully for all the Datamart tables',
        )

        sp_tdaily_inforce_policy >> sp_tpolicy_summary >> sp_titem_summary >> sp_tcustomer_summary >> send_datamart_email

    with TaskGroup("reference_group") as reference_group:

        sp_tbroker = MsSqlOperator(
            task_id='sp_tbroker',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tbroker",
            database="vault_edw",
        )

        sp_tcustomer = MsSqlOperator(
            task_id='sp_tcustomer',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tcustomer",
            database="vault_edw",
        )

        sp_users = MsSqlOperator(
            task_id='sp_users',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_users",
            database="vault_edw",
        )

        sp_tinternal_coverage = MsSqlOperator(
            task_id='sp_tinternal_coverage',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tinternal_coverage",
            database="vault_edw",
        )

        sp_ttax_fee_surcharge = MsSqlOperator(
            task_id='sp_ttax_fee_surcharge',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_ttax_fee_surcharge",
            database="vault_edw",
        )

        send_reference_email = EmailOperator(
            task_id='send_reference_email',
            to=to_email,
            subject='Reference tables loaded successfully',
            html_content='All stored procedures executed successfully for all the Reference tables',
        )

        sp_tbroker >> sp_tcustomer >> sp_users >> sp_tinternal_coverage >> sp_ttax_fee_surcharge >> send_reference_email

    with TaskGroup("policy_group") as policy_group:

        sp_tpolicy = MsSqlOperator(
            task_id='sp_tpolicy',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tpolicy",
            database="vault_edw",
        )

        sp_tpolicy_history = MsSqlOperator(
            task_id='sp_tpolicy_history',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tpolicy_history",
            database="vault_edw",
        )

        send_policy_email = EmailOperator(
            task_id='send_policy_email',
            to=to_email,
            subject='Policy tables loaded successfully',
            html_content='All stored procedures executed successfully for all the Policy tables',
        )

        sp_tpolicy >> sp_tpolicy_history >> send_policy_email


    end = DummyOperator(
        task_id='end',
    )

start >> ADF_group >> reference_group >> policy_group >> [home_group , PEL_group, collection_group] >> policy_transaction >> datamart_group >> end