// ============================================================================
// INSIGHTS MODULE - JavaScript for Insights Chat Interface
// ============================================================================
// This file contains all Insights-specific functionality for the AI Analytics module.
// It depends on utility functions from main.js (escapeHtml, scrollToBottom, downloadFile)
// ============================================================================

// ============================================================================
// CHART PARAMETERS CONFIGURATION
// ============================================================================
// Defines UI parameters, labels, and validation for each chart type

const CHART_UI_CONFIG = {
    'bar': {
        params: ['x', 'y', 'color'],
        labels: {
            'x': 'Category Column',
            'y': 'Value Column',
            'color': 'Group By (Optional)'
        },
        required: ['x', 'y'],
        optional: ['color'],
        description: 'Compare values across categories with vertical bars'
    },
    'line': {
        params: ['x', 'y', 'color'],
        labels: {
            'x': 'X-Axis Column (Time/Sequence)',
            'y': 'Y-Axis Column (Metric)',
            'color': 'Multiple Lines (Optional)'
        },
        required: ['x', 'y'],
        optional: ['color'],
        description: 'Show trends over time or sequences'
    },
    'pie': {
        params: ['names', 'values'],
        labels: {
            'names': 'Labels Column',
            'values': 'Values Column'
        },
        required: ['names', 'values'],
        optional: [],
        description: 'Show proportions of a whole'
    },
    'multi_line': {
        params: ['x', 'y', 'color'],
        labels: {
            'x': 'X-Axis Column (Time/Sequence)',
            'y': 'Y-Axis Column (Metric)',
            'color': 'Group By (Creates Lines)'
        },
        required: ['x', 'y', 'color'],
        optional: [],
        description: 'Compare multiple trends over time or sequences'
    }
};

// ============================================================================
// AVAILABLE CHART TYPES CONFIGURATION
// ============================================================================
// Single source of truth for available chart types
// Add new chart types here as they are implemented

const AVAILABLE_CHART_TYPES = {
    'bar': 'Bar Chart',
    'line': 'Line Chart',
    'pie': 'Pie Chart',
    'multi_line': 'Multi-Line Chart'
};

/**
 * Generate chart type selector options dynamically
 * @returns {string} HTML string with option elements
 */
function generateChartTypeOptions() {
    let options = '<option value="">-- Select Chart Type --</option>';
    for (const [value, label] of Object.entries(AVAILABLE_CHART_TYPES)) {
        options += `<option value="${value}">${label}</option>`;
    }
    return options;
}

/**
 * Render dynamic parameter UI based on chart type
 * @param {string} chartType - Type of chart ('bar', 'line', 'pie', 'multi_line')
 * @param {Array} availableColumns - Array of column names from data
 * @param {string} containerId - ID of container element to render UI in
 */
function renderChartParametersUI(chartType, availableColumns, containerId) {
    console.log('=== renderChartParametersUI called ===');
    console.log('chartType:', chartType);
    console.log('availableColumns:', availableColumns);
    console.log('containerId:', containerId);
    
    const container = document.getElementById(containerId);
    if (!container) {
        console.error(`Container with id '${containerId}' not found`);
        return;
    }

    // Get chart configuration
    const config = CHART_UI_CONFIG[chartType];
    console.log('Chart config for', chartType, ':', config);
    
    if (!config) {
        container.innerHTML = '<div class="parameter-error">Unknown chart type</div>';
        return;
    }

    // Clear existing content
    container.innerHTML = '';
    
    console.log('Will create', config.params.length, 'parameter fields:', config.params);

    // Create parameter rows for each parameter
    config.params.forEach(paramName => {
        console.log('Creating parameter field for:', paramName);
        const isRequired = config.required.includes(paramName);
        const isOptional = config.optional.includes(paramName);
        const label = config.labels[paramName] || paramName;

        // Create parameter row container
        const paramRow = document.createElement('div');
        paramRow.className = 'chart-parameter-row';
        paramRow.setAttribute('data-param', paramName);

        // For optional parameters, add enable checkbox
        if (isOptional) {
            const checkboxContainer = document.createElement('div');
            checkboxContainer.className = 'parameter-optional-container';
            
            const checkbox = document.createElement('input');
            checkbox.type = 'checkbox';
            checkbox.id = `enable-${paramName}-${Date.now()}`;
            checkbox.className = 'parameter-optional-checkbox';
            checkbox.title = `Enable ${label}`;
            checkbox.addEventListener('change', function() {
                const dropdown = paramRow.querySelector('.parameter-dropdown');
                dropdown.disabled = !this.checked;
                if (!this.checked) {
                    dropdown.value = '';
                }
            });
            
            const checkboxLabel = document.createElement('label');
            checkboxLabel.htmlFor = checkbox.id;
            checkboxLabel.textContent = `Enable ${label}`;
            checkboxLabel.className = 'parameter-optional-label';
            checkboxLabel.title = `Enable ${label}`;
            
            checkboxContainer.appendChild(checkbox);
            checkboxContainer.appendChild(checkboxLabel);
            paramRow.appendChild(checkboxContainer);
        }

        // Create label
        const labelEl = document.createElement('label');
        labelEl.className = 'parameter-label';
        labelEl.textContent = label;
        if (isRequired) {
            const asterisk = document.createElement('span');
            asterisk.className = 'required-asterisk';
            asterisk.textContent = ' *';
            asterisk.style.color = '#ef4444';
            labelEl.appendChild(asterisk);
        } else if (isOptional) {
            const optionalText = document.createElement('span');
            optionalText.className = 'optional-text';
            optionalText.textContent = ' (opt)';
            optionalText.style.color = '#9ca3af';
            optionalText.style.fontWeight = 'normal';
            optionalText.style.fontSize = '10px';
            labelEl.appendChild(optionalText);
        }
        paramRow.appendChild(labelEl);

        // Create dropdown
        const dropdown = document.createElement('select');
        dropdown.className = 'parameter-dropdown';
        dropdown.id = `param-${paramName}`;
        dropdown.setAttribute('data-param', paramName);
        
        // Disable optional parameters by default
        if (isOptional) {
            dropdown.disabled = true;
        }

        // Add empty option
        const emptyOption = document.createElement('option');
        emptyOption.value = '';
        emptyOption.textContent = '-- Select Column --';
        dropdown.appendChild(emptyOption);

        // Add column options
        availableColumns.forEach(colName => {
            const option = document.createElement('option');
            option.value = colName;
            option.textContent = colName;
            dropdown.appendChild(option);
        });

        paramRow.appendChild(dropdown);
        container.appendChild(paramRow);
        console.log('✅ Added parameter field:', paramName, 'Required:', isRequired, 'Optional:', isOptional);
    });
    
    console.log('=== Finished rendering', config.params.length, 'parameter fields ===');

    // Add description
    const description = document.createElement('div');
    description.className = 'chart-description';
    description.textContent = config.description;
    container.appendChild(description);
}

/**
 * Get chart parameters from UI
 * @param {string} containerId - ID of container with parameter UI
 * @returns {Object} Parameters object (e.g., {x: 'COLUMN1', y: 'COLUMN2', color: 'COLUMN3'})
 */
function getChartParametersFromUI(containerId) {
    console.log('=== getChartParametersFromUI called ===');
    console.log('containerId:', containerId);
    
    const container = document.getElementById(containerId);
    if (!container) {
        console.error(`Container with id '${containerId}' not found`);
        return {};
    }

    const params = {};
    const dropdowns = container.querySelectorAll('.parameter-dropdown');
    
    console.log('Found', dropdowns.length, 'parameter dropdowns in container');
    
    dropdowns.forEach(dropdown => {
        const paramName = dropdown.getAttribute('data-param');
        const value = dropdown.value;
        const disabled = dropdown.disabled;
        
        console.log(`Dropdown ${paramName}: value='${value}', disabled=${disabled}`);
        
        // Only include if not disabled and has value
        if (!dropdown.disabled && value) {
            params[paramName] = value;
            console.log(`✅ Including ${paramName} = ${value}`);
        } else {
            console.log(`⏭️  Skipping ${paramName} (disabled=${disabled}, has value=${!!value})`);
        }
    });

    console.log('Final params:', params);
    console.log('=== getChartParametersFromUI finished ===');
    return params;
}

