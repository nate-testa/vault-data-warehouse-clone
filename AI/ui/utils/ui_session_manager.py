"""
UI Session Management utilities for Flask application.

This module provides session management specifically for UI-related data
to prevent cookie overflow and manage application state efficiently.
"""

import sys
import json
from typing import Dict, List, Any, Optional, Union
from flask import session, current_app
from datetime import datetime

# Import the configured UI logger
from .logging import logger


class BaseUISessionManager:
    """
    Base session manager for shared UI functionality.
    Provides core session management that can be extended by modules.
    """
    
    # Generic session keys
    DEBUG_KEY = 'debug'
    
    def __init__(self, max_cookie_size: int = 3500):
        self.max_cookie_size = max_cookie_size
        
    def get_generic_session_size_estimate(self) -> int:
        """Basic session size estimation for generic data."""
        try:
            debug_data = {'debug': session.get(self.DEBUG_KEY, False)}
            json_str = json.dumps(debug_data, separators=(',', ':'))
            return len(json_str.encode('utf-8'))
        except Exception:
            return 0


class UISessionManager(BaseUISessionManager):
    """
    Session manager for UI-specific data and chat history.
    
    This class handles session data for the UI application, including chat messages,
    file uploads, and user preferences, while preventing cookie overflow issues.
    """
    
    # Generic session keys (inherited from BaseUISessionManager)
    # Note: Specific functionality has been moved to module-specific session managers
    
    def __init__(self, max_cookie_size: int = 3500):
        """
        Initialize the generic UI session manager.
        
        Args:
            max_cookie_size (int): Maximum cookie size in bytes (with safety buffer)
        """
        super().__init__(max_cookie_size)  # Call parent constructor
        
    def initialize_generic_session(self):
        """Initialize generic session variables with default values."""
        if self.DEBUG_KEY not in session:
            session[self.DEBUG_KEY] = False
    
    def set_generic_preference(self, key: str, value: Any):
        """
        Set generic user preference in session.
        
        Args:
            key (str): Preference key (must be DEBUG_KEY)
            value (Any): Preference value
        """
        if key == self.DEBUG_KEY:
            session[key] = value
        else:
            raise ValueError(f"Invalid generic preference key: {key}. Only DEBUG_KEY is supported.")
    
    def get_generic_preference(self, key: str, default: Any = None) -> Any:
        """
        Get generic user preference from session.
        
        Args:
            key (str): Preference key
            default (Any): Default value if key not found
            
        Returns:
            Any: Preference value or default
        """
        return session.get(key, default)
    
    def cleanup_generic_session_storage(self) -> bool:
        """
        Perform cleanup of generic session storage to prevent cookie overflow.
        
        Returns:
            bool: True if cleanup was performed
        """
        original_size = self.get_generic_session_size_estimate()
        cleanup_performed = False
        
        # For generic session, there's minimal data to clean up
        # This method serves as a template for module-specific implementations
        
        if cleanup_performed:
            new_size = self.get_generic_session_size_estimate()
            logger.info(
                f"[GENERIC_SESSION] Session cleanup completed. "
                f"Size reduced from ~{original_size} to ~{new_size} bytes"
            )
        
        return cleanup_performed
    
    def get_session_size_estimate(self) -> int:
        """
        Estimate the current generic session size in bytes.
        
        Returns:
            int: Estimated session size in bytes
        """
        # Delegate to the generic estimation method
        return self.get_generic_session_size_estimate()
    
    def get_generic_session_stats(self) -> Dict[str, Any]:
        """
        Get generic session statistics for monitoring.
        
        Returns:
            Dict[str, Any]: Generic session statistics
        """
        return {
            'module': 'generic',
            'estimated_size_bytes': self.get_generic_session_size_estimate(),
            'max_allowed_size': self.max_cookie_size,
            'size_utilization_percent': round(
                (self.get_generic_session_size_estimate() / self.max_cookie_size) * 100, 2
            ),
            'debug_enabled': session.get(self.DEBUG_KEY, False)
        }
