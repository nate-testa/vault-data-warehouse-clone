import pendulum
from datetime import timedelta
import pandas as pd
from sqlalchemy import text

from airflow.models.dag import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.microsoft.mssql.hooks.mssql import MsSqlHook
from airflow.operators.dummy import DummyOperator

# v5
def extract_edw_and_update_metal():
    print("Connecting to source server: Vault_EDW...")
    source_hook = MsSqlHook(mssql_conn_id='Vault_EDW')
    sql_extract = "SELECT broker_id, loss_ratio FROM edw_integration.broker_claim_metal_feed;"
    
    print(f"Extracting data with query: {sql_extract}")
    df = source_hook.get_pandas_df(sql=sql_extract)

    if df.empty:
        print("Source data is empty. No update to perform.")
        return

    print(f"Successfully extracted {len(df)} rows from EDW.")

    print("Connecting to target server: Vault_METAL...")
    target_hook = MsSqlHook(mssql_conn_id='Vault_METAL')
    engine = target_hook.get_sqlalchemy_engine()
    staging_table_name = '#broker_loss_ratio_staging'

    with engine.connect() as conn:
        print("SQLAlchemy connection opened.")
        
        print(f"Loading data into temporary table '{staging_table_name}'...")
        df.to_sql(
            name=staging_table_name,
            con=conn,
            if_exists='replace',
            index=False
        )
        print("Data successfully loaded into staging table.")
        
        sql_merge = f"""
        MERGE INTO Brokerage AS TGT
        USING {staging_table_name} AS SRC
        ON TGT.ProducerId = SRC.broker_id
        WHEN MATCHED THEN
            UPDATE SET TGT.LossRatio = SRC.loss_ratio;
        """
        
        print("Merging staged data into the final Brokerage table...")
        conn.execute(text(sql_merge))
        
        print("✅ Merge complete. Brokerage loss ratios updated successfully.")
    
    print("SQLAlchemy connection closed.")

args = {
    'owner': 'airflow',
    'start_date': pendulum.datetime(2025, 1, 1, tz="America/New_York"),
    'retries': 0,
    'retry_delay': timedelta(minutes=5),
}

with DAG(
    dag_id='metal_update_brokerage_loss_ratio',
    default_args=args,
    schedule_interval=None,
    catchup=False,
    max_active_runs=1,
    tags=['metal', 'edw', 'update', 'python'],
    doc_md="""
    ### Update Brokerage Loss Ratio (Cross-Server)
    """
) as dag:

    start = DummyOperator(
        task_id='start',
    )

    transfer_and_update_data = PythonOperator(
        task_id='transfer_and_update_broker_data',
        python_callable=extract_edw_and_update_metal,
    )

    end = DummyOperator(
        task_id='end',
    )

    start >> transfer_and_update_data >> end