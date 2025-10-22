"""
Insights AI Config Loader Module

Simple configuration loader for the Insights AI module.
"""

import json
import os
from pathlib import Path


def load_insights_config():
    """Load the Insights AI module configuration from config.json."""
    current_dir = Path(__file__).parent
    config_path = current_dir / "config.json"
    
    with open(config_path, 'r', encoding='utf-8') as f:
        return json.load(f)


def get_insights_config():
    """Get Insights AI configuration as a simple dictionary."""
    return load_insights_config()


def get_semantic_domains():
    """Get the semantic view domains configuration."""
    config = load_insights_config()
    return config.get("semantic_view_domains", {})


def get_semantic_view_domains():
    """
    Get the semantic view domains configuration.
    
    Returns:
        dict: Semantic view domains with backward compatibility
    """
    config = load_insights_config()
    domains = config.get("semantic_view_domains", {})
    
    # Provide backward compatibility by converting new format to old format when needed
    # This ensures existing code continues to work while new code can use enhanced metadata
    return domains


def get_snowflake_config():
    """Get the Snowflake connection configuration."""
    config = load_insights_config()
    return config.get("snowflake", {})


def get_api_config():
    """Get the API configuration settings."""
    config = load_insights_config()
    return config.get("api_config", {})


def get_domain_config():
    """Get the domain-specific configuration settings."""
    config = load_insights_config()
    return config.get("domain_config", {})


def get_domain_specific_config(domain):
    """
    Get configuration for a specific domain.
    
    Args:
        domain: Domain key
        
    Returns:
        dict: Domain-specific configuration or default settings
    """
    domain_configs = get_domain_config()
    return domain_configs.get(domain, {
        "default_model": None,
        "access_level": "public",
        "max_query_complexity": "medium", 
        "supported_operations": ["SELECT", "SHOW"],
        "enable_advanced_analytics": False
    })


def get_complete_snowflake_config():
    """
    Get complete Snowflake configuration combining module config with environment variables.
    
    This function merges the module-specific Snowflake settings (warehouse, database, schema, stage)
    with the connection settings from environment variables (account, user, password, role).
    
    Returns:
        dict: Complete Snowflake configuration ready for connections
    """
    import os
    from dotenv import load_dotenv
    
    load_dotenv()
    
    # Get module-specific config
    module_sf_config = get_snowflake_config()
    
    # Get connection config from environment variables  
    complete_config = {
        # Connection settings from environment
        "account": os.getenv('SF_ACCOUNT'),
        "user": os.getenv('SF_USER'), 
        "password": os.getenv('SF_PAT_TOKEN'),
        "role": os.getenv('SF_ROLE'),
        
        # Module-specific settings from config.json
        "warehouse": module_sf_config.get("warehouse"),
        "database": module_sf_config.get("database"),
        "schema": module_sf_config.get("schema"),
        "stage": module_sf_config.get("stage")
    }
    
    return complete_config


def get_semantic_view_metadata(domain, view_path):
    """
    Get metadata for a specific semantic view.
    
    Args:
        domain: The domain key (e.g., 'policy', 'claims', 'others')
        view_path: The full path of the semantic view
        
    Returns:
        dict: Metadata including display_name, description, is_default, or None if not found
    """
    config = load_insights_config()
    domains = config.get("semantic_view_domains", {})
    
    if domain not in domains:
        return None
    
    models = domains[domain].get("models", [])
    for model in models:
        if isinstance(model, dict) and model.get("path") == view_path:
            return {
                "display_name": model.get("display_name"),
                "description": model.get("description"),
                "is_default": model.get("is_default", False),
                "path": model.get("path")
            }
    
    return None


def get_domain_examples(domain):
    """
    Get examples and use cases for a specific domain.
    
    Args:
        domain: The domain key (e.g., 'policy', 'claims', 'others')
        
    Returns:
        dict: Domain examples including use_cases, example_questions, supported_analyses
    """
    config = load_insights_config()
    domain_examples = config.get("domain_examples", {})
    
    return domain_examples.get(domain, {
        "use_cases": [],
        "example_questions": [],
        "supported_analyses": []
    })


def get_all_semantic_views():
    """
    Get all semantic views across all domains for validation.
    
    Returns:
        list: List of all semantic view paths
    """
    config = load_insights_config()
    domains = config.get("semantic_view_domains", {})
    
    all_views = []
    for domain_key, domain_data in domains.items():
        models = domain_data.get("models", [])
        for model in models:
            if isinstance(model, dict):
                path = model.get("path")
                if path:
                    all_views.append(path)
            elif isinstance(model, str):
                # Backward compatibility with old string format
                all_views.append(model)
    
    return all_views


