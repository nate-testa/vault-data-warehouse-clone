"""
Insights AI Router Module

This module contains FastAPI route definitions for the Insights AI functionality including:
- Domain management endpoints for semantic views
- Cortex Analyst query processing with semantic views
- SQL execution endpoints  
- Feedback submission endpoints
- Health check and status endpoints
"""

import time
from typing import List, Optional
from fastapi import APIRouter, HTTPException, status, Depends, Request
from fastapi.responses import JSONResponse
from pydantic import ValidationError

from app.utils.logging import logger
from app.modules.insights.services import insights_service
from app.modules.insights.validators import (
    validate_question,
    validate_domain,
    validate_semantic_view,
    validate_sql,
    sanitize_text,
    input_validator
)
from app.modules.insights.schemas import (
    AnalystRequest,
    AnalystRequestV2,
    AnalystResponse,
    DomainInfo,
    DomainResponse,
    SemanticModelInfo,
    SemanticModelResponse,
    SQLExecutionRequest,
    SQLExecutionResponse,
    FeedbackRequest,
    FeedbackResponse,
    ConversationMessage,
    MessageContent,
    ContentType,
    MessageRole
)


# Create FastAPI router 
router = APIRouter()


@router.get("/domains", 
           response_model=DomainResponse,
           summary="Get Available Domains",
           description="Retrieve all available semantic view domains with their metadata and view counts")
async def get_domains(request: Request):
    """
    Get all available semantic view domains.
    
    Returns domains overview with list of domains, total counts,
    and configuration information.
    
    Returns:
        DomainResponse: Complete domains overview with metadata
    """
    start_time = time.time()
    request_id = f"domains_{int(time.time())}"
    
    logger.info(f"GET /insights/domains [request_id: {request_id}]")
    
    try:
        # Get domains overview from service
        domains_data = insights_service.get_domains_overview()
        
        # Format individual domain info
        domain_list = []
        for domain_key, domain_info in domains_data["domains"].items():
            if "error" in domain_info:
                logger.error(f"Error in domain '{domain_key}': {domain_info['error']}")
                continue
            
            # Extract semantic view paths as strings for the schema
            model_paths = [model["path"] if isinstance(model, dict) else model for model in domain_info["models"][:5]]
            
            domain_item = DomainInfo(
                key=domain_key,
                name=domain_info["name"],
                description=domain_info["description"],
                model_count=domain_info["model_count"],
                models=model_paths  # Only semantic view paths as strings
            )
            domain_list.append(domain_item)
        
        # Create the complete response
        domain_response = DomainResponse(
            domains=domain_list,
            total_domains=domains_data["total_domains"],
            total_models=domains_data["total_models"]
        )
        
        processing_time = time.time() - start_time
        logger.info(f"GET /insights/domains completed: {len(domain_list)} domains in {processing_time:.2f}s [request_id: {request_id}]")
        
        return domain_response
        
    except Exception as e:
        processing_time = time.time() - start_time
        error_msg = f"Failed to retrieve domains: {str(e)}"
        logger.error(f"GET /insights/domains error: {error_msg} [request_id: {request_id}, time: {processing_time:.2f}s]")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={"error": error_msg, "request_id": request_id}
        )


@router.get("/domains/{domain}/models",
           response_model=SemanticModelResponse, 
           summary="Get Domain Semantic Views",
           description="Retrieve semantic views for a specific domain")
