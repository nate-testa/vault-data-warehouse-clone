"""
Authentication decorators for route protection.

This module provides decorators for protecting Flask routes with
authentication requirements and role-based access control.
"""

import os
import functools
from typing import List, Optional, Callable, Any, Union
from flask import request, redirect, url_for, flash, jsonify, current_app, session, g

from .session_manager import session_manager
from .user_service import user_service


def sso_enabled() -> bool:
    """
    Check if SSO authentication is enabled.
    
    Returns:
        bool: True if SSO is enabled, False otherwise
    """
    return os.getenv("ENABLE_SSO", "false").lower() == "true"


def login_required(f: Optional[Callable] = None, *, 
                  redirect_url: Optional[str] = None,
                  json_response: bool = False) -> Callable:
    """
    Decorator to require user authentication for accessing a route.
    
    When SSO is disabled, this decorator allows all requests to pass through.
    When SSO is enabled, it requires valid authentication.
    
    Args:
        f (Callable): The function to decorate
        redirect_url (Optional[str]): Custom URL to redirect to for login
        json_response (bool): Return JSON error instead of redirect
        
    Returns:
        Callable: Decorated function
        
    Usage:
        @login_required
        def protected_route():
            return "This requires login"
            
        @login_required(json_response=True)
        def api_route():
            return jsonify({"data": "protected"})
    """
    def decorator(func: Callable) -> Callable:
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            # If SSO is disabled, allow all requests through
            if not sso_enabled():
                current_app.logger.debug(f"SSO disabled, allowing access to {func.__name__}")
                return func(*args, **kwargs)
            
            # SSO is enabled, check authentication
            current_user = session_manager.get_current_user()
            
            if not current_user or not current_user.is_authenticated:
                current_app.logger.warning(f"Unauthenticated access attempt to {func.__name__}")
                
                if json_response:
                    return jsonify({
                        'error': 'Authentication required',
                        'code': 401,
                        'message': 'You must be logged in to access this resource'
                    }), 401
                
                # Store the original URL for redirect after login
                session['next_url'] = request.url
                
                # Redirect to SSO login
                login_url = redirect_url or url_for('saml_sso')
                flash('Please log in to access this page.', 'info')
                return redirect(login_url)
            
            # Store current user in Flask g for easy access in routes
            g.current_user = current_user
            
            current_app.logger.debug(f"Authenticated user {current_user.username} accessing {func.__name__}")
            return func(*args, **kwargs)
        
        return wrapper
    
    # Handle both @login_required and @login_required() usage
    if f is None:
        return decorator
    return decorator(f)


def require_groups(groups: Union[str, List[str]], 
                  require_all: bool = False,
                  json_response: bool = False) -> Callable:
    """
    Decorator to require specific group membership for accessing a route.
    
    Args:
        groups (Union[str, List[str]]): Required group(s)
        require_all (bool): If True, user must be in ALL groups. If False, ANY group.
        json_response (bool): Return JSON error instead of redirect
        
    Returns:
        Callable: Decorated function
        
    Usage:
        @require_groups('admin')
        def admin_route():
            return "Admin only"
            
        @require_groups(['admin', 'moderator'])
        def staff_route():
            return "Admin or moderator"
            
        @require_groups(['admin', 'super_admin'], require_all=True)
        def super_admin_route():
            return "Must be both admin AND super_admin"
    """
    if isinstance(groups, str):
        groups = [groups]
    
    def decorator(func: Callable) -> Callable:
        @functools.wraps(func)
        @login_required(json_response=json_response)
        def wrapper(*args, **kwargs):
            # If SSO is disabled, allow all requests through
            if not sso_enabled():
                return func(*args, **kwargs)
            
            current_user = g.get('current_user') or session_manager.get_current_user()
            
            if not current_user:
                if json_response:
                    return jsonify({
                        'error': 'Authentication required',
                        'code': 401
                    }), 401
                flash('Authentication required.', 'error')
                return redirect(url_for('saml_sso'))
            
            # Check group membership
            if require_all:
                has_access = all(current_user.has_group(group) for group in groups)
                access_type = "all required groups"
            else:
                has_access = current_user.has_any_group(groups)
                access_type = "any required group"
            
            if not has_access:
                current_app.logger.warning(
                    f"User {current_user.username} denied access to {func.__name__} "
                    f"- missing {access_type}: {groups}"
                )
                
                if json_response:
                    return jsonify({
                        'error': 'Insufficient permissions',
                        'code': 403,
                        'message': f'You must be a member of {access_type}: {", ".join(groups)}'
                    }), 403
                
                flash(f'Access denied. Required group membership: {", ".join(groups)}', 'error')
                return redirect(url_for('home'))
            
            current_app.logger.debug(
                f"User {current_user.username} authorized for {func.__name__} "
                f"with groups: {current_user.groups}"
            )
            return func(*args, **kwargs)
        
        return wrapper
    return decorator


