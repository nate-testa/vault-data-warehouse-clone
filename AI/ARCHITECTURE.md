# Snowflake AI - Architecture Documentation

## Table of Contents
1. [Overview](#overview)
2. [Architecture Principles](#architecture-principles)
3. [System Architecture](#system-architecture)
4. [Technology Stack](#technology-stack)
5. [Folder Structure](#folder-structure)
6. [Module Architecture](#module-architecture)
7. [Development Guidelines](#development-guidelines)
8. [Creating New Modules](#creating-new-modules)
9. [Architecture Violations Found](#architecture-violations-found)
10. [Best Practices](#best-practices)

---

## Overview

The Snowflake AI application is built with a **strict separation of concerns** between the backend API and frontend UI. This architecture follows a **client-server model** where:

- **`app/`** folder: Contains the FastAPI backend (API server) with all business logic, database connections, and AI/ML operations
- **`ui/`** folder: Contains the Flask frontend that serves web pages and acts as a pure API consumer

This separation ensures:
- ✅ **Maintainability**: Clear boundaries between presentation and business logic
- ✅ **Scalability**: API and UI can scale independently
- ✅ **Reusability**: API endpoints can be consumed by multiple clients (web, mobile, CLI)
- ✅ **Testability**: Each layer can be tested independently

---

## Architecture Principles

### Core Principles

1. **API-First Design**
   - All business logic, database operations, and AI processing MUST reside in the `app/` folder
   - The `app/` folder exposes RESTful API endpoints that encapsulate all functionality
   - The API is the single source of truth for data and operations

2. **UI as Pure Consumer**
   - The `ui/` folder MUST ONLY consume API endpoints
   - UI should handle: rendering, user interactions, session management, authentication
   - UI should NEVER directly connect to databases or perform business logic

3. **Modular Architecture**
   - Each feature/functionality is organized as an independent module
   - Modules in `app/` and `ui/` mirror each other (e.g., `docuclaims`, `insights`)
   - Modules are self-contained with their own routes, services, schemas, and configurations

4. **Service Layer Pattern**
   - In `app/`: Services contain business logic and database operations
   - In `ui/`: Services act as API client wrappers (HTTP requests only)
   - No direct business logic or database access in route handlers

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         Browser/Client                        │
│                    (JavaScript Frontend)                      │
└────────────────────┬──────────────────────────────────────────┘
                     │ HTTP Requests
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                    UI Layer (Flask)                          │
│                    Port: 5000                                │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ Responsibilities:                                     │   │
│  │ • Render HTML templates (Jinja2)                     │   │
│  │ • Handle user sessions (authentication)              │   │
│  │ • Serve static assets (CSS, JS, images)             │   │
│  │ • Act as API proxy/consumer                          │   │
│  │ • NO business logic or database access               │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
│  Modules: docuclaims/, insights/                             │
│  Each module:                                                 │
│    • routes.py (Flask blueprints - renders UI)               │
│    • services.py (API client - HTTP requests only)           │
│    • templates/ (HTML with Jinja2)                           │
│    • static/ (CSS, JS)                                        │
│    • session_manager.py (UI session state)                   │
└────────────────────┬──────────────────────────────────────────┘
                     │ HTTP API Calls (requests library)
                     │ API_BASE_URL environment variable
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                   API Layer (FastAPI)                        │
│                   Port: 8080                                 │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ Responsibilities:                                     │   │
│  │ • All business logic                                  │   │
│  │ • Database connections (Snowflake)                    │   │
│  │ • AI/ML operations (Cortex, embeddings)              │   │
│  │ • Data validation and processing                      │   │
│  │ • File uploads and processing                         │   │
│  │ • RESTful API endpoints                               │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
│  Modules: docuclaims/, insights/                             │
│  Each module:                                                 │
│    • router.py (FastAPI router - API endpoints)              │
│    • services.py (Business logic + DB operations)            │
│    • schemas.py (Pydantic models for validation)             │
│    • validators.py (Input validation logic)                  │
│    • config.json (Module configuration)                      │
└────────────────────┬──────────────────────────────────────────┘
                     │ SQL Queries / AI API Calls
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                   External Services                          │
│  • Snowflake Database (Data Warehouse)                      │
│  • Snowflake Cortex (AI/ML Services)                        │
│  • Cortex Search (Vector Search)                            │
│  • Cortex Analyst (Semantic Layer)                          │
└─────────────────────────────────────────────────────────────┘
```

---

## Technology Stack

### API Backend (`app/`)
- **Framework**: FastAPI 0.115+
- **Server**: Uvicorn (ASGI server)
- **Database**: Snowflake (via `snowflake-connector-python`)
- **AI Services**: Snowflake Cortex (COMPLETE, SEARCH, ANALYST)
- **Validation**: Pydantic v2
- **Async**: Native async/await support

### UI Frontend (`ui/`)
- **Framework**: Flask 3.0+
- **Server**: Gunicorn (WSGI server)
- **Template Engine**: Jinja2
- **HTTP Client**: `requests` library
- **Authentication**: SAML SSO integration
- **Session Management**: Server-side sessions (Flask-Session)
- **Frontend**: jQuery, Bootstrap 5, Chart.js

### Shared
- **Language**: Python 3.10+
- **Environment**: `.venv` (virtual environment)
- **Configuration**: `.env` files + JSON config files
- **Logging**: Custom logger (`utils/logging.py`)

---

## Folder Structure

```
snowflake_ai/
│
├── app/                          # API Backend (FastAPI)
│   ├── .env                      # API environment variables
│   ├── api/
│   │   └── main.py              # FastAPI application entry point
│   ├── modules/                  # Feature modules
│   │   ├── docuclaims/          # Document Q&A module
│   │   │   ├── router.py        # ✅ API endpoints
│   │   │   ├── services.py      # ✅ Business logic + DB operations
│   │   │   ├── schemas.py       # ✅ Pydantic models
│   │   │   ├── validators.py    # ✅ Input validation
│   │   │   ├── config.json      # ✅ Module configuration
│   │   │   └── temp_uploads/    # ✅ Temporary file storage
│   │   └── insights/            # Data insights module
│   │       ├── router.py        # ✅ API endpoints
│   │       ├── services.py      # ✅ Business logic + DB operations
│   │       ├── schemas.py       # ✅ Pydantic models
│   │       ├── validators.py    # ✅ Input validation
│   │       └── config.json      # ✅ Module configuration
│   ├── shared/                   # Shared API components
│   │   └── middleware.py        # CORS, timing, etc.
│   └── utils/                    # API utilities
│       ├── database.py          # ✅ Snowflake connection
│       └── logging.py           # ✅ Logger configuration
│
├── ui/                           # UI Frontend (Flask)
│   ├── .env                      # UI environment variables
│   ├── app.py                    # Flask application entry point
│   ├── auth/                     # Authentication module
│   │   ├── sso_auth.py          # SSO integration
│   │   ├── session_manager.py   # Session management
│   │   ├── decorators.py        # Auth decorators
│   │   └── access_control.py    # Permission control
│   ├── modules/                  # Feature modules (mirror API)
│   │   ├── docuclaims/          # Document Q&A UI
│   │   │   ├── routes.py        # ✅ Flask blueprint (renders pages)
│   │   │   ├── services.py      # ✅ API client (HTTP only)
│   │   │   ├── session_manager.py # ✅ UI session state
│   │   │   ├── templates/       # ✅ HTML templates
│   │   │   │   └── docuclaims.html
│   │   │   └── static/          # ✅ CSS, JS assets
│   │   │       ├── css/
│   │   │       └── js/
│   │   └── insights/            # Data insights UI
│   │       ├── routes.py        # ✅ Flask blueprint
│   │       ├── services.py      # ✅ API client (HTTP only)
│   │       ├── session_manager.py # ✅ UI session state
│   │       ├── templates/
│   │       └── static/
│   ├── templates/                # Global templates
│   │   ├── base.html            # Base layout
│   │   ├── applications.html    # Home/dashboard
│   │   └── login.html           # Login page
│   ├── static/                   # Global static assets
│   │   ├── css/
│   │   ├── js/
│   │   └── img/
│   └── utils/                    # UI utilities
│       ├── logging.py           # ✅ Logger configuration
│       └── session_config.py    # ✅ Session configuration
│
├── .venv/                        # Python virtual environment
├── requirements.txt              # Python dependencies
├── README.md                     # Getting started guide
└── ARCHITECTURE.md               # This file
```

---

## Module Architecture

Each module follows a consistent structure across `app/` and `ui/`.

### API Module Structure (`app/modules/<module_name>/`)

```python
# router.py - API Endpoints
"""
Defines FastAPI routes for the module.
Each endpoint should be self-contained with inline exception handling.
"""
from fastapi import APIRouter, HTTPException
from .services import business_logic_function
from .schemas import RequestModel, ResponseModel

router = APIRouter()

@router.post("/endpoint", response_model=ResponseModel)
def endpoint_handler(request: RequestModel):
    """
    Endpoint documentation.
    """
    try:
        result = business_logic_function(request.data)
        return ResponseModel(data=result)
    except Exception as e:
        logger.error(f"Error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))
```

```python
# services.py - Business Logic
"""
Contains all business logic, database operations, and AI processing.
Pure Python functions that can be tested independently.
"""
from app.utils.database import get_sf_conn
from app.utils.logging import logger

def business_logic_function(input_data):
    """
    Perform business operation.
    
    This function:
    - Connects to Snowflake database
    - Executes queries
    - Processes AI operations
    - Returns processed results
    """
    conn, cur = get_sf_conn()
    
    try:
        # Database operations
        cur.execute("SELECT * FROM table WHERE id = %s", (input_data,))
        result = cur.fetchall()
        
        # Business logic processing
        processed = process_data(result)
        
        return processed
        
    finally:
        cur.close()
        conn.close()
```

```python
# schemas.py - Data Models
"""
Pydantic models for request/response validation.
"""
from pydantic import BaseModel, Field
from typing import Optional, List

class RequestModel(BaseModel):
    """Request schema with validation."""
    question: str = Field(..., min_length=1)
    model: Optional[str] = "default-model"

class ResponseModel(BaseModel):
    """Response schema."""
    answer: str
    sources: List[str]
```

```python
# validators.py - Input Validation
"""
Input validation and sanitization functions.
"""
def validate_input(text: str) -> bool:
    """Validate input meets requirements."""
    if not text or len(text) < 1:
        return False
    return True

def sanitize_filename(filename: str) -> str:
    """Remove dangerous characters from filename."""
    return "".join(c for c in filename if c.isalnum() or c in "._-")
```

```json
// config.json - Module Configuration
{
  "module_name": "DocuClaims",
  "version": "1.0.0",
  "snowflake": {
    "warehouse": "COMPUTE_WH",
    "database": "AI_DB",
    "schema": "PUBLIC"
  },
  "ai_models": {
    "default_llm": "claude-3-sonnet",
    "embedding_model": "e5-base-v2"
  }
}
```

### UI Module Structure (`ui/modules/<module_name>/`)

```python
# routes.py - Flask Blueprint
"""
Flask routes that render templates and handle UI interactions.
MUST NOT contain business logic or database access.
"""
from flask import Blueprint, render_template, request, jsonify
from .services import fetch_data_from_api
from auth.decorators import login_required, require_app_access

module_bp = Blueprint(
    'module_name',
    __name__,
    template_folder='templates',
    static_folder='static',
    static_url_path='/module/static'
)

@module_bp.route('/module')
@login_required
@require_app_access('Module Name')
def module_page():
    """Render the main module page."""
    # Get data from API via service layer
    data = fetch_data_from_api()
    
    # Render template
    return render_template('module.html', data=data)

@module_bp.route('/endpoint', methods=['POST'])
@login_required
def handle_action():
    """Handle user action by calling API."""
    user_input = request.form.get('input')
    
    # Call API via service layer
    result = send_to_api(user_input)
    
    return jsonify(result)
```

```python
# services.py - API Client
"""
Service layer that makes HTTP requests to API backend.
Acts as a client wrapper - NO business logic here.
"""
import requests
import os
from utils.logging import logger

API_BASE = os.environ.get("API_BASE_URL")

def fetch_data_from_api():
    """Fetch data from API backend."""
    try:
        response = requests.get(
            f"{API_BASE}/module/endpoint",
            timeout=5
        )
        response.raise_for_status()
        
        data = response.json()
        logger.info(f"Fetched data from API: {len(data)} items")
        
        return data
        
    except requests.Timeout:
        logger.error("API request timeout")
        return []
    except Exception as e:
        logger.error(f"API request failed: {str(e)}")
        return []

def send_to_api(input_data):
    """Send data to API backend."""
    try:
        response = requests.post(
            f"{API_BASE}/module/process",
            json={"data": input_data},
            timeout=30
        )
        response.raise_for_status()
        
        return response.json()
        
    except Exception as e:
        logger.error(f"API request failed: {str(e)}")
        return {"error": str(e)}
```

```python
# session_manager.py - UI Session State
"""
Manages UI-specific session state (not business data).
"""
from flask import session

class ModuleSessionManager:
    """Manage module-specific session data."""
    
    def get_preference(self, key, default=None):
        """Get user preference from session."""
        return session.get(f'module_{key}', default)
    
    def set_preference(self, key, value):
        """Save user preference to session."""
        session[f'module_{key}'] = value
    
    def clear_session(self):
        """Clear all module session data."""
        keys_to_remove = [k for k in session.keys() if k.startswith('module_')]
        for key in keys_to_remove:
            session.pop(key, None)
```

```html
<!-- templates/module.html - Template -->
{% extends "base.html" %}

{% block title %}Module Name{% endblock %}

{% block content %}
<div class="container">
    <h1>{{ module_data.title }}</h1>
    
    <!-- UI content that interacts with JavaScript -->
    <div id="module-container">
        <!-- Dynamic content loaded via AJAX -->
    </div>
</div>
{% endblock %}

{% block extra_js %}
<script src="{{ url_for('module.static', filename='js/module.js') }}"></script>
{% endblock %}
```

```javascript
// static/js/module.js - Frontend JavaScript
// Makes AJAX calls to UI Flask endpoints (which then call API)

$(document).ready(function() {
    // Load data by calling UI endpoint (not API directly)
    $.ajax({
        url: '/module/data',  // UI Flask endpoint
        type: 'GET',
        success: function(data) {
            renderData(data);
        },
        error: function(xhr, status, error) {
            console.error('Error loading data:', error);
        }
    });
    
    // Handle user action
    $('#submit-btn').on('click', function() {
        const input = $('#input').val();
        
        // Call UI endpoint (not API directly)
        $.ajax({
            url: '/module/process',  // UI Flask endpoint
            type: 'POST',
            data: { input: input },
            success: function(result) {
                displayResult(result);
            }
        });
    });
});
```

---

## Development Guidelines

### ✅ DO's

#### In API (`app/`)
- ✅ Implement all business logic in `services.py`
- ✅ Connect to Snowflake database for data operations
- ✅ Use Pydantic models for request/response validation
- ✅ Handle all AI/ML operations (Cortex, embeddings, etc.)
- ✅ Implement comprehensive error handling
- ✅ Log all operations with detailed context
- ✅ Write self-contained endpoints with inline exception handling
- ✅ Use configuration files (`config.json`) for module settings
- ✅ Validate and sanitize all inputs
- ✅ Return structured JSON responses

#### In UI (`ui/`)
- ✅ Render HTML templates with Jinja2
- ✅ Handle user authentication and sessions
- ✅ Call API endpoints via `services.py` (HTTP requests)
- ✅ Manage UI state with session managers
- ✅ Serve static assets (CSS, JS, images)
- ✅ Use Flask blueprints for modular routing
- ✅ Implement proper error handling for API calls
- ✅ Use decorators for authentication (`@login_required`)

### ❌ DON'Ts

#### In API (`app/`)
- ❌ NEVER render HTML templates
- ❌ NEVER handle user sessions (authentication)
- ❌ NEVER serve static files directly
- ❌ NEVER implement UI-specific logic
- ❌ NEVER use Flask blueprints (use FastAPI routers)

#### In UI (`ui/`)
- ❌ NEVER connect directly to databases
- ❌ NEVER implement business logic
- ❌ NEVER perform AI/ML operations
- ❌ NEVER process data beyond formatting for display
- ❌ NEVER duplicate API functionality
- ❌ NEVER make direct database queries
- ❌ NEVER use `get_sf_conn()` or similar database utilities

---

## Creating New Modules

Follow this step-by-step guide to create a new module that follows the architecture correctly.

### Step 1: API Module Setup (`app/modules/<new_module>/`)

1. **Create the module directory structure:**
```bash
mkdir -p app/modules/new_module
touch app/modules/new_module/__init__.py
touch app/modules/new_module/router.py
touch app/modules/new_module/services.py
touch app/modules/new_module/schemas.py
touch app/modules/new_module/validators.py
touch app/modules/new_module/config.json
```

2. **Define Pydantic schemas (`schemas.py`):**
```python
from pydantic import BaseModel, Field
from typing import Optional, List

class ModuleRequest(BaseModel):
    """Request model for the module."""
    query: str = Field(..., min_length=1, description="User query")
    options: Optional[dict] = Field(default_factory=dict)

class ModuleResponse(BaseModel):
    """Response model for the module."""
    result: str
    metadata: dict
```

3. **Implement business logic (`services.py`):**
```python
from app.utils.database import get_sf_conn
from app.utils.logging import logger
from .config_loader import get_module_config

def process_query(query: str, options: dict) -> dict:
    """
    Process user query with business logic.
    
    Args:
        query: User input query
        options: Additional processing options
        
    Returns:
        dict: Processed results
    """
    conn, cur = get_sf_conn()
    config = get_module_config()
    
    try:
        # Implement your business logic here
        # - Database queries
        # - AI operations
        # - Data processing
        
        result = perform_processing(query, options)
        
        logger.info(f"Query processed successfully: {query[:50]}...")
        return result
        
    except Exception as e:
        logger.error(f"Error processing query: {str(e)}", exc_info=True)
        raise
        
    finally:
        cur.close()
        conn.close()
```

4. **Create API endpoints (`router.py`):**
```python
from fastapi import APIRouter, HTTPException
from app.utils.logging import logger
from .schemas import ModuleRequest, ModuleResponse
from .services import process_query

router = APIRouter()

@router.post("/process", response_model=ModuleResponse)
def process_endpoint(request: ModuleRequest):
    """
    Process user request and return results.
    """
    try:
        result = process_query(request.query, request.options)
        
        return ModuleResponse(
            result=result["output"],
            metadata=result["metadata"]
        )
        
    except Exception as e:
        logger.error(f"Endpoint error: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Processing failed: {str(e)}"
        )
```

5. **Register router in main application (`app/api/main.py`):**
```python
from app.modules.new_module.router import router as new_module_router

# Register router
app.include_router(
    new_module_router,
    prefix="/new_module",
    tags=["New Module"]
)
```

### Step 2: UI Module Setup (`ui/modules/<new_module>/`)

1. **Create the UI module directory structure:**
```bash
mkdir -p ui/modules/new_module/{templates,static/css,static/js}
touch ui/modules/new_module/__init__.py
touch ui/modules/new_module/routes.py
touch ui/modules/new_module/services.py
touch ui/modules/new_module/session_manager.py
touch ui/modules/new_module/templates/new_module.html
touch ui/modules/new_module/static/css/new_module.css
touch ui/modules/new_module/static/js/new_module.js
```

2. **Create API client service (`services.py`):**
```python
import os
import requests
from utils.logging import logger

API_BASE = os.environ.get("API_BASE_URL")

def fetch_data_from_api(query: str, options: dict = None):
    """
    Fetch processed data from API backend.
    
    This is a pure API client - NO business logic here.
    """
    try:
        response = requests.post(
            f"{API_BASE}/new_module/process",
            json={
                "query": query,
                "options": options or {}
            },
            timeout=30
        )
        response.raise_for_status()
        
        data = response.json()
        logger.info(f"API call successful: {query[:50]}...")
        
        return data
        
    except requests.Timeout:
        logger.error("API timeout")
        return {"error": "Request timeout"}
        
    except Exception as e:
        logger.error(f"API call failed: {str(e)}")
        return {"error": str(e)}
```

3. **Create Flask blueprint (`routes.py`):**
```python
from flask import Blueprint, render_template, request, jsonify
from auth.decorators import login_required, require_app_access
from .services import fetch_data_from_api

new_module_bp = Blueprint(
    'new_module',
    __name__,
    template_folder='templates',
    static_folder='static',
    static_url_path='/new_module/static'
)

@new_module_bp.route('/new_module')
@login_required
@require_app_access('New Module')
def module_page():
    """Render the main module page."""
    return render_template('new_module.html')

@new_module_bp.route('/new_module/process', methods=['POST'])
@login_required
def process_request():
    """Handle user request by calling API."""
    query = request.form.get('query')
    
    # Call API via service layer
    result = fetch_data_from_api(query)
    
    return jsonify(result)
```

4. **Register blueprint in main app (`ui/app.py`):**
```python
from modules.new_module.routes import new_module_bp

# Register blueprint
app.register_blueprint(new_module_bp)
logger.info("[APP_INIT] New Module blueprint registered")
```

5. **Create template (`templates/new_module.html`):**
```html
{% extends "base.html" %}

{% block title %}New Module{% endblock %}

{% block extra_css %}
<link rel="stylesheet" href="{{ url_for('new_module.static', filename='css/new_module.css') }}">
{% endblock %}

{% block content %}
<div class="container">
    <h1>New Module</h1>
    
    <div id="module-content">
        <!-- Your UI content here -->
    </div>
</div>
{% endblock %}

{% block extra_js %}
<script src="{{ url_for('new_module.static', filename='js/new_module.js') }}"></script>
{% endblock %}
```

6. **Create JavaScript (`static/js/new_module.js`):**
```javascript
$(document).ready(function() {
    // Call UI endpoint (which calls API)
    $('#submit-btn').on('click', function() {
        const query = $('#query-input').val();
        
        $.ajax({
            url: '/new_module/process',  // UI Flask endpoint
            type: 'POST',
            data: { query: query },
            success: function(result) {
                displayResult(result);
            },
            error: function(xhr, status, error) {
                console.error('Error:', error);
            }
        });
    });
});
```

### Step 3: Configuration

1. **API environment variables (`.env`):**
```properties
# Snowflake connection
SNOWFLAKE_ACCOUNT=your_account
SNOWFLAKE_USER=your_user
SNOWFLAKE_PASSWORD=your_password
SNOWFLAKE_WAREHOUSE=COMPUTE_WH
SNOWFLAKE_DATABASE=AI_DB
SNOWFLAKE_SCHEMA=PUBLIC
```

2. **UI environment variables (`.env`):**
```properties
# API connection
API_BASE_URL=http://127.0.0.1:8080

# Session configuration
FLASK_SECRET_KEY=your-secret-key-here
```

3. **Module configuration (`app/modules/new_module/config.json`):**
```json
{
  "module_name": "New Module",
  "version": "1.0.0",
  "enabled": true,
  "snowflake": {
    "warehouse": "COMPUTE_WH",
    "database": "AI_DB",
    "schema": "PUBLIC"
  },
  "settings": {
    "max_results": 100,
    "timeout": 30
  }
}
```

### Step 4: Testing

1. **Test API endpoint:**
```bash
curl -X POST http://localhost:8080/new_module/process \
  -H "Content-Type: application/json" \
  -d '{"query": "test query", "options": {}}'
```

2. **Test UI endpoint:**
```bash
# Access in browser
http://localhost:5000/new_module
```

---

## Best Practices

### API Development (`app/`)

1. **Always use Pydantic models for validation**
```python
# GOOD
class Request(BaseModel):
    query: str = Field(..., min_length=1)

@router.post("/endpoint")
def handler(request: Request):
    # Automatically validated
    pass
```

2. **Implement comprehensive error handling**
```python
try:
    result = process_data(input)
    return {"result": result}
except DatabaseError as e:
    logger.error(f"Database error: {str(e)}", exc_info=True)
    raise HTTPException(status_code=500, detail="Database error")
except ValidationError as e:
    logger.error(f"Validation error: {str(e)}")
    raise HTTPException(status_code=400, detail=str(e))
except Exception as e:
    logger.error(f"Unexpected error: {str(e)}", exc_info=True)
    raise HTTPException(status_code=500, detail="Internal error")
```

3. **Always close database connections**
```python
conn, cur = get_sf_conn()
try:
    cur.execute("SELECT * FROM table")
    result = cur.fetchall()
finally:
    cur.close()
    conn.close()
```

4. **Use detailed logging**
```python
logger.info(f"[REQUEST_ID] Processing query: {query[:100]}...")
logger.info(f"[REQUEST_ID] Query executed in {execution_time:.2f}s")
logger.error(f"[REQUEST_ID] Error: {str(e)}", exc_info=True)
```

### UI Development (`ui/`)

1. **Never bypass the service layer**
```python
# BAD - Direct API call in routes
@bp.route('/data')
def get_data():
    response = requests.get(f"{API_BASE}/data")  # ❌ NO!
    return response.json()

# GOOD - Use service layer
@bp.route('/data')
def get_data():
    data = fetch_data_from_api()  # ✅ YES!
    return jsonify(data)
```

2. **Handle API errors gracefully**
```python
def fetch_data_from_api():
    try:
        response = requests.get(f"{API_BASE}/data", timeout=5)
        response.raise_for_status()
        return response.json()
    except requests.Timeout:
        logger.error("API timeout")
        return {"error": "timeout"}
    except requests.HTTPError as e:
        logger.error(f"API error: {e.response.status_code}")
        return {"error": "api_error"}
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        return {"error": "unknown"}
```

3. **Use Flask blueprints correctly**
```python
# Blueprint registration
my_module_bp = Blueprint(
    'my_module',                    # Blueprint name
    __name__,                       # Module name
    template_folder='templates',    # Templates location
    static_folder='static',         # Static files location
    static_url_path='/my_module/static'  # URL path for static files
)

# In app.py
app.register_blueprint(my_module_bp)
```

4. **JavaScript best practices**
```javascript
// GOOD - Call UI endpoint
$.ajax({
    url: '/module/endpoint',  // UI Flask route
    type: 'POST',
    data: { input: value },
    success: function(result) {
        // Handle success
    },
    error: function(xhr, status, error) {
        console.error('Error:', error);
        // Show user-friendly error message
    }
});

// BAD - Don't call API directly from JavaScript
// (unless absolutely necessary and documented)
$.ajax({
    url: 'http://localhost:8080/api/endpoint',  // ❌ NO!
    // ...
});
```

### Testing

1. **Test API endpoints independently**
```bash
# Test API
curl -X POST http://localhost:8080/docuclaims/rag_complete \
  -H "Content-Type: application/json" \
  -d '{"question": "test", "llm_model": "claude-3-sonnet"}'
```

2. **Test UI with API mocked (if needed)**
```python
# In tests, mock the API service
@patch('modules.docuclaims.services.fetch_data_from_api')
def test_route(mock_fetch):
    mock_fetch.return_value = {"result": "test"}
    # Test route logic
```

### Deployment

1. **Run API and UI separately**
```bash
# Terminal 1 - API
cd /path/to/snowflake_ai
source .venv/bin/activate
uvicorn app.api.main:app --host 0.0.0.0 --port 8080

# Terminal 2 - UI
cd /path/to/snowflake_ai/ui
source ../.venv/bin/activate
gunicorn -w 4 -b 127.0.0.1:5000 app:app
```

2. **Environment variables**
```bash
# API (.env)
SNOWFLAKE_ACCOUNT=...
SNOWFLAKE_USER=...
# ... other Snowflake configs

# UI (.env)
API_BASE_URL=http://127.0.0.1:8080
FLASK_SECRET_KEY=...
# ... other UI configs
```

---

## Quick Reference

### Common Patterns

#### API Endpoint Pattern
```python
@router.post("/endpoint", response_model=ResponseModel)
def endpoint_handler(request: RequestModel):
    try:
        result = service_function(request.data)
        return ResponseModel(**result)
    except Exception as e:
        logger.error(f"Error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))
```

#### UI Service Pattern
```python
def api_service_call(data):
    try:
        response = requests.post(
            f"{API_BASE}/endpoint",
            json=data,
            timeout=30
        )
        response.raise_for_status()
        return response.json()
    except Exception as e:
        logger.error(f"API call failed: {str(e)}")
        return {"error": str(e)}
```

#### UI Route Pattern
```python
@blueprint.route('/route', methods=['POST'])
@login_required
def route_handler():
    user_input = request.form.get('input')
    result = api_service_call(user_input)
    return jsonify(result)
```

---

## Conclusion

This architecture ensures:
- ✅ **Clear Separation**: API handles logic, UI handles presentation
- ✅ **Maintainability**: Each layer can be developed and tested independently
- ✅ **Scalability**: API and UI can scale independently
- ✅ **Reusability**: API can serve multiple clients
- ✅ **Security**: Business logic is protected in API layer
- ✅ **Testability**: Layers can be tested in isolation

**Remember**: When in doubt, ask yourself:
- *"Does this involve business logic or database access?"* → **API (`app/`)**
- *"Does this involve rendering UI or user sessions?"* → **UI (`ui/`)**

---

**Last Updated**: 2025-01-15  
**Version**: 1.0.0  
**Authors**: Architecture Team
