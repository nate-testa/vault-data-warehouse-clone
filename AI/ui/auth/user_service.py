"""
User service for profile management and Azure group extraction.

This module provides user operations, Azure group extraction logic,
and user profile management functions for the authentication system.
"""

import os
import re
from typing import Dict, List, Optional, Any, Set, Tuple
from flask import current_app
from datetime import datetime

from .models import User, Session
from .session_manager import session_manager
from utils.logging import logger


class UserService:
    """
    Service class for user profile management and operations.
    
    This class provides utilities for managing user profiles, extracting
    Azure AD groups, and performing user-related operations.
    """
    
    # Common Azure AD SAML attribute mappings
    AZURE_ATTRIBUTE_MAPPINGS = {
        'given_name': [
            'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname',
            'givenName',
            'firstName',
            'first_name'
        ],
        'surname': [
            'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname',
            'surname',
            'lastName',
            'last_name'
        ],
        'display_name': [
            'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name',
            'displayName',
            'name',
            'fullName'
        ],
        'email': [
            'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress',
            'email',
            'emailAddress',
            'mail'
        ],
        'groups': [
            'http://schemas.microsoft.com/ws/2008/06/identity/claims/groups',
            'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/groups',
            'groups',
            'roles',
            'memberOf'
        ],
        'upn': [
            'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn',
            'userPrincipalName',
            'upn'
        ],
        'object_id': [
            'http://schemas.microsoft.com/identity/claims/objectidentifier',
            'objectId',
            'oid'
        ],
        'tenant_id': [
            'http://schemas.microsoft.com/identity/claims/tenantid',
            'tenantId',
            'tid'
        ]
    }
    
    def __init__(self, app=None):
        """
        Initialize the user service.
        
        Args:
            app: Flask application instance
        """
        self.app = app
        if app is not None:
            self.init_app(app)
    
    def init_app(self, app):
        """
        Initialize the user service with Flask app.
        
        Args:
            app: Flask application instance
        """
        self.app = app
        
        # Set default configurations
        app.config.setdefault('USER_GROUP_CACHE_TIMEOUT', 3600)  # 1 hour
        app.config.setdefault('USER_PROFILE_CACHE_TIMEOUT', 1800)  # 30 minutes
        app.config.setdefault('ALLOWED_GROUPS', [])  # Empty means all groups allowed
        app.config.setdefault('ADMIN_GROUPS', ['admin', 'administrators'])
        app.config.setdefault('DEFAULT_USER_ROLE', 'user')
    
    def create_user_from_saml(self, name_id: str, attributes: Dict[str, List[str]]) -> User:
        """
        Create a User object from SAML attributes with enhanced Azure AD support.
        
        Args:
            name_id (str): SAML NameID (typically email)
            attributes (Dict[str, List[str]]): SAML attributes dictionary
            
        Returns:
            User: User object populated with SAML data
        """
        # Extract user information using attribute mappings
        user_data = self._extract_user_attributes(name_id, attributes)
        
        # Extract and process groups
        groups = self._extract_and_process_groups(attributes)
        
        # Create user object
        user = User(
            user_id=user_data['user_id'],
            username=user_data['username'],
            email=user_data['email'],
            display_name=user_data['display_name'],
            first_name=user_data['first_name'],
            last_name=user_data['last_name'],
            groups=groups,
            attributes=attributes,
            is_authenticated=True,
            last_login=datetime.utcnow()
        )
        
        # Log user creation for audit
        logger.info(f"User created from SAML: {user.username} with groups: {groups}")
        
        return user
    
    def get_current_user(self) -> Optional[User]:
        """
        Get the current authenticated user.
        
        Returns:
            Optional[User]: Current user if authenticated, None otherwise
        """
        return session_manager.get_current_user()
    
    def update_user_profile(self, user: User, **updates) -> User:
        """
        Update user profile with new information.
        
        Args:
            user (User): User object to update
            **updates: Key-value pairs of attributes to update
            
        Returns:
            User: Updated user object
        """
        # Define allowed update fields
        allowed_fields = {
            'display_name', 'first_name', 'last_name', 'email'
        }
        
        # Apply updates
        for field, value in updates.items():
            if field in allowed_fields and hasattr(user, field):
                setattr(user, field, value)
        
        # Re-run post-init to update derived fields
        user.__post_init__()
        
        # Update session if this is the current user
        current_user = self.get_current_user()
        if current_user and current_user.user_id == user.user_id:
            from flask import session
            session[session_manager.USER_KEY] = user.to_dict()
        
        logger.info(f"User profile updated: {user.username}")
        
        return user
    
    def get_user_groups(self, user: User) -> List[str]:
        """
        Get all groups for a user.
        
        Args:
            user (User): User object
            
        Returns:
            List[str]: List of group names
        """
        return user.groups.copy()
    
    def get_user_roles(self, user: User) -> List[str]:
        """
        Get user roles based on group membership.
        
        Args:
            user (User): User object
            
        Returns:
            List[str]: List of role names
        """
        roles = []
        
        # Check for admin role
        admin_groups = current_app.config.get('ADMIN_GROUPS', [])
        if user.has_any_group(admin_groups):
            roles.append('admin')
        
        # Add default role
        default_role = current_app.config.get('DEFAULT_USER_ROLE', 'user')
        if default_role not in roles:
            roles.append(default_role)
        
        # Add group-based roles (groups can also be roles)
        roles.extend(user.groups)
        
        return list(set(roles))  # Remove duplicates
    
    def is_user_authorized(self, user: User, required_groups: Optional[List[str]] = None) -> bool:
        """
        Check if user is authorized based on group membership.
        
        Args:
            user (User): User object
            required_groups (Optional[List[str]]): Required groups for authorization
            
        Returns:
            bool: True if authorized, False otherwise
        """
        # If no specific groups required, check general authorization
        if not required_groups:
            allowed_groups = current_app.config.get('ALLOWED_GROUPS', [])
            if not allowed_groups:  # Empty list means all authenticated users allowed
                return user.is_authenticated
            return user.has_any_group(allowed_groups)
        
        # Check specific group requirements
        return user.has_any_group(required_groups)
    
    def is_user_admin(self, user: User) -> bool:
        """
        Check if user has admin privileges.
        
        Args:
            user (User): User object
            
        Returns:
            bool: True if user is admin, False otherwise
        """
        admin_groups = current_app.config.get('ADMIN_GROUPS', [])
        return user.has_any_group(admin_groups)
    
    def get_user_permissions(self, user: User) -> Dict[str, bool]:
        """
        Get user permissions based on roles and groups.
        
        Args:
            user (User): User object
            
        Returns:
            Dict[str, bool]: Dictionary of permission names and their status
        """
        permissions = {
            'can_read': user.is_authenticated,
            'can_write': user.is_authenticated,
            'can_delete': False,
            'can_admin': self.is_user_admin(user),
            'can_upload_files': user.is_authenticated,
            'can_download_files': user.is_authenticated,
            'can_view_logs': self.is_user_admin(user),
            'can_manage_users': self.is_user_admin(user)
        }
        
        # Enhanced permissions for admin users
        if permissions['can_admin']:
            permissions.update({
                'can_delete': True,
                'can_view_all_data': True,
                'can_configure_system': True
            })
        
        return permissions
    
    def search_users_by_group(self, group_name: str) -> List[str]:
        """
        Search for users by group membership.
        
        Note: This is a placeholder for when user persistence is implemented.
        Currently returns empty list as users are session-based.
        
        Args:
            group_name (str): Group name to search for
            
        Returns:
            List[str]: List of user IDs in the group
        """
        # This would be implemented with persistent user storage
        logger.info(f"Group search requested for: {group_name}")
        return []
    
    def get_group_statistics(self) -> Dict[str, int]:
        """
        Get statistics about group membership.
        
        Note: This is a placeholder for when user persistence is implemented.
        
        Returns:
            Dict[str, int]: Dictionary of group names and member counts
        """
        # This would be implemented with persistent user storage
        return {}
    
    def validate_user_session(self, user: User) -> bool:
        """
        Validate if user session is still valid.
        
        Args:
            user (User): User object to validate
            
        Returns:
            bool: True if session is valid, False otherwise
        """
        if not user.is_authenticated:
            return False
        
        # Check if session exists and is valid
        current_session = session_manager.get_current_session()
        if not current_session:
            return False
        
        # Check if user ID matches
        if current_session.user_id != user.user_id:
            return False
        
        return current_session.is_valid()
    
    def refresh_user_from_session(self) -> Optional[User]:
        """
        Refresh user data from current session.
        
        Returns:
            Optional[User]: Refreshed user object or None if not authenticated
        """
        return session_manager.get_current_user()
    
    def _extract_user_attributes(self, name_id: str, attributes: Dict[str, List[str]]) -> Dict[str, str]:
        """
        Extract user attributes from SAML response.
        
        Args:
            name_id (str): SAML NameID
            attributes (Dict[str, List[str]]): SAML attributes
            
        Returns:
            Dict[str, str]: Extracted user attributes
        """
        # Start with name_id as default values
        user_data = {
            'user_id': name_id,
            'username': name_id,
            'email': name_id if '@' in name_id else '',
            'display_name': '',
            'first_name': None,
            'last_name': None
        }
        
        # Extract first name
        first_name = self._get_attribute_value(attributes, self.AZURE_ATTRIBUTE_MAPPINGS['given_name'])
        if first_name:
            user_data['first_name'] = first_name
        
        # Extract last name
        last_name = self._get_attribute_value(attributes, self.AZURE_ATTRIBUTE_MAPPINGS['surname'])
        if last_name:
            user_data['last_name'] = last_name
        
        # Extract display name
        display_name = self._get_attribute_value(attributes, self.AZURE_ATTRIBUTE_MAPPINGS['display_name'])
        if display_name:
            user_data['display_name'] = display_name
        elif first_name or last_name:
            # Construct display name from first/last name
            parts = [name for name in [first_name, last_name] if name]
            user_data['display_name'] = ' '.join(parts)
        else:
            user_data['display_name'] = name_id
        
        # Extract email
        email = self._get_attribute_value(attributes, self.AZURE_ATTRIBUTE_MAPPINGS['email'])
        if email:
            user_data['email'] = email
        
        # Extract UPN as alternative username
        upn = self._get_attribute_value(attributes, self.AZURE_ATTRIBUTE_MAPPINGS['upn'])
        if upn:
            user_data['username'] = upn
        
        return user_data
    
    def _extract_and_process_groups(self, attributes: Dict[str, List[str]]) -> List[str]:
        """
        Extract and process groups from SAML attributes.
        
        Args:
            attributes (Dict[str, List[str]]): SAML attributes
            
        Returns:
            List[str]: Processed list of group names
        """
        groups = []
        
        # Extract groups using different attribute names
        for attr_name in self.AZURE_ATTRIBUTE_MAPPINGS['groups']:
            if attr_name in attributes and attributes[attr_name]:
                groups.extend(attributes[attr_name])
        
        # Process groups
        processed_groups = []
        for group in groups:
            processed_group = self._process_group_name(group)
            if processed_group:
                processed_groups.append(processed_group)
        
        # Remove duplicates and sort
        return sorted(list(set(processed_groups)))
    
    def _process_group_name(self, group: str) -> Optional[str]:
        """
        Process and normalize a group name.
        
        Args:
            group (str): Raw group name from SAML
            
        Returns:
            Optional[str]: Processed group name or None if invalid
        """
        if not group:
            return None
        
        # Handle Azure AD Object IDs (GUIDs)
        if self._is_azure_object_id(group):
            # In production, you might want to resolve these to friendly names
            logger.debug(f"Azure AD Object ID found: {group}")
            return group
        
        # Handle DN format (e.g., "CN=GroupName,OU=Groups,DC=domain,DC=com")
        if group.startswith('CN='):
            cn_match = re.match(r'CN=([^,]+)', group)
            if cn_match:
                return cn_match.group(1).lower().replace(' ', '_')
        
        # Handle email-like groups
        if '@' in group:
            return group.lower()
        
        # Clean and normalize regular group names
        clean_group = re.sub(r'[^\w\-_.]', '_', group.lower())
        clean_group = re.sub(r'_+', '_', clean_group).strip('_')
        
        return clean_group if clean_group else None
    
    def _is_azure_object_id(self, value: str) -> bool:
        """
        Check if a value is an Azure AD Object ID (GUID).
        
        Args:
            value (str): Value to check
            
        Returns:
            bool: True if it's a GUID format, False otherwise
        """
        guid_pattern = r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
        return bool(re.match(guid_pattern, value.lower()))
    
    def _get_attribute_value(self, attributes: Dict[str, List[str]], 
                           attribute_names: List[str]) -> Optional[str]:
        """
        Get the first available attribute value from a list of possible attribute names.
        
        Args:
            attributes (Dict[str, List[str]]): SAML attributes
            attribute_names (List[str]): List of possible attribute names
            
        Returns:
            Optional[str]: First found attribute value or None
        """
        for attr_name in attribute_names:
            if attr_name in attributes and attributes[attr_name]:
                return attributes[attr_name][0]
        return None


