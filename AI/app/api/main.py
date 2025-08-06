import os
import time
import shutil
from pathlib import Path
from datetime import datetime
from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException, Depends, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from app.utils.logging import logger
from app.utils.tools import get_model_options
from app.utils.file_validators import sanitize_filename, is_allowed_filetype, is_file_size_valid, ALLOWED_MIME_TYPES, ALLOWED_EXTENSIONS, MAX_FILE_SIZE_MB
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
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Replace "*" with specific origins for better security
    allow_credentials=True,
    allow_methods=["*"],  # Allow all HTTP methods
    allow_headers=["*"],  # Allow all headers
)

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

    question = request.question.strip()
    chat_history = request.chat_history or []
    llm_model = request.llm_model
    logger.info(f"Received request for LLM model: {llm_model}, question: {question}, chat history length: {len(chat_history)}")
    if not llm_model:
        raise HTTPException(status_code=400, detail="`llm_model` must be provided in the request.")

    if not question:
        raise HTTPException(status_code=400, detail="`question` must be a non-empty string.")

    try:
        prompt = build_prompt(question, chat_history, llm_model)
        cur = conn.cursor()
        sql = """
            SELECT SNOWFLAKE.CORTEX.AI_COMPLETE(%s, %s) AS response
        """
        try:
            cur.execute(sql, (llm_model, prompt))
            row = cur.fetchone()
        finally:
            cur.close()
            conn.close()

        if not row or not row[0]:
            raise HTTPException(status_code=500, detail="No response returned from Snowflake Cortex.")
        return RAGResponse(answer=row[0].replace("'", "").replace('"', ''))
    except Exception as e:
        logger.error(f"Error in /rag_complete: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error.")


@app.post("/upload_file")
async def upload_file_to_snowflake(file: UploadFile = File(...), config=Depends(get_config_dep), conn=Depends(get_sf_conn_dep)):
    """
    Upload a file to Snowflake stage. Checks for duplicates and returns status.
    """
    upload_id = f"upload_{int(time.time())}"
    if file.filename is None:
        raise HTTPException(status_code=400, detail="Filename cannot be None")
    sanitized_filename = sanitize_filename(file.filename)
    temp_path = Path(config["UPLOAD_FOLDER"]) / sanitized_filename
    logger.info(f"[{upload_id}] Received file: {sanitized_filename}")

    # Validate file type (MIME and extension)
    content_type = file.content_type or ""
    extension = os.path.splitext(sanitized_filename)[1]
    if not is_allowed_filetype(content_type, extension):
        logger.warning(f"[{upload_id}] File type not allowed: {content_type}, {extension}")
        raise HTTPException(status_code=400, detail=f"File type not allowed. Allowed types: {ALLOWED_EXTENSIONS}")

    # Check file size before saving (streamed, so check after save)

    # Build stage path
    database = config["SF_DATABASE"]
    schema = config["SF_SCHEMA"]
    stage = config["SF_STAGE"]
    qualified_stage = f"{database}.{schema}.{stage}"

    # Check if file already exists in Snowflake stage
    cur = None
    try:
        cur = conn.cursor()
        cur.execute(f"LIST @{qualified_stage}")
        files = cur.fetchall()
        existing_filenames = [str(file_info[0]).split('/')[-1] for file_info in files if file_info and len(file_info) > 0]
        if sanitized_filename in existing_filenames:
            logger.info(f"[{upload_id}] File '{sanitized_filename}' already exists in @{qualified_stage}. Upload aborted.")
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
        cur.execute(query, (file_name,))
        result = cur.fetchone()
        if result and result[0] > 0:
            return {"processed": True, "message": f"File '{file_name}' has been processed."}
        else:
            return {"processed": False, "message": f"File '{file_name}' has not been processed yet."}
    except Exception as e:
        logger.error(f"Error checking file processing status: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail="Error checking file processing status.")
    finally:
        if cur:
            cur.close()
        conn.close()
