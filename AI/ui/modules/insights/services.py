"""
Insights-specific API service layer.

This module provides service functions to interact with the Insights API endpoints,
handling domain management, Cortex Analyst queries, SQL execution, and feedback submission.
"""

import os
import requests
import time
from typing import Dict, List, Any, Optional, Union
from dotenv import load_dotenv
from utils.logging import logger
from modules.insights.session_manager import InsightsSessionManager
from modules.insights.schemas import ResultData, CachedResult, generate_cache_key
from modules.insights.charts import generate_chart_from_query_result, get_chart_recommendations

# Load environment variables
load_dotenv()

# Insights session manager instance for services
insights_session = InsightsSessionManager(max_cookie_size=3500, max_chat_messages=10)

# API endpoint configuration
API_BASE = os.environ.get("API_BASE_URL")
if not API_BASE:
    raise RuntimeError("Missing required environment variable: API_BASE_URL")

# API timeout configurations (connection timeout, read timeout)
DEFAULT_TIMEOUT = (10, 30)  # 10s connection, 30s read
QUERY_TIMEOUT = (15, 240)   # 15s connection, 240s (4 min) read for complex BI queries with AI
SQL_TIMEOUT = (10, 120)     # 10s connection, 120s read for SQL execution


def get_available_domains() -> Dict[str, Any]:
    """
    Get semantic model domains from the Insights API.
    
    Fetches all available domains (sales, policy, claims, others) with their
    metadata, semantic view counts, and model information through the API.
    
    Returns:
        Dict[str, Any]: Domains data with domain list and metadata
        
    Raises:
        requests.RequestException: If API connection fails
        ValueError: If API response is invalid
    """
    try:
        logger.info("[INSIGHTS_SERVICE] Fetching domains from API")
        
        response = requests.get(
            f"{API_BASE}/insights/domains",
            timeout=DEFAULT_TIMEOUT
        )
        response.raise_for_status()
        
        api_response = response.json()
        
        # Validate response structure
        if not isinstance(api_response, dict):
            raise ValueError("Invalid API response structure")
        
        required_fields = ['domains', 'total_domains', 'total_models']
        for field in required_fields:
            if field not in api_response:
                raise ValueError(f"Missing required field '{field}' in API response")
        
        # Format domains for UI consumption (convert from API format to UI format)
        formatted_domains = {}
        api_domains = api_response.get('domains', [])
        
        for domain_info in api_domains:
            domain_key = domain_info.get('key')
            if not domain_key:
                continue
                
            # Convert semantic models to semantic_views format for UI compatibility
            semantic_views = []
            models = domain_info.get('models', [])
            for model in models:
                semantic_views.append({
                    'name': model.split('.')[-1],  # Get model name without schema
                    'full_path': model,
                    'description': f'{domain_info.get("name", domain_key.title())} model'
                })
            
            formatted_domains[domain_key] = {
                'key': domain_key,
                'name': domain_info.get('name', domain_key.title()),
                'description': domain_info.get('description', f'{domain_key.title()} analytics'),
                'semantic_views': semantic_views,
                'default_model': models[0] if models else '',
                'model_count': domain_info.get('model_count', len(models))
            }
        
        result = {
            'domains': formatted_domains,
            'total_domains': api_response.get('total_domains'),
            'total_semantic_views': api_response.get('total_models')  # API uses 'total_models'
        }
        
        logger.info(f"[INSIGHTS_SERVICE] Successfully fetched {len(formatted_domains)} domains with {result['total_semantic_views']} total models from API")
        
        return result
        
    except requests.Timeout:
        logger.error("[INSIGHTS_SERVICE] Timeout while fetching domains from API")
        raise requests.RequestException("Request timeout while fetching domains")
        
    except requests.ConnectionError:
        logger.error("[INSIGHTS_SERVICE] Connection error while fetching domains from API")
        raise requests.RequestException("Cannot connect to Insights API")
        
    except requests.HTTPError as e:
        error_msg = f"API returned error {e.response.status_code} while fetching domains"
        logger.error(f"[INSIGHTS_SERVICE] {error_msg}")
        
        # Try to extract error details from response
        try:
            error_details = e.response.json()
            if isinstance(error_details, dict) and 'detail' in error_details:
                error_msg += f": {error_details['detail']}"
        except:
            pass
        
        raise requests.RequestException(error_msg)
        
    except ValueError as e:
        logger.error(f"[INSIGHTS_SERVICE] Invalid API response data: {str(e)}")
        raise ValueError(f"Invalid API response: {str(e)}")
        
    except Exception as e:
        logger.error(f"[INSIGHTS_SERVICE] Unexpected error fetching domains: {str(e)}", exc_info=True)
        raise requests.RequestException(f"Unexpected error: {str(e)}")
        