/**
 * Validate chart parameters before sending to backend
 * @param {string} chartType - Type of chart
 * @param {Object} params - Parameters object
 * @returns {Object} {isValid: boolean, error: string}
 */
function validateChartParameters(chartType, params) {
    const config = CHART_UI_CONFIG[chartType];
    if (!config) {
        return { isValid: false, error: `❌ Unknown chart type: ${chartType}` };
    }

    // Check required parameters
    const missingParams = [];
    config.required.forEach(paramName => {
        if (!params[paramName]) {
            const label = config.labels[paramName] || paramName;
            missingParams.push(label);
        }
    });

    if (missingParams.length > 0) {
        let errorMsg = `❌ Missing required parameters:\n`;
        missingParams.forEach(param => {
            errorMsg += `  • ${param}\n`;
        });
        errorMsg += `\n💡 Tip: All required fields must be selected before generating the chart.`;
        
        return {
            isValid: false,
            error: errorMsg
        };
    }

    return { isValid: true, error: null };
}

/**
 * Handle chart type change event
 * @param {HTMLSelectElement} selectElement - The chart type selector element
 */
function handleChartTypeChange(selectElement) {
    const chartType = selectElement.value;
    const container = selectElement.closest('.chart-container');
    
    if (!container) {
        console.error('Chart container not found');
        return;
    }
    
    // Find or create parameters container
    let parametersContainer = container.querySelector('.chart-parameters');
    
    if (!parametersContainer) {
        // Create parameters container if it doesn't exist
        const chartHeader = container.querySelector('.chart-header');
        if (chartHeader) {
            parametersContainer = document.createElement('div');
            parametersContainer.className = 'chart-parameters';
            parametersContainer.id = `chartParameters-${Date.now()}`;
            chartHeader.insertAdjacentElement('afterend', parametersContainer);
        } else {
            console.error('Chart header not found');
            return;
        }
    }
    
    // Clear previous parameters
    parametersContainer.innerHTML = '';
    
    if (!chartType) {
        // No chart type selected, show message
        parametersContainer.innerHTML = '<div class="parameter-info">Select a chart type to configure parameters</div>';
        return;
    }
    
    // Get available columns from data
    const dataKey = container.getAttribute('data-chart-key');
    const sqlResultJson = container.getAttribute('data-sql-result');
    
    let columns = [];
    
    if (dataKey && window[dataKey]) {
        const queryResult = window[dataKey];
        columns = queryResult.columns || [];
    } else if (sqlResultJson) {
        try {
            const sqlResults = JSON.parse(sqlResultJson);
            columns = sqlResults.columns || [];
        } catch (e) {
            console.error('Failed to parse SQL result data:', e);
        }
    } else if (window.lastSqlResult && window.lastSqlResult.columns) {
        // Fallback to last SQL result
        columns = window.lastSqlResult.columns;
        console.log('Using columns from window.lastSqlResult:', columns);
    }
    
    if (columns.length === 0) {
        parametersContainer.innerHTML = '<div class="parameter-error">No columns available for chart configuration. Please execute a query first.</div>';
        return;
    }
    
    // Render parameter UI for selected chart type
    console.log(`Rendering chart parameters UI for ${chartType} with ${columns.length} columns:`, columns);
    renderChartParametersUI(chartType, columns, parametersContainer.id);
}

/**
 * Initialize Insights chat interface
 */
function initializeInsights() {
    const messageInput = $('#messageInput');
    const sendBtn = $('#sendBtn');
    const resetBtn = $('#resetBtn');
    
    // Enable/disable send button based on input
    messageInput.on('input', function() {
        const hasText = $(this).val().trim() !== '';
        sendBtn.prop('disabled', !hasText);
    });
    
    // Handle domain selector change
    $('#domainSelector').on('change', function() {
        const selectedDomain = $(this).val();
        updateCurrentDomain(selectedDomain);
    });
    
    // Initialize current domain from dropdown
    const currentDomain = $('#domainSelector').val();
    if (currentDomain) {
        window.InsightsConfig.currentDomain = currentDomain;
    }
    
    // Send message on Enter key (Shift+Enter for new line)
    messageInput.on('keypress', function(e) {
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            if (!sendBtn.prop('disabled')) {
                sendMessage();
            }
        }
    });
    
    // Send message on button click
    sendBtn.on('click', function(e) {
        e.preventDefault();
        sendMessage();
    });
    
    // Reset conversation on button click
    if (resetBtn.length) {
        resetBtn.on('click', function(e) {
            e.preventDefault();
            resetConversation();
        });
    }
    
    // Handle chat history checkbox change
    $('#chatHistoryCheck').on('change', function() {
        const useChatHistory = $(this).is(':checked');
        updateChatHistorySetting(useChatHistory);
    });
    
    // Auto-resize textarea
    messageInput.on('input', function() {
        this.style.height = 'auto';
        this.style.height = Math.min(this.scrollHeight, 120) + 'px';
    });
    
    // Focus input on page load
    setTimeout(() => messageInput.focus(), 500);
    
    // Auto-scroll to bottom on load
    scrollToBottom();
    
    // Initialize chart type selectors with dynamic options
    initializeChartTypeSelectors();
    
    // Handle suggestion pill clicks with event delegation
    $(document).on('click', '.suggestion-pill', function(e) {
        e.preventDefault();
        const suggestion = $(this).data('suggestion');
        if (suggestion) {
            sendSuggestedMessage(suggestion);
        }
    });
}

/**
 * Initialize all chart type selectors with dynamic options
 */
function initializeChartTypeSelectors() {
    const selectors = document.querySelectorAll('.chart-type-selector');
    const options = generateChartTypeOptions();
    
    selectors.forEach(selector => {
        const previousValue = selector.value;
        selector.innerHTML = options;
        
        // If there was a previous value, restore it and trigger parameter rendering
        if (previousValue) {
            selector.value = previousValue;
            console.log(`Restoring chart type selector value: ${previousValue}`);
            // Trigger handleChartTypeChange to render parameters
            handleChartTypeChange(selector);
        }
    });
    
    console.log(`Initialized ${selectors.length} chart type selector(s) with available chart types:`, Object.keys(AVAILABLE_CHART_TYPES));
}

/**
 * Update current domain in config
 */
function updateCurrentDomain(domain) {
    window.InsightsConfig.currentDomain = domain;
    
    // Call backend to switch domain and update welcome message if needed
    $.ajax({
        url: window.InsightsConfig.endpoints.switchDomain,
        method: 'POST',
        data: JSON.stringify({
            domain: domain
        }),
        contentType: 'application/json',
        success: function(response) {
            if (response.success && response.welcome_updated) {
                // Welcome message was updated, reload the page silently to show new questions
                console.log('Domain switched and welcome updated, reloading...');
                window.location.reload();
            } else {
                console.log('Domain switched:', response.domain);
            }
        },
        error: function(xhr, status, error) {
            console.error('Error switching domain:', error);
            // Don't show error to user, domain selector will still work for next queries
        }
    });
}

/**
 * Update chat history setting
 */
function updateChatHistorySetting(useChatHistory) {
    $.ajax({
        url: window.InsightsConfig.endpoints.reset,
        method: 'POST',
        timeout: 10000,
        headers: {
            'X-CSRFToken': window.InsightsConfig.csrfToken
        },
        data: JSON.stringify({
            use_chat_history: useChatHistory
        }),
        contentType: 'application/json',
        success: function(data) {
            if (data.success) {
                const status = useChatHistory ? 'enabled' : 'disabled';
                showToast(`Chat history ${status}`);
                console.log('Chat history setting updated:', useChatHistory);
            }
        },
        error: function() {
            console.error('Error updating chat history setting');
        }
    });
}

/**
 * Reset conversation
 */
function resetConversation() {
    if (!confirm('Are you sure you want to reset the conversation? This will clear all chat messages.')) {
        return;
    }
    
    const resetBtn = $('#resetBtn');
    const originalText = resetBtn.html();
    
    // Show loading state
    resetBtn.prop('disabled', true).html('<i class="fas fa-spinner fa-spin"></i> Resetting...');
    
    $.ajax({
        url: window.InsightsConfig.endpoints.reset,
        method: 'POST',
        timeout: 10000,
        headers: {
            'X-CSRFToken': window.InsightsConfig.csrfToken
        },
        data: JSON.stringify({
            preserve_domain: true
        }),
        contentType: 'application/json',
        success: function(data) {
            if (data.success) {
                $('#chatMessages').empty();
                window.InsightsConfig.conversationId = '';
                showToast('Conversation reset successfully!');
                
                setTimeout(() => {
                    window.location.reload();
                }, 1000);
            } else {
                showToast('Failed to reset conversation', 'error');
                resetBtn.prop('disabled', false).html(originalText);
            }
        },
        error: function() {
            showToast('Error resetting conversation', 'error');
            resetBtn.prop('disabled', false).html(originalText);
        }
    });
}

