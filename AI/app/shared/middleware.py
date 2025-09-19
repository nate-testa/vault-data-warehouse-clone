"""
Shared middleware for the Snowflake AI application.

This module contains middleware functions that are used across the entire application.
"""

import os
import time
from fastapi import Request
from fastapi.middleware.cors import CORSMiddleware
from app.utils.logging import logger


def configure_cors_middleware(app):
    """
    Configure CORS middleware for the FastAPI application.
    
    Args:
        app: FastAPI application instance
    """
    # Get allowed origins from environment or use defaults
    CORS_ORIGINS = os.environ.get("CORS_ORIGINS", "http://localhost:5001,https://ai.vaultinsurance.com").split(",")
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
    Middleware to log request timing and detect client disconnections.
    
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
    
    try:
        response = await call_next(request)
        duration = time.time() - start_time
        status_code = response.status_code
        
        if status_code >= 400:
            logger.warning(f"[REQUEST_ERROR] [{request_id}] Request completed with error - {method} {path} - {status_code} in {duration:.2f}s")
        else:
            logger.info(f"[REQUEST_SUCCESS] [{request_id}] Request completed successfully - {method} {path} - {status_code} in {duration:.2f}s")
        
        return response
        
    except Exception as e:
        duration = time.time() - start_time
        logger.error(f"[REQUEST_EXCEPTION] [{request_id}] Request failed with exception - {method} {path} after {duration:.2f}s: {str(e)}", exc_info=True)
        # Re-raise the exception so FastAPI can handle it appropriately
        raise
