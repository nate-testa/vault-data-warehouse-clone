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
    dag_id='ebao_onetime_edw_data_load',
    catchup=False,
    max_active_runs=1,
    default_args=args,
    start_date=pendulum.datetime(2023, 8, 7, tz="America/New_York"),
     schedule_interval=None, 
    tags=["master dag", "ebao"],
) as dag:

    start = DummyOperator(
        task_id='start',
    )

    with TaskGroup("ADF_group") as ADF_group:
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

        send_adf_email = EmailOperator(
            task_id='send_adf_email',
            to=to_email,
            subject='Airflow - ADF pipelines executed successfully',
            html_content=get_HTML_on_vault_format('The Ebao Azure Data Factory pipelines executed successfully',''),
        )

        adf_etl_load_stage >> adf_etl_load_ebao_mqq >> adf_etl_load_ebao_mqq_address >> adf_etl_load_ebao_pub_user >> adf_etl_load_ebao_pub_diary >> adf_etl_load_ls_aws_dms >> send_adf_email

    with TaskGroup("claim_group") as claim_group:

        claim_group_items = [
            'sp_update_ebao_stage',
            'sp_tcatastrophe',
            'sp_tcause_of_loss',
            'sp_tsub_cause_of_loss',
            'sp_tclaim',
            'sp_ebao_tclaim_onetime_datafix',
            'sp_tclaim_feature',
            'sp_tclaim_payment',
            'sp_tclaim_transaction',
            'sp_tclaim_diary',
            'sp_update_tclaim',
            'sp_update_tclaim_feature',
            'sp_treconciliation_ebao',
            'sp_tclaim_litigation',
            'sp_tclaim_feature_summary',
            'sp_tclaim_summary'
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

    end = DummyOperator(
        task_id='end',
    )


start >> ADF_group >> claim_group >> end