/**
 * Handle suggested message click - populate input field
 */
function sendSuggestedMessage(suggestion) {
    const messageInput = $('#messageInput');
    
    messageInput.val(suggestion);
    messageInput.trigger('input');
    messageInput.focus();
    messageInput[0].scrollIntoView({ behavior: 'smooth', block: 'center' });
}

// Global variable to track pending AJAX request
let currentQueryRequest = null;
let isSendingMessage = false;

/**
 * Send message to AI
 */
function sendMessage() {
    const messageInput = $('#messageInput');
    const message = messageInput.val().trim();
    
    if (!message) return;
    
    if (isSendingMessage) {
        console.log('Message send already in progress, ignoring duplicate call');
        return;
    }
    
    if (currentQueryRequest && currentQueryRequest.readyState !== 4) {
        console.log('Aborting previous query request');
        currentQueryRequest.abort();
        currentQueryRequest = null;
    }
    
    isSendingMessage = true;
    
    appendUserMessage(message);
    
    messageInput.val('').css('height', 'auto');
    $('#sendBtn').prop('disabled', true);
    showTypingIndicator();
    
    $.ajax({
        url: window.InsightsConfig.endpoints.domainModels + '/' + window.InsightsConfig.currentDomain + '/models',
        method: 'GET',
        timeout: 30000,
        success: function(response) {
            const semanticModels = response.models.map(model => ({
                semantic_view: model.full_path,
                name: model.name,
                description: model.description
            }));
            
            currentQueryRequest = $.ajax({
                url: window.InsightsConfig.endpoints.query,
                method: 'POST',
                timeout: 240000,
                headers: {
                    'X-CSRFToken': window.InsightsConfig.csrfToken
                },
                data: JSON.stringify({
                    question: message,
                    domain: window.InsightsConfig.currentDomain,
                    semantic_models: semanticModels,
                    conversation_id: window.InsightsConfig.conversationId
                }),
                contentType: 'application/json',
                beforeSend: function(jqXHR) {
                    console.log('Starting new query request');
                },
                success: function(data) {
                    console.log('Query response received:', {
                        success: data.success,
                        has_response: !!data.response,
                        has_sql_results: !!data.sql_results,
                        processing_time: data.processing_time,
                        response_size: JSON.stringify(data).length
                    });
                    
                    hideTypingIndicator();
                    
                    if (data.success) {
                        if (data.conversation_id) {
                            window.InsightsConfig.conversationId = data.conversation_id;
                        }
                        
                        if (data.export_data) {
                            window.lastExportData = data.export_data;
                            console.log('Export data available for download');
                        }
                        
                        appendAssistantMessage(data.response, data.request_id, data.sql_results, data.sql_execution_error);
                        
                        if (data.processing_time && data.query_generation_time) {
                            console.log(`Query processed in ${data.query_generation_time}s, total time: ${data.processing_time}s`);
                        }
                    } else {
                        console.error('Query returned success=false:', data.error);
                        appendErrorMessage(data.error || 'An error occurred while processing your request.');
                    }
                },
                error: function(xhr, status, error) {
                    hideTypingIndicator();
                    
                    console.error('AJAX Error Details:', {
                        status: status,
                        error: error,
                        xhr_status: xhr.status,
                        xhr_statusText: xhr.statusText,
                        responseText: xhr.responseText ? xhr.responseText.substring(0, 500) : 'empty',
                        readyState: xhr.readyState
                    });
                    
                    let errorMessage = 'Unable to send message. Please check your connection and try again.';
                    
                    if (status === 'timeout') {
                        errorMessage = 'Request timed out. The query is taking longer than expected. Please try a simpler question.';
                    } else if (status === 'abort') {
                        console.log('Request was intentionally aborted (new query started)');
                        return;
                    } else if (status === 'parsererror') {
                        errorMessage = 'Invalid response from server. Please try again.';
                        console.error('Parser error - Response text:', xhr.responseText);
                    } else if (xhr.responseJSON && xhr.responseJSON.message) {
                        errorMessage = xhr.responseJSON.message;
                    } else if (xhr.responseText) {
                        try {
                            const response = JSON.parse(xhr.responseText);
                            if (response.message) {
                                errorMessage = response.message;
                            } else if (response.error) {
                                errorMessage = response.error;
                            }
                        } catch (e) {
                            console.error('Failed to parse error response:', e);
                        }
                    }
                    
                    appendErrorMessage(errorMessage);
                    console.error('Query error:', error);
                },
                complete: function(jqXHR, textStatus) {
                    isSendingMessage = false;
                    currentQueryRequest = null;
                    
                    console.log('Query request completed with status:', textStatus);
                    $('#sendBtn').prop('disabled', false);
                    scrollToBottom();
                }
            });
        },
        error: function(xhr, status, error) {
            hideTypingIndicator();
            
            isSendingMessage = false;
            currentQueryRequest = null;
            
            appendErrorMessage('Failed to load semantic models for the selected domain.');
            $('#sendBtn').prop('disabled', false);
            scrollToBottom();
            console.error('Domain models error:', error);
        }
    });
}

/**
 * Add user message to chat
 */
function appendUserMessage(message) {
    $('.welcome-message').remove();
    
    const userMessage = `
        <div class="message-wrapper user-message fade-in">
            <div class="user-message-content">
                ${escapeHtml(message)}
            </div>
            <div class="message-avatar user-avatar">
                <i class="fa-solid fa-user"></i>
            </div>
        </div>
    `;
    
    $('#chatMessages').append(userMessage);
    scrollToBottom();
}

/**
 * Add assistant message to chat
 */
function appendAssistantMessage(content, requestId, sqlResults, sqlExecutionError) {
    let messageHtml = `
        <div class="message-wrapper assistant-message fade-in" data-request-id="${requestId || ''}">
            <div class="message-avatar assistant-avatar">
                <i class="fas fa-robot"></i>
            </div>
            <div class="message-content">
    `;
    
    if (typeof content === 'string') {
        messageHtml += `<div class="message-text">${formatMessageText(content)}</div>`;
    } else if (Array.isArray(content)) {
        let suggestions = [];
        let hasSqlQuery = false;
        
        content.forEach(item => {
            if (item.type === 'text') {
                messageHtml += `<div class="message-text">${formatMessageText(item.text)}</div>`;
            } else if (item.type === 'suggestions' && item.suggestions) {
                suggestions = item.suggestions;
            } else if (item.type === 'sql' && item.statement) {
                hasSqlQuery = true;
                messageHtml += `
                    <div class="sql-code-block collapsed">
                        <div class="sql-header" onclick="toggleSqlVisibility(this)">
                            <span>SQL Query</span>
                            <div class="sql-header-buttons">
                                <button class="copy-sql-btn" onclick="event.stopPropagation(); copySQLQuery(this)">
                                    <i class="fas fa-copy"></i>
                                    Copy
                                </button>
                                <button class="sql-toggle-btn">
                                    <i class="fas fa-chevron-down"></i> Show Query
                                </button>
                            </div>
                        </div>
                        <div class="sql-content" style="display: none;">${escapeHtml(item.statement)}</div>
                    </div>
                `;
            }
        });
        
        if (hasSqlQuery) {
            if (sqlResults) {
                messageHtml += createResultsDisplay(sqlResults);
            } else if (sqlExecutionError) {
                messageHtml += `
                    <div class="error-message sql-error">
                        <strong>SQL Execution Error:</strong> ${escapeHtml(sqlExecutionError)}
                    </div>
                `;
            } else {
                messageHtml += `
                    <div class="info-message">
                        <i class="fas fa-info-circle"></i> Query generated successfully. Results will appear above when executed.
                    </div>
                `;
            }
        }
        
        if (suggestions.length > 0) {
            messageHtml += `
                <div class="suggestions-section" style="margin-top: 20px;">
                    <h4 class="suggestions-title" style="font-size: 14px; font-weight: 600; color: #d4af37; margin-bottom: 12px; display: flex; align-items: center; gap: 6px;">
                        <i class="fas fa-lightbulb" style="color: #f59e0b;"></i>
                        Suggested Questions
                    </h4>
                    <div class="suggestion-pills" style="display: flex; flex-wrap: wrap; gap: 8px;">`;
            suggestions.forEach(suggestion => {
                messageHtml += `<span class="suggestion-pill" onclick="handleSuggestedReply('${escapeHtml(suggestion)}')">${escapeHtml(suggestion)}</span>`;
            });
            messageHtml += `
                    </div>
                </div>`;
        }
    }
    
    if (requestId) {
        messageHtml += `
            <div class="feedback-controls" style="display: flex;">
                <button class="feedback-btn positive" onclick="submitQuickFeedback('${requestId}', true)" title="Helpful">
                    <i class="fas fa-thumbs-up"></i>
                </button>
                <button class="feedback-btn negative" onclick="submitQuickFeedback('${requestId}', false)" title="Not helpful">
                    <i class="fas fa-thumbs-down"></i>
                </button>
            </div>
        `;
    }
    
    messageHtml += `
            </div>
        </div>
    `;
    
    $('#chatMessages').append(messageHtml);
    scrollToBottom();
}

