"""
Flask routes for the Insights module.

This module provides Flask blueprint routes for the Insights chat interface,
handling domain selection, Cortex Analyst queries, SQL execution, and feedback submission.
"""

from flask import Blueprint, render_template, request, jsonify
import time
import json
import csv
import io
import base64
from typing import Dict, List, Any, Optional
from auth.decorators import login_required, require_app_access
from auth.session_manager import SessionManager
from modules.insights.session_manager import InsightsSessionManager
from .services import (
    send_analyst_query,
    send_analyst_query_v2,
    get_available_domains,
    get_domain_models,
    get_cached_domains,
    cache_domains,
    execute_sql_query,
    submit_feedback,
    get_example_questions
)
from utils.logging import logger

# Create Blueprint for Insights module
insights_bp = Blueprint(
    'insights',
    __name__,
    template_folder='templates',
    static_folder='static',
    static_url_path='/insights/static'
)

# Initialize session managers
session_manager = SessionManager()
insights_session = InsightsSessionManager()


def generate_csv_content(columns: List[str], data: List[List]) -> str:
    """
    Generate CSV content from columns and data.
    
    Args:
        columns (List[str]): Column headers
        data (List[List]): Data rows
        
    Returns:
        str: CSV content as string
    """
    output = io.StringIO()
    writer = csv.writer(output)
    
    # Write header
    writer.writerow(columns)
    
    # Write data rows
    for row in data:
        # Convert None values to empty strings
        clean_row = ['' if cell is None else str(cell) for cell in row]
        writer.writerow(clean_row)
    
    csv_content = output.getvalue()
    output.close()
    
    return csv_content


def generate_excel_base64(columns: List[str], data: List[List]) -> str:
    """
    Generate Excel content as base64 string.
    
    Args:
        columns (List[str]): Column headers
        data (List[List]): Data rows
        
    Returns:
        str: Excel file content encoded as base64
    """
    try:
        import pandas as pd
        import openpyxl
        from openpyxl.styles import Font, PatternFill
        
        logger.debug(f"Generating Excel with {len(columns)} columns and {len(data)} rows")
        
        # Create DataFrame with proper handling of None values
        clean_data = []
        for row in data:
            clean_row = ['' if cell is None else cell for cell in row]
            clean_data.append(clean_row)
        
        df = pd.DataFrame(clean_data, columns=columns)
        
        # Create Excel file in memory
        output = io.BytesIO()
        
        # Use pandas ExcelWriter with openpyxl engine
        with pd.ExcelWriter(output, engine='openpyxl') as writer:
            df.to_excel(writer, sheet_name='Query Results', index=False)
            
            # Get workbook and worksheet for formatting
            workbook = writer.book
            worksheet = writer.sheets['Query Results']
            
            # Auto-adjust column widths
            for column in worksheet.columns:
                max_length = 0
                column_letter = column[0].column_letter
                for cell in column:
                    try:
                        if cell.value is not None and len(str(cell.value)) > max_length:
                            max_length = len(str(cell.value))
                    except:
                        pass
                adjusted_width = min(max(max_length + 2, 10), 50)  # Min 10, Max 50
                worksheet.column_dimensions[column_letter].width = adjusted_width
            
            # Style header row
            header_font = Font(bold=True, color="FFFFFF")
            header_fill = PatternFill(start_color="366092", end_color="366092", fill_type="solid")
            
            for cell in worksheet[1]:
                cell.font = header_font
                cell.fill = header_fill
        
        # Get the Excel content
        output.seek(0)
        excel_bytes = output.getvalue()
        output.close()
        
        logger.debug(f"Excel file generated successfully: {len(excel_bytes)} bytes")
        
        # Convert to base64
        base64_content = base64.b64encode(excel_bytes).decode('utf-8')
        logger.debug(f"Base64 encoded: {len(base64_content)} characters")
        
        return base64_content
        
    except ImportError as e:
        # Fallback: generate CSV with Excel-compatible format
        logger.warning(f"pandas/openpyxl not available ({e}), falling back to CSV for Excel export")
        csv_content = generate_csv_content(columns, data)
        return base64.b64encode(csv_content.encode('utf-8-sig')).decode('utf-8')  # UTF-8 BOM for Excel
        
    except Exception as e:
        logger.error(f"Excel generation failed: {e}", exc_info=True)
        # Fallback to CSV
        logger.warning("Falling back to CSV format")
        csv_content = generate_csv_content(columns, data)
        return base64.b64encode(csv_content.encode('utf-8-sig')).decode('utf-8')


def extract_sql_from_response(response_content: List[Dict]) -> Optional[str]:
    """
    Extract SQL query from Cortex Analyst response content.
    
    Args:
        response_content (List[Dict]): The response content from Cortex Analyst
        
    Returns:
        Optional[str]: The SQL query if found, None otherwise
    """
    logger.debug(f"[extract_sql_from_response] Input type: {type(response_content)}, content: {response_content}")
    
    if not response_content or not isinstance(response_content, list):
        logger.debug(f"[extract_sql_from_response] Invalid response_content: {response_content}")
        return None
    
    for i, item in enumerate(response_content):
        logger.debug(f"[extract_sql_from_response] Item {i}: type={type(item)}, content={item}")
        if isinstance(item, dict) and item.get('type') == 'sql':
            sql_statement = item.get('statement', '').strip()
            logger.debug(f"[extract_sql_from_response] Found SQL item: statement length={len(sql_statement)}")
            if sql_statement:
                logger.info(f"[extract_sql_from_response] Successfully extracted SQL: {sql_statement[:100]}...")
                return sql_statement
    
    logger.debug(f"[extract_sql_from_response] No SQL found in {len(response_content)} items")
    return None



