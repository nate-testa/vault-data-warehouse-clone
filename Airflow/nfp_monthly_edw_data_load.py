import os
import pendulum
from datetime import timedelta
from airflow import DAG
from airflow.models import Variable
from airflow.utils.task_group import TaskGroup
from airflow.providers.microsoft.mssql.operators.mssql import MsSqlOperator
from airflow.operators.email import EmailOperator
from airflow.operators.empty import EmptyOperator
from airflow.operators.bash import BashOperator
from vault_edw_HTML_format import get_sp_success_data_HTML, get_sp_error_data_HTML, get_HTML_on_vault_format

to_email = "itdatateam@vault.insurance"
# to_email = "hernando.gonzalez.garcia@vault.insurance, alberto.valbuena@vault.insurance"
cc_email = ""

ENVIRONMENT = Variable.get("environment")
FOLDER_PATH = Variable.get("NFP_FOLDER_PATH")  # Use absolute path
server = Variable.get("NFP_SERVER")  # Default value for server


def run_preprocess():
    preprocess_script = os.path.join(FOLDER_PATH, 'preProcess.py')
    os.system(f'python3 {preprocess_script}')

def run_process(server):
    process_script = os.path.join(FOLDER_PATH, 'process.py')
    command = f'python3 {process_script}'
    if server:
        command += f' --server {server}'
    os.system(command)

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
    dag_id='nfp_monthly_edw_data_load',
    catchup=False,
    max_active_runs=1,
    default_args=args,
    start_date=pendulum.datetime(2023, 11, 16, tz="America/New_York"),
    # schedule_interval='0 5 * * 1-5', # At 05:00 every day
    schedule_interval=None, 
    # schedule_interval=datetime.timedelta(hours=6), # Every 6 hours
    tags=["master dag nfp", "vault"],
) as dag:
    

    start = EmptyOperator(
        task_id='start',
    )

    end = EmptyOperator(
        task_id='end',
        trigger_rule='none_failed',
    )

    with TaskGroup("nfp_file_processing_group") as nfp_file_processing_group:

        pre_process_task = BashOperator(
        task_id='preprocess_task',
        bash_command=f'python3 {FOLDER_PATH}/preProcess.py',
        dag=dag,
        )

        process_task = BashOperator(
            task_id='process_task',
            bash_command=f'python3 {FOLDER_PATH}/process.py --server {server}',
            dag=dag,
        )

        pre_process_task.set_downstream(process_task)


    with TaskGroup("nfp_stored_procedures_group") as nfp_stored_procedures_group:

        last_day_previous_month = (pendulum.now().subtract(months=1).end_of('month')).format('YYYY-MM-DD')
        previous_month = (pendulum.now().subtract(months=1)).format('YYYYMM')

        nfp_stored_procedures_group_config_json = {
            "sp_nfp_policy_update": {},
            "sp_tcustomer_nfp": {},
            "sp_tpolicy_nfp": {},
            "sp_tpolicy_update_nfp": {},
            "sp_tpolicy_history_nfp": {},
            "sp_tgrpel_coverage": {},
            "sp_tpolicy_transaction_nfp": {},
            "sp_tdaily_inforce_policy": {"sp_parameters": [{"name": "@in_inforce_dt", "value": last_day_previous_month},{"name": "@in_source_system", "value": "NFP"}]},
            "sp_tpolicy_update_policy_inforce_in": {},
            "sp_tpolicy_summary": {"sp_parameters": [{"name": "@in_end_dt", "value": last_day_previous_month},{"name": "@in_source_system", "value": "NFP"}]},
            "sp_tpolicy_transaction_summary": {"sp_parameters": [{"name": "@in_month_end_dt", "value": last_day_previous_month},{"name": "@in_source_system", "value": "NFP"}]},
            "sp_tcustomer_summary": {"sp_parameters": [{"name": "@in_end_dt", "value": last_day_previous_month}]},
            "sp_titem_inforce": {"sp_parameters": [{"name": "@in_inforce_dt", "value": last_day_previous_month},{"name": "@in_source_system", "value": "NFP"}]},
            "sp_titem_summary": {"sp_parameters": [{"name": "@in_month_end_dt", "value": last_day_previous_month},{"name": "@in_source_system", "value": "NFP"}]},
            "sp_tinternal_coverage_inforce": {"sp_parameters": [{"name": "@in_inforce_dt", "value": last_day_previous_month},{"name": "@in_source_system", "value": "NFP"}]},
            "sp_tinternal_coverage_summary": {"sp_parameters": [{"name": "@in_month_end_dt", "value": last_day_previous_month},{"name": "@in_source_system", "value": "NFP"}]},
            "sp_nfp_claim_policy_search_snapsheet_api": {},
            "sp_nfp_claim_policy_webhook_snapsheet_api": {},
            "sp_trenewal_summary": {"sp_parameters": [{"name": "@in_yearmonth", "value": previous_month},{"name": "@in_source_system", "value": "NFP"}]},
            "sp_tbroker_summary": {"sp_parameters": [{"name": "@in_end_dt", "value": last_day_previous_month},{"name": "@in_broker_id", "value": "56601"}]},
        }

        # Build the list of items filtering
        nfp_stored_procedures_group_items = []
        for sp_name, config in nfp_stored_procedures_group_config_json.items():
            # Skip if exec_only_in_environment configuration is set and doesn't match current environment
            if 'exec_only_in_environment' in config and config['exec_only_in_environment'] != ENVIRONMENT:
                continue
            nfp_stored_procedures_group_items.append(sp_name)
        
        # Create operators for each stored procedure
        operators = {}
        item_name = ''
        for item in nfp_stored_procedures_group_items:
            config = nfp_stored_procedures_group_config_json.get(item, {})
            
            # Build SQL command with parameters if provided
            sp_parameters = config.get('sp_parameters', [])
            if sp_parameters:
                # Build parameter string: @param1=value1, @param2=value2, ...
                params_str = ', '.join([f"{param['name']}='{param['value']}'" for param in sp_parameters])
                sql_command = f"exec edw_core.{item} {params_str}"
                item_name = item
            else:
                sql_command = f"exec edw_core.{item}"
                item_name = item
            
            operator = MsSqlOperator(
                task_id=item_name,
                mssql_conn_id='Vault_EDW',
                sql=sql_command,
                database="vault_edw",
                autocommit=True,
            )
            operators[item] = operator

        send_nfp_email = EmailOperator(
            task_id='send_nfp_email',
            to=to_email,
            subject='Airflow - nfp monthly load executed successfully',
            html_content=get_sp_success_data_HTML(nfp_stored_procedures_group_items, 'The stored procedures executed successfully for nfp monthly load'),
        )

        # Set up sequential dependencies: SP1 >> SP2 >> SP3 >> ... >> Email
        operator_list = [operators[item] for item in nfp_stored_procedures_group_items]
        
        if operator_list:
            # Chain all operators sequentially
            for i in range(len(operator_list) - 1):
                operator_list[i].set_downstream(operator_list[i + 1])
            
            # Connect last operator to email
            operator_list[-1].set_downstream(send_nfp_email)


start.set_downstream(nfp_file_processing_group)
nfp_file_processing_group.set_downstream(nfp_stored_procedures_group)
nfp_stored_procedures_group.set_downstream(end)