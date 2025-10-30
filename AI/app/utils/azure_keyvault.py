"""
Azure Key Vault integration for Snowflake AI API Backend.

This module provides secure access to secrets stored in Azure Key Vault using
Managed Identity authentication. Secrets are loaded once at startup and cached
in memory for performance.

Design Pattern: Load-once at startup with in-memory caching
Authentication: Azure Managed Identity (DefaultAzureCredential)
NO FALLBACK: If a secret is not in Key Vault, the application WILL FAIL

IMPORTANT: This module does NOT use .env files as fallback. All secrets MUST
be in Azure Key Vault. This ensures production security and prevents accidentally
using local development credentials in production.
"""

from typing import Optional, Dict
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
from azure.core.exceptions import ResourceNotFoundError
from app.utils.logging import logger
from app.config import get_config


class KeyVaultConfig:
    """
    Centralized Key Vault configuration manager for API backend.
    
    Features:
    - Singleton pattern: Only one instance per application
    - Load secrets ONCE at startup
    - Cache in memory (never write to disk)
    - Uses Managed Identity (no credentials in code)
    - NO .env fallback - secrets MUST be in Key Vault
    
    Example:
        >>> from app.utils.azure_keyvault import keyvault
        >>> db_token = keyvault.get_secret('vaultai-snowflake-pat-token')
    """
    
    _instance: Optional['KeyVaultConfig'] = None
    _secrets_cache: Dict[str, str] = {}
    _vault_url: Optional[str] = None
    _client: Optional[SecretClient] = None
    _initialized = False
    
    def __new__(cls) -> 'KeyVaultConfig':
        """Singleton pattern: ensure only one instance exists."""
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance
    
    def __init__(self):
        """
        Initialize Key Vault client with Managed Identity.
        
        Raises:
            RuntimeError: If Key Vault connection cannot be established
        """
        if self._initialized:
            return
        
        # Get Key Vault URL from config
        self._vault_url = get_config('AZURE_KEYVAULT_URL')
        
        try:
            credential = DefaultAzureCredential()
            self._client = SecretClient(
                vault_url=self._vault_url,
                credential=credential
            )
            # Test connection by listing properties (doesn't retrieve actual secrets)
            self._client.list_properties_of_secrets(max_page_size=1)
            logger.info(f"✅ API: Connected to Azure Key Vault: {self._vault_url}")
        except Exception as e:
            error_msg = (
                f"❌ API: CRITICAL - Cannot connect to Azure Key Vault. "
                f"Application cannot start without Key Vault access. Error: {str(e)}"
            )
            logger.error(error_msg)
            raise RuntimeError(error_msg) from e
        
        self._initialized = True
    
    def get_secret(self, secret_name: str) -> str:
        """
        Get secret from Key Vault (cached).
        
        NO FALLBACK: If the secret is not in Key Vault, this method raises an exception.
        This ensures that production deployments never accidentally use local credentials.
        
        Load order:
        1. Check in-memory cache
        2. Retrieve from Azure Key Vault
        3. FAIL if not found (no .env fallback)
        
        Args:
            secret_name: Name in Key Vault (e.g., 'vaultai-snowflake-pat-token')
        
        Returns:
            Secret value as string
        
        Raises:
            RuntimeError: If secret is not found in Key Vault
        
        Example:
            >>> token = keyvault.get_secret('vaultai-snowflake-pat-token')
        """
        # Check cache first (fastest)
        if secret_name in self._secrets_cache:
            logger.debug(f"API: Using cached secret '{secret_name}'")
            return self._secrets_cache[secret_name]
        
        # Retrieve from Key Vault (REQUIRED - no fallback)
        try:
            secret = self._client.get_secret(secret_name)
            if not secret.value:
                raise RuntimeError(f"Secret '{secret_name}' is empty in Key Vault")
            
            self._secrets_cache[secret_name] = secret.value
            logger.info(f"✅ API: Loaded secret '{secret_name}' from Key Vault")
            return secret.value
            
        except ResourceNotFoundError:
            error_msg = (
                f"❌ API: CRITICAL - Secret '{secret_name}' not found in Key Vault. "
                f"Please ensure the secret exists in {self._vault_url}"
            )
            logger.error(error_msg)
            raise RuntimeError(error_msg)
        except Exception as e:
            error_msg = (
                f"❌ API: Failed to retrieve secret '{secret_name}' from Key Vault: {str(e)}"
            )
            logger.error(error_msg)
            raise RuntimeError(error_msg) from e
    
    def clear_cache(self):
        """Clear the secrets cache. Useful for testing."""
        self._secrets_cache.clear()
        logger.info("API: Secrets cache cleared")


# Singleton instance - import and use this
keyvault = KeyVaultConfig()
