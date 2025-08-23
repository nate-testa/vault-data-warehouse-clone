"""
Session management utilities for authentication.

This module provides secure session storage, retrieval, and validation
utilities for managing user authentication sessions with Flask.
"""

import os
import secrets
from datetime import datetime, timedelta
from typing import Dict, Optional, Any, Union
from flask import session, request, current_app
from werkzeug.security import generate_password_hash, check_password_hash

from .models import User, Session
from utils.logging import logger


class SessionManager:
    """
    Session manager for handling user authentication sessions.
    
    This class provides utilities for creating, storing, retrieving, and
    validating user sessions with proper security measures.
    """
    
    # Session keys
    USER_KEY = 'auth_user'
    SESSION_KEY = 'auth_session'
    CSRF_KEY = 'csrf_token'
    SAML_NAMEID_KEY = 'saml_nameid'
    SAML_SESSION_INDEX_KEY = 'saml_session_index'
    
    def __init__(self, app=None):
        """
        Initialize the session manager.
        
        Args:
            app: Flask application instance
        """
        self.app = app
        if app is not None:
            self.init_app(app)
    
    def init_app(self, app):
        """
        Initialize the session manager with Flask app.
        
        Args:
            app: Flask application instance
        """
        self.app = app
        
        # Set default session configuration
        app.config.setdefault('SESSION_TIMEOUT_HOURS', 24)
        app.config.setdefault('SESSION_EXTEND_ON_ACCESS', True)
        app.config.setdefault('CSRF_PROTECTION', True)
    
    def create_session(self, user: User, duration_hours: Optional[int] = None,
                      saml_session_index: Optional[str] = None,
                      saml_nameid: Optional[str] = None) -> Session:
        """
        Create a new user session.
        
        Args:
            user (User): User object
            duration_hours (Optional[int]): Session duration in hours
            saml_session_index (Optional[str]): SAML session index
            saml_nameid (Optional[str]): SAML NameID
            
        Returns:
            Session: Created session object
        """
        if duration_hours is None:
            duration_hours = current_app.config.get('SESSION_TIMEOUT_HOURS', 24)
        
        # Generate secure session ID
        session_id = self._generate_session_id()
        
        # Get client information
        ip_address = self._get_client_ip()
        user_agent = request.headers.get('User-Agent', '')
        
        # Generate CSRF token
        csrf_token = self._generate_csrf_token() if current_app.config.get('CSRF_PROTECTION') else None
        
        # Create session object
        auth_session = Session.create_new(
            session_id=session_id,
            user_id=user.user_id,
            duration_hours=duration_hours or 24,
            saml_session_index=saml_session_index,
            saml_name_id=saml_nameid,
            ip_address=ip_address,
            user_agent=user_agent,
            csrf_token=csrf_token
        )
        
        # Update user with session info
        user.session_id = session_id
        user.is_authenticated = True
        user.last_login = datetime.utcnow()
        
        # Store in Flask session
        self._store_session_data(user, auth_session)
        
        return auth_session
    
    def get_current_user(self) -> Optional[User]:
        """
        Get the current authenticated user from session.
        
        Returns:
            Optional[User]: Current user if authenticated, None otherwise
        """
        try:
            user_data = session.get(self.USER_KEY)
            if not user_data:
                return None
            
            user = User.from_dict(user_data)
            
            # Validate session
            if not self._is_session_valid(user):
                self.clear_session()
                return None
            
            # Extend session if configured
            if current_app.config.get('SESSION_EXTEND_ON_ACCESS', True):
                self._extend_session()
            
            return user
            
        except Exception as e:
            logger.error(f"Error getting current user: {str(e)}")
            self.clear_session()
            return None
    
    def get_current_session(self) -> Optional[Session]:
        """
        Get the current session object.
        
        Returns:
            Optional[Session]: Current session if valid, None otherwise
        """
        try:
            session_data = session.get(self.SESSION_KEY)
            if not session_data:
                return None
            
            auth_session = Session.from_dict(session_data)
            
            # Validate session
            if not auth_session.is_valid():
                self.clear_session()
                return None
            
            return auth_session
            
        except Exception as e:
            logger.error(f"Error getting current session: {str(e)}")
            self.clear_session()
            return None
    
    def is_authenticated(self) -> bool:
        """
        Check if the current user is authenticated.
        
        Returns:
            bool: True if authenticated, False otherwise
        """
        user = self.get_current_user()
        return user is not None and user.is_authenticated
    
    def clear_session(self):
        """Clear all authentication-related session data."""
        keys_to_remove = [
            self.USER_KEY,
            self.SESSION_KEY,
            self.CSRF_KEY,
            self.SAML_NAMEID_KEY,
            self.SAML_SESSION_INDEX_KEY
        ]
        
        for key in keys_to_remove:
            session.pop(key, None)
    
    def invalidate_session(self):
        """Invalidate the current session."""
        auth_session = self.get_current_session()
        if auth_session:
            auth_session.invalidate()
            session[self.SESSION_KEY] = auth_session.to_dict()
        
        self.clear_session()
    
    def get_csrf_token(self) -> Optional[str]:
        """
        Get the current CSRF token.
        
        Returns:
            Optional[str]: CSRF token if available
        """
        return session.get(self.CSRF_KEY)
    
    def validate_csrf_token(self, token: str) -> bool:
        """
        Validate a CSRF token.
        
        Args:
            token (str): Token to validate
            
        Returns:
            bool: True if valid, False otherwise
        """
        if not current_app.config.get('CSRF_PROTECTION'):
            return True
        
        stored_token = self.get_csrf_token()
        if not stored_token or not token:
            return False
        
        return secrets.compare_digest(stored_token, token)
    
    def get_saml_data(self) -> Dict[str, Optional[str]]:
        """
        Get SAML-related session data.
        
        Returns:
            Dict[str, Optional[str]]: SAML session data
        """
        return {
            'nameid': session.get(self.SAML_NAMEID_KEY),
            'session_index': session.get(self.SAML_SESSION_INDEX_KEY)
        }
    
    def set_session_data(self, key: str, value: Any):
        """
        Set custom data in the current session.
        
        Args:
            key (str): Data key
            value (Any): Data value
        """
        auth_session = self.get_current_session()
        if auth_session:
            auth_session.set_data(key, value)
            session[self.SESSION_KEY] = auth_session.to_dict()
    
    def get_session_data(self, key: str, default: Any = None) -> Any:
        """
        Get custom data from the current session.
        
        Args:
            key (str): Data key
            default (Any): Default value if key not found
            
        Returns:
            Any: Data value or default
        """
        auth_session = self.get_current_session()
        if auth_session:
            return auth_session.get_data(key, default)
        return default
    
    def preserve_flask_session_data(self) -> Dict[str, Any]:
        """
        Preserve non-authentication Flask session data.
        
        Returns:
            Dict[str, Any]: Preserved session data
        """
        preserved_keys = [
            'rag_messages', 'file_uploaded', 'uploaded_filename',
            'debug', 'use_chat_history', 'selected_model', 'rag_warnings'
        ]
        
        preserved_data = {}
        for key in preserved_keys:
            if key in session:
                preserved_data[key] = session[key]
        
        return preserved_data
    
    def restore_flask_session_data(self, preserved_data: Dict[str, Any]):
        """
        Restore non-authentication Flask session data.
        
        Args:
            preserved_data (Dict[str, Any]): Data to restore
        """
        for key, value in preserved_data.items():
            session[key] = value
    
    def cleanup_expired_sessions(self):
        """
        Clean up expired sessions.
        
        Note: This is a placeholder for session cleanup.
        In a production environment, you might want to store sessions
        in a database or cache and clean them up periodically.
        """
        # This would be implemented if using persistent session storage
        pass
    
    def _store_session_data(self, user: User, auth_session: Session):
        """
        Store user and session data in Flask session.
        
        Args:
            user (User): User object
            auth_session (Session): Session object
        """
        session[self.USER_KEY] = user.to_dict()
        session[self.SESSION_KEY] = auth_session.to_dict()
        
        if auth_session.csrf_token:
            session[self.CSRF_KEY] = auth_session.csrf_token
        
        if auth_session.saml_name_id:
            session[self.SAML_NAMEID_KEY] = auth_session.saml_name_id
        
        if auth_session.saml_session_index:
            session[self.SAML_SESSION_INDEX_KEY] = auth_session.saml_session_index
        
        # Make session permanent
        session.permanent = True
    
    def _is_session_valid(self, user: User) -> bool:
        """
        Validate if the session is still valid.
        
        Args:
            user (User): User object
            
        Returns:
            bool: True if valid, False otherwise
        """
        if not user.is_authenticated:
            return False
        
        auth_session = self.get_current_session()
        if not auth_session:
            return False
        
        return auth_session.is_valid()
    
    def _extend_session(self):
        """Extend the current session expiration."""
        auth_session = self.get_current_session()
        if auth_session:
            duration_hours = current_app.config.get('SESSION_TIMEOUT_HOURS', 24)
            auth_session.extend_expiration(duration_hours)
            session[self.SESSION_KEY] = auth_session.to_dict()
    
    def _generate_session_id(self) -> str:
        """
        Generate a secure session ID.
        
        Returns:
            str: Secure session ID
        """
        return secrets.token_urlsafe(32)
    
    def _generate_csrf_token(self) -> str:
        """
        Generate a CSRF token.
        
        Returns:
            str: CSRF token
        """
        return secrets.token_urlsafe(32)
    
    def _get_client_ip(self) -> str:
        """
        Get the client IP address.
        
        Returns:
            str: Client IP address
        """
        # Check for forwarded IP (proxy/load balancer)
        forwarded_ips = request.headers.getlist("X-Forwarded-For")
        if forwarded_ips:
            return forwarded_ips[0].split(',')[0].strip()
        
        # Check for real IP
        real_ip = request.headers.get("X-Real-IP")
        if real_ip:
            return real_ip
        
        # Fall back to remote address
        return request.environ.get('REMOTE_ADDR', 'unknown')