async def get_domain_models(domain: str, request: Request):
    """
    Get semantic views for a specific domain.
    
    Args:
        domain: Domain key (configured in semantic_view_domains)
        
    Returns:
        SemanticModelResponse: Domain information with available semantic views
        
    Raises:
        HTTPException: If domain not found or service error
    """
    start_time = time.time()
    request_id = f"models_{domain}_{int(time.time())}"
    
    logger.info(f"GET /insights/domains/{domain}/models [request_id: {request_id}]")
    
    try:
        # Validate domain
        validate_domain(domain)
        
        # Get domain semantic views from service
        domain_models = insights_service.get_models_by_domain(domain)
        domain_metadata = insights_service.get_domain_metadata(domain)
        
        # Create domain info object
        domain_info = DomainInfo(
            key=domain,
            name=domain_metadata["name"],
            description=domain_metadata["description"], 
            model_count=domain_metadata["model_count"],
            models=[model["path"] for model in domain_models["models"]]
        )
        
        # Create semantic view info objects
        model_infos = []
        default_model = None
        
        for model in domain_models["models"]:
            model_info = SemanticModelInfo(
                path=model["path"],
                name=model["name"],
                description=model.get("description", f"Semantic view for {domain} analytics"),
                is_default=model.get("is_default", False)
            )
            model_infos.append(model_info)
            
            if model.get("is_default"):
                default_model = model_info
        
        # Format response
        response = SemanticModelResponse(
            domain=domain,
            domain_info=domain_info,
            models=model_infos,
            default_model=default_model
        )
        
        processing_time = time.time() - start_time
        logger.info(f"GET /insights/domains/{domain}/models completed: {len(model_infos)} semantic views in {processing_time:.2f}s [request_id: {request_id}]")
        
        return response
        
    except ValidationError as e:
        processing_time = time.time() - start_time
        logger.warning(f"GET /insights/domains/{domain}/models validation error: {str(e)} [request_id: {request_id}, time: {processing_time:.2f}s]")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"error": str(e), "request_id": request_id}
        )
    except ValueError as e:
        processing_time = time.time() - start_time
        logger.warning(f"GET /insights/domains/{domain}/models not found: {str(e)} [request_id: {request_id}, time: {processing_time:.2f}s]")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error": str(e), "request_id": request_id}
        )
    except Exception as e:
        processing_time = time.time() - start_time
        error_msg = f"Failed to retrieve semantic views for domain '{domain}': {str(e)}"
        logger.error(f"GET /insights/domains/{domain}/models error: {error_msg} [request_id: {request_id}, time: {processing_time:.2f}s]")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={"error": error_msg, "request_id": request_id}
        )


@router.post("/query",
            response_model=AnalystResponse,
            summary="Process Analyst Query", 
            description="Process natural language questions using Cortex Analyst with conversation context")
async def process_query(request_data: AnalystRequest, request: Request):
    """
    Process a natural language question using Cortex Analyst.
    
    Supports multi-turn conversations with message history and provides
    intelligent responses including SQL generation and data analysis.
    
    Args:
        request_data: Analyst request with question, domain, and optional history
        
    Returns:
        AnalystResponse: Cortex Analyst response with content, warnings, and request_id
        
    Raises:
        HTTPException: If validation fails, service error, or Cortex Analyst error
    """
    start_time = time.time()
    request_id = f"query_{int(time.time())}"
    
    logger.info(f"POST /insights/query: '{request_data.question[:100]}...' [request_id: {request_id}]")
    
    try:
        # Sanitize input text
        sanitized_question = sanitize_text(request_data.question)
        
        # Validate input
        validate_question(sanitized_question)
        validate_semantic_view(request_data.semantic_view)
        
        if request_data.domain:
            validate_domain(request_data.domain)
        
        # Validate message history if provided
        if request_data.message_history:
            is_valid, error_msg = input_validator.validate_message_history(request_data.message_history)
            if not is_valid:
                raise ValueError(error_msg)
        
        # Process query with Cortex Analyst
        result = insights_service.process_analyst_query(
            question=sanitized_question,
            semantic_view=request_data.semantic_view,
            domain=request_data.domain,
            history=request_data.message_history
        )
        
        # Format response
        response = AnalystResponse(
            conversation_id=result["conversation_id"],
            request_id=result["request_id"],
            message=result["content"],
            warnings=result.get("warnings", []),
            processing_time_seconds=result["processing_time_seconds"],
            semantic_view_used=result["semantic_view_used"],
            domain=result.get("domain")
        )
        
        processing_time = time.time() - start_time
        logger.info(f"POST /insights/query completed in {processing_time:.2f}s [request_id: {request_id}, conversation_id: {result['conversation_id']}]")
        
        return response
        
    except ValidationError as e:
        processing_time = time.time() - start_time
        logger.warning(f"POST /insights/query validation error: {str(e)} [request_id: {request_id}, time: {processing_time:.2f}s]")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"error": str(e), "request_id": request_id}
        )
    except ValueError as e:
        processing_time = time.time() - start_time
        logger.warning(f"POST /insights/query value error: {str(e)} [request_id: {request_id}, time: {processing_time:.2f}s]")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"error": str(e), "request_id": request_id}
        )
    except Exception as e:
        processing_time = time.time() - start_time
        error_msg = f"Failed to process query: {str(e)}"
        logger.error(f"POST /insights/query error: {error_msg} [request_id: {request_id}, time: {processing_time:.2f}s]")
        
        # Check for specific error types
        if "authentication" in str(e).lower() or "token" in str(e).lower():
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail={"error": "Authentication failed", "request_id": request_id}
            )
        elif "connection" in str(e).lower() or "network" in str(e).lower():
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail={"error": "Service temporarily unavailable", "request_id": request_id}
            )
        else:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail={"error": error_msg, "request_id": request_id}
            )


