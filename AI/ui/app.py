from flask import Flask, render_template, request, redirect, url_for, flash, jsonify, session
import os
from dotenv import load_dotenv
from utils.logging import logger

# Import auth components
from auth.sso_auth import SSOAuth
from auth.session_manager import SessionManager
from auth.user_service import UserService
from auth.models import User
from auth.decorators import login_required, require_app_access
from auth.access_control import AccessControlService

# Import DocuClaims blueprint
from modules.docuclaims.routes import docuclaims_bp

# Load environment variables
load_dotenv()

# Initialize Flask app
app = Flask(__name__)

# Configure session security with fixed secret key
if 'FLASK_SECRET_KEY' in os.environ:
    app.secret_key = os.environ['FLASK_SECRET_KEY']
    logger.info("[APP_INIT] Using FLASK_SECRET_KEY from environment")
else:
    # Fixed secret key for session persistence across app restarts
    app.secret_key = 'snowflake-ai-ui-2025-session-key-64-chars-fixed-for-persistence'
    logger.info("[APP_INIT] Using fixed secret key for session persistence across restarts")

app.config['MAX_CONTENT_LENGTH'] = 200 * 1024 * 1024  # 200MB max upload size

# Log session configuration
logger.info("[APP_INIT] Flask secret key configured for secure sessions")
logger.info("[APP_INIT] Flask session configuration loaded")

# Initialize auth components
sso_auth = SSOAuth()
session_manager = SessionManager()
user_service = UserService()

# Initialize access control service
access_control = AccessControlService()

# Manually set the app and components for SSOAuth without route registration
sso_auth.app = app
sso_auth.session_manager = session_manager
sso_auth.user_service = user_service

logger.info("[APP_INIT] SSO authentication components and access control service initialized")

# Register blueprints
app.register_blueprint(docuclaims_bp)
logger.info("[APP_INIT] DocuClaims blueprint registered")

# No theme customization

# Compatibility route for SSOAuth which expects 'index' endpoint
@app.route('/index')
@login_required
def index():
    """Index route - redirects to applications page after SSO login for compatibility with SSOAuth"""
    return redirect(url_for('applications'))

@app.route('/applications')
@login_required  # Add authentication protection
def applications():
    """Applications page displaying available AI tools and services"""
    # Get user IP for tracking
    client_ip = request.environ.get('HTTP_X_FORWARDED_FOR', request.environ.get('REMOTE_ADDR', 'unknown'))
    if ',' in client_ip:
        client_ip = client_ip.split(',')[0].strip()
    
    logger.info(f"Applications page accessed by IP: {client_ip}")
    
    # Check if SSO is enabled
    sso_enabled = os.getenv('ENABLE_SSO', 'false').lower() == 'true'
    
    # Get current user for personalization
    user = session_manager.get_current_user()
    
    # Extract first name for personalized greeting
    first_name = "User"  # Default fallback
    if user and user.display_name:
        # Try to extract first name from display_name
        name_parts = user.display_name.split()
        if name_parts:
            first_name = name_parts[0]
    elif user and user.username:
        # Fallback to username if no display name
        first_name = user.username.split('@')[0] if '@' in user.username else user.username
    
    logger.info(f"Applications page loaded for user: {user.username if user else 'Unknown'} (Display: {first_name}) - SSO enabled: {sso_enabled}")
    
    # Available applications (complete list)
    apps = [
        {
            'id': 'docuclaims',
            'name': 'DocuClaims AI',
            'description': 'AI-powered document analysis and claims processing',
            'icon': 'fa-file-contract',
            'url': url_for('docuclaims.docuclaims'),
            'status': 'active'
        },
        # {
        #     'id': 'vaultanalyst',
        #     'name': 'Vault Analyst',
        #     'description': 'Advanced data analysis and intelligence platform',
        #     'icon': 'fa-chart-pie',
        #     'url': url_for('vaultanalyst'),
        #     'status': 'coming_soon'
        # },
        {
            'id': 'doculegal',
            'name': 'DocuLegal AI',
            'description': 'Legal document analysis and compliance checking',
            'icon': 'fa-balance-scale',
            'url': '#',
            'status': 'coming_soon'
        },
        {
            'id': 'docufinance',
            'name': 'DocuFinance AI',
            'description': 'Financial document processing and analysis',
            'icon': 'fa-chart-line',
            'url': '#',
            'status': 'coming_soon'
        }
    ]
    
    # Apply role-based access control filtering only when SSO is enabled
    if sso_enabled:
        try:
            # Get user groups from the current user object
            user_groups = user.groups if user and hasattr(user, 'groups') and user.groups else []
            
            # Log user groups for debugging (only log count for security)
            logger.info(f"[ACCESS_CONTROL] User has {len(user_groups)} groups for filtering")
            
            # Filter applications based on user groups
            filtered_apps = access_control.filter_applications(apps, user_groups)
            
            logger.info(f"[ACCESS_CONTROL] Filtered {len(apps)} applications to {len(filtered_apps)} accessible applications")
            
            # Use filtered applications
            apps = filtered_apps
            
        except Exception as e:
            logger.error(f"[ACCESS_CONTROL] Error during application filtering: {e}")
            logger.info("[ACCESS_CONTROL] Falling back to showing all applications due to filtering error")
            # On error, keep original apps list for backward compatibility
    else:
        # When SSO is disabled, show all applications without filtering
        logger.info(f"[ACCESS_CONTROL] SSO disabled, showing all {len(apps)} applications without filtering")
    
    return render_template('applications.html', 
                         user=user, 
                         first_name=first_name,
                         apps=apps,
                         config=os.environ)

