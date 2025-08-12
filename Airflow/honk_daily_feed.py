import os
import pendulum
from datetime import datetime, timedelta
from airflow import DAG
from airflow.models import Variable
from airflow.operators.mssql_operator import MsSqlOperator
from airflow.operators.email_operator import EmailOperator
from airflow.operators.dummy_operator import DummyOperator
from vault_edw_HTML_format import get_sp_success_data_HTML, get_sp_error_data_HTML, get_HTML_on_vault_format

to_email = "itdatateam@vault.insurance"
# to_email = "alberto.valbuena@vault.insurance"
cc_email = ""

HOME_PATH = os.path.expanduser('~')
ENVIRONMENT = Variable.get("environment")


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
    dag_id='Honk_Daily_Feed',
    catchup=False,
    max_active_runs=1,
    default_args=args,
    start_date=pendulum.datetime(2025, 1, 9, tz="America/New_York"),
    # schedule_interval='0 3 * * *', # At 02:00 every day
    schedule_interval=None,
    tags=["honk daily feed dag", "vault"],
) as dag:

    start = DummyOperator(
        task_id='start',
    )

    policy_honk_group_items = [
            'sp_policy_honk_policyholder_feed',
            'sp_policy_honk_vehicle_feed'
        ]

    operators = []
    for item in policy_honk_group_items:
        operator = MsSqlOperator(
            task_id=item,
            mssql_conn_id='Vault_EDW',
            sql=f"EXEC edw_core.{item}",
            database="vault_edw",
            autocommit=True,
        )
        operators.append(operator)

    send_policy_honk_group_email = EmailOperator(
        task_id='send_policy_honk_group_email',
        to=to_email,
        subject='Airflow - Policy honk group tables loaded successfully',
        html_content=get_sp_success_data_HTML(policy_honk_group_items, 'All stored procedures executed successfully for all the Policy honk group tables'),
    )

    for i in range(len(operators) - 1):
        operators[i] >> operators[i + 1]

    operators[-1] >> send_policy_honk_group_email

    end = DummyOperator(
        task_id='end',
    )
    
start >> send_policy_honk_group_email >> end