@router.post("/query_v2",
            response_model=AnalystResponse,
            summary="Process Analyst Query V2 (Multiple Semantic Models)", 
            description="Process natural language questions using Cortex Analyst with multiple semantic models selection")
async def process_query_v2(request_data: AnalystRequestV2, request: Request):
    """
    Process a natural language question using Cortex Analyst with multiple semantic models.
    
    This version allows specifying multiple semantic models, and Cortex Analyst will
    automatically choose the most appropriate one for the query. Supports multi-turn 
    conversations with message history.
    
    Args:
        request_data: Analyst request with question, semantic models list, and optional history
        
    Returns:
        AnalystResponse: Cortex Analyst response with content, warnings, and request_id
        
    Raises:
        HTTPException: If validation fails, service error, or Cortex Analyst error
    """
    start_time = time.time()
    request_id = f"query_v2_{int(time.time())}"
    
    logger.info(f"POST /insights/query_v2: '{request_data.question[:100]}...' with {len(request_data.semantic_models)} models [request_id: {request_id}]")
    
    try:
        # Sanitize input text
        sanitized_question = sanitize_text(request_data.question)
        
        # Validate input
        validate_question(sanitized_question)
        
        # Validate semantic models - extract the semantic view names for validation
        semantic_views = [model.semantic_view for model in request_data.semantic_models]
        for semantic_view in semantic_views:
            validate_semantic_view(semantic_view)
        
        if request_data.domain:
            validate_domain(request_data.domain)
        
        # Validate message history if provided
        if request_data.message_history:
            is_valid, error_msg = input_validator.validate_message_history(request_data.message_history)
            if not is_valid:
                raise ValueError(error_msg)
        
        # Process query with Cortex Analyst using multiple semantic models
        result = insights_service.process_analyst_query_v2(
            question=sanitized_question,
            semantic_models=request_data.semantic_models,
            domain=request_data.domain,
            history=request_data.message_history
        )
        
        # Extract suggestions from content if present
        suggestions = None
        for content_item in result.get("content", []):
            if content_item.get("type") == "suggestions":
                suggestions = content_item.get("suggestions", [])
                break
        
        # Format response
        response = AnalystResponse(
            conversation_id=result["conversation_id"],
            request_id=result["request_id"],
            message=result["content"],
            warnings=result.get("warnings", []),
            processing_time_seconds=result["processing_time_seconds"],
            semantic_view_used=result["semantic_view_used"],
            domain=result.get("domain"),
            suggestions=suggestions
        )
        
        processing_time = time.time() - start_time
        logger.info(f"POST /insights/query_v2 completed in {processing_time:.2f}s [request_id: {request_id}, conversation_id: {result['conversation_id']}]")
        
        return response
        
    except ValidationError as e:
        processing_time = time.time() - start_time
        logger.warning(f"POST /insights/query_v2 validation error: {str(e)} [request_id: {request_id}, time: {processing_time:.2f}s]")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"error": str(e), "request_id": request_id}
        )
    except ValueError as e:
        processing_time = time.time() - start_time
        logger.warning(f"POST /insights/query_v2 value error: {str(e)} [request_id: {request_id}, time: {processing_time:.2f}s]")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"error": str(e), "request_id": request_id}
        )
    except Exception as e:
        processing_time = time.time() - start_time
        error_msg = f"Failed to process query v2: {str(e)}"
        logger.error(f"POST /insights/query_v2 error: {error_msg} [request_id: {request_id}, time: {processing_time:.2f}s]")
        
        # Check for specific error types
        if "authentication" in str(e).lower() or "token" in str(e).lower():
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail={"error": "Authentication failed", "request_id": request_id}
            )
        elif "connection" in str(e).lower() or "network" in str(e).lower():
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail={"error": "Service temporarily unavailable", "request_id": request_id}
            )
        else:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail={"error": error_msg, "request_id": request_id}
            )


