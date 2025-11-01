"""
DocuClaims Module Configuration
"""

# UI Configuration
ENABLE_MODEL_SELECTION = False  # Set to True to allow users to select the AI model
DEFAULT_MODEL = "claude-4-sonnet"  # Default model when selection is disabled

# Questions Configuration
ENABLE_SUGGESTION_QUESTIONS = False  # Enable/disable initial suggestion questions on welcome screen
ENABLE_FOLLOWUP_QUESTIONS = True  # Enable/disable follow-up question suggestions

# API Configuration
API_TIMEOUT = 300  # Timeout for API requests in seconds