def get_domain_models(domain: str) -> List[Dict[str, Any]]:
    """
    Get semantic models for a specific domain from the Insights API.
    
    Retrieves all available semantic models/views for the specified domain
    through the API endpoint instead of local configuration access.
    
    Args:
        domain (str): Domain name (sales, policy, claims, others)
        
    Returns:
        List[Dict[str, Any]]: List of semantic models with metadata
        
    Raises:
        requests.RequestException: If API connection fails
        ValueError: If domain is invalid or API response is invalid
    """
    try:
        if not domain or not isinstance(domain, str):
            raise ValueError("Domain must be a non-empty string")
        
        if domain.strip() == "":
            raise ValueError("Domain cannot be empty")
        
        logger.info(f"[INSIGHTS_SERVICE] Fetching models for domain '{domain}' from API")
        
        response = requests.get(
            f"{API_BASE}/insights/domains/{domain}/models",
            timeout=DEFAULT_TIMEOUT
        )
        response.raise_for_status()
        
        api_response = response.json()
        
        # Validate response structure
        if not isinstance(api_response, dict):
            raise ValueError("Invalid API response structure")
        
        # Extract semantic models from API response (correct format from backend)
        models = api_response.get('models', [])
        if not isinstance(models, list):
            raise ValueError(f"Invalid models format in API response for domain '{domain}'")
        
        # Convert API models format to UI semantic_views format for compatibility
        semantic_views = []
        for model in models:
            if isinstance(model, dict):
                semantic_views.append({
                    'name': model.get('name', ''),
                    'full_path': model.get('path', ''),
                    'description': model.get('description', f'{domain.title()} model')
                })
            elif isinstance(model, str):
                # Handle case where models are just paths (fallback)
                semantic_views.append({
                    'name': model.split('.')[-1],  # Get model name without schema
                    'full_path': model,
                    'description': f'{domain.title()} model'
                })
        
        logger.info(f"[INSIGHTS_SERVICE] Successfully fetched {len(semantic_views)} models for domain '{domain}' from API")
        
        return semantic_views
        
    except requests.Timeout:
        logger.error(f"[INSIGHTS_SERVICE] Timeout while fetching models for domain '{domain}'")
        raise requests.RequestException(f"Request timeout while fetching models for domain '{domain}'")
        
    except requests.ConnectionError:
        logger.error(f"[INSIGHTS_SERVICE] Connection error while fetching models for domain '{domain}'")
        raise requests.RequestException("Cannot connect to Insights API")
        
    except requests.HTTPError as e:
        error_msg = f"API returned error {e.response.status_code} for domain '{domain}'"
        logger.error(f"[INSIGHTS_SERVICE] {error_msg}")
        
        # Try to extract error details from response
        try:
            error_details = e.response.json()
            if isinstance(error_details, dict) and 'detail' in error_details:
                error_msg += f": {error_details['detail']}"
        except:
            pass
        
        raise requests.RequestException(error_msg)
        
    except ValueError as e:
        logger.error(f"[INSIGHTS_SERVICE] Invalid input or API response for domain '{domain}': {str(e)}")
        raise ValueError(f"Invalid data for domain '{domain}': {str(e)}")
        
    except Exception as e:
        logger.error(f"[INSIGHTS_SERVICE] Unexpected error fetching models for domain '{domain}': {str(e)}", exc_info=True)
        raise requests.RequestException(f"Unexpected error: {str(e)}")


