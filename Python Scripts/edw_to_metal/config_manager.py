"""
Azure Key Vault Configuration Manager

This module manages all secret retrieval from Azure Key Vault using Managed Identity.
All secrets are prefixed with 'edwtometal-' in the Key Vault.
"""

import os
import logging
from azure.identity import ManagedIdentityCredential
from azure.keyvault.secrets import SecretClient
from azure.core.exceptions import AzureError
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

class ConfigManager:
    """
    Manages configuration and secrets retrieval from Azure Key Vault.
    Uses Managed Identity for authentication.
    """
    
    KEY_VAULT_URI = os.getenv('KEY_VAULT_URI', 'key-vault-uri-not-set')
    
    # Secret names in Key Vault (all prefixed with 'edwtometal-')
    SECRET_NAMES = {
        # Host 1 (Source)
        'host1_sql_server': 'edwtometal-host-sql-server',
        'host1_sql_database': 'edwtometal-host-sql-database',
        'host1_sql_username': 'edwtometal-host-sql-username',
        'host1_sql_password': 'edwtometal-host-sql-password',
        
        # Host 2 (Target)
        'host2_sql_server': 'edwtometal-target-sql-server',
        'host2_sql_database': 'edwtometal-target-sql-database',
        'host2_sql_username': 'edwtometal-target-sql-username',
        'host2_sql_password': 'edwtometal-target-sql-password',
    }
    
    def __init__(self, logger=None):
        self.logger = logger or self._setup_logger()
        self.secrets = {}
        self._load_secrets()
    
    def _setup_logger(self):
        logger = logging.getLogger("ConfigManager")
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
    
    def _load_secrets(self):
        try:
            self.logger.info("Connecting to Azure Key Vault using Managed Identity...")
            credential = ManagedIdentityCredential()
            client = SecretClient(vault_url=self.KEY_VAULT_URI, credential=credential)
            self.logger.info(f"Successfully connected to Key Vault: {self.KEY_VAULT_URI}")
            
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
    
    def get_sql_host1_config(self):
        """Returns Host 1 (Source) SQL Server config."""
        return {
            'server': self.secrets['host1_sql_server'],
            'database': self.secrets['host1_sql_database'],
            'username': self.secrets['host1_sql_username'],
            'password': self.secrets['host1_sql_password']
        }
    
    def get_sql_host2_config(self):
        """Returns Host 2 (Target) SQL Server config."""
        return {
            'server': self.secrets['host2_sql_server'],
            'database': self.secrets['host2_sql_database'],
            'username': self.secrets['host2_sql_username'],
            'password': self.secrets['host2_sql_password']
        }