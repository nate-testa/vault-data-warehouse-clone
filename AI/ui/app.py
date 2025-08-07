from flask import Flask, render_template, request, redirect, url_for, flash, jsonify, session
import os
import requests
import time
import urllib.parse
import secrets
from dotenv import load_dotenv
from concurrent.futures import ThreadPoolExecutor, as_completed
from utils_logging import logger
import json

# Import auth components
from auth.sso_auth import SSOAuth
from auth.session_manager import SessionManager
from auth.user_service import UserService
from auth.models import User
from auth.decorators import login_required

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

# Manually set the app and components for SSOAuth without route registration
sso_auth.app = app
sso_auth.session_manager = session_manager
sso_auth.user_service = user_service

logger.info("[APP_INIT] SSO authentication components initialized")

# Fixed color for app styling
PRIMARY_COLOR = "#DC2626"  # Main accent color

# API endpoint configuration
API_BASE = os.environ.get("API_BASE_URL")
if not API_BASE:
    raise RuntimeError("Missing required environment variable: API_BASE_URL")

# No theme customization

# Compatibility route for SSOAuth which expects 'index' endpoint
@app.route('/index')
def index():
    """Index route - redirects to home for compatibility with SSOAuth"""
    return redirect(url_for('home'))

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
        logger.info(f"Home page loaded by user from IP: {client_ip}")
    
    # Get current user for template context
    user = session_manager.get_current_user()
    
    return render_template('home.html', user=user)

@app.route('/docuclaims')
@login_required  # Add authentication protection
def docuclaims():
    # Get user IP for tracking
    client_ip = request.environ.get('HTTP_X_FORWARDED_FOR', request.environ.get('REMOTE_ADDR', 'unknown'))
    if ',' in client_ip:
        client_ip = client_ip.split(',')[0].strip()
    
    logger.info(f"DocuClaims AI page accessed by IP: {client_ip}")
    
    # Initialize session variables if they don't exist
    if 'rag_messages' not in session:
        session['rag_messages'] = []
    if 'file_uploaded' not in session:
        session['file_uploaded'] = False
    if 'uploaded_filename' not in session:
        session['uploaded_filename'] = None
    if 'debug' not in session:
        session['debug'] = False
    if 'use_chat_history' not in session:
        session['use_chat_history'] = True
        
    # Fetch model options from API
    model_options = fetch_model_options()
    
    # Log if no model options are available
    if not model_options:
        logger.error("No model options returned from API")
    
    # Only set a selected model if there are valid options and the current selection is invalid
    if model_options and ('selected_model' not in session or session['selected_model'] not in model_options):
        session['selected_model'] = model_options[0]
    elif not model_options:
        # If no options are available, clear any existing selection
        session['selected_model'] = None
    
    # Get current user for template context
    user = session_manager.get_current_user()
    
    return render_template(
        'docuclaims.html',
        accent_color=PRIMARY_COLOR,  # Using fixed color
        model_options=model_options,
        selected_model=session.get('selected_model'),
        rag_messages=session.get('rag_messages', []),
        file_uploaded=session.get('file_uploaded', False),
        uploaded_filename=session.get('uploaded_filename'),
        use_chat_history=session.get('use_chat_history', True),
        debug=session.get('debug', False),
        user=user
    )

@app.route('/clear_chat', methods=['POST'])
@login_required
def clear_chat():
    session['rag_messages'] = []
    session['rag_warnings'] = []
    return redirect(url_for('docuclaims'))

@app.route('/reset_everything', methods=['POST'])
@login_required
def reset_everything():
    # Reset all session variables
    session['rag_messages'] = []
    session['rag_warnings'] = []
    session['file_uploaded'] = False
    session['uploaded_filename'] = None
    session['debug'] = False
    return redirect(url_for('docuclaims'))

# Theme customization removed