def send_analyst_query(
    question: str, 
    domain: str, 
    semantic_view: str, 
    message_history: Optional[List[Dict[str, Any]]] = None
) -> Dict[str, Any]:
    """
    Send a question to Cortex Analyst with domain context and conversation history.
    
    Processes natural language questions using Snowflake Cortex Analyst,
    providing contextual responses with SQL generation and insights.
    
    Args:
        question (str): Natural language question
        domain (str): Domain context (sales, policy, claims, others)
        semantic_view (str): Path to semantic view/model
        message_history (Optional[List[Dict[str, Any]]]): Previous conversation messages
        
    Returns:
        Dict[str, Any]: Cortex Analyst response with content, warnings, and metadata
        
    Raises:
        requests.RequestException: If API connection fails
        ValueError: If input validation fails
    """
    try:
        # Validate inputs
        if not question or not isinstance(question, str):
            raise ValueError("Question must be a non-empty string")
        
        if not domain or not isinstance(domain, str):
            raise ValueError("Domain must be a non-empty string")
        
        if not semantic_view or not isinstance(semantic_view, str):
            logger.error(f"[INSIGHTS_SERVICE] Invalid semantic view: '{semantic_view}' (type: {type(semantic_view)})")
            raise ValueError("Semantic view must be a non-empty string. Please ensure a valid semantic view is selected for the domain.")
        
        if question.strip() == "":
            raise ValueError("Question cannot be empty")
        
        # Prepare request payload
        payload = {
            "question": question.strip(),
            "domain": domain,
            "semantic_view": semantic_view,
            "message_history": message_history or []
        }
        
        logger.info(f"[INSIGHTS_SERVICE] Sending analyst query: '{question[:100]}...' for domain '{domain}'")
        logger.debug(f"[INSIGHTS_SERVICE] Semantic view: {semantic_view}")
        logger.debug(f"[INSIGHTS_SERVICE] History length: {len(message_history) if message_history else 0}")
        
        response = requests.post(
            f"{API_BASE}/insights/query",
            json=payload,
            timeout=QUERY_TIMEOUT
        )
        response.raise_for_status()
        
        analyst_response = response.json()
        
        # Validate response structure
        if not isinstance(analyst_response, dict):
            raise ValueError("Invalid analyst response structure")
        
        required_fields = ['request_id', 'message']
        for field in required_fields:
            if field not in analyst_response:
                raise ValueError(f"Missing required field '{field}' in analyst response")
        
        request_id = analyst_response['request_id']
        logger.info(f"[INSIGHTS_SERVICE] Successfully received analyst response [request_id: {request_id}]")
        
        # Log response details for debugging
        content_items = len(analyst_response.get('message', []))
        warnings_count = len(analyst_response.get('warnings', []))
        logger.debug(f"[INSIGHTS_SERVICE] Response contains {content_items} content items, {warnings_count} warnings")
        
        return analyst_response
        
    except requests.Timeout:
        logger.error(f"[INSIGHTS_SERVICE] Timeout while processing query: '{question[:50]}...'")
        raise requests.RequestException("Request timeout while processing question")
        
    except requests.ConnectionError:
        logger.error(f"[INSIGHTS_SERVICE] Connection error while processing query: '{question[:50]}...'")
        raise requests.RequestException("Cannot connect to Insights API")
        
    except requests.HTTPError as e:
        error_msg = f"API returned error {e.response.status_code} for query"
        logger.error(f"[INSIGHTS_SERVICE] {error_msg}: '{question[:50]}...'")
        
        # Try to extract error details from response
        try:
            error_details = e.response.json()
            if isinstance(error_details, dict) and 'detail' in error_details:
                error_msg += f": {error_details['detail']}"
        except:
            pass
        
        raise requests.RequestException(error_msg)
        
    except ValueError as e:
        logger.error(f"[INSIGHTS_SERVICE] Invalid input or response data: {str(e)}")
        raise ValueError(f"Invalid data: {str(e)}")
        
    except Exception as e:
        logger.error(f"[INSIGHTS_SERVICE] Unexpected error processing query: {str(e)}", exc_info=True)
        raise requests.RequestException(f"Unexpected error: {str(e)}")


