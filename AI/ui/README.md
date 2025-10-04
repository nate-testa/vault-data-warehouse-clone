# Snowflake AI Web Application Documentation

## Overview

The **Snowflake AI Web Application** is a Flask-based web interface that provides a user-friendly frontend for the Snowflake AI API. It features SSO authentication with Azure AD, role-based access control, and an intuitive interface for document-based question answering using AI.

## Table of Contents

- [Quick Start](#quick-start)
- [Architecture](#architecture)
- [Authentication & Security](#authentication--security)
- [User Interface](#user-interface)
- [Configuration](#configuration)
- [File Structure](#file-structure)
- [Development](#development)
- [Deployment](#deployment)
- [Troubleshooting](#troubleshooting)

## Quick Start

### Prerequisites

- Python 3.8+
- Snowflake AI API running (see `/app` documentation)
- Azure AD application configured for SAML SSO (if using SSO)
- Required environment variables (see [Configuration](#configuration))

### Installation

1. Install dependencies:
```bash
pip install -r requirements.txt
```

2. Set up environment variables in `.env` file (see [Configuration](#configuration))

3. Start the web application:
```bash
python app.py
```

The web application will be available at `http://localhost:5001`

## Architecture

The web application follows a modular Flask architecture with comprehensive authentication, authorization, and application blueprints:

```
ui/
├── app.py              # Main Flask application with routing
├── .env                # Environment configuration
├── app_roles.json      # Application access control configuration
├── auth/               # Authentication and authorization modules
│   ├── access_control.py    # Role-based access control service
│   ├── decorators.py        # Route protection decorators
│   ├── middleware.py        # Authentication middleware
│   ├── models.py            # User and session data models
│   ├── session_manager.py   # Session management
│   ├── sso_auth.py         # SAML SSO authentication
│   └── user_service.py     # User profile and group management
├── modules/            # Application modules (blueprints)
│   └── docuclaims/     # DocuClaims AI module
│       ├── routes.py        # DocuClaims routes and endpoints
│       ├── services.py      # DocuClaims business logic
│       ├── session_manager.py # DocuClaims-specific session handling
│       └── templates/       # DocuClaims-specific templates
├── templates/          # Main Jinja2 HTML templates
├── static/             # CSS, JavaScript, and images
├── utils/              # Utility functions and helpers
│   ├── logging.py          # Centralized logging configuration
│   ├── secret_key_generator.py # Security utilities
│   └── ui_session_manager.py   # UI session management
└── logs/               # Application logs with rotation
```

### Key Features

- **Modular Blueprint Architecture**: Each application (DocuClaims, etc.) is a separate Flask blueprint
- **SSO Authentication**: Azure AD SAML integration with fallback mode
- **Role-Based Access Control**: Dynamic application filtering based on Azure AD groups
- **Session Management**: Multi-level session handling (app-wide and module-specific)
- **Responsive UI**: Modern, clean interface with Snowflake-inspired design
- **Security**: CSRF protection, secure headers, input validation, and audit logging
- **Scalable Structure**: Easy to add new AI applications as blueprints
- **Logging**: Comprehensive audit trail with automatic rotation and debugging logs

## Authentication & Security

### SSO (Single Sign-On) with Azure AD

The application supports SAML-based SSO authentication with Azure AD:

- **Protocol**: SAML 2.0
- **Identity Provider**: Azure AD
- **User Attributes**: Username, display name, email, groups
- **Session Management**: Secure Flask sessions with persistence

### Role-Based Access Control (RBAC)

Access to applications is controlled by Azure AD group memberships:

- **Configuration**: `app_roles.json` defines group-to-application mappings
- **Dynamic Access**: Users only see applications they have access to
- **Route Protection**: Direct URL access is protected by decorators
- **Fallback Mode**: Graceful operation when SSO is disabled

### Security Features

- **CSRF Protection**: Cross-site request forgery prevention
- **Secure Sessions**: Encrypted session cookies
- **Input Validation**: File upload and form input sanitization
- **Security Headers**: XSS protection and content security policies
- **Audit Logging**: Authentication events and user actions

## User Interface

### Application Flow

1. **Landing Page** (`/`): Clean, professional landing page with login option
2. **Authentication**: Azure AD SSO login (if enabled)
3. **Applications Dashboard** (`/applications`): Grid of available applications
4. **DocuClaims Application** (`/docuclaims`): AI-powered document analysis

### Application Portfolio

The platform currently supports multiple AI-powered applications with role-based access:

#### Active Applications

**DocuClaims AI** - *Fully Implemented*
- AI-powered insurance document analysis and claims processing
- Support for multiple file formats (PDF, DOC, images)
- Real-time question answering with source attribution
- Advanced conversation history and session management

#### Planned Applications

**Vault Analyst** - *Coming Soon*
- Advanced data analysis and business intelligence platform
- Interactive dashboards and reporting capabilities

**DocuLegal AI** - *Coming Soon*
- Legal document analysis and compliance checking
- Contract review and risk assessment tools

**DocuFinance AI** - *Coming Soon*  
- Financial document processing and analysis
- Automated financial report generation and insights

### Pages and Features

#### Landing Page (`templates/home.html`)
- Clean, centered design inspired by Snowflake's interface
- Conditional SSO login integration
- Responsive layout optimized for all device sizes
- Professional branding and navigation

#### Applications Dashboard (`templates/applications.html`)
- Dynamic grid layout showing available applications
- Real-time filtering based on user Azure AD group permissions
- Application status indicators (Active, Coming Soon)
- Professional tile-based design with Font Awesome icons
- Personalized user greeting with first name extraction

#### DocuClaims Application (`modules/docuclaims/templates/docuclaims.html`)
- Modern document upload interface with drag & drop support
- Real-time AI-powered question answering across multiple models
- Chat-like conversation interface with persistent message history
- Advanced file management with validation and progress tracking
- Source attribution and confidence scoring for AI responses
- Support for multiple AI models (GPT-4, Claude, Gemini, etc.)
- Cross-session conversation continuity and file persistence

#### Navigation (`templates/base.html`)
- Consistent navigation header across all application pages
- User authentication status and profile information display
- Secure logout functionality
- Fixed navbar design optimized for minimal screen space usage

## Configuration

### Environment Variables

Create a `.env` file in the `ui/` directory:

```bash
# Flask Configuration
FLASK_SECRET_KEY=your_flask_secret_key_64_chars_minimum
FLASK_ENV=development
FLASK_DEBUG=True

# API Configuration
API_BASE_URL=http://127.0.0.1:8080

# SSO Authentication (Set to false to use fallback mode)
ENABLE_SSO=false

# SAML Service Provider (SP) Configuration (Required if ENABLE_SSO=true)
SAML_SP_ENTITY_ID=https://ai.yourdomain.com/
SAML_SP_ACS_URL=https://ai.yourdomain.com/saml/acs
SAML_SP_SLO_URL=https://ai.yourdomain.com/saml/sls
SAML_SP_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----
...your_private_key_content...
-----END PRIVATE KEY-----"
SAML_SP_X509_CERT="-----BEGIN CERTIFICATE-----
...your_certificate_content...
-----END CERTIFICATE-----"

# SAML Identity Provider (IdP) Configuration - Azure AD
SAML_IDP_ENTITY_ID=https://sts.windows.net/your-tenant-id/
SAML_IDP_SSO_URL=https://login.microsoftonline.com/your-tenant-id/saml2
SAML_IDP_SLO_URL=https://login.microsoftonline.com/your-tenant-id/saml2
SAML_IDP_X509_CERT="-----BEGIN CERTIFICATE-----
...azure_ad_certificate_content...
-----END CERTIFICATE-----"

# Logging Configuration
LOG_LEVEL=INFO
```

### SSO Configuration

For Azure AD SAML SSO, you need:

1. **Azure AD App Registration**:
   - Configure SAML SSO
   - Set redirect URLs
   - Configure group claims

2. **Certificate**: Download X.509 certificate from Azure AD

3. **Group Mappings**: Configure `app_roles.json` for access control

### Application Roles Configuration

Edit `app_roles.json` to define which Azure AD groups can access which applications. The configuration uses Azure AD group IDs for precise access control:

```json
{
  "DocuClaims AI": {
    "required_groups": [
      "c40e783c-97f3-47d5-9e8e-dd007f1ba704"
    ]
  },
  "Vault Analyst": {
    "required_groups": [
      "c40e783c-97f3-47d5-9e8e-dd007f1ba704"
    ]
  },
  "DocuLegal AI": {
    "required_groups": [
      "c40e783c-97f3-47d5-9e8e-dd007f1ba705"
    ]
  },
  "DocuFinance AI": {
    "required_groups": [
      "c40e783c-97f3-47d5-9e8e-dd007f1ba706"
    ]
  }
}
```

**Note**: Use actual Azure AD group GUIDs from your Azure portal for production deployment.

## File Structure

```
ui/
├── app.py                      # Main Flask application with blueprint registration
├── .env                        # Environment variables configuration
├── app_roles.json             # Application access control configuration
├── __init__.py                 # Package initialization
├── auth/                      # Authentication and authorization system
│   ├── __init__.py
│   ├── access_control.py      # Role-based access control service
│   ├── decorators.py          # Route protection decorators
│   ├── middleware.py          # Authentication middleware
│   ├── models.py              # User and session data models
│   ├── session_manager.py     # Core session management
│   ├── sso_auth.py           # SAML SSO authentication handler
│   └── user_service.py       # User profile and group management
├── modules/                   # Application modules (Flask blueprints)
│   ├── __init__.py
│   └── docuclaims/           # DocuClaims AI application module
│       ├── __init__.py
│       ├── routes.py         # DocuClaims routes and API endpoints
│       ├── services.py       # DocuClaims business logic and API integration
│       ├── session_manager.py # DocuClaims-specific session management
│       └── templates/        # DocuClaims-specific templates
│           └── docuclaims.html # Main DocuClaims interface
├── templates/                 # Main application Jinja2 templates
│   ├── base.html             # Base template with navigation and auth
│   ├── home.html             # Landing page with SSO integration
│   ├── applications.html     # Dynamic applications dashboard
│   └── login.html           # Fallback login page (SSO disabled)
├── static/                   # Static web assets
│   ├── css/
│   │   └── style.css        # Comprehensive application styles
│   ├── js/
│   │   └── main.js          # Client-side JavaScript functionality
│   ├── img/                 # Images, icons, and favicon variants
│   │   ├── favicon-32.png
│   │   └── favicon.svg
│   └── favicon.ico          # Main site favicon
├── utils/                   # Shared utility modules
│   ├── __init__.py
│   ├── logging.py           # Centralized logging with rotation
│   ├── secret_key_generator.py  # Security and encryption utilities
│   └── ui_session_manager.py    # UI-specific session management
└── logs/                    # Application logs with automatic rotation
    ├── ui.log              # Current log file
    ├── ui.log.2025-09-19   # Rotated log files
    └── ui.log.2025-09-23   # Rotated log files
```

## Development

### Running in Development Mode

```bash
# Set development environment
export FLASK_ENV=development
export FLASK_DEBUG=True

# Start the application
python app.py

# View logs
tail -f logs/ui.log
```

### Testing Authentication

1. **SSO Enabled**: Test with actual Azure AD credentials
2. **SSO Disabled**: Use the fallback login form
3. **Access Control**: Test with different user groups

### Adding New Applications

1. **Create Blueprint Module**: Create new directory in `modules/` (e.g., `modules/newapp/`)
2. **Implement Routes**: Create `routes.py` with Flask Blueprint
3. **Add Services**: Create `services.py` for business logic and API integration
4. **Create Templates**: Add application-specific templates in `modules/newapp/templates/`
5. **Update `app_roles.json`**: Define required Azure AD groups for access control
6. **Register Blueprint**: Add blueprint registration in main `app.py`
7. **Update Applications Dashboard**: Add new app entry in the apps list in `app.py`
8. **Test Access Control**: Verify group-based access and functionality

**Example Blueprint Structure**:
```
modules/newapp/
├── __init__.py
├── routes.py              # Flask blueprint with routes
├── services.py            # API integration and business logic
├── session_manager.py     # App-specific session handling (optional)
└── templates/
    └── newapp.html       # Main application interface
```

### Custom Styling

- **CSS**: Modify `static/css/style.css`
- **JavaScript**: Add functionality to `static/js/main.js`
- **Images**: Add assets to `static/img/`

## Deployment

### Production Considerations

1. **HTTPS**: Always use HTTPS in production
2. **Secret Key**: Use a secure, random Flask secret key
3. **Session Security**: Configure secure session cookies
4. **Environment Variables**: Secure management of credentials
5. **Process Management**: Use WSGI server (Gunicorn, uWSGI)
6. **Web Server**: Use reverse proxy (nginx, Apache)

### WSGI Deployment (Example)

```bash
# Install WSGI server
pip install gunicorn

# Run with Gunicorn
gunicorn -w 4 -b 0.0.0.0:5001 app:app
```

### Nginx Configuration (Example)

```nginx
server {
    listen 80;
    server_name yourdomain.com;
    
    location / {
        proxy_pass http://127.0.0.1:5001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Docker Deployment (Example)

```dockerfile
FROM python:3.9-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY ui/ ./ui/
WORKDIR /app/ui

EXPOSE 5001
CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:5001", "app:app"]
```

## Troubleshooting

### Common Issues

1. **SSO Authentication Failures**
   - Check Azure AD configuration
   - Verify SAML certificate and URLs
   - Review authentication logs

2. **Access Control Issues**
   - Verify `app_roles.json` configuration
   - Check user's Azure AD group memberships
   - Review access control logs

3. **API Connection Problems**
   - Ensure Snowflake AI API is running
   - Check `API_BASE_URL` configuration
   - Verify network connectivity

4. **Session Issues**
   - Check Flask secret key configuration
   - Verify session timeout settings
   - Clear browser cookies

### Debugging

#### Enable Debug Mode
```python
# In app.py
app.debug = True
```

#### Check Logs
```bash
# View current logs in real-time
tail -f logs/ui.log

# Search for specific errors across all log files
grep ERROR logs/ui.log*

# View recent authentication events
grep "\[SSO\]" logs/ui.log*

# Monitor access control decisions
grep "\[ACCESS_CONTROL\]" logs/ui.log*

# Check application initialization
grep "\[APP_INIT\]" logs/ui.log*
```

#### Test SSO Configuration
```python
# Use test script
python test/test_sso_poc.py
```

### Performance Optimization

1. **Session Management**: Configure appropriate session timeouts
2. **Static Files**: Use web server for static file serving
3. **Caching**: Implement caching for API responses
4. **Database**: Optimize session storage if using database sessions

### Security Checklist

- [ ] HTTPS enabled in production
- [ ] Secure Flask secret key
- [ ] CSRF protection enabled
- [ ] Input validation implemented
- [ ] Security headers configured
- [ ] Audit logging enabled
- [ ] Session security configured
- [ ] File upload restrictions in place

## Testing

### Unit Tests

The application includes test modules for critical functionality:

```bash
# Run access control tests
python -m pytest auth/test_access_control.py

# Test SSO functionality (if available)
python auth/test_sso_poc.py

# Run all available tests
find . -name "test_*.py" -exec python {} \;
```

### Manual Testing

1. **Authentication Flow**: Test SSO login/logout
2. **Access Control**: Test with different user groups
3. **File Upload**: Test document upload functionality
4. **UI Responsiveness**: Test on different screen sizes
5. **Error Handling**: Test error scenarios

## Integration with API

The UI application integrates seamlessly with the Snowflake AI API through modular services:

### DocuClaims Integration (`modules/docuclaims/services.py`)

- **File Upload**: Handles document uploads with validation and progress tracking
- **Model Selection**: Fetches available AI models from API dynamically
- **Question Answering**: Real-time communication with AI models for document analysis
- **Chat History**: Maintains conversation context across sessions
- **File Processing**: Monitors document processing status and provides feedback
- **Error Handling**: Comprehensive error handling with user-friendly messages

### API Configuration

- **Base URL**: Configured via `API_BASE_URL` environment variable (default: `http://127.0.0.1:8080`)
- **Timeout Handling**: Automatic request timeouts and retry logic
- **Response Processing**: Structured response parsing and validation
- **Authentication**: User context passed to API when authentication is enabled

### Service Architecture

Each application module includes its own `services.py` file that handles:
- API endpoint communication
- Request/response transformation  
- Error handling and logging
- Business logic specific to the application

Ensure the Snowflake AI API is running and accessible at the configured `API_BASE_URL` before starting the UI application.

## Support

For issues or questions:

1. Check the logs in `ui/logs/ui.log`
2. Review this documentation
3. Verify SSO and Azure AD configuration
4. Test with SSO disabled to isolate issues
5. Check API connectivity and status

---

**Note**: This web application is designed to work with the Snowflake AI API. For complete functionality, ensure both components are properly configured and running.
