"""
Azure Key Vault Configuration Manager for Broker Goal Project

This module manages configuration from either static config.yml or Azure Key Vault.
All secrets are prefixed with 'brokergoal-' in the Key Vault.
"""

import os
import logging
import yaml
from azure.identity import ManagedIdentityCredential
from azure.keyvault.secrets import SecretClient
from azure.core.exceptions import AzureError
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

class ConfigManager:
    """
    Manages configuration and secrets from config.yml or Azure Key Vault.
    Supports both static configuration and Managed Identity authentication.
    """
    
    KEY_VAULT_URI = os.getenv('KEY_VAULT_URI', 'key-vault-uri-not-set')
    
    # Secret names in Key Vault (all prefixed with 'brokergoal-')
    SECRET_NAMES = {
        # SQL Server (Target Database)
        'sql_server': 'brokergoal-sql-server',
        'sql_database': 'brokergoal-sql-database',
        'sql_username': 'brokergoal-sql-username',
        'sql_password': 'brokergoal-sql-password',
        # Blob Storage (optional)
        'storage_account': 'brokergoal-storage-account',
    }
    
    def __init__(self, logger=None):
        self.logger = logger or self._setup_logger()
        self.secrets = {}
        self.config = {}
        self._load_config()
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
    
    def _load_config(self):
        """Load configuration from config.yml"""
        config_path = os.path.join(os.path.dirname(__file__), 'config.yml')
        
        try:
            with open(config_path, 'r') as f:
                self.config = yaml.safe_load(f) or {}
            
            self.logger.info(f"Configuration loaded from {config_path}")
            
            # Log configuration mode
            use_static = self.config.get('use_static_config', False)
            if use_static:
                self.logger.warning("⚠️  Using STATIC configuration from config.yml")
            else:
                self.logger.info("Using Azure Key Vault for secrets")
                
        except FileNotFoundError:
            self.logger.warning(f"Config file not found: {config_path}, using defaults")
            self.config = {'use_static_config': False}
        except yaml.YAMLError as e:
            self.logger.error(f"Error parsing config.yml: {e}")
            raise
    
    def _load_secrets(self):
        """Load secrets from Key Vault or static config based on use_static_config"""
        use_static = self.config.get('use_static_config', False)
        
        if use_static:
            self._load_static_config()
        else:
            self._load_from_keyvault()
    
    def _load_static_config(self):
        """Load configuration from static_config section in config.yml"""
        try:
            self.logger.info("Loading static configuration from config.yml...")
            
            static_config = self.config.get('static_config', {})
            
            if not static_config:
                raise ValueError("static_config section not found in config.yml")
            
            # Load all configuration values
            self.secrets['sql_server'] = static_config.get('sql_server')
            self.secrets['sql_database'] = static_config.get('sql_database')
            self.secrets['sql_username'] = static_config.get('sql_username')
            self.secrets['sql_password'] = static_config.get('sql_password')
            self.secrets['storage_account'] = static_config.get('storage_account')
            
            # Validate that all required values are present
            required_fields = ['sql_server', 'sql_database', 'sql_username', 'sql_password', 'storage_account']
            missing = [k for k in required_fields if not self.secrets.get(k)]
            if missing:
                raise ValueError(f"Missing required static configuration values: {missing}")
            
            self.logger.info(f"Successfully loaded {len(self.secrets)} configuration values from static config")
            
        except Exception as e:
            self.logger.error(f"Error loading static configuration: {e}")
            raise
    
    def _load_from_keyvault(self):
        """Load secrets from Azure Key Vault using Managed Identity"""
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
    
    def get_sql_config(self):
        """Returns SQL Server connection config."""
        return {
            'server': self.secrets['sql_server'],
            'database': self.secrets['sql_database'],
            'username': self.secrets['sql_username'],
            'password': self.secrets['sql_password']
        }
    
    def get_storage_account(self):
        """
        Returns the storage account name from Key Vault or static config.
        """
        storage_account = self.secrets.get('storage_account')
        
        if not storage_account:
            self.logger.error("storage_account not configured in Key Vault or static_config")
            raise ValueError("storage_account must be configured in Key Vault (brokergoal-storage-account) or static_config section")
        
        return storage_account
    
    def get_blob_container(self):
        """Returns the blob container name from config.yml."""
        blob_config = self.config.get('blob_storage', {})
        return blob_config.get('container', 'inbound-broker-goal')
    
    def get_blob_folder(self):
        """Returns the blob folder path from config.yml."""
        blob_config = self.config.get('blob_storage', {})
        return blob_config.get('folder', 'files')
    
    def get_target_schema(self):
        """Returns the target database schema."""
        target_db = self.config.get('target_database', {})
        return target_db.get('schema', 'edw_stage')
    
    def get_target_table(self):
        """Returns the target database table name."""
        target_db = self.config.get('target_database', {})
        return target_db.get('table', 'stage_broker_goal')
    
    def get_load_mode(self):
        """Returns the load mode: 'truncate' or 'append'."""
        target_db = self.config.get('target_database', {})
        return target_db.get('load_mode', 'truncate')
    
    def get_year_config(self):
        """Returns year configuration (auto_year flag and override value)."""
        load_options = self.config.get('load_options', {})
        return {
            'auto_year': load_options.get('auto_year', True),
            'year_override': load_options.get('year_override', 2026)
        }
    
    def should_skip_invalid_rows(self):
        """Returns whether to skip rows with invalid data."""
        load_options = self.config.get('load_options', {})
        return load_options.get('skip_invalid_rows', True)
    
    def should_validate_data(self):
        """Returns whether to validate data before loading."""
        load_options = self.config.get('load_options', {})
        return load_options.get('validate_data', True)
    
    def get_archive_config(self):
        """Returns archive configuration (enabled flag, folder, and timestamp option)."""
        archive = self.config.get('archive', {})
        return {
            'enabled': archive.get('enabled', False),
            'folder': archive.get('folder', 'archived'),
            'add_timestamp': archive.get('add_timestamp', True)
        }
