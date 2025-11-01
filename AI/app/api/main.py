"""
Main FastAPI Application

This is the simplified main application file that handles only:
- FastAPI initialization
- Lifespan management
- Middleware registration
- Router registration

All business logic has been moved to modular routers.
"""

from datetime import datetime
from contextlib import asynccontextmanager
from fastapi import FastAPI
from app.utils.logging import logger
from app.shared.middleware import configure_cors_middleware, request_timing_middleware
from app.modules.docuclaims.router import router as docuclaims_router
from app.modules.insights.router import router as insights_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan management."""
    logger.info("=" * 50)
    logger.info(f"Cortex API server starting up on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    logger.info("=" * 50)
    yield
    logger.info("=" * 50)
    logger.info(f"Cortex API server shutting down at {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    logger.info("=" * 50)


# Initialize FastAPI application
app = FastAPI(lifespan=lifespan)

# Configure CORS middleware using shared component
configure_cors_middleware(app)

# Add request timing middleware using shared component
app.middleware("http")(request_timing_middleware)

# Register module routers
app.include_router(docuclaims_router, prefix="/docuclaims", tags=["DocuClaims"])
app.include_router(insights_router, prefix="/insights", tags=["Insights AI"])

logger.info("FastAPI application initialized with modular structure")
logger.info("Available DocuClaims routes: /docuclaims/model_options, /docuclaims/rag_complete, /docuclaims/upload_file, /docuclaims/check_file_processed")
logger.info("Available Insights AI routes: /insights/domains, /insights/domains/{domain}/models, /insights/query, /insights/execute-sql, /insights/feedback")
