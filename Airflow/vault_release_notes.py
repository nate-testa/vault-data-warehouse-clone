import pendulum
from datetime import datetime, timedelta
from airflow import DAG
from airflow.hooks.mssql_hook import MsSqlHook
from airflow.operators.email_operator import EmailOperator
from airflow.operators.dummy_operator import DummyOperator
from airflow.operators.python_operator import PythonOperator
from airflow.models import Variable
from vault_edw_HTML_format import get_HTML_on_vault_format, get_release_notes_data_HTML

ENVIRONMENT = Variable.get("environment")
if ENVIRONMENT == 'PRODUCTION':
    to_email = "edw_users@vault.insurance"
else:
    to_email = "itdatateam@vault.insurance"
    # to_email = "alberto.valbuena@vault.insurance"

cc_email = ""


def check_tedw_release_note_and_send_email(**kwargs):
    
    current_date = datetime.now().strftime('%m/%d/%Y')
    
    sql_qry = """
                SELECT 
                    TICKET_NO,TICKET_SHORT_DESC,TICKET_TYPE,DATABASE_CHANGE_TYPE,IMPACTED_TABLE_NM,IMPACTED_COLUMN_NM, RESOLUTION_SUMMARY
                FROM edw_core.tedw_release_note 
                WHERE send_email_in = 'Yes' 
                AND send_email_dt = CAST(GETDATE() AS DATE) 
              """
    mssql_hook = MsSqlHook(mssql_conn_id='Vault_EDW')
    result = mssql_hook.get_first(sql_qry)

    sql_qry_hl = """
                SELECT TOP 1 release_summary 
                FROM edw_core.tedw_release_summary  
                WHERE send_email_in = 'Yes'
                AND send_email_dt = CAST(GETDATE() AS DATE)
              """
    mssql_hook_hl = MsSqlHook(mssql_conn_id='Vault_EDW')
    result_hl = mssql_hook_hl.get_first(sql_qry_hl)
    msg_text = "The following is a detailed list of database changes implemented in this release."

    if result_hl is not None:
        release_highlights = result_hl[0]
        msg_text = release_highlights + "\nThe following is a detailed list of database changes implemented in this release."              
    
    if result is not None:
        EmailOperator(
            task_id='send_email_release_notes',
            to=to_email,
            subject='Enterprise Data Warehouse(EDW) Release Notes - ' + current_date,
            html_content=get_release_notes_data_HTML(sql_qry,msg_text),
            dag=kwargs['dag'],
        ).execute(context=kwargs)


def on_failure_callback(context):

    task_instance = context['task_instance']
    error_info = str(context.get('exception'))
    task_type = task_instance.task.__class__.__name__
    html_content_body = ''
    
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
    dag_id='vault_release_notes',
    catchup=False,
    max_active_runs=1,
    default_args=args,
    start_date=pendulum.datetime(2024, 2, 12, tz="America/New_York"),
    schedule_interval='0 9 * * 1', # At 09:00 every monday
    # schedule_interval=None,
    tags=["release notes dag", "vault"],
) as dag:
    

    start = DummyOperator(
        task_id='start',
    )

    release_notes_email = PythonOperator(
        task_id='release_notes_email',
        python_callable=check_tedw_release_note_and_send_email,
        provide_context=True,
        dag=dag,
    )

    end = DummyOperator(
        task_id='end',
    )


start >> release_notes_email >> end
