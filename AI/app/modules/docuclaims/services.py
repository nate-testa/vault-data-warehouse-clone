"""
DocuClaims Services Module

This module contains all business logic for DocuClaims functionality including:
- RAG (Retrieval-Augmented Generation) operations
- Snowflake database connections and queries
- Chat history processing and prompt building
- Follow-up question generation
"""

import json
import random
import re
from app.utils.logging import logger
from app.utils.database import get_sf_conn
from app.modules.docuclaims.config_loader import get_docuclaims_config

def get_similar_chunks(question: str) -> str:
    """
    Query Snowflake via sf_conn to retrieve the top NUM_CHUNKS most similar
    chunks (by cosine similarity) from chunks table, given a question.
    Concatenate their text and return it as a single string.
    """
    import time
    start_time = time.time()
    
    conn, cur = get_sf_conn()
    
    # Get DocuClaims local configuration
    docuclaims_config = get_docuclaims_config()
    warehouse = docuclaims_config['snowflake']['warehouse']
    database = docuclaims_config['snowflake']['database']
    schema = docuclaims_config['snowflake']['schema']
    chunks_table = docuclaims_config['snowflake']['chunks_table']
    embedding_model = docuclaims_config['ai_models']['embedding_model']
    num_chunks = docuclaims_config['search_config']['num_chunks']
    
    chunks_databe_schema_table = f"{database}.{schema}.{chunks_table}"


    sql = f"""
        WITH results AS (
          SELECT
            RELATIVE_PATH AS FILE_NAME,
            VECTOR_COSINE_SIMILARITY(
              {chunks_table}.chunk_vec,
              SNOWFLAKE.CORTEX.EMBED_TEXT_1024(%s, %s)
            ) AS similarity,
            chunk
          FROM {chunks_databe_schema_table}
          ORDER BY similarity DESC
          LIMIT %s
        )
        SELECT chunk, FILE_NAME FROM results
    """
    try:
        logger.info(f"Executing legacy vector similarity search for question: {question}")
        logger.info(f"Target table: {chunks_databe_schema_table}")
        logger.info(f"Embedding model: {embedding_model}")
        logger.info(f"Chunk limit: {num_chunks}")
        
        cur.execute(sql, (embedding_model, question, num_chunks))
        df_chunks = cur.fetch_pandas_all()
        
        execution_time = time.time() - start_time
        logger.info(f"Legacy vector similarity search executed in {execution_time:.2f}s")
        
        # Validate result
        if df_chunks is None or df_chunks.empty:
            logger.warning("No chunks returned from legacy vector similarity search")
            logger.warning(f"Table: {chunks_databe_schema_table}, Model: {embedding_model}")
        
    except Exception as e:
        execution_time = time.time() - start_time
        error_message = str(e).lower()
        
        # Enhanced error handling for legacy method
        if "does not exist" in error_message or "not found" in error_message:
            if chunks_table in error_message:
                logger.error(f"Chunks table not found after {execution_time:.2f}s")
                logger.error(f"Table: {chunks_databe_schema_table}")
                logger.error(f"Verify that the chunks table exists and is accessible")
                raise RuntimeError(f"Chunks table '{chunks_databe_schema_table}' not found. Please verify table configuration.")
            else:
                logger.error(f"Database object not found after {execution_time:.2f}s: {str(e)}")
                raise RuntimeError(f"Database object not found: {str(e)}")
                
        elif "permission" in error_message or "access" in error_message or "unauthorized" in error_message:
            logger.error(f"Access denied to chunks table after {execution_time:.2f}s")
            logger.error(f"Table: {chunks_databe_schema_table}")
            logger.error(f"Current role/user may not have access to the table")
            raise RuntimeError(f"Access denied to chunks table '{chunks_databe_schema_table}'. Check user permissions and role configuration.")
            
        elif "timeout" in error_message or execution_time > 60:
            logger.error(f"Vector similarity query timeout after {execution_time:.2f}s")
            logger.error(f"Table: {chunks_databe_schema_table}")
            logger.error(f"Consider optimizing the query or reducing the chunk limit")
            raise RuntimeError(f"Vector similarity query timed out after {execution_time:.2f}s. Consider reducing chunk limit.")
            
        elif "cortex" in error_message and ("embed" in error_message or "model" in error_message):
            logger.error(f"Embedding model error after {execution_time:.2f}s")
            logger.error(f"Model: {embedding_model}")
            logger.error(f"The embedding model may not be available or supported")
            raise RuntimeError(f"Embedding model '{embedding_model}' error: {str(e)}")
            
        elif "memory" in error_message or "resource" in error_message:
            logger.error(f"Resource/memory error after {execution_time:.2f}s")
            logger.error(f"Table: {chunks_databe_schema_table}, Limit: {num_chunks}")
            logger.error(f"Consider reducing the chunk limit or optimizing the query")
            raise RuntimeError(f"Resource constraint in vector similarity search. Consider reducing chunk limit from {num_chunks}.")
            
        else:
            # Generic database error
            logger.error(f"Unexpected legacy vector similarity error after {execution_time:.2f}s")
            logger.error(f"Table: {chunks_databe_schema_table}")
            logger.error(f"Model: {embedding_model}")
            logger.error(f"Limit: {num_chunks}")
            logger.error(f"Original error: {str(e)}")
            logger.error(f"Error type: {type(e).__name__}")
            raise RuntimeError(f"Legacy vector similarity search error: {str(e)}")
            
    finally:
        try:
            cur.close()
            conn.close()
        except Exception as close_error:
            logger.warning(f"Failed to close database connection: {str(close_error)}")

    context_parts = []
    for index, row in df_chunks.iterrows():
        chunk_text = row['CHUNK']
        file_name = row['FILE_NAME']
        context_parts.append(f"[SOURCE: {file_name}]\n{chunk_text}")

    chunk_count = len(context_parts)
    final_result = "\n\n".join(context_parts)
    logger.info(f"Legacy vector similarity method completed, returned {chunk_count} processed chunks")
    
    return final_result


