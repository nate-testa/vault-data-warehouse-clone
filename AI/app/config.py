import os
from dotenv import load_dotenv

load_dotenv()


def get_config():
    """Return config as a dict for dependency injection."""
    required_env_vars = [
        "SF_ACCOUNT", "SF_USER", "SF_PAT_TOKEN", "SF_ROLE", "SF_WAREHOUSE",
        "SF_DATABASE", "SF_SCHEMA", "SF_STAGE"
    ]
    missing_vars = [var for var in required_env_vars if not os.getenv(var)]
    if missing_vars:
        raise RuntimeError(f"Missing required environment variables: {', '.join(missing_vars)}")

    config = {
        "SF_ACCOUNT": os.getenv('SF_ACCOUNT'),
        "SF_USER": os.getenv('SF_USER'),
        "SF_PAT_TOKEN": os.getenv('SF_PAT_TOKEN'),
        "SF_ROLE": os.getenv('SF_ROLE'),
        "SF_WAREHOUSE": os.getenv('SF_WAREHOUSE'),
        "SF_DATABASE": os.getenv('SF_DATABASE'),
        "SF_SCHEMA": os.getenv('SF_SCHEMA'),
        "SF_STAGE": os.getenv('SF_STAGE'),
        "USE_SSO": os.getenv('USE_SSO', 'False') == 'True',
        "SF_CHUNKS_TABLE": "DOCS_CHUNKS_TABLE",
        "EMBEDDING_MODEL": "snowflake-arctic-embed-l-v2.0",
        "NUM_CHUNKS": 100,
        "USE_CHAT_HISTORY": True,
        "UPLOAD_FOLDER": "app/temp_uploads"
    }
    os.makedirs(config["UPLOAD_FOLDER"], exist_ok=True)
    return config