def send_analyst_query_v2(
    question: str, 
    domain: str, 
    semantic_models: List[Dict[str, Any]], 
    message_history: Optional[List[Dict[str, Any]]] = None
) -> Dict[str, Any]:
    """
    Send a question to Cortex Analyst with multiple semantic models.
    
    Processes natural language questions using Snowflake Cortex Analyst with 
    multiple semantic models, allowing the AI to choose the most appropriate one.
    
    Args:
        question (str): Natural language question
        domain (str): Domain context (sales, policy, claims, others)
        semantic_models (List[Dict[str, Any]]): List of semantic models with view, name, description
        message_history (Optional[List[Dict[str, Any]]]): Previous conversation messages
        
    Returns:
        Dict[str, Any]: Cortex Analyst response with content, warnings, and metadata
        
    Raises:
        requests.RequestException: If API connection fails
        ValueError: If input validation fails
    """
    try:
        # Validate inputs
        if not question or not isinstance(question, str):
            raise ValueError("Question must be a non-empty string")
        
        if not domain or not isinstance(domain, str):
            raise ValueError("Domain must be a non-empty string")
        
        if not semantic_models or not isinstance(semantic_models, list):
            raise ValueError("Semantic models must be a non-empty list")
        
        if question.strip() == "":
            raise ValueError("Question cannot be empty")
        
        # Prepare request payload for query_v2
        payload = {
            "question": question.strip(),
            "domain": domain,
            "semantic_models": semantic_models,
            "message_history": message_history or []
        }
        
        logger.info(f"[INSIGHTS_SERVICE] Sending analyst query v2: '{question[:100]}...' for domain '{domain}'")
        logger.debug(f"[INSIGHTS_SERVICE] Semantic models: {len(semantic_models)} models")
        logger.debug(f"[INSIGHTS_SERVICE] History length: {len(message_history) if message_history else 0}")
        
        response = requests.post(
            f"{API_BASE}/insights/query_v2",
            json=payload,
            timeout=QUERY_TIMEOUT
        )
        response.raise_for_status()
        
        analyst_response = response.json()
        
        # Validate response structure
        if not isinstance(analyst_response, dict):
            raise ValueError("Invalid analyst response structure")
        
        required_fields = ['request_id', 'message']
        for field in required_fields:
            if field not in analyst_response:
                raise ValueError(f"Missing required field '{field}' in analyst response")
        
        # Handle the new message structure from query_v2 API
        message_data = analyst_response.get('message', {})
        if isinstance(message_data, dict) and 'content' in message_data:
            # New format: message = { role: "analyst", content: [...] }
            analyst_response['message'] = message_data['content']
        elif not isinstance(message_data, list):
            # Fallback: ensure message is always a list
            analyst_response['message'] = []
        
        request_id = analyst_response['request_id']
        semantic_view_used = analyst_response.get('semantic_view_used', 'unknown')
        logger.info(f"[INSIGHTS_SERVICE] Successfully received analyst response v2 [request_id: {request_id}, semantic_view_used: {semantic_view_used}]")
        
        # Log response details for debugging
        content_items = len(analyst_response.get('message', []))
        warnings_count = len(analyst_response.get('warnings', []))
        logger.debug(f"[INSIGHTS_SERVICE] Response contains {content_items} content items, {warnings_count} warnings")
        
        return analyst_response
        
    except requests.Timeout:
        logger.error(f"[INSIGHTS_SERVICE] Timeout while processing query v2: '{question[:50]}...'")
        raise requests.RequestException("Request timeout while processing question")
        
    except requests.ConnectionError:
        logger.error(f"[INSIGHTS_SERVICE] Connection error while processing query v2: '{question[:50]}...'")
        raise requests.RequestException("Cannot connect to Insights API")
        
    except requests.HTTPError as e:
        error_msg = f"API returned error {e.response.status_code} for query v2"
        logger.error(f"[INSIGHTS_SERVICE] {error_msg}: '{question[:50]}...'")
        
        # Try to extract error details from response
        try:
            error_details = e.response.json()
            if isinstance(error_details, dict) and 'detail' in error_details:
                error_msg += f": {error_details['detail']}"
        except:
            pass
        
        raise requests.RequestException(error_msg)
        
    except ValueError as e:
        logger.error(f"[INSIGHTS_SERVICE] Invalid input or response data for query v2: {str(e)}")
        raise ValueError(f"Invalid data: {str(e)}")
        
    except Exception as e:
        logger.error(f"[INSIGHTS_SERVICE] Unexpected error processing query v2: {str(e)}", exc_info=True)
        raise requests.RequestException(f"Unexpected error: {str(e)}")


