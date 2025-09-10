import snowflake.connector
from app.utils.logging import logger

def get_sf_conn(config):
    """Create a Snowflake connection using injected config."""
    account = config.get("SF_ACCOUNT", "default_account")
    user = config.get("SF_USER", "default_user")
    pat = config.get("SF_PAT_TOKEN", "default_pat_token")
    role = config.get("SF_ROLE", "PUBLIC")
    warehouse = config.get("SF_WAREHOUSE", "default_warehouse")
    database = config.get("SF_DATABASE", "default_database")
    schema = config.get("SF_SCHEMA", "default_schema")

    conn = snowflake.connector.connect(
        account=account,
        user=user,
        password=pat,
        role=role,
        warehouse=warehouse,
        database=database,
        schema=schema
    )
    logger.info(f"Snowflake connection established for user '{user}' on account '{account}' with role '{role}'.")
    return conn
