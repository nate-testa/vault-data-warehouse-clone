import os
import logging
import yaml
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
from azure.core.exceptions import AzureError
from dotenv import load_dotenv

load_dotenv()

class ConfigManager:
    KEY_VAULT_URI = os.getenv('KEY_VAULT_URI')

    def __init__(self, logger=None):
        self.logger = logger or logging.getLogger("ConfigManager")
        self.secrets = {}
        self.config = {}
        self._load_config()
        self._load_secrets()

    def _load_config(self):
        """Load configuration from config.yml with environment variable overrides"""
        config_path = os.path.join(os.path.dirname(__file__), 'config.yml')
        
        try:
            with open(config_path, 'r') as f:
                self.config = yaml.safe_load(f) or {}
            
            # Apply environment variable overrides
            if 'memory' not in self.config:
                self.config['memory'] = {}
            
            # Override chunk_size if environment variable set
            if os.getenv('CHUNK_SIZE'):
                try:
                    self.config['memory']['chunk_size'] = int(os.getenv('CHUNK_SIZE'))
                    if self.logger:
                        self.logger.info(f"Chunk size overridden by env var: {self.config['memory']['chunk_size']}")
                except ValueError:
                    if self.logger:
                        self.logger.warning(f"Invalid CHUNK_SIZE env var: {os.getenv('CHUNK_SIZE')}")
            
            # Override processing_mode if environment variable set
            if os.getenv('PROCESSING_MODE'):
                self.config['memory']['processing_mode'] = os.getenv('PROCESSING_MODE')
                if self.logger:
                    self.logger.info(f"Processing mode overridden by env var: {self.config['memory']['processing_mode']}")
            
            if self.logger:
                self.logger.info(f"Configuration loaded from {config_path}")
                
        except FileNotFoundError:
            if self.logger:
                self.logger.warning(f"Config file not found: {config_path}, using defaults")
        except yaml.YAMLError as e:
            if self.logger:
                self.logger.error(f"Error parsing config.yml: {e}")
            raise

    def _load_secrets(self):
        """Load secrets from either Azure Key Vault or static configuration"""
        secrets_config = self.config.get('secrets', {})
        secrets_source = secrets_config.get('source', 'keyvault')
        
        if secrets_source == 'static':
            self._load_static_secrets()
        elif secrets_source == 'keyvault':
            self._load_keyvault_secrets()
        else:
            raise ValueError(f"Invalid secrets source: {secrets_source}. Must be 'static' or 'keyvault'")
    
    def _load_static_secrets(self):
        """Load secrets from static configuration values"""
        try:
            self.logger.info("Loading secrets from static configuration")
            static_values = self.config.get('secrets', {}).get('static_values', {})
            
            required_keys = ['tenant_id', 'sp_id', 'sp_secret', 'db_server', 'db_name', 'db_user', 'db_password']
            
            for key in required_keys:
                if key not in static_values:
                    self.logger.warning(f"Missing static secret: {key}")
                    self.secrets[key] = ""
                else:
                    self.secrets[key] = static_values[key]
            
            self.logger.info("Successfully loaded static secrets")
            
        except Exception as e:
            self.logger.error(f"Error loading static secrets: {e}")
            raise
    
    def _load_keyvault_secrets(self):
        """Load secrets from Azure Key Vault"""
        try:
            self.logger.info(f"Connecting to Key Vault: {self.KEY_VAULT_URI}")
            credential = DefaultAzureCredential()
            client = SecretClient(vault_url=self.KEY_VAULT_URI, credential=credential)

            # Secrets to fetch
            secret_map = {
                'tenant_id': 'sharepoint-datamigration-tenant-id',            # Azure AD Tenant ID
                'sp_id': 'sharepoint-client-id',           # SharePoint App Client ID
                'sp_secret': 'sharepoint-client-secret',   # SharePoint App Secret
                'db_server': 'sharepoint-datamigration-sql-server',   # SQL Server hostname
                'db_name': 'sharepoint-datamigration-sql-database',   # SQL Database name
                'db_user': 'sharepoint-datamigration-sql-username',   # SQL Server username
                'db_password': 'sharepoint-datamigration-sql-password' # SQL Server password
            }

            for key, name in secret_map.items():
                self.secrets[key] = client.get_secret(name).value
            
            self.logger.info("Successfully loaded secrets from Key Vault")

        except AzureError as e:
            self.logger.error(f"Key Vault Error: {e}")
            raise

    def get(self, key):
        return self.secrets.get(key)