@router.post("/execute-sql",
            response_model=SQLExecutionResponse,
            summary="Execute SQL Query",
            description="Execute SQL queries with optional conversation tracking")
async def execute_sql(request_data: SQLExecutionRequest, request: Request):
    """
    Execute SQL query and return formatted results.
    
    Executes SQL queries generated by Cortex Analyst or provided directly,
    with proper security validation and result formatting.
    
    Args:
        request_data: SQL execution request with query and optional conversation_id
        
    Returns:
        SQLExecutionResponse: Query results with columns, data, and execution metadata
        
    Raises:
        HTTPException: If validation fails, SQL error, or database error
    """
    start_time = time.time()
    request_id = f"sql_{int(time.time())}"
    
    logger.info(f"POST /insights/execute-sql [request_id: {request_id}, conversation_id: {request_data.conversation_id}]")
    logger.debug(f"SQL Query: {request_data.query[:200]}...")
    
    try:
        # Validate SQL query
        validate_sql(request_data.query, allow_modifications=False)
        
        # Execute SQL query
        result = insights_service.execute_sql_query(
            sql_query=request_data.query,
            conversation_id=request_data.conversation_id
        )
        
        # Format response
        response = SQLExecutionResponse(
            execution_id=result["execution_id"],
            conversation_id=result["conversation_id"],
            columns=result["columns"],
            data=result["data"],
            row_count=result["row_count"],
            execution_time_ms=int(result["execution_time_seconds"] * 1000),  # Convert seconds to milliseconds
            query_hash=None  # Optional field, not provided by service yet
        )
        
        processing_time = time.time() - start_time
        logger.info(f"POST /insights/execute-sql completed: {result['row_count']} rows in {processing_time:.2f}s [request_id: {request_id}]")
        
        return response
        
    except ValidationError as e:
        processing_time = time.time() - start_time
        logger.warning(f"POST /insights/execute-sql validation error: {str(e)} [request_id: {request_id}, time: {processing_time:.2f}s]")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"error": f"SQL validation failed: {str(e)}", "request_id": request_id}
        )
    except Exception as e:
        processing_time = time.time() - start_time
        error_msg = f"SQL execution failed: {str(e)}"
        logger.error(f"POST /insights/execute-sql error: {error_msg} [request_id: {request_id}, time: {processing_time:.2f}s]")
        
        # Check for specific database errors
        if "permission" in str(e).lower() or "access denied" in str(e).lower():
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail={"error": "Insufficient permissions for SQL execution", "request_id": request_id}
            )
        elif "syntax" in str(e).lower() or "invalid" in str(e).lower():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail={"error": f"Invalid SQL query: {str(e)}", "request_id": request_id}
            )
        else:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail={"error": error_msg, "request_id": request_id}
            )


@router.post("/feedback",
            response_model=FeedbackResponse,
            summary="Submit Feedback",
            description="Submit user feedback for Cortex Analyst requests")