def get_similar_chunks_cortex(question: str) -> str:
    """
    Query Snowflake Cortex Search Service to retrieve the most similar chunks
    for a given question. Uses SNOWFLAKE.CORTEX.SEARCH_PREVIEW function.
    Maintains identical function signature and return format as get_similar_chunks().
    """
    import time
    start_time = time.time()
    
    conn, cur = get_sf_conn()
    
    # Get DocuClaims local configuration
    docuclaims_config = get_docuclaims_config()
    warehouse = docuclaims_config['snowflake']['warehouse']
    database = docuclaims_config['snowflake']['database']
    schema = docuclaims_config['snowflake']['schema']
    num_chunks = docuclaims_config['search_config']['num_chunks']
    cortex_search_service = docuclaims_config['ai_models']['cortex_search_service']
    
    # Construct query payload for Cortex Search
    search_payload = {
        "query": question,
        "columns": ["CHUNK", "RELATIVE_PATH"],
        "limit": num_chunks
    }
    
    sql = """
        SELECT SNOWFLAKE.CORTEX.SEARCH_PREVIEW(%s, %s) AS search_result
    """
    
    try:
        logger.info(f"Executing Cortex Search for question: {question}")
        logger.info(f"Using service: {cortex_search_service}")
        logger.info(f"Search payload: {json.dumps(search_payload, indent=2)}")
        
        cur.execute(sql, (cortex_search_service, json.dumps(search_payload)))
        result = cur.fetchone()
        
        if not result or not result[0]:
            logger.warning("No results returned from Cortex Search Service")
            logger.warning(f"Service: {cortex_search_service}, Payload: {search_payload}")
            return ""
            
        # Parse the JSON response
        search_results = json.loads(result[0])
        
        execution_time = time.time() - start_time
        logger.info(f"Cortex Search executed in {execution_time:.2f}s")
        
    except Exception as e:
        execution_time = time.time() - start_time
        error_message = str(e).lower()
        
        # Enhanced error handling with specific Cortex Search scenarios
        if "search service" in error_message and ("not found" in error_message or "does not exist" in error_message):
            logger.error(f"Cortex Search Service not found after {execution_time:.2f}s")
            logger.error(f"Service name: {cortex_search_service}")
            logger.error(f"Verify that the search service exists and is properly configured")
            raise RuntimeError(f"Cortex Search Service '{cortex_search_service}' not found. Please verify service configuration.")
            
        elif "suspended" in error_message or "indexing" in error_message:
            logger.error(f"Cortex Search Service suspended/indexing after {execution_time:.2f}s")
            logger.error(f"Service: {cortex_search_service}")
            logger.error(f"The service may be temporarily unavailable due to indexing or maintenance")
            raise RuntimeError(f"Cortex Search Service '{cortex_search_service}' is temporarily suspended or being indexed. Please try again later.")
            
        elif "timeout" in error_message or execution_time > 30:
            logger.error(f"Cortex Search query timeout after {execution_time:.2f}s")
            logger.error(f"Service: {cortex_search_service}")
            logger.error(f"Query payload: {json.dumps(search_payload)}")
            logger.error(f"Consider reducing the limit or optimizing the query")
            raise RuntimeError(f"Cortex Search query timed out after {execution_time:.2f}s. Consider reducing chunk limit or simplifying query.")
            
        elif "permission" in error_message or "access" in error_message or "unauthorized" in error_message:
            logger.error(f"Cortex Search Service access denied after {execution_time:.2f}s")
            logger.error(f"Service: {cortex_search_service}")
            logger.error(f"Current role/user may not have access to the search service")
            raise RuntimeError(f"Access denied to Cortex Search Service '{cortex_search_service}'. Check user permissions and role configuration.")
            
        elif "invalid" in error_message and "query" in error_message:
            logger.error(f"Invalid Cortex Search query after {execution_time:.2f}s")
            logger.error(f"Service: {cortex_search_service}")
            logger.error(f"Query payload: {json.dumps(search_payload)}")
            logger.error(f"The query format may be incorrect or contain invalid parameters")
            raise RuntimeError(f"Invalid query format for Cortex Search Service. Check query structure and parameters.")
            
        else:
            # Generic Snowflake/Database error
            logger.error(f"Unexpected Cortex Search error after {execution_time:.2f}s")
            logger.error(f"Service: {cortex_search_service}")
            logger.error(f"Query payload: {json.dumps(search_payload)}")
            logger.error(f"Original error: {str(e)}")
            logger.error(f"Error type: {type(e).__name__}")
            raise RuntimeError(f"Cortex Search Service error: {str(e)}. Check service status and configuration.")
            
    finally:
        try:
            cur.close()
            conn.close()
        except Exception as close_error:
            logger.warning(f"Failed to close database connection: {str(close_error)}")

    # Process results to match the expected format
    context_parts = []
    
    try:
        # Enhanced parsing with better error handling
        logger.info(f"Parsing Cortex Search response structure")
        
        # Validate response is a dictionary or list
        if not isinstance(search_results, (dict, list)):
            logger.error(f"Invalid response type: {type(search_results)}")
            logger.error(f"Expected dict or list, got: {search_results}")
            raise RuntimeError(f"Cortex Search returned invalid response type: {type(search_results).__name__}")
        
        # Handle different possible response structures
        if isinstance(search_results, dict):
            if 'results' in search_results:
                results = search_results['results']
                logger.info(f"Found 'results' key in response with {len(results)} items")
            elif 'data' in search_results:
                results = search_results['data']
                logger.info(f"Found 'data' key in response with {len(results)} items")
            else:
                # Try to find any array in the response
                array_keys = [k for k, v in search_results.items() if isinstance(v, list)]
                if array_keys:
                    results = search_results[array_keys[0]]
                    logger.warning(f"No standard 'results' key found, using '{array_keys[0]}' with {len(results)} items")
                else:
                    logger.error(f"No array found in response structure: {list(search_results.keys())}")
                    logger.error(f"Full response: {search_results}")
                    raise RuntimeError("Cortex Search response does not contain expected results array")
        elif isinstance(search_results, list):
            results = search_results
            logger.info(f"Response is a direct list with {len(results)} items")
        else:
            logger.error(f"Unexpected response structure: {search_results}")
            raise RuntimeError("Malformed response from Cortex Search Service")
        
        # Validate results is a list
        if not isinstance(results, list):
            logger.error(f"Results is not a list: {type(results)}")
            logger.error(f"Results content: {results}")
            raise RuntimeError(f"Cortex Search results should be a list, got {type(results).__name__}")
            
        chunk_count = len(results)
        logger.info(f"Processing {chunk_count} result items from Cortex Search")
        
        # Process each result item with enhanced error handling
        for idx, result_item in enumerate(results):
            try:
                if not isinstance(result_item, dict):
                    logger.warning(f"Result item {idx} is not a dictionary: {type(result_item)}")
                    continue
                    
                # Extract chunk and relative_path from the result
                chunk_text = result_item.get('CHUNK', result_item.get('chunk', ''))
                file_name = result_item.get('RELATIVE_PATH', result_item.get('relative_path', result_item.get('file_name', 'unknown')))
                
                # Validate extracted data
                if not chunk_text:
                    logger.warning(f"Result item {idx} has no chunk text, skipping")
                    logger.debug(f"Item keys: {list(result_item.keys())}")
                    continue
                    
                if not isinstance(chunk_text, str):
                    logger.warning(f"Result item {idx} chunk text is not a string: {type(chunk_text)}")
                    chunk_text = str(chunk_text)
                
                context_parts.append(f"[SOURCE: {file_name}]\n{chunk_text}")
                
            except Exception as item_error:
                logger.warning(f"Error processing result item {idx}: {str(item_error)}")
                logger.debug(f"Problematic item: {result_item}")
                continue
                
    except json.JSONDecodeError as e:
        logger.error(f"JSON parsing error in Cortex Search response: {str(e)}")
        logger.error(f"Raw response (first 500 chars): {str(search_results)[:500]}...")
        raise RuntimeError(f"Cortex Search returned invalid JSON response: {str(e)}")
        
    except (KeyError, TypeError, AttributeError) as e:
        logger.error(f"Error parsing Cortex Search results structure: {str(e)}")
        logger.error(f"Response type: {type(search_results)}")
        logger.error(f"Response keys: {list(search_results.keys()) if isinstance(search_results, dict) else 'Not a dict'}")
        logger.error(f"Raw response: {search_results}")
        raise RuntimeError(f"Failed to parse Cortex Search response structure: {str(e)}")
        
    except Exception as e:
        logger.error(f"Unexpected error parsing Cortex Search results: {str(e)}")
        logger.error(f"Error type: {type(e).__name__}")
        logger.error(f"Raw response: {search_results}")
        raise RuntimeError(f"Unexpected error processing Cortex Search response: {str(e)}")

    # Final validation and logging
    processed_chunks = len(context_parts)
    if processed_chunks == 0:
        logger.warning("No valid chunks were extracted from Cortex Search response")
        logger.warning(f"Original result count: {chunk_count if 'chunk_count' in locals() else 'unknown'}")
        
    final_result = "\n\n".join(context_parts)
    logger.info(f"Cortex Search method completed, returned {processed_chunks} processed chunks")
    
    return final_result


