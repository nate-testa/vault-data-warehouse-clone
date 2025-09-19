"""
DocuClaims Schemas Module

This module contains all Pydantic models for DocuClaims functionality including:
- RAG request and response models
- Data validation schemas
"""

from pydantic import BaseModel
from typing import List, Optional

class RAGRequest(BaseModel):
    question: str
    chat_history: Optional[List[str]] = []
    llm_model: str

class RAGResponse(BaseModel):
    answer: str