def execute_sql_query(sql: str, conversation_id: Optional[str] = None) -> Dict[str, Any]:
    """
    Execute a SQL query with optional conversation tracking.
    
    Executes SQL queries generated by Cortex Analyst or provided directly,
    returning formatted results with proper security validation.
    
    Args:
        sql (str): SQL query to execute
        conversation_id (Optional[str]): Conversation identifier for tracking
        
    Returns:
        Dict[str, Any]: Query results with columns, data, and execution metadata
        
    Raises:
        requests.RequestException: If API connection fails
        ValueError: If SQL validation fails
    """
    try:
        # Validate SQL input
        if not sql or not isinstance(sql, str):
            raise ValueError("SQL query must be a non-empty string")
        
        if sql.strip() == "":
            raise ValueError("SQL query cannot be empty")
        
        # Prepare request payload
        payload = {
            "query": sql.strip(),
            "conversation_id": conversation_id
        }
        
        logger.info(f"[INSIGHTS_SERVICE] Executing SQL query [conversation_id: {conversation_id}]")
        logger.debug(f"[INSIGHTS_SERVICE] SQL: {sql[:200]}...")
        
        response = requests.post(
            f"{API_BASE}/insights/execute-sql",
            json=payload,
            timeout=SQL_TIMEOUT
        )
        response.raise_for_status()
        
        sql_response = response.json()
        
        # Validate response structure
        if not isinstance(sql_response, dict):
            raise ValueError("Invalid SQL execution response structure")
        
        required_fields = ['columns', 'data', 'row_count']
        for field in required_fields:
            if field not in sql_response:
                raise ValueError(f"Missing required field '{field}' in SQL response")
        
        # Generate a simple execution ID if not provided
        execution_id = sql_response.get('query_hash') or f"exec_{int(time.time())}"
        row_count = sql_response.get('row_count', len(sql_response.get('data', [])))
        column_count = len(sql_response.get('columns', []))
        
        logger.info(f"[INSIGHTS_SERVICE] Successfully executed SQL [execution_id: {execution_id}]")
        logger.info(f"[INSIGHTS_SERVICE] Results: {row_count} rows, {column_count} columns")
        
        # Create structured result data using schemas
        result_data = ResultData.from_api_response(sql_response)
        result_data.execution_id = execution_id
        
        # Add execution_id to response for compatibility and enhanced data
        sql_response['execution_id'] = execution_id
        sql_response['enhanced_data'] = result_data.to_dict()
        
        return sql_response
        
    except requests.Timeout:
        logger.error("[INSIGHTS_SERVICE] Timeout while executing SQL query")
        raise requests.RequestException("Request timeout while executing SQL")
        
    except requests.ConnectionError:
        logger.error("[INSIGHTS_SERVICE] Connection error while executing SQL query")
        raise requests.RequestException("Cannot connect to Insights API")
        
    except requests.HTTPError as e:
        error_msg = f"API returned error {e.response.status_code} for SQL execution"
        logger.error(f"[INSIGHTS_SERVICE] {error_msg}")
        
        # Try to extract error details from response
        try:
            error_details = e.response.json()
            if isinstance(error_details, dict) and 'detail' in error_details:
                error_msg += f": {error_details['detail']}"
        except:
            pass
        
        raise requests.RequestException(error_msg)
        
    except ValueError as e:
        logger.error(f"[INSIGHTS_SERVICE] Invalid SQL or response data: {str(e)}")
        raise ValueError(f"Invalid SQL or data: {str(e)}")
        
    except Exception as e:
        logger.error(f"[INSIGHTS_SERVICE] Unexpected error executing SQL: {str(e)}", exc_info=True)
        raise requests.RequestException(f"Unexpected error: {str(e)}")