@insights_bp.route('/insights')
@login_required
@require_app_access('Insights')
def insights():
    """
    Main Insights chat interface page.
    
    Initializes session, loads available domains and renders the chat template.
    Implements a ChatGPT-style conversational interface for semantic model analytics.
    
    Returns:
        str: Rendered HTML template for the Insights chat interface
    """
    # Get user IP for tracking and security logging
    client_ip = request.environ.get('HTTP_X_FORWARDED_FOR', request.environ.get('REMOTE_ADDR', 'unknown'))
    if ',' in client_ip:
        client_ip = client_ip.split(',')[0].strip()
    
    logger.info(f"[INSIGHTS_ROUTES] Insights page accessed by IP: {client_ip}")
    
    try:
        # Initialize Insights session variables
        insights_session.initialize_insights_session()
        
        # Perform session cleanup to prevent cookie overflow
        insights_session.cleanup_generic_session_storage()
        
        # Get current user for template context
        user = session_manager.get_current_user()
        
        # Load available domains with caching
        domains_data = None
        try:
            # Try to get cached domains first
            domains_data = get_cached_domains()
            
            if not domains_data:
                # Fetch fresh data from API
                domains_data = get_available_domains()
                cache_domains(domains_data)
                
        except Exception as e:
            logger.error(f"[INSIGHTS_ROUTES] Error loading domains: {str(e)}")
            # Provide fallback domains if API fails
            domains_data = {
                'domains': {
                    'policy': {'name': 'Policy', 'description': 'Policy data analysis', 'semantic_views': []},
                    'sales': {'name': 'Sales', 'description': 'Sales performance analysis', 'semantic_views': []},
                    'claims': {'name': 'Claims', 'description': 'Claims processing analysis', 'semantic_views': []},
                    'others': {'name': 'Others', 'description': 'General business metrics', 'semantic_views': []}
                },
                'total_domains': 4,
                'total_semantic_views': 0
            }
        
        # Get current domain selection
        domain_selection = insights_session.get_domain_selection()
        current_domain = domain_selection.get('domain', 'policy')
        
        # Ensure selected domain exists in available domains
        if current_domain not in domains_data.get('domains', {}):
            current_domain = 'policy'
            insights_session.set_domain_selection(current_domain)
        
        # Get conversation messages for template
        chat_messages = insights_session.get_chat_messages()
        
        # Add welcome message if this is a new session
        if insights_session.should_show_welcome():
            welcome_message = _create_welcome_message(current_domain, domains_data)
            insights_session.add_chat_message(welcome_message)
            insights_session.mark_welcome_shown()
            chat_messages = insights_session.get_chat_messages()
        
        # Get user preferences
        user_preferences = insights_session.get_user_preferences()
        use_chat_history = insights_session.get_chat_history_preference()
        
        logger.info(f"[INSIGHTS_ROUTES] Rendering Insights interface - Domain: {current_domain}, Messages: {len(chat_messages)}, Chat History: {use_chat_history}")
        
        return render_template(
            'insights.html',
            user=user,
            domains_data=domains_data,
            current_domain=current_domain,
            chat_messages=chat_messages,
            user_preferences=user_preferences,
            use_chat_history=use_chat_history,
            conversation_id=insights_session.get_conversation_id(),
            active_suggestions=insights_session.get_active_suggestions()
        )
        
    except Exception as e:
        logger.error(f"[INSIGHTS_ROUTES] Error rendering Insights page: {str(e)}", exc_info=True)
        # Return a simple error response instead of trying to render non-existent error template
        return f"<h1>Service Unavailable</h1><p>Unable to load Insights interface. Please try again later.</p><p>Error: {str(e)}</p>", 500


@insights_bp.route('/insights/domains/<domain>/models', methods=['GET'])
@login_required
@require_app_access('Insights')
def get_domain_models_endpoint(domain):
    """
    Get available semantic models for a specific domain.
    
    Returns models in the format expected by the frontend model selector.
    """
    try:
        models = get_domain_models(domain)
        
        return jsonify({
            'success': True,
            'domain': domain,
            'models': models
        })
        
    except Exception as e:
        logger.error(f"[INSIGHTS_ROUTES] Error getting models for domain '{domain}': {str(e)}")
        return jsonify({
            'success': False,
            'error': f'Unable to get models for domain {domain}',
            'message': str(e)
        }), 500


