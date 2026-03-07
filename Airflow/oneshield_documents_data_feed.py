import os
import logging
import pendulum
import subprocess
from datetime import timedelta
from airflow import DAG
from airflow.models.param import Param
from airflow.operators.email import EmailOperator
from airflow.operators.empty import EmptyOperator
from airflow.operators.python import PythonOperator
from vault_edw_HTML_format import get_sp_success_data_HTML, get_sp_error_data_HTML, get_HTML_on_vault_format

to_email = "itdatateam@vault.insurance"
# to_email = "alberto.valbuena@vaultinsurance.com"
cc_email = ""

HOME_PATH = os.path.expanduser('~')
FOLDER_PATH = HOME_PATH + "/python_scripts/oneshield_documents"

# Initialize Airflow task logger
logger = logging.getLogger("airflow.task")

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
    'retry_delay': timedelta(minutes=1),
    'on_failure_callback': on_failure_callback,
}

with DAG(
    dag_id='oneshield_documents_data_feed',
    catchup=False,
    max_active_runs=1,
    default_args=args,
    start_date=pendulum.datetime(2026, 1, 1, tz="America/New_York"),
    # schedule_interval='0 4 * * *', # At 04:00 every day
    schedule_interval=None,
    tags=["oneshield documents"],
    params={
        # Request selector: Choose which request to run or ALL for all requests
        "request": Param(
            default="clm002_customers",
            type="string",
            enum=["clm001_claims", "clm002_customers"],
            description="Select the request to execute."
        ),
        # Parameters for clm001_claims
        "documentType": Param(
            default=None, 
            type=["null", "string"], 
            description="For [clm001_claims] request, add Document type filter (Example: Claim). Leave empty to use all document types"
        ),
        "documentSubTypes": Param(
            default=None,
            type=["null", "string"],
            description="For [clm001_claims] request, add Comma-separated document subtypes (Example: Estimate of Damages,BI/UM Demand). Leave empty to use all document subtypes."
        ),
        # Parameters for clm002_customers
        "customerName": Param(
            default=None,
            type=["null", "string"],
            description="For [clm002_customers] request, add Customer name filter (Example: John Doe). Leave empty to use all customers."
        ),
    },
) as dag:

    start = EmptyOperator(
        task_id='start',
    )

    end = EmptyOperator(
        task_id='end',
    )

    def execute_main_script(**context):
        
        # Get parameters from the execution context
        params = context['params']
        request = params.get('request', 'clm001_claims')
        
        # Build the base command as a list (safer than a string)
        cmd = ["python3", "main.py", "-r", request]

        # Parameters for clm001_claims
        if request == "clm001_claims":
            doc_type = params.get('documentType')
            if doc_type:
                cmd.extend(["-p", f"documentType={doc_type}"])
                
            sub_types = params.get('documentSubTypes')
            if sub_types:
                cmd.extend(["-p", f"documentSubTypes={sub_types},"])
                    
        # Parameters for clm002_customers
        elif request == "clm002_customers":
            cust_name = params.get('customerName')
            if cust_name:
                cmd.extend(["-p", f"customerName={cust_name}"])

        # Log the exact command to facilitate debugging in Airflow logs
        logger.info("!"*150)
        logger.info(f"Working directory: {FOLDER_PATH}")
        logger.info(f"Command set on Airflow: {' '.join(cmd)}")
        logger.info("!"*150)
        
        # Execute the command
        result = subprocess.run(cmd, cwd=FOLDER_PATH, capture_output=True, text=True)
        
        # Log the standard output
        if result.stdout:
            logger.info("--- STDOUT ---")
            logger.info(f"\n{result.stdout}")
            
        # Validate if there was an error (exit code different from 0)
        if result.returncode != 0:
            logger.error("--- STDERR ---")
            logger.error(f"\n{result.stderr}")
            raise Exception(f"The script failed with exit code: {result.returncode}")

    run_oneshield_documents_process = PythonOperator(
        task_id='run_oneshield_documents_process',
        python_callable=execute_main_script,
    )

    start >> run_oneshield_documents_process >> end