/**
 * Add error message to chat
 */
function appendErrorMessage(errorText) {
    const errorMessage = `
        <div class="message-wrapper assistant-message fade-in">
            <div class="message-avatar assistant-avatar">
                <i class="fas fa-exclamation-triangle"></i>
            </div>
            <div class="message-content">
                <div class="error-message">
                    <strong>Error:</strong> ${escapeHtml(errorText)}
                </div>
            </div>
        </div>
    `;
    
    $('#chatMessages').append(errorMessage);
    scrollToBottom();
}

/**
 * Show typing indicator
 */
function showTypingIndicator() {
    hideTypingIndicator();
    
    const typingHtml = `
        <div class="message-wrapper assistant-message typing-message" id="typingIndicator">
            <div class="message-avatar assistant-avatar">
                <i class="fas fa-robot"></i>
            </div>
            <div class="message-content">
                <div class="typing-indicator">
                    <span>AI is thinking</span>
                    <div class="loading-dots">
                        <div class="loading-dot"></div>
                        <div class="loading-dot"></div>
                        <div class="loading-dot"></div>
                    </div>
                </div>
            </div>
        </div>
    `;
    
    $('#chatMessages').append(typingHtml);
    scrollToBottom();
}

/**
 * Hide typing indicator
 */
function hideTypingIndicator() {
    $('#typingIndicator').remove();
}

/**
 * Format message text with basic HTML support
 */
function formatMessageText(text) {
    return text
        .replace(/\n/g, '<br>')
        .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
        .replace(/\*(.*?)\*/g, '<em>$1</em>')
        .replace(/`(.*?)`/g, '<code>$1</code>');
}

// ============================================================================
// GLOBAL FUNCTIONS (called from template)
// ============================================================================

/**
 * Handle suggested reply click
 */
function handleSuggestedReply(suggestion) {
    if (isSendingMessage) {
        console.log('Message send in progress, ignoring suggestion click');
        return;
    }
    
    const messageInput = $('#messageInput');
    messageInput.val(suggestion).focus();
    $('#sendBtn').prop('disabled', false);
    
    setTimeout(() => {
        if (messageInput.val().trim() === suggestion && !isSendingMessage) {
            sendMessage();
        }
    }, 300);
}

// Global variable to store feedback context
window.feedbackContext = {
    requestId: null,
    positive: null,
    messageWrapper: null
};

/**
 * Submit quick feedback (thumbs up/down) - Shows modal for optional comment
 */
function submitQuickFeedback(requestId, positive) {
    console.log('[FEEDBACK] Opening feedback modal:', requestId, positive);
    
    const messageWrapper = $(`[data-request-id="${requestId}"]`);
    if (!messageWrapper.length) {
        console.error('[FEEDBACK] Message wrapper not found for request:', requestId);
        return;
    }
    
    // Store context for later use
    window.feedbackContext = {
        requestId: requestId,
        positive: positive,
        messageWrapper: messageWrapper
    };
    
    // Update modal content based on feedback type
    const modalTitle = positive ? 
        '<i class="fas fa-thumbs-up" style="color: #16a34a; margin-right: 8px;"></i>Thanks for the positive feedback!' : 
        '<i class="fas fa-thumbs-down" style="color: #dc2626; margin-right: 8px;"></i>We\'re sorry it wasn\'t helpful';
    
    $('#feedbackModalTitle').html(modalTitle);
    $('#feedbackModalDescription').text(
        positive ? 
        'Would you like to tell us what you liked?' : 
        'Would you like to tell us how we can improve?'
    );
    
    // Reset and show modal
    $('#feedbackCommentInput').val('');
    $('#feedbackCharCount').text('0');
    $('#feedbackModal').fadeIn(200);
    
    // Focus on textarea after animation
    setTimeout(() => {
        $('#feedbackCommentInput').focus();
    }, 250);
}

/**
 * Close feedback modal
 */
function closeFeedbackModal() {
    $('#feedbackModal').fadeOut(200);
    window.feedbackContext = { requestId: null, positive: null, messageWrapper: null };
}

/**
 * Submit feedback (with or without comment)
 */
function submitFeedbackWithComment() {
    const comment = $('#feedbackCommentInput').val().trim();
    console.log('[FEEDBACK] Submitting with comment:', comment);
    // Save context before closing modal
    const context = { ...window.feedbackContext };
    console.log('[FEEDBACK] Context saved:', context);
    closeFeedbackModal();
    performFeedbackSubmission(comment || null, context);
}

/**
 * Perform the actual feedback submission
 */
function performFeedbackSubmission(comment, context) {
    // Use provided context or fall back to global context
    const feedbackContext = context || window.feedbackContext;
    const { requestId, positive, messageWrapper } = feedbackContext;
    
    if (!requestId || !messageWrapper) {
        console.error('[FEEDBACK] Invalid feedback context:', feedbackContext);
        return;
    }
    
    console.log('[FEEDBACK] Submitting feedback:', requestId, positive, comment ? 'with comment' : 'without comment');
    
    const buttons = messageWrapper.find('.feedback-btn');
    buttons.prop('disabled', true);
    
    // Prepare headers (only add CSRF token if it exists)
    const headers = {
        'Content-Type': 'application/json'
    };
    if (window.InsightsConfig && window.InsightsConfig.csrfToken) {
        headers['X-CSRFToken'] = window.InsightsConfig.csrfToken;
    }
    
    // Prepare payload
    const payload = {
        request_id: requestId,
        positive: positive
    };
    
    // Add comment only if provided
    if (comment) {
        payload.message = comment;
    }
    
    $.ajax({
        url: window.InsightsConfig.endpoints.feedback,
        method: 'POST',
        timeout: 15000,
        headers: headers,
        data: JSON.stringify(payload),
        contentType: 'application/json',
        success: function(data) {
            console.log('[FEEDBACK] Success:', data);
            
            if (data.success) {
                buttons.addClass('submitted');
                const activeBtn = messageWrapper.find(`.feedback-btn.${positive ? 'positive' : 'negative'}`);
                activeBtn.css({
                    'background': positive ? '#dcfce7' : '#fef2f2',
                    'color': positive ? '#16a34a' : '#dc2626',
                    'border-color': positive ? '#16a34a' : '#dc2626'
                });
                
                const thankYouMsg = comment ? 
                    'Thank you for your detailed feedback!' : 
                    (positive ? 'Thanks for your feedback!' : 'Feedback received!');
                showToast(thankYouMsg, 'success');
            } else {
                console.warn('[FEEDBACK] Response success=false:', data);
                showToast('Failed to submit feedback. Please try again.', 'error');
                buttons.prop('disabled', false);
            }
        },
        error: function(xhr, status, error) {
            console.error('[FEEDBACK] Error:', {xhr, status, error});
            console.error('[FEEDBACK] Response:', xhr.responseText);
            
            let errorMsg = 'Failed to submit feedback';
            if (xhr.responseJSON && xhr.responseJSON.message) {
                errorMsg = xhr.responseJSON.message;
            } else if (xhr.status === 409) {
                errorMsg = 'Feedback already submitted for this response';
            } else if (xhr.status === 401 || xhr.status === 403) {
                errorMsg = 'Authentication required. Please refresh the page.';
            }
            
            showToast(errorMsg, 'error');
            buttons.prop('disabled', false);
        }
    });
}