@insights_bp.route('/insights/query_v2', methods=['POST'])
@login_required
@require_app_access('Insights')
def process_query_v2():
    """
    Handle user question submissions via AJAX using multiple semantic models.
    
    Processes natural language questions through Cortex Analyst with multiple 
    semantic models, updates conversation history, and returns structured response.
    
    Returns:
        JSON: Analyst response with content, warnings, and UI updates
    """
    start_time = time.time()
    interaction_id = f"query_v2_{int(time.time())}_{request.environ.get('REMOTE_ADDR', 'unknown')[-3:]}"
    
    try:
        # Parse request data
        if not request.is_json:
            logger.error(f"[{interaction_id}] Invalid request format - not JSON")
            return jsonify({
                'error': 'Invalid request format',
                'message': 'Request must be JSON'
            }), 400
        
        data = request.get_json()
        question = data.get('question', '').strip()
        domain = data.get('domain', '').strip()
        semantic_models = data.get('semantic_models', [])
        
        logger.info(f"[{interaction_id}] Request data - question: '{question[:50]}...', domain: '{domain}', models: {len(semantic_models)}")
        
        # Input validation
        if not question:
            logger.warning(f"[{interaction_id}] Empty question submitted")
            return jsonify({
                'error': 'Invalid input',
                'message': 'Please enter a question'
            }), 400
        
        if not domain:
            logger.warning(f"[{interaction_id}] No domain specified")
            return jsonify({
                'error': 'Invalid input', 
                'message': 'Please select a domain'
            }), 400
        
        if not semantic_models:
            logger.warning(f"[{interaction_id}] No semantic models provided")
            return jsonify({
                'error': 'Invalid input', 
                'message': 'No semantic models available for the selected domain'
            }), 400
        
        logger.info(f"[{interaction_id}] Processing query: '{question[:100]}...' for domain: {domain}")
        logger.info(f"[{interaction_id}] Using {len(semantic_models)} semantic models")
        
        # Check if chat history is enabled
        use_chat_history = insights_session.get_chat_history_preference()
        
        # Get conversation history for context (only if enabled)
        conversation_history = []
        if use_chat_history:
            conversation_history = insights_session.get_conversation_history_for_api()
            history_length = len(conversation_history)
            logger.debug(f"[{interaction_id}] Conversation history enabled: {history_length} messages")
        else:
            logger.debug(f"[{interaction_id}] Conversation history disabled by user preference")
        
        # Add user message to session first
        user_message = {
            'role': 'user',
            'content': question,
            'domain': domain,
            'semantic_models': semantic_models
        }
        
        insights_session.add_chat_message(user_message)
        
        # Send query to Cortex Analyst using query_v2
        try:
            analyst_response = send_analyst_query_v2(
                question=question,
                domain=domain,
                semantic_models=semantic_models,
                message_history=conversation_history
            )
            
            # Process and add assistant response to session
            assistant_message = {
                'role': 'assistant',
                'content': analyst_response.get('message', []),
                'request_id': analyst_response.get('request_id'),
                'warnings': analyst_response.get('warnings', []),
                'domain': domain,
                'semantic_view_used': analyst_response.get('semantic_view_used')
            }
            
            insights_session.add_chat_message(assistant_message)
            
            # Update active suggestions if present in response
            suggestions = []
            for item in analyst_response.get('message', []):
                if isinstance(item, dict) and item.get('type') == 'suggestions':
                    suggestions.extend(item.get('suggestions', []))
            
            if suggestions:
                insights_session.set_active_suggestions(suggestions)
            
            # Set conversation ID if provided
            if analyst_response.get('conversation_id'):
                insights_session.set_conversation_id(analyst_response['conversation_id'])
            
            query_time = time.time() - start_time
            logger.info(f"[{interaction_id}] Successfully processed query in {query_time:.2f}s")
            
            # Automatic SQL execution logic (using the semantic view that was actually used)
            sql_results = None
            sql_execution_error = None
            total_processing_time = query_time
            semantic_view_used = analyst_response.get('semantic_view_used', '')
            
            # Try to extract and automatically execute SQL
            sql_query = extract_sql_from_response(analyst_response.get('message', []))
            logger.debug(f"[{interaction_id}] Extracted SQL query: {bool(sql_query)}")
            logger.debug(f"[{interaction_id}] semantic_view_used: {semantic_view_used}")
            logger.debug(f"[{interaction_id}] Response message structure: {type(analyst_response.get('message', []))}")
            
            if sql_query:
                logger.info(f"[{interaction_id}] Found SQL query, attempting automatic execution...")
                
                # Use semantic_view_used if available, otherwise use first semantic model as fallback for caching
                cache_semantic_view = semantic_view_used or (semantic_models[0]['semantic_view'] if semantic_models else 'unknown')
                
                # Check cache first
                cache_key = insights_session.generate_cache_key(sql_query, domain, cache_semantic_view)
                cached_result = insights_session.get_cached_result(cache_key)
                
                if cached_result:
                    logger.info(f"[{interaction_id}] Using cached SQL result")
                    sql_results = cached_result
                    sql_execution_time = 0.05  # Minimal time for cache retrieval
                    total_processing_time += sql_execution_time
                else:
                    # Execute SQL if not cached
                    try:
                        sql_execution_start = time.time()
                        sql_results = execute_sql_query(
                            sql=sql_query,
                            conversation_id=analyst_response.get('conversation_id')
                        )
                        sql_execution_time = time.time() - sql_execution_start
                        total_processing_time += sql_execution_time
                        
                        # Cache the result
                        insights_session.cache_query_result(
                            cache_key, sql_results, sql_query, domain, cache_semantic_view
                        )
                        
                        logger.info(f"[{interaction_id}] SQL executed automatically in {sql_execution_time:.2f}s")
                        logger.info(f"[{interaction_id}] Results: {len(sql_results.get('data', []))} rows, {len(sql_results.get('columns', []))} columns")
                        
                    except Exception as sql_error:
                        sql_execution_time = time.time() - sql_execution_start
                        total_processing_time += sql_execution_time
                        sql_execution_error = str(sql_error)
                        
                        logger.error(f"[{interaction_id}] Auto SQL execution failed after {sql_execution_time:.2f}s: {str(sql_error)}")
            else:
                logger.info(f"[{interaction_id}] No SQL query found in response, skipping auto-execution")
            
            # Build response with query results or SQL execution error
            response_data = {
                'success': True,
                'request_id': analyst_response.get('request_id'),
                'conversation_id': analyst_response.get('conversation_id'),
                'response': analyst_response.get('message', []),
                'warnings': analyst_response.get('warnings', []),
                'suggestions': suggestions,
                'processing_time': round(total_processing_time, 2),
                'query_generation_time': round(query_time, 2),
                'semantic_view_used': semantic_view_used
            }
            
            # Add SQL results if available
            if sql_results:
                columns = sql_results.get('columns', [])
                data = sql_results.get('data', [])
                
                response_data.update({
                    'sql_executed': True,
                    'sql_results': {
                        'execution_id': sql_results.get('execution_id'),
                        'columns': columns,
                        'data': data,
                        'row_count': len(data),
                        'column_count': len(columns)
                    },
                    'sql_execution_time': round(total_processing_time - query_time, 2)
                })
                
                # Generate export data if we have results
                if columns and data:
                    try:
                        logger.debug(f"[{interaction_id}] Generating export data for {len(data)} rows")
                        response_data['export_data'] = {
                            'csv': generate_csv_content(columns, data),
                            'excel_base64': generate_excel_base64(columns, data),
                            'filename_base': f"insights_export_{int(time.time())}"
                        }
                        logger.debug(f"[{interaction_id}] Export data generated successfully")
                    except Exception as export_error:
                        logger.warning(f"[{interaction_id}] Failed to generate export data: {export_error}")
                        # Continue without export data if generation fails
            elif sql_execution_error:
                response_data.update({
                    'sql_executed': False,
                    'sql_execution_error': sql_execution_error,
                    'sql_execution_time': round(total_processing_time - query_time, 2)
                })
            else:
                response_data['sql_executed'] = False
            
            # Log response details before sending
            response_size = len(str(response_data))
            logger.info(f"[{interaction_id}] Preparing response: size={response_size}B, sql_executed={response_data.get('sql_executed', False)}")
            
            try:
                response = jsonify(response_data)
                logger.info(f"[{interaction_id}] Response successfully serialized and sent to client")
                return response
            except Exception as json_error:
                logger.error(f"[{interaction_id}] Failed to serialize response to JSON: {str(json_error)}", exc_info=True)
                return jsonify({
                    'success': False,
                    'error': 'Serialization error',
                    'message': 'Failed to format response data. Please try again.',
                    'processing_time': round(total_processing_time, 2)
                }), 500
            
        except Exception as api_error:
            query_time = time.time() - start_time
            logger.error(f"[{interaction_id}] API error after {query_time:.2f}s: {str(api_error)}", exc_info=True)
            
            # Remove the user message we added since the request failed
            insights_session.remove_last_chat_message()
            
            logger.info(f"[{interaction_id}] Sending error response to client")
            return jsonify({
                'success': False,
                'error': 'Processing error',
                'message': f'Sorry, I encountered an error while processing your question: {str(api_error)}',
                'processing_time': round(query_time, 2)
            }), 500
            
    except Exception as e:
        processing_time = time.time() - start_time
        logger.error(f"[{interaction_id}] Unexpected error after {processing_time:.2f}s: {str(e)}", exc_info=True)
        
        return jsonify({
            'success': False,
            'error': 'Internal error',
            'message': 'An unexpected error occurred. Please try again or contact support.',
            'processing_time': round(processing_time, 2)
        }), 500