def admin_required(json_response: bool = False) -> Callable:
    """
    Decorator to require admin privileges for accessing a route.
    
    Args:
        json_response (bool): Return JSON error instead of redirect
        
    Returns:
        Callable: Decorated function
        
    Usage:
        @admin_required()
        def admin_panel():
            return "Admin panel"
    """
    def decorator(func: Callable) -> Callable:
        @functools.wraps(func)
        @login_required(json_response=json_response)
        def wrapper(*args, **kwargs):
            # If SSO is disabled, allow all requests through
            if not sso_enabled():
                return func(*args, **kwargs)
            
            current_user = g.get('current_user') or session_manager.get_current_user()
            
            if not current_user:
                if json_response:
                    return jsonify({'error': 'Authentication required', 'code': 401}), 401
                return redirect(url_for('saml_sso'))
            
            if not user_service.is_user_admin(current_user):
                current_app.logger.warning(
                    f"User {current_user.username} denied admin access to {func.__name__}"
                )
                
                if json_response:
                    return jsonify({
                        'error': 'Admin privileges required',
                        'code': 403,
                        'message': 'You must have administrator privileges to access this resource'
                    }), 403
                
                flash('Administrator privileges required.', 'error')
                return redirect(url_for('home'))
            
            current_app.logger.debug(f"Admin user {current_user.username} accessing {func.__name__}")
            return func(*args, **kwargs)
        
        return wrapper
    return decorator


def require_permissions(permissions: Union[str, List[str]], 
                       require_all: bool = True,
                       json_response: bool = False) -> Callable:
    """
    Decorator to require specific permissions for accessing a route.
    
    Args:
        permissions (Union[str, List[str]]): Required permission(s)
        require_all (bool): If True, user must have ALL permissions. If False, ANY permission.
        json_response (bool): Return JSON error instead of redirect
        
    Returns:
        Callable: Decorated function
        
    Usage:
        @require_permissions('can_delete')
        def delete_route():
            return "Can delete"
            
        @require_permissions(['can_read', 'can_write'])
        def read_write_route():
            return "Can read and write"
    """
    if isinstance(permissions, str):
        permissions = [permissions]
    
    def decorator(func: Callable) -> Callable:
        @functools.wraps(func)
        @login_required(json_response=json_response)
        def wrapper(*args, **kwargs):
            # If SSO is disabled, allow all requests through
            if not sso_enabled():
                return func(*args, **kwargs)
            
            current_user = g.get('current_user') or session_manager.get_current_user()
            
            if not current_user:
                if json_response:
                    return jsonify({'error': 'Authentication required', 'code': 401}), 401
                return redirect(url_for('saml_sso'))
            
            # Get user permissions
            user_permissions = user_service.get_user_permissions(current_user)
            
            # Check permissions
            if require_all:
                has_access = all(user_permissions.get(perm, False) for perm in permissions)
                access_type = "all required permissions"
            else:
                has_access = any(user_permissions.get(perm, False) for perm in permissions)
                access_type = "any required permission"
            
            if not has_access:
                current_app.logger.warning(
                    f"User {current_user.username} denied access to {func.__name__} "
                    f"- missing {access_type}: {permissions}"
                )
                
                if json_response:
                    return jsonify({
                        'error': 'Insufficient permissions',
                        'code': 403,
                        'message': f'You need {access_type}: {", ".join(permissions)}'
                    }), 403
                
                flash(f'Access denied. Required permissions: {", ".join(permissions)}', 'error')
                return redirect(url_for('home'))
            
            current_app.logger.debug(
                f"User {current_user.username} authorized for {func.__name__} "
                f"with permissions: {[p for p in permissions if user_permissions.get(p, False)]}"
            )
            return func(*args, **kwargs)
        
        return wrapper
    return decorator


