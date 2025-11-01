"""
DocuClaims Config Loader Module

Simple configuration loader for the DocuClaims module.
"""

import json
import re
from pathlib import Path
from app.config import get_config


def load_docuclaims_config():
    """Load the DocuClaims module configuration from config.json."""
    current_dir = Path(__file__).parent
    config_path = current_dir / "config.json"
    
    with open(config_path, 'r', encoding='utf-8') as f:
        config_text = f.read()
    
    # Replace ${SNOWFLAKE_DATABASE} with actual value from config.py
    snowflake_db = get_config('SNOWFLAKE_DATABASE')
    config_text = config_text.replace('${SNOWFLAKE_DATABASE}', str(snowflake_db))
    
    return json.loads(config_text)


def get_docuclaims_config():
    """Get DocuClaims configuration as a simple dictionary."""
    return load_docuclaims_config()