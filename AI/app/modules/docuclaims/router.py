"""
DocuClaims Router Module

This module contains all endpoints related to DocuClaims functionality including:
- Model options retrieval
- RAG (Retrieval-Augmented Generation) completion
- File upload to Snowflake
- File processing status checking

All endpoints are self-contained with inline exception handling.
"""

import os
import time
import shutil
import urllib.parse
from pathlib import Path
from fastapi import APIRouter, HTTPException, UploadFile, File
from app.utils.logging import logger
from app.modules.docuclaims.validators import (
    sanitize_filename, is_allowed_filetype, is_file_size_valid, 
    is_filename_valid, ALLOWED_MIME_TYPES, ALLOWED_EXTENSIONS, MAX_FILE_SIZE_MB
)
from app.utils.database import get_sf_conn
from app.modules.docuclaims.schemas import RAGRequest, RAGResponse, FollowUpRequest, FollowUpResponse
from app.modules.docuclaims.services import build_prompt, get_random_suggestion_questions, generate_followup_questions
from app.modules.docuclaims.config_loader import get_docuclaims_config

# Create the router instance
router = APIRouter()


def get_model_options():
    """Return available model options for docuclaims."""
    config = get_docuclaims_config()
    return config['ai_models']['available_llm_models']


@router.get("/model_options", response_model=list[str])
def model_options():
    """Return available model options for UI."""
    return get_model_options()


