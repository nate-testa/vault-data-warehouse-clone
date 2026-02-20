import pendulum
from airflow import DAG
from airflow.models import Variable
from airflow.providers.ssh.operators.ssh import SSHOperator
from airflow.operators.dummy_operator import DummyOperator
from airflow.operators.email_operator import EmailOperator
from vault_edw_HTML_format import get_sp_error_data_HTML, get_HTML_on_vault_format

to_email = "itdatateam@vault.insurance"
#to_email = "hernando.gonzalez.garcia@vault.insurance;Architha.Gudimalla@vault.insurance"
ENVIRONMENT = Variable.get("environment", default_var="DEV")

Hubspot_VM_USERNAME = Variable.get("Hubspot-VM-USERNAME")
Hubspot_HOST = Variable.get("Hubspot-HOST")
Hubspot_PASS = Variable.get("Hubspot-PASS")
Hubspot_USERNAME = Variable.get("Hubspot-USERNAME")
Hubspot_DB = Variable.get("Hubspot-DB")

if ENVIRONMENT == "PRODUCTION":
    Hubspot_HSTOKEN = Variable.get("Hubspot-HSTOKEN")
else:
    Hubspot_HSTOKEN = Variable.get("Hubspot-HSSANDBOXKEY")

SSH_HOME = f'/home/{Hubspot_VM_USERNAME}/hs-integration'
REMOTE_ENV_PATH = f'{SSH_HOME}/.env'


def on_failure_callback(context):
    task_instance = context['task_instance']
    error_info = str(context.get('exception'))
    task_type = task_instance.task.__class__.__name__
    html_content_body = ''
    
    if task_type == "MsSqlOperator":
        task_name = task_instance.task_id
        sp_name = []
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


def on_success_callback(context):
    """
    Send execution report on successful completion
    Reads the report file from the remote server and emails it
    """
    from airflow.providers.ssh.hooks.ssh import SSHHook
    from airflow.models import Variable
    
    task_instance = context['task_instance']
    ssh_hook = SSHHook(ssh_conn_id='ssh_vm_hubspot')
    
    # Get username from Airflow variable
    Hubspot_VM_USERNAME = Variable.get("Hubspot-VM-USERNAME")
    ENVIRONMENT = Variable.get("environment", default_var="DEV")
    report_path = f'/home/{Hubspot_VM_USERNAME}/hs-integration/logs/latest_execution_report.html'
    
    try:
        # Use SSH to read the report file
        with ssh_hook.get_conn() as ssh_client:
            sftp = ssh_client.open_sftp()
            with sftp.file(report_path, 'r') as remote_file:
                html_content = remote_file.read().decode('utf-8')
            sftp.close()
        
        # Determine subject based on content
        if '❌' in html_content or 'FAILED' in html_content:
            subject = f'⚠️ HubSpot Integration - Completed with Errors - {ENVIRONMENT}'
        elif '⚠️' in html_content or 'WARNING' in html_content:
            subject = f'⚠️ HubSpot Integration - Completed with Warnings - {ENVIRONMENT}'
        else:
            subject = f'✅ HubSpot Integration - Success - {ENVIRONMENT}'
        
    except Exception as e:
        # Fallback if report cannot be read
        error_msg = str(e)
        
        # Provide helpful message based on error type
        if 'No such file' in error_msg or 'FileNotFoundError' in error_msg:
            html_content = get_HTML_on_vault_format(
                f'<strong>HubSpot Integration Script Executed</strong><br><br>'
                f'The integration script ran but the execution report was not generated. '
                f'This usually means the script was interrupted or encountered an error before completion.<br><br>'
                f'<strong>Recommended Actions:</strong><br>'
                f'• Check the application log: <code>/home/{Hubspot_VM_USERNAME}/hs-integration/logs/hs-integration-run-*.log</code><br>'
                f'• Verify the script completed successfully<br>'
                f'• Check for any Python errors or exceptions<br><br>'
                f'<strong>Error Details:</strong> {error_msg}',
                ''
            )
        else:
            html_content = get_HTML_on_vault_format(
                f'HubSpot Integration completed but could not retrieve detailed report.<br><br>'
                f'<strong>Error:</strong> {error_msg}',
                ''
            )
        subject = f'HubSpot Integration - Report Unavailable - {ENVIRONMENT}'
    
    # Send email with report
    email = EmailOperator(
        task_id='send_success_report',
        to=to_email,
        subject=subject,
        html_content=html_content
    )
    email.execute(context)


args = {
    'owner': 'airflow',
    'retries': 0,
    'on_failure_callback': on_failure_callback,
    # 'on_success_callback': on_success_callback,  # Uncomment to use success callback
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

    start = DummyOperator(task_id="start")

    write_remote_env = SSHOperator(
        task_id="write_remote_env",
        ssh_conn_id="ssh_vm_hubspot",
        command="""\
cat > {{ params.env_path }} <<EOF
ENVIRONMENT={{ params.environment }}
{%- if var.value.environment == "PRODUCTION" %}
HSTOKEN={{ params.token }}
{%- else %}
HSSANDBOXKEY={{ params.token }}
{%- endif %}
HOST={{ params.host }}
USERNAME={{ params.username }}
PASS={{ params.password }}
DB={{ params.db }}
EOF
""",
        params={
            "env_path": REMOTE_ENV_PATH,
            "environment": ENVIRONMENT,
            "host": Hubspot_HOST,
            "password": Hubspot_PASS,
            "username": Hubspot_USERNAME,
            "token": Hubspot_HSTOKEN,
            "db": Hubspot_DB
        },
    )

    run_hs = SSHOperator(
        task_id="run_hs_integration_script",
        ssh_conn_id="ssh_vm_hubspot",
        command='{{ "bash /home/" ~ var.value.get("Hubspot-VM-USERNAME") ~ "/hs-integration/run_script.sh" }}',
        cmd_timeout=18000,
        # Add success callback to this specific task
        on_success_callback=on_success_callback,
    )

    end = DummyOperator(task_id="end")

    start >> write_remote_env >> run_hs >> end