class UserProfileManager:
    """
    Manager class for user profile operations and caching.
    
    This class provides utilities for managing user profiles with
    caching and optimization features.
    """
    
    def __init__(self, user_service: UserService):
        """
        Initialize the profile manager.
        
        Args:
            user_service (UserService): User service instance
        """
        self.user_service = user_service
        self._profile_cache = {}
        self._group_cache = {}
    
    def get_user_profile(self, user: User, use_cache: bool = True) -> Dict[str, Any]:
        """
        Get comprehensive user profile information.
        
        Args:
            user (User): User object
            use_cache (bool): Whether to use cached data
            
        Returns:
            Dict[str, Any]: User profile information
        """
        cache_key = f"profile_{user.user_id}"
        
        if use_cache and cache_key in self._profile_cache:
            cached_profile, cached_time = self._profile_cache[cache_key]
            cache_timeout = current_app.config.get('USER_PROFILE_CACHE_TIMEOUT', 1800)
            
            if (datetime.utcnow() - cached_time).seconds < cache_timeout:
                return cached_profile
        
        # Build profile
        profile = {
            'user_id': user.user_id,
            'username': user.username,
            'email': user.email,
            'display_name': user.display_name,
            'first_name': user.first_name,
            'last_name': user.last_name,
            'groups': self.user_service.get_user_groups(user),
            'roles': self.user_service.get_user_roles(user),
            'permissions': self.user_service.get_user_permissions(user),
            'is_admin': self.user_service.is_user_admin(user),
            'last_login': user.last_login.isoformat() if user.last_login else None,
            'session_id': user.session_id,
            'is_authenticated': user.is_authenticated
        }
        
        # Cache the profile
        if use_cache:
            self._profile_cache[cache_key] = (profile, datetime.utcnow())
        
        return profile
    
    def clear_user_cache(self, user_id: str):
        """
        Clear cached data for a specific user.
        
        Args:
            user_id (str): User ID to clear cache for
        """
        cache_keys = [f"profile_{user_id}", f"groups_{user_id}"]
        for key in cache_keys:
            self._profile_cache.pop(key, None)
            self._group_cache.pop(key, None)
    
    def clear_all_cache(self):
        """Clear all cached user data."""
        self._profile_cache.clear()
        self._group_cache.clear()


# Create global instances for easy import
user_service = UserService()
user_profile_manager = UserProfileManager(user_service)