def get_similar_chunks_unified(question: str) -> str:
    """
    Unified method dispatcher that routes to the appropriate chunk retrieval method
    based on the USE_CORTEX_SEARCH configuration flag.
    
    Args:
        question (str): The user's question
        
    Returns:
        str: Concatenated chunks in the same format as both legacy and Cortex methods
    """
    import time
    start_time = time.time()
    
    # Get DocuClaims local configuration
    docuclaims_config = get_docuclaims_config()
    use_cortex = docuclaims_config['search_config']['use_cortex_search']
    num_chunks = docuclaims_config['search_config']['num_chunks']
    
    method_name = "Cortex Search Service" if use_cortex else "Legacy Vector Similarity"
    
    logger.info(f"=== SIMILARITY SEARCH START ===")
    logger.info(f"Method selected: {method_name}")
    logger.info(f"USE_CORTEX_SEARCH config: {use_cortex}")
    logger.info(f"Question length: {len(question)} characters")
    logger.info(f"Target chunks: {num_chunks}")
    
    if use_cortex:
        # Use Cortex Search method
        logger.info("Routing to Cortex Search Service method")
        result = get_similar_chunks_cortex(question)
    else:
        # Use legacy method
        logger.info("Routing to legacy vector similarity method")
        result = get_similar_chunks(question)
    
    # Calculate overall execution time and result metrics
    total_execution_time = time.time() - start_time
    result_chunks = result.count("[SOURCE:") if result else 0
    result_length = len(result) if result else 0
    
    logger.info(f"=== SIMILARITY SEARCH COMPLETE ===")
    logger.info(f"Method used: {method_name}")
    logger.info(f"Total execution time: {total_execution_time:.2f}s")
    logger.info(f"Result chunks returned: {result_chunks}")
    logger.info(f"Result total length: {result_length} characters")
    logger.info(f"Average chunk size: {result_length / result_chunks if result_chunks > 0 else 0:.1f} characters")
    
    return result