async def submit_feedback(request_data: FeedbackRequest, request: Request):
    """
    Submit user feedback for a Cortex Analyst request.
    
    Allows users to provide positive or negative feedback with optional
    text comments to improve Cortex Analyst responses.
    
    Args:
        request_data: Feedback request with request_id, rating, and optional message
        
    Returns:
        FeedbackResponse: Feedback submission confirmation
        
    Raises:
        HTTPException: If validation fails or feedback submission error
    """
    start_time = time.time()
    feedback_request_id = f"feedback_{int(time.time())}"
    
    logger.info(f"POST /insights/feedback for request_id: {request_data.request_id} [feedback_request_id: {feedback_request_id}]")
    
    try:
        # Validate request ID
        is_valid, error_msg = input_validator.validate_request_id(request_data.request_id)
        if not is_valid:
            raise ValueError(error_msg)
        
        # Validate feedback message if provided
        if request_data.feedback_message:
            is_valid, error_msg = input_validator.validate_feedback_message(request_data.feedback_message)
            if not is_valid:
                raise ValueError(error_msg)
        
        # Submit feedback
        result = insights_service.submit_feedback(
            request_id=request_data.request_id,
            positive=request_data.positive,
            message=request_data.feedback_message
        )
        
        # Format response
        response = FeedbackResponse(
            feedback_id=result["feedback_id"],
            request_id=result["request_id"],
            success=result["success"],
            submitted_at=result["submitted_at"],
            message="Feedback submitted successfully"
        )
        
        processing_time = time.time() - start_time
        logger.info(f"POST /insights/feedback completed in {processing_time:.2f}s [feedback_request_id: {feedback_request_id}]")
        
        return response
        
    except ValidationError as e:
        processing_time = time.time() - start_time
        logger.warning(f"POST /insights/feedback validation error: {str(e)} [feedback_request_id: {feedback_request_id}, time: {processing_time:.2f}s]")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"error": str(e), "feedback_request_id": feedback_request_id}
        )
    except Exception as e:
        processing_time = time.time() - start_time
        error_msg = f"Failed to submit feedback: {str(e)}"
        logger.error(f"POST /insights/feedback error: {error_msg} [feedback_request_id: {feedback_request_id}, time: {processing_time:.2f}s]")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={"error": error_msg, "feedback_request_id": feedback_request_id}
        )


@router.get("/health",
           summary="Health Check",
           description="Check the health status of the Insights AI service")
async def health_check(request: Request):
    """
    Perform a health check of the Insights AI service.
    
    Validates service configuration, database connectivity,
    and authentication status.
    
    Returns:
        Dict: Health check results with status and component checks
    """
    start_time = time.time()
    request_id = f"health_{int(time.time())}"
    
    logger.info(f"GET /insights/health [request_id: {request_id}]")
    
    try:
        # Get health status from service
        health_status = insights_service.health_check()
        
        processing_time = time.time() - start_time
        health_status["processing_time_seconds"] = processing_time
        health_status["request_id"] = request_id
        
        # Determine HTTP status code based on health
        if health_status["status"] == "healthy":
            status_code = status.HTTP_200_OK
        elif health_status["status"] == "degraded":
            status_code = status.HTTP_206_PARTIAL_CONTENT
        else:
            status_code = status.HTTP_503_SERVICE_UNAVAILABLE
        
        logger.info(f"GET /insights/health completed: {health_status['status']} in {processing_time:.2f}s [request_id: {request_id}]")
        
        return JSONResponse(
            status_code=status_code,
            content=health_status
        )
        
    except Exception as e:
        processing_time = time.time() - start_time
        error_msg = f"Health check failed: {str(e)}"
        logger.error(f"GET /insights/health error: {error_msg} [request_id: {request_id}, time: {processing_time:.2f}s]")
        
        return JSONResponse(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            content={
                "status": "error",
                "error": error_msg,
                "request_id": request_id,
                "processing_time_seconds": processing_time
            }
        )


@router.get("/domains/{domain}/info",
           summary="Get Domain Information",
           description="Get comprehensive information about a specific domain")
