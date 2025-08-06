from pydantic import BaseModel
from typing import List, Optional

class RAGRequest(BaseModel):
    question: str
    chat_history: Optional[List[str]] = []
    llm_model: str

class RAGResponse(BaseModel):
    answer: str
