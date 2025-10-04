# Snowflake AI API Documentation

## Overview

The **Snowflake AI API** is a FastAPI-based backend service that provides Retrieval-Augmented Generation (RAG) capabilities using Snowflake's Cortex AI. This API enables document upload, processing, and intelligent question-answering based on uploaded documents.

## Table of Contents

- [Quick Start](#quick-start)
- [Architecture](#architecture)
- [API Endpoints](#api-endpoints)
- [Configuration](#configuration)
- [Services](#services)
- [File Structure](#file-structure)
- [Development](#development)
- [Deployment](#deployment)
- [Troubleshooting](#troubleshooting)

## Quick Start

### Prerequisites

- Python 3.8+
- Snowflake account with Cortex AI enabled
- Required environment variables (see [Configuration](#configuration))

### Installation

1. Install dependencies:
```bash
pip install -r requirements.txt
```

2. Set up environment variables in `.env` file (see [Configuration](#configuration))

3. Start the API server:
```bash
uvicorn app.api.main:app --host 0.0.0.0 --port 8000
```

The API will be available at `http://localhost:8000`

## Architecture

The API follows a modern modular architecture with clear separation of concerns and module-based organization:

```
app/
├── api/                    # Main FastAPI application
│   └── main.py            # Application initialization and router registration
├── modules/               # Feature modules (business domains)
│   └── docuclaims/        # DocuClaims RAG module
│       ├── router.py      # FastAPI routes and endpoints
│       ├── services.py    # Business logic and RAG operations
│       ├── schemas.py     # Pydantic models for request/response
│       ├── validators.py  # Input validation and file handling
│       ├── config_loader.py # Module-specific configuration
│       ├── config.json    # DocuClaims configuration
│       └── temp_uploads/  # Temporary file storage
├── shared/                # Shared components across modules
│   └── middleware.py      # CORS, timing, and other middleware
├── utils/                 # Shared utility functions
│   ├── database.py        # Snowflake connection management
│   └── logging.py         # Centralized logging configuration
└── logs/                  # Application logs with rotation
```

### Key Components

- **Modular Router Architecture**: Each business domain is a separate module with its own router, services, and configuration
- **FastAPI Application**: High-performance async web framework with lifespan management and automatic documentation
- **Snowflake Integration**: Direct connection to Snowflake using official connector and Cortex AI services
- **Advanced RAG Service**: Retrieval-Augmented Generation using Snowflake Cortex Search with vector similarity
- **File Processing Pipeline**: Secure document upload, validation, chunking, and embedding generation
- **Configuration Management**: Module-specific JSON configuration with environment variable overrides
- **Shared Middleware**: CORS, request timing, performance monitoring, and security middleware
- **Comprehensive Logging**: Structured logging with automatic rotation, performance metrics, and error tracking

### Current Module Portfolio

#### DocuClaims Module - *Fully Implemented*
- **Purpose**: AI-powered document analysis and insurance claims processing
- **Capabilities**:
  - Multi-format document upload and processing (PDF, DOC, images)
  - Advanced RAG with Snowflake Cortex Search
  - Chat history integration for conversational AI
  - Multiple LLM model support (Claude-4-Sonnet, GPT-5)
  - Real-time file processing status monitoring
- **Endpoints**: `/docuclaims/*`
- **Configuration**: Dedicated Snowflake warehouse, database, and Cortex Search service

## API Endpoints

All endpoints are organized by module with appropriate prefixes for clear API organization.

### DocuClaims Module (`/docuclaims`)

#### Model Options
**GET** `/docuclaims/model_options`
- Get available AI models for DocuClaims question answering
- **Response**: List of available Snowflake Cortex LLM models
- **Example**: `["claude-4-sonnet", "openai-gpt-5"]`

#### RAG Question Answering
**POST** `/docuclaims/rag_complete`
- Advanced RAG-based question answering with chat history support
- **Content-Type**: `application/json`
- **Request Body**:
```json
{
  "question": "What are the main claims in this document?",
  "llm_model": "claude-4-sonnet",
  "chat_history": [
    {"role": "user", "content": "Previous question"},
    {"role": "assistant", "content": "Previous response"}
  ]
}
```
- **Response**:
```json
{
  "answer": "Comprehensive answer based on document analysis",
  "model_used": "claude-4-sonnet",
  "sources": ["document1.pdf", "document2.txt"],
  "processing_time_ms": 2345
}
```

#### Document Upload
**POST** `/docuclaims/upload_file`
- Upload and process documents for RAG indexing
- **Content-Type**: `multipart/form-data`
- **Parameters**:
  - `file`: Document file (PDF, TXT, DOC, DOCX, images)
- **File Restrictions**:
  - Max size: 200MB
  - Supported formats: PDF, TXT, DOC, DOCX, PNG, JPG, JPEG
- **Response**: Upload status, processing information, and file metadata

#### File Processing Status
**GET** `/docuclaims/check_file_processed/{filename}`
- Check if an uploaded file has been processed and indexed
- **Parameters**:
  - `filename`: Name of the uploaded file
- **Response**: Processing status and availability for querying

## Configuration

### Environment Variables

Create a `.env` file in the `app/` directory with the following variables:

```bash
# API Configuration
API_BASE_URL=http://127.0.0.1:8080

# Snowflake Configuration (Required)
SF_ACCOUNT=your_snowflake_account_identifier
SF_USER=your_snowflake_service_user
SF_PAT_TOKEN=your_personal_access_token_or_password
SF_ROLE=your_snowflake_role

# CORS Configuration (Optional)
CORS_ORIGINS=http://localhost:5001,https://yourdomain.com

# Logging Configuration (Optional)
LOG_LEVEL=INFO
```

### Module Configuration

Each module has its own `config.json` file for module-specific settings:

#### DocuClaims Configuration (`modules/docuclaims/config.json`)

```json
{
  "module_info": {
    "name": "docuclaims",
    "version": "1.0.0",
    "description": "Document Claims RAG Module"
  },
  "snowflake": {
    "warehouse": "VAULT_AI_DOCUCLAIMS_WH",
    "database": "VAULT_AI_UAT", 
    "schema": "DOCUCLAIMS",
    "stage": "DOCS",
    "chunks_table": "DOC_CHUNKS_VECTORS"
  },
  "ai_models": {
    "embedding_model": "snowflake-arctic-embed-l-v2.0",
    "available_llm_models": ["claude-4-sonnet", "openai-gpt-5"],
    "cortex_search_service": "VAULT_AI_UAT.DOCUCLAIMS.DOC_CHUNK_VECTORS_SEARCH_SERVICE"
  },
  "search_config": {
    "num_chunks": 200,
    "use_cortex_search": true
  }
}
```

### Snowflake Requirements

1. **Cortex AI Access**: Your Snowflake account must have Cortex AI enabled
2. **Cortex Search Service**: Set up for enhanced vector search capabilities
3. **Tables Required**:
   - `DOC_CHUNKS_VECTORS`: For storing document chunks and vector embeddings
4. **Permissions**: Service user must have access to:
   - Read/write to specified database and schema
   - Execute Cortex AI functions (EMBED_TEXT_1024, AI_COMPLETE, SEARCH)
   - Access to specified warehouse and stage
   - Use Cortex Search services

## Services

### DocuClaims Services (`modules/docuclaims/services.py`)

Comprehensive RAG and document processing services:

- **`get_similar_chunks(question)`**: Advanced semantic search using Snowflake Cortex Search
- **`build_prompt(question, chat_history, llm_model)`**: Intelligent prompt construction with chat context
- **`summarize_chat_history(chat_history)`**: Chat history summarization for context management
- **Vector Similarity Search**: Uses Snowflake's VECTOR_COSINE_SIMILARITY and Cortex Search
- **Context Assembly**: Combines relevant chunks with source attribution and confidence scoring
- **File Processing**: Document chunking, embedding generation, and indexing

### Shared Database Service (`utils/database.py`)

Centralized Snowflake connection management:

- **`get_sf_conn()`**: Creates authenticated Snowflake connections using environment variables
- **Connection Management**: Automatic connection lifecycle management
- **Error Handling**: Robust connection error handling with detailed logging
- **Environment Integration**: Seamless integration with environment variable configuration

### Configuration Management (`modules/docuclaims/config_loader.py`)

Module-specific configuration handling:

- **`get_docuclaims_config()`**: Loads and validates DocuClaims module configuration
- **JSON-based Configuration**: Module settings stored in structured JSON files
- **Environment Override**: Support for environment variable overrides
- **Validation**: Configuration validation and default value handling

## File Structure

```
app/
├── __init__.py                     # Package initialization
├── .env                           # Environment variables configuration
├── api/                          # Main FastAPI application layer
│   ├── main.py                   # Application initialization, lifespan, and router registration
│   └── __pycache__/             # Python bytecode cache
├── modules/                      # Business domain modules
│   ├── __init__.py
│   ├── __pycache__/
│   └── docuclaims/              # DocuClaims RAG module
│       ├── __init__.py
│       ├── router.py            # FastAPI routes (/docuclaims endpoints)
│       ├── services.py          # RAG business logic and Snowflake operations
│       ├── schemas.py           # Pydantic models for requests/responses
│       ├── validators.py        # File upload validation and sanitization
│       ├── config_loader.py     # Module configuration management
│       ├── config.json          # DocuClaims-specific configuration
│       ├── temp_uploads/        # Temporary file storage for DocuClaims
│       └── __pycache__/         # Python bytecode cache
├── shared/                       # Shared components across modules
│   ├── __init__.py
│   ├── middleware.py            # CORS, timing, and security middleware
│   └── __pycache__/             # Python bytecode cache
├── utils/                        # Shared utility functions
│   ├── database.py              # Snowflake connection management
│   ├── logging.py               # Centralized logging configuration with rotation
│   └── __pycache__/             # Python bytecode cache
└── logs/                         # Application logs with automatic rotation
    ├── api.log                  # Current log file
    ├── api.log.2025-09-18      # Rotated log files
    └── api.log.2025-09-19      # Rotated log files
```

## Development

### Running in Development Mode

```bash
# Start with auto-reload
uvicorn app.api.main:app --reload --host 0.0.0.0 --port 8000

# View logs
tail -f app/logs/api.log
```

### Adding New Modules

To add a new business domain module (e.g., "docalegal"):

1. **Create Module Directory**: Create `modules/docalegal/`
2. **Implement Router**: Create `router.py` with FastAPI routes
3. **Add Business Logic**: Create `services.py` with domain-specific operations  
4. **Define Schemas**: Create `schemas.py` with Pydantic request/response models
5. **Add Validation**: Create `validators.py` for input validation
6. **Configure Module**: Create `config.json` with module-specific settings
7. **Add Configuration Loader**: Create `config_loader.py` for configuration management
8. **Register Router**: Add router registration in `app/api/main.py`
9. **Update Documentation**: Update API documentation and this README

### Adding Endpoints to Existing Modules

1. Add endpoint to module's `router.py`
2. Define request/response schemas in module's `schemas.py`
3. Implement business logic in module's `services.py`
4. Add validation logic in module's `validators.py`
5. Add comprehensive logging and error handling
6. Update module configuration if needed
7. Update API documentation

### Testing

```bash
# Test DocuClaims model options
curl http://localhost:8000/docuclaims/model_options

# Test DocuClaims file upload
curl -X POST -F "file=@test.pdf" http://localhost:8000/docuclaims/upload_file

# Test DocuClaims RAG completion
curl -X POST -H "Content-Type: application/json" \
  -d '{
    "question": "What are the main claims in this document?",
    "llm_model": "claude-4-sonnet",
    "chat_history": []
  }' \
  http://localhost:8000/docuclaims/rag_complete

# Test file processing status
curl http://localhost:8000/docuclaims/check_file_processed/test.pdf
```

## Deployment

### Production Considerations

1. **Environment Variables**: Secure management of sensitive credentials
2. **HTTPS**: Use reverse proxy (nginx) for SSL termination
3. **Process Management**: Use systemd, supervisor, or Docker
4. **Monitoring**: Implement health checks and log monitoring
5. **Scaling**: Consider multiple worker processes for high load

### Docker Deployment (Example)

```dockerfile
FROM python:3.9-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY app/ ./app/
EXPOSE 8000

CMD ["uvicorn", "app.api.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Systemd Service (Example)

```ini
[Unit]
Description=Snowflake AI API
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/path/to/snowflake_ai
ExecStart=/path/to/venv/bin/uvicorn app.api.main:app --host 0.0.0.0 --port 8000
Restart=always

[Install]
WantedBy=multi-user.target
```

## Troubleshooting

### Common Issues

1. **Snowflake Connection Errors**
   - Verify credentials in `.env` file
   - Check network connectivity to Snowflake
   - Ensure user has required permissions

2. **File Upload Failures**
   - Check file size (max 50MB)
   - Verify file format is supported
   - Ensure temp_uploads directory exists and is writable

3. **Empty Responses from RAG**
   - Verify documents are uploaded and processed via `/docuclaims/check_file_processed`
   - Check if `DOC_CHUNKS_VECTORS` table contains data in the configured database/schema
   - Verify Cortex Search service is properly configured and accessible
   - Review embedding model configuration in `modules/docuclaims/config.json`

### Logging

- **Current Logs**: `app/logs/api.log` (with automatic rotation)
- **Rotated Logs**: `app/logs/api.log.YYYY-MM-DD` format
- **Log Levels**: DEBUG, INFO, WARNING, ERROR, CRITICAL
- **Configuration**: Set log level via `LOG_LEVEL` environment variable
- **Structured Logging**: Includes module names, request timing, and performance metrics

**Log Analysis Commands**:
```bash
# View current logs in real-time
tail -f app/logs/api.log

# Search for specific modules
grep "\[RAG_" app/logs/api.log*

# Monitor performance metrics
grep "completed in" app/logs/api.log*

# Check error patterns
grep "ERROR\|CRITICAL" app/logs/api.log*
```

### Performance Optimization

1. **Database**: Optimize Snowflake warehouse size
2. **Caching**: Implement caching for frequent queries
3. **Connection Pooling**: Configure appropriate pool sizes
4. **File Processing**: Consider async file processing for large documents

## API Documentation

When the server is running, interactive API documentation is available at:
- **Swagger UI**: `http://localhost:8000/docs` - Interactive API testing interface
- **ReDoc**: `http://localhost:8000/redoc` - Clean API documentation

The documentation includes all module endpoints with:
- Request/response schemas
- Parameter descriptions  
- Example requests and responses
- Authentication requirements
- Error response formats

## Support

For issues or questions:
1. Check the logs in `app/logs/api.log`
2. Review this documentation
3. Verify Snowflake configuration and permissions
4. Test with simple requests before complex operations

---

**Note**: This API is designed to work with the Snowflake AI UI application. For complete functionality, ensure both the API and UI components are properly configured and running.
