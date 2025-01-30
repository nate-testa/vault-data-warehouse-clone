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

to_email = "itdatateam@vault.insurance"
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
                ORDER BY ts.validation_sql_desc
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

        adf_etl_load_ebao_pub_user: BaseOperator = AzureDataFactoryRunPipelineOperator(
            task_id="adf_etl_load_ebao_pub_user",
            azure_data_factory_conn_id='azure_data_factory_vault_data',
            pipeline_name="t_pub_user_eBao_to_Edw_stage_FullLoad",
            # parameters={"myParam": "value"},
        )

        adf_etl_load_ebao_pub_diary: BaseOperator = AzureDataFactoryRunPipelineOperator(
            task_id="adf_etl_load_ebao_pub_diary",
            azure_data_factory_conn_id='azure_data_factory_vault_data',
            pipeline_name="t_pub_diary_eBao_to_Edw_stage_FullLoad",
            # parameters={"myParam": "value"},
        )

        adf_etl_load_ls_aws_dms: BaseOperator = AzureDataFactoryRunPipelineOperator(
            task_id="adf_etl_load_ls_aws_dms",
            azure_data_factory_conn_id='azure_data_factory_vault_data',
            pipeline_name="LS_AWS_DMS_dmsDocument",
            # parameters={"myParam": "value"},
        )        

        send_adf_email = EmailOperator(
            task_id='send_adf_email',
            to=to_email,
            subject='Airflow - ADF pipelines executed successfully',
            html_content=get_HTML_on_vault_format('The Azure Data Factory pipelines executed successfully',''),
        )

        adf_etl_load_stage >> adf_etl_load_ebao_mqq >> adf_etl_load_ebao_mqq_address >> adf_etl_load_ebao_pub_user >> adf_etl_load_ebao_pub_diary >> adf_etl_load_ls_aws_dms >> send_adf_email


    with TaskGroup("home_group") as home_group:

        home_group_items = [
            'sp_thome_location',
            'sp_thome_coverage',
            'sp_tmortgagee',
            'sp_thome_additional_coverage',
            'sp_thome_coverage_ext'
        ]

        operators = []
        for item in home_group_items:
            operator = MsSqlOperator(
                task_id=item,
                mssql_conn_id='Vault_EDW',
                sql=f"EXEC edw_core.{item}",
                database="vault_edw",
                autocommit=True,
            )
            operators.append(operator)

        send_home_email = EmailOperator(
            task_id='send_home_email',
            to=to_email,
            subject='Airflow - Home tables loaded successfully',
            html_content=get_sp_success_data_HTML(home_group_items, 'All stored procedures executed successfully for all the Home tables'),
        )

        for i in range(len(operators) - 1):
            operators[i] >> operators[i + 1]

        operators[-1] >> send_home_email

    
    collection_marine = DummyOperator(
        task_id='collection_marine',
    )

    with TaskGroup("collection_group") as collection_group:

        collection_group_items = [
            'sp_tcollection_location',
            'sp_tcollection_coverage',
            'sp_tcollection_class_type',
            'sp_tcollection_scheduled_item'
        ]

        operators = []
        for item in collection_group_items:
            operator = MsSqlOperator(
                task_id=item,
                mssql_conn_id='Vault_EDW',
                sql=f"EXEC edw_core.{item}",
                database="vault_edw",
                autocommit=True,
            )
            operators.append(operator)

        send_collection_email = EmailOperator(
            task_id='send_collection_email',
            to=to_email,
            subject='Airflow - Collection tables loaded successfully',
            html_content=get_sp_success_data_HTML(collection_group_items, 'All stored procedures executed successfully for all the Collection tables'),
        )

        for i in range(len(operators) - 1):
            operators[i] >> operators[i + 1]

        operators[-1] >> send_collection_email


    with TaskGroup("marine_group") as marine_group:

        marine_group_items = [
            'sp_tmarine_boat_yacht',
            'sp_tmarine_boat_yacht_location',
            'sp_tmarine_boat_yacht_coverage',
            'sp_tmarine_boat_yacht_operator',
            'sp_tmarine_boat_yacht_watercraft'
        ]

        operators = []
        for item in marine_group_items:
            operator = MsSqlOperator(
                task_id=item,
                mssql_conn_id='Vault_EDW',
                sql=f"EXEC edw_core.{item}",
                database="vault_edw",
                autocommit=True,
            )
            operators.append(operator)

        send_marine_email = EmailOperator(
            task_id='send_marine_email',
            to=to_email,
            subject='Airflow - Marine tables loaded successfully',
            html_content=get_sp_success_data_HTML(marine_group_items, 'All stored procedures executed successfully for all the Marine tables'),
        )

        for i in range(len(operators) - 1):
            operators[i] >> operators[i + 1]

        operators[-1] >> send_marine_email


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

        operators = []
        for item in PEL_group_items:
            operator = MsSqlOperator(
                task_id=item,
                mssql_conn_id='Vault_EDW',
                sql=f"EXEC edw_core.{item}",
                database="vault_edw",
                autocommit=True,
            )
            operators.append(operator)

        send_PEL_email = EmailOperator(
            task_id='send_PEL_email',
            to=to_email,
            subject='Airflow - PEL tables loaded successfully',
            html_content=get_sp_success_data_HTML(PEL_group_items, 'All stored procedures executed successfully for all the PEL tables'),
        )

        for i in range(len(operators) - 1):
            operators[i] >> operators[i + 1]

        operators[-1] >> send_PEL_email


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

        operators = []
        for item in auto_group_items:
            operator = MsSqlOperator(
                task_id=item,
                mssql_conn_id='Vault_EDW',
                sql=f"EXEC edw_core.{item}",
                database="vault_edw",
                autocommit=True,
            )
            operators.append(operator)

        send_auto_email = EmailOperator(
            task_id='send_auto_email',
            to=to_email,
            subject='Airflow - Auto tables loaded successfully',
            html_content=get_sp_success_data_HTML(auto_group_items, 'All stored procedures executed successfully for all the Auto tables'),
        )

        for i in range(len(operators) - 1):
            operators[i] >> operators[i + 1]

        operators[-1] >> send_auto_email


    with TaskGroup("policy_transaction_group") as policy_transaction_group:

        policy_transaction_group_items = [
            'sp_tpolicy_transaction',
            'sp_tpolicy_transaction_update',
            'sp_thome_coverage_update',
            'sp_tpolicy_update_cancels',
            'sp_treconciliation'
        ]

        operators = []
        for item in policy_transaction_group_items:
            operator = MsSqlOperator(
                task_id=item,
                mssql_conn_id='Vault_EDW',
                sql=f"EXEC edw_core.{item}",
                database="vault_edw",
                autocommit=True,
            )
            operators.append(operator)

        send_policy_transaction_email = EmailOperator(
            task_id='send_policy_transaction_email',
            to=to_email,
            subject='Airflow - Policy_transaction tables loaded successfully',
            html_content=get_sp_success_data_HTML(policy_transaction_group_items, 'All stored procedures executed successfully for all the Policy Transaction tables'),
        )

        for i in range(len(operators) - 1):
            operators[i] >> operators[i + 1]

        operators[-1] >> send_policy_transaction_email


    with TaskGroup("claim_group") as claim_group:

        claim_group_items = [
            'sp_tcatastrophe_snapsheet',
            'sp_tclaim_cost_category_snapsheet',
            'sp_tcause_of_loss_snapsheet',
            'sp_tclaim_snapsheet',
            'sp_tclaim_feature_snapsheet',
            'sp_tclaim_payment_snapsheet',
            'sp_tclaim_transaction_snapsheet',
            'sp_tclaim_note_snapsheet',
            'sp_tclaim_task_snapsheet',
            'sp_update_tclaim_snapsheet',
            'sp_update_tclaim_feature_snapsheet',
            'sp_tpolicy_update_lifetime_claims'
            ]

        operators = []
        for item in claim_group_items:
            operator = MsSqlOperator(
                task_id=item,
                mssql_conn_id='Vault_EDW',
                sql=f"EXEC edw_core.{item}",
                database="vault_edw",
                autocommit=True,
            )
            operators.append(operator)       

        treconciliation_email = PythonOperator(
            task_id='treconciliation_email',
            python_callable=check_treconciliation_and_send_email,
            provide_context=True,
            dag=dag,
        )

        send_claim_email = EmailOperator(
            task_id='send_claim_email',
            to=to_email,
            subject='Airflow - Claim tables loaded successfully',
            html_content=get_sp_success_data_HTML(claim_group_items, 'All stored procedures executed successfully for all the Claim tables'),
        )

        for i in range(len(operators) - 1):
            operators[i] >> operators[i + 1]

        operators[-1] >> treconciliation_email >> send_claim_email


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

        send_datamart_email = EmailOperator(
            task_id='send_datamart_email',
            to=to_email,
            subject='Airflow - Datamart tables loaded successfully',
            html_content=get_sp_success_data_HTML(datamart_group_items, 'All stored procedures executed successfully for all the Datamart tables'),
        )

        for i in range(len(operators) - 1):
            operators[i] >> operators[i + 1]

        operators[-1] >> send_datamart_email


    with TaskGroup("reference_group") as reference_group:

        reference_group_items = [
            'sp_tcustomer',
            'sp_tuser',
            'sp_tinternal_coverage',
            'sp_ttax_fee_surcharge',
            'sp_tbillingaccount'
        ]

        operators = []
        for item in reference_group_items:
            operator = MsSqlOperator(
                task_id=item,
                mssql_conn_id='Vault_EDW',
                sql=f"EXEC edw_core.{item}",
                database="vault_edw",
                autocommit=True,
            )
            operators.append(operator)

        new_internal_coverage_cd_email = PythonOperator(
            task_id='new_internal_coverage_cd_email',
            python_callable=check_for_new_internal_coverage_cd_and_send_email,
            provide_context=True,
            dag=dag,
        )

        send_reference_email = EmailOperator(
            task_id='send_reference_email',
            to=to_email,
            subject='Airflow - Reference tables loaded successfully',
            html_content=get_sp_success_data_HTML(reference_group_items, 'All stored procedures executed successfully for all the Reference tables'),
        )

        operators[0] >> operators[1] >> operators[2] >> new_internal_coverage_cd_email >> operators[3] >> operators[4] >> send_reference_email


    with TaskGroup("broker_group") as broker_group:

        broker_group_items = [
            'sp_tbroker',
            'sp_tbroker_relation',
            'sp_tbroker_commission',
            'sp_tbroker_license',
            'sp_tbroker_vault_team',
            'sp_tproducer'
        ]

        operators = []
        for item in broker_group_items:
            operator = MsSqlOperator(
                task_id=item,
                mssql_conn_id='Vault_EDW',
                sql=f"EXEC edw_core.{item}",
                database="vault_edw",
                autocommit=True,
            )
            operators.append(operator)

        send_broker_email = EmailOperator(
            task_id='send_broker_email',
            to=to_email,
            subject='Airflow - Broker tables loaded successfully',
            html_content=get_sp_success_data_HTML(broker_group_items, 'All stored procedures executed successfully for all the Broker tables'),
        )

        for i in range(len(operators) - 1):
            operators[i] >> operators[i + 1]

        operators[-1] >> send_broker_email


    with TaskGroup("policy_group") as policy_group:

        policy_group_items = [
            'sp_tpolicy',
            'sp_tpolicy_update_non_renwal_billing',
            'sp_tpolicy_history', 
            'sp_tpolicy_insured', 
            'sp_tpolicy_insured_update',
            'sp_tloss_history', 
            'sp_tadditional_interest', 
            'sp_ttask_workflow',
            'sp_ttask_workflow_step',
            'sp_ttask', 
            'sp_tmanuscript',
            'sp_tnote',
            'sp_tpolicy_referral_message',
            'sp_tpolicy_form'
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

        send_policy_email = EmailOperator(
            task_id='send_policy_email',
            to=to_email,
            subject='Airflow - Policy tables loaded successfully',
            html_content=get_sp_success_data_HTML(policy_group_items, 'All stored procedures executed successfully for all the Policy tables'),
        )

        for i in range(len(operators) - 1):
            operators[i] >> operators[i + 1]

        operators[-1] >> send_policy_email


    with TaskGroup("validation_result_group") as validation_result_group:

        validation_result_group_items = [
            'sp_tvalidation_result'
        ]

        operators = []
        for item in validation_result_group_items:
            operator = MsSqlOperator(
                task_id=item,
                mssql_conn_id='Vault_EDW',
                sql=f"EXEC edw_core.{item}",
                database="vault_edw",
                autocommit=True,
            )
            operators.append(operator)

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

        for i in range(len(operators) - 1):
            operators[i] >> operators[i + 1]

        operators[-1] >> tvalidation_email >> send_validation_email


    with TaskGroup("integration_group") as integration_group:

        integration_group_items = [
            'sp_tclaim_policy_search_api',
            'sp_policy_claim_search_dms_api',
            'sp_tclaim_symbility_api', 
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

        exec_Snapsheet_Daily_Feed = TriggerDagRunOperator(
            task_id="exec_Snapsheet_Daily_Feed",
            trigger_dag_id="Snapsheet_Daily_Feed",
            dag=dag,
        )

        operators = []
        for item in integration_group_items:
            operator = MsSqlOperator(
                task_id=item,
                mssql_conn_id='Vault_EDW',
                sql=f"EXEC edw_core.{item}",
                database="vault_edw",
                autocommit=True,
            )
            operators.append(operator)

        ivans_api_call = PythonOperator(
            task_id='ivans_api_call',
            python_callable=call_ivans_api,
            provide_context=True,
            dag=dag,
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

        exec_vault_redzone_feed = TriggerDagRunOperator(
            task_id="exec_vault_redzone_feed",
            trigger_dag_id="vault_redzone_feed",
            dag=dag,
        )

        exec_vault_CLUE_property_daily_feed = TriggerDagRunOperator(
            task_id="exec_vault_CLUE_property_daily_feed",
            trigger_dag_id="vault_CLUE_property_daily_feed",
            dag=dag,
        )

        send_integration_email = EmailOperator(
            task_id='send_integration_email',
            to=to_email,
            subject='Airflow - Integration tables loaded successfully',
            html_content=get_sp_success_data_HTML(integration_group_items, 'All stored procedures executed successfully for all the integration tables'),
        )

        exec_Snapsheet_Daily_Feed >> operators[0] >> operators[1] >> operators[2] >> operators[3] >> operators[4] >> operators[5] >> operators[6] >> operators[7] >> ivans_api_call >> operators[8] >> generate_livevox_file >> upload_livevox_file_to_sftp >> operators[9] >> operators[10] >> operators[11] >> exec_vault_redzone_feed >> exec_vault_CLUE_property_daily_feed >> send_integration_email

    exec_vault_edw_data_load_quotes = TriggerDagRunOperator(
        task_id="exec_vault_edw_data_load_quotes",
        trigger_dag_id="vault_edw_data_load_quotes",
        dag=dag,
    )

    end = DummyOperator(
        task_id='end',
    )


start >> ADF_group >> reference_group >> broker_group >> policy_group >> [home_group , PEL_group, auto_group] >> collection_marine >> [collection_group, marine_group] >> policy_transaction_group >> claim_group >> datamart_group >> integration_group >> validation_result_group >> exec_vault_edw_data_load_quotes >> end
