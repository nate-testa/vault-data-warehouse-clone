"""
API Configuration Management
Centralized configuration for different environments (DEV, UAT, PRODUCTION).

Environment is controlled by the ENVIRONMENT variable:
- export ENVIRONMENT=DEV          # Local development
- export ENVIRONMENT=UAT          # UAT environment
- export ENVIRONMENT=PRODUCTION   # Production environment

All sensitive credentials (Snowflake account, user, tokens, etc.) are loaded from Azure Key Vault.
This file contains only non-sensitive configuration like API URLs and feature flags.
"""
import os


# Determine current environment
ENVIRONMENT = os.getenv('ENVIRONMENT')

# Environment-specific configurations
CONFIGS = {
    'DEV': {
        # API Configuration
        'API_BASE_URL': 'http://127.0.0.1:8080',
        
        # CORS Settings
        'CORS_ORIGINS': 'http://localhost:5001,http://127.0.0.1:5001',
        
        # Debug Mode
        'DEBUG': True,
        
        # Snowflake Configuration
        'SNOWFLAKE_DATABASE': 'VAULT_AI_DEV',
        
        # Azure Key Vault Configuration
        'AZURE_KEYVAULT_URL': 'https://azrdevdatakeyvltai01.vault.azure.net/',
    },
    
    'UAT': {
        # API Configuration
        'API_BASE_URL': 'http://127.0.0.1:8080',
        
        # CORS Settings
        'CORS_ORIGINS': 'https://ai.uat.vaultinsurance.com',
        
        # Debug Mode
        'DEBUG': False,
        
        # Snowflake Configuration
        'SNOWFLAKE_DATABASE': 'VAULT_AI_UAT',
        
        # Azure Key Vault Configuration
        'AZURE_KEYVAULT_URL': 'https://azruatdatakeyvltai01.vault.azure.net/',
    },
    
    'PRODUCTION': {
        # API Configuration
        'API_BASE_URL': 'http://127.0.0.1:8080',
        
        # CORS Settings
        'CORS_ORIGINS': 'https://ai.vaultinsurance.com',
        
        # Debug Mode
        'DEBUG': False,
        
        # Snowflake Configuration
        'SNOWFLAKE_DATABASE': 'VAULT_AI',
        
        # Azure Key Vault Configuration
        'AZURE_KEYVAULT_URL': 'https://azrproddatakeyvltai01.vault.azure.net/',
    },
}


def get_config(key: str, default=None):
    """
    Get configuration value for the current environment.
    
    Args:
        key: Configuration key to retrieve
        default: Default value if key not found (optional)
    
    Returns:
        Configuration value for current environment
    
    Raises:
        KeyError: If environment is invalid or key not found (when no default provided)
    
    Example:
        >>> from config import get_config
        >>> api_url = get_config('API_BASE_URL')
        >>> cors_origins = get_config('CORS_ORIGINS')
    """
    if ENVIRONMENT not in CONFIGS:
        raise ValueError(f"Invalid ENVIRONMENT: {ENVIRONMENT}. Valid options: {list(CONFIGS.keys())}")
    
    env_config = CONFIGS[ENVIRONMENT]
    
    if key not in env_config and default is None:
        raise KeyError(f"Configuration key '{key}' not found for environment '{ENVIRONMENT}'")
    
    return env_config.get(key, default)


def get_all_config():
    """
    Get all configuration for the current environment.
    
    Returns:
        dict: Complete configuration dictionary for current environment
    """
    if ENVIRONMENT not in CONFIGS:
        raise ValueError(f"Invalid ENVIRONMENT: {ENVIRONMENT}. Valid options: {list(CONFIGS.keys())}")
    
    return CONFIGS[ENVIRONMENT].copy()