def summarize_question_with_history(chat_history, question, llm_model):
    """
    Given a chat history (list of previous messages) and a new question,
    ask Snowflake Cortex to produce a concise "summarized query" incorporating the prior conversation.
    llm_model is required.
    """
    if not llm_model:
        raise ValueError("llm_model must be provided to summarize_question_with_history.")
    
    history_str = "\n".join(chat_history)
    prompt = f"""
                Based on the chat history below and the question, generate a query that extends the question
                with the chat history provided. The query should be in natural language.
                Answer with only the query. Do not add any explanation.

                <chat_history>
                {history_str}
                </chat_history>
                <question>
                {question}
                </question>
    """
    conn, cur = get_sf_conn()
    

    sql = """
        SELECT SNOWFLAKE.CORTEX.AI_COMPLETE(%s, %s) AS response
    """
    try:
        cur.execute(sql, (llm_model, prompt))
        row = cur.fetchone()
        logger.info("Summarized question with chat history using Snowflake Cortex.")
    finally:
        try:
            cur.close()
            conn.close()
        except Exception as close_error:
            logger.warning(f"Failed to close database connection: {str(close_error)}")

    if not row or not row[0]:
        raise RuntimeError("No response returned from Snowflake Cortex.")
    return row[0].replace("'", "")