@insights_bp.route('/insights/query', methods=['POST'])
@login_required
@require_app_access('Insights')
def process_query():
    """
    Handle user question submissions via AJAX.
    
    Processes natural language questions through Cortex Analyst,
    updates conversation history, and returns structured response.
    
    Returns:
        JSON: Analyst response with content, warnings, and UI updates
    """
    start_time = time.time()
    interaction_id = f"query_{int(time.time())}_{request.environ.get('REMOTE_ADDR', 'unknown')[-3:]}"
    
    try:
        # Parse request data
        if not request.is_json:
            logger.error(f"[{interaction_id}] Invalid request format - not JSON")
            return jsonify({
                'error': 'Invalid request format',
                'message': 'Request must be JSON'
            }), 400
        
        data = request.get_json()
        question = data.get('question', '').strip()
        domain = data.get('domain', '').strip()
        semantic_view = data.get('semantic_view', '').strip()
        
        logger.info(f"[{interaction_id}] Request data - question: '{question[:50]}...', domain: '{domain}', semantic_view: '{semantic_view}'")
        
        # Input validation
        if not question:
            logger.warning(f"[{interaction_id}] Empty question submitted")
            return jsonify({
                'error': 'Invalid input',
                'message': 'Please enter a question'
            }), 400
        
        if not domain:
            logger.warning(f"[{interaction_id}] No domain specified")
            return jsonify({
                'error': 'Invalid input', 
                'message': 'Please select a domain'
            }), 400
        
        # Handle missing semantic view - get default one for the domain
        if not semantic_view:
            try:
                logger.info(f"[{interaction_id}] No semantic view provided, fetching default for domain '{domain}'")
                
                # Get domain info and use default model from configuration
                domains_data = get_available_domains()
                domain_info = domains_data.get('domains', {}).get(domain, {})
                semantic_view = domain_info.get('default_model', '')
                
                if not semantic_view:
                    # Fallback to first available model if no default specified
                    semantic_views = domain_info.get('semantic_views', [])
                    if semantic_views:
                        semantic_view = semantic_views[0].get('full_path', '')
                
                if semantic_view:
                    logger.info(f"[{interaction_id}] Using default semantic view: '{semantic_view}'")
                    # Store the selected semantic view in session
                    insights_session.set_domain_selection(domain, semantic_view)
                else:
                    logger.error(f"[{interaction_id}] No semantic view found for domain '{domain}'")
                    return jsonify({
                        'error': 'No semantic model available', 
                        'message': f'No semantic models found for domain {domain}. Please contact support.'
                    }), 500
                    
            except Exception as e:
                logger.error(f"[{interaction_id}] Error getting default semantic view for domain '{domain}': {str(e)}")
                return jsonify({
                    'error': 'Configuration error', 
                    'message': 'Unable to get domain configuration. Please try again or contact support.'
                }), 500
        
        logger.info(f"[{interaction_id}] Processing query: '{question[:100]}...' for domain: {domain}")
        logger.info(f"[{interaction_id}] Using semantic view: '{semantic_view}'")
        
        # Get conversation history for context
        conversation_history = insights_session.get_conversation_history_for_api()
        history_length = len(conversation_history)
        
        logger.debug(f"[{interaction_id}] Conversation history: {history_length} messages")
        
        # Add user message to session first
        user_message = {
            'role': 'user',
            'content': question,
            'domain': domain,
            'semantic_view': semantic_view
        }
        
        insights_session.add_chat_message(user_message)
        
        # Send query to Cortex Analyst
        try:
            analyst_response = send_analyst_query(
                question=question,
                domain=domain,
                semantic_view=semantic_view,
                message_history=conversation_history
            )
            
            # Process and add assistant response to session
            assistant_message = {
                'role': 'assistant',
                'content': analyst_response.get('message', []),
                'request_id': analyst_response.get('request_id'),
                'warnings': analyst_response.get('warnings', []),
                'domain': domain,
                'semantic_view': semantic_view
            }
            
            insights_session.add_chat_message(assistant_message)
            
            # Update active suggestions if present in response
            suggestions = []
            for item in analyst_response.get('message', []):
                if isinstance(item, dict) and item.get('type') == 'suggestions':
                    suggestions.extend(item.get('suggestions', []))
            
            if suggestions:
                insights_session.set_active_suggestions(suggestions)
            
            # Set conversation ID if provided
            if analyst_response.get('conversation_id'):
                insights_session.set_conversation_id(analyst_response['conversation_id'])
            
            query_time = time.time() - start_time
            logger.info(f"[{interaction_id}] Successfully processed query in {query_time:.2f}s")
            
            # NEW: Automatic SQL execution logic
            sql_results = None
            sql_execution_error = None
            total_processing_time = query_time
            
            # Try to extract and automatically execute SQL
            sql_query = extract_sql_from_response(analyst_response.get('message', []))
            if sql_query:
                logger.info(f"[{interaction_id}] Found SQL query, attempting automatic execution...")
                
                # Check cache first
                cache_key = insights_session.generate_cache_key(sql_query, domain, semantic_view)
                cached_result = insights_session.get_cached_result(cache_key)
                
                if cached_result:
                    logger.info(f"[{interaction_id}] Using cached SQL result")
                    sql_results = cached_result
                    sql_execution_time = 0.05  # Minimal time for cache retrieval
                    total_processing_time += sql_execution_time
                else:
                    # Execute SQL if not cached
                    try:
                        sql_execution_start = time.time()
                        sql_results = execute_sql_query(
                            sql=sql_query,
                            conversation_id=analyst_response.get('conversation_id')
                        )
                        sql_execution_time = time.time() - sql_execution_start
                        total_processing_time += sql_execution_time
                        
                        # Cache the result
                        insights_session.cache_query_result(
                            cache_key, sql_results, sql_query, domain, semantic_view
                        )
                        
                        logger.info(f"[{interaction_id}] SQL executed automatically in {sql_execution_time:.2f}s")
                        logger.info(f"[{interaction_id}] Results: {len(sql_results.get('data', []))} rows, {len(sql_results.get('columns', []))} columns")
                        
                    except Exception as sql_error:
                        sql_execution_time = time.time() - sql_execution_start
                        total_processing_time += sql_execution_time
                        sql_execution_error = str(sql_error)
                        
                        logger.error(f"[{interaction_id}] Auto SQL execution failed after {sql_execution_time:.2f}s: {str(sql_error)}")
            else:
                logger.info(f"[{interaction_id}] No SQL query found in response, skipping auto-execution")
            
            # Build response with query results or SQL execution error
            response_data = {
                'success': True,
                'request_id': analyst_response.get('request_id'),
                'conversation_id': analyst_response.get('conversation_id'),
                'response': analyst_response.get('message', []),
                'warnings': analyst_response.get('warnings', []),
                'suggestions': suggestions,
                'processing_time': round(total_processing_time, 2),
                'query_generation_time': round(query_time, 2)
            }
            
            # Add SQL results if available
            if sql_results:
                columns = sql_results.get('columns', [])
                data = sql_results.get('data', [])
                
                response_data.update({
                    'sql_executed': True,
                    'sql_results': {
                        'execution_id': sql_results.get('execution_id'),
                        'columns': columns,
                        'data': data,
                        'row_count': len(data),
                        'column_count': len(columns)
                    },
                    'sql_execution_time': round(total_processing_time - query_time, 2)
                })
                
                # Generate export data if we have results
                if columns and data:
                    try:
                        logger.debug(f"[{interaction_id}] Generating export data for {len(data)} rows")
                        response_data['export_data'] = {
                            'csv': generate_csv_content(columns, data),
                            'excel_base64': generate_excel_base64(columns, data),
                            'filename_base': f"insights_export_{int(time.time())}"
                        }
                        logger.debug(f"[{interaction_id}] Export data generated successfully")
                    except Exception as export_error:
                        logger.warning(f"[{interaction_id}] Failed to generate export data: {export_error}")
                        # Continue without export data if generation fails
            elif sql_execution_error:
                response_data.update({
                    'sql_executed': False,
                    'sql_execution_error': sql_execution_error,
                    'sql_execution_time': round(total_processing_time - query_time, 2)
                })
            else:
                response_data['sql_executed'] = False
            
            # Log response details before sending
            response_size = len(str(response_data))
            logger.info(f"[{interaction_id}] Preparing response: size={response_size}B, sql_executed={response_data.get('sql_executed', False)}")
            
            try:
                response = jsonify(response_data)
                logger.info(f"[{interaction_id}] Response successfully serialized and sent to client")
                return response
            except Exception as json_error:
                logger.error(f"[{interaction_id}] Failed to serialize response to JSON: {str(json_error)}", exc_info=True)
                return jsonify({
                    'success': False,
                    'error': 'Serialization error',
                    'message': 'Failed to format response data. Please try again.',
                    'processing_time': round(total_processing_time, 2)
                }), 500
            
        except Exception as api_error:
            query_time = time.time() - start_time
            error_msg = str(api_error)
            
            logger.error(f"[{interaction_id}] API error after {query_time:.2f}s: {str(api_error)}")
            
            # Add error message to chat for user context
            error_message = {
                'role': 'assistant',
                'content': [{'type': 'text', 'text': f"Sorry, {error_msg}"}],
                'is_error': True
            }
            insights_session.add_chat_message(error_message)
            
            logger.info(f"[{interaction_id}] Sending error response to client")
            return jsonify({
                'error': 'Processing failed',
                'message': error_msg,
                'processing_time': round(query_time, 2)
            }), 500
            
    except Exception as e:
        query_time = time.time() - start_time
        logger.error(f"[{interaction_id}] Unexpected error after {query_time:.2f}s: {str(e)}", exc_info=True)
        
        return jsonify({
            'error': 'Unexpected error',
            'message': 'An unexpected error occurred. Please try again.',
            'processing_time': round(query_time, 2)
        }), 500