/**
 * Execute SQL from response
 */
function executeSQLFromResponse(sqlStatement, requestId) {
    const executeBtn = $(event.target);
    const originalText = executeBtn.html();
    
    executeBtn.prop('disabled', true).html('<i class="fas fa-spinner fa-spin"></i> Running...');
    
    $.ajax({
        url: window.InsightsConfig.endpoints.executeSQL,
        method: 'POST',
        timeout: 60000,
        headers: {
            'X-CSRFToken': window.InsightsConfig.csrfToken
        },
        data: JSON.stringify({
            query: sqlStatement,
            request_id: requestId,
            conversation_id: window.InsightsConfig.conversationId,
            generate_charts: true
        }),
        contentType: 'application/json',
        success: function(data) {
            if (data.success) {
                window.lastSqlResult = data;
                
                console.log('SQL execution successful:', {
                    rows: data.row_count,
                    columns: data.column_count,
                    hasChart: !!(data.chart && data.chart.success),
                    sampleData: data.data ? data.data.slice(0, 2) : null
                });
                
                const resultsHtml = createResultsDisplay(data);
                executeBtn.closest('.sql-code-block').after(resultsHtml);
                // Auto-scroll when new results are added
                scrollToBottom();
                
                console.log('Results display with tabs added to DOM');
            } else {
                const errorHtml = `<div class="error-message sql-error"><strong>SQL Error:</strong> ${escapeHtml(data.message || 'Execution failed')}</div>`;
                executeBtn.closest('.sql-code-block').after(errorHtml);
                // Auto-scroll when error message is added
                scrollToBottom();
            }
        },
        error: function(xhr, status, error) {
            let errorMessage = 'Unable to execute query. Please try again.';
            
            if (xhr.responseJSON && xhr.responseJSON.message) {
                errorMessage = xhr.responseJSON.message;
            } else if (xhr.responseText) {
                try {
                    const response = JSON.parse(xhr.responseText);
                    if (response.message) {
                        errorMessage = response.message;
                    }
                } catch (e) {
                    // Keep default message
                }
            }
            
            const errorHtml = `<div class="error-message sql-error"><strong>SQL Error:</strong> ${escapeHtml(errorMessage)}</div>`;
            executeBtn.closest('.sql-code-block').after(errorHtml);
            // Auto-scroll when error message is added
            scrollToBottom();
        },
        complete: function() {
            executeBtn.prop('disabled', false).html(originalText);
        }
    });
}

/**
 * Execute SQL from response using data attributes
 */
function executeSQLFromResponseData(button) {
    const sqlStatement = button.getAttribute('data-sql-statement');
    const requestId = button.getAttribute('data-request-id');
    executeSQLFromResponse(sqlStatement, requestId);
}

/**
 * Create results table HTML
 */
function createResultsTable(sqlResult, rowCount) {
    const data = sqlResult.data;
    const columns = sqlResult.columns;
    
    if (!data || !data.length || !columns || !columns.length) return '';
    
    const displayRows = Math.min(data.length, rowCount || data.length);
    let tableHtml = `
        <div class="results-table-container">
            <div class="results-header">
                <div class="results-info">${displayRows} row${displayRows !== 1 ? 's' : ''} returned</div>
                <button class="toggle-results-btn" onclick="toggleResults(this)">
                    <i class="fas fa-chevron-up"></i> Collapse
                </button>
            </div>
            <div class="results-body">
                <table class="results-table">
                    <thead><tr>
    `;
    
    columns.forEach(column => {
        tableHtml += `<th>${escapeHtml(column)}</th>`;
    });
    
    tableHtml += `</tr></thead><tbody>`;
    
    data.forEach(row => {
        tableHtml += '<tr>';
        columns.forEach(column => {
            const value = row[column];
            const cellValue = value !== null ? String(value) : 'NULL';
            const cellStyle = value === null ? 'font-style: italic; color: #6b7280;' : '';
            tableHtml += `<td style="${cellStyle}">${escapeHtml(cellValue)}</td>`;
        });
        tableHtml += '</tr>';
    });
    
    tableHtml += `</tbody></table></div></div>`;
    return tableHtml;
}

/**
 * Create chart container from chart data
 */
function createChartContainerFromData(title, chartData) {
    console.log('Creating chart container for:', title, chartData);
    
    if (!chartData || !chartData.success || !chartData.html) {
        console.error('Invalid chart data:', chartData);
        return '<div class="chart-error">Chart generation failed</div>';
    }
    
    const chartId = `chart-${Date.now()}`;
    let chartHtml = `
        <div class="chart-container" id="${chartId}" style="margin: 20px 0; padding: 20px; border: 2px solid #e5e7eb; border-radius: 8px; background: white;">
            <div class="chart-wrapper">
                <div class="chart-header" style="margin-bottom: 16px; padding-bottom: 12px; border-bottom: 1px solid #e5e7eb;">
                    <h3 class="chart-title" style="margin: 0; color: #1f2937;">${escapeHtml(title)}</h3>
                    <div class="chart-controls">
                        <select class="chart-type-selector" onchange="changeChartType(this)" style="margin-left: 10px; padding: 4px 8px;">
                            ${generateChartTypeOptions()}
                        </select>
                    </div>
                </div>
                <div class="chart-content" style="min-height: 400px;">
                    ${chartData.html}
                </div>
            </div>
        </div>
    `;
    
    if (chartData.recommendations && chartData.recommendations.length > 0) {
        chartHtml += createChartRecommendationsHTML(chartData.recommendations);
    }
    
    console.log('Generated chart HTML length:', chartHtml.length);
    return chartHtml;
}

/**
 * Create chart recommendations HTML
 */
function createChartRecommendationsHTML(recommendations) {
    let html = `
        <div class="chart-recommendations">
            <span style="font-size: 12px; font-weight: 500; color: #6b7280; margin-right: 12px;">Suggested visualizations:</span>
    `;
    
    recommendations.forEach(rec => {
        const icon = getChartIcon(rec.type);
        html += `
            <button class="chart-recommendation" onclick="changeChartTypeByRecommendation('${rec.type}')" title="${escapeHtml(rec.description)}">
                <i class="fas fa-${icon}"></i> ${escapeHtml(rec.name)}
            </button>
        `;
    });
    
    html += '</div>';
    return html;
}

/**
 * Change chart type by recommendation
 */
function changeChartTypeByRecommendation(chartType) {
    changeChartType(null, chartType);
}

/**
 * Get chart icon name
 */
function getChartIcon(chartType) {
    const icons = {
        'line': 'chart-line',
        'bar': 'chart-bar',
        'column': 'chart-column',
        'pie': 'chart-pie',
        'scatter': 'braille',
        'heatmap': 'table-cells',
        'table': 'table'
    };
    return icons[chartType] || 'chart-column';
}

/**
 * Toggle results table visibility
 */
function toggleResults(btn) {
    const resultsBody = $(btn).closest('.results-table-container').find('.results-body');
    const isVisible = resultsBody.is(':visible');
    
    resultsBody.toggle();
    
    const icon = isVisible ? 'fa-chevron-down' : 'fa-chevron-up';
    const text = isVisible ? 'Expand' : 'Collapse';
    
    $(btn).html(`<i class="fas ${icon}"></i> ${text}`);
    
}

/**
 * Toggle SQL query visibility
 */
function toggleSqlVisibility(header) {
    const sqlBlock = $(header).closest('.sql-code-block');
    const sqlContent = sqlBlock.find('.sql-content');
    const toggleBtn = sqlBlock.find('.sql-toggle-btn');
    const isVisible = sqlContent.is(':visible');
    
    sqlContent.toggle();
    sqlBlock.toggleClass('collapsed', isVisible);
    
    const icon = isVisible ? 'fa-chevron-down' : 'fa-chevron-up';
    const text = isVisible ? 'Show Query' : 'Hide Query';
    
    toggleBtn.html(`<i class="fas ${icon}"></i> ${text}`);
    
}

/**
 * Copy SQL query to clipboard
 */
