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
        self.environment = None
        self.env_config = {}
        self._load_config()
        self._resolve_environment()
        self._load_secrets()

    def _load_config(self):
        """Load configuration from config.yml"""
        config_path = os.path.join(os.path.dirname(__file__), 'config.yml')

        try:
            with open(config_path, 'r') as f:
                self.config = yaml.safe_load(f) or {}

            self.logger.info(f"Configuration loaded from {config_path}")

        except FileNotFoundError:
            self.logger.warning(f"Config file not found: {config_path}, using defaults")
        except yaml.YAMLError as e:
            self.logger.error(f"Error parsing config.yml: {e}")
            raise

    def _resolve_environment(self):
        """Resolve active environment and merge env-specific URLs into api config."""
        # Env var override > config.yml
        self.environment = os.getenv('ENVIRONMENT',
                                     self.config.get('active_environment', 'uat'))

        environments = self.config.get('environments', {})
        self.env_config = environments.get(self.environment, {})

        if not self.env_config:
            raise ValueError(f"Environment '{self.environment}' not found in config.yml. "
                             f"Available: {list(environments.keys())}")

        # Merge env-specific URLs into api section (env var overrides still win)
        if 'api' not in self.config:
            self.config['api'] = {}

        self.config['api']['pss_url'] = os.getenv('PSS_URL', self.env_config.get('pss_url', ''))
        self.config['api']['dms_url'] = os.getenv('DMS_URL', self.env_config.get('dms_url', ''))

        # Resolve Key Vault URI for this environment (env var > env config > .env fallback)
        self.keyvault_uri = os.getenv('KEY_VAULT_URI', self.env_config.get('keyvault_uri', ''))

        self.logger.info(f"Active environment: {self.environment.upper()}")
        self.logger.info(f"  PSS URL: {self.config['api']['pss_url']}")
        self.logger.info(f"  DMS URL: {self.config['api']['dms_url']}")
        self.logger.info(f"  Key Vault: {self.keyvault_uri or '(not configured)'}")

    def _load_secrets(self):
        """Load secrets based on the active environment's secrets_source."""
        secrets_source = self.env_config.get('secrets_source', 'keyvault')

        if secrets_source == 'static':
            self._load_static_secrets()
        elif secrets_source == 'keyvault':
            self._load_keyvault_secrets()
        else:
            raise ValueError(f"Invalid secrets source: {secrets_source}. Must be 'static' or 'keyvault'")

    def _load_static_secrets(self):
        """Load secrets from static configuration values (environment-specific)."""
        try:
            self.logger.info("Loading secrets from static configuration")
            static_values = self.env_config.get('static_values', {})

            required_keys = ['client_id', 'client_secret']
            optional_keys = ['blob_container', 'blob_storage_account']

            for key in required_keys:
                if key not in static_values or not static_values[key]:
                    self.logger.warning(f"Missing static secret: {key}")
                    self.secrets[key] = ""
                else:
                    self.secrets[key] = static_values[key]

            for key in optional_keys:
                self.secrets[key] = static_values.get(key, '') or ''

            self.logger.info("Successfully loaded static secrets")

        except Exception as e:
            self.logger.error(f"Error loading static secrets: {e}")
            raise

    def _load_keyvault_secrets(self):
        """Load secrets from Azure Key Vault (same secret names, different vault per env)."""
        try:
            if not self.keyvault_uri:
                raise ValueError("Key Vault URI not configured for this environment")

            self.logger.info(f"Connecting to Key Vault: {self.keyvault_uri}")
            credential = DefaultAzureCredential()
            client = SecretClient(vault_url=self.keyvault_uri, credential=credential)

            # Secret names are shared across environments (defined in secrets.keyvault_map)
            keyvault_map = self.config.get('secrets', {}).get('keyvault_map', {})
            secret_map = {
                'client_id': keyvault_map.get('client_id', 'os-document-extract-client-id'),
                'client_secret': keyvault_map.get('client_secret', 'os-document-extract-client-secret'),
                'blob_container': keyvault_map.get('blob_container', 'oneshield-documents-container'),
                'blob_storage_account': keyvault_map.get('blob_storage_account', 'oneshield-documents-storage-account'),
            }

            for key, name in secret_map.items():
                try:
                    self.secrets[key] = client.get_secret(name).value
                except Exception as e:
                    # blob secrets are optional (only needed if upload enabled)
                    if key.startswith('blob_'):
                        self.logger.warning(f"Optional secret '{name}' not found in Key Vault: {e}")
                        self.secrets[key] = ''
                    else:
                        raise

            self.logger.info("Successfully loaded secrets from Key Vault")

        except AzureError as e:
            self.logger.error(f"Key Vault Error: {e}")
            raise

    def get(self, key):
        """Get a secret value by key"""
        return self.secrets.get(key)