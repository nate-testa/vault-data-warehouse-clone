"""
Authentication module for the Flask UI application.

This module provides a complete authentication system with SSO support,
session management, user services, route protection decorators, and middleware.
"""

from .models import User, Session
from .session_manager import SessionManager
from .user_service import UserService
from .decorators import login_required, require_groups, admin_required, require_permissions, optional_auth
from .middleware import AuthMiddleware, RequestContextManager, inject_user_context
from .sso_auth import SSOAuth

# Create global instances that can be shared across the application
session_manager = SessionManager()
user_service = UserService()
auth_middleware = AuthMiddleware()
request_context = RequestContextManager()

__all__ = [
    'User',
    'Session', 
    'SessionManager',
    'UserService',
    'SSOAuth',
    'AuthMiddleware',
    'RequestContextManager',
    'inject_user_context',
    'login_required',
    'require_groups', 
    'admin_required',
    'require_permissions',
    'optional_auth',
    'session_manager',
    'user_service',
    'auth_middleware',
    'request_context'
]