function copySQLQuery(button) {
    const sqlBlock = $(button).closest('.sql-code-block');
    const sqlContent = sqlBlock.find('.sql-content').text();
    
    navigator.clipboard.writeText(sqlContent).then(() => {
        const $button = $(button);
        const originalHtml = $button.html();
        
        $button.addClass('copied');
        $button.html('<i class="fas fa-check"></i> Copied!');
        
        setTimeout(() => {
            $button.removeClass('copied');
            $button.html(originalHtml);
        }, 2000);
    }).catch(err => {
        console.error('Failed to copy SQL query:', err);
        alert('Failed to copy query to clipboard');
    });
}

/**
 * Create results display with automatic tabbed interface
 */
function createResultsDisplay(sqlResults) {
    if (!sqlResults || !sqlResults.data || sqlResults.data.length === 0) {
        return `<div class="info-message"><i class="fas fa-info-circle"></i> No results returned.</div>`;
    }
    
    const rowCount = sqlResults.row_count || sqlResults.data.length;
    const columnCount = sqlResults.column_count || sqlResults.columns.length;
    
    const enhancedData = sqlResults.enhanced_data;
    const recommendedCharts = enhancedData?.recommended_chart_types || ['table'];
    const dataSummary = enhancedData?.data_summary || {};
    
    let resultsHtml = `
        <div class="results-container">
            <div class="results-header">
                <div class="results-info">
                    <i class="fas fa-table"></i> ${rowCount} row${rowCount !== 1 ? 's' : ''}, ${columnCount} column${columnCount !== 1 ? 's' : ''}
                    ${dataSummary.numeric_columns > 0 ? `<span class="data-type-indicator" title="Contains numeric data"><i class="fas fa-hashtag"></i> ${dataSummary.numeric_columns} numeric</span>` : ''}
                    ${dataSummary.temporal_columns > 0 ? `<span class="data-type-indicator" title="Contains date/time data"><i class="fas fa-calendar"></i> ${dataSummary.temporal_columns} temporal</span>` : ''}
                </div>
                <div class="results-actions">
                    <div class="export-buttons">
                        <button class="export-btn" onclick="exportToCSV(this)" data-export-data='${JSON.stringify(window.lastExportData || {})}' title="Export to CSV">
                            <i class="fas fa-file-csv"></i> CSV
                        </button>
                        <button class="export-btn" onclick="exportToExcel(this)" data-export-data='${JSON.stringify(window.lastExportData || {})}' title="Export to Excel">
                            <i class="fas fa-file-excel"></i> Excel
                        </button>
                    </div>
                    <div class="results-tabs">
                        <button class="tab-btn active" onclick="switchResultsTab(this, 'data')">
                            <i class="fas fa-table"></i> Data
                        </button>
                        <button class="tab-btn ${recommendedCharts.includes('table') ? '' : 'recommended'}" onclick="switchResultsTab(this, 'chart')" 
                            title="Recommended: ${recommendedCharts.slice(0, 2).join(', ')}">
                            <i class="fas fa-chart-bar"></i> Chart ${recommendedCharts.length > 1 ? `(${recommendedCharts.length})` : ''}
                        </button>
                    </div>
                </div>
            </div>
            <div class="results-body">
                <div class="tab-content active" data-tab="data">
                    ${createDataTable(sqlResults)}
                </div>
                <div class="tab-content" data-tab="chart">
                    ${createChartContent(sqlResults)}
                </div>
            </div>
        </div>
    `;
    
    return resultsHtml;
}

/**
 * Create data table HTML
 */
function createDataTable(sqlResults) {
    if (!sqlResults.data || sqlResults.data.length === 0) {
        return '<div class="no-data">No data to display</div>';
    }
    
    let tableHtml = `
        <div class="data-table-container">
            <table class="results-table">
                <thead><tr>
    `;
    
    sqlResults.columns.forEach(column => {
        tableHtml += `<th>${escapeHtml(column)}</th>`;
    });
    
    tableHtml += `</tr></thead><tbody>`;
    
    const displayRows = sqlResults.data.slice(0, 100);
    displayRows.forEach(row => {
        tableHtml += '<tr>';
        sqlResults.columns.forEach((column, columnIndex) => {
            const value = row[columnIndex];
            const cellValue = value !== null && value !== undefined ? String(value) : 'NULL';
            const cellStyle = (value === null || value === undefined) ? 'font-style: italic; color: #6b7280;' : '';
            tableHtml += `<td style="${cellStyle}">${escapeHtml(cellValue)}</td>`;
        });
        tableHtml += '</tr>';
    });
    
    tableHtml += `</tbody></table>`;
    
    if (sqlResults.data.length > 100) {
        tableHtml += `<div class="table-footer">Showing first 100 of ${sqlResults.data.length} rows</div>`;
    }
    
    tableHtml += `</div>`;
    
    return tableHtml;
}

/**
 * Create chart content for results tab
 */
function createChartContent(sqlResults) {
    if (sqlResults.chart && sqlResults.chart.success) {
        console.log('Using pre-generated chart data');
        
        const chart = sqlResults.chart;
        const columns = chart.columns || [];
        const columnTypes = chart.column_types || {};
        const currentXCol = chart.x_col || (columns.length > 0 ? columns[0] : '');
        const currentYCol = chart.y_col || (columns.length > 1 ? columns[1] : '');
        const chartDivId = chart.chart_id || `chart-${Date.now()}`;
        
        const xAxisOptions = columns.map(col => {
            const typeLabel = columnTypes[col] ? ` (${columnTypes[col]})` : '';
            const selected = col === currentXCol ? ' selected' : '';
            return `<option value="${escapeHtml(col)}"${selected}>${escapeHtml(col)}${typeLabel}</option>`;
        }).join('');
        
        const yAxisOptions = columns.map(col => {
            const typeLabel = columnTypes[col] ? ` (${columnTypes[col]})` : '';
            const selected = col === currentYCol ? ' selected' : '';
            return `<option value="${escapeHtml(col)}"${selected}>${escapeHtml(col)}${typeLabel}</option>`;
        }).join('');
        
        return `
            <div class="chart-container" data-sql-result='${JSON.stringify(sqlResults).replace(/'/g, "&#39;")}'>
                <div class="chart-wrapper">
                    <div class="chart-header">
                        <h3 class="chart-title">Query Results Visualization</h3>
                        <div class="chart-controls">
                            <select class="chart-type-selector" onchange="regenerateTabChart(this)">
                                ${generateChartTypeOptions()}
                            </select>
                            <div class="chart-axis-group">
                                <span class="chart-axis-label">X:</span>
                                <select class="chart-axis-selector chart-x-selector" onchange="regenerateTabChartWithAxes(this)">
                                    ${xAxisOptions}
                                </select>
                            </div>
                            <div class="chart-axis-group">
                                <span class="chart-axis-label">Y:</span>
                                <select class="chart-axis-selector chart-y-selector" onchange="regenerateTabChartWithAxes(this)">
                                    ${yAxisOptions}
                                </select>
                            </div>
                        </div>
                    </div>
                    <div class="chart-content">
                        <div id="${chartDivId}" style="width: 100%; height: 400px;"></div>
                    </div>
                </div>
            </div>
            <script>
                if (typeof Plotly !== 'undefined') {
                    const chartData = ${JSON.stringify(chart)};
                    Plotly.newPlot('${chartDivId}', chartData.data, chartData.layout, chartData.config);
                }
            </script>
        `;
    }
    
    const chartId = `chart-tab-${Date.now()}`;
    const dataKey = `chartData${chartId.replace(/[^a-zA-Z0-9]/g, '')}`;
    const parametersContainerId = `chartParameters-${chartId}`;
    
    const columns = sqlResults.columns || [];
    
    return `
        <div id="${chartId}" class="chart-container" data-chart-key="${dataKey}">
            <div class="chart-wrapper">
                <div class="chart-header">
                    <h3 class="chart-title">Query Results Visualization</h3>
                    <div class="chart-controls">
                        <select class="chart-type-selector" onchange="handleChartTypeChange(this)">
                            ${generateChartTypeOptions()}
                        </select>
                        <div id="${parametersContainerId}" class="chart-parameters">
                            <span style="color: #9ca3af; font-size: 11px; font-style: italic;">Select chart type</span>
                        </div>
                        <button class="generate-chart-btn" onclick="generateTabChart('${chartId}')">
                            <i class="fas fa-chart-bar"></i> Generate
                        </button>
                    </div>
                </div>
                <div class="chart-content">
                    <div class="chart-loading">
                        <i class="fas fa-chart-bar fa-3x"></i>
                        <h3>Select a chart type and configure parameters</h3>
                        <p>Data contains ${sqlResults.row_count} rows with ${sqlResults.column_count || sqlResults.columns.length} columns.</p>
                    </div>
                </div>
            </div>
        </div>
        <script>
            window['${dataKey}'] = ${JSON.stringify(sqlResults)};
        </script>
    `;
}

