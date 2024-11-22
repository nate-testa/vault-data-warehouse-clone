import pendulum
from datetime import timedelta
from airflow import DAG
from airflow.models import BaseOperator
from airflow.utils.task_group import TaskGroup
from airflow.hooks.mssql_hook import MsSqlHook
from airflow.operators.mssql_operator import MsSqlOperator
from airflow.operators.email_operator import EmailOperator
from airflow.operators.dummy_operator import DummyOperator
from airflow.operators.dagrun_operator import TriggerDagRunOperator
from airflow.providers.microsoft.azure.operators.data_factory import AzureDataFactoryRunPipelineOperator
from vault_edw_HTML_format import get_sp_success_data_HTML, get_sp_error_data_HTML, get_HTML_on_vault_format, get_vault_data_HTML

to_email = "itdatateam@vault.insurance"
# to_email = "alberto.valbuena@vault.insurance"
cc_email = ""


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
    dag_id='vault_edw_data_load_snapsheet',
    catchup=False,
    max_active_runs=1,
    default_args=args,
    start_date=pendulum.datetime(2024, 7, 1, tz="America/New_York"),
    # schedule_interval='0 4 * * *', # At 04:00 every day
    schedule_interval=None,
    tags=["dag snapsheet", "vault"],
) as dag:
    

    start = DummyOperator(
        task_id='start',
    )

    with TaskGroup("ADF_snapsheet_group") as ADF_snapsheet_group:

        edw_stage_snapsheet_from_uat_to_dev: BaseOperator = AzureDataFactoryRunPipelineOperator(
            task_id="edw_stage_snapsheet_from_uat_to_dev",
            azure_data_factory_conn_id='azure_data_factory_vault_data',
            pipeline_name="edw_stage_snapsheet_from_uat_to_dev",
            # parameters={"myParam": "value"},
        )

        send_adf_email = EmailOperator(
            task_id='send_adf_email',
            to=to_email,
            subject='Airflow - ADF Snapsheet pipelines executed successfully',
            html_content=get_HTML_on_vault_format('The Azure Data Factory pipelines executed successfully for Snapsheet data',''),
        )

        edw_stage_snapsheet_from_uat_to_dev >> send_adf_email


    
    with TaskGroup("snapsheet_group") as snapsheet_group:

        snapsheet_group_items = [
            'sp_tcatastrophe_snapsheet',
            'sp_tclaim_cost_category_snapsheet',
            'sp_tcause_of_loss_snapsheet',
            'sp_tclaim_snapsheet',
            'sp_tclaim_feature_snapsheet',
            'sp_tclaim_payment_snapsheet',
            'sp_tclaim_transaction_snapsheet',
            'sp_update_tclaim_snapsheet',
            'sp_update_tclaim_feature_snapsheet'
        ]

        operators = []
        for item in snapsheet_group_items:
            operator = MsSqlOperator(
                task_id=item,
                mssql_conn_id='Vault_EDW',
                sql=f"EXEC edw_core.{item}",
                database="vault_edw",
                autocommit=True,
            )
            operators.append(operator)

        send_snapsheet_email = EmailOperator(
            task_id='send_snapsheet_email',
            to=to_email,
            subject='Airflow - snapsheet stored procedures executed successfully',
            html_content=get_sp_success_data_HTML(snapsheet_group_items, 'All snapsheet stored procedures executed successfully'),
        )

        for i in range(len(operators) - 1):
            operators[i] >> operators[i + 1]

        operators[-1] >> send_snapsheet_email


    end = DummyOperator(
        task_id='end',
    )

start >> ADF_snapsheet_group >> snapsheet_group >> end
