"""
Insights AI Services Module

This module contains the core business logic for Cortex Analyst integration
and provides services for:
- Semantic view domain management
- Natural language query processing with Cortex Analyst
- SQL execution and result formatting
- Conversation history management
- User feedback submission
"""

import os
import json
import time
import uuid
import hashlib
import requests
from typing import List, Dict, Any, Optional, Tuple
from datetime import datetime

from app.utils.database import get_sf_conn
from app.utils.logging import logger
from app.modules.insights.config_loader import (
    get_semantic_domains, 
    get_snowflake_config, 
    get_api_config,
    get_complete_snowflake_config,
    get_domain_config,
    get_domain_specific_config,
    get_domain_examples,
    get_semantic_view_metadata,
    get_models_for_domain
)
from app.modules.insights.schemas import (
    ConversationMessage,
    MessageContent,
    ContentType,
    MessageRole,
    SemanticModel
)


class InsightsService:
    """
    Core service class for Insights AI functionality.
    
    Handles Cortex Analyst integration, domain management,
    SQL execution, and conversation tracking.
    """
    
    def __init__(self):
        """Initialize the service with configuration."""
        self.domains = get_semantic_domains()
        self.snowflake_config = get_snowflake_config()
        self.api_config = get_api_config()
        self.domain_config = get_domain_config()
        self.account = os.getenv('SF_ACCOUNT')
        
        # API configuration
        self.max_history_length = self.api_config.get('max_history_length', 10)
        self.max_history_tokens = self.api_config.get('max_history_tokens', 32000)
        self.api_timeout_ms = self.api_config.get('api_timeout_ms', 50000)
        self.conversation_id_prefix = self.api_config.get('conversation_id_prefix', 'insights_conv_')
        
        # Cortex Analyst API endpoints
        self.cortex_message_url = f"https://{self.account}.snowflakecomputing.com/api/v2/cortex/analyst/message"
        self.cortex_feedback_url = f"https://{self.account}.snowflakecomputing.com/api/v2/cortex/analyst/feedback"
        
        logger.info("InsightsService initialized with Cortex Analyst integration")

    def _is_session_expired_error(self, response_data: Dict[str, Any]) -> bool:
        """
        Check if the response indicates a session expiration error.
        
        Args:
            response_data: API response data
            
        Returns:
            bool: True if session has expired
        """
        if not isinstance(response_data, dict):
            return False
            
        error_code = response_data.get("code") or response_data.get("error_code")
        message_field = response_data.get("message", "")
        
        # Handle message field that could be string or dict
        if isinstance(message_field, str):
            error_message = message_field.lower()
        elif isinstance(message_field, dict):
            # If message is a dict, check for text content
            error_message = str(message_field).lower()
        else:
            error_message = str(message_field).lower()
        
        # Check for specific session expiration indicators
        session_expired_codes = ["390111"]
        session_expired_messages = [
            "session no longer exists", 
            "new login required", 
            "session expired",
            "authentication failed"
        ]
        
        if error_code in session_expired_codes:
            return True
            
        for msg in session_expired_messages:
            if msg in error_message:
                return True
                
        return False

    def _verify_cortex_analyst_configuration(self) -> Tuple[bool, str]:
        """
        Verify if Cortex Analyst is properly configured.
        
        Returns:
            Tuple[bool, str]: (is_configured, error_message)
        """
        try:
            conn, cursor = get_sf_conn()
            
            # Test basic Cortex AI access
            try:
                cursor.execute("SELECT SNOWFLAKE.CORTEX.COMPLETE('claude-4-sonnet', 'test')")
                logger.debug("Cortex AI functions are accessible")
            except Exception as e:
                error_msg = f"Cortex AI functions not available: {str(e)[:100]}"
                cursor.close()
                conn.close()
                return False, error_msg
            
            # Test basic schema access (don't validate specific views here)
            try:
                cursor.execute(f"USE DATABASE {self.snowflake_config.get('database')}")
                cursor.execute(f"USE SCHEMA {self.snowflake_config.get('schema')}")
                logger.debug("Database and schema access validated")
            except Exception as e:
                error_msg = f"Database/schema access failed: {str(e)[:100]}"
                cursor.close()
                conn.close()
                return False, error_msg
                
            cursor.close()
            conn.close()
            return True, "Configuration verified"
            
        except Exception as e:
            return False, f"Configuration check failed: {str(e)[:100]}"

    def get_semantic_domains(self) -> Dict[str, Any]:
        """
        Get all available semantic view domains with their metadata.
        
        Returns:
            Dict: Domains organized by key with names, descriptions, and model counts
        """
        logger.info("Retrieving semantic view domains")
        
        domains_info = {}
        for domain_key, domain_data in self.domains.items():
            domains_info[domain_key] = {
                "key": domain_key,
                "name": domain_data.get("name"),
                "description": domain_data.get("description"),
                "model_count": len(domain_data.get("models", [])),
                "models": domain_data.get("models", [])
            }
        
        logger.info(f"Retrieved {len(domains_info)} semantic domains")
        return domains_info

    def get_models_by_domain(self, domain: str) -> Dict[str, Any]:
        """
        Get semantic views for a specific domain.
        
        Args:
            domain: Domain key (configured in semantic_view_domains)
            
        Returns:
            Dict: Domain information with available semantic views
            
        Raises:
            ValueError: If domain doesn't exist
        """
        logger.info(f"Retrieving models for domain: {domain}")
        
        if domain not in self.domains:
            available_domains = list(self.domains.keys())
            raise ValueError(f"Domain '{domain}' not found. Available domains: {available_domains}")
        
        domain_data = self.domains[domain]
        result = {
            "domain": domain,
            "name": domain_data.get("name"),
            "description": domain_data.get("description"),
            "models": []
        }
        
        # Get models using the new config structure
        models = get_models_for_domain(domain)
        
        for view_path in models:
            # Get metadata from configuration instead of string manipulation
            metadata = get_semantic_view_metadata(domain, view_path)
            
            if metadata:
                # Use configured display name and description
                result["models"].append({
                    "name": metadata["display_name"],
                    "path": view_path,
                    "full_path": view_path,  # Semantic views don't need @ prefix
                    "description": metadata.get("description", ""),
                    "is_default": metadata.get("is_default", False)
                })
            else:
                # Fallback for missing metadata (should not happen with proper config)
                logger.warning(f"Missing metadata for semantic view {view_path} in domain {domain}")
                fallback_name = view_path.split(".")[-1].replace("SV_", "").replace("_", " ").title()
                result["models"].append({
                    "name": fallback_name,
                    "path": view_path,
                    "full_path": view_path,
                    "description": f"Semantic view for {domain} analytics",
                    "is_default": False
                })
        
        logger.info(f"Retrieved {len(result['models'])} models for domain '{domain}'")
        return result

    def validate_domain(self, domain: str) -> bool:
        """
        Check if a domain exists in the configuration.
        
        Args:
            domain: Domain key to validate
            
        Returns:
            bool: True if domain exists, False otherwise
        """
        return domain in self.domains

    def get_default_model(self, domain: str) -> Optional[str]:
        """
        Get the default semantic view for a domain.
        
        Uses domain-specific configuration if available, otherwise falls back to first model.
        
        Args:
            domain: Domain key
            
        Returns:
            Optional[str]: Default model path or None if no models
        """
        if domain not in self.domains:
            return None
        
        # Try to get configured default model first
        domain_specific_config = get_domain_specific_config(domain)
        default_model = domain_specific_config.get("default_model")
        
        if default_model:
            # Verify the configured default model exists in domain models
            domain_models = self.domains[domain].get("models", [])
            if default_model in domain_models:
                return default_model
            else:
                logger.warning(f"Configured default model '{default_model}' not found in domain '{domain}' models")
        
        # Fall back to first available model
        models = self.domains[domain].get("models", [])
        return models[0] if models else None

    def generate_conversation_id(self) -> str:
        """
        Generate a unique conversation ID for request tracking.
        
        Returns:
            str: Unique conversation ID with timestamp and random component
        """
        timestamp = int(time.time())
        random_part = str(uuid.uuid4())[:8]
        conversation_id = f"{self.conversation_id_prefix}{timestamp}_{random_part}"
        
        logger.debug(f"Generated conversation ID: {conversation_id}")
        return conversation_id

    def truncate_message_history(self, messages: List[ConversationMessage], max_length: Optional[int] = None) -> List[ConversationMessage]:
        """
        Truncate message history to stay within token limits.
        
        Args:
            messages: List of conversation messages
            max_length: Maximum number of messages (uses config default if None)
            
        Returns:
            List[ConversationMessage]: Truncated message history
        """
        if max_length is None:
            max_length = self.max_history_length
            
        if len(messages) <= max_length:
            return messages
        
        # Keep the most recent messages
        truncated = messages[-max_length:]
        logger.info(f"Truncated message history from {len(messages)} to {len(truncated)} messages")
        
        return truncated

    def _get_auth_headers(self, force_new_connection: bool = False) -> Dict[str, str]:
        """
        Get authentication headers for Cortex Analyst API requests.
        
        Enhanced version with multiple fallback methods and better error handling.
        
        Args:
            force_new_connection: If True, forces creation of a new connection
        
        Returns:
            Dict[str, str]: Headers with authentication token
            
        Raises:
            Exception: If token extraction fails
        """
        try:
            # Get Snowflake connection
            # Note: force_new_connection parameter is for future use when connection pooling is implemented
            if force_new_connection:
                logger.debug("Requesting fresh connection for authentication")
                
            conn, cursor = get_sf_conn()
            cursor.close()  # Close cursor immediately as we only need connection
            
            # Log connector version for debugging
            connector_version = getattr(conn, 'version', 'unknown')
            logger.debug(f"Snowflake connector version: {connector_version}")
            
            # Extract session token with multiple fallback methods
            token = None
            extraction_method = None
            
            # Method 1: Standard _rest._token_request approach
            if not token:
                try:
                    if hasattr(conn, '_rest') and hasattr(conn._rest, '_token_request'):
                        token_response = conn._rest._token_request("ISSUE")
                        if isinstance(token_response, dict) and "data" in token_response:
                            token = token_response["data"]["sessionToken"]
                            extraction_method = "_rest._token_request"
                            logger.debug("Successfully extracted token using _rest._token_request method")
                except (AttributeError, KeyError, TypeError) as e:
                    logger.debug(f"Method 1 (_rest._token_request) failed: {e}")
            
            # Method 2: Direct get_session_token method
            if not token:
                try:
                    if hasattr(conn, 'get_session_token'):
                        token = conn.get_session_token()
                        extraction_method = "get_session_token"
                        logger.debug("Successfully extracted token using get_session_token method")
                except (AttributeError, TypeError) as e:
                    logger.debug(f"Method 2 (get_session_token) failed: {e}")
            
            # Method 3: Connection object token attribute
            if not token:
                try:
                    if hasattr(conn, '_connection') and hasattr(conn._connection, '_token'):
                        token = conn._connection._token
                        extraction_method = "_connection._token"
                        logger.debug("Successfully extracted token using _connection._token method")
                except (AttributeError, TypeError) as e:
                    logger.debug(f"Method 3 (_connection._token) failed: {e}")
            
            # Method 4: Try accessing token via rest client
            if not token:
                try:
                    if hasattr(conn, '_rest') and hasattr(conn._rest, 'token'):
                        token = conn._rest.token
                        extraction_method = "_rest.token"
                        logger.debug("Successfully extracted token using _rest.token method")
                except (AttributeError, TypeError) as e:
                    logger.debug(f"Method 4 (_rest.token) failed: {e}")
            
            # Method 5: Check for session token in connection
            if not token:
                try:
                    if hasattr(conn, '_session_token'):
                        token = conn._session_token
                        extraction_method = "_session_token"
                        logger.debug("Successfully extracted token using _session_token method")
                except (AttributeError, TypeError) as e:
                    logger.debug(f"Method 5 (_session_token) failed: {e}")
            
            # Validate token was extracted
            if not token:
                error_msg = f"All token extraction methods failed for connector version {connector_version}"
                logger.error(error_msg)
                raise Exception(error_msg)
            
            # Validate token format
            if not isinstance(token, str) or len(token) < 10:
                raise Exception(f"Invalid token format extracted via {extraction_method}")
            
            # Create headers
            headers = {
                "Authorization": f'Snowflake Token="{token}"',
                "Content-Type": "application/json",
                "User-Agent": "InsightsAI/1.0.0",
                "X-Snowflake-Service": "cortex-analyst"
            }
            
            # Log token info (masked for security)
            token_preview = f"{token[:10]}...{token[-10:]}" if len(token) > 20 else "***REDACTED***"
            logger.info(f"Authentication token extracted successfully using method: {extraction_method}, token preview: {token_preview}")
            
            if force_new_connection:
                logger.info("Fresh connection token obtained for retry")
            
            return headers
            
        except Exception as e:
            logger.error(f"Failed to get authentication headers: {e}")
            raise Exception(f"Authentication failed: {e}")
        # Note: Not closing connection here to keep session token valid

    def _prepare_messages_for_api(self, messages: List[ConversationMessage]) -> List[Dict[str, Any]]:
        """
        Convert ConversationMessage objects to API format with enhanced validation.
        
        Args:
            messages: List of conversation messages
            
        Returns:
            List[Dict]: Messages in Cortex Analyst API format
        """
        api_messages = []
        total_content_length = 0
        
        for message_idx, message in enumerate(messages):
            try:
                api_message = {
                    "role": message.role.value,
                    "content": []
                }
                
                for content_idx, content in enumerate(message.content):
                    content_item = {"type": content.type.value}
                    content_length = 0
                    
                    if content.type == ContentType.TEXT and content.text:
                        content_item["text"] = content.text
                        content_length = len(content.text)
                    elif content.type == ContentType.SQL and content.statement:
                        content_item["statement"] = content.statement
                        content_length = len(content.statement)
                    elif content.type == ContentType.SUGGESTIONS and content.suggestions:
                        content_item["suggestions"] = content.suggestions
                        content_length = sum(len(suggestion) for suggestion in content.suggestions)
                    
                    # Track total content for token management
                    total_content_length += content_length
                    
                    # Only add content items that have actual content
                    if any(key in content_item for key in ["text", "statement", "suggestions"]):
                        api_message["content"].append(content_item)
                    else:
                        logger.warning(f"Empty content item in message {message_idx}, content {content_idx}")
                
                # Only add messages that have content
                if api_message["content"]:
                    api_messages.append(api_message)
                else:
                    logger.warning(f"Message {message_idx} has no valid content, skipping")
                    
            except Exception as e:
                logger.error(f"Error processing message {message_idx}: {e}")
                continue
        
        # Log token estimation
        estimated_tokens = total_content_length / 4  # Rough estimation: 4 chars per token
        logger.debug(f"Prepared {len(api_messages)} messages with ~{estimated_tokens:.0f} estimated tokens")
        
        # Warn if approaching token limits
        if estimated_tokens > self.max_history_tokens * 0.8:
            logger.warning(f"Message history approaching token limit: {estimated_tokens:.0f}/{self.max_history_tokens}")
        
        return api_messages

    def _estimate_token_count(self, text: str) -> int:
        """
        Estimate token count for text (rough approximation).
        
        Args:
            text: Text to estimate tokens for
            
        Returns:
            int: Estimated token count
        """
        # Rough estimation: ~4 characters per token for English text
        return max(1, len(text) // 4)

    def _validate_api_response(self, response_data: Dict[str, Any]) -> bool:
        """
        Validate Cortex Analyst API response structure.
        
        Args:
            response_data: API response data
            
        Returns:
            bool: True if response is valid
        """
        try:
            # Check for error responses first
            if isinstance(response_data, dict):
                # Check for session expiration or other error codes
                error_code = response_data.get("code") or response_data.get("error_code")
                if error_code:
                    error_message = response_data.get('message', 'No message')
                    if self._is_session_expired_error(response_data):
                        logger.warning(f"Session expired detected in validation - code: {error_code}, message: {error_message}")
                    else:
                        logger.error(f"API returned error code: {error_code}, message: {error_message}")
                    return False
            
            # Check required top-level fields
            if "message" not in response_data:
                logger.error("API response missing 'message' field")
                return False
            
            message = response_data["message"]
            
            # Check message structure
            if "content" not in message:
                logger.error("API response message missing 'content' field")
                return False
            
            content_list = message["content"]
            if not isinstance(content_list, list):
                logger.error("API response content is not a list")
                return False
            
            # Validate content items
            valid_content_types = ["text", "sql", "suggestions"]
            for idx, content_item in enumerate(content_list):
                if not isinstance(content_item, dict):
                    logger.error(f"Content item {idx} is not a dictionary")
                    return False
                
                if "type" not in content_item:
                    logger.error(f"Content item {idx} missing 'type' field")
                    return False
                
                content_type = content_item["type"]
                if content_type not in valid_content_types:
                    logger.warning(f"Content item {idx} has unknown type: {content_type}")
                
                # Validate type-specific fields
                if content_type == "text" and "text" not in content_item:
                    logger.error(f"Text content item {idx} missing 'text' field")
                    return False
                elif content_type == "sql" and "statement" not in content_item:
                    logger.error(f"SQL content item {idx} missing 'statement' field")  
                    return False
                elif content_type == "suggestions" and "suggestions" not in content_item:
                    logger.error(f"Suggestions content item {idx} missing 'suggestions' field")
                    return False
            
            logger.debug("API response validation passed")
            return True
            
        except Exception as e:
            logger.error(f"Error validating API response: {e}")
            return False

    def process_analyst_query(self, 
                            question: str, 
                            semantic_view: str,
                            domain: Optional[str] = None, 
                            history: Optional[List[ConversationMessage]] = None) -> Dict[str, Any]:
        """
        Process a natural language question using Cortex Analyst.
        
        Args:
            question: Natural language question
            semantic_view: Semantic view name (required for Cortex Analyst)
            domain: Domain key for categorization (optional)
            history: Previous conversation history
            
        Returns:
            Dict: Cortex Analyst response with parsed content, warnings, and request_id
            
        Raises:
            Exception: If API request fails or semantic view is invalid
        """
        start_time = time.time()
        conversation_id = self.generate_conversation_id()
        
        logger.info(f"Processing analyst query: '{question[:100]}...' with semantic view: {semantic_view} [conversation_id: {conversation_id}]")
        
        # Verify Cortex Analyst configuration before proceeding
        config_ok, config_error = self._verify_cortex_analyst_configuration()
        if not config_ok:
            raise ValueError(f"Cortex Analyst configuration error: {config_error}. Please run diagnose_cortex_access.py for detailed information.")
        
        try:
            # Validate semantic view
            if not semantic_view:
                raise ValueError("Semantic view name is required for Cortex Analyst")
                
            # Validate access to specific semantic view
            has_access, access_error = self.validate_semantic_view_access(semantic_view)
            if not has_access:
                raise ValueError(access_error)
            
            # Enhanced message history processing
            messages = []
            conversation_context = {}
            
            if history:
                # Generate context summary for logging
                conversation_context = self.get_conversation_context_summary(history)
                logger.debug(f"Conversation context: {conversation_context}")
                
                # Optimize history for token limits
                optimized_history = self.optimize_message_history_for_tokens(history)
                
                # Convert to API format
                messages.extend(self._prepare_messages_for_api(optimized_history))
                
                logger.info(f"Processed conversation history: {len(optimized_history)}/{len(history)} messages, ~{conversation_context.get('estimated_tokens', 0)} tokens")
            
            # Add current question
            messages.append({
                "role": "user",
                "content": [{"type": "text", "text": question}]
            })
            
            # Prepare API request
            headers = self._get_auth_headers()
            
            request_body = {
                "messages": messages,
                "semantic_view": semantic_view
            }
            
            logger.debug(f"Cortex Analyst API request: {json.dumps(request_body, indent=2)}")
            
            # Log request details
            logger.info(f"Sending request to Cortex Analyst: {len(messages)} messages, semantic view: {semantic_view}")
            logger.debug(f"Request URL: {self.cortex_message_url}")
            logger.debug(f"Request body: {json.dumps(request_body, indent=2)}")
            logger.debug(f"Authentication header present: {'Authorization' in headers}")
            
            # Store original headers for potential retry
            original_headers = headers.copy()
            
            # Make API request with enhanced error handling
            timeout_seconds = self.api_timeout_ms / 1000
            
            try:
                response = requests.post(
                    self.cortex_message_url,
                    json=request_body,
                    headers=headers,
                    timeout=timeout_seconds
                )
                
                # Log response details
                logger.debug(f"API Response Status: {response.status_code}")
                logger.debug(f"API Response Headers: {dict(response.headers)}")
                
            except requests.exceptions.Timeout:
                processing_time = time.time() - start_time
                error_msg = f"Cortex Analyst API timeout after {timeout_seconds}s"
                logger.error(f"{error_msg} [conversation_id: {conversation_id}, time: {processing_time:.2f}s]")
                raise Exception(error_msg)
            except requests.exceptions.ConnectionError as e:
                processing_time = time.time() - start_time
                error_msg = f"Cortex Analyst API connection error: {e}"
                logger.error(f"{error_msg} [conversation_id: {conversation_id}, time: {processing_time:.2f}s]")
                raise Exception(error_msg)
            except requests.exceptions.RequestException as e:
                processing_time = time.time() - start_time
                error_msg = f"Cortex Analyst API request error: {e}"
                logger.error(f"{error_msg} [conversation_id: {conversation_id}, time: {processing_time:.2f}s]")
                raise Exception(error_msg)
            
            processing_time = time.time() - start_time
            
            # Enhanced error handling for different status codes
            if response.status_code == 401:
                error_msg = "Authentication failed - check Snowflake credentials and Cortex Analyst permissions"
                logger.error(f"{error_msg} [conversation_id: {conversation_id}]")
                raise Exception(error_msg)
            elif response.status_code == 403:
                error_msg = "Access forbidden - insufficient Cortex Analyst permissions"
                logger.error(f"{error_msg} [conversation_id: {conversation_id}]")
                raise Exception(error_msg)
            elif response.status_code == 404:
                error_msg = "Cortex Analyst API endpoint not found - check service availability"
                logger.error(f"{error_msg} [conversation_id: {conversation_id}]")
                raise Exception(error_msg)
            elif response.status_code == 429:
                error_msg = "Rate limit exceeded - too many requests to Cortex Analyst"
                logger.error(f"{error_msg} [conversation_id: {conversation_id}]")
                raise Exception(error_msg)
            elif response.status_code >= 500:
                error_msg = f"Cortex Analyst server error: {response.status_code} - {response.text[:200]}"
                logger.error(f"{error_msg} [conversation_id: {conversation_id}]")
                raise Exception(error_msg)
            elif response.status_code != 200:
                error_msg = f"Cortex Analyst API error: {response.status_code} - {response.text[:200]}"
                logger.error(f"{error_msg} [conversation_id: {conversation_id}]")
                raise Exception(error_msg)
            
            # Parse JSON response
            try:
                api_response = response.json()
                logger.info(f"Cortex Analyst API response structure: {json.dumps(api_response, indent=2)}")
            except json.JSONDecodeError as e:
                error_msg = f"Invalid JSON response from Cortex Analyst: {e}"
                logger.error(f"{error_msg} [conversation_id: {conversation_id}]")
                raise Exception(error_msg)
            
            # Check for session expiration error before validating response structure
            if self._is_session_expired_error(api_response):
                # Session expired - attempt re-authentication once
                error_code = api_response.get("code") or api_response.get("error_code", "unknown")
                logger.warning(f"Session expired (code {error_code}), attempting re-authentication [conversation_id: {conversation_id}]")
                
                try:
                    logger.info(f"Starting re-authentication process [conversation_id: {conversation_id}]")
                    retry_start_time = time.time()
                    
                    # Get fresh authentication headers with forced new connection
                    fresh_headers = self._get_auth_headers(force_new_connection=True)
                    
                    logger.info(f"Fresh authentication headers obtained, retrying request [conversation_id: {conversation_id}]")
                    
                    # Retry the request with fresh token
                    retry_response = requests.post(
                        self.cortex_message_url,
                        json=request_body,
                        headers=fresh_headers,
                        timeout=timeout_seconds
                    )
                    
                    retry_duration = time.time() - retry_start_time
                    logger.info(f"Retry request completed in {retry_duration:.2f}s, status: {retry_response.status_code} [conversation_id: {conversation_id}]")
                    
                    # Check retry response status
                    if retry_response.status_code == 200:
                        try:
                            retry_api_response = retry_response.json()
                            logger.info(f"Retry response received: {json.dumps(retry_api_response, indent=2)} [conversation_id: {conversation_id}]")
                            
                            # Check if the retry response still has session errors
                            # This can happen if there are persistent authentication issues
                            if self._is_session_expired_error(retry_api_response):
                                # Try one more time with a small delay to ensure token propagation
                                logger.warning(f"Retry still shows session expired, attempting final retry with delay [conversation_id: {conversation_id}]")
                                
                                import time as time_module
                                time_module.sleep(2)  # Small delay for token propagation
                                
                                # Get completely fresh headers
                                final_headers = self._get_auth_headers(force_new_connection=True)
                                
                                final_response = requests.post(
                                    self.cortex_message_url,
                                    json=request_body,
                                    headers=final_headers,
                                    timeout=timeout_seconds
                                )
                                
                                if final_response.status_code == 200:
                                    final_api_response = final_response.json()
                                    logger.info(f"Final retry response: {json.dumps(final_api_response, indent=2)} [conversation_id: {conversation_id}]")
                                    
                                    if self._is_session_expired_error(final_api_response):
                                        error_msg = ("Persistent session expiration after multiple re-authentication attempts. "
                                                   "This indicates a Snowflake account configuration issue. "
                                                   "Please verify: 1) Cortex AI is enabled, 2) User has CORTEX_ANALYST_USER role, "
                                                   "3) Semantic views are accessible. Run diagnose_cortex_access.py for details.")
                                        logger.error(f"{error_msg} [conversation_id: {conversation_id}]")
                                        raise Exception(error_msg)
                                    else:
                                        retry_api_response = final_api_response
                                        retry_response = final_response
                                        logger.info(f"Final retry successful [conversation_id: {conversation_id}]")
                                else:
                                    error_msg = f"Final retry failed: {final_response.status_code} - {final_response.text[:200]}"
                                    logger.error(f"{error_msg} [conversation_id: {conversation_id}]")
                                    raise Exception(error_msg)
                            
                            api_response = retry_api_response
                            logger.info(f"Successfully re-authenticated and retried request [conversation_id: {conversation_id}]")
                            logger.debug(f"Retry API response structure: {json.dumps(api_response, indent=2)}")
                            response = retry_response  # Use the successful retry response
                            
                        except json.JSONDecodeError as e:
                            error_msg = f"Invalid JSON response from Cortex Analyst after retry: {e}"
                            logger.error(f"{error_msg} [conversation_id: {conversation_id}]")
                            raise Exception(error_msg)
                    else:
                        error_msg = f"Re-authentication failed: {retry_response.status_code} - {retry_response.text[:200]}"
                        logger.error(f"{error_msg} [conversation_id: {conversation_id}]")
                        raise Exception(error_msg)
                        
                except Exception as retry_error:
                    error_msg = f"Re-authentication attempt failed: {retry_error}"
                    logger.error(f"{error_msg} [conversation_id: {conversation_id}]")
                    raise Exception(error_msg)
            
            # Validate response structure
            if not self._validate_api_response(api_response):
                error_msg = "Invalid response structure from Cortex Analyst API"
                logger.error(f"{error_msg} [conversation_id: {conversation_id}]")
                logger.error(f"Actual response: {json.dumps(api_response, indent=2)}")
                raise Exception(error_msg)
            
            logger.info(f"Cortex Analyst request completed in {processing_time:.2f}s [conversation_id: {conversation_id}]")
            
            # Enhanced response parsing
            message_content = api_response.get("message", {}).get("content", [])
            warnings = api_response.get("warnings", [])
            request_id = api_response.get("request_id")
            
            # Parse and categorize content types
            content_summary = {"text": 0, "sql": 0, "suggestions": 0, "other": 0}
            sql_statements = []
            
            for item in message_content:
                content_type = item.get("type", "unknown")
                if content_type in content_summary:
                    content_summary[content_type] += 1
                else:
                    content_summary["other"] += 1
                
                # Extract SQL statements for logging
                if content_type == "sql" and "statement" in item:
                    sql_statements.append(item["statement"])
            
            # Log content analysis
            logger.info(f"Response analysis [conversation_id: {conversation_id}]: {content_summary}")
            if sql_statements:
                logger.info(f"Generated {len(sql_statements)} SQL statement(s) [conversation_id: {conversation_id}]")
                for i, sql in enumerate(sql_statements):
                    logger.debug(f"SQL {i+1}: {sql[:100]}..." if len(sql) > 100 else f"SQL {i+1}: {sql}")
            
            # Log warnings if present
            if warnings:
                logger.warning(f"Cortex Analyst warnings [conversation_id: {conversation_id}]: {warnings}")
            
            # Build enhanced response with comprehensive metrics
            parsed_response = {
                "conversation_id": conversation_id,
                "request_id": request_id,
                "content": message_content,
                "warnings": warnings,
                "processing_time_seconds": processing_time,
                "semantic_view_used": semantic_view,
                "domain": domain,
                "content_summary": content_summary,
                "sql_generated": len(sql_statements) > 0,
                "message_count": len(messages),
                "api_response_size": len(response.content),
                "success": True,
                "conversation_context": conversation_context,
                "response_metadata": {
                    "content_items": len(message_content),
                    "warning_count": len(warnings),
                    "has_sql": len(sql_statements) > 0,
                    "has_suggestions": content_summary.get("suggestions", 0) > 0,
                    "response_size_bytes": len(response.content)
                }
            }
            
            # Track comprehensive conversation metrics
            self.track_conversation_metrics(conversation_id, {
                "query_type": "cortex_analyst_query",
                "domain": domain,
                "semantic_view": semantic_view,
                "processing_time_seconds": processing_time,
                "success": True,
                "content_summary": content_summary,
                "sql_generated": len(sql_statements) > 0,
                "conversation_turns": conversation_context.get("conversation_turns", 0),
                "message_history_length": len(history) if history else 0,
                "question_length": len(question),
                "warnings_count": len(warnings),
                "response_size": len(response.content)
            })
            
            return parsed_response
            
        except Exception as e:
            processing_time = time.time() - start_time
            error_msg = f"Failed to process analyst query: {e}"
            error_type = type(e).__name__
            
            logger.error(f"{error_msg} [conversation_id: {conversation_id}, processing_time: {processing_time:.2f}s, error_type: {error_type}]")
            
            # Track error metrics
            self.track_conversation_metrics(conversation_id, {
                "query_type": "cortex_analyst_query",
                "domain": domain,
                "semantic_view": semantic_view if 'semantic_view' in locals() else None,
                "processing_time_seconds": processing_time,
                "success": False,
                "error_type": error_type,
                "error_message": str(e),
                "question_length": len(question),
                "message_history_length": len(history) if history else 0
            })
            
            # Re-raise with enhanced error information
            enhanced_error_msg = f"{error_msg} (Type: {error_type}, Time: {processing_time:.2f}s)"
            raise Exception(enhanced_error_msg)

    def process_analyst_query_v2(self, 
                               question: str, 
                               semantic_models: List[SemanticModel],
                               domain: Optional[str] = None, 
                               history: Optional[List[ConversationMessage]] = None) -> Dict[str, Any]:
        """
        Process a natural language question using Cortex Analyst with multiple semantic models.
        
        Args:
            question: Natural language question
            semantic_models: List of semantic models with semantic_view field for Cortex Analyst to choose from
            domain: Domain key for categorization (optional)
            history: Previous conversation history
            
        Returns:
            Dict: Cortex Analyst response with parsed content, warnings, and request_id
            
        Raises:
            Exception: If API request fails or semantic models are invalid
        """
        start_time = time.time()
        conversation_id = self.generate_conversation_id()
        
        semantic_model_names = [model.semantic_view for model in semantic_models]
        logger.info(f"Processing analyst query v2: '{question[:100]}...' with semantic models: {semantic_model_names} [conversation_id: {conversation_id}]")
        
        # Verify Cortex Analyst configuration before proceeding
        config_ok, config_error = self._verify_cortex_analyst_configuration()
        if not config_ok:
            raise ValueError(f"Cortex Analyst configuration error: {config_error}. Please run diagnose_cortex_access.py for detailed information.")
        
        try:
            # Validate semantic models
            if not semantic_models:
                raise ValueError("At least one semantic model is required for Cortex Analyst")
                
            # Validate access to each semantic view
            for model in semantic_models:
                semantic_view = model.semantic_view
                has_access, access_error = self.validate_semantic_view_access(semantic_view)
                if not has_access:
                    raise ValueError(f"Access error for semantic view '{semantic_view}': {access_error}")
            
            # Enhanced message history processing
            messages = []
            conversation_context = {}
            
            if history:
                # Generate context summary for logging
                conversation_context = self.get_conversation_context_summary(history)
                logger.debug(f"Conversation context: {conversation_context}")
                
                # Optimize history for token limits
                optimized_history = self.optimize_message_history_for_tokens(history)
                
                # Convert to API format
                messages.extend(self._prepare_messages_for_api(optimized_history))
                
                logger.info(f"Processed conversation history: {len(optimized_history)}/{len(history)} messages, ~{conversation_context.get('estimated_tokens', 0)} tokens")
            
            # Add current question
            messages.append({
                "role": "user",
                "content": [{"type": "text", "text": question}]
            })
            
            # Prepare API request
            headers = self._get_auth_headers()
            
            # Build semantic_models array for API
            semantic_models_api = []
            for model in semantic_models:
                semantic_models_api.append({"semantic_view": model.semantic_view})
            
            request_body = {
                "messages": messages,
                "semantic_models": semantic_models_api
            }
            
            logger.debug(f"Cortex Analyst API request v2: {json.dumps(request_body, indent=2)}")
            
            # Log request details
            logger.info(f"Sending request to Cortex Analyst v2: {len(messages)} messages, {len(semantic_models_api)} semantic models")
            logger.debug(f"Request URL: {self.cortex_message_url}")
            logger.debug(f"Request body: {json.dumps(request_body, indent=2)}")
            logger.debug(f"Authentication header present: {'Authorization' in headers}")
            
            # Store original headers for potential retry
            original_headers = headers.copy()
            
            # Make API request with enhanced error handling
            timeout_seconds = self.api_timeout_ms / 1000
            
            try:
                response = requests.post(
                    self.cortex_message_url,
                    json=request_body,
                    headers=headers,
                    timeout=timeout_seconds
                )
                
                # Log response details
                logger.debug(f"API Response Status: {response.status_code}")
                logger.debug(f"API Response Headers: {dict(response.headers)}")
                
            except requests.exceptions.Timeout:
                processing_time = time.time() - start_time
                error_msg = f"Cortex Analyst API timeout after {timeout_seconds}s"
                logger.error(f"{error_msg} [conversation_id: {conversation_id}, time: {processing_time:.2f}s]")
                raise Exception(error_msg)
            except requests.exceptions.ConnectionError as e:
                processing_time = time.time() - start_time
                error_msg = f"Cortex Analyst API connection error: {e}"
                logger.error(f"{error_msg} [conversation_id: {conversation_id}, time: {processing_time:.2f}s]")
                raise Exception(error_msg)
            except requests.exceptions.RequestException as e:
                processing_time = time.time() - start_time
                error_msg = f"Cortex Analyst API request error: {e}"
                logger.error(f"{error_msg} [conversation_id: {conversation_id}, time: {processing_time:.2f}s]")
                raise Exception(error_msg)
            
            processing_time = time.time() - start_time
            
            # Enhanced error handling for different status codes
            if response.status_code == 401:
                error_msg = "Authentication failed - check Snowflake credentials and Cortex Analyst permissions"
                logger.error(f"{error_msg} [conversation_id: {conversation_id}]")
                raise Exception(error_msg)
            elif response.status_code == 403:
                error_msg = "Access forbidden - insufficient Cortex Analyst permissions"
                logger.error(f"{error_msg} [conversation_id: {conversation_id}]")
                raise Exception(error_msg)
            elif response.status_code == 404:
                error_msg = "Cortex Analyst API endpoint not found - check service availability"
                logger.error(f"{error_msg} [conversation_id: {conversation_id}]")
                raise Exception(error_msg)
            elif response.status_code == 429:
                error_msg = "Rate limit exceeded - too many requests to Cortex Analyst"
                logger.error(f"{error_msg} [conversation_id: {conversation_id}]")
                raise Exception(error_msg)
            elif response.status_code >= 500:
                error_msg = f"Cortex Analyst server error: {response.status_code} - {response.text[:200]}"
                logger.error(f"{error_msg} [conversation_id: {conversation_id}]")
                raise Exception(error_msg)
            elif response.status_code != 200:
                error_msg = f"Cortex Analyst API error: {response.status_code} - {response.text[:200]}"
                logger.error(f"{error_msg} [conversation_id: {conversation_id}]")
                raise Exception(error_msg)
            
            # Parse JSON response
            try:
                api_response = response.json()
                logger.info(f"Cortex Analyst API response structure v2: {json.dumps(api_response, indent=2)}")
            except json.JSONDecodeError as e:
                error_msg = f"Invalid JSON response from Cortex Analyst: {e}"
                logger.error(f"{error_msg} [conversation_id: {conversation_id}]")
                raise Exception(error_msg)
            
            # Check for session expiration error before validating response structure
            if self._is_session_expired_error(api_response):
                # Session expired - attempt re-authentication once
                error_code = api_response.get("code") or api_response.get("error_code", "unknown")
                logger.warning(f"Session expired (code {error_code}), attempting re-authentication [conversation_id: {conversation_id}]")
                
                try:
                    logger.info(f"Starting re-authentication process [conversation_id: {conversation_id}]")
                    retry_start_time = time.time()
                    
                    # Get fresh authentication headers with forced new connection
                    fresh_headers = self._get_auth_headers(force_new_connection=True)
                    
                    logger.info(f"Fresh authentication headers obtained, retrying request [conversation_id: {conversation_id}]")
                    
                    # Retry the request with fresh token
                    retry_response = requests.post(
                        self.cortex_message_url,
                        json=request_body,
                        headers=fresh_headers,
                        timeout=timeout_seconds
                    )
                    
                    retry_duration = time.time() - retry_start_time
                    logger.info(f"Retry request completed in {retry_duration:.2f}s, status: {retry_response.status_code} [conversation_id: {conversation_id}]")
                    
                    # Check retry response status
                    if retry_response.status_code == 200:
                        try:
                            retry_api_response = retry_response.json()
                            logger.info(f"Retry response received: {json.dumps(retry_api_response, indent=2)} [conversation_id: {conversation_id}]")
                            
                            # Check if the retry response still has session errors
                            if self._is_session_expired_error(retry_api_response):
                                # Try one more time with a small delay to ensure token propagation
                                logger.warning(f"Retry still shows session expired, attempting final retry with delay [conversation_id: {conversation_id}]")
                                
                                import time as time_module
                                time_module.sleep(2)  # Small delay for token propagation
                                
                                # Get completely fresh headers
                                final_headers = self._get_auth_headers(force_new_connection=True)
                                
                                final_response = requests.post(
                                    self.cortex_message_url,
                                    json=request_body,
                                    headers=final_headers,
                                    timeout=timeout_seconds
                                )
                                
                                if final_response.status_code == 200:
                                    final_api_response = final_response.json()
                                    logger.info(f"Final retry response: {json.dumps(final_api_response, indent=2)} [conversation_id: {conversation_id}]")
                                    
                                    if self._is_session_expired_error(final_api_response):
                                        error_msg = ("Persistent session expiration after multiple re-authentication attempts. "
                                                   "This indicates a Snowflake account configuration issue. "
                                                   "Please verify: 1) Cortex AI is enabled, 2) User has CORTEX_ANALYST_USER role, "
                                                   "3) Semantic views are accessible. Run diagnose_cortex_access.py for details.")
                                        logger.error(f"{error_msg} [conversation_id: {conversation_id}]")
                                        raise Exception(error_msg)
                                    else:
                                        retry_api_response = final_api_response
                                        retry_response = final_response
                                        logger.info(f"Final retry successful [conversation_id: {conversation_id}]")
                                else:
                                    error_msg = f"Final retry failed: {final_response.status_code} - {final_response.text[:200]}"
                                    logger.error(f"{error_msg} [conversation_id: {conversation_id}]")
                                    raise Exception(error_msg)
                            
                            api_response = retry_api_response
                            logger.info(f"Successfully re-authenticated and retried request [conversation_id: {conversation_id}]")
                            logger.debug(f"Retry API response structure: {json.dumps(api_response, indent=2)}")
                            response = retry_response  # Use the successful retry response
                            
                        except json.JSONDecodeError as e:
                            error_msg = f"Invalid JSON response from Cortex Analyst after retry: {e}"
                            logger.error(f"{error_msg} [conversation_id: {conversation_id}]")
                            raise Exception(error_msg)
                    else:
                        error_msg = f"Re-authentication failed: {retry_response.status_code} - {retry_response.text[:200]}"
                        logger.error(f"{error_msg} [conversation_id: {conversation_id}]")
                        raise Exception(error_msg)
                        
                except Exception as retry_error:
                    error_msg = f"Re-authentication attempt failed: {retry_error}"
                    logger.error(f"{error_msg} [conversation_id: {conversation_id}]")
                    raise Exception(error_msg)
            
            # Validate response structure
            if not self._validate_api_response(api_response):
                error_msg = "Invalid response structure from Cortex Analyst API"
                logger.error(f"{error_msg} [conversation_id: {conversation_id}]")
                logger.error(f"Actual response: {json.dumps(api_response, indent=2)}")
                raise Exception(error_msg)
            
            logger.info(f"Cortex Analyst v2 request completed in {processing_time:.2f}s [conversation_id: {conversation_id}]")
            
            # Enhanced response parsing
            message_content = api_response.get("message", {}).get("content", [])
            warnings = api_response.get("warnings", [])
            request_id = api_response.get("request_id")
            
            # Extract semantic model selection info if available
            semantic_model_selection = api_response.get("semantic_model_selection")
            semantic_view_used = None
            if semantic_model_selection:
                semantic_view_used = semantic_model_selection.get("semantic_view")
                logger.info(f"Cortex Analyst selected semantic model: {semantic_view_used} [conversation_id: {conversation_id}]")
            else:
                # Fallback to first semantic model if selection info not available
                semantic_view_used = semantic_model_names[0] if semantic_model_names else None
                logger.info(f"No semantic model selection info, using first model: {semantic_view_used} [conversation_id: {conversation_id}]")
            
            # Parse and categorize content types
            content_summary = {"text": 0, "sql": 0, "suggestions": 0, "other": 0}
            sql_statements = []
            
            for item in message_content:
                content_type = item.get("type", "unknown")
                if content_type in content_summary:
                    content_summary[content_type] += 1
                else:
                    content_summary["other"] += 1
                
                # Extract SQL statements for logging
                if content_type == "sql" and "statement" in item:
                    sql_statements.append(item["statement"])
            
            # Log content analysis
            logger.info(f"Response analysis v2 [conversation_id: {conversation_id}]: {content_summary}")
            if sql_statements:
                logger.info(f"Generated {len(sql_statements)} SQL statement(s) [conversation_id: {conversation_id}]")
                for i, sql in enumerate(sql_statements):
                    logger.debug(f"SQL {i+1}: {sql[:100]}..." if len(sql) > 100 else f"SQL {i+1}: {sql}")
            
            # Log warnings if present
            if warnings:
                logger.warning(f"Cortex Analyst v2 warnings [conversation_id: {conversation_id}]: {warnings}")
            
            # Build enhanced response with comprehensive metrics
            parsed_response = {
                "conversation_id": conversation_id,
                "request_id": request_id,
                "content": message_content,
                "warnings": warnings,
                "processing_time_seconds": processing_time,
                "semantic_view_used": semantic_view_used,
                "domain": domain,
                "content_summary": content_summary,
                "sql_generated": len(sql_statements) > 0,
                "message_count": len(messages),
                "api_response_size": len(response.content),
                "success": True,
                "conversation_context": conversation_context,
                "semantic_models_provided": semantic_model_names,
                "semantic_model_selection": semantic_model_selection,
                "response_metadata": {
                    "content_items": len(message_content),
                    "warning_count": len(warnings),
                    "has_sql": len(sql_statements) > 0,
                    "has_suggestions": content_summary.get("suggestions", 0) > 0,
                    "response_size_bytes": len(response.content),
                    "models_provided": len(semantic_model_names),
                    "model_selected": semantic_view_used
                }
            }
            
            # Track comprehensive conversation metrics
            self.track_conversation_metrics(conversation_id, {
                "query_type": "cortex_analyst_query_v2",
                "domain": domain,
                "semantic_models": semantic_model_names,
                "semantic_view_selected": semantic_view_used,
                "processing_time_seconds": processing_time,
                "success": True,
                "content_summary": content_summary,
                "sql_generated": len(sql_statements) > 0,
                "conversation_turns": conversation_context.get("conversation_turns", 0),
                "message_history_length": len(history) if history else 0,
                "question_length": len(question),
                "warnings_count": len(warnings),
                "response_size": len(response.content),
                "models_provided_count": len(semantic_model_names)
            })
            
            # Add AI-generated suggestions if Cortex Analyst didn't provide them
            parsed_response = self._add_suggestions_to_response(
                parsed_response, 
                question, 
                sql_query=sql_statements[0] if sql_statements else None,
                columns=None  # Will be populated later if needed
            )
            
            return parsed_response
            
        except Exception as e:
            processing_time = time.time() - start_time
            error_msg = f"Failed to process analyst query v2: {e}"
            error_type = type(e).__name__
            
            logger.error(f"{error_msg} [conversation_id: {conversation_id}, processing_time: {processing_time:.2f}s, error_type: {error_type}]")
            
            # Track error metrics
            self.track_conversation_metrics(conversation_id, {
                "query_type": "cortex_analyst_query_v2",
                "domain": domain,
                "semantic_models": semantic_model_names if 'semantic_model_names' in locals() else None,
                "processing_time_seconds": processing_time,
                "success": False,
                "error_type": error_type,
                "error_message": str(e),
                "question_length": len(question),
                "message_history_length": len(history) if history else 0,
                "models_provided_count": len(semantic_models) if semantic_models else 0
            })
            
            # Re-raise with enhanced error information
            enhanced_error_msg = f"{error_msg} (Type: {error_type}, Time: {processing_time:.2f}s)"
            raise Exception(enhanced_error_msg)

    def _generate_ai_suggestions(self, question: str, sql_query: Optional[str] = None, columns: Optional[List[str]] = None) -> List[str]:
        """
        Generate intelligent suggestions using Snowflake Cortex AI.
        
        Args:
            question: Original user question
            sql_query: Generated SQL query (if available)
            columns: Result columns (if available)
            
        Returns:
            List[str]: List of 3 AI-generated follow-up questions
        """
        try:
            logger.info(f"Generating AI suggestions for question: {question[:50]}...")
            
            # Build context for the AI
            context_parts = [f"User asked: {question}"]
            
            if sql_query:
                context_parts.append(f"SQL generated: {sql_query[:200]}...")
            
            if columns:
                context_parts.append(f"Available data columns: {', '.join(columns[:10])}")
            
            context = "\n".join(context_parts)
            
            # Create prompt for Cortex AI
            # prompt = f"""Based on this data analysis context:

            #             {context}

            #             Generate exactly 3 relevant follow-up questions that would provide deeper insights. The questions should:
            #             1. Explore different aspects of the same data
            #             2. Be progressively more analytical
            #             3. Be specific and actionable

            #             Return ONLY the 3 questions, one per line, without numbering or bullets.
            #         """

            prompt = f"""
                    You are an intelligent assistant that suggests highly relevant follow-up questions for database analysis.

                    context:
                    {context}

                    Your goal is to suggest questions that:
                    1. Naturally build upon the current analysis
                    2. Help users discover deeper insights
                    3. Explore related dimensions or time periods
                    4. Compare or contrast with the current results
                    5. Are specific and actionable

                    CRITICAL RULES:
                    1. Generate EXACTLY 3 follow-up questions
                    2. Each question must be related to the current question or results
                    3. Vary the types of questions (e.g., comparison, drill-down, time-based, aggregation)
                    4. Use actual column names and values from the results when relevant
                    5. Make questions conversational and natural
                    6. Return ONLY the questions, one per line
                    7. Don't number the questions or add any markdown
                    8. Don't repeat the current question

                    Examples of good follow-up patterns:
                    - If they asked about totals → suggest breakdowns by dimension
                    - If they asked about a specific period → suggest comparisons with other periods
                    - If they asked about one dimension → suggest exploring another related dimension
                    - If they asked about counts → suggest asking about amounts or vice versa
                    - If they asked about all records → suggest filtering or top N
            """

            # Execute Cortex Complete
            conn, cursor = get_sf_conn()
            
            # Use Claude for better context understanding
            cortex_query = f"SELECT SNOWFLAKE.CORTEX.COMPLETE('claude-4-sonnet', %s) AS suggestions"
            
            cursor.execute(cortex_query, (prompt,))
            result = cursor.fetchone()
            
            cursor.close()
            conn.close()
            
            if result and result[0]:
                # Parse the response - split by newlines and clean
                suggestions_text = result[0]
                suggestions = [
                    line.strip().lstrip('123456789.-) ').strip() 
                    for line in suggestions_text.split('\n') 
                    if line.strip() and not line.strip().startswith('#')
                ]
                
                # Filter out empty or very short suggestions
                suggestions = [s for s in suggestions if len(s) > 10]
                
                # Take exactly 3 suggestions
                if len(suggestions) >= 3:
                    final_suggestions = suggestions[:3]
                else:
                    # If we got fewer, pad with generic ones
                    final_suggestions = suggestions + [
                        "What are the key trends in this data over time?",
                        "How do these metrics compare across different segments?",
                        "What factors might be driving these patterns?"
                    ]
                    final_suggestions = final_suggestions[:3]
                
                logger.info(f"Generated {len(final_suggestions)} AI suggestions successfully")
                return final_suggestions
            
            # Fallback if Cortex Complete fails
            logger.warning("Cortex Complete returned empty result, using fallback")
            return self._get_generic_suggestions()
            
        except Exception as e:
            logger.error(f"Error generating AI suggestions: {e}")
            return self._get_generic_suggestions()
    
    def _get_generic_suggestions(self) -> List[str]:
        """
        Get generic but useful suggestions as fallback.
        
        Returns:
            List[str]: List of 3 generic analytical questions
        """
        return [
            "What are the trends in this data over different time periods?",
            "How do these results compare across different categories or segments?",
            "What are the top and bottom performers in this analysis?"
        ]
    
    def _add_suggestions_to_response(self, parsed_response: Dict[str, Any], question: str, sql_query: Optional[str] = None, columns: Optional[List[str]] = None) -> Dict[str, Any]:
        """
        Add AI-generated suggestions to the response if not present.
        
        Args:
            parsed_response: The parsed Cortex Analyst response
            question: Original user question
            sql_query: Generated SQL query
            columns: Result columns if available
            
        Returns:
            Dict[str, Any]: Response with suggestions added
        """
        content = parsed_response.get('content', [])
        
        # Check if suggestions already exist
        has_suggestions = any(
            item.get('type') == 'suggestions' and item.get('suggestions')
            for item in content
        )
        
        if not has_suggestions:
            logger.info("Cortex Analyst didn't provide suggestions, generating with Cortex AI...")
            
            # Generate AI suggestions
            suggestions = self._generate_ai_suggestions(question, sql_query, columns)
            
            # Add to content
            suggestions_item = {
                "type": "suggestions",
                "text": None,
                "statement": None,
                "suggestions": suggestions
            }
            
            content.append(suggestions_item)
            parsed_response['content'] = content
            
            # Update metadata
            if 'content_summary' in parsed_response:
                parsed_response['content_summary']['suggestions'] = 1
            if 'response_metadata' in parsed_response:
                parsed_response['response_metadata']['has_suggestions'] = True
            
            logger.info(f"Successfully added {len(suggestions)} AI-generated suggestions")
        else:
            logger.info("Suggestions already present in Cortex Analyst response")
        
        return parsed_response

    def execute_sql_query(self, sql_query: str, conversation_id: Optional[str] = None) -> Dict[str, Any]:
        """
        Execute SQL query and return formatted results.
        
        Args:
            sql_query: SQL query to execute
            conversation_id: Optional conversation ID for tracking
            
        Returns:
            Dict: Query results with columns, data, and execution metadata
            
        Raises:
            Exception: If SQL execution fails
        """
        start_time = time.time()
        execution_id = str(uuid.uuid4())[:8]
        
        logger.info(f"Executing SQL query [execution_id: {execution_id}, conversation_id: {conversation_id}]")
        logger.debug(f"SQL Query: {sql_query}")
        
        try:
            # Get Snowflake connection with module-specific context
            conn, cursor = get_sf_conn()
            
            # Set warehouse and database context with error handling
            sf_config = self.snowflake_config
            context_commands = [
                f"USE WAREHOUSE {sf_config.get('warehouse')}",
                f"USE DATABASE {sf_config.get('database')}",
                f"USE SCHEMA {sf_config.get('schema')}"
            ]
            
            context_start_time = time.time()
            for cmd in context_commands:
                try:
                    cursor.execute(cmd)
                    logger.debug(f"Context set successfully: {cmd}")
                except Exception as context_error:
                    logger.error(f"Failed to set context '{cmd}': {context_error}")
                    # Continue with other context commands
            
            context_time = time.time() - context_start_time
            logger.debug(f"Context setup completed in {context_time:.2f}s")
            
            # Validate query before execution (additional safety check)
            query_validation_start = time.time()
            if not sql_query.strip():
                raise ValueError("Empty SQL query provided")
            
            # Log query details
            query_lines = sql_query.count('\n') + 1
            query_length = len(sql_query)
            logger.info(f"Executing SQL: {query_lines} lines, {query_length} characters [execution_id: {execution_id}]")
            
            # Execute the main query with timeout handling
            query_start_time = time.time()
            try:
                cursor.execute(sql_query)
                query_execution_time = time.time() - query_start_time
                logger.debug(f"Query executed in {query_execution_time:.2f}s [execution_id: {execution_id}]")
            except Exception as query_error:
                query_execution_time = time.time() - query_start_time
                logger.error(f"Query execution failed after {query_execution_time:.2f}s: {query_error}")
                raise
            
            # Fetch results with progress logging
            fetch_start_time = time.time()
            results = cursor.fetchall()
            fetch_time = time.time() - fetch_start_time
            
            # Get column metadata
            column_names = []
            column_types = []
            if cursor.description:
                for desc in cursor.description:
                    column_names.append(desc[0])
                    column_types.append(desc[1].__name__ if hasattr(desc[1], '__name__') else str(desc[1]))
            
            execution_time = time.time() - start_time
            row_count = len(results) if results else 0
            
            # Log execution statistics
            logger.info(f"SQL execution completed: {row_count} rows, {len(column_names)} columns in {execution_time:.2f}s [execution_id: {execution_id}]")
            logger.debug(f"Execution breakdown - Context: {context_time:.2f}s, Query: {query_execution_time:.2f}s, Fetch: {fetch_time:.2f}s")
            
            # Enhanced result formatting with metadata
            formatted_results = {
                "execution_id": execution_id,
                "conversation_id": conversation_id,
                "columns": column_names,
                "column_types": column_types,
                "data": [list(row) for row in results] if results else [],
                "row_count": row_count,
                "execution_time_seconds": execution_time,
                "performance_metrics": {
                    "context_setup_time": context_time,
                    "query_execution_time": query_execution_time,
                    "fetch_time": fetch_time,
                    "total_time": execution_time
                },
                "success": True,
                "executed_at": datetime.now().isoformat(),
                "query": sql_query,
                "query_metadata": {
                    "length": query_length,
                    "lines": query_lines,
                    "estimated_complexity": "low" if query_length < 200 else "medium" if query_length < 1000 else "high"
                },
                "warehouse": sf_config.get('warehouse'),
                "database": sf_config.get('database'),
                "schema": sf_config.get('schema')
            }
            
            return formatted_results
            
        except Exception as e:
            execution_time = time.time() - start_time
            error_msg = f"SQL execution failed: {e}"
            logger.error(f"{error_msg} [execution_id: {execution_id}, execution_time: {execution_time:.2f}s]")
            
            # Return error response
            error_results = {
                "execution_id": execution_id,
                "conversation_id": conversation_id,
                "columns": [],
                "data": [],
                "row_count": 0,
                "execution_time_seconds": execution_time,
                "success": False,
                "error": str(e),
                "executed_at": datetime.now().isoformat(),
                "query": sql_query
            }
            
            raise Exception(error_msg)
        
        finally:
            if 'cursor' in locals():
                cursor.close()
            if 'conn' in locals():
                conn.close()

    def submit_feedback(self, request_id: str, positive: bool, message: Optional[str] = None) -> Dict[str, Any]:
        """
        Submit user feedback for a Cortex Analyst request.
        
        Args:
            request_id: Request ID from Cortex Analyst response
            positive: Whether feedback is positive (True) or negative (False)
            message: Optional feedback message
            
        Returns:
            Dict: Feedback submission confirmation
            
        Raises:
            Exception: If feedback submission fails
        """
        feedback_id = str(uuid.uuid4())[:8]
        
        logger.info(f"Submitting feedback for request_id: {request_id} [feedback_id: {feedback_id}, positive: {positive}]")
        
        try:
            headers = self._get_auth_headers()
            
            feedback_body = {
                "request_id": request_id,
                "positive": positive
            }
            
            if message:
                feedback_body["feedback_message"] = message
            
            logger.debug(f"Feedback payload: {feedback_body}")
            
            response = requests.post(
                self.cortex_feedback_url,
                json=feedback_body,
                headers=headers,
                timeout=30
            )
            
            if response.status_code != 200:
                error_msg = f"Feedback submission failed: {response.status_code} - {response.text}"
                logger.error(error_msg)
                raise Exception(error_msg)
            
            result = {
                "feedback_id": feedback_id,
                "request_id": request_id,
                "success": True,
                "submitted_at": datetime.now().isoformat(),
                "rating": "positive" if positive else "negative",
                "message": message
            }
            
            logger.info(f"Feedback submitted successfully [feedback_id: {feedback_id}]")
            return result
            
        except Exception as e:
            error_msg = f"Failed to submit feedback: {e}"
            logger.error(f"{error_msg} [feedback_id: {feedback_id}]")
            raise Exception(error_msg)

    def get_domain_info(self, domain: str) -> Dict[str, Any]:
        """
        Get detailed information about a specific domain.
        
        Args:
            domain: Domain key
            
        Returns:
            Dict: Domain information with models and metadata
            
        Raises:
            ValueError: If domain doesn't exist
        """
        if not self.validate_domain(domain):
            available_domains = list(self.domains.keys())
            raise ValueError(f"Domain '{domain}' not found. Available domains: {available_domains}")
        
        return self.get_models_by_domain(domain)

    def get_available_domains(self) -> List[str]:
        """
        Get list of available domain keys.
        
        Returns:
            List[str]: Available domain keys
        """
        return list(self.domains.keys())

    def get_domain_models(self, domain: str) -> List[Dict[str, Any]]:
        """
        Get semantic views for a specific domain.
        
        Args:
            domain: Domain key
            
        Returns:
            List[Dict]: List of semantic views with metadata
            
        Raises:
            ValueError: If domain doesn't exist
        """
        logger.info(f"Retrieving models for domain: {domain}")
        
        if not self.validate_domain(domain):
            available_domains = list(self.domains.keys())
            raise ValueError(f"Domain '{domain}' not found. Available domains: {available_domains}")
        
        domain_data = self.domains[domain]
        models = []
        
        # Get models using the new config structure
        model_paths = get_models_for_domain(domain)
        
        for view_path in model_paths:
            # Get metadata from configuration instead of string manipulation
            metadata = get_semantic_view_metadata(domain, view_path)
            
            if metadata:
                # Use configured display name and description
                model_info = {
                    "name": metadata["display_name"],
                    "path": view_path,
                    "full_path": view_path,  # Semantic views don't need @ prefix
                    "domain": domain,
                    "type": "semantic_view",
                    "format": "view",
                    "description": metadata.get("description", ""),
                    "is_default": metadata.get("is_default", False)
                }
            else:
                # Fallback for missing metadata (should not happen with proper config)
                logger.warning(f"Missing metadata for semantic view {view_path} in domain {domain}")
                fallback_name = view_path.split(".")[-1].replace("SV_", "").replace("_", " ").title()
                model_info = {
                    "name": fallback_name,
                    "path": view_path,
                    "full_path": view_path,
                    "domain": domain,
                    "type": "semantic_view",
                    "format": "view",
                    "description": f"Semantic view for {domain} analytics",
                    "is_default": False
                }
            models.append(model_info)
        
        logger.info(f"Retrieved {len(models)} models for domain '{domain}'")
        return models

    def get_domain_metadata(self, domain: str) -> Dict[str, Any]:
        """
        Get comprehensive metadata for a domain including use cases and examples.
        
        Args:
            domain: Domain key
            
        Returns:
            Dict: Complete domain metadata
            
        Raises:
            ValueError: If domain doesn't exist
        """
        if not self.validate_domain(domain):
            available_domains = list(self.domains.keys())
            raise ValueError(f"Domain '{domain}' not found. Available domains: {available_domains}")
        
        domain_data = self.domains[domain]
        
        # Define domain-specific use cases and example questions
        domain_examples = self._get_domain_examples(domain)
        
        # Get domain-specific configuration
        domain_specific_config = get_domain_specific_config(domain)
        
        metadata = {
            "key": domain,
            "name": domain_data.get("name"),
            "description": domain_data.get("description"),
            "model_count": len(domain_data.get("models", [])),
            "models": self.get_domain_models(domain),
            "default_model": self.get_default_model(domain),
            "use_cases": domain_examples.get("use_cases", []),
            "example_questions": domain_examples.get("example_questions", []),
            "supported_analyses": domain_examples.get("supported_analyses", []),
            "configuration": {
                "access_level": domain_specific_config.get("access_level", "public"),
                "max_query_complexity": domain_specific_config.get("max_query_complexity", "medium"),
                "supported_operations": domain_specific_config.get("supported_operations", ["SELECT", "SHOW"]),
                "enable_advanced_analytics": domain_specific_config.get("enable_advanced_analytics", False)
            }
        }
        
        return metadata

    def _get_domain_examples(self, domain: str) -> Dict[str, List[str]]:
        """
        Get domain-specific use cases, example questions, and supported analyses.
        
        Args:
            domain: Domain key
            
        Returns:
            Dict: Domain examples and use cases from configuration
        """
        return get_domain_examples(domain)

    def get_domains_overview(self) -> Dict[str, Any]:
        """
        Get a comprehensive overview of all domains and their capabilities.
        
        Returns:
            Dict: Complete domains overview with statistics
        """
        logger.info("Generating domains overview")
        
        domains_overview = {
            "total_domains": len(self.domains),
            "total_models": sum(len(domain.get("models", [])) for domain in self.domains.values()),
            "domains": {}
        }
        
        for domain_key in self.domains.keys():
            try:
                domain_metadata = self.get_domain_metadata(domain_key)
                domains_overview["domains"][domain_key] = domain_metadata
            except Exception as e:
                logger.error(f"Error getting metadata for domain '{domain_key}': {e}")
                domains_overview["domains"][domain_key] = {
                    "error": f"Failed to load domain metadata: {e}"
                }
        
        logger.info(f"Generated overview for {domains_overview['total_domains']} domains with {domains_overview['total_models']} total models")
        return domains_overview

    def validate_domain_access(self, domain: str, user_permissions: Optional[List[str]] = None) -> Tuple[bool, Optional[str]]:
        """
        Validate if user has access to a specific domain (for future access control).
        
        Args:
            domain: Domain key to validate
            user_permissions: Optional list of user permissions
            
        Returns:
            Tuple[bool, Optional[str]]: (has_access, error_message)
        """
        # First validate domain exists
        if not self.validate_domain(domain):
            available_domains = list(self.domains.keys())
            return False, f"Domain '{domain}' not found. Available domains: {available_domains}"
        
        # For now, all domains are accessible (future: implement permission checking)
        if user_permissions is not None:
            # Future: Check if user has permission for this domain
            # For example: f"domain:{domain}:read" in user_permissions
            pass
        
        return True, None

    def get_domain_model_by_name(self, domain: str, model_name: str) -> Optional[Dict[str, Any]]:
        """
        Get a specific semantic view by name within a domain.
        
        Args:
            domain: Domain key
            model_name: Display name of the semantic view (derived from SV_ name)
            
        Returns:
            Optional[Dict]: Semantic view information or None if not found
        """
        if not self.validate_domain(domain):
            return None
        
        models = self.get_domain_models(domain)
        for model in models:
            if model["name"] == model_name:
                return model
        
        return None

    def get_domain_query_restrictions(self, domain: str) -> Dict[str, Any]:
        """
        Get query restrictions for a specific domain based on configuration.
        
        Args:
            domain: Domain key
            
        Returns:
            Dict: Domain query restrictions and capabilities
        """
        if not self.validate_domain(domain):
            return {
                "allowed": False,
                "reason": f"Invalid domain: {domain}"
            }
        
        domain_config = get_domain_specific_config(domain)
        
        restrictions = {
            "allowed": True,
            "access_level": domain_config.get("access_level", "public"),
            "max_query_complexity": domain_config.get("max_query_complexity", "medium"),
            "supported_operations": domain_config.get("supported_operations", ["SELECT", "SHOW"]),
            "enable_advanced_analytics": domain_config.get("enable_advanced_analytics", False),
            "restrictions": []
        }
        
        # Add specific restrictions based on access level
        if domain_config.get("access_level") == "restricted":
            restrictions["restrictions"].append("Requires additional permissions for data access")
        
        # Add complexity restrictions
        complexity = domain_config.get("max_query_complexity", "medium")
        if complexity == "low":
            restrictions["restrictions"].append("Limited to simple queries only")
        elif complexity == "medium":
            restrictions["restrictions"].append("Moderate query complexity allowed")
        
        # Add operation restrictions
        operations = domain_config.get("supported_operations", [])
        if "INSERT" not in operations and "UPDATE" not in operations and "DELETE" not in operations:
            restrictions["restrictions"].append("Read-only access - no data modifications allowed")
        
        return restrictions

    def is_domain_operation_allowed(self, domain: str, operation: str) -> bool:
        """
        Check if a specific SQL operation is allowed for a domain.
        
        Args:
            domain: Domain key
            operation: SQL operation (SELECT, INSERT, UPDATE, etc.)
            
        Returns:
            bool: True if operation is allowed
        """
        if not self.validate_domain(domain):
            return False
        
        domain_config = get_domain_specific_config(domain)
        allowed_operations = domain_config.get("supported_operations", ["SELECT", "SHOW"])
        
        return operation.upper() in [op.upper() for op in allowed_operations]

    def track_conversation_metrics(self, conversation_id: str, metrics: Dict[str, Any]) -> None:
        """
        Track conversation metrics for analytics and monitoring.
        
        Args:
            conversation_id: Conversation identifier
            metrics: Metrics dictionary to track
        """
        try:
            # Enhanced metrics logging with structured data
            metric_summary = {
                "conversation_id": conversation_id,
                "timestamp": datetime.now().isoformat(),
                "service": "InsightsAI",
                **metrics
            }
            
            # Log metrics in structured format for monitoring systems
            logger.info(f"CONVERSATION_METRICS: {json.dumps(metric_summary)}")
            
            # Log human-readable summary
            processing_time = metrics.get("processing_time_seconds", 0)
            query_type = metrics.get("query_type", "unknown")
            success = metrics.get("success", False)
            
            logger.info(f"Conversation {conversation_id}: {query_type} {'completed' if success else 'failed'} in {processing_time:.2f}s")
            
        except Exception as e:
            logger.error(f"Failed to track conversation metrics: {e}")

    def validate_semantic_view_access(self, view_name: str) -> Tuple[bool, Optional[str]]:
        """
        Validate access to a semantic view with enhanced checks.
        
        Args:
            view_name: Semantic view name to validate
            
        Returns:
            Tuple[bool, Optional[str]]: (has_access, error_message)
        """
        try:
            # Clean the view name
            clean_view = view_name.strip()
            
            # Check if view is in allowed semantic views
            all_allowed_views = set()
            for domain_data in self.domains.values():
                for model in domain_data.get("models", []):  # "models" contains model objects
                    if isinstance(model, dict):
                        all_allowed_views.add(model.get("path"))
                    else:
                        # Backward compatibility for string models
                        all_allowed_views.add(model)
            
            if clean_view not in all_allowed_views:
                return False, f"Semantic view not found or not accessible: {view_name}"
            
            # Validate view name format (DATABASE.SCHEMA.VIEW_NAME)
            view_parts = clean_view.split('.')
            if len(view_parts) != 3:
                return False, f"Invalid semantic view format: {view_name}"
            
            database, schema, view_name_only = view_parts
            if not view_name_only.startswith('SV_'):
                return False, f"Semantic view must start with SV_ prefix: {view_name}"
            
            # Optional: Try to verify the view exists in Snowflake (but don't fail if we can't check)
            try:
                conn, cursor = get_sf_conn()
                cursor.execute(f"DESCRIBE VIEW {clean_view}")
                cursor.close()
                conn.close()
                logger.debug(f"Semantic view verified to exist in Snowflake: {view_name}")
            except Exception as db_error:
                logger.warning(f"Could not verify semantic view existence in Snowflake: {db_error}")
                # Return the specific error about the view not existing
                if "does not exist" in str(db_error).lower():
                    return False, f"Semantic view does not exist in Snowflake: {view_name}. Error: {db_error}"
                # For other errors (permissions, connection), still allow the request to proceed
                logger.debug("Proceeding with request despite view verification failure")
            
            logger.debug(f"Semantic view access validated: {view_name}")
            return True, None
            
        except Exception as e:
            error_msg = f"Error validating semantic view access: {e}"
            logger.error(error_msg)
            return False, error_msg
    
    def validate_semantic_model_access(self, model_path: str) -> Tuple[bool, Optional[str]]:
        """
        [DEPRECATED] Validate semantic model access - use validate_semantic_view_access() instead.
        
        Args:
            model_path: Semantic view name to validate
            
        Returns:
            Tuple[bool, Optional[str]]: (has_access, error_message)
        """
        logger.warning("validate_semantic_model_access is deprecated, use validate_semantic_view_access instead")
        return self.validate_semantic_view_access(model_path)

    def get_conversation_context_summary(self, messages: List[ConversationMessage]) -> Dict[str, Any]:
        """
        Generate a summary of conversation context for logging and analytics.
        
        Args:
            messages: List of conversation messages
            
        Returns:
            Dict: Context summary with statistics
        """
        try:
            context_summary = {
                "message_count": len(messages),
                "user_messages": 0,
                "analyst_messages": 0,
                "content_types": {"text": 0, "sql": 0, "suggestions": 0},
                "total_text_length": 0,
                "sql_statements": 0,
                "suggestion_count": 0,
                "conversation_turns": 0
            }
            
            for message in messages:
                if message.role.value == "user":
                    context_summary["user_messages"] += 1
                elif message.role.value == "analyst":
                    context_summary["analyst_messages"] += 1
                
                for content in message.content:
                    content_type = content.type.value
                    if content_type in context_summary["content_types"]:
                        context_summary["content_types"][content_type] += 1
                    
                    if content_type == "text" and content.text:
                        context_summary["total_text_length"] += len(content.text)
                    elif content_type == "sql" and content.statement:
                        context_summary["sql_statements"] += 1
                        context_summary["total_text_length"] += len(content.statement)
                    elif content_type == "suggestions" and content.suggestions:
                        context_summary["suggestion_count"] += len(content.suggestions)
            
            # Calculate conversation turns (pairs of user-analyst exchanges)
            context_summary["conversation_turns"] = min(
                context_summary["user_messages"], 
                context_summary["analyst_messages"]
            )
            
            # Estimate complexity
            total_content = context_summary["total_text_length"]
            if total_content < 500:
                complexity = "low"
            elif total_content < 2000:
                complexity = "medium"
            else:
                complexity = "high"
            
            context_summary["conversation_complexity"] = complexity
            context_summary["estimated_tokens"] = total_content // 4  # Rough estimation
            
            return context_summary
            
        except Exception as e:
            logger.error(f"Error generating conversation context summary: {e}")
            return {"error": str(e)}

    def optimize_message_history_for_tokens(self, messages: List[ConversationMessage], target_tokens: int = None) -> List[ConversationMessage]:
        """
        Optimize message history to fit within token limits while preserving conversation context.
        
        Args:
            messages: Original message history
            target_tokens: Target token limit (uses config default if None)
            
        Returns:
            List[ConversationMessage]: Optimized message history
        """
        if target_tokens is None:
            target_tokens = self.max_history_tokens
        
        if not messages:
            return messages
        
        # Calculate current token usage
        total_tokens = 0
        for message in messages:
            for content in message.content:
                if content.type == ContentType.TEXT and content.text:
                    total_tokens += self._estimate_token_count(content.text)
                elif content.type == ContentType.SQL and content.statement:
                    total_tokens += self._estimate_token_count(content.statement)
        
        # If within limits, return as-is
        if total_tokens <= target_tokens:
            logger.debug(f"Message history within token limits: {total_tokens}/{target_tokens}")
            return messages
        
        logger.info(f"Optimizing message history: {total_tokens} tokens -> target: {target_tokens}")
        
        # Strategy: Keep recent messages and preserve important context
        optimized_messages = []
        current_tokens = 0
        
        # Start from the most recent messages
        for message in reversed(messages):
            message_tokens = 0
            for content in message.content:
                if content.type == ContentType.TEXT and content.text:
                    message_tokens += self._estimate_token_count(content.text)
                elif content.type == ContentType.SQL and content.statement:
                    message_tokens += self._estimate_token_count(content.statement)
            
            # Add message if it fits within token budget
            if current_tokens + message_tokens <= target_tokens:
                optimized_messages.insert(0, message)  # Insert at beginning to maintain order
                current_tokens += message_tokens
            else:
                break
        
        logger.info(f"Optimized message history: {len(optimized_messages)}/{len(messages)} messages, {current_tokens} tokens")
        return optimized_messages

    def health_check(self) -> Dict[str, Any]:
        """
        Perform a health check of the service and its dependencies.
        
        Returns:
            Dict: Health check results
        """
        health_status = {
            "service": "InsightsService",
            "status": "healthy",
            "timestamp": datetime.now().isoformat(),
            "checks": {}
        }
        
        try:
            # Check configuration
            health_status["checks"]["configuration"] = {
                "status": "ok",
                "domains_count": len(self.domains),
                "api_config_loaded": bool(self.api_config)
            }
            
            # Check Snowflake connection
            try:
                conn, cursor = get_sf_conn()
                cursor.execute("SELECT 1")
                cursor.close()
                conn.close()
                health_status["checks"]["snowflake_connection"] = {"status": "ok"}
            except Exception as e:
                health_status["checks"]["snowflake_connection"] = {
                    "status": "error",
                    "error": str(e)
                }
                health_status["status"] = "degraded"
            
            # Check authentication
            try:
                headers = self._get_auth_headers()
                health_status["checks"]["authentication"] = {"status": "ok"}
            except Exception as e:
                health_status["checks"]["authentication"] = {
                    "status": "error",
                    "error": str(e)
                }
                health_status["status"] = "degraded"
            
        except Exception as e:
            health_status["status"] = "error"
            health_status["error"] = str(e)
        
        return health_status

    def get_example_questions(self, domain: str, count: int = 3) -> List[str]:
        """
        Get random example questions for a specific domain.
        
        Args:
            domain: Domain key (e.g., 'policy', 'claims', 'others')
            count: Number of random questions to return (default: 3)
            
        Returns:
            List[str]: List of example questions (up to count)
            
        Raises:
            ValueError: If domain not found
        """
        import random
        
        if not self.validate_domain(domain):
            available_domains = list(self.domains.keys())
            raise ValueError(f"Domain '{domain}' not found. Available domains: {available_domains}")
        
        domain_data = self.domains.get(domain, {})
        example_questions = domain_data.get("example_questions", [])
        
        if not example_questions:
            logger.warning(f"No example questions configured for domain '{domain}'")
            return []
        
        # Return random sample (up to count)
        sample_size = min(count, len(example_questions))
        selected_questions = random.sample(example_questions, sample_size)
        
        logger.info(f"Retrieved {len(selected_questions)} example questions for domain '{domain}'")
        return selected_questions


# Create a singleton instance for use across the application
insights_service = InsightsService()