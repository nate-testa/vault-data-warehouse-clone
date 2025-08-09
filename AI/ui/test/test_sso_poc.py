#!/usr/bin/env python3
"""
Basic POC for testing SSO SAML login
This script creates a minimal Flask app to test SSO authentication flow

SAML Endpoints (matching .env configuration):
- /saml/sso - SSO Initiation (redirects to Azure AD)
- /saml/acs - Assertion Consumer Service (handles Azure AD response)
- /saml/slo - Single Logout (POST)
- /saml/sls - Single Logout Service (GET)
- /saml/metadata - SAML Metadata

Convenience Routes:
- /login - Redirects to /saml/sso
- /logout - Clears session and redirects home

Usage with nginx + gunicorn:
    gunicorn -w 9 -b 127.0.0.1:5000 --timeout 300 test_sso_poc:app
"""

import os
import sys
from flask import Flask, request, session, redirect, url_for, render_template_string
from flask import render_template as flask_render_template
from dotenv import load_dotenv

# Load environment variables from ui/.env file
env_path = os.path.join(os.path.dirname(__file__), 'ui', '.env')
load_dotenv(dotenv_path=env_path)

# Add ui directory to path for importing modules
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'ui'))

# Import our auth modules
from auth.sso_auth import SSOAuth
from auth.session_manager import SessionManager
from auth.user_service import UserService
from auth.models import User

app = Flask(__name__, template_folder='templates')
app.secret_key = os.getenv('FLASK_SECRET_KEY', 'dev-only-insecure-key')

# Initialize auth components
sso_auth = SSOAuth()  # DON'T pass app to avoid auto-registration of routes
session_manager = SessionManager()
user_service = UserService()

# Manually set the app and components for SSOAuth without route registration
sso_auth.app = app
sso_auth.session_manager = session_manager
sso_auth.user_service = user_service