@app.route('/upload_files', methods=['POST'])
@login_required
def upload_files():
    upload_id = f"upload_{int(time.time())}_{os.urandom(4).hex()}"
    
    # Get user IP for tracking
    client_ip = request.environ.get('HTTP_X_FORWARDED_FOR', request.environ.get('REMOTE_ADDR', 'unknown'))
    if ',' in client_ip:
        client_ip = client_ip.split(',')[0].strip()
    
    logger.info(f"[{upload_id}] File upload initiated by IP: {client_ip}")
    
    # Check if files are in request
    if 'files[]' not in request.files:
        logger.error(f"[{upload_id}] No file part in request")
        return jsonify({"error": "No file part in request"}), 400
    
    files = request.files.getlist('files[]')
    
    if not files or all(file.filename == '' for file in files):
        logger.error(f"[{upload_id}] No selected files")
        return jsonify({"error": "No selected files"}), 400
    
    # Log basic file info for debugging
    for file in files:
        if file.filename:
            logger.info(f"[{upload_id}] Processing file: {file.filename}, MIME type: {file.content_type}, Size: {file.content_length if hasattr(file, 'content_length') else 'unknown'}")
    
    # Process each file upload
    file_status = {}
    uploaded_filenames = []
    any_success = False
    
    for file in files:
        if file.filename:  # Check if filename is not None
            filename = file.filename
            # Check file extension locally before sending to API
            extension = os.path.splitext(filename)[1].lower()
            if extension not in ['.pdf', '.txt', '.docx', '.doc']:
                logger.warning(f"[{upload_id}] File type not allowed locally: {extension} for file {filename}")
                file_status[filename] = "error"
                continue
                
            status = handle_file_upload(file)
            file_status[filename] = status
            
            if status == 'processed':
                uploaded_filenames.append(filename)
                any_success = True
    
    # Update session variables
    if uploaded_filenames:
        session['uploaded_filename'] = uploaded_filenames
        session['file_uploaded'] = True
        logger.info(f"[{upload_id}] Files processed successfully: {uploaded_filenames}")
    else:
        logger.warning(f"[{upload_id}] No files were processed successfully. Status: {file_status}")
    
    return jsonify({"file_status": file_status, "uploaded_files": uploaded_filenames})

