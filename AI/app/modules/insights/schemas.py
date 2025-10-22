"""
Insights AI Schemas Module

This module contains Pydantic data models for:
- Cortex Analyst query requests and responses
- Domain and semantic view schemas
- SQL execution schemas  
- Feedback submission schemas
"""

from pydantic import BaseModel, Field, validator
from typing import List, Optional, Dict, Any, Union
from enum import Enum

# Import config loader for dynamic domain validation
from app.modules.insights.config_loader import get_all_domains, get_all_semantic_views


def get_dynamic_domain_example():
    """Get dynamic allowed domains for schema examples"""
    try:
        return get_all_domains()
    except Exception:
        # Fallback in case config is not available
        return ["policy", "claims", "others"]


def get_dynamic_semantic_view_example():
    """Get dynamic semantic view example for schema examples"""
    try:
        views = get_all_semantic_views()
        return views[0] if views else "VAULT_AI_UAT.INSIGHTS.SV_DAILY_INFORCE_POLICY"
    except Exception:
        # Fallback in case config is not available
        return "VAULT_AI_UAT.INSIGHTS.SV_DAILY_INFORCE_POLICY"


def get_dynamic_domain_models_example():
    """Get dynamic models example for a domain"""
    try:
        from app.modules.insights.config_loader import get_models_for_domain, get_semantic_view_domains
        domains = get_all_domains()
        if domains:
            first_domain = domains[0]
            models = get_models_for_domain(first_domain)
            domain_data = get_semantic_view_domains().get(first_domain, {})
            return {
                "key": first_domain,
                "name": domain_data.get("name", first_domain.title()),
                "description": domain_data.get("description", f"{first_domain.title()} domain analysis"),
                "model_count": len(models),
                "models": models[:3]  # Limit to first 3 for example
            }
    except Exception:
        pass
    
    # Fallback
    return {
        "key": "policy",
        "name": "Policy Management",
        "description": "Insurance policy data and lifecycle analysis",
        "model_count": 2,
        "models": [
            "VAULT_AI_UAT.INSIGHTS.SV_POLICY_LIFECYCLE",
            "VAULT_AI_UAT.INSIGHTS.SV_DAILY_INFORCE_POLICY"
        ]
    }


def get_dynamic_domain_response_example():
    """Get dynamic example for domain response with all domains"""
    try:
        from app.modules.insights.config_loader import get_models_for_domain, get_semantic_view_domains
        domains = get_all_domains()
        domain_configs = get_semantic_view_domains()
        
        domain_examples = []
        total_models = 0
        
        for domain_key in domains:
            models = get_models_for_domain(domain_key)
            domain_data = domain_configs.get(domain_key, {})
            
            domain_examples.append({
                "key": domain_key,
                "name": domain_data.get("name", domain_key.title()),
                "description": domain_data.get("description", f"{domain_key.title()} domain analysis"),
                "model_count": len(models),
                "models": models[:2]  # Limit to first 2 for example
            })
            total_models += len(models)
        
        return {
            "domains": domain_examples,
            "total_domains": len(domains),
            "total_models": total_models
        }
    except Exception:
        pass
    
    # Fallback
    return {
        "domains": [
            {
                "key": "policy",
                "name": "Policy Management", 
                "description": "Insurance policy data and lifecycle analysis",
                "model_count": 2,
                "models": ["VAULT_AI_UAT.INSIGHTS.SV_POLICY_LIFECYCLE"]
            }
        ],
        "total_domains": 3,
        "total_models": 6
    }