@app.route('/favicon.ico')
def favicon():
    return app.send_static_file('favicon.ico')

@app.route('/')
def home():
    # Filter out health check requests from monitoring systems
    client_ip = request.environ.get('HTTP_X_FORWARDED_FOR', request.environ.get('REMOTE_ADDR', 'unknown'))
    
    # Known monitoring/health check IP addresses
    monitoring_ips = ['10.72.13.199', '10.72.13.196']
    
    # Only log actual user visits, not health checks
    if client_ip not in monitoring_ips:
        logger.info(f"Landing page loaded by user from IP: {client_ip}")
    
    # Get current user for template context
    user = session_manager.get_current_user()
    
    # Pass config to template for SSO check
    return render_template('home.html', user=user, config=os.environ)

# Theme customization removed

# Helper functions
# ============================================================================
# SSO AUTHENTICATION ROUTES
# ============================================================================

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
        logger.error(f"[SSO_SSO] Error starting SSO: {str(e)}")
        return f"Error starting SSO: {str(e)}", 500

@app.route('/saml/acs', methods=['GET', 'POST'])
def saml_acs():
    """SAML Assertion Consumer Service - handles SAML response from Azure AD"""
    try:
        return sso_auth.acs()
    except Exception as e:
        logger.error(f"[SSO_ACS] Error processing SSO callback: {str(e)}")
        return f"Error processing SSO callback: {str(e)}", 500

@app.route('/saml/slo', methods=['POST'])
def saml_slo():
    """SAML Single Logout endpoint"""
    try:
        return sso_auth.slo()
    except Exception as e:
        logger.error(f"[SSO_SLO] Error in SLO: {str(e)}")
        return f"Error in SLO: {str(e)}", 500

@app.route('/saml/sls')
def saml_sls():
    """SAML Single Logout Service endpoint"""
    try:
        return sso_auth.sls()
    except Exception as e:
        logger.error(f"[SSO_SLS] Error in SLS: {str(e)}")
        return f"Error in SLS: {str(e)}", 500

@app.route('/saml/metadata')
def saml_metadata():
    """SAML metadata endpoint"""
    try:
        return sso_auth.metadata()
    except Exception as e:
        logger.error(f"[SSO_METADATA] Error generating metadata: {str(e)}")
        return f"Error generating metadata: {str(e)}", 500

# Convenience routes
@app.route('/login')
def login():
    """Convenience login route - redirects to SAML SSO"""
    try:
        if not os.getenv('ENABLE_SSO', 'false').lower() == 'true':
            return "SSO is not enabled. Configure ENABLE_SSO=true in .env", 400
        
        # Redirect to SAML SSO endpoint (like in working POC)
        return redirect(url_for('saml_sso'))
        
    except Exception as e:
        logger.error(f"[SSO_LOGIN] Error starting SSO: {str(e)}")
        return f"Error starting SSO: {str(e)}", 500

@app.route('/logout')
def logout():
    """Close session"""
    try:
        session_manager.clear_session()
        logger.info("[SSO_LOGOUT] User session cleared successfully")
        return redirect(url_for('home'))
    except Exception as e:
        logger.error(f"[SSO_LOGOUT] Error in logout: {str(e)}")
        return f"Error in logout: {str(e)}", 500

if __name__ == "__main__":
    # Use debug based on environment variable
    debug_mode = os.environ.get('FLASK_DEBUG', 'False').lower() == 'true'
    app.run(debug=debug_mode, host='127.0.0.1', port=5001)
