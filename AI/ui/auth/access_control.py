"""
Role-based access control service for application access management.

This module provides access control functionality to manage user permissions
for different applications based on Azure AD group memberships.
"""

from typing import Dict, List, Optional, Any, Set
from flask import current_app
from utils.logging import logger
from config import get_config


class AccessControlService:
    """
    Service class for role-based access control functionality.
    
    This class provides methods to load application role configurations,
    check user permissions, and filter applications based on user groups.
    """
    
    def __init__(self):
        """
        Initialize the access control service.
        
        Loads application roles from config.py based on the current environment.
        """
        self.app_roles_config: Dict[str, Any] = {}
        self._load_app_roles()
        
        logger.info("[ACCESS_CONTROL] Service initialized from config.py")
    
    def _load_app_roles(self) -> None:
        """
        Load application roles configuration from config.py.
        
        This method loads the APP_ROLES configuration from config.py based on
        the current environment (DEV, UAT, PRODUCTION).
        """
        try:
            # Get APP_ROLES from environment-specific configuration
            self.app_roles_config = get_config('APP_ROLES', default={})
            
            logger.info(f"[ACCESS_CONTROL] Loaded configuration for {len(self.app_roles_config)} applications")
            
            # Log loaded applications for debugging
            for app_name in self.app_roles_config.keys():
                group_count = len(self.app_roles_config[app_name].get('required_groups', []))
                logger.debug(f"[ACCESS_CONTROL] App '{app_name}' requires {group_count} groups")
                
        except Exception as e:
            logger.error(f"[ACCESS_CONTROL] Error loading configuration from config.py: {e}")
            logger.info("[ACCESS_CONTROL] Using empty configuration due to error")
            self.app_roles_config = {}
    
    def user_has_access(self, app_name: str, user_groups: List[str]) -> bool:
        """
        Check if a user has access to a specific application.
        
        Args:
            app_name (str): Name of the application to check access for.
            user_groups (List[str]): List of Azure AD groups the user belongs to.
            
        Returns:
            bool: True if user has access, False otherwise.
        """
        try:
            # Validate input parameters
            if not app_name:
                logger.warning("[ACCESS_CONTROL] Empty application name provided")
                return False
            
            if not isinstance(user_groups, list):
                logger.warning("[ACCESS_CONTROL] Invalid user_groups parameter - must be a list")
                return False
            
            # If app is not in configuration, allow access to all authenticated users
            if app_name not in self.app_roles_config:
                logger.debug(f"[ACCESS_CONTROL] App '{app_name}' not in config - allowing access")
                return True
            
            # Get required groups for the application
            app_config = self.app_roles_config[app_name]
            required_groups = app_config.get('required_groups', [])
            
            # If required_groups is empty, DENY access (app is disabled)
            if not required_groups:
                logger.info(f"[ACCESS_CONTROL] App '{app_name}' has empty required_groups - access DENIED (app disabled)")
                return False
            
            # Convert user groups to set for faster lookup
            user_groups_set = set(user_groups)
            required_groups_set = set(required_groups)
            
            # Check if user has any of the required groups
            has_access = bool(user_groups_set.intersection(required_groups_set))
            
            # Log access decision for auditing
            if has_access:
                matching_groups = user_groups_set.intersection(required_groups_set)
                logger.info(f"[ACCESS_CONTROL] User granted access to '{app_name}' via groups: {list(matching_groups)}")
            else:
                logger.info(f"[ACCESS_CONTROL] User denied access to '{app_name}' - no matching groups")
                logger.debug(f"[ACCESS_CONTROL] User groups: {user_groups}")
                logger.debug(f"[ACCESS_CONTROL] Required groups: {required_groups}")
            
            return has_access
            
        except Exception as e:
            logger.error(f"[ACCESS_CONTROL] Error checking access for '{app_name}': {e}")
            # On error, deny access for security
            return False
    
    def filter_applications(self, all_apps: List[Dict[str, Any]], user_groups: List[str]) -> List[Dict[str, Any]]:
        """
        Filter applications list based on user's group memberships.
        
        Args:
            all_apps (List[Dict[str, Any]]): List of all available applications.
            user_groups (List[str]): List of Azure AD groups the user belongs to.
            
        Returns:
            List[Dict[str, Any]]: Filtered list of applications the user can access.
        """
        try:
            # Validate input parameters
            if not isinstance(all_apps, list):
                logger.warning("[ACCESS_CONTROL] Invalid all_apps parameter - must be a list")
                return []
            
            if not isinstance(user_groups, list):
                logger.warning("[ACCESS_CONTROL] Invalid user_groups parameter - must be a list")
                return []
            
            filtered_apps = []
            
            for app in all_apps:
                # Handle different app dictionary structures
                app_name = None
                
                # Try different possible keys for app name
                if isinstance(app, dict):
                    app_name = app.get('name') or app.get('title') or app.get('app_name')
                elif isinstance(app, str):
                    app_name = app
                
                if not app_name:
                    logger.warning(f"[ACCESS_CONTROL] Could not determine app name from: {app}")
                    continue
                
                # Check if user has access to this application
                if self.user_has_access(app_name, user_groups):
                    filtered_apps.append(app)
            
            logger.info(f"[ACCESS_CONTROL] Filtered {len(all_apps)} apps to {len(filtered_apps)} accessible apps")
            
            return filtered_apps
            
        except Exception as e:
            logger.error(f"[ACCESS_CONTROL] Error filtering applications: {e}")
            # On error, return empty list for security
            return []
    
    def get_app_configuration(self, app_name: str) -> Optional[Dict[str, Any]]:
        """
        Get the configuration for a specific application.
        
        Args:
            app_name (str): Name of the application.
            
        Returns:
            Optional[Dict[str, Any]]: Application configuration or None if not found.
        """
        try:
            return self.app_roles_config.get(app_name)
        except Exception as e:
            logger.error(f"[ACCESS_CONTROL] Error getting app configuration for '{app_name}': {e}")
            return None
    
    def get_all_configured_apps(self) -> List[str]:
        """
        Get list of all applications with role-based access control configured.
        
        Returns:
            List[str]: List of application names with access control configured.
        """
        try:
            return list(self.app_roles_config.keys())
        except Exception as e:
            logger.error(f"[ACCESS_CONTROL] Error getting configured apps: {e}")
            return []
    
    def validate_configuration(self) -> Dict[str, Any]:
        """
        Validate the current configuration and return validation results.
        
        Returns:
            Dict[str, Any]: Validation results including errors and warnings.
        """
        validation_results = {
            'valid': True,
            'errors': [],
            'warnings': [],
            'app_count': 0,
            'total_groups': 0
        }
        
        try:
            if not self.app_roles_config:
                validation_results['warnings'].append('No applications configured for access control')
                return validation_results
            
            validation_results['app_count'] = len(self.app_roles_config)
            all_groups = set()
            
            for app_name, app_config in self.app_roles_config.items():
                # Validate app name
                if not isinstance(app_name, str) or not app_name.strip():
                    validation_results['errors'].append(f'Invalid app name: {app_name}')
                    validation_results['valid'] = False
                    continue
                
                # Validate app configuration structure
                if not isinstance(app_config, dict):
                    validation_results['errors'].append(f'Invalid config for app {app_name}: must be an object')
                    validation_results['valid'] = False
                    continue
                
                # Check required_groups field
                required_groups = app_config.get('required_groups', [])
                if not isinstance(required_groups, list):
                    validation_results['errors'].append(f'Invalid required_groups for app {app_name}: must be an array')
                    validation_results['valid'] = False
                    continue
                
                # Validate group IDs
                for group_id in required_groups:
                    if not isinstance(group_id, str) or not group_id.strip():
                        validation_results['errors'].append(f'Invalid group ID in app {app_name}: {group_id}')
                        validation_results['valid'] = False
                    else:
                        all_groups.add(group_id)
                
                # Check for empty required_groups
                if not required_groups:
                    validation_results['warnings'].append(f'App {app_name} has no required groups - accessible to all users')
            
            validation_results['total_groups'] = len(all_groups)
            
        except Exception as e:
            validation_results['valid'] = False
            validation_results['errors'].append(f'Unexpected validation error: {e}')
            logger.error(f"[ACCESS_CONTROL] Configuration validation error: {e}")
        
        return validation_results


# Global instance for easy access
access_control_service = AccessControlService()