/**
 * Switch between results tabs
 */
function switchResultsTab(button, tabName) {
    const container = $(button).closest('.results-container');
    
    container.find('.tab-btn').removeClass('active');
    $(button).addClass('active');
    
    container.find('.tab-content').removeClass('active');
    container.find(`.tab-content[data-tab="${tabName}"]`).addClass('active');
}

/**
 * Generate chart for tab interface
 */
async function generateTabChart(chartId) {
    const container = document.getElementById(chartId);
    if (!container) {
        console.error('Chart container not found:', chartId);
        return;
    }
    
    const chartContent = container.querySelector('.chart-content');
    const chartTypeSelector = container.querySelector('.chart-type-selector');
    const chartType = chartTypeSelector ? chartTypeSelector.value : '';
    
    // Validate chart type selected
    if (!chartType) {
        chartContent.innerHTML = '<div class="chart-error">Please select a chart type</div>';
        return;
    }
    
    // Get parameters from UI (new parameter system)
    const chartParametersDiv = container.querySelector('.chart-parameters');
    let params = {};
    
    // If new parameter UI exists, use it
    if (chartParametersDiv) {
        params = getChartParametersFromUI(chartParametersDiv.id);
        
        // Validate parameters
        const validation = validateChartParameters(chartType, params);
        if (!validation.isValid) {
            chartContent.innerHTML = `<div class="chart-error">${validation.error}</div>`;
            return;
        }
    } else {
        // Fallback to old axis selectors (for backward compatibility)
        const xSelector = container.querySelector('.chart-x-selector');
        const ySelector = container.querySelector('.chart-y-selector');
        const xCol = xSelector ? xSelector.value : null;
        const yCol = ySelector ? ySelector.value : null;
        
        if (!xCol || !yCol) {
            chartContent.innerHTML = '<div class="chart-error">Please select both X and Y axis columns</div>';
            return;
        }
        
        params = { x: xCol, y: yCol };
    }
    
    const dataKey = container.getAttribute('data-chart-key');
    const queryResult = dataKey ? window[dataKey] : null;
    
    console.log('Chart generation attempt:', {
        chartId: chartId,
        dataKey: dataKey,
        hasData: !!queryResult,
        chartType: chartType,
        params: params
    });
    
    if (!queryResult) {
        console.error('No query result data found. Available keys:', Object.keys(window).filter(k => k.startsWith('chartData')));
        chartContent.innerHTML = '<div class="chart-error">No data available for chart generation</div>';
        return;
    }
    
    if (!queryResult.data || !queryResult.data.length) {
        chartContent.innerHTML = '<div class="chart-error">Query returned no data to visualize</div>';
        return;
    }
    
    // Show loading state
    chartContent.innerHTML = '<div class="chart-loading"><i class="fas fa-spinner fa-spin"></i> Generating chart...</div>';
    
    try {
        const endpoint = window.InsightsConfig?.endpoints?.generateChart || '/insights/generate-chart';
        
        const response = await fetch(endpoint, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                query_result: queryResult,
                chart_type: chartType,
                title: 'Query Results Visualization',
                params: params
            })
        });
        
        if (!response.ok) {
            throw new Error(`Chart generation failed: ${response.statusText}`);
        }
        
        const chartData = await response.json();
        
        if (chartData.success) {
            console.log('Chart data received:', {
                type: chartData.type,
                chartId: chartData.chart_id,
                hasPlotly: typeof Plotly !== 'undefined'
            });
            
            const chartDiv = document.createElement('div');
            chartDiv.id = chartData.chart_id;
            chartDiv.style.width = '100%';
            chartDiv.style.height = '400px';
            
            chartContent.innerHTML = '';
            chartContent.appendChild(chartDiv);
            
            if (typeof Plotly !== 'undefined') {
                Plotly.newPlot(chartData.chart_id, chartData.data, chartData.layout, chartData.config);
                console.log('Chart rendered successfully with Plotly.newPlot');
            } else {
                chartContent.innerHTML = '<div class="chart-error">Plotly library not found. Please refresh the page.</div>';
            }
            
            console.log('Chart generated successfully');
        } else {
            chartContent.innerHTML = `<div class="chart-error">Chart generation failed: ${chartData.error || 'Unknown error'}</div>`;
            console.error('Chart generation failed:', chartData);
        }
    } catch (error) {
        console.error('Error generating tab chart:', error);
        chartContent.innerHTML = `<div class="chart-error">Error generating chart: ${error.message}</div>`;
    }
}

/**
 * Regenerate chart with new type for tab interface
 */
function regenerateTabChart(selector) {
    const container = selector.closest('.chart-container');
    if (!container) return;
    
    const chartId = container.id;
    if (chartId) {
        generateTabChart(chartId);
    } else {
        regenerateTabChartWithAxes(selector);
    }
}

/**
 * Regenerate chart with custom X/Y axes for tab interface
 */
async function regenerateTabChartWithAxes(selector) {
    const container = selector.closest('.chart-container');
    if (!container) {
        console.error('Chart container not found');
        return;
    }
    
    let sqlResults;
    const sqlResultJson = container.getAttribute('data-sql-result');
    if (sqlResultJson) {
        try {
            sqlResults = JSON.parse(sqlResultJson);
        } catch (e) {
            console.error('Failed to parse SQL result data:', e);
            return;
        }
    } else {
        const dataKey = container.getAttribute('data-chart-key');
        if (dataKey && window[dataKey]) {
            sqlResults = window[dataKey];
        } else {
            console.error('No SQL result data found (checked both data-sql-result and data-chart-key)');
            return;
        }
    }
    
    if (!sqlResults || !sqlResults.data) {
        console.error('Invalid SQL result data');
        return;
    }
    
    const chartTypeSelector = container.querySelector('.chart-type-selector');
    const chartType = chartTypeSelector ? chartTypeSelector.value : '';
    
    // Validate chart type selected
    if (!chartType) {
        const chartContent = container.querySelector('.chart-content');
        if (chartContent) {
            chartContent.innerHTML = '<div class="chart-error">Please select a chart type</div>';
        }
        return;
    }
    
    // Get parameters from UI (new parameter system)
    const chartParametersDiv = container.querySelector('.chart-parameters');
    let params = {};
    
    // If new parameter UI exists, use it
    if (chartParametersDiv) {
        params = getChartParametersFromUI(chartParametersDiv.id);
        
        // Validate parameters
        const validation = validateChartParameters(chartType, params);
        if (!validation.isValid) {
            const chartContent = container.querySelector('.chart-content');
            if (chartContent) {
                chartContent.innerHTML = `<div class="chart-error">${validation.error}</div>`;
            }
            return;
        }
    } else {
        // Fallback to old axis selectors (for backward compatibility)
        const xSelector = container.querySelector('.chart-x-selector');
        const ySelector = container.querySelector('.chart-y-selector');
        const xCol = xSelector ? xSelector.value : null;
        const yCol = ySelector ? ySelector.value : null;
        
        if (!xCol || !yCol) {
            const chartContent = container.querySelector('.chart-content');
            if (chartContent) {
                chartContent.innerHTML = '<div class="chart-error">Please select both X and Y axis columns</div>';
            }
            return;
        }
        
        params = { x: xCol, y: yCol };
    }
    
    console.log('Regenerating chart with params:', { chartType, params });
    
    const chartContent = container.querySelector('.chart-content');
    if (chartContent) {
        chartContent.innerHTML = '<div class="chart-loading"><i class="fas fa-spinner fa-spin"></i> Regenerating chart...</div>';
    }
    
    try {
        const endpoint = window.InsightsConfig?.endpoints?.generateChart || '/insights/generate-chart';
        
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 30000);
        
        const response = await fetch(endpoint, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                query_result: sqlResults,
                chart_type: chartType,
                title: 'Query Results Visualization',
                params: params
            }),
            signal: controller.signal
        });
        
        clearTimeout(timeoutId);
        
        if (!response.ok) {
            throw new Error(`Chart generation failed: ${response.statusText}`);
        }
        
        const chartData = await response.json();
        
        if (chartData.success && typeof Plotly !== 'undefined') {
            console.log('Chart regenerated successfully:', {
                type: chartData.type,
                chartId: chartData.chart_id,
                xCol: chartData.x_col,
                yCol: chartData.y_col
            });
            
            const chartDiv = document.createElement('div');
            chartDiv.id = chartData.chart_id;
            chartDiv.style.width = '100%';
            chartDiv.style.height = '400px';
            
            chartContent.innerHTML = '';
            chartContent.appendChild(chartDiv);
            
            Plotly.newPlot(chartData.chart_id, chartData.data, chartData.layout, chartData.config);
            console.log('Chart rendered successfully with custom axes');
        } else {
            chartContent.innerHTML = `<div class="chart-error">Chart regeneration failed: ${chartData.error || 'Unknown error'}</div>`;
            console.error('Chart regeneration failed:', chartData);
        }
    } catch (error) {
        console.error('Error regenerating chart with axes:', error);
        if (chartContent) {
            chartContent.innerHTML = `<div class="chart-error">Error regenerating chart: ${error.message}</div>`;
        }
    }
}