@insights_bp.route('/insights/execute-sql', methods=['POST'])
@login_required
@require_app_access('Insights')
def execute_sql():
    """
    Handle SQL execution from generated queries.
    
    Executes SQL queries with conversation tracking and returns formatted results.
    
    Returns:
        JSON: Query results with columns, data, and execution metadata
    """
    start_time = time.time()
    execution_id = f"sql_{int(time.time())}_{request.environ.get('REMOTE_ADDR', 'unknown')[-3:]}"
    
    try:
        # Parse request data
        if not request.is_json:
            logger.error(f"[{execution_id}] Invalid request format - not JSON")
            return jsonify({
                'error': 'Invalid request format',
                'message': 'Request must be JSON'
            }), 400
        
        data = request.get_json()
        sql_query = data.get('query', '').strip()
        conversation_id = data.get('conversation_id')
        request_id = data.get('request_id')  # For tracking which response generated this SQL
        chart_type = data.get('chart_type')  # Optional chart type preference
        generate_charts = data.get('generate_charts', True)  # Whether to generate charts
        
        # Input validation
        if not sql_query:
            logger.warning(f"[{execution_id}] Empty SQL query submitted")
            return jsonify({
                'error': 'Invalid input',
                'message': 'SQL query is required'
            }), 400
        
        logger.info(f"[{execution_id}] Executing SQL query [conversation_id: {conversation_id}]")
        logger.debug(f"[{execution_id}] SQL: {sql_query[:200]}...")
        
        try:
            # Execute SQL query through service with optional chart generation
            sql_result = execute_sql_query(
                sql=sql_query,
                conversation_id=conversation_id
            )
            
            # Generate chart directly if requested and data is available
            if generate_charts and sql_result.get('data'):
                try:
                    from modules.insights.charts import generate_chart_from_query_result
                    chart_result = generate_chart_from_query_result(
                        query_result=sql_result,
                        chart_type=chart_type if chart_type != 'auto' else None,
                        title=f"Results for Query {sql_result.get('execution_id', '')}"
                    )
                    sql_result['chart'] = chart_result
                    logger.info(f"[{execution_id}] Chart generated successfully: {chart_result.get('success')}")
                except Exception as chart_error:
                    logger.error(f"[{execution_id}] Chart generation failed: {chart_error}")
                    # Continue without chart if generation fails
            
            execution_time = time.time() - start_time
            row_count = len(sql_result.get('data', []))
            column_count = len(sql_result.get('columns', []))
            
            logger.info(f"[{execution_id}] SQL executed successfully in {execution_time:.2f}s - {row_count} rows, {column_count} columns")
            
            # Debug chart generation
            if 'chart' in sql_result:
                chart_data = sql_result['chart']
                logger.info(f"[{execution_id}] Chart generated: success={chart_data.get('success')}, type={chart_data.get('type')}")
            else:
                logger.warning(f"[{execution_id}] No chart data in SQL result")
            
            # Prepare response
            response_data = {
                'success': True,
                'execution_id': sql_result.get('execution_id'),
                'conversation_id': sql_result.get('conversation_id'),
                'columns': sql_result.get('columns', []),
                'data': sql_result.get('data', []),
                'row_count': row_count,
                'column_count': column_count,
                'execution_time': round(execution_time, 2),
                'query': sql_query[:500] + ('...' if len(sql_query) > 500 else '')  # Truncated for response
            }
            
            # Add chart data if generated
            if 'chart' in sql_result:
                response_data['chart'] = sql_result['chart']
                logger.info(f"[{execution_id}] Chart data included in response")
            
            return jsonify(response_data)
            
        except Exception as sql_error:
            execution_time = time.time() - start_time
            error_msg = str(sql_error)
            
            logger.error(f"[{execution_id}] SQL execution error after {execution_time:.2f}s: {str(sql_error)}")
            
            return jsonify({
                'error': 'SQL execution failed',
                'message': error_msg,
                'execution_time': round(execution_time, 2),
                'query': sql_query[:200] + ('...' if len(sql_query) > 200 else '')
            }), 500
            
    except Exception as e:
        execution_time = time.time() - start_time
        logger.error(f"[{execution_id}] Unexpected error after {execution_time:.2f}s: {str(e)}", exc_info=True)
        
        return jsonify({
            'error': 'Unexpected error',
            'message': 'An unexpected error occurred during SQL execution.',
            'execution_time': round(execution_time, 2)
        }), 500