def submit_feedback(request_id: str, positive: bool, message: Optional[str] = None) -> Dict[str, Any]:
    """
    Submit user feedback for a Cortex Analyst request.
    
    Allows users to provide positive or negative feedback with optional
    detailed comments to improve response quality.
    
    Args:
        request_id (str): Request identifier from analyst response
        positive (bool): True for positive feedback, False for negative
        message (Optional[str]): Optional detailed feedback message
        
    Returns:
        Dict[str, Any]: Feedback submission confirmation
        
    Raises:
        requests.RequestException: If API connection fails
        ValueError: If input validation fails
    """
    try:
        # Validate inputs
        if not request_id or not isinstance(request_id, str):
            raise ValueError("Request ID must be a non-empty string")
        
        if not isinstance(positive, bool):
            raise ValueError("Positive feedback flag must be a boolean")
        
        # Prepare request payload
        payload = {
            "request_id": request_id,
            "positive": positive
        }
        
        # Add message if provided (API expects 'feedback_message' field)
        if message and isinstance(message, str) and message.strip():
            payload["feedback_message"] = message.strip()
        
        logger.info(f"[INSIGHTS_SERVICE] Submitting {'positive' if positive else 'negative'} feedback for request: {request_id}")
        logger.debug(f"[INSIGHTS_SERVICE] Payload being sent: {payload}")
        if message:
            logger.debug(f"[INSIGHTS_SERVICE] Feedback message: {message[:100]}...")
        
        response = requests.post(
            f"{API_BASE}/insights/feedback",
            json=payload,
            timeout=DEFAULT_TIMEOUT
        )
        response.raise_for_status()
        
        feedback_response = response.json()
        
        # Validate response structure
        if not isinstance(feedback_response, dict):
            raise ValueError("Invalid feedback response structure")
        
        if 'feedback_id' not in feedback_response:
            raise ValueError("Missing feedback_id in response")
        
        feedback_id = feedback_response['feedback_id']
        logger.info(f"[INSIGHTS_SERVICE] Successfully submitted feedback [feedback_id: {feedback_id}]")
        
        return feedback_response
        
    except requests.Timeout:
        logger.error(f"[INSIGHTS_SERVICE] Timeout while submitting feedback for request: {request_id}")
        raise requests.RequestException("Request timeout while submitting feedback")
        
    except requests.ConnectionError:
        logger.error(f"[INSIGHTS_SERVICE] Connection error while submitting feedback for request: {request_id}")
        raise requests.RequestException("Cannot connect to Insights API")
        
    except requests.HTTPError as e:
        error_msg = f"API returned error {e.response.status_code} for feedback submission"
        logger.error(f"[INSIGHTS_SERVICE] {error_msg} for request: {request_id}")
        
        # Try to extract error details from response
        try:
            error_details = e.response.json()
            if isinstance(error_details, dict) and 'detail' in error_details:
                error_msg += f": {error_details['detail']}"
        except:
            pass
        
        raise requests.RequestException(error_msg)
        
    except ValueError as e:
        logger.error(f"[INSIGHTS_SERVICE] Invalid feedback data: {str(e)}")
        raise ValueError(f"Invalid feedback data: {str(e)}")
        
    except Exception as e:
        logger.error(f"[INSIGHTS_SERVICE] Unexpected error submitting feedback: {str(e)}", exc_info=True)
        raise requests.RequestException(f"Unexpected error: {str(e)}")


