import pytz
import pendulum
from datetime import datetime, timedelta
from airflow import DAG
from airflow.utils.task_group import TaskGroup
from airflow.exceptions import AirflowSkipException
from airflow.operators.mssql_operator import MsSqlOperator
from airflow.operators.email_operator import EmailOperator
from airflow.operators.dummy_operator import DummyOperator
from airflow.operators.python_operator import PythonOperator
from vault_edw_HTML_format import get_sp_success_data_HTML, get_sp_error_data_HTML, get_HTML_on_vault_format
from ivans_api import call_ivans_api

to_email = "itdatateam@vault.insurance"
# to_email = "hernando.gonzalez.garcia@vault.insurance, alberto.valbuena@vault.insurance"
cc_email = ""

def check_day_and_time():
    # check for maintenance window on Ivans
    now = datetime.now(pytz.timezone("America/New_York"))
    if now.weekday() == 6 and now.hour < 8:
        raise AirflowSkipException("Execution skipped: Sunday between 12 AM and 8 AM EST.")

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
    dag_id='Ivans_Daily_Feed',
    catchup=False,
    max_active_runs=1,
    default_args=args,
    start_date=pendulum.datetime(2025, 1, 1, tz="America/New_York"),
    # schedule_interval='30 0 * * *', # At 12:30 every day
    schedule_interval=None, 
    tags=["ivans dag", "vault"],
) as dag:
    

    start = DummyOperator(
        task_id='start',
    )

    check_maintenance_window = PythonOperator(
        task_id = 'check_maintenance_window',
        python_callable = check_day_and_time,
    )   

    with TaskGroup("ivans_group") as ivans_group:

        ivans_group_items = [
            'sp_policy_ivans_auto_feed',
            'sp_policy_ivans_home',
            'sp_policy_ivans_pel_feed'
        ]

        operators = []
        for item in ivans_group_items:
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

        send_ivans_email = EmailOperator(
            task_id='send_ivans_email',
            to=to_email,
            subject='Airflow - Ivans tables loaded successfully',
            html_content=get_sp_success_data_HTML(ivans_group_items, 'All stored procedures executed successfully for all the ivans tables'),
        )

        for i in range(len(operators) - 1):
            operators[i] >> operators[i + 1]

        operators[-1] >> ivans_api_call >> send_ivans_email

    end = DummyOperator(
        task_id='end',
    )


start >> check_maintenance_window >> ivans_group >> end
