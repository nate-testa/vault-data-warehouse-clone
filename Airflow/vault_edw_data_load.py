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
from livevox_csv_generation import SFTPUploadLiveVoxOperator, generate_livevox_csv_file
from ivans_api import call_ivans_api

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

def check_for_new_internal_coverage_cd_and_send_email(**kwargs):
    sql_qry = """
                SELECT internal_coverage_sk, internal_coverage_cd, product_cd, aslob_cd, internal_coverage_category_nm, primary_coverage_cd
                FROM edw_core.tinternal_coverage
                WHERE CAST(create_ts as date) = CAST(GETDATE() as date)
                ORDER BY internal_coverage_sk
              """
    mssql_hook = MsSqlHook(mssql_conn_id='Vault_EDW')
    result = mssql_hook.get_first(sql_qry)
    if result is not None:
        EmailOperator(
            task_id='send_email_new_internal_coverage',
            to=to_email,
            subject='Airflow - New Internal Coverage created',
            html_content=get_vault_data_HTML(sql_qry,'There are new Internal Coverage rows created into edw_core.tinternal_coverage table. Please review the details below.'),
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
    catchup=False,
    max_active_runs=1,
    default_args=args,
    start_date=pendulum.datetime(2023, 8, 7, tz="America/New_York"),
    schedule_interval='30 0 * * *', # At 12:30 every day
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

        adf_etl_load_ebao_mqq: BaseOperator = AzureDataFactoryRunPipelineOperator(
            task_id="adf_etl_load_ebao_mqq",
            azure_data_factory_conn_id='azure_data_factory_vault_data',
            pipeline_name="MetadataDrivenCopy_eBao_to_Edw_stage_FullLoad_mqq_TopLevel",
            # parameters={"myParam": "value"},
        )

        adf_etl_load_ebao_mqq_address: BaseOperator = AzureDataFactoryRunPipelineOperator(
            task_id="adf_etl_load_ebao_mqq_address",
            azure_data_factory_conn_id='azure_data_factory_vault_data',
            pipeline_name="MetadataDrivenCopy_eBao_to_Edw_stage_FullLoad_mqq_TopLevel_t_pub_address",
            # parameters={"myParam": "value"},
        )

        adf_etl_load_ebao_mqq_diary: BaseOperator = AzureDataFactoryRunPipelineOperator(
            task_id="adf_etl_load_ebao_mqq_diary",
            azure_data_factory_conn_id='azure_data_factory_vault_data',
            pipeline_name="MetadataDrivenCopy_eBao_to_Edw_stage_FullLoad_mqq_TopLevel_t_pub_diary",
            # parameters={"myParam": "value"},
        )        

        send_adf_email = EmailOperator(
            task_id='send_adf_email',
            to=to_email,
            subject='Airflow - ADF pipelines executed successfully',
            html_content=get_HTML_on_vault_format('The Azure Data Factory pipelines executed successfully',''),
        )

        adf_etl_load_stage >> adf_etl_load_ebao_mqq >> adf_etl_load_ebao_mqq_address >> adf_etl_load_ebao_mqq_diary >> send_adf_email


    with TaskGroup("home_group") as home_group:

        home_group_items = ['sp_thome_location','sp_thome_coverage','sp_thome_coverage_update','sp_tmortgagee','sp_thome_additional_coverage']

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

        sp_thome_coverage_update = MsSqlOperator(
            task_id='sp_thome_coverage_update',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_thome_coverage_update",
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

        sp_thome_location >> sp_thome_coverage >> sp_thome_coverage_update >> sp_tmortgagee >> sp_thome_additional_coverage >> send_home_email


    with TaskGroup("collection_group") as collection_group:

        collection_group_items = ['sp_tcollection_location','sp_tcollection_coverage','sp_tcollection_class_type','sp_tcollection_scheduled_item']
        
        sp_tcollection_location = MsSqlOperator(
            task_id='sp_tcollection_location',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tcollection_location",
            database="vault_edw",
            autocommit=True,
        )

        sp_tcollection_class_type = MsSqlOperator(
            task_id='sp_tcollection_class_type',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tcollection_class_type",
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

        sp_tcollection_scheduled_item = MsSqlOperator(
            task_id='sp_tcollection_scheduled_item',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tcollection_scheduled_item",
            database="vault_edw",
            autocommit=True,
        )

        send_collection_email = EmailOperator(
            task_id='send_collection_email',
            to=to_email,
            subject='Airflow - Collection tables loaded successfully',
            html_content=get_sp_success_data_HTML(collection_group_items, 'All stored procedures executed successfully for all the Collection tables'),
        )

        sp_tcollection_location >> sp_tcollection_coverage >> sp_tcollection_class_type >> sp_tcollection_scheduled_item >> send_collection_email


    with TaskGroup("PEL_group") as PEL_group:

        PEL_group_items = [
            'sp_tpel_location',
            'sp_tpel_driver',
            'sp_tpel_driver_incident',
            'sp_tpel_vehicle',
            'sp_tpel_watercraft',
            'sp_tpel_coverage',
            'sp_tpel_vehicle_rapa'
            ]

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

        sp_tpel_vehicle_rapa = MsSqlOperator(
            task_id='sp_tpel_vehicle_rapa',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tpel_vehicle_rapa",
            database="vault_edw",
            autocommit=True,
        )

        send_PEL_email = EmailOperator(
            task_id='send_PEL_email',
            to=to_email,
            subject='Airflow - PEL tables loaded successfully',
            html_content=get_sp_success_data_HTML(PEL_group_items, 'All stored procedures executed successfully for all the PEL tables'),
        )

        sp_tpel_location >> sp_tpel_driver >> sp_tpel_driver_incident >> sp_tpel_vehicle >> sp_tpel_watercraft >> sp_tpel_coverage >> sp_tpel_vehicle_rapa >> send_PEL_email


    with TaskGroup("auto_group") as auto_group:

        auto_group_items = [
            'sp_tauto_vehicle',
            'sp_tauto_garage_location',
            'sp_tauto_vehicle_coverage',
            'sp_tauto_vehicle_coverage_update',
            'sp_tauto_policy_coverage',
            'sp_tauto_driver',
            'sp_tauto_driver_incident',
            'sp_tauto_vehicle_coverage_rapa'
            ]

        sp_tauto_vehicle = MsSqlOperator(
            task_id='sp_tauto_vehicle',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tauto_vehicle",
            database="vault_edw",
            autocommit=True,
        )

        sp_tauto_garage_location = MsSqlOperator(
            task_id='sp_tauto_garage_location',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tauto_garage_location",
            database="vault_edw",
            autocommit=True,
        )

        sp_tauto_vehicle_coverage = MsSqlOperator(
            task_id='sp_tauto_vehicle_coverage',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tauto_vehicle_coverage",
            database="vault_edw",
            autocommit=True,
        )

        sp_tauto_vehicle_coverage_update = MsSqlOperator(
            task_id='sp_tauto_vehicle_coverage_update',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tauto_vehicle_coverage_update",
            database="vault_edw",
            autocommit=True,
        )
        
        sp_tauto_policy_coverage = MsSqlOperator(
            task_id='sp_tauto_policy_coverage',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tauto_policy_coverage",
            database="vault_edw",
            autocommit=True,
        )

        sp_tauto_driver = MsSqlOperator(
            task_id='sp_tauto_driver',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tauto_driver",
            database="vault_edw",
            autocommit=True,
        )

        sp_tauto_driver_incident = MsSqlOperator(
            task_id='sp_tauto_driver_incident',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tauto_driver_incident",
            database="vault_edw",
            autocommit=True,
        )

        sp_tauto_vehicle_coverage_rapa = MsSqlOperator(
            task_id='sp_tauto_vehicle_coverage_rapa',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tauto_vehicle_coverage_rapa",
            database="vault_edw",
            autocommit=True,
        )

        send_auto_email = EmailOperator(
            task_id='send_auto_email',
            to=to_email,
            subject='Airflow - Auto tables loaded successfully',
            html_content=get_sp_success_data_HTML(auto_group_items, 'All stored procedures executed successfully for all the Auto tables'),
        )

        sp_tauto_vehicle >> sp_tauto_garage_location >> sp_tauto_vehicle_coverage >> sp_tauto_vehicle_coverage_update >> sp_tauto_policy_coverage >> sp_tauto_driver >> sp_tauto_driver_incident >> sp_tauto_vehicle_coverage_rapa >> send_auto_email


    with TaskGroup("policy_transaction_group") as policy_transaction_group:

        policy_transaction_group_items = ['sp_tpolicy_transaction','sp_tpolicy_transaction_update','sp_tpolicy_update_cancels','sp_treconciliation']

        sp_tpolicy_transaction = MsSqlOperator(
            task_id='sp_tpolicy_transaction',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tpolicy_transaction",
            database="vault_edw",
            autocommit=True,
        )

        sp_tpolicy_transaction_update = MsSqlOperator(
            task_id='sp_tpolicy_transaction_update',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tpolicy_transaction_update",
            database="vault_edw",
            autocommit=True,
        )

        sp_tpolicy_update_cancels = MsSqlOperator(
            task_id='sp_tpolicy_update_cancels',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tpolicy_update_cancels",
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

        sp_tpolicy_transaction >> sp_tpolicy_transaction_update >> sp_tpolicy_update_cancels >> sp_treconciliation >> treconciliation_email >> send_policy_transaction_email


    with TaskGroup("claim_group") as claim_group:

        claim_group_items = [
            'sp_tcatastrophe',
            'sp_tcause_of_loss',
            'sp_tsub_cause_of_loss',
            'sp_tclaim',
            'sp_ebao_tclaim_onetime_datafix',
            'sp_tclaim_feature',
            'sp_tclaim_payment',
            'sp_tclaim_transaction',
            'sp_tclaim_note',
            'sp_tclaim_diary',
            'sp_update_tclaim',
            'sp_update_tclaim_feature',
            'sp_treconciliation_ebao',
            'sp_tclaim_litigation'
            ]

        sp_tcatastrophe = MsSqlOperator(
            task_id='sp_tcatastrophe',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tcatastrophe",
            database="vault_edw",
            autocommit=True,
        )

        sp_tcause_of_loss = MsSqlOperator(
            task_id='sp_tcause_of_loss',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tcause_of_loss",
            database="vault_edw",
            autocommit=True,
        )

        sp_tsub_cause_of_loss = MsSqlOperator(
            task_id='sp_tsub_cause_of_loss',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tsub_cause_of_loss",
            database="vault_edw",
            autocommit=True,
        )

        sp_tclaim = MsSqlOperator(
            task_id='sp_tclaim',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tclaim",
            database="vault_edw",
            autocommit=True,
        )

        sp_ebao_tclaim_onetime_datafix = MsSqlOperator(
            task_id='sp_ebao_tclaim_onetime_datafix',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_ebao_tclaim_onetime_datafix",
            database="vault_edw",
            autocommit=True,
        )

        sp_tclaim_feature = MsSqlOperator(
            task_id='sp_tclaim_feature',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tclaim_feature",
            database="vault_edw",
            autocommit=True,
        )

        sp_tclaim_payment = MsSqlOperator(
            task_id='sp_tclaim_payment',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tclaim_payment",
            database="vault_edw",
            autocommit=True,
        )

        sp_tclaim_transaction = MsSqlOperator(
            task_id='sp_tclaim_transaction',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tclaim_transaction",
            database="vault_edw",
            autocommit=True,
        )

        sp_tclaim_note = MsSqlOperator(
            task_id='sp_tclaim_note',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tclaim_note",
            database="vault_edw",
            autocommit=True,
        )

        sp_tclaim_diary = MsSqlOperator(
            task_id='sp_tclaim_diary',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tclaim_diary",
            database="vault_edw",
            autocommit=True,
        )

        sp_update_tclaim = MsSqlOperator(
            task_id='sp_update_tclaim',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_update_tclaim",
            database="vault_edw",
            autocommit=True,
        )

        sp_update_tclaim_feature = MsSqlOperator(
            task_id='sp_update_tclaim_feature',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_update_tclaim_feature",
            database="vault_edw",
            autocommit=True,
        )

        sp_treconciliation_ebao = MsSqlOperator(
            task_id='sp_treconciliation_ebao',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_treconciliation_ebao",
            database="vault_edw",
            autocommit=True,
        )

        sp_tclaim_litigation = MsSqlOperator(
            task_id='sp_tclaim_litigation',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tclaim_litigation",
            database="vault_edw",
            autocommit=True,
        )

        send_claim_email = EmailOperator(
            task_id='send_claim_email',
            to=to_email,
            subject='Airflow - Claim tables loaded successfully',
            html_content=get_sp_success_data_HTML(claim_group_items, 'All stored procedures executed successfully for all the Claim tables'),
        )

        sp_tcatastrophe >> sp_tcause_of_loss >> sp_tsub_cause_of_loss >> sp_tclaim >> sp_ebao_tclaim_onetime_datafix >> sp_tclaim_feature >> sp_tclaim_payment >> sp_tclaim_transaction >> sp_tclaim_note >> sp_tclaim_diary >> sp_update_tclaim >> sp_update_tclaim_feature >> sp_treconciliation_ebao >> sp_tclaim_litigation >> send_claim_email


    with TaskGroup("datamart_group") as datamart_group:

        datamart_group_items = [
            'sp_tdaily_inforce_policy',
            'sp_tpolicy_summary',
            'sp_tpolicy_transaction_summary',
            'sp_tcustomer_summary',
            'sp_titem_inforce',
            'sp_titem_summary',
            'sp_tinternal_coverage_inforce',
            'sp_tinternal_coverage_summary',
            'sp_tclaim_feature_summary',
            'sp_tclaim_summary'
            ]

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

        sp_tpolicy_transaction_summary = MsSqlOperator(
            task_id='sp_tpolicy_transaction_summary',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tpolicy_transaction_summary",
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
        
        sp_tclaim_feature_summary = MsSqlOperator(
            task_id='sp_tclaim_feature_summary',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tclaim_feature_summary",
            database="vault_edw",
            autocommit=True,
        )

        sp_tclaim_summary = MsSqlOperator(
            task_id='sp_tclaim_summary',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tclaim_summary",
            database="vault_edw",
            autocommit=True,
        )

        send_datamart_email = EmailOperator(
            task_id='send_datamart_email',
            to=to_email,
            subject='Airflow - Datamart tables loaded successfully',
            html_content=get_sp_success_data_HTML(datamart_group_items, 'All stored procedures executed successfully for all the Datamart tables'),
        )

        sp_tdaily_inforce_policy >> sp_tpolicy_summary >> sp_tpolicy_transaction_summary >> sp_tcustomer_summary >> sp_titem_inforce >> sp_titem_summary >> sp_tinternal_coverage_inforce >> sp_tinternal_coverage_summary >> sp_tclaim_feature_summary >> sp_tclaim_summary >> send_datamart_email


    with TaskGroup("reference_group") as reference_group:

        reference_group_items = ['sp_tcustomer','sp_tuser','sp_tinternal_coverage','sp_ttax_fee_surcharge','sp_tbillingaccount']

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

        new_internal_coverage_cd_email = PythonOperator(
            task_id='new_internal_coverage_cd_email',
            python_callable=check_for_new_internal_coverage_cd_and_send_email,
            provide_context=True,
            dag=dag,
        )

        sp_ttax_fee_surcharge = MsSqlOperator(
            task_id='sp_ttax_fee_surcharge',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_ttax_fee_surcharge",
            database="vault_edw",
            autocommit=True,
        )

        sp_tbillingaccount = MsSqlOperator(
            task_id='sp_tbillingaccount',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tbillingaccount",
            database="vault_edw",
            autocommit=True,
        )

        send_reference_email = EmailOperator(
            task_id='send_reference_email',
            to=to_email,
            subject='Airflow - Reference tables loaded successfully',
            html_content=get_sp_success_data_HTML(reference_group_items, 'All stored procedures executed successfully for all the Reference tables'),
        )

        sp_tcustomer >> sp_tuser >> sp_tinternal_coverage >> new_internal_coverage_cd_email >> sp_ttax_fee_surcharge >> sp_tbillingaccount >> send_reference_email


    with TaskGroup("broker_group") as broker_group:

        broker_group_items = ['sp_tbroker','sp_tbroker_relation','sp_tbroker_commission','sp_tbroker_license','sp_tbroker_vault_team', 'sp_tproducer']

        sp_tbroker = MsSqlOperator(
            task_id='sp_tbroker',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tbroker",
            database="vault_edw",
            autocommit=True,
        )

        sp_tbroker_relation = MsSqlOperator(
            task_id='sp_tbroker_relation',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tbroker_relation",
            database="vault_edw",
            autocommit=True,
        )

        sp_tbroker_commission = MsSqlOperator(
            task_id='sp_tbroker_commission',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tbroker_commission",
            database="vault_edw",
            autocommit=True,
        )

        sp_tbroker_license = MsSqlOperator(
            task_id='sp_tbroker_license',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tbroker_license",
            database="vault_edw",
            autocommit=True,
        )

        sp_tbroker_vault_team = MsSqlOperator(
            task_id='sp_tbroker_vault_team',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tbroker_vault_team",
            database="vault_edw",
            autocommit=True,
        )

        sp_tproducer = MsSqlOperator(
            task_id='sp_tproducer',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tproducer",
            database="vault_edw",
            autocommit=True,
        )

        send_broker_email = EmailOperator(
            task_id='send_broker_email',
            to=to_email,
            subject='Airflow - Broker tables loaded successfully',
            html_content=get_sp_success_data_HTML(broker_group_items, 'All stored procedures executed successfully for all the Broker tables'),
        )

        sp_tbroker >> sp_tbroker_relation >> sp_tbroker_commission >> sp_tbroker_license >> sp_tbroker_vault_team >> sp_tproducer >> send_broker_email


    with TaskGroup("policy_group") as policy_group:

        policy_group_items = [
            'sp_tpolicy',
            'sp_tpolicy_history', 
            'sp_tpolicy_insured', 
            'sp_tloss_history', 
            'sp_tadditional_interest', 
            'sp_tpolicy_update_non_renwal_billing',
            'sp_ttask_workflow',
            'sp_ttask_workflow_step',
            'sp_ttask', 
            'sp_tmanuscript',
            'sp_tnote',
            'sp_tpolicy_referral_message'
            ]

        sp_tpolicy = MsSqlOperator(
            task_id='sp_tpolicy',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tpolicy",
            database="vault_edw",
            autocommit=True,
        )

        sp_tpolicy_update_non_renwal_billing = MsSqlOperator(
            task_id='sp_tpolicy_update_non_renwal_billing',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tpolicy_update_non_renwal_billing",
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

        sp_ttask_workflow = MsSqlOperator(
            task_id='sp_ttask_workflow',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_ttask_workflow",
            database="vault_edw",
            autocommit=True,
        )

        sp_ttask_workflow_step = MsSqlOperator(
            task_id='sp_ttask_workflow_step',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_ttask_workflow_step",
            database="vault_edw",
            autocommit=True,
        )

        sp_ttask = MsSqlOperator(
            task_id='sp_ttask',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_ttask",
            database="vault_edw",
            autocommit=True,
        )

        sp_tmanuscript = MsSqlOperator(
            task_id='sp_tmanuscript',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tmanuscript",
            database="vault_edw",
            autocommit=True,
        )

        sp_tnote = MsSqlOperator(
            task_id='sp_tnote',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tnote",
            database="vault_edw",
            autocommit=True,
        )

        sp_tpolicy_referral_message = MsSqlOperator(
            task_id='sp_tpolicy_referral_message',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tpolicy_referral_message",
            database="vault_edw",
            autocommit=True,
        )

        send_policy_email = EmailOperator(
            task_id='send_policy_email',
            to=to_email,
            subject='Airflow - Policy tables loaded successfully',
            html_content=get_sp_success_data_HTML(policy_group_items, 'All stored procedures executed successfully for all the Policy tables'),
        )

        sp_tpolicy >> sp_tpolicy_update_non_renwal_billing >> sp_tpolicy_history >> sp_tpolicy_insured >> sp_tloss_history >> sp_tadditional_interest >> sp_ttask_workflow >> sp_ttask_workflow_step >> sp_ttask >> sp_tmanuscript >> sp_tnote >> sp_tpolicy_referral_message >> send_policy_email


    # with TaskGroup("vendor_report_group") as vendor_report_group:

    #     vendor_report_group_items = ['sp_tvendor_report']

    #     sp_tvendor_report_CarfaxVin = MsSqlOperator(
    #         task_id='sp_tvendor_report_CarfaxVin',
    #         mssql_conn_id='Vault_EDW',
    #         sql="EXEC edw_core.sp_tvendor_report 'CarfaxVin'",
    #         database="vault_edw",
    #         autocommit=True,
    #     )

    #     sp_tvendor_report_ClueProperty = MsSqlOperator(
    #         task_id='sp_tvendor_report_ClueProperty',
    #         mssql_conn_id='Vault_EDW',
    #         sql="EXEC edw_core.sp_tvendor_report 'Clue Property'",
    #         database="vault_edw",
    #         autocommit=True,
    #     )

    #     sp_tvendor_report_GuyCarpenter = MsSqlOperator(
    #         task_id='sp_tvendor_report_GuyCarpenter',
    #         mssql_conn_id='Vault_EDW',
    #         sql="EXEC edw_core.sp_tvendor_report 'GuyCarpenter'",
    #         database="vault_edw",
    #         autocommit=True,
    #     )

    #     sp_tvendor_report_IsoVin = MsSqlOperator(
    #         task_id='sp_tvendor_report_IsoVin',
    #         mssql_conn_id='Vault_EDW',
    #         sql="EXEC edw_core.sp_tvendor_report 'IsoVin'",
    #         database="vault_edw",
    #         autocommit=True,
    #     )

    #     sp_tvendor_report_LC360 = MsSqlOperator(
    #         task_id='sp_tvendor_report_LC360',
    #         mssql_conn_id='Vault_EDW',
    #         sql="EXEC edw_core.sp_tvendor_report 'LC360'",
    #         database="vault_edw",
    #         autocommit=True,
    #     )

    #     sp_tvendor_report_SAQ = MsSqlOperator(
    #         task_id='sp_tvendor_report_SAQ',
    #         mssql_conn_id='Vault_EDW',
    #         sql="EXEC edw_core.sp_tvendor_report 'SAQ'",
    #         database="vault_edw",
    #         autocommit=True,
    #     )

    #     sp_tvendor_report_TransUnion = MsSqlOperator(
    #         task_id='sp_tvendor_report_TransUnion',
    #         mssql_conn_id='Vault_EDW',
    #         sql="EXEC edw_core.sp_tvendor_report 'TransUnion'",
    #         database="vault_edw",
    #         autocommit=True,
    #     )

    #     sp_tvendor_report_IsoProperty = MsSqlOperator(
    #         task_id='sp_tvendor_report_IsoProperty',
    #         mssql_conn_id='Vault_EDW',
    #         sql="EXEC edw_core.sp_tvendor_report 'IsoProperty'",
    #         database="vault_edw",
    #         autocommit=True,
    #     )

    #     send_vendor_report_email = EmailOperator(
    #         task_id='send_vendor_report_email',
    #         to=to_email,
    #         subject='Airflow - Vendor report stored procedure executions finalized successfully',
    #         html_content=get_sp_success_data_HTML(vendor_report_group_items, 'All executions of stored procedure vendor report executed successfully'),
    #     )

    #     sp_tvendor_report_CarfaxVin >> sp_tvendor_report_ClueProperty >> sp_tvendor_report_GuyCarpenter >> sp_tvendor_report_IsoVin >> sp_tvendor_report_LC360 >> sp_tvendor_report_SAQ >> sp_tvendor_report_TransUnion >> sp_tvendor_report_IsoProperty >> send_vendor_report_email


    with TaskGroup("validation_result_group") as validation_result_group:

        validation_result_group_items = ['sp_tvalidation_result']

        sp_tvalidation_result = MsSqlOperator(
            task_id='sp_tvalidation_result',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tvalidation_result",
            database="vault_edw",
            autocommit=True,
        )

        tvalidation_email = PythonOperator(
            task_id='tvalidation_email',
            python_callable=check_tvalidation_and_send_email,
            provide_context=True,
            dag=dag,
        )

        send_validation_email = EmailOperator(
            task_id='send_validation_email',
            to=to_email,
            subject='Airflow - Validation result tables loaded successfully',
            html_content=get_sp_success_data_HTML(validation_result_group_items, 'All stored procedures executed successfully for all the validation resul tables'),
        )

        sp_tvalidation_result >> tvalidation_email >> send_validation_email


    with TaskGroup("integration_group") as integration_group:

        integration_group_items = [
            'sp_tclaim_policy_search_api',
            'sp_tclaim_symbility_api', 
            # 'sp_tpolicy_hsb_hsp_feed', 
            # 'sp_tpolicy_hsb_cyber_feed', 
            # 'sp_tpolicy_hsb_slc_feed', 
            'sp_billing_account_customer_portal_api', 
            'sp_policy_customer_portal_api',
            'sp_policy_ivans_auto_feed',
            'sp_policy_ivans_home',
            'sp_policy_ivans_pel_feed',
            'sp_customer_broker_livevox_feed',
            'sp_claim_renewal_rating_home_collection_api',
            'sp_claim_renewal_rating_auto_pel_api',
            'sp_claim_product_search_api'
            ]

        sp_tclaim_policy_search_api = MsSqlOperator(
            task_id='sp_tclaim_policy_search_api',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tclaim_policy_search_api",
            database="vault_edw",
            autocommit=True,
        )

        sp_tclaim_symbility_api = MsSqlOperator(
            task_id='sp_tclaim_symbility_api',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tclaim_symbility_api",
            database="vault_edw",
            autocommit=True,
        )

        # sp_tpolicy_hsb_hsp_feed = MsSqlOperator(
        #     task_id='sp_tpolicy_hsb_hsp_feed',
        #     mssql_conn_id='Vault_EDW',
        #     sql="EXEC edw_core.sp_tpolicy_hsb_hsp_feed",
        #     database="vault_edw",
        #     autocommit=True,
        # )

        # sp_tpolicy_hsb_cyber_feed = MsSqlOperator(
        #     task_id='sp_tpolicy_hsb_cyber_feed',
        #     mssql_conn_id='Vault_EDW',
        #     sql="EXEC edw_core.sp_tpolicy_hsb_cyber_feed",
        #     database="vault_edw",
        #     autocommit=True,
        # )

        # sp_tpolicy_hsb_slc_feed = MsSqlOperator(
        #     task_id='sp_tpolicy_hsb_slc_feed',
        #     mssql_conn_id='Vault_EDW',
        #     sql="EXEC edw_core.sp_tpolicy_hsb_slc_feed",
        #     database="vault_edw",
        #     autocommit=True,
        # )

        sp_billing_account_customer_portal_api = MsSqlOperator(
            task_id='sp_billing_account_customer_portal_api',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_billing_account_customer_portal_api",
            database="vault_edw",
            autocommit=True,
        )

        sp_policy_customer_portal_api = MsSqlOperator(
            task_id='sp_policy_customer_portal_api',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_policy_customer_portal_api",
            database="vault_edw",
            autocommit=True,
        )

        sp_policy_ivans_auto_feed = MsSqlOperator(
            task_id='sp_policy_ivans_auto_feed',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_policy_ivans_auto_feed",
            database="vault_edw",
            autocommit=True,
        )

        sp_policy_ivans_home = MsSqlOperator(
            task_id='sp_policy_ivans_home',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_policy_ivans_home",
            database="vault_edw",
            autocommit=True,
        )

        sp_policy_ivans_pel_feed = MsSqlOperator(
            task_id='sp_policy_ivans_pel_feed',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_policy_ivans_pel_feed",
            database="vault_edw",
            autocommit=True,
        )

        ivans_api_call = PythonOperator(
            task_id='ivans_api_call',
            python_callable=call_ivans_api,
            provide_context=True,
            dag=dag,
        )

        sp_customer_broker_livevox_feed = MsSqlOperator(
            task_id='sp_customer_broker_livevox_feed',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_customer_broker_livevox_feed",
            database="vault_edw",
            autocommit=True,
        )

        generate_livevox_file = PythonOperator(
            task_id='generate_livevox_file',
            python_callable=generate_livevox_csv_file,
            dag=dag,
        )

        upload_livevox_file_to_sftp = SFTPUploadLiveVoxOperator(
            task_id='upload_livevox_file_to_sftp',
            sftp_conn_id='Vault_livevox_sftp',
            dag=dag,
        )

        sp_claim_renewal_rating_home_collection_api = MsSqlOperator(
            task_id='sp_claim_renewal_rating_home_collection_api',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_claim_renewal_rating_home_collection_api",
            database="vault_edw",
            autocommit=True,
        )

        sp_claim_renewal_rating_auto_pel_api = MsSqlOperator(
            task_id='sp_claim_renewal_rating_auto_pel_api',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_claim_renewal_rating_auto_pel_api",
            database="vault_edw",
            autocommit=True,
        )

        sp_claim_product_search_api = MsSqlOperator(
            task_id='sp_claim_product_search_api',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_claim_product_search_api",
            database="vault_edw",
            autocommit=True,
        )

        send_integration_email = EmailOperator(
            task_id='send_integration_email',
            to=to_email,
            subject='Airflow - Integration tables loaded successfully',
            html_content=get_sp_success_data_HTML(integration_group_items, 'All stored procedures executed successfully for all the integration tables'),
        )

        sp_tclaim_policy_search_api >> sp_tclaim_symbility_api >> sp_billing_account_customer_portal_api >> sp_policy_customer_portal_api >> sp_policy_ivans_auto_feed >> sp_policy_ivans_home >> sp_policy_ivans_pel_feed >> ivans_api_call >> sp_customer_broker_livevox_feed >> generate_livevox_file >> upload_livevox_file_to_sftp >> sp_claim_renewal_rating_home_collection_api >> sp_claim_renewal_rating_auto_pel_api >> sp_claim_product_search_api >> send_integration_email

    exec_vault_edw_data_load_quotes = TriggerDagRunOperator(
        task_id="exec_vault_edw_data_load_quotes",
        trigger_dag_id="vault_edw_data_load_quotes",
        dag=dag,
    )

    end = DummyOperator(
        task_id='end',
    )


start >> ADF_group >> reference_group >> broker_group >> policy_group >> [home_group , PEL_group, auto_group] >> collection_group >> policy_transaction_group >> claim_group >> datamart_group >> validation_result_group >> integration_group >> exec_vault_edw_data_load_quotes >> end