def get_api_health() -> Dict[str, Any]:
    """
    Check Insights API health and connectivity.
    
    Performs a health check to verify the Insights API is accessible
    and functioning properly.
    
    Returns:
        Dict[str, Any]: API health status and information
        
    Raises:
        requests.RequestException: If API is not accessible
    """
    try:
        logger.debug("[INSIGHTS_SERVICE] Checking API health")
        
        response = requests.get(
            f"{API_BASE}/insights/health",
            timeout=(5, 10)  # Short timeout for health check
        )
        response.raise_for_status()
        
        health_data = response.json()
        
        logger.info("[INSIGHTS_SERVICE] API health check successful")
        return health_data
        
    except requests.Timeout:
        logger.error("[INSIGHTS_SERVICE] Timeout during API health check")
        raise requests.RequestException("API health check timeout")
        
    except requests.ConnectionError:
        logger.error("[INSIGHTS_SERVICE] Connection error during API health check")
        raise requests.RequestException("Cannot connect to Insights API")
        
    except requests.HTTPError as e:
        logger.error(f"[INSIGHTS_SERVICE] API health check failed: {e.response.status_code}")
        raise requests.RequestException(f"API health check failed: {e.response.status_code}")
        
    except Exception as e:
        logger.error(f"[INSIGHTS_SERVICE] Unexpected error during health check: {str(e)}", exc_info=True)
        raise requests.RequestException(f"Health check error: {str(e)}")


def format_error_message(error: Exception, context: str = "") -> str:
    """
    Format error messages for user-friendly display.
    
    Converts technical error messages into user-friendly text while
    preserving important information for debugging.
    
    Args:
        error (Exception): The exception that occurred
        context (str): Context about what operation failed
        
    Returns:
        str: User-friendly error message
    """
    if isinstance(error, requests.Timeout):
        return f"Request timed out{f' while {context}' if context else ''}. Please try again."
        
    elif isinstance(error, requests.ConnectionError):
        return f"Cannot connect to the service{f' while {context}' if context else ''}. Please check your connection."
        
    elif isinstance(error, requests.HTTPError):
        status_code = getattr(error.response, 'status_code', 'unknown')
        if status_code == 404:
            return f"The requested resource was not found{f' while {context}' if context else ''}."
        elif status_code == 400:
            return f"Invalid request{f' while {context}' if context else ''}. Please check your input."
        elif status_code == 500:
            return f"Server error{f' while {context}' if context else ''}. Please try again later."
        else:
            return f"Server returned error {status_code}{f' while {context}' if context else ''}."
            
    elif isinstance(error, ValueError):
        return f"Invalid data{f' while {context}' if context else ''}: {str(error)}"
        
    else:
        return f"An unexpected error occurred{f' while {context}' if context else ''}. Please try again."


# Cache for domain data to reduce API calls
_domain_cache = {}
_cache_timeout = 300  # 5 minutes cache timeout


def get_cached_domains() -> Optional[Dict[str, Any]]:
    """
    Get cached domain data if available and not expired.
    
    Returns:
        Optional[Dict[str, Any]]: Cached domain data or None if expired/missing
    """
    current_time = time.time()
    cache_entry = _domain_cache.get('domains')
    
    if cache_entry and (current_time - cache_entry['timestamp']) < _cache_timeout:
        logger.debug("[INSIGHTS_SERVICE] Using cached domain data")
        return cache_entry['data']
    
    return None


def cache_domains(domains_data: Dict[str, Any]) -> None:
    """
    Cache domain data with timestamp.
    
    Args:
        domains_data (Dict[str, Any]): Domain data to cache
    """
    _domain_cache['domains'] = {
        'data': domains_data,
        'timestamp': time.time()
    }
    logger.debug("[INSIGHTS_SERVICE] Cached domain data")


def clear_domain_cache() -> None:
    """Clear the domain cache."""
    _domain_cache.clear()