@insights_bp.route('/insights/generate-chart', methods=['POST'])
@login_required
@require_app_access('Insights')
def generate_chart():
    """
    Generate chart from provided data.
    
    Creates interactive Plotly charts from query results or raw data.
    
    Returns:
        JSON: Chart HTML and metadata
    """
    start_time = time.time()
    chart_id = f"chart_{int(time.time())}_{request.environ.get('REMOTE_ADDR', 'unknown')[-3:]}"
    
    try:
        # Parse request data
        if not request.is_json:
            logger.error(f"[{chart_id}] Invalid request format - not JSON")
            return jsonify({
                'error': 'Invalid request format',
                'message': 'Request must be JSON'
            }), 400
        
        data = request.get_json()
        chart_type = data.get('chart_type', 'auto')
        chart_title = data.get('title', 'Data Visualization')
        query_result = data.get('query_result')  # Expected to have 'data' and 'columns'
        raw_data = data.get('data')  # Alternative direct data input
        
        # NEW: Support for parameter-based system
        params = data.get('params')  # Dictionary like {'x': 'COL1', 'y': 'COL2', 'color': 'COL3'}
        
        # LEGACY: Support old x_col/y_col format for backward compatibility
        x_col = data.get('x_col')
        y_col = data.get('y_col')
        
        # Convert legacy format to params format if needed
        # NOTE: Parameter normalization (including chart-specific conversions like pie: x->names, y->values)
        # is now handled by normalize_chart_params() in charts.py
        if not params and (x_col or y_col):
            params = {}
            if x_col:
                params['x'] = x_col
            if y_col:
                params['y'] = y_col
            logger.debug(f"[{chart_id}] Converted legacy x_col/y_col to params format: {params}")
        
        # Input validation
        if not query_result and not raw_data:
            logger.warning(f"[{chart_id}] No data provided for chart generation")
            return jsonify({
                'error': 'Invalid input',
                'message': 'Either query_result or data is required'
            }), 400
        
        logger.info(f"[{chart_id}] Generating {chart_type} chart: '{chart_title}'")
        logger.info(f"[{chart_id}] Request params received: {params}")
        logger.info(f"[{chart_id}] Full request data keys: {list(data.keys())}")
        
        try:
            # Generate chart using charts module directly
            if query_result:
                from modules.insights.charts import chart_generator
                
                final_chart_type = chart_type if chart_type != 'auto' else None
                logger.info(f"[{chart_id}] Calling chart_generator with chart_type={final_chart_type}, params={params}")
                
                chart_result = chart_generator.generate_chart(
                    data=query_result.get('data', []),
                    chart_type=final_chart_type,
                    title=chart_title,
                    params=params,
                    columns=query_result.get('columns', [])
                )
            else:
                # Use charts module directly for raw data
                from modules.insights.charts import chart_generator
                chart_result = chart_generator.generate_chart(
                    data=raw_data,
                    chart_type=chart_type if chart_type != 'auto' else None,
                    title=chart_title,
                    params=params
                )
            
            generation_time = time.time() - start_time
            
            if chart_result.get('success'):
                logger.info(f"[{chart_id}] Chart generated successfully in {generation_time:.2f}s")
            else:
                logger.warning(f"[{chart_id}] Chart generation failed in {generation_time:.2f}s")
            
            # Return chart data
            chart_result['generation_time'] = round(generation_time, 2)
            chart_result['chart_id'] = chart_id
            
            return jsonify(chart_result)
            
        except Exception as chart_error:
            generation_time = time.time() - start_time
            error_msg = f"Chart generation failed: {str(chart_error)}"
            
            logger.error(f"[{chart_id}] Chart generation error after {generation_time:.2f}s: {str(chart_error)}")
            
            return jsonify({
                'error': 'Chart generation failed',
                'message': error_msg,
                'success': False,
                'generation_time': round(generation_time, 2),
                'chart_id': chart_id
            }), 500
            
    except Exception as e:
        generation_time = time.time() - start_time
        logger.error(f"[{chart_id}] Unexpected error after {generation_time:.2f}s: {str(e)}", exc_info=True)
        
        return jsonify({
            'error': 'Unexpected error',
            'message': 'An unexpected error occurred during chart generation.',
            'success': False,
            'generation_time': round(generation_time, 2),
            'chart_id': chart_id
        }), 500


@insights_bp.route('/insights/feedback', methods=['POST'])
@login_required
@require_app_access('Insights')
def submit_user_feedback():
    """
    Handle user feedback submissions for specific requests.
    
    Processes feedback with request tracking and returns confirmation.
    
    Returns:
        JSON: Feedback submission confirmation and status
    """
    feedback_start_time = time.time()
    feedback_id = f"feedback_{int(time.time())}_{request.environ.get('REMOTE_ADDR', 'unknown')[-3:]}"
    
    try:
        # Parse request data
        if not request.is_json:
            logger.error(f"[{feedback_id}] Invalid request format - not JSON")
            return jsonify({
                'error': 'Invalid request format',
                'message': 'Request must be JSON'
            }), 400
        
        data = request.get_json()
        request_id = data.get('request_id', '').strip()
        positive = data.get('positive')
        message = data.get('message', '').strip() or None
        
        # Input validation
        if not request_id:
            logger.warning(f"[{feedback_id}] Missing request_id in feedback submission")
            return jsonify({
                'error': 'Invalid input',
                'message': 'Request ID is required'
            }), 400
        
        if not isinstance(positive, bool):
            logger.warning(f"[{feedback_id}] Invalid positive flag in feedback: {positive}")
            return jsonify({
                'error': 'Invalid input',
                'message': 'Feedback type (positive/negative) is required'
            }), 400
        
        # Check if feedback already submitted for this request
        if insights_session.is_feedback_submitted(request_id):
            logger.warning(f"[{feedback_id}] Feedback already submitted for request: {request_id}")
            return jsonify({
                'error': 'Already submitted',
                'message': 'Feedback has already been submitted for this request'
            }), 409
        
        logger.info(f"[{feedback_id}] Submitting {'positive' if positive else 'negative'} feedback for request: {request_id}")
        
        try:
            # Submit feedback through service
            feedback_result = submit_feedback(
                request_id=request_id,
                positive=positive,
                message=message
            )
            
            # Track feedback in session to prevent duplicates
            feedback_data = {
                'positive': positive,
                'message': message,
                'feedback_id': feedback_result.get('feedback_id')
            }
            insights_session.track_feedback_submission(request_id, feedback_data)
            
            submission_time = time.time() - feedback_start_time
            logger.info(f"[{feedback_id}] Feedback submitted successfully in {submission_time:.2f}s")
            
            return jsonify({
                'success': True,
                'feedback_id': feedback_result.get('feedback_id'),
                'message': 'Thank you for your feedback!',
                'submission_time': round(submission_time, 2)
            })
            
        except Exception as feedback_error:
            submission_time = time.time() - feedback_start_time
            error_msg = str(feedback_error)
            
            logger.error(f"[{feedback_id}] Feedback submission error after {submission_time:.2f}s: {str(feedback_error)}")
            
            return jsonify({
                'error': 'Feedback submission failed',
                'message': error_msg,
                'submission_time': round(submission_time, 2)
            }), 500
            
    except Exception as e:
        submission_time = time.time() - feedback_start_time
        logger.error(f"[{feedback_id}] Unexpected error after {submission_time:.2f}s: {str(e)}", exc_info=True)
        
        return jsonify({
            'error': 'Unexpected error',
            'message': 'An unexpected error occurred while submitting feedback.',
            'submission_time': round(submission_time, 2)
        }), 500


