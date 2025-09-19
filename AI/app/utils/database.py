"""
Database utilities for the Snowflake AI application.

This module contains database connection functions and utilities
that can be shared across different modules.
"""

import os
import snowflake.connector
from dotenv import load_dotenv
from app.utils.logging import logger

# Load environment variables
load_dotenv()


def get_sf_conn():
    """
    Create a basic Snowflake connection reading configuration from environment variables.
    
    This function establishes a basic connection with account, user, password and role.
    Required environment variables:
    - SF_ACCOUNT: Snowflake account identifier
    - SF_USER: Snowflake username
    - SF_PAT_TOKEN: Snowflake password/token
    - SF_ROLE: Snowflake role
    
    Returns:
        tuple: (connection, cursor) objects
    """
    # Check required environment variables
    required_env_vars = ["SF_ACCOUNT", "SF_USER", "SF_PAT_TOKEN", "SF_ROLE"]
    missing_vars = [var for var in required_env_vars if not os.getenv(var)]
    if missing_vars:
        raise RuntimeError(f"Missing required environment variables: {', '.join(missing_vars)}")
    
    account = os.getenv('SF_ACCOUNT')
    user = os.getenv('SF_USER')
    pat = os.getenv('SF_PAT_TOKEN')
    role = os.getenv('SF_ROLE')

    conn = snowflake.connector.connect(
        account=account,
        user=user,
        password=pat,
        role=role
    )
    cursor = conn.cursor()
    logger.info(f"Snowflake connection established for user '{user}' on account '{account}' with role '{role}'.")

    return conn, cursor
