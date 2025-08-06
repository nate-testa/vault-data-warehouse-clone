import os
import time
import shutil
import urllib.parse
from pathlib import Path
from datetime import datetime
from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException, Depends, UploadFile, File, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from app.utils.logging import logger
from app.utils.tools import get_model_options
from app.utils.file_validators import sanitize_filename, is_allowed_filetype, is_file_size_valid, is_filename_valid, ALLOWED_MIME_TYPES, ALLOWED_EXTENSIONS, MAX_FILE_SIZE_MB
from app.config import get_config
from app.schemas.rag import RAGRequest, RAGResponse
from app.services.rag_service import build_prompt
from app.services.snowflake_service import get_sf_conn


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("=" * 50)
    logger.info(f"Cortex API server starting up on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    config = get_config()
    logger.info(f"Snowflake connection initialized, using Snowflake account: {config['SF_ACCOUNT']}")
    logger.info("=" * 50)
    yield
    logger.info("=" * 50)
    logger.info(f"Cortex API server shutting down at {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    logger.info("=" * 50)

app = FastAPI(lifespan=lifespan)

# Configure CORS
# Get allowed origins from environment or use defaults
CORS_ORIGINS = os.environ.get("CORS_ORIGINS", "http://localhost:5001,https://ai.vaultinsurance.com").split(",")
logger.info(f"Configuring CORS with allowed origins: {CORS_ORIGINS}")

app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS,  # Use specific origins for better security
    allow_credentials=True,
    allow_methods=["*"],  # Allow all HTTP methods
    allow_headers=["*"],  # Allow all headers
)

# Custom middleware to log request timing and detect client disconnections
@app.middleware("http")
async def request_timing_middleware(request: Request, call_next):
    """
    Middleware to log request timing and detect client disconnections.
    """
    start_time = time.time()
    client_ip = request.client.host if request.client else "unknown"
    method = request.method
    path = request.url.path
    
    # Generate a unique request ID for this request
    request_id = f"req_{int(start_time * 1000)}"
    logger.info(f"[REQUEST_START] [{request_id}] Request started - {method} {path} from {client_ip}")
    
    try:
        response = await call_next(request)
        duration = time.time() - start_time
        status_code = response.status_code
        
        if status_code >= 400:
            logger.warning(f"[REQUEST_ERROR] [{request_id}] Request completed with error - {method} {path} - {status_code} in {duration:.2f}s")
        else:
            logger.info(f"[REQUEST_SUCCESS] [{request_id}] Request completed successfully - {method} {path} - {status_code} in {duration:.2f}s")
        
        return response
        
    except Exception as e:
        duration = time.time() - start_time
        logger.error(f"[REQUEST_EXCEPTION] [{request_id}] Request failed with exception - {method} {path} after {duration:.2f}s: {str(e)}", exc_info=True)
        # Re-raise the exception so FastAPI can handle it appropriately
        raise

# Routers and endpoints should be added here

def get_config_dep():
    """Dependency provider for config."""
    return get_config()


def get_sf_conn_dep(config=Depends(get_config_dep)):
    """Dependency provider for Snowflake connection."""
    return get_sf_conn(config)


@app.get("/model_options", response_model=list[str])
def model_options():
    """Return available model options for UI."""
    return get_model_options()


@app.post("/rag_complete", response_model=RAGResponse)
def rag_complete(request: RAGRequest, config=Depends(get_config_dep), conn=Depends(get_sf_conn_dep)) -> RAGResponse:
    """
    Given a question and optional chat_history, construct a prompt that includes:
      1. A summary of the chat history (if any)
      2. The most similar chunks from chunks table
      3. The user's question

    Then send that prompt to Snowflake Cortex via SNOWFLAKE.CORTEX.AI_COMPLETE,
    and return the generated answer as JSON.
    """
    endpoint_start_time = time.time()
    question = request.question.strip()
    chat_history = request.chat_history or []
    llm_model = request.llm_model
    
    logger.info(f"[RAG_REQUEST] RAG request started - Model: {llm_model}, Question: '{question[:100]}...', Chat history: {len(chat_history)} messages")
    
    if not llm_model:
        logger.error("[RAG_ERROR] Request validation failed - llm_model missing")
        raise HTTPException(status_code=400, detail="`llm_model` must be provided in the request.")

    if not question:
        logger.error("[RAG_ERROR] Request validation failed - question empty or missing")
        raise HTTPException(status_code=400, detail="`question` must be a non-empty string.")

    try:
        prompt = build_prompt(question, chat_history, llm_model)
        logger.info("[RAG_PROCESS] Prompt built successfully, starting Snowflake Cortex query execution.")
        
        snowflake_start_time = time.time()
        cur = conn.cursor()
        sql = """
            SELECT SNOWFLAKE.CORTEX.AI_COMPLETE(%s, %s) AS response
        """
        try:
            logger.info("[RAG_SNOWFLAKE] Executing SNOWFLAKE.CORTEX.AI_COMPLETE query...")
            cur.execute(sql, (llm_model, prompt))
            row = cur.fetchone()
            snowflake_duration = time.time() - snowflake_start_time
            logger.info(f"[RAG_SNOWFLAKE] Snowflake query completed in {snowflake_duration:.2f}s, processing response...")
        finally:
            cur.close()
            conn.close()
            logger.info("[RAG_PROCESS] Database connection closed.")

        if not row or not row[0]:
            logger.error("[RAG_ERROR] Empty response from Snowflake Cortex - no data returned")
            raise HTTPException(status_code=500, detail="No response returned from Snowflake Cortex.")
        
        # Log response details for debugging
        raw_response = row[0]
        response_length = len(raw_response) if raw_response else 0
        logger.info(f"[RAG_RESPONSE] Raw response received from Snowflake Cortex - Length: {response_length} characters")
        
        # Process the response more carefully - only remove leading/trailing quotes if they exist
        try:
            processed_response = raw_response.strip()
            # Only remove quotes if the entire string is wrapped in them
            if processed_response.startswith('"') and processed_response.endswith('"'):
                processed_response = processed_response[1:-1]
            elif processed_response.startswith("'") and processed_response.endswith("'"):
                processed_response = processed_response[1:-1]
                
            logger.info("[RAG_PROCESS] Response processed successfully, creating RAGResponse object...")
            response_obj = RAGResponse(answer=processed_response)
            
            total_duration = time.time() - endpoint_start_time
            logger.info(f"[RAG_SUCCESS] RAGResponse object created successfully - Total request duration: {total_duration:.2f}s")
            logger.info("[RAG_RESPONSE] Sending response to client...")
            
            return response_obj
            
        except Exception as response_error:
            logger.error(f"[RAG_ERROR] Error processing Snowflake response: {str(response_error)}")
            logger.error(f"[RAG_DEBUG] Raw response preview (first 200 chars): {raw_response[:200] if raw_response else 'None'}")
            raise HTTPException(status_code=500, detail="Error processing AI response.")
            
    except HTTPException as http_exc:
        total_duration = time.time() - endpoint_start_time
        logger.error(f"[RAG_HTTP_ERROR] HTTP exception after {total_duration:.2f}s: {http_exc.status_code} - {http_exc.detail}")
        # Re-raise HTTP exceptions as-is
        raise
        
    except Exception as e:
        total_duration = time.time() - endpoint_start_time
        logger.error(f"[RAG_EXCEPTION] Unexpected error in /rag_complete after {total_duration:.2f}s: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail="Internal server error.")


@app.post("/upload_file")
async def upload_file_to_snowflake(file: UploadFile = File(...), config=Depends(get_config_dep), conn=Depends(get_sf_conn_dep)):
    """
    Upload a file to Snowflake stage. Checks for duplicates and returns status.
    """
    upload_start_time = time.time()
    upload_id = f"upload_{int(time.time())}"
    
    logger.info(f"[UPLOAD_REQUEST] File upload started - ID: {upload_id}, Filename: {file.filename}, Content-Type: {file.content_type}")
    
    if file.filename is None:
        logger.error(f"[UPLOAD_ERROR] [{upload_id}] Upload failed - filename is None")
        raise HTTPException(status_code=400, detail="Filename cannot be None")
        
    # Check if the filename contains only allowed characters
    if not is_filename_valid(file.filename):
        logger.warning(f"[UPLOAD_WARNING] [{upload_id}] Invalid filename format: {file.filename}")
        raise HTTPException(
            status_code=400, 
            detail="Invalid filename. Only alphanumeric characters, dots, underscores, and hyphens are allowed."
        )
    
    # Only remove path traversal, keep original filename
    sanitized_filename = sanitize_filename(file.filename)
    temp_path = Path(config["UPLOAD_FOLDER"]) / sanitized_filename
    logger.info(f"[UPLOAD_PROCESS] [{upload_id}] Filename sanitized: {sanitized_filename}, temp path: {temp_path}")

    # Validate file type (MIME and extension)
    content_type = file.content_type or ""
    extension = os.path.splitext(sanitized_filename)[1]
    if not is_allowed_filetype(content_type, extension):
        logger.warning(f"[UPLOAD_WARNING] [{upload_id}] File type not allowed: {content_type}, {extension}")
        raise HTTPException(status_code=400, detail=f"File type not allowed. Allowed types: {ALLOWED_EXTENSIONS}")

    # Check file size before saving (streamed, so check after save)

    # Build stage path
    database = config["SF_DATABASE"]
    schema = config["SF_SCHEMA"]
    stage = config["SF_STAGE"]
    qualified_stage = f"{database}.{schema}.{stage}"
    logger.info(f"[UPLOAD_TARGET] [{upload_id}] Target Snowflake stage: {qualified_stage}")

    # Check if file already exists in Snowflake stage
    cur = None
    try:
        logger.info(f"[UPLOAD_CHECK] [{upload_id}] Checking if file already exists in stage...")
        stage_check_start = time.time()
        cur = conn.cursor()
        cur.execute(f"LIST @{qualified_stage}")
        files = cur.fetchall()
        stage_check_duration = time.time() - stage_check_start
        
        existing_filenames = [str(file_info[0]).split('/')[-1] for file_info in files if file_info and len(file_info) > 0]
        logger.info(f"[UPLOAD_CHECK] [{upload_id}] Stage check completed in {stage_check_duration:.2f}s - Found {len(existing_filenames)} existing files")
        
        if sanitized_filename in existing_filenames:
            logger.info(f"[UPLOAD_WARNING] [{upload_id}] File '{sanitized_filename}' already exists in @{qualified_stage}. Upload aborted.")
            raise HTTPException(status_code=409, detail=f"A file named '{sanitized_filename}' has already been uploaded.")
    finally:
        if cur:
            cur.close()

    cur = None
    try:
        # Save file temporarily
        with open(temp_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        logger.info(f"[{upload_id}] File saved to temporary path.")

        # Validate file size after save
        file_size = os.path.getsize(temp_path)
        if not is_file_size_valid(file_size):
            logger.warning(f"[{upload_id}] File size exceeds limit: {file_size / (1024 * 1024):.2f} MB")
            os.remove(temp_path)
            raise HTTPException(status_code=400, detail=f"File size exceeds {MAX_FILE_SIZE_MB} MB limit.")

        # Upload to Snowflake
        cur = conn.cursor()
        logger.info(f"[{upload_id}] Uploading file to @{qualified_stage}")
        logger.info(f"[{upload_id}] File size: {file_size / (1024 * 1024):.2f} MB")
        file_path_str = str(temp_path)
        file_path_quoted = file_path_str.replace("'", "''")
        put_sql = f"PUT 'file://{file_path_quoted}' @{qualified_stage} AUTO_COMPRESS=FALSE OVERWRITE=FALSE"
        logger.info(f"[{upload_id}] Executing file upload command.")
        cur.execute(put_sql)
        result = cur.fetchall()
        logger.info(f"[{upload_id}] Upload result: {result}")
        success = False
        message = f"File '{sanitized_filename}' uploaded to @{qualified_stage}."
        if result and len(result) > 0:
            status = None
            for row in result:
                if len(row) >= 2:
                    status = row[1]
                    logger.info(f"[{upload_id}] File status: {status}")
            if status and status.upper() in ('UPLOADED', 'SKIPPED'):
                success = True
                if status.upper() == 'SKIPPED':
                    message = f"File '{sanitized_filename}' already exists in @{qualified_stage} (skipped)."
            else:
                message = f"File upload status: {status if status else 'unknown'}"
        return {
            "message": message,
            "success": success,
            "upload_result": result
        }
    except Exception as e:
        logger.error(f"[{upload_id}] Upload failed: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to upload file: {str(e)}")
    finally:
        file.file.close()
        try:
            if os.path.exists(temp_path):
                os.remove(temp_path)
                logger.info(f"[{upload_id}] Temporary file removed.")
        except Exception as cleanup_error:
            logger.warning(f"[{upload_id}] Failed to remove temporary file: {str(cleanup_error)}")
        if cur:
            cur.close()
        conn.close()


@app.get("/check_file_processed/{file_name}")
def check_file_processed(file_name: str, config=Depends(get_config_dep), conn=Depends(get_sf_conn_dep)):
    """
    Check if a file has been processed by verifying its presence in the chunks table.
    """
    check_id = f"check_{int(time.time())}"
    # Handle URL-encoded filenames
    try:
        file_name = urllib.parse.unquote(file_name)
        logger.info(f"[{check_id}] Checking processing status for file: '{file_name}'")
    except Exception as e:
        logger.warning(f"[{check_id}] Error decoding filename '{file_name}': {str(e)}")
        # Continue with the original filename if decoding fails
    
    cur = None
    try:
        cur = conn.cursor()

        # Build stage path
        database = config["SF_DATABASE"]
        schema = config["SF_SCHEMA"]
        stage = config["SF_STAGE"]
        chunks_table = config["SF_CHUNKS_TABLE"]
        qualified_stage = f"{database}.{schema}.{stage}"

        # Refresh the stage to ensure the latest files are available
        refresh_stage_query = f"ALTER STAGE {qualified_stage} REFRESH;"
        cur.execute(refresh_stage_query)
        chunks_table = f"{database}.{schema}.{chunks_table}"
        query = f"""
            SELECT COUNT(*)
            FROM {chunks_table}
            WHERE RELATIVE_PATH = %s
        """
        
        logger.info(f"[{check_id}] Executing query with RELATIVE_PATH = '{file_name}'")
        cur.execute(query, (file_name,))
        result = cur.fetchone()
        
        if result and result[0] > 0:
            logger.info(f"[{check_id}] File '{file_name}' has been processed.")
            return {"processed": True, "message": f"File '{file_name}' has been processed."}
        else:
            logger.info(f"[{check_id}] File '{file_name}' has not been processed yet.")
            return {"processed": False, "message": f"File '{file_name}' has not been processed yet."}
    except Exception as e:
        logger.error(f"[{check_id}] Error checking processing status for '{file_name}': {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Error checking file processing status: {str(e)}")
    finally:
        if cur:
            cur.close()
        conn.close()