def optional_auth(f: Callable) -> Callable:
    """
    Decorator that makes authentication optional - sets g.current_user if authenticated.
    
    This decorator allows routes to access user information if available,
    but doesn't require authentication.
    
    Args:
        f (Callable): The function to decorate
        
    Returns:
        Callable: Decorated function
        
    Usage:
        @optional_auth
        def mixed_route():
            if g.current_user:
                return f"Hello {g.current_user.display_name}"
            return "Hello anonymous user"
    """
    @functools.wraps(f)
    def wrapper(*args, **kwargs):
        # Always try to get current user, even if SSO is disabled
        current_user = None
        if sso_enabled():
            current_user = session_manager.get_current_user()
        
        # Store in Flask g for easy access
        g.current_user = current_user
        
        if current_user:
            current_app.logger.debug(f"Optional auth: user {current_user.username} accessing {f.__name__}")
        else:
            current_app.logger.debug(f"Optional auth: anonymous user accessing {f.__name__}")
        
        return f(*args, **kwargs)
    
    return wrapper


def csrf_protected(f: Callable) -> Callable:
    """
    Decorator to protect routes against CSRF attacks.
    
    Args:
        f (Callable): The function to decorate
        
    Returns:
        Callable: Decorated function
        
    Usage:
        @csrf_protected
        def form_handler():
            return "CSRF protected form handler"
    """
    @functools.wraps(f)
    def wrapper(*args, **kwargs):
        # Skip CSRF check if SSO is disabled
        if not sso_enabled():
            return f(*args, **kwargs)
        
        # Only check CSRF for POST, PUT, DELETE requests
        if request.method in ['POST', 'PUT', 'DELETE', 'PATCH']:
            # Get CSRF token from form data or headers
            csrf_token = request.form.get('csrf_token') or request.headers.get('X-CSRF-Token')
            
            if csrf_token and not session_manager.validate_csrf_token(csrf_token):
                current_app.logger.warning(f"CSRF validation failed for {f.__name__}")
                
                if request.is_json:
                    return jsonify({
                        'error': 'CSRF token validation failed',
                        'code': 403
                    }), 403
                
                flash('Security validation failed. Please try again.', 'error')
                return redirect(request.referrer or url_for('home'))
            elif not csrf_token:
                current_app.logger.warning(f"Missing CSRF token for {f.__name__}")
                
                if request.is_json:
                    return jsonify({
                        'error': 'CSRF token required',
                        'code': 403
                    }), 403
                
                flash('Security token required. Please try again.', 'error')
                return redirect(request.referrer or url_for('home'))
        
        return f(*args, **kwargs)
    
    return wrapper


class RouteProtection:
    """
    Utility class for route protection and authorization helpers.
    
    This class provides utility methods for checking authentication
    and authorization status without decorators.
    """
    
    @staticmethod
    def is_authenticated() -> bool:
        """
        Check if current request is from authenticated user.
        
        Returns:
            bool: True if authenticated, False otherwise
        """
        if not sso_enabled():
            return True  # Consider all users authenticated when SSO is disabled
        
        current_user = session_manager.get_current_user()
        return current_user is not None and current_user.is_authenticated
    
    @staticmethod
    def get_current_user():
        """
        Get current authenticated user.
        
        Returns:
            Optional[User]: Current user or None
        """
        if not sso_enabled():
            return None
        
        return session_manager.get_current_user()
    
    @staticmethod
    def require_auth_or_fail() -> bool:
        """
        Check authentication and raise exception if not authenticated.
        
        Returns:
            bool: True if authenticated
            
        Raises:
            Unauthorized: If not authenticated
        """
        if not RouteProtection.is_authenticated():
            from werkzeug.exceptions import Unauthorized
            raise Unauthorized("Authentication required")
        return True
    
    @staticmethod
    def has_group(group_name: str) -> bool:
        """
        Check if current user has specific group membership.
        
        Args:
            group_name (str): Group name to check
            
        Returns:
            bool: True if user has group, False otherwise
        """
        if not sso_enabled():
            return True
        
        current_user = session_manager.get_current_user()
        if not current_user:
            return False
        
        return current_user.has_group(group_name)
    
    @staticmethod
    def has_permission(permission: str) -> bool:
        """
        Check if current user has specific permission.
        
        Args:
            permission (str): Permission to check
            
        Returns:
            bool: True if user has permission, False otherwise
        """
        if not sso_enabled():
            return True
        
        current_user = session_manager.get_current_user()
        if not current_user:
            return False
        
        user_permissions = user_service.get_user_permissions(current_user)
        return user_permissions.get(permission, False)
    
    @staticmethod
    def is_admin() -> bool:
        """
        Check if current user has admin privileges.
        
        Returns:
            bool: True if user is admin, False otherwise
        """
        if not sso_enabled():
            return True
        
        current_user = session_manager.get_current_user()
        if not current_user:
            return False
        
        return user_service.is_user_admin(current_user)


# Create global instance for easy import
route_protection = RouteProtection()
