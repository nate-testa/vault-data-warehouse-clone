"""
Azure Key Vault Configuration Manager

This module manages all secret retrieval from Azure Key Vault using Managed Identity.
All secrets are prefixed with 'datamigration-' in the Key Vault.
"""

import os
import logging
import sys  # <--- IMPORTED SYS
from azure.identity import ManagedIdentityCredential
from azure.keyvault.secrets import SecretClient
from azure.core.exceptions import AzureError
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

class ConfigManager:
    """
    Manages configuration and secrets retrieval from Azure Key Vault.
    Uses Managed Identity for authentication (no credentials needed).
    """
    
    # Azure Key Vault URI - read from environment variable

    KEY_VAULT_URI = os.getenv('KEY_VAULT_URI', 'key-vault-uri-not-set')
    
    # Secret names in Key Vault (all prefixed with 'datamigration-')
    SECRET_NAMES = {
        'sql_server': 'datamigration-sql-server',
        'sql_database': 'datamigration-sql-database',
        'sql_username': 'datamigration-sql-username',
        'sql_password': 'datamigration-sql-password',
        'snowflake_account': 'datamigration-snowflake-account',
        'snowflake_user': 'datamigration-snowflake-user',
        'snowflake_password': 'datamigration-snowflake-password',
        'snowflake_role': 'datamigration-snowflake-role',
        'snowflake_warehouse': 'datamigration-snowflake-warehouse',
        'snowflake_database': 'datamigration-snowflake-database',
        'snowflake_schema': 'datamigration-snowflake-schema',
    }
    
    def __init__(self, logger=None):
        """
        Initialize the Config Manager with Managed Identity authentication.
        
        Args:
            logger: Optional logger instance. If not provided, creates a new one.
        """
        self.logger = logger or self._setup_logger()
        self.secrets = {}
        self._load_secrets()
    
    def _setup_logger(self):
        """Sets up a basic logger that splits INFO and ERROR streams."""
        logger = logging.getLogger("ConfigManager")
        if not logger.handlers:
            logger.setLevel(logging.INFO) # Set logger to the lowest level
            
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
    
    def _load_secrets(self):
        """
        Loads all secrets from Azure Key Vault using Managed Identity.
        """
        try:
            self.logger.info("Connecting to Azure Key Vault using Managed Identity...")
            
            # Use ManagedIdentityCredential directly (no env vars or local credentials)
            credential = ManagedIdentityCredential()
            client = SecretClient(vault_url=self.KEY_VAULT_URI, credential=credential)
            
            self.logger.info(f"Successfully connected to Key Vault: {self.KEY_VAULT_URI}")
            
            # Fetch all secrets
            for key, secret_name in self.SECRET_NAMES.items():
                try:
                    self.logger.info(f"Fetching secret: {secret_name}")
                    secret = client.get_secret(secret_name)
                    self.secrets[key] = secret.value
                    self.logger.info(f"✓ Successfully retrieved secret for: {key}")
                except Exception as e:
                    self.logger.error(f"✗ Failed to retrieve secret '{secret_name}' for key '{key}': {e}")
                    raise
            
            self.logger.info(f"Successfully loaded {len(self.secrets)} secrets from Key Vault")
            
        except AzureError as e:
            self.logger.error(f"Azure Key Vault error: {e}")
            raise
        except Exception as e:
            self.logger.error(f"Unexpected error loading secrets: {e}")
            raise
    
    def get_sql_server_config(self):
        """
        Returns SQL Server configuration dictionary.
        
        Returns:
            dict: SQL Server connection parameters
        """
        return {
            'server': self.secrets['sql_server'],
            'database': self.secrets['sql_database'],
            'username': self.secrets['sql_username'],
            'password': self.secrets['sql_password']
        }
    
    def get_snowflake_config(self):
        """
        Returns Snowflake configuration dictionary.
        
        Returns:
            dict: Snowflake connection parameters
        """
        return {
            'account': self.secrets['snowflake_account'],
            'user': self.secrets['snowflake_user'],
            'password': self.secrets['snowflake_password'],
            'role': self.secrets['snowflake_role'],
            'warehouse': self.secrets['snowflake_warehouse'],
            'database': self.secrets['snowflake_database'],
            'schema': self.secrets['snowflake_schema'],
            'authenticator': 'standard'  # Using standard auth with password
        }
    
    def get_secret(self, key):
        """
        Get a specific secret value by key.
        
        Args:
            key: The secret key (e.g., 'sql_server', 'snowflake_user')
            
        Returns:
            str: The secret value
            
        Raises:
            KeyError: If the key doesn't exist
        """
        if key not in self.secrets:
            raise KeyError(f"Secret key '{key}' not found. Available keys: {list(self.secrets.keys())}")
        return self.secrets[key]