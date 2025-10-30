"""
Database utilities for the Snowflake AI application.

This module contains database connection functions and utilities
that can be shared across different modules.

All Snowflake credentials are loaded from Azure Key Vault (NO .env fallback).
"""

import snowflake.connector
from app.utils.logging import logger
from app.utils.azure_keyvault import keyvault


def get_sf_conn():
    """
    Create a basic Snowflake connection using secrets from Azure Key Vault.
    
    This function establishes a connection with account, user, password and role.
    Secrets are loaded ONLY from Azure Key Vault (NO .env fallback).
    
    Required secrets in Key Vault:
    - vaultai-snowflake-account: Snowflake account identifier
    - vaultai-snowflake-user: Snowflake username
    - vaultai-snowflake-pat-token: Snowflake password/token
    - vaultai-snowflake-role: Snowflake role
    
    Returns:
        tuple: (connection, cursor) objects
    
    Raises:
        RuntimeError: If required secrets are not found in Key Vault or
                     if Key Vault connection fails
    """
    # Load secrets from Key Vault (NO .env fallback - will raise RuntimeError if not found)
    account = keyvault.get_secret('vaultai-snowflake-account')
    user = keyvault.get_secret('vaultai-snowflake-user')
    pat = keyvault.get_secret('vaultai-snowflake-pat-token')
    role = keyvault.get_secret('vaultai-snowflake-role')
    
    # Establish connection
    conn = snowflake.connector.connect(
        account=account,
        user=user,
        password=pat,
        role=role
    )
    cursor = conn.cursor()
    logger.info(f"Snowflake connection established for user '{user}' on account '{account}' with role '{role}'.")

    return conn, cursor
