"""
UI Configuration Management
Centralized configuration for different environments (DEV, UAT, PRODUCTION).

Environment is controlled by the ENVIRONMENT variable:
- export ENVIRONMENT=DEV          # Local development
- export ENVIRONMENT=UAT          # UAT environment
- export ENVIRONMENT=PRODUCTION   # Production environment

All sensitive credentials (secrets, certificates, keys) are loaded from Azure Key Vault.
This file contains only non-sensitive configuration like URLs, feature flags, and SAML endpoints.
"""
import os


# Determine current environment
ENVIRONMENT = os.getenv('ENVIRONMENT')

# Environment-specific configurations
CONFIGS = {
    'DEV': {
        # API Connection
        'API_BASE_URL': 'http://127.0.0.1:8080',
        
        # SSO Configuration
        'ENABLE_SSO': False,
        
        # SAML Service Provider (SP) - Development
        'SAML_SP_ENTITY_ID': 'https://localhost:5001/',
        'SAML_SP_ACS_URL': 'https://localhost:5001/saml/acs',
        'SAML_SP_SLO_URL': 'https://localhost:5001/saml/sls',
        
        # SAML Identity Provider (IdP) - Development (Azure AD)
        'SAML_IDP_ENTITY_ID': 'https://sts.windows.net/348d7f3f-9dec-4a47-a2a1-d314cc2e5774/',
        'SAML_IDP_SSO_URL': 'https://login.microsoftonline.com/348d7f3f-9dec-4a47-a2a1-d314cc2e5774/saml2',
        'SAML_IDP_SLO_URL': 'https://login.microsoftonline.com/348d7f3f-9dec-4a47-a2a1-d314cc2e5774/saml2',
        
        # Application Settings
        'APP_HOST': 'localhost',
        'APP_HOME_URL': 'https://localhost:5001/',
        'FORCE_HTTPS': False,
        'FLASK_DEBUG': True,
        
        # Azure Key Vault Configuration
        'AZURE_KEYVAULT_URL': 'https://azrdevdatakeyvltai01.vault.azure.net/',
        
        # Application Roles - Azure AD Group Object IDs (Development)
        'APP_ROLES': {
            'DocuClaims AI': {
                'required_groups': [
                    'DEV-GROUP-ID-DOCUCLAIMS-1',
                    'DEV-GROUP-ID-DOCUCLAIMS-2'
                ]
            },
            'Insights AI': {
                'required_groups': [
                    'DEV-GROUP-ID-INSIGHTS-1',
                    'DEV-GROUP-ID-INSIGHTS-2'
                ]
            }
        },
    },
    
    'UAT': {
        # API Connection
        'API_BASE_URL': 'http://127.0.0.1:8080',
        
        # SSO Configuration
        'ENABLE_SSO': True,
        
        # SAML Service Provider (SP) - UAT
        'SAML_SP_ENTITY_ID': 'https://ai.uat.vaultinsurance.com/',
        'SAML_SP_ACS_URL': 'https://ai.uat.vaultinsurance.com/saml/acs',
        'SAML_SP_SLO_URL': 'https://ai.uat.vaultinsurance.com/saml/sls',
        
        # SAML Identity Provider (IdP) - UAT (Azure AD)
        'SAML_IDP_ENTITY_ID': 'https://sts.windows.net/348d7f3f-9dec-4a47-a2a1-d314cc2e5774/',
        'SAML_IDP_SSO_URL': 'https://login.microsoftonline.com/348d7f3f-9dec-4a47-a2a1-d314cc2e5774/saml2',
        'SAML_IDP_SLO_URL': 'https://login.microsoftonline.com/348d7f3f-9dec-4a47-a2a1-d314cc2e5774/saml2',
        
        # Application Settings
        'APP_HOST': 'ai.uat.vaultinsurance.com',
        'APP_HOME_URL': 'https://ai.uat.vaultinsurance.com/',
        'FORCE_HTTPS': True,
        'FLASK_DEBUG': False,
        
        # Azure Key Vault Configuration
        'AZURE_KEYVAULT_URL': 'https://azruatdatakeyvltai01.vault.azure.net/',
        
        # Application Roles - Azure AD Group Object IDs (UAT)
        'APP_ROLES': {
            'DocuClaims AI': {
                'required_groups': [
                    '0480ae6c-4661-4cac-8b67-ea6d4522ff9e',
                    '77408e82-c692-41f9-b244-5bf3d6decd7d'
                ]
            },
            'Insights AI': {
                'required_groups': [
                    '16f2e5b0-6efe-4a71-a940-be5171f8f712',
                    '77408e82-c692-41f9-b244-5bf3d6decd7d'
                ]
            }
        },
    },
    
    'PRODUCTION': {
        # API Connection
        'API_BASE_URL': 'http://127.0.0.1:8080',
        
        # SSO Configuration
        'ENABLE_SSO': True,
        
        # SAML Service Provider (SP) - Production
        'SAML_SP_ENTITY_ID': 'https://ai.vaultinsurance.com/',
        'SAML_SP_ACS_URL': 'https://ai.vaultinsurance.com/saml/acs',
        'SAML_SP_SLO_URL': 'https://ai.vaultinsurance.com/saml/sls',
        
        # SAML Identity Provider (IdP) - Production (Azure AD)
        'SAML_IDP_ENTITY_ID': 'https://sts.windows.net/348d7f3f-9dec-4a47-a2a1-d314cc2e5774/',
        'SAML_IDP_SSO_URL': 'https://login.microsoftonline.com/348d7f3f-9dec-4a47-a2a1-d314cc2e5774/saml2',
        'SAML_IDP_SLO_URL': 'https://login.microsoftonline.com/348d7f3f-9dec-4a47-a2a1-d314cc2e5774/saml2',
        
        # Application Settings
        'APP_HOST': 'ai.vaultinsurance.com',
        'APP_HOME_URL': 'https://ai.vaultinsurance.com/',
        'FORCE_HTTPS': True,
        'FLASK_DEBUG': False,
        
        # Azure Key Vault Configuration
        'AZURE_KEYVAULT_URL': 'https://azrproddatakeyvltai01.vault.azure.net/',
        
        # Application Roles - Azure AD Group Object IDs (Production)
        'APP_ROLES': {
            'DocuClaims AI': {
                'required_groups': [
                    'c40e783c-97f3-47d5-9e8e-dd007f1ba704',
                    '3a6916c7-cb26-4845-8b1d-0d32314c55d1'
                ]
            },
            'Insights AI': {
                'required_groups': [
                    '21733501-e1d4-4774-9574-82d551f471c3',
                    '3a6916c7-cb26-4845-8b1d-0d32314c55d1'
                ]
            }
        },
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
        >>> enable_sso = get_config('ENABLE_SSO')
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
