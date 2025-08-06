from flask import Flask, render_template, request, redirect, url_for, flash, jsonify, session
import os
import requests
import time
from dotenv import load_dotenv
from concurrent.futures import ThreadPoolExecutor, as_completed
from utils_logging import logger
import json

# Load environment variables
load_dotenv()

# Initialize Flask app
app = Flask(__name__)
app.secret_key = os.urandom(24)  # Required for flash messages and sessions
app.config['MAX_CONTENT_LENGTH'] = 200 * 1024 * 1024  # 200MB max upload size

# Fixed color for app styling
PRIMARY_COLOR = "#DC2626"  # Main accent color

# API endpoint configuration
API_BASE = os.environ.get("API_BASE_URL")
if not API_BASE:
    raise RuntimeError("Missing required environment variable: API_BASE_URL")

# No theme customization

@app.route('/favicon.ico')
def favicon():
    return app.send_static_file('favicon.ico')

@app.route('/')
def home():
    logger.info("Home page loaded.")
    return render_template('home.html')

@app.route('/docuclaims')
def docuclaims():
    logger.info("DocuClaims AI page loaded.")
    
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
    
    return render_template(
        'docuclaims.html',
        accent_color=PRIMARY_COLOR,  # Using fixed color
        model_options=model_options,
        selected_model=session.get('selected_model'),
        rag_messages=session.get('rag_messages', []),
        file_uploaded=session.get('file_uploaded', False),
        uploaded_filename=session.get('uploaded_filename'),
        use_chat_history=session.get('use_chat_history', True),
        debug=session.get('debug', False)
    )

@app.route('/clear_chat', methods=['POST'])
def clear_chat():
    session['rag_messages'] = []
    session['rag_warnings'] = []
    return redirect(url_for('docuclaims'))

@app.route('/reset_everything', methods=['POST'])
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
def upload_files():
    logger.info("File upload initiated.")
    
    if 'files[]' not in request.files:
        flash('No file part')
        return redirect(url_for('docuclaims'))
    
    files = request.files.getlist('files[]')
    
    if not files or all(file.filename == '' for file in files):
        flash('No selected files')
        return redirect(url_for('docuclaims'))
    
    # Process each file upload
    file_status = {}
    uploaded_filenames = []
    
    for file in files:
        if file.filename:  # Check if filename is not None
            filename = file.filename
            status = handle_file_upload(file)
            file_status[filename] = status
            
            if status == 'processed':
                uploaded_filenames.append(filename)
    
    # Update session variables
    if uploaded_filenames:
        session['uploaded_filename'] = uploaded_filenames
        session['file_uploaded'] = True
        logger.info(f"Files processed: {uploaded_filenames}")
    
    return jsonify({"file_status": file_status, "uploaded_files": uploaded_filenames})

@app.route('/send_message', methods=['POST'])
def send_message():
    prompt = request.form.get('message')
    
    if not prompt or not prompt.strip():
        return jsonify({"error": "Empty message"})
    
    # Add user message to chat history
    user_message = {"role": "user", "content": prompt}
    rag_messages = session.get('rag_messages', [])
    rag_messages.append(user_message)
    session['rag_messages'] = rag_messages
    
    # Get model directly from form data rather than session
    selected_model = request.form.get('model')
    
    # Fallback to session or default if no model provided in request
    if not selected_model:
        selected_model = session.get('selected_model')
        
        # Final fallback to first available model if no model in session
        if not selected_model:
            selected_model = fetch_model_options()[0] if fetch_model_options() else "default"
            logger.info(f"No model in session or request, using first available: {selected_model}")
    
    try:
        # Get chat history for context
        message_history = get_chat_history() if session.get('use_chat_history', True) else []
        
        # Query document with timeout handling
        response = query_document(prompt, message_history, selected_model)
    except requests.Timeout:
        logger.error("API request timed out during document query")
        response = None
    
    if response and "answer" in response:
        answer_text = (
            response.get("answer", "")
            .replace("\\n", "\n")
            .replace("\n", "\n")
        )
        assistant_response_text = f"**Model used:** `{selected_model}`\n\n{answer_text}"
        logger.info("Assistant response received from API.")
    else:
        assistant_response_text = "Sorry, I encountered an error processing your question. Please try again."
        logger.error("Error in assistant response from API.")
    
    # Add assistant response to chat history
    assistant_message = {"role": "assistant", "content": assistant_response_text}
    rag_messages.append(assistant_message)
    session['rag_messages'] = rag_messages
    
    return jsonify({
        "user_message": user_message,
        "assistant_message": assistant_message
    })