def get_default_model(domain):
    """
    Get the default model for a specific domain.
    
    Args:
        domain: The domain key (e.g., 'policy', 'claims', 'others')
        
    Returns:
        str: Path of the default model, or None if not found
    """
    config = load_insights_config()
    domains = config.get("semantic_view_domains", {})
    
    if domain not in domains:
        return None
    
    models = domains[domain].get("models", [])
    for model in models:
        if isinstance(model, dict) and model.get("is_default", False):
            return model.get("path")
    
    # Fallback to domain_config if no default found in models
    domain_config = get_domain_specific_config(domain)
    return domain_config.get("default_model")


def get_all_domains():
    """
    Get all configured domains.
    
    Returns:
        list: List of all domain keys
    """
    config = load_insights_config()
    domains = config.get("semantic_view_domains", {})
    return list(domains.keys())


def get_models_for_domain(domain):
    """
    Get models for a specific domain as a simple list for backward compatibility.
    
    Args:
        domain: The domain key (e.g., 'policy', 'claims', 'others')
        
    Returns:
        list: List of model paths (strings)
    """
    config = load_insights_config()
    domains = config.get("semantic_view_domains", {})
    
    if domain not in domains:
        return []
    
    models = domains[domain].get("models", [])
    model_paths = []
    
    for model in models:
        if isinstance(model, dict):
            path = model.get("path")
            if path:
                model_paths.append(path)
        elif isinstance(model, str):
            model_paths.append(model)
    
    return model_paths


def validate_config():
    """Validate that all required configuration keys are present."""
    try:
        config = load_insights_config()
        
        required_keys = ["module_info", "snowflake", "semantic_view_domains", "api_config"]
        for key in required_keys:
            if key not in config:
                raise ValueError(f"Missing required config key: {key}")
        
        # Validate snowflake config
        sf_config = config["snowflake"]
        sf_required = ["warehouse", "database", "schema", "stage"]
        for key in sf_required:
            if key not in sf_config:
                raise ValueError(f"Missing required Snowflake config key: {key}")
        
        # Validate semantic view domains
        domains = config["semantic_view_domains"]
        if not domains:
            raise ValueError("No semantic view domains configured")
        
        # Validate semantic view metadata
        for domain_key, domain_data in domains.items():
            if "models" not in domain_data:
                raise ValueError(f"Domain '{domain_key}' missing models array")
            
            models = domain_data["models"]
            if not models:
                raise ValueError(f"Domain '{domain_key}' has empty models array")
            
            # Check if we have at least one default model per domain
            has_default = False
            for model in models:
                if isinstance(model, dict):
                    # Validate required fields for new format
                    required_fields = ["path", "display_name", "description"]
                    for field in required_fields:
                        if field not in model:
                            raise ValueError(f"Model in domain '{domain_key}' missing required field: {field}")
                    
                    if model.get("is_default", False):
                        has_default = True
                elif isinstance(model, str):
                    # Old format - still supported for backward compatibility
                    pass
                else:
                    raise ValueError(f"Invalid model format in domain '{domain_key}': expected dict or string")
            
            # Note: We don't require a default model to be set via is_default
            # as it can also be configured in domain_config
        
        # Validate domain_examples if present
        if "domain_examples" in config:
            domain_examples = config["domain_examples"]
            for domain_key, examples in domain_examples.items():
                if domain_key not in domains:
                    raise ValueError(f"Domain examples exist for non-existent domain: {domain_key}")
                
                # Validate required example fields
                required_example_fields = ["use_cases", "example_questions", "supported_analyses"]
                for field in required_example_fields:
                    if field not in examples:
                        raise ValueError(f"Missing required domain examples field '{field}' for domain '{domain_key}'")
                    if not isinstance(examples[field], list):
                        raise ValueError(f"Domain examples field '{field}' must be a list for domain '{domain_key}'")
        
        # Validate domain_config if present
        if "domain_config" in config:
            domain_config = config["domain_config"]
            for domain_key, domain_settings in domain_config.items():
                if domain_key not in domains:
                    raise ValueError(f"Domain config exists for non-existent domain: {domain_key}")
                
                # Validate required domain config fields
                required_domain_fields = ["default_model", "access_level"]
                for field in required_domain_fields:
                    if field not in domain_settings:
                        raise ValueError(f"Missing required domain config field '{field}' for domain '{domain_key}'")
                
                # Validate that default_model exists in the domain's models
                default_model = domain_settings["default_model"]
                if default_model:
                    all_model_paths = []
                    for model in domains[domain_key]["models"]:
                        if isinstance(model, dict):
                            all_model_paths.append(model["path"])
                        elif isinstance(model, str):
                            all_model_paths.append(model)
                    
                    if default_model not in all_model_paths:
                        raise ValueError(f"Default model '{default_model}' not found in domain '{domain_key}' models")
        
        return True
        
    except Exception as e:
        print(f"Configuration validation error: {e}")
        return False