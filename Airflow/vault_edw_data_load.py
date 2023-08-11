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
from airflow.providers.microsoft.azure.operators.data_factory import AzureDataFactoryRunPipelineOperator
from vault_edw_HTML_format import get_sp_success_data_HTML, get_sp_error_data_HTML, get_HTML_on_vault_format, get_treconciliation_data_HTML

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
            subject='Airflow - Reconciliation Errors',
            html_content=get_treconciliation_data_HTML(sql_qry,'There are reconciliation errors. Please review the details below.'),
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
    dag_id='vault_edw_data_load',
    default_args=args,
    start_date=pendulum.datetime(2023, 8, 7, tz="America/New_York"),
    schedule_interval='0 5 * * 1-5', # At 05:00 every day
    # schedule_interval=None, 
    # schedule_interval=datetime.timedelta(hours=6), # Every 6 hours
    tags=["master dag", "vault"],
) as dag:
    
    start = DummyOperator(
        task_id='start',
    )

    with TaskGroup("ADF_group") as ADF_group:

        adf_etl_load_stage: BaseOperator = AzureDataFactoryRunPipelineOperator(
            task_id="adf_etl_load_stage",
            azure_data_factory_conn_id='azure_data_factory_vault_data',
            pipeline_name="MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel",
            # parameters={"myParam": "value"},
        )

        send_adf_email = EmailOperator(
            task_id='send_adf_email',
            to=to_email,
            subject='Airflow - ADF pipeline executed successfully',
            html_content=get_HTML_on_vault_format('The Azure Data Factory pipeline MetadataDrivenCopy_MetalDB_to_Edw_stage_1i1_TopLevel executed successfully',''),
        )

        adf_etl_load_stage >> send_adf_email

    with TaskGroup("home_group") as home_group:

        home_group_items = ['sp_thome_location','sp_thome_coverage','sp_tmortgagee','sp_thome_additional_coverage']

        sp_thome_location = MsSqlOperator(
            task_id='sp_thome_location',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_thome_location",
            database="vault_edw",
            autocommit=True,
        )

        sp_thome_coverage = MsSqlOperator(
            task_id='sp_thome_coverage',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_thome_coverage",
            database="vault_edw",
            autocommit=True,
        )

        sp_tmortgagee = MsSqlOperator(
            task_id='sp_tmortgagee',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tmortgagee",
            database="vault_edw",
            autocommit=True,
        )

        sp_thome_additional_coverage = MsSqlOperator(
            task_id='sp_thome_additional_coverage',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_thome_additional_coverage",
            database="vault_edw",
            autocommit=True,
        )

        send_home_email = EmailOperator(
            task_id='send_home_email',
            to=to_email,
            subject='Airflow - Home tables loaded successfully',
            html_content=get_sp_success_data_HTML(home_group_items, 'All stored procedures executed successfully for all the Home tables'),
        )

        sp_thome_location >> sp_thome_coverage >> sp_tmortgagee >> sp_thome_additional_coverage >> send_home_email

    with TaskGroup("collection_group") as collection_group:

        collection_group_items = ['sp_tcollection_location','sp_tcollection_additional_coverage','sp_tcollection_coverage','sp_tcollection_scheduled_item_detail']
        
        sp_tcollection_location = MsSqlOperator(
            task_id='sp_tcollection_location',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tcollection_location",
            database="vault_edw",
            autocommit=True,
        )

        sp_tcollection_additional_coverage = MsSqlOperator(
            task_id='sp_tcollection_additional_coverage',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tcollection_additional_coverage",
            database="vault_edw",
            autocommit=True,
        )
        
        sp_tcollection_coverage = MsSqlOperator(
            task_id='sp_tcollection_coverage',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tcollection_coverage",
            database="vault_edw",
            autocommit=True,
        )

        sp_tcollection_scheduled_item_detail = MsSqlOperator(
            task_id='sp_tcollection_scheduled_item_detail',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tcollection_scheduled_item_detail",
            database="vault_edw",
            autocommit=True,
        )

        send_collection_email = EmailOperator(
            task_id='send_collection_email',
            to=to_email,
            subject='Airflow - Collection tables loaded successfully',
            html_content=get_sp_success_data_HTML(collection_group_items, 'All stored procedures executed successfully for all the Collection tables'),
        )

        sp_tcollection_location >> sp_tcollection_additional_coverage >> sp_tcollection_coverage >> sp_tcollection_scheduled_item_detail >> send_collection_email

    with TaskGroup("PEL_group") as PEL_group:

        PEL_group_items = ['sp_tpel_location','sp_tpel_driver','sp_tpel_driver_incident','sp_tpel_vehicle','sp_tpel_watercraft','sp_tpel_coverage']

        sp_tpel_location = MsSqlOperator(
            task_id='sp_tpel_location',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tpel_location",
            database="vault_edw",
            autocommit=True,
        )

        sp_tpel_driver = MsSqlOperator(
            task_id='sp_tpel_driver',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tpel_driver",
            database="vault_edw",
            autocommit=True,
        )

        sp_tpel_driver_incident = MsSqlOperator(
            task_id='sp_tpel_driver_incident',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tpel_driver_incident",
            database="vault_edw",
            autocommit=True,
        )
        
        sp_tpel_vehicle = MsSqlOperator(
            task_id='sp_tpel_vehicle',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tpel_vehicle",
            database="vault_edw",
            autocommit=True,
        )

        sp_tpel_watercraft = MsSqlOperator(
            task_id='sp_tpel_watercraft',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tpel_watercraft",
            database="vault_edw",
            autocommit=True,
        )

        sp_tpel_coverage = MsSqlOperator(
            task_id='sp_tpel_coverage',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tpel_coverage",
            database="vault_edw",
            autocommit=True,
        )

        send_PEL_email = EmailOperator(
            task_id='send_PEL_email',
            to=to_email,
            subject='Airflow - PEL tables loaded successfully',
            html_content=get_sp_success_data_HTML(PEL_group_items, 'All stored procedures executed successfully for all the PEL tables'),
        )

        sp_tpel_location >> sp_tpel_driver >> sp_tpel_driver_incident >> sp_tpel_vehicle >> sp_tpel_watercraft >> sp_tpel_coverage >> send_PEL_email

    with TaskGroup("policy_transaction_group") as policy_transaction_group:

        policy_transaction_group_items = ['sp_tpolicy_transaction','sp_treconciliation']

        sp_tpolicy_transaction = MsSqlOperator(
            task_id='sp_tpolicy_transaction',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tpolicy_transaction",
            database="vault_edw",
            autocommit=True,
        )

        sp_treconciliation = MsSqlOperator(
            task_id='sp_treconciliation',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_treconciliation",
            database="vault_edw",
            autocommit=True,
        )

        treconciliation_email = PythonOperator(
            task_id='treconciliation_email',
            python_callable=check_treconciliation_and_send_email,
            provide_context=True,
            dag=dag,
        )

        send_policy_transaction_email = EmailOperator(
            task_id='send_policy_transaction_email',
            to=to_email,
            subject='Airflow - Policy_transaction tables loaded successfully',
            html_content=get_sp_success_data_HTML(policy_transaction_group_items, 'All stored procedures executed successfully for all the Policy Transaction tables'),
        )

        sp_tpolicy_transaction >> sp_treconciliation >> treconciliation_email >> send_policy_transaction_email

    with TaskGroup("datamart_group") as datamart_group:

        datamart_group_items = ['sp_tdaily_inforce_policy','sp_tpolicy_summary','sp_tcustomer_summary','sp_titem_inforce','sp_titem_summary','sp_tinternal_coverage_inforce','sp_tinternal_coverage_summary']

        sp_tdaily_inforce_policy = MsSqlOperator(
            task_id='sp_tdaily_inforce_policy',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tdaily_inforce_policy",
            database="vault_edw",
            autocommit=True,
        )

        sp_tpolicy_summary = MsSqlOperator(
            task_id='sp_tpolicy_summary',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tpolicy_summary",
            database="vault_edw",
            autocommit=True,
        )

        sp_tcustomer_summary = MsSqlOperator(
            task_id='sp_tcustomer_summary',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tcustomer_summary",
            database="vault_edw",
            autocommit=True,
        )

        sp_titem_inforce = MsSqlOperator(
            task_id='sp_titem_inforce',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_titem_inforce",
            database="vault_edw",
            autocommit=True,
        )

        sp_titem_summary = MsSqlOperator(
            task_id='sp_titem_summary',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_titem_summary",
            database="vault_edw",
            autocommit=True,
        )

        sp_tinternal_coverage_inforce = MsSqlOperator(
            task_id='sp_tinternal_coverage_inforce',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tinternal_coverage_inforce",
            database="vault_edw",
            autocommit=True,
        )

        sp_tinternal_coverage_summary = MsSqlOperator(
            task_id='sp_tinternal_coverage_summary',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tinternal_coverage_summary",
            database="vault_edw",
            autocommit=True,
        )

        send_datamart_email = EmailOperator(
            task_id='send_datamart_email',
            to=to_email,
            subject='Airflow - Datamart tables loaded successfully',
            html_content=get_sp_success_data_HTML(datamart_group_items, 'All stored procedures executed successfully for all the Datamart tables'),
        )

        sp_tdaily_inforce_policy >> sp_tpolicy_summary >> sp_tcustomer_summary >> sp_titem_inforce >> sp_titem_summary >> sp_tinternal_coverage_inforce >> sp_tinternal_coverage_summary >> send_datamart_email

    with TaskGroup("reference_group") as reference_group:

        reference_group_items = ['sp_tbroker','sp_tcustomer','sp_tuser','sp_tinternal_coverage','sp_ttax_fee_surcharge']

        sp_tbroker = MsSqlOperator(
            task_id='sp_tbroker',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tbroker",
            database="vault_edw",
            autocommit=True,
        )

        sp_tcustomer = MsSqlOperator(
            task_id='sp_tcustomer',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tcustomer",
            database="vault_edw",
            autocommit=True,
        )

        sp_tuser = MsSqlOperator(
            task_id='sp_tuser',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tuser",
            database="vault_edw",
            autocommit=True,
        )

        sp_tinternal_coverage = MsSqlOperator(
            task_id='sp_tinternal_coverage',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tinternal_coverage",
            database="vault_edw",
            autocommit=True,
        )

        sp_ttax_fee_surcharge = MsSqlOperator(
            task_id='sp_ttax_fee_surcharge',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_ttax_fee_surcharge",
            database="vault_edw",
            autocommit=True,
        )

        send_reference_email = EmailOperator(
            task_id='send_reference_email',
            to=to_email,
            subject='Airflow - Reference tables loaded successfully',
            html_content=get_sp_success_data_HTML(reference_group_items, 'All stored procedures executed successfully for all the Reference tables'),
        )

        sp_tbroker >> sp_tcustomer >> sp_tuser >> sp_tinternal_coverage >> sp_ttax_fee_surcharge >> send_reference_email

    with TaskGroup("policy_group") as policy_group:

        policy_group_items = ['sp_tpolicy','sp_tpolicy_history', 'sp_tpolicy_insured', 'sp_tloss_history', 'sp_tadditional_interest']

        sp_tpolicy = MsSqlOperator(
            task_id='sp_tpolicy',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tpolicy",
            database="vault_edw",
            autocommit=True,
        )

        sp_tpolicy_history = MsSqlOperator(
            task_id='sp_tpolicy_history',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tpolicy_history",
            database="vault_edw",
            autocommit=True,
        )

        sp_tpolicy_insured = MsSqlOperator(
            task_id='sp_tpolicy_insured',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tpolicy_insured",
            database="vault_edw",
            autocommit=True,
        )

        sp_tloss_history = MsSqlOperator(
            task_id='sp_tloss_history',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tloss_history",
            database="vault_edw",
            autocommit=True,
        )

        sp_tadditional_interest = MsSqlOperator(
            task_id='sp_tadditional_interest',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tadditional_interest",
            database="vault_edw",
            autocommit=True,
        )

        send_policy_email = EmailOperator(
            task_id='send_policy_email',
            to=to_email,
            subject='Airflow - Policy tables loaded successfully',
            html_content=get_sp_success_data_HTML(policy_group_items, 'All stored procedures executed successfully for all the Policy tables'),
        )

        sp_tpolicy >> sp_tpolicy_history >> sp_tpolicy_insured >> sp_tloss_history >> sp_tadditional_interest >> send_policy_email


    end = DummyOperator(
        task_id='end',
    )

start >> ADF_group >> reference_group >> policy_group >> [home_group , PEL_group, collection_group] >> policy_transaction_group >> datamart_group >> end