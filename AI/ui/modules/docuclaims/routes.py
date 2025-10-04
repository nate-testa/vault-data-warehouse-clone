from flask import Blueprint, render_template, request, redirect, url_for, jsonify
import time
import os
import requests
import urllib.parse
from dotenv import load_dotenv
from auth.decorators import login_required, require_app_access
from auth.session_manager import SessionManager
from modules.docuclaims.session_manager import DocuClaimsSessionManager
from utils.logging import logger
from modules.docuclaims.services import (
    fetch_model_options,
    handle_file_upload,
    query_document,
    check_file_processing_status,
    get_chat_history,
    PRIMARY_COLOR,
    API_BASE
)

# Load environment variables (required for routes that may access env vars directly)
load_dotenv()

# Create Blueprint with template folder specification
docuclaims_bp = Blueprint('docuclaims', __name__, template_folder='templates')

# Initialize auth and session managers (same configuration as main app)
session_manager = SessionManager()
ui_session = DocuClaimsSessionManager(max_cookie_size=3500, max_chat_messages=8)


@docuclaims_bp.route('/docuclaims')
@login_required  # Add authentication protection
@require_app_access('DocuClaims AI')  # Add application-level access control
def docuclaims():
    # Get user IP for tracking
    client_ip = request.environ.get('HTTP_X_FORWARDED_FOR', request.environ.get('REMOTE_ADDR', 'unknown'))
    if ',' in client_ip:
        client_ip = client_ip.split(',')[0].strip()
    
    logger.info(f"DocuClaims AI page accessed by IP: {client_ip}")
    
    # Initialize DocuClaims session variables using DocuClaimsSessionManager
    ui_session.initialize_docuclaims_session()
    
    # Perform proactive session cleanup to prevent cookie overflow (inherited method)
    ui_session.cleanup_generic_session_storage()
        
    # Fetch model options from API
    model_options = fetch_model_options()
    
    # Log if no model options are available
    if not model_options:
        logger.error("No model options returned from API")
    
    # Only set a selected model if there are valid options and the current selection is invalid
    current_model = ui_session.get_docuclaims_preference('selected_model')
    if model_options and (not current_model or current_model not in model_options):
        ui_session.set_docuclaims_preference('selected_model', model_options[0])
    elif not model_options:
        # If no options are available, clear any existing selection
        ui_session.set_docuclaims_preference('selected_model', None)
    
    # Get current user for template context
    user = session_manager.get_current_user()
    
    # Get UI data through UISessionManager
    file_status = ui_session.get_file_upload_status()
    
    return render_template(
        'docuclaims.html',
        accent_color=PRIMARY_COLOR,  # Using fixed color
        model_options=model_options,
        selected_model=ui_session.get_docuclaims_preference('selected_model'),
        rag_messages=ui_session.get_chat_messages(),
        file_uploaded=file_status['uploaded'],
        uploaded_filename=file_status['filenames'],
        use_chat_history=ui_session.get_docuclaims_preference('use_chat_history', True),
        debug=ui_session.get_generic_preference('debug', False),
        user=user
    )


@docuclaims_bp.route('/clear_chat', methods=['POST'])
@login_required
@require_app_access('DocuClaims AI')
def clear_chat():
    ui_session.clear_chat_messages()
    return redirect(url_for('docuclaims.docuclaims'))


@docuclaims_bp.route('/reset_everything', methods=['POST'])
@login_required
@require_app_access('DocuClaims AI')
def reset_everything():
    # Reset all DocuClaims session data
    ui_session.reset_all_docuclaims_data()
    return redirect(url_for('docuclaims.docuclaims'))


@docuclaims_bp.route('/upload_files', methods=['POST'])
@login_required
@require_app_access('DocuClaims AI')
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
    
    # Update session variables using UISessionManager
    if uploaded_filenames:
        ui_session.set_file_upload_status(True, uploaded_filenames)
        logger.info(f"[{upload_id}] Files processed successfully: {uploaded_filenames}")
    else:
        logger.warning(f"[{upload_id}] No files were processed successfully. Status: {file_status}")
    
    return jsonify({"file_status": file_status, "uploaded_files": uploaded_filenames})


@docuclaims_bp.route('/send_message', methods=['POST'])
@login_required
@require_app_access('DocuClaims AI')
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
        selected_model = ui_session.get_docuclaims_preference('selected_model')
        
        # Final fallback to first available model if no model in session
        if not selected_model:
            selected_model = fetch_model_options()[0] if fetch_model_options() else "default"
            logger.info(f"[{interaction_id}] No model in session or request, using first available: {selected_model}")
    
    logger.info(f"[{interaction_id}] Using LLM model: {selected_model}")
    
    try:
        # Get chat history for context BEFORE adding the current message
        use_history = ui_session.get_docuclaims_preference('use_chat_history', True)
        message_history = ui_session.get_chat_history_for_context() if use_history else []
        chat_context_length = len(message_history)
        logger.info(f"[{interaction_id}] Chat history context: {chat_context_length} previous messages")
        logger.info(f"[{interaction_id}] [RAG_START] Starting API query process...")
        
        # Add user message to chat history using DocuClaimsSessionManager
        ui_session.add_chat_message(user_message)
        
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
    
    # Add assistant response to chat history using UISessionManager
    assistant_message = {"role": "assistant", "content": assistant_response_text}
    ui_session.add_chat_message(assistant_message)
    
    total_time = time.time() - start_time
    logger.info(f"[{interaction_id}] Total interaction completed in {total_time:.2f}s")
    
    return jsonify({
        "user_message": user_message,
        "assistant_message": assistant_message
    })


@docuclaims_bp.route('/toggle_setting', methods=['POST'])
@login_required
@require_app_access('DocuClaims AI')
def toggle_setting():
    setting = request.form.get('setting')
    value = request.form.get('value') == 'true'
    
    if setting == 'use_chat_history':
        ui_session.set_docuclaims_preference(setting, value)
    elif setting == 'debug':
        ui_session.set_generic_preference(setting, value)
    
    return jsonify({"success": True})


@docuclaims_bp.route('/select_model', methods=['POST'])
@login_required
@require_app_access('DocuClaims AI')
def select_model():
    model = request.form.get('model')
    if model:
        ui_session.set_docuclaims_preference('selected_model', model)
        logger.info(f"Model selected: {model}")
    else:
        logger.error("Attempt to select model but no model provided")
        return jsonify({"success": False, "error": "No model provided"})
    
    return jsonify({"success": True, "model": model})


@docuclaims_bp.route('/check_file_processed/<file_name>')
@login_required
@require_app_access('DocuClaims AI')
def check_file_processed_endpoint(file_name):
    check_id = f"check_{int(time.time())}"
    logger.info(f"[{check_id}] Checking processing status for file: '{file_name}'")
    try:
        # Ensure the filename is properly URL encoded for the API request
        encoded_file_name = urllib.parse.quote(file_name)
        api_url = f"{API_BASE}/docuclaims/check_file_processed/{encoded_file_name}"
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