async def get_domain_info(domain: str, request: Request):
    """
    Get comprehensive information about a specific domain.
    
    Provides detailed domain metadata including use cases, example questions,
    configuration settings, and available semantic views.
    
    Args:
        domain: Domain key (configured in semantic_view_domains)
        
    Returns:
        Dict: Complete domain metadata and configuration
        
    Raises:
        HTTPException: If domain not found or service error
    """
    start_time = time.time()
    request_id = f"domain_info_{domain}_{int(time.time())}"
    
    logger.info(f"GET /insights/domains/{domain}/info [request_id: {request_id}]")
    
    try:
        # Validate domain
        validate_domain(domain)
        
        # Get domain metadata from service
        domain_metadata = insights_service.get_domain_metadata(domain)
        domain_restrictions = insights_service.get_domain_query_restrictions(domain)
        
        # Combine information
        domain_info = {
            **domain_metadata,
            "query_restrictions": domain_restrictions,
            "request_id": request_id
        }
        
        processing_time = time.time() - start_time
        logger.info(f"GET /insights/domains/{domain}/info completed in {processing_time:.2f}s [request_id: {request_id}]")
        
        return domain_info
        
    except ValidationError as e:
        processing_time = time.time() - start_time
        logger.warning(f"GET /insights/domains/{domain}/info validation error: {str(e)} [request_id: {request_id}, time: {processing_time:.2f}s]")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"error": str(e), "request_id": request_id}
        )
    except ValueError as e:
        processing_time = time.time() - start_time
        logger.warning(f"GET /insights/domains/{domain}/info not found: {str(e)} [request_id: {request_id}, time: {processing_time:.2f}s]")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error": str(e), "request_id": request_id}
        )
    except Exception as e:
        processing_time = time.time() - start_time
        error_msg = f"Failed to retrieve domain information: {str(e)}"
        logger.error(f"GET /insights/domains/{domain}/info error: {error_msg} [request_id: {request_id}, time: {processing_time:.2f}s]")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={"error": error_msg, "request_id": request_id}
        )


@router.get("/domains/{domain}/example-questions",
           summary="Get Example Questions",
           description="Get random example questions for a specific domain")
async def get_example_questions(domain: str, count: int = 3, request: Request = None):
    """
    Get random example questions for a specific domain.
    
    Returns a randomized selection of example questions configured
    for the domain to help users get started.
    
    Args:
        domain: Domain key (configured in semantic_view_domains)
        count: Number of questions to return (default: 3, max: 10)
        
    Returns:
        Dict: Example questions with domain metadata
        
    Raises:
        HTTPException: If domain not found or service error
    """
    start_time = time.time()
    request_id = f"example_questions_{domain}_{int(time.time())}"
    
    logger.info(f"GET /insights/domains/{domain}/example-questions [count: {count}, request_id: {request_id}]")
    
    try:
        # Validate domain
        validate_domain(domain)
        
        # Validate count parameter
        if count < 1 or count > 10:
            raise ValueError("Count must be between 1 and 10")
        
        # Get example questions from service
        questions = insights_service.get_example_questions(domain, count)
        
        # Get domain metadata
        domain_metadata = insights_service.get_domain_metadata(domain)
        
        # Format response
        response = {
            "domain": domain,
            "domain_name": domain_metadata["name"],
            "example_questions": questions,
            "total_available": len(insights_service.domains.get(domain, {}).get("example_questions", [])),
            "returned_count": len(questions)
        }
        
        processing_time = time.time() - start_time
        logger.info(f"GET /insights/domains/{domain}/example-questions completed: {len(questions)} questions in {processing_time:.2f}s [request_id: {request_id}]")
        
        return response
        
    except ValidationError as e:
        processing_time = time.time() - start_time
        logger.warning(f"GET /insights/domains/{domain}/example-questions validation error: {str(e)} [request_id: {request_id}, time: {processing_time:.2f}s]")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"error": str(e), "request_id": request_id}
        )
    except ValueError as e:
        processing_time = time.time() - start_time
        logger.warning(f"GET /insights/domains/{domain}/example-questions value error: {str(e)} [request_id: {request_id}, time: {processing_time:.2f}s]")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"error": str(e), "request_id": request_id}
        )
    except Exception as e:
        processing_time = time.time() - start_time
        error_msg = f"Failed to retrieve example questions: {str(e)}"
        logger.error(f"GET /insights/domains/{domain}/example-questions error: {error_msg} [request_id: {request_id}, time: {processing_time:.2f}s]")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={"error": error_msg, "request_id": request_id}
        )


# Startup event logging
logger.info("Insights AI router initialized with endpoints: /domains, /query, /query_v2, /execute-sql, /feedback, /health")