@insights_bp.route('/insights/reset', methods=['POST'])
@login_required
@require_app_access('Insights')
def reset_conversation():
    """
    Reset conversation session and clear history.
    
    Clears chat messages while preserving domain selection and user preferences.
    
    Returns:
        JSON: Reset confirmation and status
    """
    reset_start_time = time.time()
    reset_id = f"reset_{int(time.time())}_{request.environ.get('REMOTE_ADDR', 'unknown')[-3:]}"
    
    try:
        # Parse optional request data
        preserve_domain = True
        use_chat_history = None
        
        if request.is_json:
            data = request.get_json()
            preserve_domain = data.get('preserve_domain', True)
            use_chat_history = data.get('use_chat_history')
        
        # Handle chat history preference update
        if use_chat_history is not None:
            insights_session.set_chat_history_preference(use_chat_history)
            logger.info(f"[{reset_id}] Chat history preference updated to: {use_chat_history}")
            return jsonify({
                'success': True,
                'message': f'Chat history {"enabled" if use_chat_history else "disabled"}',
                'use_chat_history': use_chat_history
            })
        
        logger.info(f"[{reset_id}] Resetting conversation [preserve_domain: {preserve_domain}]")
        
        # Get current domain before reset
        current_domain = insights_session.get_domain_selection().get('domain', 'policy')
        
        # Clear conversation but preserve domain if requested
        insights_session.clear_conversation(preserve_domain=preserve_domain)
        
        # Add welcome message for fresh start
        try:
            # Try to get cached domains for welcome message
            domains_data = get_cached_domains()
            if not domains_data:
                domains_data = get_available_domains()
                cache_domains(domains_data)
            
            welcome_message = _create_welcome_message(current_domain, domains_data)
            insights_session.add_chat_message(welcome_message)
            insights_session.mark_welcome_shown()
            
        except Exception as welcome_error:
            logger.warning(f"[{reset_id}] Could not create welcome message: {str(welcome_error)}")
        
        reset_time = time.time() - reset_start_time
        logger.info(f"[{reset_id}] Conversation reset successfully in {reset_time:.2f}s")
        
        return jsonify({
            'success': True,
            'message': 'Conversation reset successfully',
            'current_domain': current_domain,
            'reset_time': round(reset_time, 2)
        })
        
    except Exception as e:
        reset_time = time.time() - reset_start_time
        logger.error(f"[{reset_id}] Error resetting conversation: {str(e)}", exc_info=True)
        return jsonify({
            'success': False,
            'error': 'Reset failed',
            'message': str(e),
            'reset_time': round(reset_time, 2)
        }), 500


@insights_bp.route('/insights/switch-domain', methods=['POST'])
@login_required
@require_app_access('Insights')
def switch_domain():
    """
    Switch to a different domain and update welcome message if only welcome exists.
    
    If the conversation only has the welcome message (no user interactions),
    update it with new example questions for the selected domain.
    
    Returns:
        JSON: Domain switch confirmation and updated messages if applicable
    """
    switch_start_time = time.time()
    switch_id = f"switch_{int(time.time())}_{request.environ.get('REMOTE_ADDR', 'unknown')[-3:]}"
    
    try:
        data = request.get_json()
        new_domain = data.get('domain')
        
        if not new_domain:
            return jsonify({
                'success': False,
                'error': 'Missing domain parameter'
            }), 400
        
        logger.info(f"[{switch_id}] Switching to domain: '{new_domain}'")
        
        # Get current messages
        chat_messages = insights_session.get_chat_messages()
        
        # Check if we should update the welcome message
        # Only update if there's exactly 1 message and it's the welcome message
        should_update_welcome = (
            len(chat_messages) == 1 and 
            chat_messages[0].get('role') == 'assistant' and
            chat_messages[0].get('is_welcome', False)
        )
        
        logger.info(f"[{switch_id}] Should update welcome: {should_update_welcome} (messages: {len(chat_messages)})")
        
        # Update domain selection
        insights_session.set_domain_selection(new_domain)
        
        # If only welcome message exists, update it with new domain questions
        if should_update_welcome:
            try:
                # Get domains data
                domains_data = get_cached_domains()
                if not domains_data:
                    domains_data = get_available_domains()
                    cache_domains(domains_data)
                
                # Create new welcome message for the new domain
                new_welcome_message = _create_welcome_message(new_domain, domains_data)
                
                # Clear current messages and add new welcome
                insights_session.clear_conversation(preserve_domain=True)
                insights_session.add_chat_message(new_welcome_message)
                insights_session.mark_welcome_shown()
                
                logger.info(f"[{switch_id}] Updated welcome message for domain '{new_domain}'")
                
                switch_time = time.time() - switch_start_time
                return jsonify({
                    'success': True,
                    'domain': new_domain,
                    'welcome_updated': True,
                    'message': f'Switched to {new_domain} domain with updated suggestions',
                    'switch_time': round(switch_time, 2)
                })
                
            except Exception as welcome_error:
                logger.warning(f"[{switch_id}] Could not update welcome message: {str(welcome_error)}")
                # Continue anyway, domain selection was updated
        
        # Domain switched but no welcome update needed
        switch_time = time.time() - switch_start_time
        return jsonify({
            'success': True,
            'domain': new_domain,
            'welcome_updated': False,
            'message': f'Switched to {new_domain} domain',
            'switch_time': round(switch_time, 2)
        })
        
    except Exception as e:
        switch_time = time.time() - switch_start_time
        logger.error(f"[{switch_id}] Error switching domain: {str(e)}", exc_info=True)
        
        return jsonify({
            'success': False,
            'error': 'Domain switch failed',
            'message': str(e),
            'switch_time': round(switch_time, 2)
        }), 500


