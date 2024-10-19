import pendulum
from airflow import DAG
from airflow.models import Variable
from airflow.providers.ssh.operators.ssh import SSHOperator
from airflow.operators.dummy_operator import DummyOperator
from airflow.operators.email_operator import EmailOperator
from vault_edw_HTML_format import get_sp_error_data_HTML, get_HTML_on_vault_format


to_email = "itdatateam@vault.insurance"
# to_email = "alberto.valbuena@vault.insurance"


ENVIRONMENT = Variable.get("environment")
if ENVIRONMENT == 'PRODUCTION':
    bash_command = 'bash /home/vphubspotadmin/hs-integration/run_script.sh ' # It is important put and empty space at the end of the command
else:
    bash_command = ''
    print(f"**** Environment: [{ENVIRONMENT}] is not authorized to execute hubspot file (run_script.sh).")


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
    'on_failure_callback': on_failure_callback,
}

with DAG(
    dag_id='hubspot_integration_api_call',
    catchup=False,
    max_active_runs=1,
    default_args=args,
    start_date=pendulum.datetime(2024, 9, 19, tz="America/New_York"),
    # schedule_interval='0 4 * * *', # At 04:00 every day
    schedule_interval=None,
    tags=["hubspot_dag"],
) as dag:

    start = DummyOperator(
        task_id='start',
    )

    run_hs_integration_script = SSHOperator(
        task_id='run_hs_integration_script',
        ssh_conn_id='ssh_vm_hubspot',
        command=bash_command,
        cmd_timeout=18000, # 5 hours
    )

    end = DummyOperator(
        task_id='end',
    )

start >> run_hs_integration_script >> end