def get_dynamic_semantic_model_example():
    """Get dynamic example for semantic model info"""
    try:
        from app.modules.insights.config_loader import get_semantic_view_metadata, get_models_for_domain
        domains = get_all_domains()
        if domains:
            first_domain = domains[0]
            models = get_models_for_domain(first_domain)
            if models:
                metadata = get_semantic_view_metadata(first_domain, models[0])
                if metadata:
                    return {
                        "path": metadata["path"],
                        "name": metadata["display_name"],
                        "description": metadata.get("description", "Semantic view analysis"),
                        "is_default": metadata.get("is_default", False)
                    }
    except Exception:
        pass
    
    # Fallback
    return {
        "path": "VAULT_AI_UAT.INSIGHTS.SV_POLICY_LIFECYCLE",
        "name": "Policy Lifecycle Analysis",
        "description": "Comprehensive policy lifecycle and status tracking",
        "is_default": True
    }


def get_dynamic_semantic_model_response_example():
    """Get dynamic example for complete semantic model response"""
    try:
        from app.modules.insights.config_loader import (
            get_semantic_view_metadata, 
            get_models_for_domain, 
            get_semantic_view_domains
        )
        domains = get_all_domains()
        if domains:
            first_domain = domains[0]
            domain_configs = get_semantic_view_domains()
            domain_data = domain_configs.get(first_domain, {})
            models = get_models_for_domain(first_domain)
            
            model_examples = []
            default_model = None
            
            for model_path in models[:2]:  # Limit to 2 for example
                metadata = get_semantic_view_metadata(first_domain, model_path)
                if metadata:
                    model_info = {
                        "path": metadata["path"],
                        "name": metadata["display_name"],
                        "description": metadata.get("description", ""),
                        "is_default": metadata.get("is_default", False)
                    }
                    model_examples.append(model_info)
                    
                    if metadata.get("is_default", False):
                        default_model = model_info
            
            return {
                "domain": first_domain,
                "domain_info": {
                    "key": first_domain,
                    "name": domain_data.get("name", first_domain.title()),
                    "description": domain_data.get("description", f"{first_domain.title()} domain analysis"),
                    "model_count": len(models),
                    "models": []
                },
                "models": model_examples,
                "default_model": default_model
            }
    except Exception:
        pass
    
    # Fallback
    return {
        "domain": "policy",
        "domain_info": {
            "key": "policy",
            "name": "Policy Management",
            "description": "Insurance policy data and lifecycle analysis",
            "model_count": 2,
            "models": []
        },
        "models": [
            {
                "path": "VAULT_AI_UAT.INSIGHTS.SV_POLICY_LIFECYCLE",
                "name": "Policy Lifecycle Analysis",
                "description": "Comprehensive policy lifecycle tracking",
                "is_default": True
            }
        ],
        "default_model": {
            "path": "VAULT_AI_UAT.INSIGHTS.SV_POLICY_LIFECYCLE",
            "name": "Policy Lifecycle Analysis",
            "description": "Comprehensive policy lifecycle tracking",
            "is_default": True
        }
    }


class ContentType(str, Enum):
    """Content types for message content"""
    TEXT = "text"
    SQL = "sql" 
    SUGGESTIONS = "suggestions"


class MessageRole(str, Enum):
    """Message roles for conversation history"""
    USER = "user"
    ANALYST = "analyst"


class MessageContent(BaseModel):
    """Individual content item within a message"""
    type: ContentType = Field(..., description="Type of content (text, sql, suggestions)")
    text: Optional[str] = Field(None, description="Text content for text type")
    statement: Optional[str] = Field(None, description="SQL statement for sql type")
    suggestions: Optional[List[str]] = Field(None, description="List of suggestions")
    
    class Config:
        json_schema_extra = {
            "examples": [
                {"type": "text", "text": "The analysis shows that..."},
                {"type": "sql", "statement": "SELECT COUNT(*) FROM policies"},
                {"type": "suggestions", "suggestions": ["Show trends", "Compare regions"]}
            ]
        }


class ConversationMessage(BaseModel):
    """Complete message structure for conversation history"""
    role: MessageRole = Field(..., description="Role of the message sender (user or analyst)")
    content: List[MessageContent] = Field(..., description="List of content items in the message")
    
    class Config:
        json_schema_extra = {
            "example": {
                "role": "user",
                "content": [{"type": "text", "text": "What is the total policy count?"}]
            }
        }


