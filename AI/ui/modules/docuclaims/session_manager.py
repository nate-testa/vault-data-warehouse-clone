"""
DocuClaims-specific session management.

This module provides session management specifically for DocuClaims functionality,
including chat messages, file uploads, and RAG-related preferences.
"""

from flask import session
from typing import Dict, List, Any, Optional, Union
from utils.ui_session_manager import UISessionManager
from utils.logging import logger


class DocuClaimsSessionManager(UISessionManager):
    """
    Session manager for DocuClaims-specific functionality.
    
    This class now contains all DocuClaims-specific session management methods,
    providing complete isolation and modularization for DocuClaims functionality.
    """
    
    # DocuClaims-specific session keys
    CHAT_MESSAGES_KEY = 'rag_messages'
    RAG_WARNINGS_KEY = 'rag_warnings'
    FILE_UPLOADED_KEY = 'file_uploaded'
    UPLOADED_FILENAME_KEY = 'uploaded_filename'
    USE_CHAT_HISTORY_KEY = 'use_chat_history'
    SELECTED_MODEL_KEY = 'selected_model'
    
    def __init__(self, max_cookie_size: int = 3500, max_chat_messages: int = 8):
        """
        Initialize DocuClaims session manager.
        
        Args:
            max_cookie_size (int): Maximum cookie size in bytes
            max_chat_messages (int): Maximum number of chat messages to keep
        """
        super().__init__(max_cookie_size)  # UISessionManager now only takes max_cookie_size
        self.max_chat_messages = max_chat_messages
    
    def initialize_docuclaims_session(self):
        """Initialize DocuClaims session variables with default values."""
        if self.CHAT_MESSAGES_KEY not in session:
            session[self.CHAT_MESSAGES_KEY] = []
        if self.FILE_UPLOADED_KEY not in session:
            session[self.FILE_UPLOADED_KEY] = False
        if self.UPLOADED_FILENAME_KEY not in session:
            session[self.UPLOADED_FILENAME_KEY] = None
        if self.USE_CHAT_HISTORY_KEY not in session:
            session[self.USE_CHAT_HISTORY_KEY] = True
        if self.RAG_WARNINGS_KEY not in session:
            session[self.RAG_WARNINGS_KEY] = []
    
    def add_chat_message(self, message: Dict[str, str], cleanup_threshold: Optional[int] = None) -> bool:
        """
        Add a chat message to the session with automatic cleanup to prevent overflow.
        
        Args:
            message (Dict[str, str]): Message with 'role' and 'content' keys
            cleanup_threshold (Optional[int]): Custom threshold for cleanup
            
        Returns:
            bool: True if message was added successfully
        """
        try:
            messages = session.get(self.CHAT_MESSAGES_KEY, [])
            
            # Add the new message
            messages.append(message)
            
            # Apply cleanup if needed
            threshold = cleanup_threshold or self.max_chat_messages
            if len(messages) > threshold:
                # Keep only the most recent messages
                messages_to_remove = len(messages) - threshold
                messages = messages[messages_to_remove:]
                
                logger.info(
                    f"[DOCUCLAIMS_SESSION] Cleaned up chat history: removed {messages_to_remove} old messages, "
                    f"kept {len(messages)} recent messages"
                )
            
            # Check estimated size and perform additional cleanup if needed
            if self._is_session_size_critical(messages):
                # More aggressive cleanup
                messages = messages[-4:]  # Keep only last 4 messages
                logger.warning(
                    f"[DOCUCLAIMS_SESSION] Critical session size detected, aggressive cleanup applied. "
                    f"Kept only {len(messages)} messages"
                )
            
            session[self.CHAT_MESSAGES_KEY] = messages
            return True
            
        except Exception as e:
            logger.error(f"[DOCUCLAIMS_SESSION] Error adding chat message: {str(e)}")
            return False
    
    def get_chat_messages(self, limit: Optional[int] = None) -> List[Dict[str, str]]:
        """
        Get chat messages from session.
        
        Args:
            limit (Optional[int]): Maximum number of messages to return
            
        Returns:
            List[Dict[str, str]]: List of chat messages
        """
        messages = session.get(self.CHAT_MESSAGES_KEY, [])
        
        if limit is not None and limit > 0:
            return messages[-limit:]
        
        return messages
    
    def get_chat_history_for_context(self, slide_window: int = 5) -> List[str]:
        """
        Get chat history content for API context.
        
        Args:
            slide_window (int): Number of recent messages to include
            
        Returns:
            List[str]: List of message contents
        """
        messages = self.get_chat_messages()
        # Use smaller slide window to ensure we don't exceed session limits
        effective_window = min(slide_window, 6)
        start_index = max(0, len(messages) - effective_window)
        
        return [messages[i]["content"] for i in range(start_index, len(messages))]
    
    def clear_chat_messages(self):
        """Clear all chat messages from session."""
        session[self.CHAT_MESSAGES_KEY] = []
        session[self.RAG_WARNINGS_KEY] = []
    
    def set_file_upload_status(self, uploaded: bool, filename: Optional[Union[str, List[str]]] = None):
        """
        Set file upload status in session.
        
        Args:
            uploaded (bool): Whether files are uploaded
            filename (Optional[Union[str, List[str]]]): Filename(s) that were uploaded
        """
        session[self.FILE_UPLOADED_KEY] = uploaded
        session[self.UPLOADED_FILENAME_KEY] = filename
    
    def get_file_upload_status(self) -> Dict[str, Any]:
        """
        Get file upload status from session.
        
        Returns:
            Dict[str, Any]: File upload status and filenames
        """
        return {
            'uploaded': session.get(self.FILE_UPLOADED_KEY, False),
            'filenames': session.get(self.UPLOADED_FILENAME_KEY, None)
        }
    
    def set_docuclaims_preference(self, key: str, value: Any):
        """
        Set DocuClaims user preference in session.
        
        Args:
            key (str): Preference key
            value (Any): Preference value
        """
        valid_keys = [self.USE_CHAT_HISTORY_KEY, self.SELECTED_MODEL_KEY]
        
        if key in valid_keys:
            session[key] = value
        else:
            raise ValueError(f"Invalid DocuClaims preference key: {key}")
    
    def get_docuclaims_preference(self, key: str, default: Any = None) -> Any:
        """
        Get DocuClaims user preference from session.
        
        Args:
            key (str): Preference key
            default (Any): Default value if key not found
            
        Returns:
            Any: Preference value or default
        """
        return session.get(key, default)
    
    def reset_all_docuclaims_data(self):
        """Reset all DocuClaims-related session data to defaults."""
        session[self.CHAT_MESSAGES_KEY] = []
        session[self.RAG_WARNINGS_KEY] = []
        session[self.FILE_UPLOADED_KEY] = False
        session[self.UPLOADED_FILENAME_KEY] = None
        # Preserve use_chat_history and selected_model as user preferences
    
    def _is_session_size_critical(self, messages: List[Dict[str, str]]) -> bool:
        """
        Check if session size is approaching critical limits for DocuClaims.
        
        Args:
            messages (List[Dict[str, str]]): Current messages list
            
        Returns:
            bool: True if size is critical
        """
        # Quick size check based on message content
        total_content_size = sum(
            len(msg.get('content', '')) + len(msg.get('role', ''))
            for msg in messages
        )
        
        # Add overhead for JSON structure and other session data
        estimated_total = total_content_size * 1.3  # 30% overhead
        
        return estimated_total > self.max_cookie_size * 0.9  # 90% threshold
    
    def get_docuclaims_session_stats(self) -> Dict[str, Any]:
        """
        Get DocuClaims-specific session statistics.
        
        Returns:
            Dict[str, Any]: DocuClaims session statistics
        """
        messages = session.get(self.CHAT_MESSAGES_KEY, [])
        
        return {
            'module': 'docuclaims',
            'chat_message_count': len(messages),
            'estimated_size_bytes': self.get_session_size_estimate(),
            'max_allowed_size': self.max_cookie_size,
            'size_utilization_percent': round(
                (self.get_session_size_estimate() / self.max_cookie_size) * 100, 2
            ),
            'files_uploaded': session.get(self.FILE_UPLOADED_KEY, False),
            'chat_history_enabled': session.get(self.USE_CHAT_HISTORY_KEY, True),
            'selected_model': session.get(self.SELECTED_MODEL_KEY, None)
        }
    
    def get_session_size_estimate(self) -> int:
        """
        Estimate the current DocuClaims session size in bytes.
        
        Returns:
            int: Estimated session size in bytes
        """
        try:
            # Get DocuClaims-related session data
            docuclaims_data = {
                key: session.get(key) for key in [
                    self.CHAT_MESSAGES_KEY, self.FILE_UPLOADED_KEY,
                    self.UPLOADED_FILENAME_KEY, self.USE_CHAT_HISTORY_KEY, 
                    self.SELECTED_MODEL_KEY, self.RAG_WARNINGS_KEY
                ] if key in session
            }
            
            # Estimate size by serializing to JSON
            import json
            json_str = json.dumps(docuclaims_data, separators=(',', ':'))
            return len(json_str.encode('utf-8'))
            
        except Exception:
            # Fallback estimation
            messages = session.get(self.CHAT_MESSAGES_KEY, [])
            return sum(len(str(msg)) for msg in messages) if messages else 0