@app.route('/send_message', methods=['POST'])
@login_required
def send_message():
    # Generate unique session ID for tracking this interaction
    interaction_id = f"rag_{int(time.time())}_{os.urandom(4).hex()}"
    start_time = time.time()
    
    # Get user IP for tracking
    client_ip = request.environ.get('HTTP_X_FORWARDED_FOR', request.environ.get('REMOTE_ADDR', 'unknown'))
    if ',' in client_ip:
        client_ip = client_ip.split(',')[0].strip()  # Get first IP if multiple
    
    prompt = request.form.get('message')
    
    if not prompt or not prompt.strip():
        logger.warning(f"[{interaction_id}] Empty message received from IP: {client_ip}")
        return jsonify({"error": "Empty message"})
    
    # Log the incoming question
    logger.info(f"[{interaction_id}] RAG Query from IP {client_ip}: '{prompt[:100]}{'...' if len(prompt) > 100 else ''}'")
    
    # Prepare user message
    user_message = {"role": "user", "content": prompt}
    
    # Get model directly from form data rather than session
    selected_model = request.form.get('model')
    
    # Fallback to session or default if no model provided in request
    if not selected_model:
        selected_model = session.get('selected_model')
        
        # Final fallback to first available model if no model in session
        if not selected_model:
            selected_model = fetch_model_options()[0] if fetch_model_options() else "default"
            logger.info(f"[{interaction_id}] No model in session or request, using first available: {selected_model}")
    
    logger.info(f"[{interaction_id}] Using LLM model: {selected_model}")
    
    # Get rag_messages from session
    rag_messages = session.get('rag_messages', [])
    
    try:
        # Get chat history for context BEFORE adding the current message
        message_history = get_chat_history() if session.get('use_chat_history', True) else []
        chat_context_length = len(message_history)
        logger.info(f"[{interaction_id}] Chat history context: {chat_context_length} previous messages")
        logger.info(f"[{interaction_id}] [RAG_START] Starting API query process...")
        
        # NOW add user message to chat history (after getting the context)
        rag_messages.append(user_message)
        session['rag_messages'] = rag_messages
        
        # Query document with timeout handling
        response = query_document(prompt, message_history, selected_model)
        
        query_time = time.time() - start_time
        
        if response and "answer" in response:
            answer_text = (
                response.get("answer", "")
                .replace("\\n", "\n")
                .replace("\n", "\n")
            )
            assistant_response_text = f"**Model used:** `{selected_model}`\n\n{answer_text}"
            
            # Log successful response
            answer_length = len(answer_text)
            logger.info(f"[{interaction_id}] [RAG_SUCCESS] Complete interaction finished in {query_time:.2f}s, answer length: {answer_length} chars")
            
        else:
            query_time = time.time() - start_time
            if response is None:
                assistant_response_text = "Sorry, I'm having trouble connecting to the AI service. Please check your connection and try again."
                logger.error(f"[{interaction_id}] [RAG_FAILED] No response from query_document() after {query_time:.2f}s - Likely timeout or connection issue")
            else:
                assistant_response_text = "Sorry, I encountered an error processing your question. The AI service may be temporarily unavailable. Please try again."
                logger.error(f"[{interaction_id}] [RAG_INVALID] Got response but no valid answer after {query_time:.2f}s - Response: {response}")
                
    except requests.ConnectionError as e:
        query_time = time.time() - start_time
        logger.error(f"[{interaction_id}] [RAG_CONNECTION_EXCEPTION] requests.ConnectionError caught after {query_time:.2f}s: {str(e)}")
        assistant_response_text = "Sorry, I cannot connect to the AI service right now. Please check your connection and try again later."
        
    except requests.Timeout as e:
        query_time = time.time() - start_time
        logger.error(f"[{interaction_id}] [RAG_TIMEOUT_EXCEPTION] requests.Timeout caught after {query_time:.2f}s: {str(e)}")
        assistant_response_text = "Sorry, the request timed out while processing your question. This might happen with complex queries or large documents. Please try rephrasing your question or try again."
        assistant_response_text = "Sorry, the request timed out while processing your question. This might happen with complex queries or large documents. Please try rephrasing your question or try again."
        
    except requests.RequestException as e:
        query_time = time.time() - start_time
        logger.error(f"[{interaction_id}] [RAG_REQUEST_EXCEPTION] API request failed after {query_time:.2f}s: {str(e)}")
        assistant_response_text = "Sorry, there was a problem communicating with the AI service. Please try again."
        
    except Exception as e:
        query_time = time.time() - start_time
        logger.error(f"[{interaction_id}] [RAG_EXCEPTION] Unexpected error after {query_time:.2f}s: {str(e)}", exc_info=True)
        assistant_response_text = "Sorry, I encountered an error processing your question. Please try again."
    
    # Add assistant response to chat history
    assistant_message = {"role": "assistant", "content": assistant_response_text}
    rag_messages.append(assistant_message)
    session['rag_messages'] = rag_messages
    
    total_time = time.time() - start_time
    logger.info(f"[{interaction_id}] Total interaction completed in {total_time:.2f}s")
    
    return jsonify({
        "user_message": user_message,
        "assistant_message": assistant_message
    })

@app.route('/toggle_setting', methods=['POST'])
@login_required
def toggle_setting():
    setting = request.form.get('setting')
    value = request.form.get('value') == 'true'
    
    if setting in ['use_chat_history', 'debug']:
        session[setting] = value
    
    return jsonify({"success": True})

@app.route('/select_model', methods=['POST'])
@login_required
def select_model():
    model = request.form.get('model')
    if model:
        session['selected_model'] = model
        logger.info(f"Model selected: {model}")
    else:
        logger.error("Attempt to select model but no model provided")
        return jsonify({"success": False, "error": "No model provided"})
    
    return jsonify({"success": True, "model": model})

