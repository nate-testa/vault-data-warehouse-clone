import os
import pendulum
from datetime import timedelta
from airflow import DAG
from airflow.models import Variable
from airflow.providers.microsoft.mssql.hooks.mssql import MsSqlHook
from airflow.utils.task_group import TaskGroup
from airflow.operators.python import PythonOperator
from airflow.providers.microsoft.mssql.operators.mssql import MsSqlOperator
from airflow.operators.email import EmailOperator
from airflow.operators.empty import EmptyOperator
from airflow.operators.bash import BashOperator
from vault_edw_HTML_format import get_sp_success_data_HTML, get_sp_error_data_HTML, get_HTML_on_vault_format, get_vault_data_HTML

to_email = "itdatateam@vault.insurance"
# to_email = "alberto.valbuena@vault.insurance"
cc_email = ""

ENVIRONMENT = Variable.get("environment")
HOME_PATH = os.path.expanduser('~')
FOLDER_PATH = HOME_PATH + "/python_scripts/edw_to_metal"
if ENVIRONMENT == "UAT":
    BASH_COMMAND = f'bash {FOLDER_PATH}/run_script.sh '
else:
    BASH_COMMAND = f'echo " *** EDW to Metal load skipped in {ENVIRONMENT} environment *** "'


def check_customer_midterm_review_data_and_send_email(**kwargs):
    sql_qry = """
                SELECT 'metaldb.dbo.InsuredMarketingPreferenceDocument' AS Table_Name, COUNT(1) AS Rows_Loaded from dbo.InsuredMarketingPreferenceDocument  WHERE CAST(CreatedDate AS DATE) = CAST(GETDATE() AS DATE)
              """
    mssql_hook = MsSqlHook(mssql_conn_id='Vault_METAL')
    results = mssql_hook.get_records(sql_qry)
    
    print('*** Results from SQL query ***')
    for row in results:
        print(row)

    total_rows_loaded = sum(int(row[1]) for row in results) 
    print(f"Total rows loaded: {total_rows_loaded}")

    if total_rows_loaded != 0:
        email_op = EmailOperator(
            task_id='send_customer_midterm_review_data_loaded_email',
            to=to_email,
            subject='Airflow - Customer Midterm Review - Data loaded report',
            html_content=get_vault_data_HTML(sql_qry,'The Customer Midterm Review data have been loaded into MetalDB successfully. Below is the report with the rows loaded by table.','Vault_METAL'),
            dag=kwargs['dag'],
        )
        email_op.execute(context=kwargs)  # type: ignore
    else:
        print(" *** No rows loaded. No email will be sent. ***")

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
    dag_id='customer_midterm_review_daily_feed',
    catchup=False,
    max_active_runs=1,
    default_args=args,
    start_date=pendulum.datetime(2024, 3, 29, tz="America/New_York"),
    # schedule_interval='0 4 * * *', # At 04:00 every day
    schedule_interval=None,
    tags=["customer midterm review", "vault"],
) as dag:
    

    start = EmptyOperator(
        task_id='start',
    )

    end = EmptyOperator(
        task_id='end',
    )


    with TaskGroup("customer_midterm_review_group") as customer_midterm_review_group:

        customer_midterm_review_items = [
            'sp_customer_midterm_review_recommendation',
            'sp_customer_midterm_review_ghostdraft_feed'
        ]
        
        operators = []
        for item in customer_midterm_review_items:
            operator = MsSqlOperator(
                task_id=item,
                mssql_conn_id='Vault_EDW',
                sql=f"EXEC edw_core.{item}",
                database="vault_edw",
                autocommit=True,
            )
            operators.append(operator) 

        run_edw_to_metal_load = BashOperator(
            task_id='run_edw_to_metal_load',
            bash_command=BASH_COMMAND,
        )

        check_data_and_send_email = PythonOperator(
            task_id='check_data_and_send_email',
            python_callable=check_customer_midterm_review_data_and_send_email,
            provide_context=True,
            dag=dag,
        )

        send_customer_midterm_review_email = EmailOperator(
            task_id='send_customer_midterm_review_email',
            to=to_email,
            subject='Airflow - Customer Midterm Review process completed successfully',
            html_content=get_sp_success_data_HTML(customer_midterm_review_items, 'The Customer Midterm Review process finished successfully.'),
        )

        for i in range(len(operators) - 1):
            operators[i].set_downstream(operators[i + 1])

        operators[-1].set_downstream(run_edw_to_metal_load)
        run_edw_to_metal_load.set_downstream(check_data_and_send_email)
        check_data_and_send_email.set_downstream(send_customer_midterm_review_email)


start.set_downstream(customer_midterm_review_group)
customer_midterm_review_group.set_downstream(end)