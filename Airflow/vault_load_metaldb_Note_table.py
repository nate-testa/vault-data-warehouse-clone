import logging
import pendulum
import pandas as pd
from datetime import datetime, timedelta
from airflow import DAG
from sqlalchemy import create_engine
from airflow.hooks.mssql_hook import MsSqlHook
from airflow.operators.email_operator import EmailOperator
from airflow.operators.dummy_operator import DummyOperator
from airflow.operators.python import PythonOperator
from vault_edw_HTML_format import get_sp_error_data_HTML, get_HTML_on_vault_format

to_email = "itdatateam@vault.insurance"
# to_email = "alberto.valbuena@vault.insurance"
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

def load_note_tbl():

    extraction_qry = """
        SELECT
            NEWID() as Id
            ,'00000000-0000-0000-0000-000000000000' as UserId
            ,qn.hs_note_body as Content
            ,acc.id as ParentId
            ,'Account' as ObjectType
            ,GETDATE() as CreatedDate
            ,GETDATE() as UpdatedDate
            ,null as TaggedUserIds
            ,null as ExternalSourceId
            ,null as DocumentIds
            ,0 as IsExternallyShared
            ,0 as IsFlagged
            ,null as PlainTextContent
            ,qn.create_ts as notes_create_ts
        FROM [edw_stage].[Account] AS acc
        INNER JOIN [edw_stage].[hubspot_quote_notes] AS qn
        ON acc.policynumber = qn.quote_no
        AND qn.create_ts > (select last_source_extract_ts from edw_core.tetl_control where process_nm = 'py_hubspot_to_metal_note')
    """

    engine = None

    try:

        # **Step 1:** Vault_EDW connection
        vault_edw_hook = MsSqlHook(mssql_conn_id='Vault_EDW')
        with vault_edw_hook.get_conn() as vault_edw_conn:
            df = pd.read_sql_query(extraction_qry, vault_edw_conn)
            logging.info(f"Extracted {len(df)} records from Vault_EDW.")

        # **Step 2:** Validate DataFrame is not empty
        if df.empty:
            logging.warning("No records extracted. The destination table will not be updated.")
            return
        
         # **Step 3:** Select only the necessary columns for Metaldb insertion
        columns_to_insert = [
            'Id',
            'UserId',
            'Content',
            'ParentId',
            'ObjectType',
            'CreatedDate',
            'UpdatedDate',
            'TaggedUserIds',
            'ExternalSourceId',
            'DocumentIds',
            'IsExternallyShared',
            'IsFlagged'
        ]
        df_to_insert = df[columns_to_insert].copy()
        logging.info("Selected necessary columns for Metaldb insertion.")

        # **Step 4:** metaldb connection
        metaldb_hook = MsSqlHook(mssql_conn_id='MetalDB')
        engine = create_engine(metaldb_hook.get_uri())
        with engine.begin() as connection:
            df_to_insert.to_sql(name='Note', con=connection, schema='dbo', if_exists='append', index=False)
            logging.info("Data loaded successfully into dbo.Note table in Metaldb.")

        # **Step 5:** update control table
        last_notes_create_ts = df['notes_create_ts'].max()
        last_notes_create_ts_str = last_notes_create_ts.strftime('%Y-%m-%d %H:%M:%S.%f')
        update_qry = f"""
            UPDATE [edw_core].[tetl_control]
            SET last_source_extract_ts = '{last_notes_create_ts_str}',
                update_ts = GETDATE()
            WHERE process_nm = 'py_hubspot_to_metal_note'
        """
        vault_edw_hook.run(sql=update_qry)
        logging.info(f"Updated last_source_extract_ts in edw_core.tetl_control with value {last_notes_create_ts_str}")

    except Exception as e:
        logging.error(f"An error occurred in load_note_tbl: {e}")
        raise

    finally:
        if engine is not None:
            engine.dispose()
            logging.info("SQLAlchemy engine disposed successfully.")


args = {
    'owner': 'airflow',
    'retries': 0,
    'retry_delay':timedelta(minutes=1),
    'on_failure_callback': on_failure_callback,
}

with DAG(
    dag_id='vault_load_metaldb_Note_table',
    catchup=False,
    max_active_runs=1,
    default_args=args,
    start_date=pendulum.datetime(2024, 9, 19, tz="America/New_York"),
    schedule_interval='0 */2 * * *',  # Each two hours
    # schedule_interval=None,
    tags=["load metaldb Note table dag", "vault"],
) as dag:
    

    start = DummyOperator(
        task_id='start',
    )
    
    load_metaldb_note_tbl = PythonOperator(
        task_id='load_metaldb_note_tbl',
        python_callable=load_note_tbl,
        dag=dag,
    )
 
    end = DummyOperator(
        task_id='end',
    )

start >> load_metaldb_note_tbl >> end
