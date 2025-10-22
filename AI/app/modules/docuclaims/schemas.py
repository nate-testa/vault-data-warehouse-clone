"""
DocuClaims Schemas Module

This module contains all Pydantic models for DocuClaims functionality including:
- RAG request and response models
- Follow-up questions request and response models
- Data validation schemas
"""

from pydantic import BaseModel
from typing import List, Optional

class RAGRequest(BaseModel):
    question: str
    chat_history: Optional[List[str]] = []
    llm_model: str
    include_followup: Optional[bool] = False

class RAGResponse(BaseModel):
    answer: str
    followup_questions: Optional[List[str]] = None


class FollowUpRequest(BaseModel):
    user_question: str
    ai_response: str
    conversation_history: Optional[List[str]] = []
    session_id: Optional[str] = None
    model: str


class FollowUpResponse(BaseModel):
    success: bool
    followup_questions: List[str]
