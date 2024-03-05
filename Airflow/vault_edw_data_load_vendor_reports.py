import pendulum
from datetime import timedelta
from airflow import DAG
from airflow.utils.task_group import TaskGroup
from airflow.operators.mssql_operator import MsSqlOperator
from airflow.operators.email_operator import EmailOperator
from airflow.operators.dummy_operator import DummyOperator
from vault_edw_HTML_format import get_sp_success_data_HTML, get_sp_error_data_HTML, get_HTML_on_vault_format

# to_email = "itdatateam@vault.insurance"
to_email = "alberto.valbuena@vault.insurance"
cc_email = ""


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
    dag_id='vault_edw_data_load_vendor_reports',
    catchup=False,
    max_active_runs=1,
    default_args=args,
    start_date=pendulum.datetime(2024, 3, 5, tz="America/New_York"),
    # schedule_interval='0 4 * * *', # At 04:00 every day
    schedule_interval=None,
    tags=["vendor reports dag", "vault"],
) as dag:
    

    start = DummyOperator(
        task_id='start',
    )

    with TaskGroup("vendor_report_group") as vendor_report_group:

        vendor_report_group_items = ['sp_tvendor_report_stage_data','sp_tvendor_report']

        sp_tvendor_report_stage_data = MsSqlOperator(
            task_id='sp_tvendor_report_stage_data',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tvendor_report_stage_data",
            database="vault_edw",
            autocommit=True,
        )

        sp_tvendor_report_AonCatStore = MsSqlOperator(
            task_id='sp_tvendor_report_AonCatStore',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tvendor_report 'AonCatStore'",
            database="vault_edw",
            autocommit=True,
        )

        sp_tvendor_report_CarfaxMileage = MsSqlOperator(
            task_id='sp_tvendor_report_CarfaxMileage',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tvendor_report 'Carfax Mileage'",
            database="vault_edw",
            autocommit=True,
        )

        sp_tvendor_report_CarfaxValue = MsSqlOperator(
            task_id='sp_tvendor_report_CarfaxValue',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tvendor_report 'Carfax Value'",
            database="vault_edw",
            autocommit=True,
        )

        sp_tvendor_report_CLUEAuto = MsSqlOperator(
            task_id='sp_tvendor_report_CLUEAuto',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tvendor_report 'CLUE Auto'",
            database="vault_edw",
            autocommit=True,
        )

        sp_tvendor_report_ClueProperty = MsSqlOperator(
            task_id='sp_tvendor_report_ClueProperty',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tvendor_report 'Clue Property'",
            database="vault_edw",
            autocommit=True,
        )

        sp_tvendor_report_GuyCarpenter = MsSqlOperator(
            task_id='sp_tvendor_report_GuyCarpenter',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tvendor_report 'GuyCarpenter'",
            database="vault_edw",
            autocommit=True,
        )

        sp_tvendor_report_IsoVehicle = MsSqlOperator(
            task_id='sp_tvendor_report_IsoVehicle',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tvendor_report 'Iso Vehicle'",
            database="vault_edw",
            autocommit=True,
        )

        sp_tvendor_report_IsoProperty = MsSqlOperator(
            task_id='sp_tvendor_report_IsoProperty',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tvendor_report 'IsoProperty'",
            database="vault_edw",
            autocommit=True,
        )

        sp_tvendor_report_LC360 = MsSqlOperator(
            task_id='sp_tvendor_report_LC360',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tvendor_report 'LC360'",
            database="vault_edw",
            autocommit=True,
        )

        sp_tvendor_report_MVR = MsSqlOperator(
            task_id='sp_tvendor_report_MVR',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tvendor_report 'MVR'",
            database="vault_edw",
            autocommit=True,
        )

        sp_tvendor_report_NHTSA = MsSqlOperator(
            task_id='sp_tvendor_report_NHTSA',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tvendor_report 'NHTSA'",
            database="vault_edw",
            autocommit=True,
        )

        sp_tvendor_report_SAQ = MsSqlOperator(
            task_id='sp_tvendor_report_SAQ',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tvendor_report 'SAQ'",
            database="vault_edw",
            autocommit=True,
        )

        sp_tvendor_report_TransUnion = MsSqlOperator(
            task_id='sp_tvendor_report_TransUnion',
            mssql_conn_id='Vault_EDW',
            sql="EXEC edw_core.sp_tvendor_report 'TransUnion'",
            database="vault_edw",
            autocommit=True,
        )

        send_vendor_report_email = EmailOperator(
            task_id='send_vendor_report_email',
            to=to_email,
            subject='Airflow - Vendor report stored procedure executions finalized successfully',
            html_content=get_sp_success_data_HTML(vendor_report_group_items, 'All executions of stored procedure vendor report executed successfully'),
        )

        sp_tvendor_report_stage_data >> sp_tvendor_report_AonCatStore >> sp_tvendor_report_CarfaxMileage >> sp_tvendor_report_CarfaxValue >> sp_tvendor_report_CLUEAuto >> sp_tvendor_report_ClueProperty >> sp_tvendor_report_GuyCarpenter >> sp_tvendor_report_IsoVehicle >> sp_tvendor_report_IsoProperty >> sp_tvendor_report_LC360 >> sp_tvendor_report_MVR >> sp_tvendor_report_NHTSA >> sp_tvendor_report_SAQ >> sp_tvendor_report_TransUnion >> send_vendor_report_email


    end = DummyOperator(
        task_id='end',
    )


start >> vendor_report_group >> end
