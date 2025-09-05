import os
import pendulum
from datetime import datetime, timedelta
from airflow import DAG
from sqlalchemy import text
from sqlalchemy.types import VARCHAR
from airflow.providers.microsoft.mssql.hooks.mssql import MsSqlHook
from airflow.operators.email import EmailOperator
from airflow.operators.empty import EmptyOperator
from airflow.operators.python import PythonOperator
from vault_edw_HTML_format import get_sp_error_data_HTML, get_HTML_on_vault_format

to_email = "itdatateam@vault.insurance"
cc_email = ""

HOME_PATH = os.path.expanduser('~')

def extract_edw_and_update_metal():
    """
    Extracts broker loss ratio data, keeping it as a string throughout the
    Python process to guarantee full decimal precision is maintained.
    """
    print("Connecting to source server: Vault_EDW...")
    source_hook = MsSqlHook(mssql_conn_id='Vault_EDW')
    
    sql_extract = "SELECT broker_id, CAST(loss_ratio AS VARCHAR(30)) AS loss_ratio FROM edw_integration.broker_claim_metal_feed;"
    
    print(f"Extracting data with query: {sql_extract}")
    df = source_hook.get_pandas_df(sql=sql_extract)

    if df.empty:
        print("Source data is empty. No update to perform.")
        return 0

    print(f"Successfully extracted {len(df)} rows from EDW as strings to preserve precision.")

    print("Connecting to target server: Vault_METAL...")
    target_hook = MsSqlHook(mssql_conn_id='Vault_METAL')
    engine = target_hook.get_sqlalchemy_engine()
    staging_table_name = '#broker_loss_ratio_staging'

    with engine.connect() as conn:
        print("SQLAlchemy connection opened.")
        
        print(f"Loading data into a text-based temporary table '{staging_table_name}'...")

        df.to_sql(
            name=staging_table_name,
            con=conn,
            if_exists='replace',
            index=False,
            dtype={'loss_ratio': VARCHAR(30), 'broker_id': VARCHAR(255)}
        )
        print("Data successfully loaded into text-based staging table.")
        
        with conn.begin() as transaction:
            sql_merge = f"""
            MERGE INTO Brokerage AS TGT
            USING {staging_table_name} AS SRC
            ON TGT.ProducerId = SRC.broker_id
            WHEN MATCHED THEN
                UPDATE SET TGT.LossRatio = CAST(SRC.loss_ratio AS DECIMAL(16, 4));
            """
            
            print("Merging staged data into the final Brokerage table with final CAST...")
            result = conn.execute(text(sql_merge))
            
            print(f"✅ Merge complete. {result.rowcount} brokerage loss ratios updated successfully.")
            
            # Return the number of updated records
            updated_count = result.rowcount
    
    print("SQLAlchemy connection closed.")
    return updated_count

def metal_lossratio_update_email(**kwargs):

    current_date = datetime.now().strftime('%m/%d/%Y')
    
    # Get the result from the previous task using XCom
    task_instance = kwargs['task_instance']
    updated_count = task_instance.xcom_pull(task_ids='transfer_and_update_broker_data')
    
    if updated_count is None:
        updated_count = 0

    msg_text = f"Metal Brokerage Loss Ratio Update completed on [{current_date}].<br><br>Records updated: {updated_count}"
    
    EmailOperator(
        task_id='send_email_metal_loss_ratio',
        to=to_email,
        subject='Airflow - Metal Brokerage Loss Ratio Update',
        html_content=get_HTML_on_vault_format(msg_text, ''),
        dag=kwargs['dag'],
    ).execute(context=kwargs)

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
    dag_id='metal_update_brokerage_loss_ratio',
    catchup=False,
    max_active_runs=1,
    default_args=args,
    start_date=pendulum.datetime(2024, 3, 29, tz="America/New_York"),
    # schedule_interval='0 4 * * *', # At 04:00 every day
    schedule_interval=None,
    tags=['metal', 'edw', 'update', 'python'],
    doc_md="""
        ### Update Brokerage Loss Ratio (Cross-Server)
        
        This DAG extracts broker loss ratios from the EDW and updates the corresponding
        records in the METAL database's Brokerage table. It preserves full decimal
        precision and reports the number of records updated.
    """
) as dag:
    

    start = EmptyOperator(
        task_id='start',
    )

    end = EmptyOperator(
        task_id='end',
        trigger_rule='none_failed',
    )

    transfer_and_update_data = PythonOperator(
        task_id='transfer_and_update_broker_data',
        python_callable=extract_edw_and_update_metal,
        provide_context=True,
        dag=dag,
    )
    
    py_metal_lossratio_update_email = PythonOperator(
        task_id='py_metal_lossratio_update_email',
        python_callable=metal_lossratio_update_email,
        provide_context=True,
        dag=dag,
    )


start.set_downstream(transfer_and_update_data)
transfer_and_update_data.set_downstream(py_metal_lossratio_update_email)
py_metal_lossratio_update_email.set_downstream(end)
