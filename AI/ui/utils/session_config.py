"""
Server-side session configuration to avoid cookie size limitations.

This module provides configuration for Flask-Session to store session data
on the server side instead of in client cookies, preventing cookie overflow issues.
"""

import os
import tempfile
from flask import Flask
from flask_session import Session
from utils.logging import logger


def configure_server_side_sessions(app: Flask) -> None:
    """
    Configure Flask app to use server-side session storage.
    
    This prevents cookie overflow by storing session data on the server
    and only keeping a session ID in the client cookie.
    
    Args:
        app (Flask): Flask application instance
    """
    try:
        # Configure session to use filesystem storage
        session_dir = os.path.join(tempfile.gettempdir(), 'flask_sessions')
        os.makedirs(session_dir, exist_ok=True)
        
        # Session configuration
        app.config['SESSION_TYPE'] = 'filesystem'
        app.config['SESSION_FILE_DIR'] = session_dir
        app.config['SESSION_PERMANENT'] = False
        app.config['SESSION_USE_SIGNER'] = True
        app.config['SESSION_FILE_THRESHOLD'] = 500  # Max number of session files
        app.config['SESSION_FILE_MODE'] = 0o600  # Secure file permissions
        
        # Initialize server-side sessions
        Session(app)
        
        logger.info(f"[SESSION_CONFIG] Server-side sessions configured using: {session_dir}")
        
    except Exception as e:
        logger.error(f"[SESSION_CONFIG] Failed to configure server-side sessions: {str(e)}")
        logger.warning("[SESSION_CONFIG] Falling back to default cookie-based sessions")


def is_server_side_sessions_available() -> bool:
    """
    Check if Flask-Session is available for server-side session storage.
    
    Returns:
        bool: True if Flask-Session is available
    """
    try:
        import flask_session
        return True
    except ImportError:
        logger.info("[SESSION_CONFIG] Flask-Session not available, using cookie-based sessions")
        return False