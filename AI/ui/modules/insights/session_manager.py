"""
Insights-specific session management.

This module provides session management specifically for Insights functionality,
including chat messages, domain selection, conversation context, and feedback tracking.
"""

from flask import session
from typing import Dict, List, Any, Optional, Union
from utils.ui_session_manager import UISessionManager
from utils.logging import logger
from datetime import datetime, timedelta
import json
import hashlib


class InsightsSessionManager(UISessionManager):
    """
    Session manager for Insights-specific functionality.
    
    This class manages session state for the Insights chat interface, including:
    - Conversation history with message threading
    - Domain and semantic model persistence
    - User preferences and selections
    - Feedback form submission tracking
    - Active suggestions and conversation state
    """
    
    # Insights-specific session keys
    CHAT_MESSAGES_KEY = 'insights_messages'
    SELECTED_DOMAIN_KEY = 'insights_selected_domain'
    SELECTED_MODEL_KEY = 'insights_selected_model'
    DOMAIN_MODELS_KEY = 'insights_domain_models'
    CONVERSATION_ID_KEY = 'insights_conversation_id'
    ACTIVE_SUGGESTIONS_KEY = 'insights_active_suggestions'
    FEEDBACK_TRACKING_KEY = 'insights_feedback_tracking'
    USER_PREFERENCES_KEY = 'insights_user_preferences'
    CONVERSATION_CONTEXT_KEY = 'insights_conversation_context'
    WELCOME_SHOWN_KEY = 'insights_welcome_shown'
    RESULT_CACHE_KEY = 'insights_result_cache'
    
    def __init__(self, max_cookie_size: int = 2500, max_chat_messages: int = 3):
        """
        Initialize Insights session manager.
        
        Args:
            max_cookie_size (int): Maximum cookie size in bytes (reduced for safety)
            max_chat_messages (int): Maximum number of chat messages to keep (reduced to prevent overflow)
        """
        super().__init__(max_cookie_size)
        self.max_chat_messages = max_chat_messages
    
    def initialize_insights_session(self):
        """Initialize Insights session variables with default values."""
        if self.CHAT_MESSAGES_KEY not in session:
            session[self.CHAT_MESSAGES_KEY] = []
            
        if self.SELECTED_DOMAIN_KEY not in session:
            session[self.SELECTED_DOMAIN_KEY] = 'policy'  # Default domain
            
        if self.SELECTED_MODEL_KEY not in session:
            session[self.SELECTED_MODEL_KEY] = None
            
        if self.DOMAIN_MODELS_KEY not in session:
            session[self.DOMAIN_MODELS_KEY] = {}
            
        if self.CONVERSATION_ID_KEY not in session:
            session[self.CONVERSATION_ID_KEY] = None
            
        if self.ACTIVE_SUGGESTIONS_KEY not in session:
            session[self.ACTIVE_SUGGESTIONS_KEY] = []
            
        if self.FEEDBACK_TRACKING_KEY not in session:
            session[self.FEEDBACK_TRACKING_KEY] = {}
            
        if self.USER_PREFERENCES_KEY not in session:
            session[self.USER_PREFERENCES_KEY] = {
                'auto_scroll': True,
                'show_sql_by_default': True,
                'enable_suggestions': True,
                'use_chat_history': False  # Default: disabled
            }
            
        if self.CONVERSATION_CONTEXT_KEY not in session:
            session[self.CONVERSATION_CONTEXT_KEY] = {
                'domain_switched_at': None,
                'last_model_used': None,
                'conversation_started_at': datetime.now().isoformat()
            }
            
        if self.WELCOME_SHOWN_KEY not in session:
            session[self.WELCOME_SHOWN_KEY] = False
    
    def add_chat_message(self, message: Dict[str, Any], cleanup_threshold: Optional[int] = None) -> bool:
        """
        Add a chat message to the session with metadata and automatic cleanup.
        
        Args:
            message (Dict[str, Any]): Message with role, content, and metadata
            cleanup_threshold (Optional[int]): Custom threshold for cleanup
            
        Returns:
            bool: True if message was added successfully
        """
        try:
            messages = session.get(self.CHAT_MESSAGES_KEY, [])
            
            # Add timestamp and message ID if not present
            if 'timestamp' not in message:
                message['timestamp'] = datetime.now().isoformat()
            if 'message_id' not in message:
                message['message_id'] = f"msg_{len(messages)}_{int(datetime.now().timestamp())}"
            
            # Clean message content to reduce size
            message = self._clean_message_for_session(message)
            
            # Add the new message
            messages.append(message)
            
            # Apply cleanup if needed - keep fewer messages
            threshold = cleanup_threshold or self.max_chat_messages
            if len(messages) > threshold:
                messages_to_remove = len(messages) - threshold
                messages = messages[messages_to_remove:]
                
                logger.info(
                    f"[INSIGHTS_SESSION] Cleaned up chat history: removed {messages_to_remove} old messages, "
                    f"kept {len(messages)} recent messages"
                )
            
            # Check session size and perform additional cleanup if needed
            if self._is_session_size_critical(messages):
                # Keep only last 2 messages for aggressive cleanup
                messages = messages[-2:]
                logger.warning(
                    f"[INSIGHTS_SESSION] Critical session size detected, aggressive cleanup applied. "
                    f"Kept only {len(messages)} messages"
                )
            
            session[self.CHAT_MESSAGES_KEY] = messages
            
            # Log session size for monitoring
            self._log_session_size_stats()
            
            return True
            
        except Exception as e:
            logger.error(f"[INSIGHTS_SESSION] Error adding chat message: {str(e)}")
            return False

    def remove_last_chat_message(self) -> bool:
        """
        Remove the last chat message from the session.
        
        Returns:
            bool: True if message was removed successfully, False if no messages or error
        """
        try:
            messages = session.get(self.CHAT_MESSAGES_KEY, [])
            
            if not messages:
                logger.warning("[INSIGHTS_SESSION] No messages to remove")
                return False
            
            # Remove the last message
            removed_message = messages.pop()
            session[self.CHAT_MESSAGES_KEY] = messages
            
            logger.info(f"[INSIGHTS_SESSION] Removed last chat message (role: {removed_message.get('role', 'unknown')})")
            return True
            
        except Exception as e:
            logger.error(f"[INSIGHTS_SESSION] Error removing last chat message: {str(e)}")
            return False
    
    def get_chat_messages(self, limit: Optional[int] = None) -> List[Dict[str, Any]]:
        """
        Get chat messages from session.
        
        Args:
            limit (Optional[int]): Maximum number of messages to return
            
        Returns:
            List[Dict[str, Any]]: List of chat messages with metadata
        """
        messages = session.get(self.CHAT_MESSAGES_KEY, [])
        
        if limit is not None and limit > 0:
            return messages[-limit:]
        
        return messages
    
    def get_conversation_history_for_api(self, slide_window: int = 6) -> List[Dict[str, Any]]:
        """
        Get conversation history formatted for API context.
        
        Args:
            slide_window (int): Number of recent messages to include
            
        Returns:
            List[Dict[str, Any]]: List of messages formatted for API ConversationMessage schema
        """
        messages = self.get_chat_messages()
        effective_window = min(slide_window, 8)  # Ensure reasonable limit
        start_index = max(0, len(messages) - effective_window)

        api_messages = []
        last_role = None
        
        for i in range(start_index, len(messages)):
            msg = messages[i]
            # Map UI role 'assistant' to API role 'analyst'
            ui_role = msg.get('role', 'user')
            api_role = 'analyst' if ui_role == 'assistant' else ui_role
            
            # Debug logging to track role mapping
            logger.debug(f"[INSIGHTS_SESSION] Message {i}: UI role='{ui_role}' -> API role='{api_role}'")
            
            # Skip messages with consecutive same roles (Cortex Analyst requirement)
            if api_role == last_role:
                logger.debug(f"[INSIGHTS_SESSION] Skipping message {i} - consecutive role '{api_role}'")
                continue
            
            # Format content for API schema - content must be List[MessageContent]
            msg_content = msg.get('content', '')
            if isinstance(msg_content, str):
                # Simple string content - convert to MessageContent format
                formatted_content = [{"type": "text", "text": msg_content}]
            elif isinstance(msg_content, list):
                # Already in structured format - filter out SQL blocks for API
                # SQL blocks should not be sent back to API as they cause validation errors
                formatted_content = [
                    item for item in msg_content 
                    if not (isinstance(item, dict) and item.get('type') == 'sql')
                ]
                
                # If filtering removed all content, keep at least the text blocks
                if not formatted_content:
                    formatted_content = [
                        item for item in msg_content 
                        if isinstance(item, dict) and item.get('type') == 'text'
                    ]
                
                # If still empty, create a placeholder
                if not formatted_content:
                    formatted_content = [{"type": "text", "text": "[Response processed]"}]
            else:
                # Fallback for unexpected format
                formatted_content = [{"type": "text", "text": str(msg_content)}]
            
            api_messages.append({
                'role': api_role,
                'content': formatted_content
            })
            
            last_role = api_role

        logger.debug(f"[INSIGHTS_SESSION] Converted {len(messages)} UI messages to {len(api_messages)} API messages")
        return api_messages
    
    def set_domain_selection(self, domain: str, model_path: Optional[str] = None):
        """
        Set selected domain and optionally semantic model.
        
        Args:
            domain (str): Selected domain (sales, policy, claims, others)
            model_path (Optional[str]): Path to selected semantic model
        """
        # Track domain switching
        current_domain = session.get(self.SELECTED_DOMAIN_KEY)
        if current_domain != domain:
            context = session.get(self.CONVERSATION_CONTEXT_KEY, {})
            context['domain_switched_at'] = datetime.now().isoformat()
            context['previous_domain'] = current_domain
            session[self.CONVERSATION_CONTEXT_KEY] = context
            
            logger.info(f"[INSIGHTS_SESSION] Domain switched from {current_domain} to {domain}")
        
        session[self.SELECTED_DOMAIN_KEY] = domain
        if model_path:
            session[self.SELECTED_MODEL_KEY] = model_path
    
    def get_domain_selection(self) -> Dict[str, Any]:
        """
        Get current domain and model selection.
        
        Returns:
            Dict[str, Any]: Current domain and model information
        """
        return {
            'domain': session.get(self.SELECTED_DOMAIN_KEY, 'policy'),
            'model_path': session.get(self.SELECTED_MODEL_KEY),
            'available_models': session.get(self.DOMAIN_MODELS_KEY, {})
        }
    
    def set_domain_models(self, domain: str, models: List[Dict[str, Any]]):
        """
        Cache available models for a domain.
        
        Args:
            domain (str): Domain name
            models (List[Dict[str, Any]]): List of available semantic models
        """
        domain_models = session.get(self.DOMAIN_MODELS_KEY, {})
        domain_models[domain] = {
            'models': models,
            'cached_at': datetime.now().isoformat()
        }
        session[self.DOMAIN_MODELS_KEY] = domain_models
    
    def get_domain_models(self, domain: str) -> List[Dict[str, Any]]:
        """
        Get cached models for a domain.
        
        Args:
            domain (str): Domain name
            
        Returns:
            List[Dict[str, Any]]: List of models or empty list if not cached
        """
        domain_models = session.get(self.DOMAIN_MODELS_KEY, {})
        return domain_models.get(domain, {}).get('models', [])
    
    def set_active_suggestions(self, suggestions: List[str]):
        """
        Set active suggestions for the current conversation.
        
        Args:
            suggestions (List[str]): List of suggested replies
        """
        session[self.ACTIVE_SUGGESTIONS_KEY] = suggestions
    
    def get_active_suggestions(self) -> List[str]:
        """
        Get current active suggestions.
        
        Returns:
            List[str]: List of suggested replies
        """
        return session.get(self.ACTIVE_SUGGESTIONS_KEY, [])
    
    def track_feedback_submission(self, request_id: str, feedback_data: Dict[str, Any]):
        """
        Track feedback submission for a request.
        
        Args:
            request_id (str): Request identifier
            feedback_data (Dict[str, Any]): Feedback data
        """
        feedback_tracking = session.get(self.FEEDBACK_TRACKING_KEY, {})
        feedback_tracking[request_id] = {
            'feedback': feedback_data,
            'submitted_at': datetime.now().isoformat()
        }
        session[self.FEEDBACK_TRACKING_KEY] = feedback_tracking
    
    def is_feedback_submitted(self, request_id: str) -> bool:
        """
        Check if feedback has been submitted for a request.
        
        Args:
            request_id (str): Request identifier
            
        Returns:
            bool: True if feedback was submitted
        """
        feedback_tracking = session.get(self.FEEDBACK_TRACKING_KEY, {})
        return request_id in feedback_tracking
    
    def set_conversation_id(self, conversation_id: str):
        """
        Set the current conversation ID.
        
        Args:
            conversation_id (str): Unique conversation identifier
        """
        session[self.CONVERSATION_ID_KEY] = conversation_id
    
    def get_conversation_id(self) -> Optional[str]:
        """
        Get the current conversation ID.
        
        Returns:
            Optional[str]: Current conversation ID
        """
        return session.get(self.CONVERSATION_ID_KEY)
    
    def update_user_preferences(self, preferences: Dict[str, Any]):
        """
        Update user preferences.
        
        Args:
            preferences (Dict[str, Any]): User preference updates
        """
        current_prefs = session.get(self.USER_PREFERENCES_KEY, {})
        current_prefs.update(preferences)
        session[self.USER_PREFERENCES_KEY] = current_prefs
    
    def get_user_preferences(self) -> Dict[str, Any]:
        """
        Get user preferences.
        
        Returns:
            Dict[str, Any]: Current user preferences
        """
        return session.get(self.USER_PREFERENCES_KEY, {})
    
    def set_chat_history_preference(self, use_chat_history: bool):
        """
        Set the chat history preference.
        
        Args:
            use_chat_history (bool): Whether to use chat history
        """
        preferences = session.get(self.USER_PREFERENCES_KEY, {})
        preferences['use_chat_history'] = use_chat_history
        session[self.USER_PREFERENCES_KEY] = preferences
        logger.info(f"[INSIGHTS_SESSION] Chat history preference set to: {use_chat_history}")
    
    def get_chat_history_preference(self) -> bool:
        """
        Get the chat history preference.
        
        Returns:
            bool: Whether to use chat history (default: False)
        """
        preferences = session.get(self.USER_PREFERENCES_KEY, {})
        return preferences.get('use_chat_history', False)
    
    def clear_conversation(self, preserve_domain: bool = True):
        """
        Clear conversation history and reset state.
        
        Args:
            preserve_domain (bool): Whether to preserve domain selection
        """
        session[self.CHAT_MESSAGES_KEY] = []
        session[self.ACTIVE_SUGGESTIONS_KEY] = []
        session[self.FEEDBACK_TRACKING_KEY] = {}
        session[self.CONVERSATION_ID_KEY] = None
        session[self.WELCOME_SHOWN_KEY] = False
        
        # Update conversation context
        context = session.get(self.CONVERSATION_CONTEXT_KEY, {})
        context['conversation_started_at'] = datetime.now().isoformat()
        context['last_reset_at'] = datetime.now().isoformat()
        session[self.CONVERSATION_CONTEXT_KEY] = context
        
        if not preserve_domain:
            session[self.SELECTED_DOMAIN_KEY] = 'policy'
            session[self.SELECTED_MODEL_KEY] = None
        
        logger.info("[INSIGHTS_SESSION] Conversation cleared")
    
    def mark_welcome_shown(self):
        """Mark that the welcome message has been shown."""
        session[self.WELCOME_SHOWN_KEY] = True
    
    def should_show_welcome(self) -> bool:
        """
        Check if welcome message should be shown.
        
        Returns:
            bool: True if welcome should be shown
        """
        return not session.get(self.WELCOME_SHOWN_KEY, False)
    
    def get_conversation_context(self) -> Dict[str, Any]:
        """
        Get conversation context information.
        
        Returns:
            Dict[str, Any]: Conversation context data
        """
        return session.get(self.CONVERSATION_CONTEXT_KEY, {})
    
    def _is_session_size_critical(self, messages: List[Dict[str, Any]]) -> bool:
        """
        Check if session size is approaching critical limits.
        
        Args:
            messages (List[Dict[str, Any]]): Messages to check
            
        Returns:
            bool: True if session size is critical
        """
        try:
            # Estimate total session size including all session data
            session_data = {
                'messages': messages,
                'preferences': session.get(self.USER_PREFERENCES_KEY, {}),
                'context': session.get(self.CONVERSATION_CONTEXT_KEY, {}),
                'domain': session.get(self.SELECTED_DOMAIN_KEY),
                'model': session.get(self.SELECTED_MODEL_KEY),
            }
            estimated_size = len(json.dumps(session_data, separators=(',', ':')).encode('utf-8'))
            
            # Use a stricter threshold (50%) to prevent cookie overflow
            threshold = self.max_cookie_size * 0.5
            
            if estimated_size > threshold:
                logger.warning(
                    f"[INSIGHTS_SESSION] Session size critical: {estimated_size} bytes "
                    f"(threshold: {threshold}, limit: {self.max_cookie_size})"
                )
                return True
            
            return False
            
        except Exception as e:
            logger.error(f"[INSIGHTS_SESSION] Error checking session size: {str(e)}")
            # Fallback to strict message count limit
            return len(messages) > 2
    
    def _clean_message_for_session(self, message: Dict[str, Any]) -> Dict[str, Any]:
        """
        Clean message content to reduce session storage size.
        
        Args:
            message (Dict[str, Any]): Original message
            
        Returns:
            Dict[str, Any]: Cleaned message with reduced size
        """
        # Create a copy to avoid modifying original
        cleaned_msg = message.copy()
        
        # Remove non-essential fields to save space
        cleaned_msg.pop('warnings', None)
        cleaned_msg.pop('request_id', None)
        cleaned_msg.pop('domain', None)  # Remove domain info to save space
        cleaned_msg.pop('semantic_view', None)  # Remove semantic_view to save space
        
        # Clean content if it's a list (typical for assistant messages)
        content = cleaned_msg.get('content', [])
        if isinstance(content, list):
            cleaned_content = []
            for item in content:
                if isinstance(item, dict):
                    if item.get('type') == 'text':
                        # Aggressively truncate long text content
                        text = item.get('text', '')
                        if len(text) > 500:  # Reduced from 1000 to 500
                            item = item.copy()
                            item['text'] = text[:500] + '...'
                    elif item.get('type') == 'sql':
                        # Keep SQL but remove explanation and limit statement size
                        statement = item.get('statement', '')
                        if len(statement) > 300:  # Limit SQL statement size
                            statement = statement[:300] + '...'
                        item = {'type': 'sql', 'statement': statement}
                    elif item.get('type') == 'suggestions':
                        # Keep up to 3 suggestions (configurable limit)
                        suggestions = item.get('suggestions', [])
                        if suggestions:
                            # Keep up to 3 suggestions and truncate individual text if needed
                            kept_suggestions = []
                            for suggestion in suggestions[:3]:  # Limit to first 3
                                if isinstance(suggestion, str):
                                    # Truncate individual suggestion if too long
                                    if len(suggestion) > 150:
                                        suggestion = suggestion[:150] + '...'
                                    kept_suggestions.append(suggestion)
                            item = {'type': 'suggestions', 'suggestions': kept_suggestions}
                        else:
                            continue  # Skip empty suggestions
                
                cleaned_content.append(item)
            
            cleaned_msg['content'] = cleaned_content
        elif isinstance(content, str):
            # For user messages, truncate if too long
            if len(content) > 200:
                cleaned_msg['content'] = content[:200] + '...'
        
        return cleaned_msg

    # ============================================================================
    # RESULT CACHING METHODS (Task 1.2)
    # ============================================================================
    
    def cache_query_result(self, cache_key: str, result_data: Dict[str, Any], 
                          query_sql: str, domain: str, semantic_view: str) -> None:
        """
        Cache a query result for faster retrieval.
        NOTE: Caching disabled in session to prevent cookie overflow.
        Results are cached in memory on the server side instead.
        
        Args:
            cache_key (str): Unique key for the cached result
            result_data (Dict[str, Any]): Result data to cache
            query_sql (str): SQL query that generated the result
            domain (str): Domain context
            semantic_view (str): Semantic view used
        """
        try:
            # Skip session-based caching to prevent cookie overflow
            # Results are cached server-side in the API layer instead
            logger.debug(f"[INSIGHTS_SESSION] Skipping session cache to prevent cookie overflow: {cache_key[:10]}...")
            
        except Exception as e:
            logger.error(f"[INSIGHTS_SESSION] Error in cache handling: {str(e)}")
    
    def get_cached_result(self, cache_key: str) -> Optional[Dict[str, Any]]:
        """
        Retrieve a cached query result.
        NOTE: Session-based caching disabled to prevent cookie overflow.
        
        Args:
            cache_key (str): Unique key for the cached result
            
        Returns:
            Optional[Dict[str, Any]]: None (caching disabled for session safety)
        """
        try:
            # Session-based caching disabled to prevent cookie overflow
            # Results should be cached server-side in the API layer instead
            logger.debug(f"[INSIGHTS_SESSION] Session cache disabled to prevent cookie overflow")
            return None
            
        except Exception as e:
            logger.error(f"[INSIGHTS_SESSION] Error in cache retrieval: {str(e)}")
            return None
    
    def _log_session_size_stats(self) -> None:
        """Log session size statistics for monitoring cookie usage."""
        try:
            # Get current session data size
            messages = session.get(self.CHAT_MESSAGES_KEY, [])
            preferences = session.get(self.USER_PREFERENCES_KEY, {})
            context = session.get(self.CONVERSATION_CONTEXT_KEY, {})
            
            # Calculate sizes
            messages_size = len(json.dumps(messages, separators=(',', ':')).encode('utf-8'))
            preferences_size = len(json.dumps(preferences, separators=(',', ':')).encode('utf-8'))
            context_size = len(json.dumps(context, separators=(',', ':')).encode('utf-8'))
            total_size = messages_size + preferences_size + context_size
            
            # Log if size is concerning (> 40% of limit)
            if total_size > (self.max_cookie_size * 0.4):
                logger.info(
                    f"[INSIGHTS_SESSION] Session size monitor - "
                    f"Total: {total_size}B, Messages: {messages_size}B, "
                    f"Prefs: {preferences_size}B, Context: {context_size}B, "
                    f"Limit: {self.max_cookie_size}B ({(total_size/self.max_cookie_size)*100:.1f}%)"
                )
                
        except Exception as e:
            logger.debug(f"[INSIGHTS_SESSION] Error in session size monitoring: {str(e)}")
            
        except Exception as e:
            logger.error(f"[INSIGHTS_SESSION] Error retrieving cached result: {str(e)}")
            return None
    
    def clear_result_cache(self) -> None:
        """Clear all cached results."""
        try:
            session[self.RESULT_CACHE_KEY] = {}
            logger.info("[INSIGHTS_SESSION] Cleared all cached results")
        except Exception as e:
            logger.error(f"[INSIGHTS_SESSION] Error clearing cache: {str(e)}")
    
    def get_cache_stats(self) -> Dict[str, Any]:
        """
        Get statistics about cached results.
        
        Returns:
            Dict[str, Any]: Cache statistics
        """
        try:
            cache = session.get(self.RESULT_CACHE_KEY, {})
            
            stats = {
                'total_cached': len(cache),
                'cache_keys': list(cache.keys()),
                'total_access_count': sum(entry.get('access_count', 0) for entry in cache.values()),
                'oldest_entry': None,
                'newest_entry': None
            }
            
            if cache:
                cached_times = [datetime.fromisoformat(entry['cached_at']) for entry in cache.values()]
                stats['oldest_entry'] = min(cached_times).isoformat()
                stats['newest_entry'] = max(cached_times).isoformat()
            
            return stats
            
        except Exception as e:
            logger.error(f"[INSIGHTS_SESSION] Error getting cache stats: {str(e)}")
            return {'error': str(e)}
    
    def generate_cache_key(self, query_sql: str, domain: str, semantic_view: str) -> str:
        """
        Generate a consistent cache key for a query.
        
        Args:
            query_sql (str): SQL query
            domain (str): Domain context
            semantic_view (str): Semantic view used
            
        Returns:
            str: Generated cache key
        """
        # Normalize the query (remove extra whitespace)
        normalized_sql = ' '.join(query_sql.split())
        content = f"{normalized_sql}|{domain}|{semantic_view}"
        return hashlib.md5(content.encode()).hexdigest()[:16]  # Short hash for session storage