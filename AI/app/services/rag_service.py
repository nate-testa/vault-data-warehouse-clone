from app.services.snowflake_service import get_sf_conn
from app.config import get_config
from app.utils.logging import logger


def get_similar_chunks(question: str, config) -> str:
    """
    Query Snowflake via sf_conn to retrieve the top NUM_CHUNKS most similar
    chunks (by cosine similarity) from chunks table, given a question.
    Concatenate their text and return it as a single string.
    """
    conn = get_sf_conn(config)
    cur = conn.cursor()
    # chunks_table = f"{config['SF_DATABASE']}.{config['SF_SCHEMA']}.{config['SF_CHUNKS_TABLE']}"
    database = config["SF_DATABASE"]
    schema = config["SF_SCHEMA"]
    chunks_table = config["SF_CHUNKS_TABLE"]
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
        cur.execute(sql, (config["EMBEDDING_MODEL"], question, config["NUM_CHUNKS"]))
        df_chunks = cur.fetch_pandas_all()
        logger.info(f"Fetched similar chunks for question: {question}")
    finally:
        cur.close()
        conn.close()

    context_parts = []
    for index, row in df_chunks.iterrows():
        chunk_text = row['CHUNK']
        file_name = row['FILE_NAME']
        context_parts.append(f"[SOURCE: {file_name}]\n{chunk_text}")

    return "\n\n".join(context_parts)


def summarize_question_with_history(chat_history, question, llm_model):
    """
    Given a chat history (list of previous messages) and a new question,
    ask Snowflake Cortex to produce a concise “summarized query” incorporating the prior conversation.
    llm_model is required.
    """
    if not llm_model:
        raise ValueError("llm_model must be provided to summarize_question_with_history.")
    config = get_config()
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
    conn = get_sf_conn(config)
    cur = conn.cursor()
    sql = """
        SELECT SNOWFLAKE.CORTEX.AI_COMPLETE(%s, %s) AS response
    """
    try:
        cur.execute(sql, (llm_model, prompt))
        row = cur.fetchone()
        logger.info("Summarized question with chat history using Snowflake Cortex.")
    finally:
        cur.close()
        conn.close()

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
    config = get_config()
    if chat_history:
        summary = summarize_question_with_history(chat_history, question, llm_model)
        context = get_similar_chunks(summary, config)
        history_str = "\n".join(chat_history)
    else:
        context = get_similar_chunks(question, config)
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

