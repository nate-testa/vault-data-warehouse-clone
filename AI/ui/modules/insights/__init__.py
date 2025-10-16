"""
Insights UI Module

This module provides the web interface for the Snowflake Cortex Analyst capabilities.
It enables users to ask natural language questions about semantic models and interact
with AI-generated insights through a conversational ChatGPT-style interface.

Features:
- ChatGPT/Gemini-style conversation interface
- Domain selection (Sales, Policy, Claims, Others)
- Real-time messaging with typing indicators
- SQL query execution with expandable results
- Multi-turn conversations with context preservation
- Quick feedback system (thumbs up/down)
- Session management with conversation persistence
- Responsive design optimized for chat

Components:
- routes.py: Flask blueprint with chat interface and AJAX endpoints
- services.py: API client for communicating with the Insights API module
- session_manager.py: Chat session and conversation state management
- templates/: Modern chat UI templates with domain selector
"""

__version__ = "1.0.0"
__author__ = "Snowflake AI Team"