"""
Request middleware for authentication and session handling.

This module provides Flask middleware for processing requests,
injecting user context, and handling authentication preprocessing.
"""

import os
from datetime import datetime
from typing import Optional, Dict, Any, List
from functools import wraps
from flask import (
    Flask, request, session, g, current_app, 
    redirect, url_for, flash, jsonify
)

from .models import User
from .session_manager import SessionManager
from .user_service import UserService
from utils.logging import logger


class AuthMiddleware:
    """
    Authentication middleware for Flask requests.
    
    This middleware handles user context injection, session validation,
    and authentication preprocessing for all requests.
    """
    
    def __init__(self, app: Optional[Flask] = None):
        """
        Initialize the authentication middleware.
        
        Args:
            app: Flask application instance
        """
        self.app = app
        self.session_manager = None
        self.user_service = None
        
        if app is not None:
            self.init_app(app)
    
    def init_app(self, app: Flask) -> None:
        """
        Initialize the middleware with Flask app.
        
        Args:
            app: Flask application instance
        """
        self.app = app
        self.session_manager = SessionManager(app)
        self.user_service = UserService()
        
        # Register middleware hooks
        app.before_request(self.before_request)
        app.after_request(self.after_request)
        app.teardown_request(self.teardown_request)
        
        # Set up configuration defaults
        app.config.setdefault('AUTH_SESSION_TIMEOUT', 3600)  # 1 hour
        app.config.setdefault('AUTH_REMEMBER_COOKIE_DURATION', 86400 * 30)  # 30 days
        app.config.setdefault('AUTH_REFRESH_EACH_REQUEST', True)
    
    def before_request(self) -> Optional[Any]:
        """
        Process request before handling.
        
        This method:
        1. Sets up user context
        2. Validates session
        3. Handles authentication state
        4. Manages session refresh
        
        Returns:
            Optional response if request should be intercepted
        """
        # Initialize user context
        g.current_user = None
        g.user_authenticated = False
        g.auth_session = None
        
        # Skip authentication for certain endpoints
        if self._should_skip_auth():
            return None
        
        # Check if SSO is enabled
        sso_enabled = os.environ.get('ENABLE_SSO', 'false').lower() == 'true'
        
        if not sso_enabled:
            # SSO disabled - set anonymous user context
            self._set_anonymous_user_context()
            return None
        
        # Validate current session
        user = self._get_current_user()
        
        if user:
            # User is authenticated - update context
            self._set_authenticated_user_context(user)
            
            # Refresh session if needed
            if current_app.config.get('AUTH_REFRESH_EACH_REQUEST', True):
                self._refresh_session()
                
        else:
            # No valid session - clear any stale data
            self._clear_stale_session_data()
        
        return None
    
    def after_request(self, response) -> Any:
        """
        Process response after handling.
        
        Args:
            response: Flask response object
            
        Returns:
            Modified response object
        """
        # Add security headers
        response = self._add_security_headers(response)
        
        # Update session data if user context changed
        if hasattr(g, 'current_user') and g.current_user:
            self._update_session_activity()
        
        return response
    
    def teardown_request(self, exception=None) -> None:
        """
        Clean up request context.
        
        Args:
            exception: Any exception that occurred during request
        """
        try:
            # Clean up any temporary data - only if we have a request context
            if hasattr(g, 'auth_session'):
                g.auth_session = None
            
            # Log authentication events if needed
            if exception and hasattr(g, 'current_user'):
                self._log_auth_exception(exception)
        except RuntimeError:
            # Working outside of application context - ignore
            pass
    
    def _should_skip_auth(self) -> bool:
        """
        Check if authentication should be skipped for current request.
        
        Returns:
            True if auth should be skipped
        """
        # Skip for static files
        if request.endpoint and request.endpoint.startswith('static'):
            return True
        
        # Skip for health check endpoints
        health_endpoints = ['health', 'ping', 'status']
        if request.endpoint in health_endpoints:
            return True
        
        # Skip for SSO callback endpoints (they handle their own auth)
        sso_endpoints = ['sso_acs', 'sso_sls', 'sso_login', 'sso_metadata']
        if request.endpoint in sso_endpoints:
            return True
        
        # Skip for API endpoints that have their own auth
        if request.path.startswith('/api/') and not request.path.startswith('/api/auth/'):
            return True
        
        return False
    
    def _get_current_user(self) -> Optional[User]:
        """
        Get current authenticated user from session.
        
        Returns:
            User object if authenticated, None otherwise
        """
        try:
            if self.session_manager:
                return self.session_manager.get_current_user()
            return None
        except Exception as e:
            logger.warning(f"Error getting current user: {str(e)}")
            return None
    
    def _set_authenticated_user_context(self, user: User) -> None:
        """
        Set authenticated user context in Flask g object.
        
        Args:
            user: Authenticated user object
        """
        g.current_user = user
        g.user_authenticated = True
        
        # Get current session safely
        if self.session_manager:
            try:
                g.auth_session = self.session_manager.get_current_session()
            except Exception as e:
                logger.warning(f"Error getting current session: {str(e)}")
                g.auth_session = None
        else:
            g.auth_session = None
        
        # Store user info in request context for templates
        g.user_display_name = user.display_name or user.username
        g.user_groups = user.groups
        g.user_email = user.email
    
    def _set_anonymous_user_context(self) -> None:
        """
        Set anonymous user context when SSO is disabled.
        """
        # Create anonymous user
        anonymous_user = User(
            user_id='anonymous',
            username='anonymous',
            email='anonymous@localhost',
            display_name='Anonymous User',
            is_authenticated=False
        )
        
        g.current_user = anonymous_user
        g.user_authenticated = False
        g.auth_session = None
        g.user_display_name = 'Anonymous User'
        g.user_groups = []
        g.user_email = 'anonymous@localhost'
    
    def _refresh_session(self) -> None:
        """
        Refresh current session to extend timeout.
        """
        try:
            if self.session_manager:
                # Use the internal _extend_session method
                self.session_manager._extend_session()
        except Exception as e:
            logger.warning(f"Error refreshing session: {str(e)}")
    
    def _clear_stale_session_data(self) -> None:
        """
        Clear any stale session data.
        """
        try:
            # Clear Flask session data related to auth
            if self.session_manager:
                auth_keys = [
                    self.session_manager.USER_KEY,
                    self.session_manager.SESSION_KEY,
                    self.session_manager.SAML_NAMEID_KEY,
                    self.session_manager.SAML_SESSION_INDEX_KEY
                ]
            else:
                # Fallback to common session keys if session_manager not available
                auth_keys = [
                    'auth_user',
                    'auth_session', 
                    'saml_nameid',
                    'saml_session_index'
                ]
            
            for key in auth_keys:
                session.pop(key, None)
                
        except Exception as e:
            logger.warning(f"Error clearing stale session data: {str(e)}")
    
    def _add_security_headers(self, response) -> Any:
        """
        Add security headers to response.
        
        Args:
            response: Flask response object
            
        Returns:
            Response with security headers added
        """
        # Only add headers for HTML responses
        if response.content_type and 'text/html' in response.content_type:
            # X-Content-Type-Options
            response.headers['X-Content-Type-Options'] = 'nosniff'
            
            # X-Frame-Options
            response.headers['X-Frame-Options'] = 'DENY'
            
            # X-XSS-Protection
            response.headers['X-XSS-Protection'] = '1; mode=block'
            
            # Referrer Policy
            response.headers['Referrer-Policy'] = 'strict-origin-when-cross-origin'
            
            # Content Security Policy (basic)
            csp_policy = (
                "default-src 'self'; "
                "script-src 'self' 'unsafe-inline'; "
                "style-src 'self' 'unsafe-inline'; "
                "img-src 'self' data:; "
                "font-src 'self';"
            )
            response.headers['Content-Security-Policy'] = csp_policy
        
        return response
    
    def _update_session_activity(self) -> None:
        """
        Update session activity timestamp.
        """
        try:
            if hasattr(g, 'auth_session') and g.auth_session and self.session_manager:
                # Use _extend_session to update activity
                self.session_manager._extend_session()
        except Exception as e:
            logger.warning(f"Error updating session activity: {str(e)}")
    
    def _log_auth_exception(self, exception: Exception) -> None:
        """
        Log authentication-related exceptions.
        
        Args:
            exception: Exception that occurred
        """
        try:
            user_info = "anonymous"
            if hasattr(g, 'current_user') and g.current_user:
                user_info = g.current_user.username
            
            logger.error(
                f"Authentication exception for user {user_info}: {str(exception)}",
                exc_info=True
            )
        except Exception:
            # Don't let logging errors crash the request
            pass