# Create a global instance for easy import
session_manager = SessionManager()


class LegacySessionHelper:
    """
    Helper class to maintain compatibility with existing session usage.
    
    This class provides methods to bridge between the new authentication
    session system and the existing Flask session usage in the application.
    """
    
    @staticmethod
    def migrate_sso_session_to_user(user_attributes: Dict[str, Any], 
                                   saml_session_index: Optional[str] = None,
                                   saml_nameid: Optional[str] = None) -> User:
        """
        Migrate from legacy SSO session format to User model.
        
        Args:
            user_attributes (Dict[str, Any]): SAML user attributes
            saml_session_index (Optional[str]): SAML session index
            saml_nameid (Optional[str]): SAML NameID
            
        Returns:
            User: User object created from legacy session data
        """
        # Convert from legacy format to User model
        user = User.from_saml_attributes(saml_nameid or '', user_attributes)
        
        # Create session using session manager
        session_manager.create_session(
            user=user,
            saml_session_index=saml_session_index,
            saml_nameid=saml_nameid
        )
        
        return user
    
    @staticmethod
    def is_legacy_sso_session_active() -> bool:
        """
        Check if there's an active legacy SSO session.
        
        Returns:
            bool: True if legacy session exists
        """
        return 'user' in session and session['user']
    
    @staticmethod
    def migrate_legacy_session():
        """
        Migrate existing legacy session to new format.
        
        This method should be called during the transition period to
        convert existing sessions to the new format.
        """
        if LegacySessionHelper.is_legacy_sso_session_active():
            # Preserve non-auth session data
            preserved_data = session_manager.preserve_flask_session_data()
            
            # Get legacy session data
            user_attributes = session.get('user', {})
            saml_session_index = session.get('saml_session_index')
            saml_nameid = session.get('saml_nameid')
            
            # Clear old session
            session.clear()
            
            # Create new session
            if saml_nameid and user_attributes:
                user = LegacySessionHelper.migrate_sso_session_to_user(
                    user_attributes, saml_session_index, saml_nameid
                )
            
            # Restore non-auth data
            session_manager.restore_flask_session_data(preserved_data)