@insights_bp.route('/insights/cache/stats', methods=['GET'])
@login_required
@require_app_access('Insights')
def get_cache_stats():
    """
    Get cache statistics and information.
    
    Returns cache usage statistics, hit rates, and stored items information.
    """
    try:
        stats = insights_session.get_cache_stats()
        logger.info("Cache stats requested")
        
        return jsonify({
            'success': True,
            'cache_stats': stats
        })
        
    except Exception as e:
        logger.error(f"Error retrieving cache stats: {str(e)}", exc_info=True)
        return jsonify({
            'error': 'Cache stats retrieval failed',
            'message': 'Unable to retrieve cache statistics'
        }), 500


@insights_bp.route('/insights/cache/clear', methods=['POST'])
@login_required
@require_app_access('Insights')
def clear_cache():
    """
    Clear all cached results.
    
    Removes all cached query results from the session.
    """
    try:
        insights_session.clear_result_cache()
        logger.info("Cache cleared by user request")
        
        return jsonify({
            'success': True,
            'message': 'Cache cleared successfully'
        })
        
    except Exception as e:
        logger.error(f"Error clearing cache: {str(e)}", exc_info=True)
        return jsonify({
            'error': 'Cache clear failed',
            'message': 'Unable to clear cache'
        }), 500


@insights_bp.route('/insights/domains')
@login_required
@require_app_access('Insights')
def get_domains():
    """
    AJAX endpoint to get available domains.
    
    Returns JSON with domain information and model counts for UI updates.
    
    Returns:
        JSON: Available domains with metadata and model information
    """
    domains_start_time = time.time()
    domains_request_id = f"domains_{int(time.time())}_{request.environ.get('REMOTE_ADDR', 'unknown')[-3:]}"
    
    try:
        logger.debug(f"[{domains_request_id}] Fetching available domains")
        
        # Try cached data first
        domains_data = get_cached_domains()
        
        if not domains_data:
            logger.debug(f"[{domains_request_id}] Cache miss - fetching from API")
            domains_data = get_available_domains()
            cache_domains(domains_data)
        else:
            logger.debug(f"[{domains_request_id}] Using cached domain data")
        
        # Format for UI consumption
        formatted_domains = {}
        for domain_key, domain_info in domains_data.get('domains', {}).items():
            formatted_domains[domain_key] = {
                'name': domain_info.get('name', domain_key.title()),
                'description': domain_info.get('description', ''),
                'model_count': len(domain_info.get('semantic_views', [])),
                'models': domain_info.get('semantic_views', [])
            }
        
        fetch_time = time.time() - domains_start_time
        logger.info(f"[{domains_request_id}] Domains fetched successfully in {fetch_time:.2f}s")
        
        return jsonify({
            'success': True,
            'domains': formatted_domains,
            'total_domains': len(formatted_domains),
            'total_models': sum(d['model_count'] for d in formatted_domains.values()),
            'fetch_time': round(fetch_time, 2)
        })
        
    except Exception as e:
        fetch_time = time.time() - domains_start_time
        logger.error(f"[{domains_request_id}] Error fetching domains after {fetch_time:.2f}s: {str(e)}", exc_info=True)
        
        # Return fallback domains on error
        fallback_domains = {
            'policy': {'name': 'Policy', 'description': 'Policy data analysis', 'model_count': 0, 'models': []},
            'sales': {'name': 'Sales', 'description': 'Sales performance analysis', 'model_count': 0, 'models': []},
            'claims': {'name': 'Claims', 'description': 'Claims processing analysis', 'model_count': 0, 'models': []},
            'others': {'name': 'Others', 'description': 'General business metrics', 'model_count': 0, 'models': []}
        }
        
        return jsonify({
            'success': False,
            'domains': fallback_domains,
            'total_domains': 4,
            'total_models': 0,
            'error': 'Could not fetch current domain information',
            'fetch_time': round(fetch_time, 2)
        }), 206  # Partial content - fallback data


@insights_bp.route('/insights/health')
@login_required
@require_app_access('Insights')
def health_check():
    """
    Health check endpoint for Insights module and API connectivity.
    
    Returns:
        JSON: Health status and connectivity information
    """
    try:
        # Check API health
        api_health = get_api_health()
        
        return jsonify({
            'success': True,
            'module': 'Insights',
            'status': 'healthy',
            'api_status': api_health
        })
        
    except Exception as e:
        logger.error(f"[INSIGHTS_HEALTH] Health check failed: {str(e)}")
        
        return jsonify({
            'success': False,
            'module': 'Insights',
            'status': 'unhealthy',
            'error': str(e)
        }), 503


def _create_welcome_message(domain: str, domains_data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Create a welcome message for the specified domain.
    
    Fetches example questions from the API dynamically instead of using hardcoded values.
    
    Args:
        domain (str): Selected domain
        domains_data (Dict[str, Any]): Available domains information
        
    Returns:
        Dict[str, Any]: Welcome message structure for chat
    """
    domain_info = domains_data.get('domains', {}).get(domain, {})
    domain_name = domain_info.get('name', domain.title())
    models_count = len(domain_info.get('semantic_views', []))
    
    # Get example questions from API (3 random questions)
    try:
        questions = get_example_questions(domain, count=3)
        logger.info(f"[WELCOME_MESSAGE] Retrieved {len(questions)} example questions for domain '{domain}': {questions}")
    except Exception as e:
        logger.warning(f"Failed to fetch example questions for domain '{domain}': {e}")
        logger.exception(e)  # Log full traceback
        # Fallback to empty list if API fails
        questions = []
    
    welcome_text = f"""Welcome to Insights! 🎯

I'm your AI analytics assistant. I can help you analyze your {domain_name} data using natural language questions. 

Currently, I have access to {models_count} semantic model{'s' if models_count != 1 else ''} in this domain.

Try asking questions like:"""
    
    return {
        'role': 'assistant',
        'content': [
            {'type': 'text', 'text': welcome_text},
            {'type': 'suggestions', 'suggestions': questions}
        ],
        'is_welcome': True,
        'domain': domain
    }