class RequestContextManager:
    """
    Utility class for managing request context and user information.
    """
    
    @staticmethod
    def get_current_user() -> Optional[User]:
        """
        Get current user from request context.
        
        Returns:
            Current user or None if not authenticated
        """
        return getattr(g, 'current_user', None)
    
    @staticmethod
    def is_authenticated() -> bool:
        """
        Check if current user is authenticated.
        
        Returns:
            True if user is authenticated
        """
        return getattr(g, 'user_authenticated', False)
    
    @staticmethod
    def get_user_groups() -> List[str]:
        """
        Get current user's groups.
        
        Returns:
            List of user groups
        """
        return getattr(g, 'user_groups', [])
    
    @staticmethod
    def has_group(group_name: str) -> bool:
        """
        Check if current user belongs to a specific group.
        
        Args:
            group_name: Name of the group to check
            
        Returns:
            True if user belongs to the group
        """
        user_groups = RequestContextManager.get_user_groups()
        return group_name.lower() in [g.lower() for g in user_groups]
    
    @staticmethod
    def get_user_attribute(attribute_name: str, default: Any = None) -> Any:
        """
        Get a user attribute from current context.
        
        Args:
            attribute_name: Name of the attribute
            default: Default value if attribute not found
            
        Returns:
            Attribute value or default
        """
        user = RequestContextManager.get_current_user()
        if user and hasattr(user, attribute_name):
            return getattr(user, attribute_name, default)
        return default
    
    @staticmethod
    def get_session_info() -> Dict[str, Any]:
        """
        Get current session information.
        
        Returns:
            Dictionary with session information
        """
        session_info = {
            'authenticated': RequestContextManager.is_authenticated(),
            'user_id': None,
            'username': None,
            'display_name': None,
            'groups': [],
            'session_id': None
        }
        
        user = RequestContextManager.get_current_user()
        if user:
            session_info.update({
                'user_id': user.user_id,
                'username': user.username,
                'display_name': user.display_name,
                'groups': user.groups,
                'session_id': user.session_id
            })
        
        return session_info


# Template context processor for making user info available in templates
def inject_user_context():
    """
    Inject user context into templates.
    
    This function makes user information available in all templates
    without having to pass it explicitly in each route.
    
    Returns:
        Dictionary of context variables for templates
    """
    return {
        'current_user': RequestContextManager.get_current_user(),
        'user_authenticated': RequestContextManager.is_authenticated(),
        'user_groups': RequestContextManager.get_user_groups(),
        'session_info': RequestContextManager.get_session_info()
    }


# Global instances
auth_middleware = AuthMiddleware()
request_context = RequestContextManager()
