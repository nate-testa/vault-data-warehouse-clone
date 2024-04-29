import sys
import snowflake.connector
import logging
import configparser
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception_type, before_sleep_log

def load_config():
    """Load configuration from a file."""
    config = configparser.ConfigParser()
    config.read('config.ini')
    return config
    
config = load_config()

@retry(
    stop=stop_after_attempt(5), 
    wait=wait_exponential(multiplier=1, max=16), 
    retry=retry_if_exception_type(snowflake.connector.Error), 
    before_sleep=before_sleep_log(logging.getLogger(), logging.INFO))
def create_connection():
    """Creates and returns a Snowflake connection using environment or predefined variables."""
    try:
        connection = snowflake.connector.connect(
            user=config['Snowflake']['user'],
            password=config['Snowflake']['password'],
            account=config['Snowflake']['account'],
            warehouse=config['Snowflake']['warehouse'],
            database=config['Snowflake']['database'],
            schema=config['Snowflake']['schema'],
            role=config['Snowflake']['role'],
            protocol=config['Snowflake']['protocol']
        )
        logging.info("Successfully connected to Snowflake.")
        return connection
    except snowflake.connector.Error as e:
        logging.error("Snowflake connector-specific error occurred: %s", e)
        raise  # Re-raise the exception to trigger a retry
    except Exception as e:
        logging.error("An unexpected error occurred while trying to connect to Snowflake: %s", e)
        sys.exit(1)  # Exit if a non-Snowflake specific error occurs

def get_file_count(ctx, arg):
    """Retrieve the count of files in the specified stage and path."""
    cur = ctx.cursor()
    try:
        cur.execute(f"LIST @json_stage/{arg}_split/")
        results = cur.fetchall()
        file_count = len(results)
        logging.info("Number of files found: %d", file_count)
        return file_count
    except Exception as e:
        logging.error("Failed to list files: %s", e)
        return 0
    finally:
        cur.close()

def load_data(arg):
    ctx = create_connection()
    try:
        cur = ctx.cursor()
        # Create a new staging table
        cur.execute(f"CREATE OR REPLACE TABLE json_staging_{arg} (v VARIANT);")
        logging.info("Staging table created successfully.")

        # Dynamically find the number of parts
        number_of_parts = get_file_count(ctx, arg)
        if number_of_parts == 0:
            logging.error("No files to process, exiting.")
            return

        # Execute copy into for each part
        for i in range(1, number_of_parts + 1):
            cur.execute(f"""
                COPY INTO json_staging_{arg}
                FROM @json_stage/{arg}_split/part_{i}.json
                FILE_FORMAT = (FORMAT_NAME = 'json_format');
            """)
            logging.info("Data copied successfully from part %d.", i)
    except Exception as e:
        logging.error("Failed during data load: %s", e)
    finally:
        cur.close()
        ctx.close()

def main():
    if len(sys.argv) < 2:
        logging.error("Usage: python script.py <argument>")
        sys.exit(1)
    
    arg = sys.argv[1]
    load_data(arg)

if __name__ == "__main__":
    main()