@app.route('/check_file_processed/<file_name>')
@login_required
def check_file_processed_endpoint(file_name):
    check_id = f"check_{int(time.time())}"
    logger.info(f"[{check_id}] Checking processing status for file: '{file_name}'")
    try:
        # Ensure the filename is properly URL encoded for the API request
        encoded_file_name = urllib.parse.quote(file_name)
        api_url = f"{API_BASE}/check_file_processed/{encoded_file_name}"
        logger.info(f"[{check_id}] Making API request to: {api_url}")
        
        # Use the existing check_file_processing_status function but with shorter timeout
        r = requests.get(api_url, timeout=5)
        
        if r.status_code == 200:
            response_data = r.json()
            is_processed = response_data.get('processed', False)
            logger.info(f"[{check_id}] File '{file_name}' processed status: {is_processed}")
            return response_data
        else:
            logger.error(f"[{check_id}] API error ({r.status_code}) checking file status for '{file_name}': {r.text}")
            return jsonify({"processed": False, "error": f"API error: {r.status_code}"})
    except requests.Timeout:
        logger.error(f"[{check_id}] Timeout checking file status for '{file_name}'")
        return jsonify({"processed": False, "error": "API timeout"})
    except Exception as e:
        logger.error(f"[{check_id}] Error checking file status for '{file_name}': {str(e)}", exc_info=True)
        return jsonify({"processed": False, "error": str(e)})

# Helper functions
def fetch_model_options():
    """Fetch model options from FastAPI backend."""
    try:
        response = requests.get(f"{API_BASE}/model_options", timeout=5)
        response.raise_for_status()
        
        models = response.json()
        logger.info(f"Fetched model options from API: {models}")
        
        if not models:
            logger.warning("API returned empty list of models")
        
        return models
    except Exception as e:
        logger.error(f"Failed to fetch model options: {str(e)}")
        return []

def handle_file_upload(file):
    """Upload a file to the FastAPI backend and check its processing status."""
    try:
        # Upload file to API
        files = {"file": (file.filename, file.read(), file.content_type)}
        # Add timeout for large file uploads: 10 seconds for connection, 60 seconds for response
        response = requests.post(f"{API_BASE}/upload_file", files=files, timeout=(10, 60))
        
        # Log API response for debugging
        if response.status_code != 200:
            try:
                error_detail = response.json().get("detail", "Unknown error")
                logger.error(f"API returned error for file '{file.filename}': {response.status_code} - {error_detail}")
            except Exception:
                logger.error(f"API returned error for file '{file.filename}': {response.status_code} - {response.text}")
            return "error"
            
        response.raise_for_status()
        logger.info(f"File '{file.filename}' uploaded to API.")
        
        # Check processing status
        processing_status = check_file_processing_status(file.filename)
        return processing_status
    except requests.Timeout:
        logger.error(f"Timeout while uploading file '{file.filename}'")
        return "timeout"
    except Exception as e:
        logger.error(f"Error uploading file '{file.filename}': {str(e)}", exc_info=True)
        return "error"

def check_file_processing_status(file_name, timeout=300, interval=10):
    """Poll `/check_file_processed` until the file is done or the timeout is reached."""
    check_id = f"check_{int(time.time())}"
    
    # Ensure the filename is properly URL encoded for the API request
    try:
        encoded_file_name = urllib.parse.quote(file_name)
        api_url = f"{API_BASE}/check_file_processed/{encoded_file_name}"
        logger.info(f"[{check_id}] Checking file status for '{file_name}' at URL: {api_url}")
        
        # For initial upload, make just one attempt since polling is handled by JavaScript
        # This reduces server load and prevents double-polling
        r = requests.get(api_url, timeout=10)
        
        if r.status_code == 200:
            response_data = r.json()
            processed = response_data.get("processed")
            logger.info(f"[{check_id}] File '{file_name}' processing status: {processed}")
            if processed is True:
                return "processed"
            else:
                # Return "processing" status to indicate file upload was successful
                # but processing is still ongoing - JavaScript will handle polling
                return "processing"
        else:
            logger.error(f"[{check_id}] API returned status code {r.status_code} for file '{file_name}': {r.text}")
            return "error"
    except requests.Timeout:
        logger.error(f"[{check_id}] Timeout checking file status for '{file_name}'")
        return "error"
    except Exception as exc:
        logger.error(f"[{check_id}] Error checking file status for '{file_name}': {str(exc)}", exc_info=True)
        return "error"