/**
 * Show toast notification
 */
function showToast(message, type = 'success') {
    const bgColor = type === 'success' ? '#10b981' : '#ef4444';
    
    const toast = $(`
        <div class="toast-notification" style="
            position: fixed;
            top: 20px;
            right: 20px;
            background: ${bgColor};
            color: white;
            padding: 12px 20px;
            border-radius: 8px;
            z-index: 1000;
            opacity: 0;
            transform: translateY(-10px);
            transition: all 0.3s ease;
        ">${escapeHtml(message)}</div>
    `);
    
    $('body').append(toast);
    
    setTimeout(() => {
        toast.css({ opacity: 1, transform: 'translateY(0)' });
    }, 100);
    
    setTimeout(() => {
        toast.css({ opacity: 0, transform: 'translateY(-10px)' });
        setTimeout(() => toast.remove(), 300);
    }, 3000);
}

/**
 * Generate chart from data using the insights API endpoint
 */
if (typeof generateChartFromData === 'undefined') {
    window.generateChartFromData = async function(queryResult, chartType = 'auto', title = 'Data Visualization', xCol = null, yCol = null, params = null) {
        try {
            const endpoint = window.InsightsConfig?.endpoints?.generateChart || '/insights/generate-chart';
            
            const requestBody = {
                query_result: queryResult,
                chart_type: chartType,
                title: title
            };
            
            // NEW: Support params object for new parameter system
            if (params) {
                requestBody.params = params;
            }
            // LEGACY: Support old x_col/y_col format for backward compatibility
            else if (xCol || yCol) {
                // Convert to params format based on chart type
                requestBody.params = {};
                
                if (chartType === 'pie') {
                    // Pie chart uses 'names' and 'values' instead of 'x' and 'y'
                    if (xCol) requestBody.params.names = xCol;
                    if (yCol) requestBody.params.values = yCol;
                } else {
                    // Bar, line, and other charts use 'x' and 'y'
                    if (xCol) requestBody.params.x = xCol;
                    if (yCol) requestBody.params.y = yCol;
                }
            }
            
            console.log('Sending chart generation request:', requestBody);
            
            const controller = new AbortController();
            const timeoutId = setTimeout(() => controller.abort(), 30000);
            
            const response = await fetch(endpoint, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(requestBody),
                signal: controller.signal
            });
            
            clearTimeout(timeoutId);
            
            if (!response.ok) {
                throw new Error(`Chart generation failed: ${response.statusText}`);
            }
            
            return await response.json();
        } catch (error) {
            console.error('Error generating chart:', error);
            throw error;
        }
    };
}

/**
 * Export data to CSV format
 */
function exportToCSV(button) {
    try {
        const exportData = JSON.parse(button.dataset.exportData);
        
        if (!exportData.csv || !exportData.filename_base) {
            alert('Export data not available. Please try running the query again.');
            return;
        }
        
        console.log('Exporting CSV...');
        
        const filename = `${exportData.filename_base}.csv`;
        downloadFile(exportData.csv, filename, 'text/csv;charset=utf-8');
        
        console.log('CSV export completed');
        
    } catch (error) {
        console.error('CSV export failed:', error);
        alert('Failed to export CSV: ' + error.message);
    }
}

/**
 * Export data to Excel format
 */
function exportToExcel(button) {
    try {
        const exportData = JSON.parse(button.dataset.exportData);
        
        if (!exportData.excel_base64 || !exportData.filename_base) {
            alert('Export data not available. Please try running the query again.');
            return;
        }
        
        console.log('Exporting Excel...', {
            base64Length: exportData.excel_base64.length,
            filename: exportData.filename_base
        });
        
        if (exportData.excel_base64.length === 0) {
            throw new Error('Empty Excel data received');
        }
        
        try {
            const binaryString = atob(exportData.excel_base64);
            const bytes = new Uint8Array(binaryString.length);
            for (let i = 0; i < binaryString.length; i++) {
                bytes[i] = binaryString.charCodeAt(i);
            }
            
            console.log('Binary data created:', bytes.length, 'bytes');
            
            const filename = `${exportData.filename_base}.xlsx`;
            const blob = new Blob([bytes], { 
                type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' 
            });
            
            console.log('Blob created:', blob.size, 'bytes, type:', blob.type);
            
            const url = URL.createObjectURL(blob);
            
            const a = document.createElement('a');
            a.href = url;
            a.download = filename;
            a.style.display = 'none';
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            URL.revokeObjectURL(url);
            
            console.log('Excel export completed successfully');
            
        } catch (base64Error) {
            console.error('Base64 conversion failed:', base64Error);
            throw new Error('Failed to process Excel data: ' + base64Error.message);
        }
        
    } catch (error) {
        console.error('Excel export failed:', error);
        alert('Failed to export Excel: ' + error.message + '\n\nTip: Try the CSV export instead.');
    }
}

// ============================================================================
// INITIALIZATION
// ============================================================================

// Initialize Insights functionality when the page loads
document.addEventListener('DOMContentLoaded', function() {
    if (window.InsightsConfig) {
        initializeInsights();
        
        // Auto-scroll ONLY when new MESSAGE elements are added (not when toggling visibility)
        const chatContainer = document.getElementById('chatMessages');
        if (chatContainer) {
            const observer = new MutationObserver(function(mutations) {
                let shouldScroll = false;
                mutations.forEach(function(mutation) {
                    if (mutation.type === 'childList' && mutation.addedNodes.length > 0) {
                        for (let node of mutation.addedNodes) {
                            // Only scroll when new message wrappers or results are added
                            if (node.nodeType === Node.ELEMENT_NODE && 
                                (node.classList.contains('message-wrapper') || 
                                 node.classList.contains('results-table-container') ||
                                 node.classList.contains('error-message'))) {
                                shouldScroll = true;
                                break;
                            }
                        }
                    }
                });
                if (shouldScroll) {
                    setTimeout(scrollToBottom, 100);
                }
            });
            
            observer.observe(chatContainer, {
                childList: true,
                subtree: true
            });
        }
    }
    
    // Feedback modal character counter
    const feedbackInput = document.getElementById('feedbackCommentInput');
    const charCount = document.getElementById('feedbackCharCount');
    
    if (feedbackInput && charCount) {
        feedbackInput.addEventListener('input', function() {
            charCount.textContent = this.value.length;
        });
        
        // Submit with Ctrl+Enter or Cmd+Enter
        feedbackInput.addEventListener('keydown', function(e) {
            if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
                e.preventDefault();
                submitFeedbackWithComment();
            } else if (e.key === 'Escape') {
                e.preventDefault();
                closeFeedbackModal();
            }
        });
    }
    
    // Close modal when clicking outside
    const feedbackModal = document.getElementById('feedbackModal');
    if (feedbackModal) {
        feedbackModal.addEventListener('click', function(e) {
            if (e.target === feedbackModal) {
                closeFeedbackModal();
            }
        });
    }
});
