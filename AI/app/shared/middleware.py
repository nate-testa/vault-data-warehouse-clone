"""
Shared middleware for the Snowflake AI application.

This module contains middleware functions that are used across the entire application.
"""

import json
import os
import time
from datetime import datetime
from pathlib import Path
from fastapi import Request
from fastapi.middleware.cors import CORSMiddleware
from app.utils.logging import logger
from app.config import get_config


# Allowed modules for usage logging
ALLOWED_MODULES = {'docuclaims', 'insights', 'insights-agent', 'api-test'}


def _extract_module_name(path: str) -> str:
    """
    Extract module name from URL path.
    
    Args:
        path: URL path (e.g., /docuclaims/rag_complete)
        
    Returns:
        Module name (e.g., docuclaims) or 'unknown'
    """
    parts = path.strip('/').split('/')
    if len(parts) > 0 and parts[0]:
        return parts[0]
    return 'unknown'


def _is_allowed_module(path: str) -> bool:
    """
    Check if the request path corresponds to an allowed module.
    
    Args:
        path: URL path (e.g., /docuclaims/rag_complete)
        
    Returns:
        True if module is in ALLOWED_MODULES, False otherwise
    """
    module = _extract_module_name(path)
    return module in ALLOWED_MODULES


def _derive_action_type(path: str, method: str) -> str:
    """
    Derive action type from endpoint path and HTTP method.
    
    Args:
        path: URL path (e.g., /insights/query_v2)
        method: HTTP method (GET, POST, etc.)
        
    Returns:
        Action type: query, execute_sql, upload, list, page_view, export, config
    """
    path_lower = path.lower()
    
    # Query operations
    if any(keyword in path_lower for keyword in ['query', 'ask', 'search', 'rag_complete']):
        return 'query'
    
    # SQL execution
    if 'execute-sql' in path_lower or 'sql' in path_lower:
        return 'execute_sql'
    
    # Upload operations
    if 'upload' in path_lower:
        return 'upload'
    
    # Export operations
    if 'export' in path_lower or 'download' in path_lower:
        return 'export'
    
    # Configuration/metadata endpoints (GET requests for models, domains, options)
    if method == 'GET':
        if any(keyword in path_lower for keyword in ['domains', 'models', 'options', 'config', 'metadata']):
            return 'config'
        # Generic GET requests are page views or list operations
        return 'list'
    
    # Default for other operations
    return 'unknown'


def _write_usage_event(event_data: dict):
    """
    Write usage event to daily JSONL file.
    
    Args:
        event_data: Dictionary containing usage event data
    """
    try:
        usage_dir = Path.home() / 'python_scripts/snowflake_ai/app/logs/usage'
        usage_dir.mkdir(parents=True, exist_ok=True)
        
        date_str = datetime.now().strftime('%Y%m%d')
        usage_file = usage_dir / f"usage_{date_str}.jsonl"
        
        with open(usage_file, 'a') as f:
            f.write(json.dumps(event_data) + '\n')
            
    except Exception as e:
        logger.error(f"Failed to write usage event: {str(e)}", exc_info=True)


def configure_cors_middleware(app):
    """
    Configure CORS middleware for the FastAPI application.
    
    Args:
        app: FastAPI application instance
    """
    # Get allowed origins from environment configuration
    CORS_ORIGINS = get_config("CORS_ORIGINS").split(",")
    logger.info(f"Configuring CORS with allowed origins: {CORS_ORIGINS}")

    app.add_middleware(
        CORSMiddleware,
        allow_origins=CORS_ORIGINS,  # Use specific origins for better security
        allow_credentials=True,
        allow_methods=["*"],  # Allow all HTTP methods
        allow_headers=["*"],  # Allow all headers
    )


async def request_timing_middleware(request: Request, call_next):
    """
    Middleware to log request timing and capture usage data.
    
    Args:
        request: FastAPI Request object
        call_next: Next middleware/endpoint in the chain
        
    Returns:
        Response from the next middleware/endpoint
    """
    start_time = time.time()
    client_ip = request.client.host if request.client else "unknown"
    method = request.method
    path = request.url.path
    
    # Generate a unique request ID for this request
    request_id = f"req_{int(start_time * 1000)}"
    logger.info(f"[REQUEST_START] [{request_id}] Request started - {method} {path} from {client_ip}")
    
    # Extract username from header (passed by UI layer)
    username = request.headers.get('X-Username', 'anonymous')
    
    # Check if module is allowed for logging
    is_allowed = _is_allowed_module(path)
    
    try:
        response = await call_next(request)
        duration = time.time() - start_time
        status_code = response.status_code
        
        # Only log if it's an allowed module
        if is_allowed:
            if status_code >= 400:
                logger.warning(f"[REQUEST_ERROR] [{request_id}] Request completed with error - {method} {path} - {status_code} in {duration:.2f}s")
            else:
                logger.info(f"[REQUEST_SUCCESS] [{request_id}] Request completed successfully - {method} {path} - {status_code} in {duration:.2f}s")
            
            # Capture usage event data only for allowed modules
            usage_data = {
                'event_id': request_id,
                'timestamp': datetime.now().isoformat(),
                'username': username,
                'module': _extract_module_name(path),
                'endpoint': path,
                'method': method,
                'action': _derive_action_type(path, method),
                'exec_time': round(duration * 1000, 2),  # Convert to milliseconds
                'status': status_code,
                'success': status_code < 400
            }
            
            # Write to separate JSONL file
            _write_usage_event(usage_data)
        
        return response
        
    except Exception as e:
        duration = time.time() - start_time
        
        # Only log exceptions for allowed modules
        if is_allowed:
            logger.error(f"[REQUEST_EXCEPTION] [{request_id}] Request failed with exception - {method} {path} after {duration:.2f}s: {str(e)}", exc_info=True)
            
            # Capture usage event even for exceptions (only for allowed modules)
            usage_data = {
                'event_id': request_id,
                'timestamp': datetime.now().isoformat(),
                'username': username,
                'module': _extract_module_name(path),
                'endpoint': path,
                'method': method,
                'action': _derive_action_type(path, method),
                'exec_time': round(duration * 1000, 2),
                'status': 500,
                'success': False
            }
            _write_usage_event(usage_data)
        
        # Re-raise the exception so FastAPI can handle it appropriately
        raise