class AnalystRequest(BaseModel):
    """Request model for Cortex Analyst queries"""
    question: str = Field(..., min_length=1, max_length=1000, description="Natural language question")
    semantic_view: str = Field(..., description="Semantic view name to use (required for Cortex Analyst)")
    domain: Optional[str] = Field(None, description="Semantic view domain (sales, policy, claims, others) - optional for categorization")
    message_history: Optional[List[ConversationMessage]] = Field(
        default=[], 
        max_items=10,
        description="Previous conversation messages for context"
    )
    conversation_id: Optional[str] = Field(None, description="Conversation ID for tracking")
    
    @validator('question')
    def validate_question(cls, v):
        if not v.strip():
            raise ValueError('Question cannot be empty or whitespace only')
        return v.strip()
    
    @validator('domain')
    def validate_domain(cls, v):
        if v is not None:
            allowed_domains = get_all_domains()
            if v not in allowed_domains:
                raise ValueError(f'Domain must be one of: {allowed_domains}')
        return v
    
    class Config:
        json_schema_extra = {
            "example": {
                "question": "What is the total daily in-force policy count?",
                "semantic_view": get_dynamic_semantic_view_example(),
                "domain": get_dynamic_domain_example()[0] if get_dynamic_domain_example() else "policy",
                "message_history": []
            }
        }


class SemanticModel(BaseModel):
    """Model for individual semantic view specification"""
    semantic_view: str = Field(..., description="Fully qualified name of the semantic view")
    
    class Config:
        json_schema_extra = {
            "example": {
                "semantic_view": "my_db.my_sch.my_sem_view_1"
            }
        }


class AnalystRequestV2(BaseModel):
    """Request model for Cortex Analyst queries with multiple semantic models (v2)"""
    question: str = Field(..., min_length=1, max_length=1000, description="Natural language question")
    semantic_models: List[SemanticModel] = Field(..., min_items=1, max_items=10, description="List of semantic models for Cortex Analyst to choose from")
    domain: Optional[str] = Field(None, description="Semantic view domain (sales, policy, claims, others) - optional for categorization")
    message_history: Optional[List[ConversationMessage]] = Field(
        default=[], 
        max_items=10,
        description="Previous conversation messages for context"
    )
    conversation_id: Optional[str] = Field(None, description="Conversation ID for tracking")
    
    @validator('question')
    def validate_question(cls, v):
        if not v.strip():
            raise ValueError('Question cannot be empty or whitespace only')
        return v.strip()
    
    @validator('domain')
    def validate_domain(cls, v):
        if v is not None:
            allowed_domains = get_all_domains()
            if v not in allowed_domains:
                raise ValueError(f'Domain must be one of: {allowed_domains}')
        return v
    
    @validator('semantic_models')
    def validate_semantic_models(cls, v):
        if not v:
            raise ValueError('At least one semantic model must be provided')
        # Validate each semantic view name
        for model in v:
            if not model.semantic_view or not model.semantic_view.strip():
                raise ValueError('Semantic view name cannot be empty')
        return v
    
    class Config:
        json_schema_extra = {
            "example": {
                "question": "What is the total daily in-force policy count?",
                "semantic_models": [
                    {"semantic_view": "my_db.my_sch.my_sem_view_1"},
                    {"semantic_view": "my_db.my_sch.my_sem_view_2"}
                ],
                "domain": get_dynamic_domain_example()[0] if get_dynamic_domain_example() else "policy",
                "message_history": []
            }
        }


