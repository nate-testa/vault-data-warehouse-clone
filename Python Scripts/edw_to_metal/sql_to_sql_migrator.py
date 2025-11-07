"""
SQL Server to SQL Server Data Migrator

This module contains the SqlToSqlMigrator class, which is responsible for
executing configurable data migration tasks from one SQL Server (Source)
to another SQL Server (Target).

It uses configuration from 'config_manager.py' to securely retrieve
credentials from Azure Key Vault and reads migration tasks from a JSON file.
"""

import logging
import sys
import pandas as pd
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL, Engine
from config_manager import ConfigManager
from typing import List, Dict, Any

def setup_logger() -> logging.Logger:
    """
    Configures and returns a logger instance.

    This setup splits logging streams:
    - INFO and DEBUG messages are sent to sys.stdout (standard output).
    - WARNING, ERROR, and CRITICAL messages are sent to sys.stderr (standard error).
    
    This separation is crucial for CI/CD pipelines (like Azure DevOps)
    to correctly distinguish informational logs from actual error messages.
    """
    logger = logging.getLogger("SqlToSqlMigrator")
    if not logger.handlers:
        logger.setLevel(logging.INFO)  # Set the logger's minimum reporting level

        formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )

        # --- Handler 1: STDOUT for INFO (and below) ---
        class InfoFilter(logging.Filter):
            """Filters log records to allow only those below WARNING level."""
            def filter(self, record):
                return record.levelno < logging.WARNING

        stdout_handler = logging.StreamHandler(sys.stdout)
        stdout_handler.setLevel(logging.INFO)
        stdout_handler.setFormatter(formatter)
        stdout_handler.addFilter(InfoFilter())

        # --- Handler 2: STDERR for WARNING (and above) ---
        stderr_handler = logging.StreamHandler(sys.stderr)
        stderr_handler.setLevel(logging.WARNING)
        stderr_handler.setFormatter(formatter)

        # Add both handlers to the root logger
        logger.addHandler(stdout_handler)
        logger.addHandler(stderr_handler)

    return logger

