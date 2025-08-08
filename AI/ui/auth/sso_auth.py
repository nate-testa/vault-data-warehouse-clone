"""
SSO authentication module using SAML with Azure AD.

This module provides SSO authentication functionality using SAML protocol
with Azure AD integration. It has been refactored to use the new authentication
models and services while maintaining backward compatibility.
"""

import os
from typing import Dict, Optional, Any
from flask import request, session, redirect, url_for, render_template, current_app
from onelogin.saml2.auth import OneLogin_Saml2_Auth
from onelogin.saml2.utils import OneLogin_Saml2_Utils
from dotenv import load_dotenv

from .models import User, Session as AuthSession
from .session_manager import SessionManager
from .user_service import UserService
from utils.logging import logger

# Load environment variables from .env file
load_dotenv()


class SSOAuth:
    """
    Class to handle SSO authentication functionality using SAML.
    
    This class has been refactored to integrate with the new authentication
    models and services while maintaining the same external interface.
    """
    
    def __init__(self, app=None, session_manager: Optional[SessionManager] = None, 
                 user_service: Optional[UserService] = None):
        """
        Initialize the SSO authentication module.
        
        Args:
            app: Flask application instance
            session_manager: Session manager instance
            user_service: User service instance
        """
        self.app = app
        self.session_manager = session_manager
        self.user_service = user_service
        self.sso_enabled = os.getenv("ENABLE_SSO", "false").lower() == "true"
        
        if app is not None:
            self.init_app(app)
    
    def init_app(self, app):
        """
        Initialize the SSO authentication module with Flask app.
        
        Args:
            app: Flask application instance
        """
        self.app = app
        
        # Initialize session manager and user service if not provided
        if self.session_manager is None:
            self.session_manager = SessionManager(app)
        if self.user_service is None:
            self.user_service = UserService()
        
        # Register SSO routes
        if self.sso_enabled:
            app.add_url_rule('/saml/sso', 'saml_sso', self.sso)
            app.add_url_rule('/saml/acs', 'saml_acs', self.acs, methods=['POST'])
            app.add_url_rule('/saml/slo', 'saml_slo', self.slo, methods=['POST'])
            app.add_url_rule('/saml/sls', 'saml_sls', self.sls)
            app.add_url_rule('/saml/metadata', 'saml_metadata', self.metadata)
        
        # Always register the regular logout route for when SSO is disabled
        app.add_url_rule('/logout', 'logout', self.logout)
    
    def is_sso_enabled(self) -> bool:
        """
        Check if SSO authentication is enabled.
        
        Returns:
            bool: True if SSO is enabled, False otherwise
        """
        return self.sso_enabled
    
    def is_authenticated(self) -> bool:
        """
        Check if user is authenticated.
        
        Returns:
            bool: True if user is authenticated, False otherwise
        """
        if self.session_manager is None:
            return 'user' in session  # Fallback to legacy session check
        return self.session_manager.is_authenticated()
    
    def get_current_user(self) -> Optional[User]:
        """
        Get the currently authenticated user.
        
        Returns:
            Optional[User]: Current user if authenticated, None otherwise
        """
        if self.session_manager is None:
            return None  # Fallback when session manager not available
        return self.session_manager.get_current_user()
    
    def init_saml_auth(self, req: Dict[str, Any]) -> OneLogin_Saml2_Auth:
        """
        Initialize SAML authentication object.
        
        Args:
            req: Request object dictionary
            
        Returns:
            OneLogin_Saml2_Auth: SAML authentication object
        """
        # Process certificates to remove headers and footers
        sp_cert = self._clean_certificate(os.getenv("SAML_SP_X509_CERT"))
        sp_key = self._clean_private_key(os.getenv("SAML_SP_PRIVATE_KEY"))
        idp_cert = self._clean_certificate(os.getenv("SAML_IDP_X509_CERT"))
        
        # Build configuration directly from environment variables
        settings_data = {
            "strict": True,   # Enable strict mode now that certificate is correct
            "debug": False,   # Disable debug in production
            "sp": {
                "entityId": os.getenv("SAML_SP_ENTITY_ID"),
                "assertionConsumerService": {
                    "url": os.getenv("SAML_SP_ACS_URL"),
                    "binding": "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
                },
                "singleLogoutService": {
                    "url": os.getenv("SAML_SP_SLO_URL"),
                    "binding": "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"
                },
                "x509cert": sp_cert,
                "privateKey": sp_key,
                "NameIDFormat": "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"
            },
            "idp": {
                "entityId": os.getenv("SAML_IDP_ENTITY_ID"),
                "singleSignOnService": {
                    "url": os.getenv("SAML_IDP_SSO_URL"),
                    "binding": "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"
                },
                "singleLogoutService": {
                    "url": os.getenv("SAML_IDP_SLO_URL"),
                    "binding": "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"
                },
                "x509cert": idp_cert
            },
            "security": {
                "nameIdEncrypted": False,
                "authnRequestsSigned": False,
                "logoutRequestSigned": False,
                "logoutResponseSigned": False,
                "signMetadata": False,
                "wantAssertionsSigned": True,      # Keep this - Azure sends signed assertions
                "wantMessagesSigned": False,       # Azure doesn't sign the entire message
                "wantLogoutResponseSigned": False,
                "wantLogoutRequestSigned": False,
                "wantAssertionsEncrypted": False,
                "wantNameIdEncrypted": False,
                "requestedAuthnContext": False,
                "relaxDestinationValidation": True,  # Keep this for proxy setup
                "allowRepeatAttributeName": True,    # Keep this for Azure attributes
                "rejectUnsolicitedResponsesWithInResponseTo": False,
                "validateXML": True,
                "signatureAlgorithm": "http://www.w3.org/2000/09/xmldsig#rsa-sha256",  # Use stronger algorithm
                "digestAlgorithm": "http://www.w3.org/2000/09/xmldsig#sha256"          # Use stronger algorithm
            }
        }
        
        # Create and return authentication object using configuration
        auth = OneLogin_Saml2_Auth(req, old_settings=settings_data)
        return auth
    
    def _clean_certificate(self, cert: Optional[str]) -> str:
        """
        Clean certificate by removing headers and footers.
        
        Args:
            cert: Certificate string
            
        Returns:
            str: Cleaned certificate
        """
        if not cert:
            return ""
        return cert.replace("-----BEGIN CERTIFICATE-----\n", "").replace("-----END CERTIFICATE-----", "").strip()
    
    def _clean_private_key(self, key: Optional[str]) -> str:
        """
        Clean private key by removing headers and footers.
        
        Args:
            key: Private key string
            
        Returns:
            str: Cleaned private key
        """
        if not key:
            return ""
        return key.replace("-----BEGIN PRIVATE KEY-----\n", "").replace("-----END PRIVATE KEY-----", "").strip()

    def prepare_flask_request(self, request) -> Dict[str, Any]:
        """
        Prepare Flask request for python3-saml.
        
        Args:
            request: Flask request object
            
        Returns:
            dict: Request data for SAML authentication
        """
        # Determine if we're using HTTPS - consider proxy headers
        https = 'on'
        if request.scheme == 'https':
            https = 'on'
        elif request.headers.get('X-Forwarded-Proto') == 'https':
            https = 'on'
        elif os.getenv('FORCE_HTTPS') == 'true':
            https = 'on'
        else:
            https = 'off'
            
        logger.info(f"HTTPS status: {https}, Host: {request.host}, Path: {request.path}")
        
        return {
            'https': https,
            'http_host': request.host,
            'script_name': request.path,
            'get_data': request.args.copy(),
            'post_data': request.form.copy(),
            'query_string': request.query_string
        }

    def sso(self):
        """
        Handle Single Sign-On request.
        
        Returns:
            Response: Redirect to identity provider login
        """
        req = self.prepare_flask_request(request)
        auth = self.init_saml_auth(req)
        return redirect(auth.login())

    def acs(self):
        """
        Handle Assertion Consumer Service (ACS) - process SAML response.
        
        Returns:
            Response: Redirect to index page or login page with error
        """
        req = self.prepare_flask_request(request)
        auth = self.init_saml_auth(req)
        
        # Add debug information before processing response
        logger.info("Processing SAML response at /saml/acs")
        
        try:
            auth.process_response()
            errors = auth.get_errors()
            error_reason = auth.get_last_error_reason()
            
            logger.info(f"SAML errors: {errors}")
            logger.info(f"Error reason: {error_reason}")
            
            if not errors:
                logger.info("SAML authentication successful, processing user data")
                
                # Extract user information using new models
                name_id = auth.get_nameid()
                attributes = auth.get_attributes()
                
                logger.info(f"NameID: {name_id}")
                logger.info(f"User attributes: {attributes}")
                
                # Ensure name_id is not None
                if not name_id:
                    logger.error("No NameID received from SAML response")
                    return render_template('login.html', error="Authentication failed: No user identifier received")
                
                # Create user object from SAML attributes
                user = User.from_saml_attributes(name_id, attributes)
                
                # Enhanced user with user service if available
                if self.user_service is not None:
                    enhanced_user = self.user_service.create_user_from_saml(name_id, attributes)
                else:
                    enhanced_user = user
                
                # Create session using session manager if available
                if self.session_manager is not None:
                    auth_session = self.session_manager.create_session(
                        enhanced_user,
                        saml_session_index=auth.get_session_index(),
                        saml_nameid=name_id
                    )
                    logger.info(f"Created session for user: {enhanced_user.username}")
                else:
                    # Fallback to legacy session storage
                    session['user'] = attributes
                    session['saml_session_index'] = auth.get_session_index()
                    session['saml_nameid'] = name_id
                    logger.info(f"Created legacy session for user: {enhanced_user.username}")
                
                return redirect(url_for('index'))
            else:
                error_msg = f"Errors: {', '.join(errors)}. Reason: {error_reason}"
                logger.error(f"SAML authentication error: {error_msg}")
                return render_template('login.html', error=error_msg)
                
        except Exception as e:
            logger.error(f"Exception when processing SAML response: {str(e)}")
            return render_template('login.html', error=f"Processing error: {str(e)}")

    def slo(self):
        """
        Handle Single Logout (SLO) request.
        
        Returns:
            Response: Redirect to IdP logout URL or login page
        """
        req = self.prepare_flask_request(request)
        auth = self.init_saml_auth(req)
        
        logger.info("Processing SAML logout...")
        
        # Get session information
        name_id = None
        session_index = None
        
        if self.session_manager is not None:
            auth_session = self.session_manager.get_current_session()
            if auth_session:
                name_id = auth_session.saml_name_id
                session_index = auth_session.saml_session_index
        else:
            # Fallback to legacy session
            name_id = session.get('saml_nameid')
            session_index = session.get('saml_session_index')
        
        logger.info(f"NameID: {name_id}")
        logger.info(f"Session Index: {session_index}")
        
        # Clear local session first to ensure user logs out locally
        if self.session_manager is not None:
            self.session_manager.clear_session()
        else:
            session.clear()
        
        try:
            # Try SAML logout
            logout_url = auth.logout(
                name_id=name_id, 
                session_index=session_index, 
                return_to=url_for('login', _external=True)
            )
            logger.info(f"Logout URL: {logout_url}")
            return redirect(logout_url)
        except Exception as e:
            logger.error(f"Error in SAML logout: {str(e)}")
            # In case of error, simply redirect to login page
            return redirect(url_for('login'))

    def sls(self):
        """
        Handle Single Logout Service (SLS) - process logout response from IdP.
        
        Returns:
            Response: Redirect to login page
        """
        logger.info("Processing logout response from IdP...")
        req = self.prepare_flask_request(request)
        auth = self.init_saml_auth(req)
        
        try:
            # Process logout response with proper session cleanup
            def clear_session_callback():
                if self.session_manager is not None:
                    self.session_manager.clear_session()
                else:
                    session.clear()
            
            url = auth.process_slo(delete_session_cb=clear_session_callback)
            errors = auth.get_errors()
            
            logger.info(f"SLS errors: {errors}")
            
            if len(errors) == 0:
                logger.info("Logout successful")
                if url is not None:
                    return redirect(url)
                return redirect(url_for('login'))
            else:
                error_reason = auth.get_last_error_reason()
                logger.error(f"Logout error: {errors}, Reason: {error_reason}")
                # Despite SAML error, clear local session anyway
                if self.session_manager is not None:
                    self.session_manager.clear_session()
                else:
                    session.clear()
                return render_template('login.html', 
                    error=f"Logout error: {', '.join(errors)}. Reason: {error_reason}")
        except Exception as e:
            logger.error(f"Exception in SLO process: {str(e)}")
            if self.session_manager is not None:
                self.session_manager.clear_session()
            else:
                session.clear()
            return redirect(url_for('login'))

    def metadata(self):
        """
        Generate SAML metadata for service provider.
        
        Returns:
            Response: XML metadata or error message
        """
        req = self.prepare_flask_request(request)
        auth = self.init_saml_auth(req)
        settings = auth.get_settings()
        metadata = settings.get_sp_metadata()
        errors = settings.validate_metadata(metadata)

        if len(errors) == 0:
            resp = current_app.make_response(metadata)
            resp.headers['Content-Type'] = 'text/xml'
            return resp
        else:
            return 'Error found when validating SP metadata: %s' % (', '.join(errors))

    def logout(self):
        """
        Alternative route for local logout in case of SAML SLO issues.
        
        Returns:
            Response: Redirect to login page
        """
        # Clear local session and redirect to login
        if self.session_manager is not None:
            self.session_manager.clear_session()
        else:
            session.clear()
        return redirect(url_for('login'))

    # Legacy compatibility methods for existing code
    def get_user_info(self) -> Optional[Dict[str, Any]]:
        """
        Get user information in legacy format for backward compatibility.
        
        Returns:
            Optional[Dict[str, Any]]: User info dictionary or None
        """
        user = self.get_current_user()
        if user:
            return {
                'user': user.attributes,
                'username': user.username,
                'display_name': user.display_name,
                'groups': user.groups
            }
        return None
