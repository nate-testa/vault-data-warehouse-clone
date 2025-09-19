"""
DocuClaims Config Loader Module

Simple configuration loader for the DocuClaims module.
"""

import json
import os
from pathlib import Path


def load_docuclaims_config():
    """Load the DocuClaims module configuration from config.json."""
    current_dir = Path(__file__).parent
    config_path = current_dir / "config.json"
    
    with open(config_path, 'r', encoding='utf-8') as f:
        return json.load(f)


def get_docuclaims_config():
    """Get DocuClaims configuration as a simple dictionary."""
    return load_docuclaims_config()