@router.get("/example_questions", response_model=list[str])
def example_questions():
    """
    Return 3 random example questions from configuration.
    """
    try:
        questions = get_random_suggestion_questions(count=3)
        logger.info(f"Returning {len(questions)} example questions to client")
        return questions
    except Exception as e:
        logger.error(f"Error in /example_questions endpoint: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail="Failed to retrieve example questions")


@router.post("/rag_complete", response_model=RAGResponse)
def rag_complete(request: RAGRequest) -> RAGResponse:
    """
    Given a question and optional chat_history, construct a prompt that includes:
      1. A summary of the chat history (if any)
      2. The most similar chunks from chunks table
      3. The user's question

    Then send that prompt to Snowflake Cortex via SNOWFLAKE.CORTEX.AI_COMPLETE,
    and return the generated answer as JSON.
    
    Optionally generates follow-up questions if include_followup=true and feature is enabled in config.
    """
    endpoint_start_time = time.time()
    question = request.question.strip()
    chat_history = request.chat_history or []
    llm_model = request.llm_model
    include_followup = request.include_followup
    
    logger.info(f"[RAG_REQUEST] RAG request started - Model: {llm_model}, Question: '{question[:100]}...', Chat history: {len(chat_history)} messages, Include followup: {include_followup}")
    
    if not llm_model:
        logger.error("[RAG_ERROR] Request validation failed - llm_model missing")
        raise HTTPException(status_code=400, detail="`llm_model` must be provided in the request.")

    if not question:
        logger.error("[RAG_ERROR] Request validation failed - question empty or missing")
        raise HTTPException(status_code=400, detail="`question` must be a non-empty string.")

    try:
        # Get database connection
        conn, cur = get_sf_conn()
        
        prompt = build_prompt(question, chat_history, llm_model)
        logger.info("[RAG_PROCESS] Prompt built successfully, starting Snowflake Cortex query execution.")
        
        snowflake_start_time = time.time()
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
            
            followup_questions = None
            config = get_docuclaims_config()
            followup_enabled = config.get('followup_questions_config', {}).get('enable_followup_questions', False)
            
            if include_followup and followup_enabled:
                logger.info("[RAG_FOLLOWUP] Follow-up questions requested and enabled in config")
                try:
                    followup_questions = generate_followup_questions(
                        user_question=question,
                        ai_response=processed_response,
                        conversation_history=chat_history,
                        model=llm_model
                    )
                    if followup_questions:
                        logger.info(f"[RAG_FOLLOWUP] Generated {len(followup_questions)} follow-up questions")
                    else:
                        logger.warning("[RAG_FOLLOWUP] No follow-up questions generated")
                except Exception as followup_error:
                    logger.error(f"[RAG_FOLLOWUP] Error generating follow-up questions: {str(followup_error)}")
            elif include_followup and not followup_enabled:
                logger.info("[RAG_FOLLOWUP] Follow-up questions requested but disabled in config")
            
            response_obj = RAGResponse(answer=processed_response, followup_questions=followup_questions)
            
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


@router.post("/upload_file")
async def upload_file_to_snowflake(file: UploadFile = File(...)):
    """
    Upload a file to Snowflake stage. Checks for duplicates and returns status.
    """
    upload_start_time = time.time()
    upload_id = f"upload_{int(time.time())}"
    
    # Get database connection
    conn, cur = get_sf_conn()
    
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
    
    # Use module-specific temp_uploads directory
    module_upload_folder = os.path.join(os.path.dirname(os.path.abspath(__file__)), "temp_uploads")
    os.makedirs(module_upload_folder, exist_ok=True)
    temp_path = Path(module_upload_folder) / sanitized_filename
    
    logger.info(f"[UPLOAD_PROCESS] [{upload_id}] Filename sanitized: {sanitized_filename}, temp path: {temp_path}")

    # Validate file type (MIME and extension)
    content_type = file.content_type or ""
    extension = os.path.splitext(sanitized_filename)[1]
    if not is_allowed_filetype(content_type, extension):
        logger.warning(f"[UPLOAD_WARNING] [{upload_id}] File type not allowed: {content_type}, {extension}")
        raise HTTPException(status_code=400, detail=f"File type not allowed. Allowed types: {ALLOWED_EXTENSIONS}")

    # Check file size before saving (streamed, so check after save)

    # Build stage path
    docuclaims_config = get_docuclaims_config()
    database = docuclaims_config['snowflake']['database']
    schema = docuclaims_config['snowflake']['schema']
    stage = docuclaims_config['snowflake']['stage']
    qualified_stage = f"{database}.{schema}.{stage}"
    logger.info(f"[UPLOAD_TARGET] [{upload_id}] Target Snowflake stage: {qualified_stage}")

    # Check if file already exists in Snowflake stage
    try:
        logger.info(f"[UPLOAD_CHECK] [{upload_id}] Checking if file already exists in stage...")
        stage_check_start = time.time()
        cur.execute(f"LIST @{qualified_stage}")
        files = cur.fetchall()
        stage_check_duration = time.time() - stage_check_start
        
        existing_filenames = [str(file_info[0]).split('/')[-1] for file_info in files if file_info and len(file_info) > 0]
        logger.info(f"[UPLOAD_CHECK] [{upload_id}] Stage check completed in {stage_check_duration:.2f}s - Found {len(existing_filenames)} existing files")
        
        if sanitized_filename in existing_filenames:
            logger.info(f"[UPLOAD_WARNING] [{upload_id}] File '{sanitized_filename}' already exists in @{qualified_stage}. Upload aborted.")
            raise HTTPException(status_code=409, detail=f"A file named '{sanitized_filename}' has already been uploaded.")

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
        # Close cursor and connection
        try:
            if cur:
                cur.close()
            if conn:
                conn.close()
        except Exception as close_error:
            logger.warning(f"[{upload_id}] Failed to close database connection: {str(close_error)}")


@router.get("/check_file_processed/{file_name}")
def check_file_processed(file_name: str):
    """
    Check if a file has been processed by verifying its presence in the chunks table.
    """
    check_id = f"check_{int(time.time())}"
    
    # Get database connection
    conn, cur = get_sf_conn()
    
    # Handle URL-encoded filenames
    try:
        file_name = urllib.parse.unquote(file_name)
        logger.info(f"[{check_id}] Checking processing status for file: '{file_name}'")
    except Exception as e:
        logger.warning(f"[{check_id}] Error decoding filename '{file_name}': {str(e)}")
        # Continue with the original filename if decoding fails
    
    try:
        # Build stage path
        docuclaims_config = get_docuclaims_config()
        database = docuclaims_config['snowflake']['database']
        schema = docuclaims_config['snowflake']['schema']
        stage = docuclaims_config['snowflake']['stage']
        chunks_table = docuclaims_config['snowflake']['chunks_table']
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
        try:
            if cur:
                cur.close()
            if conn:
                conn.close()
        except Exception as close_error:
            logger.warning(f"[{check_id}] Failed to close database connection: {str(close_error)}")


@router.post("/suggest_followup", response_model=FollowUpResponse)
def suggest_followup(request: FollowUpRequest) -> FollowUpResponse:
    """
    Generate 3 relevant follow-up questions based on conversation context.
    
    This endpoint uses Snowflake Cortex AI to generate contextually relevant
    follow-up questions that help users continue their conversation about
    uploaded documents.
    
    Args:
        request: FollowUpRequest containing user_question, ai_response, 
                conversation_history, session_id, and model
    
    Returns:
        FollowUpResponse with success status and list of 3 follow-up questions
    """
    endpoint_start_time = time.time()
    
    conversation_history = request.conversation_history or []
    session_id = request.session_id or f"followup_{int(time.time())}"
    
    logger.info(f"[FOLLOWUP_ENDPOINT] Request received - Session: {session_id}, Model: {request.model}")
    logger.info(f"[FOLLOWUP_ENDPOINT] User question length: {len(request.user_question)}")
    logger.info(f"[FOLLOWUP_ENDPOINT] AI response length: {len(request.ai_response)}")
    logger.info(f"[FOLLOWUP_ENDPOINT] Conversation history: {len(conversation_history)} messages")
    
    if not request.model:
        logger.error("[FOLLOWUP_ENDPOINT] Validation failed - model is required")
        raise HTTPException(status_code=400, detail="Model parameter is required")
    
    if not request.user_question or not request.user_question.strip():
        logger.error("[FOLLOWUP_ENDPOINT] Validation failed - user_question is empty")
        raise HTTPException(status_code=400, detail="User question is required")
    
    if not request.ai_response or not request.ai_response.strip():
        logger.error("[FOLLOWUP_ENDPOINT] Validation failed - ai_response is empty")
        raise HTTPException(status_code=400, detail="AI response is required")
    
    try:
        questions = generate_followup_questions(
            user_question=request.user_question,
            ai_response=request.ai_response,
            conversation_history=conversation_history,
            model=request.model
        )
        
        total_duration = time.time() - endpoint_start_time
        
        if not questions or len(questions) == 0:
            logger.warning(f"[FOLLOWUP_ENDPOINT] No questions generated after {total_duration:.2f}s")
            return FollowUpResponse(success=False, followup_questions=[])
        
        logger.info(f"[FOLLOWUP_ENDPOINT] Successfully generated {len(questions)} questions in {total_duration:.2f}s")
        return FollowUpResponse(success=True, followup_questions=questions)
        
    except Exception as e:
        total_duration = time.time() - endpoint_start_time
        logger.error(f"[FOLLOWUP_ENDPOINT] Error after {total_duration:.2f}s: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to generate follow-up questions: {str(e)}")