def query_document(question, message_history=None, model=None):
    """Query the RAG API with a question and optional chat history."""
    request_start_time = time.time()
    
    try:
        # Make sure we have a list for chat_history, not None
        if message_history is None:
            message_history = []
        
        payload = {
            "question": question, 
            "chat_history": message_history,
            "llm_model": model  # Use the model from the dropdown
        }
        
        # Log request details
        logger.info(f"[RAG_REQUEST] Sending request to API: {API_BASE}/rag_complete")
        logger.info(f"[RAG_PAYLOAD] Model: {model}, Question length: {len(question)} chars, History: {len(message_history)} messages")
        logger.info(f"[RAG_TIMEOUT] Client timeout configured: 90s connect, 300s read (total max: 390s)")

        # Add timeout parameters to prevent worker hanging indefinitely
        # 90 seconds for connection timeout, 300 seconds for read timeout (increased for complex RAG queries)
        response = requests.post(f"{API_BASE}/rag_complete", json=payload, timeout=(90, 300))
        
        request_duration = time.time() - request_start_time
        logger.info(f"[RAG_RESPONSE] Received API response in {request_duration:.2f}s - Status: {response.status_code}")
        
        if response.status_code == 200:
            response_data = response.json()
            # Only log success if we actually have a valid answer
            if response_data and "answer" in response_data and response_data["answer"]:
                answer_length = len(response_data["answer"])
                logger.info(f"[RAG_SUCCESS] Document query successful - Valid response received from API, answer length: {answer_length} chars")
                return response_data
            else:
                logger.error(f"[RAG_ERROR] API returned 200 but no valid answer in response - Response data: {response_data}")
                return None
        else:
            try:
                error_detail = response.json().get("detail", "Unknown error")
            except Exception:
                error_detail = response.text[:200] + "..." if len(response.text) > 200 else response.text
            logger.error(f"[RAG_ERROR] API returned status {response.status_code} after {request_duration:.2f}s: {error_detail}")
            return None
            
    except requests.Timeout as e:
        request_duration = time.time() - request_start_time
        timeout_type = "connection" if request_duration < 35 else "read"
        logger.error(f"[RAG_TIMEOUT] API {timeout_type} timeout after {request_duration:.2f}s when processing question: '{question[:50]}...' - This suggests network or processing delays")
        return None
        
    except requests.ConnectionError as e:
        request_duration = time.time() - request_start_time
        logger.error(f"[RAG_CONNECTION_ERROR] Connection error to API after {request_duration:.2f}s when processing question: '{question[:50]}...' - Error: {str(e)}")
        return None
        
    except requests.RequestException as e:
        request_duration = time.time() - request_start_time
        logger.error(f"[RAG_REQUEST_ERROR] API request failed after {request_duration:.2f}s when processing question: '{question[:50]}...' - {type(e).__name__}: {str(e)}")
        return None
        
    except Exception as e:
        request_duration = time.time() - request_start_time
        logger.error(f"[RAG_EXCEPTION] Unexpected error after {request_duration:.2f}s processing question: '{question[:50]}...' - {type(e).__name__}: {str(e)}", exc_info=True)
        return None

def get_chat_history(slide_window=5):
    """Get the recent chat history for context."""
    rag_messages = session.get('rag_messages', [])
    start_index = max(0, len(rag_messages) - slide_window)
    chat_history = [rag_messages[i]["content"] for i in range(start_index, len(rag_messages))]
    return chat_history

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