@app.route('/toggle_setting', methods=['POST'])
def toggle_setting():
    setting = request.form.get('setting')
    value = request.form.get('value') == 'true'
    
    if setting in ['use_chat_history', 'debug']:
        session[setting] = value
    
    return jsonify({"success": True})

@app.route('/select_model', methods=['POST'])
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
def check_file_processed_endpoint(file_name):
    try:
        # Use the existing check_file_processing_status function but with shorter timeout
        r = requests.get(f"{API_BASE}/check_file_processed/{file_name}", timeout=5)
        if r.status_code == 200:
            return r.json()
        else:
            return jsonify({"processed": False, "error": "API error"})
    except requests.Timeout:
        logger.error(f"Timeout checking file status for {file_name}")
        return jsonify({"processed": False, "error": "API timeout"})
    except Exception as e:
        logger.error(f"Error checking file status: {str(e)}")
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
        response.raise_for_status()
        logger.info(f"File '{file.filename}' uploaded to API.")
        
        # Check processing status
        processing_status = check_file_processing_status(file.filename)
        return processing_status
    except Exception as e:
        logger.error(f"Error uploading file '{file.filename}': {str(e)}")
        return "error"

def check_file_processing_status(file_name, timeout=300, interval=10):
    """Poll `/check_file_processed` until the file is done or the timeout is reached."""
    deadline = time.time() + timeout
    
    # For initial upload we'll make just one attempt since polling will be handled by JS
    try:
        r = requests.get(f"{API_BASE}/check_file_processed/{file_name}", timeout=5)
        if r.status_code == 200:
            processed = r.json().get("processed")
            if processed is True:
                return "processed"
            else:
                # Return "processing" status to indicate file upload was successful
                # but processing is still ongoing
                return "processing"
        else:
            return "error"
    except Exception as exc:
        logger.error(f"Polling error: {exc}")
        return "error"
    
    # We'll never reach this with the new implementation
    # but keeping it for compatibility
    return "timeout"

def query_document(question, message_history=None, model=None):
    """Query the RAG API with a question and optional chat history."""
    try:
        # Make sure we have a list for chat_history, not None
        if message_history is None:
            message_history = []
        
        payload = {
            "question": question, 
            "chat_history": message_history,
            "llm_model": model  # Use the model from the dropdown
        }
        # Add timeout parameters to prevent worker hanging indefinitely
        # 5 seconds for connection timeout, 30 seconds for read timeout
        response = requests.post(f"{API_BASE}/rag_complete", json=payload, timeout=(5, 30))
        if response.status_code == 200:
            response_data = response.json()
            logger.info("Document query successful.")
            return response_data
        else:
            try:
                error_detail = response.json().get("detail", "Unknown error")
            except Exception:
                error_detail = response.text
            logger.error(f"Error processing question: {error_detail}")
            return None
    except requests.Timeout:
        logger.error(f"API timeout when processing question: '{question[:50]}...'")
        return None
    except Exception as e:
        logger.error(f"Error processing question: {str(e)}")
        return None

def get_chat_history(slide_window=5):
    """Get the recent chat history for context."""
    rag_messages = session.get('rag_messages', [])
    start_index = max(0, len(rag_messages) - slide_window)
    chat_history = [rag_messages[i]["content"] for i in range(start_index, len(rag_messages))]
    return chat_history

if __name__ == "__main__":
    app.run(debug=True, host='127.0.0.1', port=5001)