class SqlToSqlMigrator:
    """
    Orchestrates the migration of data from a source SQL Server to a target SQL Server.

    This class manages database connections as context managers and iterates
    through a list of migration tasks, performing an Extract, Load (EL)
    process for each task defined in the `sql_tasks.json` file.
    """
    
    def __init__(self):
        """Initializes the migrator by setting up the logger and loading configuration."""
        self.logger = setup_logger()
        self.logger.info("Initializing configuration from Azure Key Vault...")
        
        # Load all secrets (e.g., server names, credentials) from Key Vault
        self.config_manager = ConfigManager(logger=self.logger)
        
        # Initialize connection engines as None; they will be set in __enter__
        self.host1_engine: Engine | None = None
        self.host2_engine: Engine | None = None

    def __enter__(self):
        """
        Context manager entry point.
        Establishes and tests connections to both source and target databases.
        """
        self.logger.info("Establishing database connections...")
        host1_config = self.config_manager.get_sql_host1_config()
        self.host1_engine = self._connect_sql_server(host1_config, "Host 1 (Source)")
        
        host2_config = self.config_manager.get_sql_host2_config()
        self.host2_engine = self._connect_sql_server(host2_config, "Host 2 (Target)")
        
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        """
        Context manager exit point.
        Ensures all database connections are gracefully closed and disposed of.
        """
        if self.host1_engine:
            self.host1_engine.dispose()
            self.logger.info("Host 1 (Source) SQL Server connection closed.")
        if self.host2_engine:
            self.host2_engine.dispose()
            self.logger.info("Host 2 (Target) SQL Server connection closed.")

    def _connect_sql_server(self, details: dict, host_name: str) -> Engine:
        """
        Creates and tests a SQLAlchemy Engine for a given SQL Server.

        Args:
            details: A dictionary containing connection parameters 
                     (server, database, username, password).
            host_name: A friendly name for logging (e.g., "Host 1 (Source)").

        Returns:
            A connected and tested SQLAlchemy Engine instance.
        """
        try:
            self.logger.info(f"Connecting to {host_name} SQL Server: {details['server']}...")
            
            # Create a pyodbc connection URL
            connection_url = URL.create(
                "mssql+pyodbc",
                username=details['username'],
                password=details['password'],
                host=details['server'],
                database=details['database'],
                query={"driver": "ODBC Driver 17 for SQL Server"}
            )
            
            # Create the engine. Connections are pooled and managed automatically.
            engine = create_engine(connection_url)
            
            # Test the connection by executing a simple query
            with engine.connect() as conn:
                conn.execute(text("SELECT 1"))
                
            self.logger.info(f"Successfully connected to {host_name} SQL Server.")
            return engine
        
        except Exception as e:
            self.logger.error(f"Failed to connect to {host_name} SQL Server: {e}")
            raise

    def _extract_from_source(self, query: str) -> pd.DataFrame:
        """
        Extracts data from the source (Host 1) using the provided SQL query.

        Args:
            query: The SQL SELECT statement to execute on the source server.

        Returns:
            A pandas DataFrame containing the extracted data.
        """
        self.logger.info("Executing source query on Host 1...")
        
        # Use pandas to directly execute the query and load results into a DataFrame
        df = pd.read_sql(query, self.host1_engine)
        
        self.logger.info(f"Extracted {len(df)} records.")
        
        # Sanitize data: Replace pandas NaT/NaN with None for SQL compatibility
        df = df.where(pd.notnull(df), None)
        return df

    def _load_to_target(self, df: pd.DataFrame, target_db: str, target_schema: str, target_table: str, load_strategy: str):
        """
        Loads the extracted DataFrame into the target (Host 2) database.

        Args:
            df: The pandas DataFrame to be loaded.
            target_db: The name of the target database.
            target_schema: The name of the target schema.
            target_table: The name of the target table.
            load_strategy: Either 'append' or 'truncate'.
        """
        log_table_name = f"{target_db}.{target_schema}.{target_table}"
        self.logger.info(f"Preparing to load {len(df)} records into {log_table_name} on Host 2...")
        
        # Use host2_engine.begin() to ensure the entire load process
        # (including truncate) is wrapped in a single transaction.
        # It will automatically commit on success or rollback on failure.
        with self.host2_engine.begin() as conn:
            try:
                # 1. Set Database Context
                # We must wrap raw SQL commands like 'USE' in text()
                # to mark them as executable statements for SQLAlchemy.
                conn.execute(text(f"USE {target_db}"))
                self.logger.info(f"Set database context to: {target_db}")

                # 2. Apply Load Strategy
                if load_strategy == 'truncate':
                    self.logger.info(f"Truncating target table: {log_table_name}...")
                    # Also wrap TRUNCATE in text()
                    conn.execute(text(f"TRUNCATE TABLE [{target_schema}].[{target_table}]"))
                    self.logger.info("Truncate complete.")
                
                # 3. Load Data
                # Use pandas.to_sql for efficient bulk loading.
                df.to_sql(
                    name=target_table,
                    con=conn,
                    schema=target_schema,
                    if_exists='append',  # We always append (after an optional truncate)
                    index=False,         # Do not write the pandas index as a column
                    chunksize=10000,     # Load data in chunks of 10k rows
                    method='multi'       # Use 'multi' for fast bulk-insert syntax with pyodbc
                )
                
                self.logger.info(f"Successfully loaded {len(df)} records to {log_table_name}.")

            except Exception as e:
                # The 'with...begin()' block will automatically rollback the transaction
                self.logger.error(f"Failed to load data to {log_table_name}: {type(e).__name__}: {e}")
                raise

    def run_migration(self, migration_tasks: List[Dict[str, Any]]):
        """
        Runs the end-to-end migration process for all provided tasks.

        Args:
            migration_tasks: A list of task dictionaries read from sql_tasks.json.
        """
        if not migration_tasks:
            self.logger.error("No migration tasks provided. Exiting.")
            raise ValueError("No migration tasks provided")

        self.logger.info(f"Starting migration for {len(migration_tasks)} task(s).")
        
        successful_tasks, failed_tasks, skipped_tasks = [], [], []

        for task in migration_tasks:
            # --- 1. Read and Validate Task Configuration ---
            task_name = task.get('task_name', 'Unnamed Task')
            source_query = task.get('source_query')
            target_db = task.get('target_database')
            target_schema = task.get('target_schema')
            target_table = task.get('target_table_name')
            load_strategy = task.get('load_strategy', 'append').lower()
            task_id = f"{task_name} -> {target_db}.{target_schema}.{target_table}"

            if not all([source_query, target_db, target_schema, target_table]):
                self.logger.warning(f"Skipping invalid task: {task_id}. Missing required keys.")
                skipped_tasks.append({"task": task_id, "reason": "Missing required keys"})
                continue
                
            if load_strategy not in ['truncate', 'append']:
                self.logger.warning(f"Skipping task '{task_name}': Invalid load_strategy '{load_strategy}'. Must be 'truncate' or 'append'.")
                skipped_tasks.append({"task": task_id, "reason": f"Invalid load_strategy: {load_strategy}"})
                continue

            # --- 2. Execute Task ---
            try:
                self.logger.info(f"--- Processing task: {task_id} (Strategy: {load_strategy}) ---")
                
                # EXTRACT
                df = self._extract_from_source(source_query)
                
                if df.empty:
                    self.logger.warning(f"Source query returned 0 records. Skipping load.")
                    skipped_tasks.append({"task": task_id, "reason": "Source query returned no data"})
                    continue
                
                # LOAD
                self._load_to_target(df, target_db, target_schema, target_table, load_strategy)
                successful_tasks.append(task_id)
                
            except Exception as e:
                # Log the error and continue to the next task
                error_msg = f"{type(e).__name__}: {str(e)}"
                self.logger.error(f"An error occurred while processing task {task_name}: {error_msg}")
                failed_tasks.append({"task": task_id, "error": error_msg})
        
        # --- 3. Print Summary Report ---
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
        
        # If any task failed, raise an exception to fail the pipeline
        if failed_tasks:
            error_summary = f"{len(failed_tasks)} out of {len(migration_tasks)} migration task(s) failed"
            self.logger.error(error_summary)
            raise Exception(error_summary)