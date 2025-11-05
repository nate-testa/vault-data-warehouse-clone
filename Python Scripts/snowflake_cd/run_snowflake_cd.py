import sys
import logging
import pathlib
import snowflake.connector
from config_manager import ConfigManager
from typing import Dict, List

# --- Configuration ---

# Define the root of this script to find the 'input_sql' folder
SCRIPT_ROOT = pathlib.Path(__file__).resolve().parent
INPUT_SQL_PATH = SCRIPT_ROOT / "input_sql"

# --- FIX 2: Added "SQL" to the execution order ---
EXECUTION_ORDER = ["DDL", "DML", "Functions", "Stored Procedures", "SQL"]

# --- Logger Setup ---

def setup_logger():
    """Sets up a formatted logger that splits INFO and ERROR streams."""
    logger = logging.getLogger("SnowflakeCD")
    if not logger.handlers:
        logger.setLevel(logging.INFO)  # Set logger to the lowest level
        
        formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )
        
        # --- Handler 1: STDOUT for INFO and DEBUG (Green/White text) ---
        class InfoFilter(logging.Filter):
            def filter(self, record):
                return record.levelno < logging.WARNING

        stdout_handler = logging.StreamHandler(sys.stdout)
        stdout_handler.setLevel(logging.INFO)
        stdout_handler.setFormatter(formatter)
        stdout_handler.addFilter(InfoFilter())
        
        # --- Handler 2: STDERR for WARNING, ERROR, CRITICAL (Red text) ---
        stderr_handler = logging.StreamHandler(sys.stderr)
        stderr_handler.setLevel(logging.WARNING)
        stderr_handler.setFormatter(formatter)

        # Add both handlers to the logger
        logger.addHandler(stdout_handler)
        logger.addHandler(stderr_handler)
        
    return logger

# --- Core Functions ---

def find_and_categorize_sql_files(base_path: pathlib.Path, logger: logging.Logger) -> Dict[str, List[pathlib.Path]]:
    """
    Finds all .sql files and categorizes them based on their parent folder.
    """
    logger.info(f"Scanning for SQL files in: {base_path}")
    
    # Initialize dictionary to hold file paths, respecting the execution order
    sql_files = {category: [] for category in EXECUTION_ORDER}
    sql_files["Other"] = [] # For any files not in a recognized folder

    all_found_files = list(base_path.glob('**/*.sql'))
    logger.info(f"Found {len(all_found_files)} total .sql files.")

    for file_path in all_found_files:
        category = file_path.parent.name
        if category in sql_files:
            sql_files[category].append(file_path)
        else:
            logger.warning(f"Found file in uncategorized folder '{category}': {file_path.name}")
            sql_files["Other"].append(file_path)
            
    # Sort files alphabetically within each category to ensure consistent order
    for category_files in sql_files.values():
        category_files.sort()
        
    return sql_files

def connect_to_snowflake(config: dict, logger: logging.Logger) -> snowflake.connector.SnowflakeConnection:
    """
    Establishes and returns a connection to Snowflake.
    """
    try:
        auth_method = config.get('authenticator', 'standard').lower()
        logger.info(f"Connecting to Snowflake using '{auth_method}' authentication...")

        params = {
            'account': config['account'], 
            'user': config['user'],
            'role': config.get('role'), 
            'warehouse': config['warehouse'],
            'database': config['database'], 
            'schema': config['schema'],
            'password': config['password']
        }

        conn = snowflake.connector.connect(**params)
        role = conn.cursor().execute("SELECT CURRENT_ROLE()").fetchone()[0]
        db = conn.cursor().execute("SELECT CURRENT_DATABASE()").fetchone()[0]
        schema = conn.cursor().execute("SELECT CURRENT_SCHEMA()").fetchone()[0]
        logger.info(f"Successfully connected to Snowflake. Role: {role}, DB: {db}, Schema: {schema}")
        return conn
    except Exception as e:
        logger.error(f"Failed to connect to Snowflake: {e}")
        raise

def execute_sql_file(cursor: snowflake.connector.cursor.SnowflakeCursor, file_path: pathlib.Path, logger: logging.Logger):
    """
    Executes all SQL statements within a single file.
    """
    logger.info(f"--- Executing file: {file_path.name}")
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            sql_content = f.read()
        
        if not sql_content.strip():
            logger.warning(f"File {file_path.name} is empty. Skipping.")
            return

        # Use execute_string to handle files with multiple SQL statements
        for stmt in cursor.execute_string(sql_content):
            logger.debug(f"Executed statement, result: {stmt.fetchone()}")
        
        logger.info(f"✓ Successfully executed: {file_path.name}")
        
    except Exception as e:
        logger.error(f"✗ FAILED to execute: {file_path.name}")
        logger.error(f"Error details: {e}")
        raise  # Re-raise the exception to stop the entire process

def cleanup_files(base_path: pathlib.Path, logger: logging.Logger):
    """
    Deletes all .sql files found within the base_path directory.
    """
    logger.info(f"Cleaning up files in {base_path}...")
    count = 0
    try:
        for file_path in base_path.glob('**/*.sql'):
            file_path.unlink() # Deletes the file
            count += 1
        logger.info(f"Successfully deleted {count} .sql files.")
    except Exception as e:
        logger.error(f"Failed during file cleanup: {e}")
        # Do not re-raise, as the SQL execution was already successful

# --- Main Execution ---

def main():
    """
    Main orchestration function.
    """
    logger = setup_logger()
    logger.info("=" * 40)
    logger.info("Starting Snowflake Continuous Deployment script.")
    logger.info("=" * 40)
    
    conn = None
    cursor = None
    
    try:
        # 1. Load Secrets
        logger.info("Loading configuration from Azure Key Vault...")
        config_manager = ConfigManager(logger=logger)
        sf_config = config_manager.get_snowflake_config()
        
        # 2. Find and Categorize SQL Files
        all_files = find_and_categorize_sql_files(INPUT_SQL_PATH, logger)
        
        # 3. Connect to Snowflake
        conn = connect_to_snowflake(sf_config, logger)
        cursor = conn.cursor()
        
        # 4. Execute SQL in order
        total_files_executed = 0
        for category in EXECUTION_ORDER:
            files_in_category = all_files.get(category, [])
            if files_in_category:
                logger.info(f"\n--- Processing Category: {category} ({len(files_in_category)} files) ---")
                for file_path in files_in_category:
                    execute_sql_file(cursor, file_path, logger)
                    total_files_executed += 1
            else:
                logger.info(f"\n--- No files found for category: {category}. Skipping. ---")

        logger.info(f"\nSuccessfully executed all {total_files_executed} SQL files.")

        # 5. Cleanup Files (only on success)
        cleanup_files(INPUT_SQL_PATH, logger)

        logger.info("=" * 40)
        logger.info("Snowflake CD process finished successfully.")
        logger.info("=" * 40)

    except Exception as e:
        logger.error(f"\nA critical error occurred: {e}")
        logger.error("Migration process HALTED.")
        logger.info("=" * 40)
        sys.exit(1) # Exit with an error code
        
    finally:
        # 6. Close connections
        if cursor:
            cursor.close()
        if conn:
            conn.close()
            logger.info("Snowflake connection closed.")

if __name__ == "__main__":
    main()