class AnalystResponse(BaseModel):
    """Response model for Cortex Analyst queries"""
    message: List[MessageContent] = Field(..., description="Response content from Cortex Analyst")
    request_id: Optional[str] = Field(None, description="Request ID for feedback correlation")
    warnings: Optional[List[Union[str, Dict[str, Any]]]] = Field(default=[], description="Any warnings from the analysis")
    conversation_id: Optional[str] = Field(None, description="Conversation ID for tracking")
    processing_time_seconds: Optional[float] = Field(None, description="Processing time in seconds")
    semantic_view_used: Optional[str] = Field(None, description="Semantic view used")
    domain: Optional[str] = Field(None, description="Domain used")
    suggestions: Optional[List[str]] = Field(default=None, description="AI-generated follow-up question suggestions")
    
    class Config:
        json_schema_extra = {
            "example": {
                "message": [
                    {"type": "text", "text": "Based on the analysis of policy data..."},
                    {"type": "sql", "statement": "SELECT COUNT(*) as total_policies FROM SV_DAILY_INFORCE_POLICY"}
                ],
                "request_id": "req_12345",
                "warnings": [],
                "conversation_id": "insights_conv_67890",
                "suggestions": [
                    "AI-generated follow-up question 1",
                    "AI-generated follow-up question 2",
                    "AI-generated follow-up question 3"
                ]
            }
        }


class DomainInfo(BaseModel):
    """Information about a semantic view domain"""
    key: str = Field(..., description="Domain key identifier")
    name: str = Field(..., description="Display name of the domain")
    description: str = Field(..., description="Description of the domain's purpose")
    model_count: int = Field(..., description="Number of semantic views in this domain")
    models: List[str] = Field(..., description="List of semantic view names")
    
    class Config:
        json_schema_extra = {
            "example": get_dynamic_domain_models_example()
        }


class DomainRequest(BaseModel):
    """Request model for domain information (typically no body needed for GET)"""
    include_models: Optional[bool] = Field(True, description="Whether to include model list in response")


class DomainResponse(BaseModel):
    """Response model for available domains"""
    domains: List[DomainInfo] = Field(..., description="List of available semantic view domains")
    total_domains: int = Field(..., description="Total number of domains")
    total_models: int = Field(..., description="Total number of semantic views across all domains")
    
    class Config:
        json_schema_extra = {
            "example": get_dynamic_domain_response_example()
        }


class SemanticModelInfo(BaseModel):
    """Information about a specific semantic view"""
    path: str = Field(..., description="Full name of the semantic view")
    name: str = Field(..., description="Display name of the view")
    description: Optional[str] = Field(None, description="Description of the view's purpose")
    is_default: Optional[bool] = Field(False, description="Whether this is the default view for the domain")
    
    class Config:
        json_schema_extra = {
            "example": get_dynamic_semantic_model_example()
        }


class SemanticModelRequest(BaseModel):
    """Request model for semantic view information by domain"""
    domain: str = Field(..., description="Domain to get views for")
    
    @validator('domain')
    def validate_domain(cls, v):
        allowed_domains = get_all_domains()
        if v not in allowed_domains:
            raise ValueError(f'Domain must be one of: {allowed_domains}')
        return v


class SemanticModelResponse(BaseModel):
    """Response model for semantic views in a domain"""
    domain: str = Field(..., description="Domain name")
    domain_info: DomainInfo = Field(..., description="Domain information")
    models: List[SemanticModelInfo] = Field(..., description="List of semantic views")
    default_model: Optional[SemanticModelInfo] = Field(None, description="Default view for this domain")
    
    class Config:
        json_schema_extra = {
            "example": get_dynamic_semantic_model_response_example()
        }


