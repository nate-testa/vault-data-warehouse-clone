"""
Data models for authentication system.

This module provides User and Session data models with type hints
and comprehensive documentation for the authentication system.
"""

from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, field
import json


@dataclass
class User:
    """
    User data model for authentication system.
    
    This class represents a user in the authentication system, containing
    all relevant user information extracted from SSO authentication or
    local session management.
    
    Attributes:
        user_id (str): Unique identifier for the user (typically email from SAML NameID)
        username (str): Username or email address of the user
        display_name (str): Full display name of the user
        first_name (Optional[str]): First name of the user
        last_name (Optional[str]): Last name of the user
        email (str): Email address of the user
        groups (List[str]): List of groups/roles the user belongs to
        attributes (Dict[str, Any]): Additional SAML attributes
        is_authenticated (bool): Whether the user is currently authenticated
        last_login (Optional[datetime]): Timestamp of last login
        session_id (Optional[str]): Associated session identifier
    """
    
    user_id: str
    username: str
    email: str
    display_name: str = ""
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    groups: List[str] = field(default_factory=list)
    attributes: Dict[str, Any] = field(default_factory=dict)
    is_authenticated: bool = False
    last_login: Optional[datetime] = None
    session_id: Optional[str] = None
    
    def __post_init__(self):
        """Post-initialization processing to set derived fields."""
        # If display_name is not provided, construct it from first/last name
        if not self.display_name and (self.first_name or self.last_name):
            parts = [name for name in [self.first_name, self.last_name] if name]
            self.display_name = " ".join(parts)
        
        # If display_name is still empty, use username
        if not self.display_name:
            self.display_name = self.username
        
        # Ensure email is set if not provided
        if not self.email and "@" in self.username:
            self.email = self.username
    
    @classmethod
    def from_saml_attributes(cls, name_id: str, attributes: Dict[str, List[str]]) -> 'User':
        """
        Create a User instance from SAML authentication attributes.
        
        Args:
            name_id (str): SAML NameID (typically email)
            attributes (Dict[str, List[str]]): SAML attributes dictionary
            
        Returns:
            User: User instance populated with SAML data
        """
        # Extract common SAML attributes with fallbacks
        username = name_id
        email = name_id if "@" in name_id else ""
        
        # Try different attribute names for first name
        first_name = None
        for attr in ['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname', 
                    'givenName', 'firstName', 'first_name']:
            if attr in attributes and attributes[attr]:
                first_name = attributes[attr][0]
                break
        
        # Try different attribute names for last name
        last_name = None
        for attr in ['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname',
                    'surname', 'lastName', 'last_name']:
            if attr in attributes and attributes[attr]:
                last_name = attributes[attr][0]
                break
        
        # Try different attribute names for display name
        display_name = ""
        for attr in ['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name',
                    'displayName', 'name', 'fullName']:
            if attr in attributes and attributes[attr]:
                display_name = attributes[attr][0]
                break
        
        # Try different attribute names for email
        if not email:
            for attr in ['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress',
                        'email', 'emailAddress', 'mail']:
                if attr in attributes and attributes[attr]:
                    email = attributes[attr][0]
                    break
        
        # Extract groups/roles
        groups = []
        for attr in ['http://schemas.microsoft.com/ws/2008/06/identity/claims/groups',
                    'groups', 'roles', 'memberOf']:
            if attr in attributes and attributes[attr]:
                groups.extend(attributes[attr])
        
        return cls(
            user_id=username,
            username=username,
            email=email,
            display_name=display_name,
            first_name=first_name,
            last_name=last_name,
            groups=groups,
            attributes=attributes,
            is_authenticated=True,
            last_login=datetime.utcnow()
        )
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'User':
        """
        Create a User instance from a dictionary.
        
        Args:
            data (Dict[str, Any]): User data dictionary
            
        Returns:
            User: User instance populated with dictionary data
        """
        # Handle datetime deserialization
        last_login = None
        if 'last_login' in data and data['last_login']:
            if isinstance(data['last_login'], str):
                last_login = datetime.fromisoformat(data['last_login'].replace('Z', '+00:00'))
            elif isinstance(data['last_login'], datetime):
                last_login = data['last_login']
        
        return cls(
            user_id=data.get('user_id', ''),
            username=data.get('username', ''),
            email=data.get('email', ''),
            display_name=data.get('display_name', ''),
            first_name=data.get('first_name'),
            last_name=data.get('last_name'),
            groups=data.get('groups', []),
            attributes=data.get('attributes', {}),
            is_authenticated=data.get('is_authenticated', False),
            last_login=last_login,
            session_id=data.get('session_id')
        )
    
    def to_dict(self) -> Dict[str, Any]:
        """
        Convert User instance to a dictionary for serialization.
        
        Returns:
            Dict[str, Any]: User data as dictionary
        """
        return {
            'user_id': self.user_id,
            'username': self.username,
            'email': self.email,
            'display_name': self.display_name,
            'first_name': self.first_name,
            'last_name': self.last_name,
            'groups': self.groups,
            'attributes': self.attributes,
            'is_authenticated': self.is_authenticated,
            'last_login': self.last_login.isoformat() if self.last_login else None,
            'session_id': self.session_id
        }
    
    def has_group(self, group_name: str) -> bool:
        """
        Check if user belongs to a specific group.
        
        Args:
            group_name (str): Name of the group to check
            
        Returns:
            bool: True if user belongs to the group, False otherwise
        """
        return group_name in self.groups
    
    @property
    def full_name(self) -> str:
        """
        Get the full name of the user.
        
        Returns:
            str: Full name constructed from first_name and last_name, or display_name if available
        """
        if self.first_name and self.last_name:
            return f"{self.first_name} {self.last_name}"
        elif self.display_name:
            return self.display_name
        else:
            return self.username
    
    def has_any_group(self, group_names: List[str]) -> bool:
        """
        Check if user belongs to any of the specified groups.
        
        Args:
            group_names (List[str]): List of group names to check
            
        Returns:
            bool: True if user belongs to any of the groups, False otherwise
        """
        return any(group in self.groups for group in group_names)
    
    def get_attribute(self, attribute_name: str, default: Any = None) -> Any:
        """
        Get a specific SAML attribute value.
        
        Args:
            attribute_name (str): Name of the attribute
            default (Any): Default value if attribute not found
            
        Returns:
            Any: Attribute value or default
        """
        if attribute_name in self.attributes:
            attr_value = self.attributes[attribute_name]
            # If it's a list, return the first value
            return attr_value[0] if isinstance(attr_value, list) and attr_value else attr_value
        return default