# Enhanced HTML templates
BASE_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{% block title %}SSO SAML POC Test{% endblock %}</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        .container { 
            max-width: 800px; 
            margin: 0 auto; 
            background: white; 
            border-radius: 12px; 
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            overflow: hidden;
        }
        .header { 
            background: #2c3e50; 
            color: white; 
            padding: 30px; 
            text-align: center;
        }
        .header h1 { font-size: 2.5em; margin-bottom: 10px; }
        .header p { opacity: 0.8; font-size: 1.1em; }
        .content { padding: 40px; }
        .card { 
            background: #f8f9fa; 
            border-left: 4px solid #007cba; 
            padding: 20px; 
            margin: 20px 0; 
            border-radius: 8px;
        }
        .user-card { border-left-color: #28a745; }
        .error-card { border-left-color: #dc3545; }
        .warning-card { border-left-color: #ffc107; }
        .btn { 
            display: inline-block;
            padding: 12px 24px; 
            text-decoration: none; 
            border-radius: 6px; 
            font-weight: 500;
            margin: 5px;
            transition: all 0.3s ease;
        }
        .btn-primary { background: #007cba; color: white; }
        .btn-primary:hover { background: #005a8b; }
        .btn-danger { background: #dc3545; color: white; }
        .btn-danger:hover { background: #c82333; }
        .btn-secondary { background: #6c757d; color: white; }
        .btn-secondary:hover { background: #5a6268; }
        .status-grid { 
            display: grid; 
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); 
            gap: 15px; 
            margin: 20px 0;
        }
        .status-item { 
            background: #e9ecef; 
            padding: 15px; 
            border-radius: 8px; 
            text-align: center;
        }
        .status-value { font-weight: bold; font-size: 1.2em; margin-top: 5px; }
        .status-ok { color: #28a745; }
        .status-error { color: #dc3545; }
        .status-warning { color: #ffc107; }
        .debug-section { 
            background: #f1f3f4; 
            border-radius: 8px; 
            padding: 20px; 
            margin-top: 30px;
            font-family: 'Courier New', monospace;
            font-size: 0.9em;
        }
        .nav-bar { 
            background: #343a40; 
            padding: 15px 40px; 
            display: flex; 
            justify-content: space-between; 
            align-items: center;
        }
        .nav-bar a { 
            color: white; 
            text-decoration: none; 
            margin: 0 10px; 
            padding: 8px 16px; 
            border-radius: 4px; 
            transition: background 0.3s;
        }
        .nav-bar a:hover { background: rgba(255,255,255,0.1); }
        .nav-bar .active { background: #007cba; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔐 SSO SAML POC</h1>
            <p>Proof of Concept for Azure AD Authentication</p>
        </div>
        
        <div class="nav-bar">
            <div>
                <a href="/" class="{% if request.endpoint == 'home' %}active{% endif %}">🏠 Home</a>
                <a href="/health" class="{% if request.endpoint == 'health' %}active{% endif %}">🏥 Health Check</a>
                <a href="/config" class="{% if request.endpoint == 'config' %}active{% endif %}">⚙️ Configuration</a>
            </div>
            <div>
                {% if user %}
                    <span style="color: white;">👤 {{ user.username }}</span>
                    <a href="/logout" class="btn-danger">Logout</a>
                {% else %}
                    <a href="/login" class="btn-primary">Login SSO</a>
                {% endif %}
            </div>
        </div>
        
        <div class="content">
            {% block content %}{% endblock %}
        </div>
    </div>
</body>
</html>
"""

HOME_TEMPLATE = """
{% extends "base" %}
{% block content %}
    {% if user %}
    <div class="card user-card">
        <h2>✅ Authentication Successful!</h2>
        <div class="status-grid">
            <div class="status-item">
                <div>User</div>
                <div class="status-value status-ok">{{ user.username }}</div>
            </div>
            <div class="status-item">
                <div>Full Name</div>
                <div class="status-value">{{ user.full_name or 'N/A' }}</div>
            </div>
            <div class="status-item">
                <div>Email</div>
                <div class="status-value">{{ user.email or 'N/A' }}</div>
            </div>
            <div class="status-item">
                <div>Groups</div>
                <div class="status-value">{{ user.groups | length if user.groups else 0 }}</div>
            </div>
        </div>
        
        {% if user.groups %}
        <h3>Azure AD Groups:</h3>
        <ul style="margin: 10px 0;">
        {% for group in user.groups %}
            <li style="margin: 5px 0; padding: 5px; background: white; border-radius: 4px;">{{ group }}</li>
        {% endfor %}
        </ul>
        {% endif %}
        
        <p><strong>Session started:</strong> {{ user.created_at }}</p>
    </div>
    {% else %}
    <div class="card">
        <h2>🔑 Login</h2>
        <p>Click the button to start the SSO SAML authentication process with Azure AD:</p>
        <br>
        <a href="/login" class="btn btn-primary">🚀 Login with Azure SSO</a>
    </div>
    
    <div class="card {% if not sso_enabled %}warning-card{% endif %}">
        <h3>System Status</h3>
        <div class="status-grid">
            <div class="status-item">
                <div>SSO Enabled</div>
                <div class="status-value {% if sso_enabled %}status-ok{% else %}status-error{% endif %}">
                    {{ '✅ YES' if sso_enabled else '❌ NO' }}
                </div>
            </div>
            <div class="status-item">
                <div>Azure SAML URL</div>
                <div class="status-value {% if saml_url %}status-ok{% else %}status-error{% endif %}">
                    {{ '✅ Configured' if saml_url else '❌ Not configured' }}
                </div>
            </div>
        </div>
        
        {% if not sso_enabled %}
        <div style="margin-top: 15px; padding: 15px; background: #fff3cd; border-radius: 6px;">
            <strong>⚠️ SSO Disabled:</strong> To test SSO, configure <code>ENABLE_SSO=true</code> in .env file
        </div>
        {% endif %}
    </div>
    {% endif %}
    
    <div class="debug-section">
        <h3>🔍 Debug Information</h3>
        <p><strong>Session ID:</strong> {{ session_id or 'No active session' }}</p>
        <p><strong>Request Path:</strong> {{ request.path }}</p>
        <p><strong>Method:</strong> {{ request.method }}</p>
        <p><strong>User Agent:</strong> {{ request.headers.get('User-Agent', 'N/A')[:50] }}...</p>
        <hr style="margin: 15px 0; border: 1px solid #ddd;">
        <p><strong>SAML Configuration:</strong></p>
        <p><strong>ACS URL:</strong> {{ config_data.get('acs_url', 'Not configured') }}</p>
        <p><strong>SSO URL:</strong> {{ config_data.get('sso_url', 'Not configured') }}</p>
        <p><strong>Entity ID:</strong> {{ config_data.get('entity_id', 'Not configured') }}</p>
    </div>
{% endblock %}
"""

HEALTH_TEMPLATE = """
{% extends "base" %}
{% block title %}Health Check - SSO POC{% endblock %}
{% block content %}
    <div class="card">
        <h2>🏥 Health Check</h2>
        <p>SSO system components status</p>
    </div>
    
    <div class="status-grid">
        <div class="status-item">
            <div>General Status</div>
            <div class="status-value status-ok">{{ health_data.status.upper() }}</div>
        </div>
        <div class="status-item">
            <div>SSO Enabled</div>
            <div class="status-value {% if health_data.sso_enabled %}status-ok{% else %}status-error{% endif %}">
                {{ '✅' if health_data.sso_enabled else '❌' }}
            </div>
        </div>
        <div class="status-item">
            <div>Azure Configured</div>
            <div class="status-value {% if health_data.azure_configured %}status-ok{% else %}status-error{% endif %}">
                {{ '✅' if health_data.azure_configured else '❌' }}
            </div>
        </div>
    </div>
    
    <div class="card">
        <h3>Loaded Components</h3>
        <ul>
        {% for component, type_info in health_data.components.items() %}
            <li style="margin: 10px 0; padding: 10px; background: white; border-radius: 4px;">
                <strong>{{ component }}:</strong> {{ type_info }}
            </li>
        {% endfor %}
        </ul>
    </div>
{% endblock %}
"""

CONFIG_TEMPLATE = """
{% extends "base" %}
{% block title %}Configuration - SSO POC{% endblock %}
{% block content %}
    <div class="card">
        <h2>⚙️ System Configuration</h2>
        <p>Environment variables and SSO configuration</p>
    </div>
    
    <div class="card {% if not config_data.sso_enabled %}warning-card{% endif %}">
        <h3>SSO Configuration</h3>
        <table style="width: 100%; border-collapse: collapse;">
            <tr style="border-bottom: 1px solid #ddd;">
                <td style="padding: 10px; font-weight: bold;">ENABLE_SSO</td>
                <td style="padding: 10px;">{{ config_data.enable_sso }}</td>
                <td style="padding: 10px;">
                    {% if config_data.sso_enabled %}
                        <span class="status-ok">✅ Enabled</span>
                    {% else %}
                        <span class="status-error">❌ Disabled</span>
                    {% endif %}
                </td>
            </tr>
            <tr style="border-bottom: 1px solid #ddd;">
                <td style="padding: 10px; font-weight: bold;">SAML_IDP_SSO_URL</td>
                <td style="padding: 10px; word-break: break-all;">{{ config_data.azure_saml_url[:50] + '...' if config_data.azure_saml_url and config_data.azure_saml_url|length > 50 else config_data.azure_saml_url or 'Not configured' }}</td>
                <td style="padding: 10px;">
                    {% if config_data.azure_saml_url %}
                        <span class="status-ok">✅ Configured</span>
                    {% else %}
                        <span class="status-error">❌ Missing configuration</span>
                    {% endif %}
                </td>
            </tr>
            <tr>
                <td style="padding: 10px; font-weight: bold;">FLASK_SECRET_KEY</td>
                <td style="padding: 10px;">{{ config_data.secret_key_source }}</td>
                <td style="padding: 10px;">
                    {% if config_data.secret_key %}
                        <span class="status-ok">✅ From .env file</span>
                    {% else %}
                        <span class="status-error">❌ Using default</span>
                    {% endif %}
                </td>
            </tr>
        </table>
    </div>
    
    <div class="card">
        <h3>🧪 Available Tests</h3>
        <p>Actions you can perform to test the system:</p>
        <div style="margin-top: 15px;">
            <a href="/test-session" class="btn btn-secondary">🧪 Test Session Management</a>
            <a href="/test-auth-flow" class="btn btn-secondary">🔄 Simulate Auth Flow</a>
            {% if config_data.sso_enabled %}
                <a href="/login" class="btn btn-primary">🚀 Start Real SSO</a>
                <a href="/saml/metadata" class="btn btn-secondary">📄 SAML Metadata</a>
            {% endif %}
        </div>
    </div>
    
    <div class="card">
        <h3>🔗 SAML Endpoints</h3>
        <p>Available SAML endpoints (matching .env configuration):</p>
        <table style="width: 100%; border-collapse: collapse; margin-top: 15px;">
            <tr style="border-bottom: 1px solid #ddd; background: #f8f9fa;">
                <th style="padding: 10px; text-align: left;">Endpoint</th>
                <th style="padding: 10px; text-align: left;">Purpose</th>
                <th style="padding: 10px; text-align: left;">Methods</th>
            </tr>
            <tr style="border-bottom: 1px solid #ddd;">
                <td style="padding: 10px; font-family: monospace;">/saml/sso</td>
                <td style="padding: 10px;">SSO Initiation</td>
                <td style="padding: 10px;">GET</td>
            </tr>
            <tr style="border-bottom: 1px solid #ddd;">
                <td style="padding: 10px; font-family: monospace;">/saml/acs</td>
                <td style="padding: 10px;">Assertion Consumer Service</td>
                <td style="padding: 10px;">GET, POST</td>
            </tr>
            <tr style="border-bottom: 1px solid #ddd;">
                <td style="padding: 10px; font-family: monospace;">/saml/slo</td>
                <td style="padding: 10px;">Single Logout</td>
                <td style="padding: 10px;">POST</td>
            </tr>
            <tr style="border-bottom: 1px solid #ddd;">
                <td style="padding: 10px; font-family: monospace;">/saml/sls</td>
                <td style="padding: 10px;">Single Logout Service</td>
                <td style="padding: 10px;">GET</td>
            </tr>
            <tr>
                <td style="padding: 10px; font-family: monospace;">/saml/metadata</td>
                <td style="padding: 10px;">SAML Metadata</td>
                <td style="padding: 10px;">GET</td>
            </tr>
        </table>
    </div>
    
    {% if not config_data.sso_enabled or not config_data.azure_saml_url or not config_data.secret_key %}
    <div class="card error-card">
        <h3>⚠️ Configuration Issues</h3>
        {% if not config_data.sso_enabled or not config_data.azure_saml_url %}
        <p>To use SSO, you need to configure:</p>
        <ul style="margin: 10px 0;">
            {% if not config_data.sso_enabled %}
            <li>Set <code>ENABLE_SSO=true</code> in .env</li>
            {% endif %}
            {% if not config_data.azure_saml_url %}
            <li>Configure <code>SAML_IDP_SSO_URL</code> in .env</li>
            {% endif %}
        </ul>
        {% endif %}
        {% if not config_data.secret_key %}
        <div style="margin-top: 15px; padding: 15px; background: #fff3cd; border-radius: 6px;">
            <strong>⚠️ FLASK_SECRET_KEY Missing:</strong> 
            Using insecure default key. For security, add <code>FLASK_SECRET_KEY=your-secure-key</code> to ui/.env file.
            Use <code>python ui/utils/secret_key_generator.py</code> to generate a secure key.
        </div>
        {% endif %}
    </div>
    {% endif %}
{% endblock %}
"""

@app.template_filter('extend')
def extend_template(template_content):
    """Custom filter to handle template inheritance"""
    if template_content.strip().startswith('{% extends "base" %}'):
        return template_content.replace('{% extends "base" %}', BASE_TEMPLATE.replace('{% block content %}{% endblock %}', template_content.split('{% block content %}')[1].split('{% endblock %}')[0]))
    return template_content

# Compatibility route for SSOAuth which expects 'index' endpoint
@app.route('/index')
def index():
    """Index route - redirects to home for compatibility with SSOAuth"""
    return redirect(url_for('home'))

# Add a simple login template function for SSOAuth error handling
@app.route('/login_error')
def login_error():
    """Login error page for SAML authentication failures"""
    error = request.args.get('error', 'Authentication failed')
    return f"""
    <html>
    <head><title>Login Error</title></head>
    <body>
        <h1>Authentication Error</h1>
        <p>{error}</p>
        <a href="/">Return to Home</a>
    </body>
    </html>
    """

@app.route('/')
def home():
    """Main POC page"""
    # Get user from session manager
    user = session_manager.get_current_user()
    session_id = session.get('session_id')
    
    # Render with base template
    template_content = HOME_TEMPLATE
    if template_content.strip().startswith('{% extends "base" %}'):
        final_template = BASE_TEMPLATE.replace(
            '{% block content %}{% endblock %}', 
            template_content.split('{% block content %}')[1].split('{% endblock %}')[0]
        )
        final_template = final_template.replace('{% block title %}SSO SAML POC Test{% endblock %}', 'SSO SAML POC Test')
    else:
        final_template = template_content
    
    return render_template_string(final_template, 
                                user=user,
                                sso_enabled=os.getenv('ENABLE_SSO', 'false').lower() == 'true',
                                saml_url=os.getenv('SAML_IDP_SSO_URL', ''),
                                session_id=session_id,
                                config_data={
                                    'acs_url': os.getenv('SAML_SP_ACS_URL', 'Not configured'),
                                    'sso_url': os.getenv('SAML_IDP_SSO_URL', 'Not configured'),
                                    'entity_id': os.getenv('SAML_SP_ENTITY_ID', 'Not configured')
                                },
                                request=request)

# SAML Standard Routes (matching .env configuration)
@app.route('/saml/sso')
def saml_sso():
    """SAML SSO initiation endpoint"""
    try:
        # Check if SSO is enabled
        if not os.getenv('ENABLE_SSO', 'false').lower() == 'true':
            return "SSO is not enabled. Configure ENABLE_SSO=true in .env", 400
        
        # Call the SSO method directly (it returns a redirect response)
        return sso_auth.sso()
        
    except Exception as e:
        return f"Error starting SSO: {str(e)}", 500

@app.route('/saml/acs', methods=['GET', 'POST'])
def saml_acs():
    """SAML Assertion Consumer Service - handles SAML response from Azure AD"""
    try:
        # Call the correct ACS method from SSOAuth
        return sso_auth.acs()
        
    except Exception as e:
        return f"Error processing SSO callback: {str(e)}", 500

@app.route('/saml/slo', methods=['POST'])
def saml_slo():
    """SAML Single Logout endpoint"""
    try:
        # Call the SLO method from SSOAuth
        return sso_auth.slo()
    except Exception as e:
        return f"Error in SLO: {str(e)}", 500

@app.route('/saml/sls')
def saml_sls():
    """SAML Single Logout Service endpoint"""
    try:
        # Call the SLS method from SSOAuth
        return sso_auth.sls()
    except Exception as e:
        return f"Error in SLS: {str(e)}", 500

@app.route('/saml/metadata')
def saml_metadata():
    """SAML metadata endpoint"""
    try:
        # Call the metadata method from SSOAuth
        return sso_auth.metadata()
    except Exception as e:
        return f"Error generating metadata: {str(e)}", 500

# Convenience routes
@app.route('/login')
def login():
    """Convenience login route - redirects to SAML SSO"""
    try:
        # Check if SSO is enabled
        if not os.getenv('ENABLE_SSO', 'false').lower() == 'true':
            return "SSO is not enabled. Configure ENABLE_SSO=true in .env", 400
        
        # Redirect to SAML SSO endpoint
        return redirect(url_for('saml_sso'))
        
    except Exception as e:
        return f"Error starting SSO: {str(e)}", 500

@app.route('/logout')
def logout():
    """Close session"""
    try:
        # Use session manager to clear session
        session_manager.clear_session()
        return redirect(url_for('home'))
        
    except Exception as e:
        return f"Error in logout: {str(e)}", 500

@app.route('/health')
def health():
    """Health check page with UI"""
    health_data = {
        'status': 'ok',
        'sso_enabled': os.getenv('ENABLE_SSO', 'false').lower() == 'true',
        'azure_configured': bool(os.getenv('SAML_IDP_SSO_URL')),
        'components': {
            'sso_auth': str(type(sso_auth)),
            'session_manager': str(type(session_manager)),
            'user_service': str(type(user_service))
        }
    }
    
    # Check if there's an active session for navbar
    user = session_manager.get_current_user()
    
    template_content = HEALTH_TEMPLATE
    final_template = BASE_TEMPLATE.replace(
        '{% block content %}{% endblock %}', 
        template_content.split('{% block content %}')[1].split('{% endblock %}')[0]
    )
    final_template = final_template.replace('{% block title %}SSO SAML POC Test{% endblock %}', 'Health Check - SSO POC')
    
    return render_template_string(final_template, 
                                health_data=health_data,
                                user=user,
                                request=request)

@app.route('/config')
def config():
    """System configuration page"""
    # Check if FLASK_SECRET_KEY is configured
    flask_secret_key = os.getenv('FLASK_SECRET_KEY')
    
    config_data = {
        'enable_sso': os.getenv('ENABLE_SSO', 'false'),
        'sso_enabled': os.getenv('ENABLE_SSO', 'false').lower() == 'true',
        'azure_saml_url': os.getenv('SAML_IDP_SSO_URL', ''),
        'secret_key': bool(flask_secret_key),
        'secret_key_source': 'Environment (.env)' if flask_secret_key else 'Default (insecure)',
        # Add SAML URLs for debug info
        'acs_url': os.getenv('SAML_SP_ACS_URL', 'Not configured'),
        'sso_url': os.getenv('SAML_IDP_SSO_URL', 'Not configured'),
        'entity_id': os.getenv('SAML_SP_ENTITY_ID', 'Not configured')
    }
    
    # Check if there's an active session for navbar
    user = session_manager.get_current_user()
    
    template_content = CONFIG_TEMPLATE
    final_template = BASE_TEMPLATE.replace(
        '{% block content %}{% endblock %}', 
        template_content.split('{% block content %}')[1].split('{% endblock %}')[0]
    )
    final_template = final_template.replace('{% block title %}SSO SAML POC Test{% endblock %}', 'Configuration - SSO POC')
    
    return render_template_string(final_template, 
                                config_data=config_data,
                                user=user,
                                request=request)

@app.route('/test-session')
def test_session():
    """Test session management functionality"""
    try:
        # Create a test session
        test_user_data = {
            'username': 'test_user',
            'full_name': 'Test User',
            'email': 'test@example.com',
            'groups': ['TestGroup1', 'TestGroup2']
        }
        
        test_session_id = session_manager.create_session(test_user_data)
        retrieved_data = session_manager.get_session_data(test_session_id)
        session_manager.destroy_session(test_session_id)
        
        return {
            'status': 'success',
            'message': 'Session management working correctly',
            'test_session_id': test_session_id,
            'data_retrieved': retrieved_data is not None,
            'data_content': retrieved_data
        }
    except Exception as e:
        return {'status': 'error', 'message': f'Error in session management: {str(e)}'}, 500

@app.route('/test-auth-flow')
def test_auth_flow():
    """Simulate authentication flow without Azure"""
    try:
        # Simulate SAML attributes from Azure (as they would come from SAML response)
        mock_name_id = 'simulated_user@company.com'
        mock_saml_attributes = {
            'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname': ['Simulated'],
            'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname': ['User'],
            'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name': ['Simulated Test User'],
            'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress': ['simulated@company.com'],
            'http://schemas.microsoft.com/ws/2008/06/identity/claims/groups': [
                'Simulated_Group_1', 
                'Simulated_Group_2', 
                'Admin_Test'
            ]
        }
        
        # Create user using the service with proper arguments
        user = user_service.create_user_from_saml(mock_name_id, mock_saml_attributes)
        
        # Create session (pass User object, not dict)
        session_obj = session_manager.create_session(user)
        session['session_id'] = session_obj.session_id
        
        return redirect(url_for('home'))
        
    except Exception as e:
        return f"Error in auth flow simulation: {str(e)}", 500

if __name__ == '__main__':
    print("=== SSO SAML POC Test ===")
    print(f"SSO Enabled: {os.getenv('ENABLE_SSO', 'false')}")
    print(f"Azure SAML URL: {os.getenv('SAML_IDP_SSO_URL', 'Not configured')}")
    print("Starting server on http://localhost:5001")
    print("Use Ctrl+C to stop")
    
    app.run(host='0.0.0.0', port=5001, debug=True)
