import os
from flask import request, session, redirect, url_for, render_template
from onelogin.saml2.auth import OneLogin_Saml2_Auth
from onelogin.saml2.utils import OneLogin_Saml2_Utils

class SSOAuth:
    """
    Class to handle SSO authentication functionality using SAML
    """
    
    def __init__(self, app=None):
        """
        Initialize the SSO authentication module
        
        Args:
            app: Flask application instance
        """
        self.app = app
        self.sso_enabled = os.getenv("ENABLE_SSO", "false").lower() == "true"
        
        if app is not None:
            self.init_app(app)
    
    def init_app(self, app):
        """
        Initialize the SSO authentication module with Flask app
        
        Args:
            app: Flask application instance
        """
        self.app = app
        
        # Register SSO routes
        if self.sso_enabled:
            app.add_url_rule('/saml/sso', 'saml_sso', self.sso)
            app.add_url_rule('/saml/acs', 'saml_acs', self.acs, methods=['POST'])
            app.add_url_rule('/saml/slo', 'saml_slo', self.slo, methods=['POST'])
            app.add_url_rule('/saml/sls', 'saml_sls', self.sls)
            app.add_url_rule('/saml/metadata', 'saml_metadata', self.metadata)
        
        # Always register the regular logout route for when SSO is disabled
        app.add_url_rule('/logout', 'logout', self.logout)
    
    def is_sso_enabled(self):
        """
        Check if SSO authentication is enabled
        
        Returns:
            bool: True if SSO is enabled, False otherwise
        """
        return self.sso_enabled
    
    def is_authenticated(self):
        """
        Check if user is authenticated
        
        Returns:
            bool: True if user is authenticated, False otherwise
        """
        return 'user' in session
    
    def init_saml_auth(self, req):
        """
        Initialize SAML authentication object
        
        Args:
            req: Request object
            
        Returns:
            OneLogin_Saml2_Auth: SAML authentication object
        """
        # Process certificates to remove headers and footers
        sp_cert = os.getenv("SAML_SP_X509_CERT").replace("-----BEGIN CERTIFICATE-----\n", "").replace("-----END CERTIFICATE-----", "").strip()
        sp_key = os.getenv("SAML_SP_PRIVATE_KEY").replace("-----BEGIN PRIVATE KEY-----\n", "").replace("-----END PRIVATE KEY-----", "").strip()
        idp_cert = os.getenv("SAML_IDP_X509_CERT").replace("-----BEGIN CERTIFICATE-----\n", "").replace("-----END CERTIFICATE-----", "").strip()
        
        # Build configuration directly from environment variables
        settings_data = {
            "strict": False,  # Disable strict mode to check if validation is an issue
            "debug": True,
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
                # Add property for NameID format
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
                "authnRequestsSigned": True,
                "logoutRequestSigned": True,
                "logoutResponseSigned": False,  # Don't require signature on logout response
                "signMetadata": False,
                "wantAssertionsSigned": False,  # Relaxed validation
                "wantMessagesSigned": False,    # Relaxed validation
                "wantLogoutResponseSigned": False, # Don't require signature on logout response
                "wantLogoutRequestSigned": False,  # Don't require signature on logout request
                "relaxDestinationValidation": True,
                "allowRepeatAttributeName": True,
                "rejectUnsolicitedResponsesWithInResponseTo": False
            }
        }
        
        # Create and return authentication object using configuration
        auth = OneLogin_Saml2_Auth(req, old_settings=settings_data)
        return auth

    def prepare_flask_request(self, request):
        """
        Prepare Flask request for python3-saml
        
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
            
        print(f"HTTPS status: {https}, Host: {request.host}, Path: {request.path}")
        
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
        Handle Single Sign-On request
        
        Returns:
            Response: Redirect to identity provider login
        """
        req = self.prepare_flask_request(request)
        auth = self.init_saml_auth(req)
        return redirect(auth.login())

    def acs(self):
        """
        Handle Assertion Consumer Service (ACS) - process SAML response
        
        Returns:
            Response: Redirect to index page or login page with error
        """
        req = self.prepare_flask_request(request)
        auth = self.init_saml_auth(req)
        
        # Add debug information before processing response
        print("Processing SAML response at /saml/acs")
        
        try:
            auth.process_response()
            errors = auth.get_errors()
            error_reason = auth.get_last_error_reason()
            
            print("SAML errors:", errors)
            print("Error reason:", error_reason)
            
            if not errors:
                print("SAML authentication successful, getting user attributes")
                session['user'] = auth.get_attributes()
                session['saml_session_index'] = auth.get_session_index()
                session['saml_nameid'] = auth.get_nameid()
                print("User attributes:", session['user'])
                return redirect(url_for('index'))
            else:
                error_msg = f"Errors: {', '.join(errors)}. Reason: {error_reason}"
                print(f"SAML authentication error: {error_msg}")
                return render_template('login.html', error=error_msg)
        except Exception as e:
            print(f"Exception when processing SAML response: {str(e)}")
            return render_template('login.html', error=f"Processing error: {str(e)}")

    def slo(self):
        """
        Handle Single Logout (SLO) request
        
        Returns:
            Response: Redirect to IdP logout URL or login page
        """
        req = self.prepare_flask_request(request)
        auth = self.init_saml_auth(req)
        
        print("Processing SAML logout...")
        name_id = session.get('saml_nameid')
        session_index = session.get('saml_session_index')
        
        print(f"NameID: {name_id}")
        print(f"Session Index: {session_index}")
        
        # Clear local session first to ensure user logs out locally
        session.clear()
        
        try:
            # Try SAML logout
            logout_url = auth.logout(name_id=name_id, session_index=session_index, return_to=url_for('login', _external=True))
            print(f"Logout URL: {logout_url}")
            return redirect(logout_url)
        except Exception as e:
            print(f"Error in SAML logout: {str(e)}")
            # In case of error, simply redirect to login page
            return redirect(url_for('login'))

    def sls(self):
        """
        Handle Single Logout Service (SLS) - process logout response from IdP
        
        Returns:
            Response: Redirect to login page
        """
        print("Processing logout response from IdP...")
        req = self.prepare_flask_request(request)
        auth = self.init_saml_auth(req)
        
        try:
            # Process logout response
            url = auth.process_slo(delete_session_cb=lambda: session.clear())
            errors = auth.get_errors()
            
            print(f"SLS errors: {errors}")
            
            if len(errors) == 0:
                print("Logout successful")
                if url is not None:
                    return redirect(url)
                return redirect(url_for('login'))
            else:
                error_reason = auth.get_last_error_reason()
                print(f"Logout error: {errors}, Reason: {error_reason}")
                # Despite SAML error, clear local session anyway
                session.clear()
                return render_template('login.html', error=f"Logout error: {', '.join(errors)}. Reason: {error_reason}")
        except Exception as e:
            print(f"Exception in SLO process: {str(e)}")
            session.clear()
            return redirect(url_for('login'))

    def metadata(self):
        """
        Generate SAML metadata for service provider
        
        Returns:
            Response: XML metadata or error message
        """
        req = self.prepare_flask_request(request)
        auth = self.init_saml_auth(req)
        settings = auth.get_settings()
        metadata = settings.get_sp_metadata()
        errors = settings.validate_metadata(metadata)

        if len(errors) == 0:
            resp = self.app.make_response(metadata)
            resp.headers['Content-Type'] = 'text/xml'
            return resp
        else:
            return 'Error found when validating SP metadata: %s' % (', '.join(errors))

    def logout(self):
        """
        Alternative route for local logout in case of SAML SLO issues
        
        Returns:
            Response: Redirect to login page
        """
        # Clear local session and redirect to login
        session.clear()
        return redirect(url_for('login'))
