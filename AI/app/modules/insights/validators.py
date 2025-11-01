"""
Insights AI Validators Module

This module contains input validation and security functions for the Insights AI module.
Provides validation for:
- Question text validation and content safety
- Semantic view name validation
- SQL query validation and basic safety checks
- Message history validation
- Security measures and sanitization
"""

import re
import json
from typing import List, Optional, Dict, Any, Tuple
from urllib.parse import unquote

from app.utils.logging import logger
from app.modules.insights.config_loader import (
    get_semantic_domains, 
    get_api_config,
    get_all_domains,
    get_all_semantic_views
)
from app.modules.insights.schemas import ConversationMessage, MessageContent, ContentType


class ValidationError(Exception):
    """Custom exception for validation errors."""
    pass


class InputValidator:
    """
    Main validator class for Insights AI input validation and security.
    """
    
    def __init__(self):
        """Initialize validator with configuration."""
        self.domains = get_semantic_domains()
        self.api_config = get_api_config()
        
        # Validation limits from configuration
        self.max_question_length = 1000
        self.max_feedback_message_length = 500
        self.max_history_length = self.api_config.get('max_history_length', 10)
        self.max_sql_length = 10000
        
        # Build allowed semantic view names from configuration using new config structure
        self.allowed_semantic_views = set(get_all_semantic_views())
        
        # Keep legacy support for model paths during transition
        self.allowed_model_paths = self.allowed_semantic_views.copy()
        for view_name in self.allowed_semantic_views:
            self.allowed_model_paths.add(f"@{view_name}")  # With @ prefix
        
        # SQL security patterns (basic injection prevention)
        self.dangerous_sql_patterns = [
            r'\b(DROP|DELETE|INSERT|UPDATE|ALTER|CREATE|TRUNCATE)\b',
            r'\b(EXEC|EXECUTE|xp_|sp_)\b',
            # r'--.*',  # SQL comments
            # r'/\*.*?\*/',  # Multi-line comments
            # r';.*',  # Multiple statements
            # r'\b(UNION|UNION\s+ALL)\b.*\b(SELECT)\b'  # Union-based injection
        ]
        
        # Compile regex patterns for performance
        self.sql_danger_regex = [re.compile(pattern, re.IGNORECASE | re.DOTALL) for pattern in self.dangerous_sql_patterns]
        
        logger.info("InputValidator initialized with security patterns and domain validation")

    def validate_question_text(self, question: str) -> Tuple[bool, Optional[str]]:
        """
        Validate question text for length, content safety, and format.
        
        Args:
            question: Question text to validate
            
        Returns:
            Tuple[bool, Optional[str]]: (is_valid, error_message)
        """
        logger.debug(f"Validating question text: '{question[:50]}...'")
        
        # Check if question is provided
        if not question:
            return False, "Question text is required"
        
        # Check if question is string
        if not isinstance(question, str):
            return False, "Question must be a string"
        
        # Trim whitespace
        question = question.strip()
        
        # Check minimum length
        if len(question) < 3:
            return False, "Question must be at least 3 characters long"
        
        # Check maximum length
        if len(question) > self.max_question_length:
            return False, f"Question exceeds maximum length of {self.max_question_length} characters"
        
        # Check for basic content safety
        if self._contains_suspicious_content(question):
            return False, "Question contains potentially unsafe content"
        
        # Check for valid characters (allow alphanumeric, spaces, punctuation)
        if not re.match(r'^[\w\s\.,\?\!\-\(\)\[\]\{\}:;\'"@#$%&+=<>/\\]+$', question, re.UNICODE):
            return False, "Question contains invalid characters"
        
        # Check for excessive repetitive characters
        if re.search(r'(.)\1{20,}', question):
            return False, "Question contains excessive repetitive characters"
        
        logger.debug("Question text validation passed")
        return True, None

    def validate_semantic_model_path(self, model_path: str) -> Tuple[bool, Optional[str]]:
        """
        [DEPRECATED] Validate semantic model path - use validate_semantic_view() instead.
        This function now delegates to semantic view validation for backward compatibility.
        
        Args:
            model_path: Semantic view name to validate
            
        Returns:
            Tuple[bool, Optional[str]]: (is_valid, error_message)
        """
        logger.warning("validate_semantic_model_path is deprecated, use validate_semantic_view instead")
        return self.validate_semantic_view(model_path)

    def validate_semantic_view(self, semantic_view: str) -> Tuple[bool, Optional[str]]:
        """
        Validate semantic view name format, structure, and against allowed list.
        
        Args:
            semantic_view: Semantic view name to validate
            
        Returns:
            Tuple[bool, Optional[str]]: (is_valid, error_message)
        """
        logger.debug(f"Validating semantic view: {semantic_view}")
        
        if not semantic_view:
            return False, "Semantic view name is required"
        
        if not isinstance(semantic_view, str):
            return False, "Semantic view name must be a string"
        
        # Clean the view name (remove @ prefix if present)
        clean_view = semantic_view.lstrip('@').strip()
        
        # Check if view is in allowed list
        if clean_view not in self.allowed_semantic_views and semantic_view not in self.allowed_semantic_views:
            available_views = list(self.allowed_semantic_views)[:5]  # Show first 5 for reference
            return False, f"Invalid semantic view. Available views include: {available_views}"
        
        # Validate view name format (should be DATABASE.SCHEMA.VIEW_NAME)
        view_pattern = r'^[A-Z0-9_]+\.[A-Z0-9_]+\.[A-Z0-9_]+$'
        if not re.match(view_pattern, clean_view):
            return False, "Invalid semantic view format. Expected: DATABASE.SCHEMA.VIEW_NAME"
        
        # Validate that it follows semantic view naming convention
        if not clean_view.split('.')[-1].startswith('SV_'):
            return False, "Semantic view name should start with 'SV_' prefix"
        
        logger.debug("Semantic view validation passed")
        return True, None

    def validate_domain(self, domain: str) -> Tuple[bool, Optional[str]]:
        """
        Validate domain selection against available domains.
        
        Args:
            domain: Domain key to validate
            
        Returns:
            Tuple[bool, Optional[str]]: (is_valid, error_message)
        """
        logger.debug(f"Validating domain: {domain}")
        
        if not domain:
            return False, "Domain is required"
        
        if not isinstance(domain, str):
            return False, "Domain must be a string"
        
        domain = domain.strip().lower()
        
        # Check if domain exists
        if domain not in self.domains:
            available_domains = list(self.domains.keys())
            return False, f"Invalid domain '{domain}'. Available domains: {available_domains}"
        
        logger.debug("Domain validation passed")
        return True, None

    def validate_sql_query(self, sql_query: str, allow_modifications: bool = False) -> Tuple[bool, Optional[str]]:
        """
        Validate SQL query for basic safety and format.
        
        Args:
            sql_query: SQL query to validate
            allow_modifications: Whether to allow INSERT/UPDATE/DELETE operations
            
        Returns:
            Tuple[bool, Optional[str]]: (is_valid, error_message)
        """
        logger.debug(f"Validating SQL query: '{sql_query[:100]}...'")
        
        if not sql_query:
            return False, "SQL query is required"
        
        if not isinstance(sql_query, str):
            return False, "SQL query must be a string"
        
        sql_query = sql_query.strip()
        
        # Check length
        if len(sql_query) > self.max_sql_length:
            return False, f"SQL query exceeds maximum length of {self.max_sql_length} characters"
        
        # Check for basic SQL structure (must start with SELECT, WITH, or SHOW)
        if not allow_modifications:
            allowed_starters = ['SELECT', 'WITH', 'SHOW', 'DESCRIBE', 'DESC', 'EXPLAIN']
            if not any(sql_query.upper().strip().startswith(starter) for starter in allowed_starters):
                return False, f"Only {', '.join(allowed_starters)} queries are allowed"
        
        # Check for dangerous patterns
        for pattern_regex in self.sql_danger_regex:
            if pattern_regex.search(sql_query):
                if not allow_modifications:
                    return False, "SQL query contains potentially dangerous operations"
                else:
                    logger.warning(f"SQL query contains modification operations: {sql_query[:100]}...")
        
        # Check for balanced quotes and parentheses
        if not self._check_balanced_sql(sql_query):
            return False, "SQL query has unbalanced quotes or parentheses"
        
        # Check for excessive complexity (basic heuristic)
        if sql_query.upper().count('SELECT') > 10:
            return False, "SQL query is too complex (too many SELECT statements)"
        
        logger.debug("SQL query validation passed")
        return True, None

    def validate_message_history(self, history: List[ConversationMessage]) -> Tuple[bool, Optional[str]]:
        """
        Validate message history structure and content.
        
        Args:
            history: List of conversation messages to validate
            
        Returns:
            Tuple[bool, Optional[str]]: (is_valid, error_message)
        """
        logger.debug(f"Validating message history with {len(history)} messages")
        
        if not isinstance(history, list):
            return False, "Message history must be a list"
        
        # Check history length
        if len(history) > self.max_history_length:
            return False, f"Message history exceeds maximum length of {self.max_history_length} messages"
        
        # Validate each message
        for i, message in enumerate(history):
            if not isinstance(message, ConversationMessage):
                return False, f"Message {i} is not a valid ConversationMessage object"
            
            # Validate message role
            if message.role not in ['user', 'analyst']:
                return False, f"Message {i} has invalid role: {message.role}"
            
            # Validate message content
            if not message.content or not isinstance(message.content, list):
                return False, f"Message {i} has invalid content structure"
            
            # Validate each content item
            for j, content in enumerate(message.content):
                if not isinstance(content, MessageContent):
                    return False, f"Message {i}, content {j} is not a valid MessageContent object"
                
                # Validate content based on type
                if content.type == ContentType.TEXT:
                    if not content.text:
                        return False, f"Message {i}, content {j} has empty text content"
                    if len(content.text) > self.max_question_length:
                        return False, f"Message {i}, content {j} text is too long"
                
                elif content.type == ContentType.SQL:
                    if not content.statement:
                        return False, f"Message {i}, content {j} has empty SQL statement"
                    # Validate SQL in history (allow read-only)
                    sql_valid, sql_error = self.validate_sql_query(content.statement, allow_modifications=False)
                    if not sql_valid:
                        return False, f"Message {i}, content {j} has invalid SQL: {sql_error}"
                
                elif content.type == ContentType.SUGGESTIONS:
                    if not content.suggestions or not isinstance(content.suggestions, list):
                        return False, f"Message {i}, content {j} has invalid suggestions"
        
        logger.debug("Message history validation passed")
        return True, None

    def validate_feedback_message(self, feedback_message: str) -> Tuple[bool, Optional[str]]:
        """
        Validate feedback message content.
        
        Args:
            feedback_message: Feedback message to validate
            
        Returns:
            Tuple[bool, Optional[str]]: (is_valid, error_message)
        """
        logger.debug(f"Validating feedback message: '{feedback_message[:50]}...'")
        
        if not feedback_message:
            return True, None  # Feedback message is optional
        
        if not isinstance(feedback_message, str):
            return False, "Feedback message must be a string"
        
        feedback_message = feedback_message.strip()
        
        # Check length
        if len(feedback_message) > self.max_feedback_message_length:
            return False, f"Feedback message exceeds maximum length of {self.max_feedback_message_length} characters"
        
        # Check for basic content safety
        if self._contains_suspicious_content(feedback_message):
            return False, "Feedback message contains potentially unsafe content"
        
        logger.debug("Feedback message validation passed")
        return True, None

    def validate_request_id(self, request_id: str) -> Tuple[bool, Optional[str]]:
        """
        Validate request ID format.
        
        Args:
            request_id: Request ID to validate
            
        Returns:
            Tuple[bool, Optional[str]]: (is_valid, error_message)
        """
        if not request_id:
            return False, "Request ID is required"
        
        if not isinstance(request_id, str):
            return False, "Request ID must be a string"
        
        request_id = request_id.strip()
        
        # Basic format validation (alphanumeric, hyphens, underscores)
        if not re.match(r'^[a-zA-Z0-9\-_]+$', request_id):
            return False, "Request ID contains invalid characters"
        
        # Length check
        if len(request_id) < 3 or len(request_id) > 100:
            return False, "Request ID must be between 3 and 100 characters"
        
        return True, None

    def sanitize_input_text(self, text: str) -> str:
        """
        Sanitize input text by removing potentially harmful content.
        
        Args:
            text: Text to sanitize
            
        Returns:
            str: Sanitized text
        """
        if not text:
            return ""
        
        # Remove null bytes and control characters
        sanitized = re.sub(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]', '', text)
        
        # Remove excessive whitespace
        sanitized = re.sub(r'\s+', ' ', sanitized)
        
        # Trim
        sanitized = sanitized.strip()
        
        # URL decode if needed (basic protection against encoding attacks)
        try:
            decoded = unquote(sanitized)
            if decoded != sanitized and self._contains_suspicious_content(decoded):
                logger.warning("Suspicious content detected after URL decoding")
                return sanitized  # Return original if decoding reveals suspicious content
            sanitized = decoded
        except Exception:
            pass  # Keep original if decoding fails
        
        return sanitized

    def _contains_suspicious_content(self, text: str) -> bool:
        """
        Check if text contains potentially suspicious content.
        
        Args:
            text: Text to check
            
        Returns:
            bool: True if suspicious content is detected
        """
        suspicious_patterns = [
            r'<script[^>]*>.*?</script>',  # Script tags
            r'javascript:',  # JavaScript URLs
            r'on\w+\s*=',  # Event handlers
            r'eval\s*\(',  # Eval calls
            r'document\.',  # DOM access
            r'window\.',  # Window object access
            r'\.innerHTML',  # innerHTML manipulation
            r'http[s]?://(?![\w\.-]+\.(com|org|net|edu|gov))',  # Suspicious URLs
            r'\\x[0-9a-fA-F]{2}',  # Hex encoding
            r'%[0-9a-fA-F]{2}',  # URL encoding of control chars
        ]
        
        for pattern in suspicious_patterns:
            if re.search(pattern, text, re.IGNORECASE | re.DOTALL):
                logger.warning(f"Suspicious pattern detected: {pattern}")
                return True
        
        return False

    def _check_balanced_sql(self, sql: str) -> bool:
        """
        Check if SQL has balanced quotes and parentheses.
        
        Args:
            sql: SQL query to check
            
        Returns:
            bool: True if balanced
        """
        # Count parentheses
        open_parens = sql.count('(')
        close_parens = sql.count(')')
        
        if open_parens != close_parens:
            return False
        
        # Check quotes (simplified - doesn't handle escaped quotes perfectly)
        single_quotes = sql.count("'")
        double_quotes = sql.count('"')
        
        # Single quotes should be even (pairs)
        if single_quotes % 2 != 0:
            return False
        
        # Double quotes should be even (pairs)
        if double_quotes % 2 != 0:
            return False
        
        return True

    def validate_pagination_params(self, limit: Optional[int] = None, offset: Optional[int] = None) -> Tuple[bool, Optional[str]]:
        """
        Validate pagination parameters.
        
        Args:
            limit: Maximum number of results
            offset: Number of results to skip
            
        Returns:
            Tuple[bool, Optional[str]]: (is_valid, error_message)
        """
        if limit is not None:
            if not isinstance(limit, int) or limit < 1:
                return False, "Limit must be a positive integer"
            if limit > 1000:
                return False, "Limit cannot exceed 1000"
        
        if offset is not None:
            if not isinstance(offset, int) or offset < 0:
                return False, "Offset must be a non-negative integer"
        
        return True, None


