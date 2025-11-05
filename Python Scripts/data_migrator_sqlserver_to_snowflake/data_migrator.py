import logging
import pandas as pd
import snowflake.connector
from snowflake.connector.pandas_tools import write_pandas
from sqlalchemy import create_engine
from sqlalchemy.engine import URL
from config_manager import ConfigManager
from typing import Optional

def setup_logger():
    """Sets up a formatted logger."""
    logger = logging.getLogger("DataMigrator")
    if not logger.handlers:
        logger.setLevel(logging.INFO)
        handler = logging.StreamHandler()
        formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )
        handler.setFormatter(formatter)
        logger.addHandler(handler)
    return logger

class DataMigrator:
    """
    Handles the migration of data from SQL Server to Snowflake, managing
    connections, configuration, and the ETL process.
    All secrets are retrieved from Azure Key Vault using Managed Identity.
    """
    def __init__(self, migration_config: Optional[dict] = None):
        """
        Initialize the DataMigrator.
        
        Args:
            migration_config: Optional dict with migration settings like 'load_all' and 'record_limit'.
                            If not provided, defaults will be used.
        """
        self.logger = setup_logger()
        
        # Load secrets from Azure Key Vault using Managed Identity
        self.logger.info("Initializing configuration from Azure Key Vault...")
        self.config_manager = ConfigManager(logger=self.logger)
        
        # Store migration settings
        if migration_config is None:
            migration_config = {'load_all': True, 'record_limit': 10000}
        self.migration_config = migration_config
        
        self.sql_engine = None
        self.sf_conn = None

    def __enter__(self):
        """Context manager entry to establish database connections."""
        self._connect_sql_server()
        self._connect_snowflake()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit to gracefully close database connections."""
        if self.sql_engine:
            self.sql_engine.dispose()
            self.logger.info("SQL Server connection closed.")
        if self.sf_conn:
            self.sf_conn.close()
            self.logger.info("Snowflake connection closed.")

    def _connect_sql_server(self):
        """Establishes connection to the source SQL Server using SQLAlchemy."""
        try:
            details = self.config_manager.get_sql_server_config()
            self.logger.info(f"Connecting to SQL Server: {details['server']}...")
            
            # Create SQLAlchemy connection URL
            connection_url = URL.create(
                "mssql+pyodbc",
                username=details['username'],
                password=details['password'],
                host=details['server'],
                database=details['database'],
                query={
                    "driver": "ODBC Driver 17 for SQL Server",
                }
            )
            
            self.sql_engine = create_engine(connection_url)
            # Test the connection
            with self.sql_engine.connect() as conn:
                from sqlalchemy import text
                conn.execute(text("SELECT 1"))
            self.logger.info("Successfully connected to SQL Server.")
        except Exception as e:
            self.logger.error(f"Failed to connect to SQL Server: {e}")
            raise

    def _connect_snowflake(self):
        """Establishes connection to Snowflake using the configured authentication method."""
        try:
            details = self.config_manager.get_snowflake_config()
            auth_method = details.get('authenticator', 'standard').lower()
            self.logger.info(f"Connecting to Snowflake using '{auth_method}' authentication...")

            params = {
                'account': details['account'], 
                'user': details['user'],
                'role': details.get('role'), 
                'warehouse': details['warehouse'],
                'database': details['database'], 
                'schema': details['schema'],
                'password': details['password']
            }

            self.sf_conn = snowflake.connector.connect(**params)
            role = self.sf_conn.cursor().execute("SELECT CURRENT_ROLE()").fetchone()[0]
            self.logger.info(f"Successfully connected to Snowflake. Using role: {role}")
        except snowflake.connector.errors.DatabaseError as e:
            self.logger.error(f"Failed to connect to Snowflake - Database Error: {e}")
            self.logger.error(f"Connection details: account={details['account']}, user={details['user']}, warehouse={details['warehouse']}, database={details['database']}, schema={details['schema']}")
            self.logger.error("Possible causes: Invalid credentials, account identifier incorrect, network/firewall issues, or Snowflake service unavailable")
            raise
        except snowflake.connector.errors.Error as e:
            self.logger.error(f"Failed to connect to Snowflake - Connector Error: {e}")
            self.logger.error(f"Connection details: account={details['account']}, user={details['user']}")
            raise
        except Exception as e:
            self.logger.error(f"Failed to connect to Snowflake - Unexpected Error: {e}")
            self.logger.error(f"Error type: {type(e).__name__}")
            raise

    def _extract_from_sql_server(self, source_table_name: str, source_schema: str, source_database: str) -> pd.DataFrame:
        """Extracts data for a table from a specific source database and schema using SQLAlchemy."""
        query = f"SELECT * FROM [{source_database}].[{source_schema}].[{source_table_name}]"
        if not self.migration_config.get('load_all', True):
            limit = self.migration_config.get('record_limit', 10000)
            query = f"SELECT TOP {limit} * FROM [{source_database}].[{source_schema}].[{source_table_name}]"
        
        self.logger.info(f"Executing query on SQL Server for {source_database}.{source_schema}.{source_table_name}")
        df = pd.read_sql(query, self.sql_engine)
        self.logger.info(f"Extracted {len(df)} records.")
        df = df.where(pd.notnull(df), None)
        
        return df

    def _load_to_snowflake(self, df: pd.DataFrame, target_table_name: str, target_schema: str, target_database: str, load_strategy: str):
        """Loads a DataFrame into Snowflake using the specified load strategy."""
        
        final_target_table = target_table_name.upper()
        
        # Convert DataFrame column names to uppercase to match Snowflake convention
        df.columns = [col.upper() for col in df.columns]
        df_to_load = df
        source_dtypes = df.dtypes # Get dtypes after uppercasing columns

        try:
            self.logger.info(f"Setting target context in Snowflake to: {target_database}.{target_schema}")
            self.sf_conn.cursor().execute(f"USE DATABASE {target_database}")
            self.sf_conn.cursor().execute(f"USE SCHEMA {target_schema}")

            if load_strategy in ('truncate', 'append'):
                self.logger.info(f"Validating schema for {final_target_table} (strategy: {load_strategy})...")
                
                # Get source columns (already uppercase)
                source_cols_upper = set(df_to_load.columns)

                # Get target columns AND data types from Snowflake (already uppercase)
                query = f"""
                SELECT COLUMN_NAME, DATA_TYPE 
                FROM {target_database}.INFORMATION_SCHEMA.COLUMNS
                WHERE TABLE_SCHEMA = '{target_schema.upper()}' 
                  AND TABLE_NAME = '{final_target_table}'
                """
                cur = self.sf_conn.cursor()
                cur.execute(query)
                # Create a map of {COL_NAME_UPPER: DATA_TYPE}
                target_col_types = {row[0].upper(): row[1] for row in cur.fetchall()}

                if not target_col_types:
                    raise ValueError(f"Table '{final_target_table}' does not exist in {target_database}.{target_schema}. Cannot use '{load_strategy}' strategy.")

                # Find matching columns
                matching_cols_upper = source_cols_upper & target_col_types.keys()
                
                # Log any columns that will be dropped
                skipped_cols = source_cols_upper - matching_cols_upper
                if skipped_cols:
                    self.logger.warning(f"Schema mismatch: The following {len(skipped_cols)} source columns do not exist in the target table and will be SKIPPED: {list(skipped_cols)}")
                
                if not matching_cols_upper:
                    raise ValueError(f"No matching columns found between source and target '{final_target_table}'. Skipping load.")

                # Create the new, filtered DataFrame
                df_to_load = df[list(matching_cols_upper)].copy()

                # Apply data type casts based on target Snowflake schema
                self.logger.info("Checking for required data type casts...")
                for col in df_to_load.columns: # Columns are already uppercase
                    src_type = source_dtypes[col]
                    tgt_type = target_col_types[col] # Get Snowflake type
                    
                    try:
                        # Rule 1: Source is a datetime/timestamp, Target is DATE
                        if pd.api.types.is_datetime64_any_dtype(src_type) and tgt_type == 'DATE':
                            self.logger.info(f"Casting column '{col}' from datetime to date string.")
                            df_to_load[col] = pd.to_datetime(df_to_load[col]).dt.strftime('%Y-%m-%d').replace({pd.NaT: None})

                        # Rule 2: Source is object (string), Target is DATE
                        elif pd.api.types.is_object_dtype(src_type) and tgt_type == 'DATE':
                            self.logger.info(f"Casting column '{col}' from object to date string.")
                            df_to_load[col] = pd.to_datetime(df_to_load[col], errors='coerce').dt.strftime('%Y-%m-%d').replace({pd.NaT: None})

                        # Rule 3: Source is object (string), Target is any TIMESTAMP
                        elif pd.api.types.is_object_dtype(src_type) and 'TIMESTAMP' in tgt_type:
                            self.logger.info(f"Casting column '{col}' from object to datetime.")
                            df_to_load[col] = pd.to_datetime(df_to_load[col], errors='coerce').replace({pd.NaT: None})

                        # Rule 4: Source is datetime, Target is also a TIMESTAMP variant
                        elif pd.api.types.is_datetime64_any_dtype(src_type) and 'TIMESTAMP' in tgt_type:
                            self.logger.info(f"Formatting column '{col}' to millisecond precision string.")
                            df_to_load[col] = df_to_load[col].dt.strftime('%Y-%m-%d %H:%M:%S.%f').str[:-3]

                        # Rule 5: Source is number, Target is VARCHAR/TEXT
                        elif pd.api.types.is_numeric_dtype(src_type) and tgt_type in ('VARCHAR', 'TEXT', 'STRING'):
                            self.logger.info(f"Casting column '{col}' from numeric to string.")
                            df_to_load[col] = df_to_load[col].astype(str).replace({'<NA>': None, 'nan': None})
                        
                        # Rule 6: Source is object (string), Target is NUMBER/FLOAT
                        elif pd.api.types.is_object_dtype(src_type) and tgt_type in ('NUMBER', 'FLOAT', 'DECIMAL', 'NUMERIC'):
                            self.logger.info(f"Casting column '{col}' from object to numeric.")
                            df_to_load[col] = pd.to_numeric(df_to_load[col], errors='coerce').replace({pd.NaT: None})

                    except Exception as cast_error:
                        self.logger.error(f"Failed to cast column '{col}' from {src_type} to {tgt_type}. Error: {cast_error}. Setting column to NULL.", exc_info=False)
                        df_to_load[col] = None # Set entire column to None to prevent load failure
            
            else: # This 'else' handles the 'recreate' strategy
                # For 'recreate', apply standard datetime formatting (milliseconds)
                self.logger.info("Strategy is 'recreate'. Applying standard datetime formatting.")
                for col in df_to_load.columns:
                    if pd.api.types.is_datetime64_any_dtype(df_to_load[col]):
                        df_to_load[col] = df_to_load[col].dt.strftime('%Y-%m-%d %H:%M:%S.%f').str[:-3]

            log_message = {
                'recreate': f"Using 'recreate' strategy: Dropping and recreating table {final_target_table}...",
                'truncate': f"Using 'truncate' strategy: Truncating table {final_target_table} before load...",
                'append': f"Using 'append' strategy: Appending data to existing table {final_target_table}..."
            }
            
            self.logger.info(log_message.get(load_strategy))
            self.logger.info(f"Preparing to load {len(df_to_load)} records ({len(df_to_load.columns)} columns) into {target_database}.{target_schema}.{final_target_table}...")

            # Call write_pandas with correct parameters based on strategy
            if load_strategy == 'recreate':
                success, nchunks, nrows, _ = write_pandas(
                    conn=self.sf_conn,
                    df=df_to_load,
                    table_name=final_target_table,
                    auto_create_table=True,
                    overwrite=True
                )
            elif load_strategy == 'truncate':
                cursor = self.sf_conn.cursor()
                try:
                    cursor.execute(f"TRUNCATE TABLE {final_target_table}")
                    self.logger.info(f"Table {final_target_table} truncated successfully.")
                except Exception as e:
                    self.logger.error(f"Failed to truncate table: {e}")
                    raise
                finally:
                    cursor.close()
                
                success, nchunks, nrows, _ = write_pandas(
                    conn=self.sf_conn,
                    df=df_to_load,
                    table_name=final_target_table,
                    auto_create_table=False,
                    overwrite=False
                )
            else:  # append
                success, nchunks, nrows, _ = write_pandas(
                    conn=self.sf_conn,
                    df=df_to_load,
                    table_name=final_target_table,
                    auto_create_table=False,
                    overwrite=False
                )
            
            if success:
                self.logger.info(f"Successfully loaded {nrows} records.")
            else:
                raise Exception(f"write_pandas returned success=False for {target_database}.{target_schema}.{final_target_table}")
        
        except Exception as e:
            # Provide a specific error message if an 'append' or 'truncate' fails because the table is missing
            if load_strategy in ('append', 'truncate') and "does not exist" in str(e):
                 self.logger.error(f"Load failed for '{load_strategy}' strategy: Table '{final_target_table}' does not exist. Please create it or use 'recreate' strategy.")
            else:
                 self.logger.error(f"Could not load data to {target_database}.{target_schema}.{final_target_table}: {type(e).__name__}: {str(e)}", exc_info=True)
            raise # Re-raise the exception to be caught by run_migration

    def run_migration(self, migration_tasks: list):
        """Runs the migration process for a list of migration tasks."""
        if not migration_tasks:
            self.logger.error("No migration tasks provided. Exiting.")
            raise ValueError("No migration tasks provided")

        self.logger.info(f"Starting migration for {len(migration_tasks)} task(s).")
        
        # Track successful and failed tasks
        successful_tasks = []
        failed_tasks = []
        skipped_tasks = []

        for task in migration_tasks:
            source_db = task.get('source_database')
            source_schema = task.get('source_schema')
            source_table = task.get('source_table_name')
            target_db = task.get('target_database')
            target_schema = task.get('target_schema')
            target_table = task.get('target_table_name') or source_table
            
            # Default to 'truncate' if not specified.
            load_strategy = task.get('load_strategy', 'truncate').lower()

            # Build task identifier for reporting
            task_id = f"{source_db}.{source_schema}.{source_table} -> {target_db}.{target_schema}.{target_table}"

            if not all([source_db, source_schema, source_table, target_db, target_schema, target_table]):
                self.logger.warning(f"Skipping invalid task: {task}. Missing required keys.")
                skipped_tasks.append({"task": task_id, "reason": "Missing required keys"})
                continue
                
            # Validate the load strategy
            if load_strategy not in ['recreate', 'truncate', 'append']:
                self.logger.warning(f"Skipping task for {source_table}: Invalid load_strategy '{load_strategy}'. Must be 'recreate', 'truncate', or 'append'.")
                skipped_tasks.append({"task": task_id, "reason": f"Invalid load_strategy: {load_strategy}"})
                continue

            try:
                self.logger.info(f"--- Processing task: {task_id} (Strategy: {load_strategy}) ---")
                
                df = self._extract_from_sql_server(source_table, source_schema, source_db)
                
                if df.empty:
                    self.logger.warning(f"Source table is empty. Skipping load.")
                    skipped_tasks.append({"task": task_id, "reason": "Source table is empty"})
                    continue
                
                # Pass the strategy to the load method
                self._load_to_snowflake(df, target_table, target_schema, target_db, load_strategy)
                successful_tasks.append(task_id)
                
            except Exception as e:
                error_msg = f"{type(e).__name__}: {str(e)}"
                self.logger.error(f"An error occurred while processing task for table {source_table}: {error_msg}")
                failed_tasks.append({"task": task_id, "error": error_msg})
        
        # Summary report
        self.logger.info("=" * 80)
        self.logger.info("MIGRATION PROCESS SUMMARY")
        self.logger.info("=" * 80)
        self.logger.info(f"Total tasks: {len(migration_tasks)}")
        self.logger.info(f"Successful: {len(successful_tasks)}")
        self.logger.info(f"Failed: {len(failed_tasks)}")
        self.logger.info(f"Skipped: {len(skipped_tasks)}")
        
        if successful_tasks:
            self.logger.info("\n✓ SUCCESSFUL TASKS:")
            for task in successful_tasks:
                self.logger.info(f"  ✓ {task}")
        
        if failed_tasks:
            self.logger.error("\n✗ FAILED TASKS:")
            for item in failed_tasks:
                self.logger.error(f"  ✗ {item['task']}")
                self.logger.error(f"    Error: {item['error']}")
        
        if skipped_tasks:
            self.logger.warning("\n⊘ SKIPPED TASKS:")
            for item in skipped_tasks:
                self.logger.warning(f"  ⊘ {item['task']}")
                self.logger.warning(f"    Reason: {item['reason']}")
        
        self.logger.info("=" * 80)
        
        # Raise exception if any task failed
        if failed_tasks:
            error_summary = f"{len(failed_tasks)} out of {len(migration_tasks)} migration task(s) failed"
            self.logger.error(error_summary)
            raise Exception(error_summary)