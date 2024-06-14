import os
import pendulum
from datetime import timedelta
from airflow import DAG
from airflow.utils.task_group import TaskGroup
from airflow.operators.mssql_operator import MsSqlOperator
from airflow.operators.email_operator import EmailOperator
from airflow.operators.dummy_operator import DummyOperator
from airflow.operators.python_operator import PythonOperator
from vault_edw_HTML_format import get_sp_success_data_HTML, get_sp_error_data_HTML, get_HTML_on_vault_format
from clue_property_txt_generation import generate_property_txt_file_and_encrypt, SFTPUploadCluePropertyFileOperator
from clue_auto_txt_generation import generate_auto_txt_file_and_encrypt, SFTPUploadClueAutoFileOperator

to_email = "itdatateam@vault.insurance"
# to_email = "alberto.valbuena@vault.insurance"
cc_email = ""

HOME_PATH = os.path.expanduser('~')
FOLDER_PATH = HOME_PATH + "/airflow/tmp_files/clue"

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
    dag_id='vault_CLUE_daily_feed',
    catchup=False,
    max_active_runs=1,
    default_args=args,
    start_date=pendulum.datetime(2024, 3, 29, tz="America/New_York"),
    # schedule_interval='0 4 * * *', # At 04:00 every day
    schedule_interval=None,
    tags=["CLUE dag", "vault"],
) as dag:
    

    start = DummyOperator(
        task_id='start',
    )

    
    with TaskGroup("CLUE_Property_group") as CLUE_Property_group:

        sp_claim_clue_property_feed = MsSqlOperator(
            task_id='sp_claim_clue_property_feed',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_claim_clue_property_feed",
            database="vault_edw",
            autocommit=True,
        )

        generate_clue_property_txt_file = PythonOperator(
            task_id='generate_clue_property_txt_file',
            python_callable=generate_property_txt_file_and_encrypt,
            dag=dag,
        )

        upload_clue_property_txt_to_sftp = SFTPUploadCluePropertyFileOperator(
            task_id='upload_clue_property_txt_to_sftp',
            sftp_conn_id='Vault_CLUE_sftp',
            dag=dag,
        )

        send_clue_property_email = EmailOperator(
            task_id='send_clue_property_email',
            to=to_email,
            subject='Airflow - CLUE tables loaded successfully',
            html_content=get_sp_success_data_HTML('sp_claim_clue_property_feed', 'The Clue Property process (e) finished successfully.'),
        )

        sp_claim_clue_property_feed >> generate_clue_property_txt_file >> upload_clue_property_txt_to_sftp >> send_clue_property_email


    with TaskGroup("CLUE_Auto_group") as CLUE_Auto_group:

        sp_claim_clue_auto_feed = MsSqlOperator(
            task_id='sp_claim_clue_auto_feed',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_claim_clue_auto_feed",
            database="vault_edw",
            autocommit=True,
        )

        generate_clue_auto_txt_file = PythonOperator(
            task_id='generate_clue_auto_txt_file',
            python_callable=generate_auto_txt_file_and_encrypt,
            dag=dag,
        )

        upload_clue_auto_txt_to_sftp = SFTPUploadClueAutoFileOperator(
            task_id='upload_clue_auto_txt_to_sftp',
            sftp_conn_id='Vault_CLUE_sftp',
            dag=dag,
        )

        send_clue_auto_email = EmailOperator(
            task_id='send_clue_auto_email',
            to=to_email,
            subject='Airflow - CLUE tables loaded successfully',
            html_content=get_sp_success_data_HTML('sp_claim_clue_auto_feed', 'The Clue Auto process (e) finished successfully.'),
        )

        sp_claim_clue_auto_feed >> generate_clue_auto_txt_file >> upload_clue_auto_txt_to_sftp >> send_clue_auto_email

    end = DummyOperator(
        task_id='end',
    )

start >> CLUE_Property_group >> CLUE_Auto_group >> end
