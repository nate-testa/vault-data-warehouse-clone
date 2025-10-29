"""
Azure Key Vault Configuration Module for UI Layer.

This module provides secure access to Azure Key Vault secrets for the UI layer.
It implements a singleton pattern with in-memory caching.

Security Features:
- Uses DefaultAzureCredential (Managed Identity, Environment Variables, CLI)
- Secrets cached in memory (never written to disk)
- NO .env fallback - all secrets MUST be in Azure Key Vault
- No hardcoded credentials

IMPORTANT: This module does NOT use .env files as fallback. All secrets MUST
be in Azure Key Vault. This ensures production security and prevents accidentally
using local development credentials in production.

Usage:
    from ui.utils.azure_keyvault import KeyVaultConfig
    
    keyvault = KeyVaultConfig()
    secret_key = keyvault.get_secret('vaultai-flask-secret-key')
"""

from typing import Optional, Dict
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
from azure.core.exceptions import (
    ResourceNotFoundError,
    ClientAuthenticationError,
    HttpResponseError
)
from utils.logging import logger
from config import get_config


class KeyVaultConfig:
    """
    Singleton configuration class for Azure Key Vault integration in UI layer.
    
    This class manages secure access to Azure Key Vault secrets.
    NO .env fallback - secrets MUST be in Key Vault.
    
    Attributes:
        _instance: Singleton instance of the class
        _secrets_cache: In-memory cache for retrieved secrets
        _vault_url: Azure Key Vault URL
        _client: Azure SecretClient instance
    """
    
    _instance: Optional['KeyVaultConfig'] = None
    _secrets_cache: Dict[str, str] = {}
    _vault_url: Optional[str] = None
    _client: Optional[SecretClient] = None
    _initialized = False
    
    def __new__(cls):
        """Singleton pattern implementation."""
        if cls._instance is None:
            cls._instance = super(KeyVaultConfig, cls).__new__(cls)
            cls._instance._initialize_client()
        return cls._instance
    
    def _initialize_client(self) -> None:
        """
        Initialize Azure Key Vault client with DefaultAzureCredential.
        
        Attempts to authenticate using (in order):
        1. Managed Identity (production)
        2. Environment variables (AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_CLIENT_SECRET)
        3. Azure CLI (local development)
        
        Raises:
            RuntimeError: If Key Vault connection cannot be established
        """
        if self._initialized:
            return
        
        # Get Key Vault URL from config
        self._vault_url = get_config('AZURE_KEYVAULT_URL')
        
        try:
            credential = DefaultAzureCredential()
            self._client = SecretClient(vault_url=self._vault_url, credential=credential)
            # Test connection
            self._client.list_properties_of_secrets(max_page_size=1)
            logger.info("[UI_KEYVAULT] Azure Key Vault client initialized successfully")
        except Exception as e:
            error_msg = (
                f"[UI_KEYVAULT] CRITICAL - Cannot connect to Azure Key Vault. "
                f"Application cannot start without Key Vault access. Error: {str(e)}"
            )
            logger.error(error_msg)
            raise RuntimeError(error_msg) from e
        
        self._initialized = True
    
    def get_secret(self, secret_name: str) -> str:
        """
        Retrieve a secret from Azure Key Vault (cached).
        
        NO FALLBACK: If the secret is not in Key Vault, this method raises an exception.
        This ensures that production deployments never accidentally use local credentials.
        
        Retrieval order:
        1. Check in-memory cache
        2. Retrieve from Azure Key Vault
        3. FAIL if not found (no .env fallback)
        
        Args:
            secret_name: Name of the secret in Azure Key Vault
        
        Returns:
            Secret value as string
        
        Raises:
            RuntimeError: If secret is not found in Key Vault
        
        Example:
            secret_key = keyvault.get_secret('vaultai-flask-secret-key')
        """
        # 1. Check cache first
        if secret_name in self._secrets_cache:
            logger.debug(f"[UI_KEYVAULT] Retrieved '{secret_name}' from cache")
            return self._secrets_cache[secret_name]
        
        # 2. Ensure client is initialized
        if self._client is None:
            error_msg = "[UI_KEYVAULT] CRITICAL - Key Vault client not initialized"
            logger.error(error_msg)
            raise RuntimeError(error_msg)
        
        # 3. Retrieve from Azure Key Vault (REQUIRED - no fallback)
        try:
            secret = self._client.get_secret(secret_name)
            if not secret.value:
                raise RuntimeError(f"Secret '{secret_name}' is empty in Key Vault")
            
            secret_value = secret.value
            self._secrets_cache[secret_name] = secret_value
            logger.info(f"[UI_KEYVAULT] Retrieved '{secret_name}' from Key Vault")
            return secret_value
            
        except ResourceNotFoundError:
            error_msg = (
                f"[UI_KEYVAULT] CRITICAL - Secret '{secret_name}' not found in Key Vault. "
                f"Please ensure the secret exists in {self._vault_url}"
            )
            logger.error(error_msg)
            raise RuntimeError(error_msg)
        except ClientAuthenticationError as e:
            error_msg = f"[UI_KEYVAULT] Authentication error: {str(e)}"
            logger.error(error_msg)
            raise RuntimeError(error_msg) from e
        except HttpResponseError as e:
            error_msg = f"[UI_KEYVAULT] HTTP error retrieving '{secret_name}': {str(e)}"
            logger.error(error_msg)
            raise RuntimeError(error_msg) from e
        except Exception as e:
            error_msg = f"[UI_KEYVAULT] Unexpected error retrieving '{secret_name}': {str(e)}"
            logger.error(error_msg)
            raise RuntimeError(error_msg) from e
    
    def clear_cache(self) -> None:
        """
        Clear the in-memory secrets cache.
        
        This is useful for testing or when secrets need to be refreshed.
        """
        self._secrets_cache.clear()
        logger.info("[UI_KEYVAULT] Secrets cache cleared")


# Singleton instance - import and use this
keyvault = KeyVaultConfig()
