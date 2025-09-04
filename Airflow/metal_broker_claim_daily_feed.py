import os
import pendulum
from datetime import timedelta
from airflow import DAG
from airflow.providers.microsoft.mssql.operators.mssql import MsSqlOperator
from airflow.operators.email import EmailOperator
from airflow.operators.empty import EmptyOperator
from airflow.operators.dagrun_operator import TriggerDagRunOperator
from vault_edw_HTML_format import get_sp_success_data_HTML, get_sp_error_data_HTML, get_HTML_on_vault_format

to_email = "itdatateam@vault.insurance"
# to_email = "alberto.valbuena@vault.insurance"
cc_email = ""

HOME_PATH = os.path.expanduser('~')

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
    dag_id='metal_broker_claim_daily_feed',
    catchup=False,
    max_active_runs=1,
    default_args=args,
    start_date=pendulum.datetime(2024, 3, 29, tz="America/New_York"),
    # schedule_interval='0 4 * * *', # At 04:00 every day
    schedule_interval=None,
    tags=["metal_broker", "vault"],
) as dag:
    

    start = EmptyOperator(
        task_id='start',
    )

    end = EmptyOperator(
        task_id='end',
        trigger_rule='none_failed',
    )

    broker_claim_metal_items = [
            'edw_core.sp_broker_claim_metal_feed'
        ]

    sp_broker_claim_metal_feed = MsSqlOperator(
            task_id='sp_broker_claim_metal_feed',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_broker_claim_metal_feed",
            database="vault_edw",
            autocommit=True,
        )
    
    exec_metal_update_brokerage_loss_ratio = TriggerDagRunOperator(
            task_id="exec_metal_update_brokerage_loss_ratio",
            trigger_dag_id="metal_update_brokerage_loss_ratio",
            wait_for_completion=True,
            dag=dag,
        )
    
    send_metal_broker_claim_daily_feed_email = EmailOperator(
            task_id='send_metal_broker_claim_daily_feed_email',
            to=to_email,
            subject='Airflow - metal_broker_claim_daily_feed process completed successfully',
            html_content=get_sp_success_data_HTML(broker_claim_metal_items, 'The metal_broker_claim_daily_feed process finished successfully.'),
        )


start.set_downstream(sp_broker_claim_metal_feed)
sp_broker_claim_metal_feed.set_downstream(exec_metal_update_brokerage_loss_ratio)
exec_metal_update_brokerage_loss_ratio.set_downstream(send_metal_broker_claim_daily_feed_email)
send_metal_broker_claim_daily_feed_email.set_downstream(end)