import os
import requests
import time
import urllib.parse
from dotenv import load_dotenv
from utils.logging import logger
from modules.docuclaims.session_manager import DocuClaimsSessionManager

# Load environment variables
load_dotenv()

# DocuClaims session manager instance for services that need it
# NOTE: This should be the same configuration as routes.py for consistency
docuclaims_session = DocuClaimsSessionManager(max_cookie_size=3500, max_chat_messages=8)

# Fixed color for app styling
PRIMARY_COLOR = "#DC2626"  # Main accent color

# API endpoint configuration
API_BASE = os.environ.get("API_BASE_URL")
if not API_BASE:
    raise RuntimeError("Missing required environment variable: API_BASE_URL")

def fetch_model_options():
    """Fetch model options from FastAPI backend."""
    try:
        response = requests.get(f"{API_BASE}/docuclaims/model_options", timeout=5)
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
        response = requests.post(f"{API_BASE}/docuclaims/upload_file", files=files, timeout=(10, 60))
        
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
    """Poll `/docuclaims/check_file_processed` until the file is done or the timeout is reached."""
    check_id = f"check_{int(time.time())}"
    
    # Ensure the filename is properly URL encoded for the API request
    try:
        encoded_file_name = urllib.parse.quote(file_name)
        api_url = f"{API_BASE}/docuclaims/check_file_processed/{encoded_file_name}"
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
        logger.info(f"[RAG_REQUEST] Sending request to API: {API_BASE}/docuclaims/rag_complete")
        logger.info(f"[RAG_PAYLOAD] Model: {model}, Question length: {len(question)} chars, History: {len(message_history)} messages")
        logger.info(f"[RAG_TIMEOUT] Client timeout configured: 90s connect, 300s read (total max: 390s)")

        # Add timeout parameters to prevent worker hanging indefinitely
        # 90 seconds for connection timeout, 300 seconds for read timeout (increased for complex RAG queries)
        response = requests.post(f"{API_BASE}/docuclaims/rag_complete", json=payload, timeout=(90, 300))
        
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
    return docuclaims_session.get_chat_history_for_context(slide_window)