def build_prompt(question, chat_history, llm_model):
    """
    Construct the full prompt to send to Snowflake Cortex, including:
      1. A summary of the chat history (if any)
      2. The most similar chunks from chunks table
      3. The user's question
    llm_model is required.
    """
    if not llm_model:
        raise ValueError("llm_model must be provided to build_prompt.")
    
    if chat_history:
        summary = summarize_question_with_history(chat_history, question, llm_model)
        context = get_similar_chunks_unified(summary)
        history_str = "\n".join(chat_history)
    else:
        context = get_similar_chunks_unified(question)
        history_str = ""

    prompt = f"""
                You are an expert chat assistant.

                When answering the question between <question> and </question> tags, always prioritize and extract information from the CONTEXT provided between <context> and </context> tags, as well as the CHAT HISTORY provided between <chat_history> and </chat_history> tags.

                Use the retrieved documents to answer the question. At the end of the answer, list the file name(s) you referenced.

                Do not hallucinate. If you do not have enough information from either the CONTEXT, CHAT HISTORY, or your general knowledge, say so.

                Do not mention the CONTEXT or CHAT HISTORY in your answer.
                Do not include or display any "think" steps, reasoning process, or internal deliberation in your response.

                <chat_history>
                {history_str}
                </chat_history>
                <context>
                {context}
                </context>
                <question>
                {question}
                </question>
                Answer:
    """
    logger.info("Prompt built for Snowflake Cortex LLM.")
    return prompt


def get_random_suggestion_questions(count: int = 3) -> list[str]:
    """
    Get random suggestion questions from configuration.
    
    Args:
        count: Number of random questions to return (default: 3)
        
    Returns:
        list[str]: List of randomly selected suggestion questions
    """
    try:
        docuclaims_config = get_docuclaims_config()
        all_questions = docuclaims_config.get('suggestion_questions', [])
        
        if not all_questions:
            logger.warning("No suggestion questions found in configuration")
            return []
        
        # Return random sample, up to the available count
        sample_size = min(count, len(all_questions))
        selected_questions = random.sample(all_questions, sample_size)
        
        logger.info(f"Selected {sample_size} random suggestion questions from {len(all_questions)} available")
        return selected_questions
        
    except Exception as e:
        logger.error(f"Error getting suggestion questions: {str(e)}", exc_info=True)
        return []