@dataclass
class Session:
    """
    Session data model for authentication system.
    
    This class represents a user session, containing session-specific
    information for authentication and authorization.
    
    Attributes:
        session_id (str): Unique session identifier
        user_id (str): Associated user identifier
        created_at (datetime): Session creation timestamp
        last_accessed (datetime): Last access timestamp
        expires_at (datetime): Session expiration timestamp
        is_active (bool): Whether the session is currently active
        saml_session_index (Optional[str]): SAML session index for SSO
        saml_name_id (Optional[str]): SAML NameID for SSO
        ip_address (Optional[str]): Client IP address
        user_agent (Optional[str]): Client user agent string
        csrf_token (Optional[str]): CSRF protection token
        data (Dict[str, Any]): Additional session data
    """
    
    session_id: str
    user_id: str
    created_at: datetime
    last_accessed: datetime
    expires_at: datetime
    is_active: bool = True
    saml_session_index: Optional[str] = None
    saml_name_id: Optional[str] = None
    ip_address: Optional[str] = None
    user_agent: Optional[str] = None
    csrf_token: Optional[str] = None
    data: Dict[str, Any] = field(default_factory=dict)
    
    @classmethod
    def create_new(cls, session_id: str, user_id: str, 
                   duration_hours: int = 24, **kwargs) -> 'Session':
        """
        Create a new session with default expiration.
        
        Args:
            session_id (str): Unique session identifier
            user_id (str): Associated user identifier
            duration_hours (int): Session duration in hours (default: 24)
            **kwargs: Additional session data
            
        Returns:
            Session: New session instance
        """
        now = datetime.utcnow()
        return cls(
            session_id=session_id,
            user_id=user_id,
            created_at=now,
            last_accessed=now,
            expires_at=now + timedelta(hours=duration_hours),
            **kwargs
        )
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'Session':
        """
        Create a Session instance from a dictionary.
        
        Args:
            data (Dict[str, Any]): Session data dictionary
            
        Returns:
            Session: Session instance populated with dictionary data
        """
        # Handle datetime deserialization
        created_at = datetime.fromisoformat(data['created_at'].replace('Z', '+00:00'))
        last_accessed = datetime.fromisoformat(data['last_accessed'].replace('Z', '+00:00'))
        expires_at = datetime.fromisoformat(data['expires_at'].replace('Z', '+00:00'))
        
        return cls(
            session_id=data['session_id'],
            user_id=data['user_id'],
            created_at=created_at,
            last_accessed=last_accessed,
            expires_at=expires_at,
            is_active=data.get('is_active', True),
            saml_session_index=data.get('saml_session_index'),
            saml_name_id=data.get('saml_name_id'),
            ip_address=data.get('ip_address'),
            user_agent=data.get('user_agent'),
            csrf_token=data.get('csrf_token'),
            data=data.get('data', {})
        )
    
    def to_dict(self) -> Dict[str, Any]:
        """
        Convert Session instance to a dictionary for serialization.
        
        Returns:
            Dict[str, Any]: Session data as dictionary
        """
        return {
            'session_id': self.session_id,
            'user_id': self.user_id,
            'created_at': self.created_at.isoformat(),
            'last_accessed': self.last_accessed.isoformat(),
            'expires_at': self.expires_at.isoformat(),
            'is_active': self.is_active,
            'saml_session_index': self.saml_session_index,
            'saml_name_id': self.saml_name_id,
            'ip_address': self.ip_address,
            'user_agent': self.user_agent,
            'csrf_token': self.csrf_token,
            'data': self.data
        }
    
    def is_expired(self) -> bool:
        """
        Check if the session has expired.
        
        Returns:
            bool: True if session is expired, False otherwise
        """
        return datetime.utcnow() > self.expires_at
    
    def is_valid(self) -> bool:
        """
        Check if the session is valid (active and not expired).
        
        Returns:
            bool: True if session is valid, False otherwise
        """
        return self.is_active and not self.is_expired()
    
    def extend_expiration(self, hours: int = 24) -> None:
        """
        Extend the session expiration time.
        
        Args:
            hours (int): Number of hours to extend (default: 24)
        """
        self.expires_at = datetime.utcnow() + timedelta(hours=hours)
        self.touch()
    
    def touch(self) -> None:
        """Update the last accessed timestamp to current time."""
        self.last_accessed = datetime.utcnow()
    
    def invalidate(self) -> None:
        """Mark the session as inactive."""
        self.is_active = False
    
    def set_data(self, key: str, value: Any) -> None:
        """
        Set a custom data value in the session.
        
        Args:
            key (str): Data key
            value (Any): Data value
        """
        self.data[key] = value
    
    def get_data(self, key: str, default: Any = None) -> Any:
        """
        Get a custom data value from the session.
        
        Args:
            key (str): Data key
            default (Any): Default value if key not found
            
        Returns:
            Any: Data value or default
        """
        return self.data.get(key, default)
    
    def remove_data(self, key: str) -> None:
        """
        Remove a custom data value from the session.
        
        Args:
            key (str): Data key to remove
        """
        self.data.pop(key, None)