def prepare_chart_data(query_result: Dict[str, Any], 
                      chart_type: str = None,
                      title: str = None) -> Dict[str, Any]:
    """
    Prepare chart data from SQL query results using Plotly.
    
    Args:
        query_result: Query result from execute_sql_query
        chart_type: Optional chart type override
        title: Optional chart title
        
    Returns:
        Dict containing chart HTML and metadata
    """
    try:
        logger.info("[INSIGHTS_SERVICE] Preparing chart data from query results")
        
        # Generate chart using the charts module
        chart_result = generate_chart_from_query_result(
            query_result=query_result,
            chart_type=chart_type,
            title=title
        )
        
        # Add chart recommendations if chart generation was successful
        if chart_result.get('success'):
            data = query_result.get('data', [])
            recommendations = get_chart_recommendations(data)
            chart_result['recommendations'] = recommendations
        
        logger.info(f"[INSIGHTS_SERVICE] Chart preparation {'successful' if chart_result.get('success') else 'failed'}")
        return chart_result
        
    except Exception as e:
        logger.error(f"[INSIGHTS_SERVICE] Error preparing chart data: {e}")
        return {
            'html': f'<div class="chart-error">Error preparing chart: {str(e)}</div>',
            'type': 'error',
            'success': False,
            'error': str(e),
            'recommendations': []
        }


def execute_sql_with_charts(sql: str, 
                           conversation_id: Optional[str] = None,
                           chart_type: str = None,
                           generate_charts: bool = True) -> Dict[str, Any]:
    """
    Execute SQL query and generate charts if requested.
    
    Args:
        sql: SQL query to execute
        conversation_id: Optional conversation identifier
        chart_type: Optional chart type preference
        generate_charts: Whether to generate chart visualizations
        
    Returns:
        Dict containing query results and chart data
    """
    try:
        # Execute the SQL query first
        sql_result = execute_sql_query(sql, conversation_id)
        
        # Add chart data if requested and results contain data
        if generate_charts and sql_result.get('data'):
            chart_result = prepare_chart_data(
                query_result=sql_result,
                chart_type=chart_type,
                title=f"Results for Query {sql_result.get('execution_id', '')}"
            )
            sql_result['chart'] = chart_result
        
        return sql_result
        
    except Exception as e:
        logger.error(f"[INSIGHTS_SERVICE] Error executing SQL with charts: {e}")
        raise


def get_example_questions(domain: str, count: int = 3) -> List[str]:
    """
    Get random example questions for a specific domain from the API.
    
    Fetches example questions configured for the domain to help users
    get started with natural language queries.
    
    Args:
        domain: Domain key (e.g., 'policy', 'claims', 'others')
        count: Number of questions to return (default: 3)
        
    Returns:
        List[str]: List of example questions
        
    Raises:
        requests.RequestException: If API connection fails
        ValueError: If API response is invalid or domain not found
    """
    try:
        logger.info(f"[INSIGHTS_SERVICE] Fetching {count} example questions for domain '{domain}'")
        
        response = requests.get(
            f"{API_BASE}/insights/domains/{domain}/example-questions",
            params={'count': count},
            timeout=DEFAULT_TIMEOUT
        )
        response.raise_for_status()
        
        api_response = response.json()
        
        # Validate response structure
        if not isinstance(api_response, dict):
            raise ValueError("Invalid API response structure")
        
        if 'example_questions' not in api_response:
            raise ValueError("Missing 'example_questions' field in API response")
        
        questions = api_response.get('example_questions', [])
        
        logger.info(f"[INSIGHTS_SERVICE] Retrieved {len(questions)} example questions for domain '{domain}'")
        return questions
        
    except requests.RequestException as e:
        logger.error(f"[INSIGHTS_SERVICE] API error fetching example questions for '{domain}': {e}")
        raise
    except Exception as e:
        logger.error(f"[INSIGHTS_SERVICE] Unexpected error fetching example questions: {e}")
        raise
    logger.debug("[INSIGHTS_SERVICE] Cleared domain cache")