def generate_followup_questions(
    user_question: str,
    ai_response: str,
    conversation_history: list,
    model: str
) -> list[str]:
    """
    Generate 3 relevant follow-up questions based on conversation context.
    
    Uses Snowflake Cortex AI to generate contextually relevant questions that
    explore different aspects (clarification, deeper dive, related topics) and
    are specific to the document content.
    
    Args:
        user_question: The user's current question
        ai_response: The AI's response to the current question
        conversation_history: List of recent message exchanges (limited to last 6 messages)
        model: AI model to use for generation (e.g., 'claude-4-sonnet')
        
    Returns:
        List of 3 follow-up question strings. Returns empty list on error.
    """
    import time
    start_time = time.time()
    
    logger.info("[FOLLOWUP] Starting follow-up question generation")
    logger.info(f"[FOLLOWUP] Model: {model}")
    logger.info(f"[FOLLOWUP] User question length: {len(user_question)} characters")
    logger.info(f"[FOLLOWUP] AI response length: {len(ai_response)} characters")
    logger.info(f"[FOLLOWUP] Conversation history: {len(conversation_history)} messages")
    
    if not model:
        logger.error("[FOLLOWUP] Model parameter is required")
        return []
    
    if not user_question or not ai_response:
        logger.warning("[FOLLOWUP] User question or AI response is empty")
        return []
    
    limited_history = conversation_history[-6:] if len(conversation_history) > 6 else conversation_history
    history_str = "\n".join(limited_history) if limited_history else "No previous conversation"
    
    logger.info(f"[FOLLOWUP] Using {len(limited_history)} messages from conversation history")
    
    prompt = f"""
Based on the conversation context below, generate exactly 3 relevant follow-up questions that the user might want to ask next.

Requirements for the questions:
1. Each question should explore a DIFFERENT aspect: one for clarification, one for deeper analysis, and one for related topics
2. Questions must be specific to the document content mentioned in the AI response
3. Keep each question concise (maximum 15 words)
4. Make questions actionable and directly answerable from the documents
5. Do not create generic questions - they must be contextually relevant
6. Do not include question numbers or bullet points in your response

<conversation_history>
{history_str}
</conversation_history>

<user_question>
{user_question}
</user_question>

<ai_response>
{ai_response}
</ai_response>

Generate exactly 3 follow-up questions, one per line, without any numbering, bullets, or additional formatting:
"""
    
    conn, cur = get_sf_conn()
    
    sql = """
        SELECT SNOWFLAKE.CORTEX.AI_COMPLETE(%s, %s) AS response
    """
    
    try:
        logger.info("[FOLLOWUP] Executing Snowflake Cortex AI_COMPLETE query")
        cur.execute(sql, (model, prompt))
        row = cur.fetchone()
        
        execution_time = time.time() - start_time
        logger.info(f"[FOLLOWUP] Query executed in {execution_time:.2f}s")
        
        if not row or not row[0]:
            logger.error("[FOLLOWUP] No response returned from Snowflake Cortex")
            return []
        
        raw_response = row[0].strip()
        logger.info(f"[FOLLOWUP] Raw response length: {len(raw_response)} characters")
        logger.info(f"[FOLLOWUP] Raw response content: {raw_response[:500]}")  # Log first 500 chars
        
        questions = []
        lines = raw_response.split('\n')
        
        logger.info(f"[FOLLOWUP] Split into {len(lines)} lines")
        
        for idx, line in enumerate(lines):
            cleaned_line = line.strip()
            
            if not cleaned_line:
                continue
            
            logger.info(f"[FOLLOWUP] Processing line {idx + 1}: {cleaned_line[:100]}")
            
            cleaned_line = re.sub(r'^[\d\.\)\-\*•]+\s*', '', cleaned_line)
            
            if (cleaned_line.startswith('"') and cleaned_line.endswith('"')) or \
               (cleaned_line.startswith("'") and cleaned_line.endswith("'")):
                cleaned_line = cleaned_line[1:-1]
            
            if cleaned_line and len(cleaned_line) > 10:
                questions.append(cleaned_line)
                logger.info(f"[FOLLOWUP] Added question {len(questions)}: {cleaned_line}")
        
        questions = questions[:3]
        logger.info(f"[FOLLOWUP] Final questions list: {questions}")
        
        if len(questions) < 3:
            logger.warning(f"[FOLLOWUP] Only generated {len(questions)} questions, expected 3")
        
        total_time = time.time() - start_time
        logger.info(f"[FOLLOWUP] Successfully generated {len(questions)} follow-up questions in {total_time:.2f}s")
        
        return questions
        
    except Exception as e:
        execution_time = time.time() - start_time
        logger.error(f"[FOLLOWUP] Error generating follow-up questions after {execution_time:.2f}s: {str(e)}", exc_info=True)
        return []
        
    finally:
        try:
            cur.close()
            conn.close()
            logger.info("[FOLLOWUP] Database connection closed")
        except Exception as close_error:
            logger.warning(f"[FOLLOWUP] Failed to close database connection: {str(close_error)}")