class SQLExecutionRequest(BaseModel):
    """Request model for SQL query execution"""
    query: str = Field(..., min_length=1, description="SQL query to execute")
    conversation_id: Optional[str] = Field(None, description="Conversation ID for tracking")
    limit: Optional[int] = Field(100, ge=1, le=1000, description="Maximum number of rows to return")
    
    @validator('query')
    def validate_query(cls, v):
        if not v.strip():
            raise ValueError('Query cannot be empty or whitespace only')
        # Basic SQL injection prevention
        dangerous_keywords = ['DROP', 'DELETE', 'TRUNCATE', 'ALTER', 'CREATE', 'INSERT', 'UPDATE']
        query_upper = v.upper()
        for keyword in dangerous_keywords:
            if keyword in query_upper:
                raise ValueError(f'Query contains potentially dangerous keyword: {keyword}')
        return v.strip()
    
    class Config:
        json_schema_extra = {
            "example": {
                "query": "SELECT COUNT(*) as total_policies FROM SV_DAILY_INFORCE_POLICY",
                "conversation_id": "insights_conv_67890",
                "limit": 100
            }
        }


class SQLExecutionResponse(BaseModel):
    """Response model for SQL query execution results"""
    columns: List[str] = Field(..., description="Column names from the query result")
    data: List[List[Any]] = Field(..., description="Query result data as list of rows")
    row_count: int = Field(..., description="Number of rows returned")
    execution_time_ms: int = Field(..., description="Query execution time in milliseconds")
    conversation_id: Optional[str] = Field(None, description="Conversation ID for tracking")
    query_hash: Optional[str] = Field(None, description="Hash of the executed query for caching")
    
    class Config:
        json_schema_extra = {
            "example": {
                "columns": ["total_policies"],
                "data": [[15234]],
                "row_count": 1,
                "execution_time_ms": 245,
                "conversation_id": "insights_conv_67890"
            }
        }


class FeedbackRequest(BaseModel):
    """Request model for user feedback submission"""
    request_id: str = Field(..., description="Request ID from Cortex Analyst response")
    positive: bool = Field(..., description="Whether the feedback is positive (true) or negative (false)")
    feedback_message: Optional[str] = Field(
        None, 
        max_length=500,
        description="Optional text feedback message"
    )
    conversation_id: Optional[str] = Field(None, description="Conversation ID for tracking")
    
    class Config:
        json_schema_extra = {
            "example": {
                "request_id": "req_12345",
                "positive": True,
                "feedback_message": "Great analysis and helpful SQL query!",
                "conversation_id": "insights_conv_67890"
            }
        }


class FeedbackResponse(BaseModel):
    """Response model for feedback submission"""
    success: bool = Field(..., description="Whether feedback was submitted successfully")
    feedback_id: Optional[str] = Field(None, description="Feedback tracking ID")
    message: str = Field(..., description="Confirmation or error message")
    
    class Config:
        json_schema_extra = {
            "example": {
                "success": True,
                "feedback_id": "fb_98765",
                "message": "Feedback submitted successfully"
            }
        }


class ErrorResponse(BaseModel):
    """Standard error response model"""
    error: str = Field(..., description="Error type or code")
    message: str = Field(..., description="Human-readable error message")
    details: Optional[Dict[str, Any]] = Field(None, description="Additional error details")
    request_id: Optional[str] = Field(None, description="Request ID for tracking")
    
    class Config:
        json_schema_extra = {
            "example": {
                "error": "VALIDATION_ERROR",
                "message": "Invalid domain specified",
                "details": {"allowed_domains": get_dynamic_domain_example()},
                "request_id": "req_error_123"
            }
        }


class HealthCheckResponse(BaseModel):
    """Health check response model"""
    status: str = Field(..., description="Service status")
    timestamp: str = Field(..., description="Current timestamp")
    version: str = Field(..., description="Module version")
    snowflake_connected: bool = Field(..., description="Whether Snowflake connection is working")
    cortex_api_accessible: Optional[bool] = Field(None, description="Whether Cortex API is accessible")
    
    class Config:
        json_schema_extra = {
            "example": {
                "status": "healthy",
                "timestamp": "2025-09-24T19:30:00Z",
                "version": "1.0.0",
                "snowflake_connected": True,
                "cortex_api_accessible": True
            }
        }