# Convenience functions for easy validation

def validate_question(question: str) -> None:
    """
    Validate question text and raise ValidationError if invalid.
    
    Args:
        question: Question text to validate
        
    Raises:
        ValidationError: If validation fails
    """
    validator = InputValidator()
    is_valid, error_message = validator.validate_question_text(question)
    if not is_valid:
        raise ValidationError(error_message)


def validate_domain(domain: str) -> None:
    """
    Validate domain and raise ValidationError if invalid.
    
    Args:
        domain: Domain key to validate
        
    Raises:
        ValidationError: If validation fails
    """
    validator = InputValidator()
    is_valid, error_message = validator.validate_domain(domain)
    if not is_valid:
        raise ValidationError(error_message)


def validate_model_path(model_path: str) -> None:
    """
    [DEPRECATED] Validate semantic model path - use validate_semantic_view() instead.
    
    Args:
        model_path: Semantic view name to validate
        
    Raises:
        ValidationError: If validation fails
    """
    validate_semantic_view(model_path)


def validate_semantic_view(semantic_view: str) -> None:
    """
    Validate semantic view name and raise ValidationError if invalid.
    
    Args:
        semantic_view: Semantic view name to validate
        
    Raises:
        ValidationError: If validation fails
    """
    validator = InputValidator()
    is_valid, error_message = validator.validate_semantic_view(semantic_view)
    if not is_valid:
        raise ValidationError(error_message)


def validate_sql(sql_query: str, allow_modifications: bool = False) -> None:
    """
    Validate SQL query and raise ValidationError if invalid.
    
    Args:
        sql_query: SQL query to validate
        allow_modifications: Whether to allow INSERT/UPDATE/DELETE operations
        
    Raises:
        ValidationError: If validation fails
    """
    validator = InputValidator()
    is_valid, error_message = validator.validate_sql_query(sql_query, allow_modifications)
    if not is_valid:
        raise ValidationError(error_message)


def sanitize_text(text: str) -> str:
    """
    Sanitize input text by removing potentially harmful content.
    
    Args:
        text: Text to sanitize
        
    Returns:
        str: Sanitized text
    """
    validator = InputValidator()
    return validator.sanitize_input_text(text)


# Create a singleton validator instance
input_validator = InputValidator()