"""
Azure Key Vault Configuration Manager for Aircall to EDW Project

This module manages configuration from either static config.yml or Azure Key Vault.
Secret names are defined in config.yml under the 'secrets' section, allowing
reuse of existing shared secrets across environments.
"""

import os
import logging
import logging.handlers
import sys
import yaml
from azure.identity import ManagedIdentityCredential
from azure.keyvault.secrets import SecretClient
from azure.core.exceptions import AzureError
from dotenv import load_dotenv

load_dotenv()

# Project root (directory containing this file)
_PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))


def _load_logging_config():
    """Load logging section from config.yml (defaults if missing)."""
    config_path = os.path.join(_PROJECT_ROOT, 'config.yml')
    try:
        with open(config_path, 'r') as f:
            cfg = yaml.safe_load(f) or {}
    except Exception:
        cfg = {}
    log_cfg = cfg.get('logging', {})
    return {
        'log_dir': log_cfg.get('log_dir', 'log'),
        'log_level': log_cfg.get('log_level', 'INFO'),
        'max_bytes': log_cfg.get('max_bytes', 10485760),
        'backup_count': log_cfg.get('backup_count', 10),
        'write_summary_json': log_cfg.get('write_summary_json', True),
    }


def setup_logger(name="AircallToEDW"):
    """
    Create a logger that writes to both console and a rotating log file
    under the configured log directory.

    All modules share the same root logger so every message ends up in
    one log file per run (aircall_to_edw.log with rotation).
    """
    logger = logging.getLogger(name)
    if logger.handlers:
        return logger

    log_cfg = _load_logging_config()
    log_level = getattr(logging, log_cfg['log_level'].upper(), logging.INFO)
    logger.setLevel(log_level)

    formatter = logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )

    # --- Console handlers (unchanged behaviour) ---
    class InfoFilter(logging.Filter):
        def filter(self, record):
            return record.levelno < logging.WARNING

    stdout_handler = logging.StreamHandler(sys.stdout)
    stdout_handler.setLevel(logging.INFO)
    stdout_handler.setFormatter(formatter)
    stdout_handler.addFilter(InfoFilter())

    stderr_handler = logging.StreamHandler(sys.stderr)
    stderr_handler.setLevel(logging.WARNING)
    stderr_handler.setFormatter(formatter)

    logger.addHandler(stdout_handler)
    logger.addHandler(stderr_handler)

    # --- File handler (rotating) ---
    log_dir = os.path.join(_PROJECT_ROOT, log_cfg['log_dir'])
    os.makedirs(log_dir, exist_ok=True)
    log_file = os.path.join(log_dir, 'aircall_to_edw.log')

    file_handler = logging.handlers.RotatingFileHandler(
        log_file,
        maxBytes=log_cfg['max_bytes'],
        backupCount=log_cfg['backup_count'],
        encoding='utf-8',
    )
    file_handler.setLevel(log_level)
    file_handler.setFormatter(formatter)
    logger.addHandler(file_handler)

    return logger


class ConfigManager:
    """
    Manages configuration and secrets from config.yml or Azure Key Vault.
    Secret names are read from config.yml so they can be changed per environment
    without modifying code.
    """

    KEY_VAULT_URI = os.getenv('KEY_VAULT_URI', 'key-vault-uri-not-set')

    def __init__(self, logger=None):
        self.logger = logger or setup_logger()
        self.secrets = {}
        self.config = {}
        self._load_config()
        self._load_secrets()

    def _load_config(self):
        config_path = os.path.join(os.path.dirname(__file__), 'config.yml')
        try:
            with open(config_path, 'r') as f:
                self.config = yaml.safe_load(f) or {}
            self.logger.info(f"Configuration loaded from {config_path}")
        except FileNotFoundError:
            self.logger.error(f"Config file not found: {config_path}")
            raise
        except yaml.YAMLError as e:
            self.logger.error(f"Error parsing config.yml: {e}")
            raise

    def _load_secrets(self):
        use_static = self.config.get('use_static_config', False)
        if use_static:
            self.logger.warning("Using STATIC configuration from config.yml")
            self._load_static_config()
        else:
            self.logger.info("Using Azure Key Vault for secrets")
            self._load_from_keyvault()

    def _load_static_config(self):
        static = self.config.get('static_config', {})
        if not static:
            raise ValueError("static_config section not found in config.yml")

        self.secrets['aircall_api_id'] = static.get('aircall_api_id')
        self.secrets['aircall_api_token'] = static.get('aircall_api_token')
        self.secrets['edw_sql_server'] = static.get('sql_server')
        self.secrets['edw_sql_database'] = static.get('sql_database')
        self.secrets['edw_sql_username'] = static.get('sql_username')
        self.secrets['edw_sql_password'] = static.get('sql_password')

        required = ['aircall_api_id', 'aircall_api_token',
                     'edw_sql_server', 'edw_sql_database',
                     'edw_sql_username', 'edw_sql_password']
        missing = [k for k in required if not self.secrets.get(k)]
        if missing:
            raise ValueError(f"Missing required static configuration values: {missing}")

        self.logger.info(f"Loaded {len(self.secrets)} values from static config")

    def _load_from_keyvault(self):
        secret_names_map = self.config.get('secrets', {})
        if not secret_names_map:
            raise ValueError("'secrets' section not found in config.yml")

        try:
            self.logger.info("Connecting to Azure Key Vault using ManagedIdentityCredential...")
            credential = ManagedIdentityCredential()
            client = SecretClient(vault_url=self.KEY_VAULT_URI, credential=credential)
            self.logger.info(f"Connected to Key Vault: {self.KEY_VAULT_URI}")

            for key, vault_secret_name in secret_names_map.items():
                try:
                    self.logger.info(f"Fetching secret: {vault_secret_name}")
                    secret = client.get_secret(vault_secret_name)
                    self.secrets[key] = secret.value
                    self.logger.info(f"Successfully retrieved secret for: {key}")
                except Exception as e:
                    self.logger.error(f"Failed to retrieve secret '{vault_secret_name}' for key '{key}': {e}")
                    raise

            self.logger.info(f"Loaded {len(self.secrets)} secrets from Key Vault")

        except AzureError as e:
            self.logger.error(f"Azure Key Vault error: {e}")
            raise

    # ---- Accessor methods ----

    def get_aircall_credentials(self):
        return {
            'api_id': self.secrets['aircall_api_id'],
            'api_token': self.secrets['aircall_api_token']
        }

    def get_sql_config(self):
        return {
            'server': self.secrets['edw_sql_server'],
            'database': self.secrets['edw_sql_database'],
            'username': self.secrets['edw_sql_username'],
            'password': self.secrets['edw_sql_password']
        }

    def get_aircall_api_config(self):
        return self.config.get('aircall_api', {})

    def get_database_config(self):
        return self.config.get('database', {})

    def get_logging_config(self):
        return self.config.get('logging', {})
