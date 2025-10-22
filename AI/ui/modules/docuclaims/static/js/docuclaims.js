// DocuClaims Module JavaScript
// All DocuClaims-specific functionality

document.addEventListener('DOMContentLoaded', function() {
    // Function to parse markdown and apply syntax highlighting
    function parseMarkdown(text) {
        if (!text) return '';
        
        // Configure marked options
        marked.setOptions({
            highlight: function(code, lang) {
                if (lang && hljs.getLanguage(lang)) {
                    try {
                        return hljs.highlight(code, { language: lang }).value;
                    } catch (e) {}
                }
                return hljs.highlightAuto(code).value;
            },
            breaks: true,
            gfm: true
        });
        
        // Return parsed markdown
        return marked.parse(text);
    }
    
    // Apply markdown to existing content on page load
    function applyMarkdownToExistingContent() {
        $('.markdown-content').each(function() {
            const content = $(this).html();
            if (content && !$(this).data('markdown-applied')) {
                $(this).html(parseMarkdown(content));
                $(this).data('markdown-applied', true);
            }
        });
    }
    
    // Function to scroll to bottom of chat container
    function scrollToBottom() {
        const chatContainer = document.getElementById('chatContainer');
        if (chatContainer) {
            chatContainer.scrollTop = chatContainer.scrollHeight;
        }
    }
    
    $(document).ready(function() {
        // Force hide modal and backdrop on page load with !important rules
        $('#uploadContainer').hide().attr('style', 'display: none !important');
        $('#modalBackdrop').hide().attr('style', 'display: none !important');
        
        // Global flag to track if we should continue polling
        window.shouldPollFileStatus = false;
        
        // Initialize tooltips
        const tooltipTriggerList = document.querySelectorAll('[data-bs-toggle="tooltip"]');
        const tooltipList = [...tooltipTriggerList].map(tooltipTriggerEl => new bootstrap.Tooltip(tooltipTriggerEl));
        
        // Apply markdown to existing content
        applyMarkdownToExistingContent();
        
        // Scroll to bottom of chat container on load
        scrollToBottom();
        
        // Load suggestion questions if welcome section is visible and feature is enabled
        if ($('#welcomeSection').length > 0 && window.ENABLE_SUGGESTION_QUESTIONS) {
            loadSuggestionQuestions();
        }
        
        // Focus on the message input when page loads
        setTimeout(() => {
            $('#messageInput').focus();
        }, 500);
        
        // Enable/disable send button based on input only - model is assumed to be pre-selected
        $('#messageInput').on('input', function() {
            const hasText = $(this).val().trim() !== '';
            $('#sendBtn').prop('disabled', !hasText);
        });
        
        // Attachment button click handler
        $('#attachmentBtn').on('click', function() {
            $('#fileUpload').click();
        });
        
        // Function to show the upload modal
        function showUploadModal() {
            // First remove the !important style via stylesheet or inline style
            $('#modalBackdrop, #uploadContainer').removeClass('d-none').css({
                'cssText': 'display: block !important'
            });
            // Enable polling when modal is shown
            window.shouldPollFileStatus = true;
        }
        
        // Function to hide the upload modal
        function hideUploadModal() {
            // Hide with !important to ensure it stays hidden
            $('#modalBackdrop, #uploadContainer').css({
                'cssText': 'display: none !important'
            });
            // Stop polling when modal is hidden
            window.shouldPollFileStatus = false;
        }
        
        // Close upload status panel
        $('#closeUploadStatus').on('click', function() {
            hideUploadModal();
        });
        
        // Close modal when clicking on backdrop
        $('#modalBackdrop').on('click', function() {
            hideUploadModal();
        });
        
        // Close modal with ESC key
        $(document).on('keydown', function(e) {
            if (e.key === 'Escape' && $('#uploadContainer').is(':visible')) {
                hideUploadModal();
            }
        });
        
        // File upload functionality
        $('#fileUpload').on('change', function() {
            const files = this.files;
            
            if (files.length === 0) return;
            
            // Display selected files
            let fileListHTML = '<div class="selected-files mt-3 mb-3">';
            fileListHTML += '<p class="mb-2 text-muted small fw-medium">Selected files:</p>';
            fileListHTML += '<ul class="list-group">';
            
            for (let i = 0; i < files.length; i++) {
                const file = files[i];
                const fileSize = (file.size / 1024).toFixed(1) + ' KB';
                let fileIcon = 'fa-file-alt';
                
                if (file.name.endsWith('.pdf')) {
                    fileIcon = 'fa-file-pdf';
                } else if (file.name.endsWith('.doc') || file.name.endsWith('.docx')) {
                    fileIcon = 'fa-file-word';
                }
                
                fileListHTML += `
                    <li class="list-group-item d-flex justify-content-between align-items-center py-2 px-3">
                        <div>
                            <i class="fas ${fileIcon} me-2 text-secondary"></i>
                            <span class="text-truncate d-inline-block" style="max-width: 400px;">${file.name}</span>
                        </div>
                        <span class="badge bg-light text-dark">${fileSize}</span>
                    </li>`;
            }
            
            fileListHTML += '</ul></div>';
            $('#fileList').html(fileListHTML);
            
            // Show upload modal only (no need for the small upload badge anymore)
            showUploadModal();
            
            // Upload files automatically
            const formData = new FormData();
            for (let i = 0; i < files.length; i++) {
                formData.append('files[]', files[i]);
            }
            
            // Show initial upload status with spinner
            let statusHtml = '<div class="mt-3 mb-2"><h6>Upload Status:</h6></div>';
            statusHtml += '<div class="file-status-list" id="fileStatusList">';
            
            // Create object to track file status
            const fileStatuses = {};
            
            for (let i = 0; i < files.length; i++) {
                const file = files[i];
                const filename = file.name;
                fileStatuses[filename] = 'uploading';
                
                // Add initial card with uploading status for each file
                statusHtml += `
                    <div class="card mb-2 border-0 shadow-sm" id="status-card-${i}">
                        <div class="card-body py-2 px-3">
                            <div class="d-flex justify-content-between align-items-center">
                                <div class="text-truncate">
                                    <i class="fa-solid fa-spinner fa-spin text-primary"></i> <span class="ms-2 fw-medium">${filename}</span>
                                </div>
                                <span class="badge bg-primary">Uploading...</span>
                            </div>
                            <div class="progress mt-1" style="height: 6px;">
                                <div class="progress-bar progress-bar-striped progress-bar-animated bg-primary" role="progressbar" style="width: 30%" aria-valuenow="30" aria-valuemin="0" aria-valuemax="100"></div>
                            </div>
                        </div>
                    </div>
                `;
            }
            
            statusHtml += '</div>';
            $('#uploadStatus').html(statusHtml);
            $('#attachmentBtn').prop('disabled', true);
            
            $.ajax({
                url: '/upload_files',
                type: 'POST',
                data: formData,
                processData: false,
                contentType: false,
                success: function(response) {
                    // Update status for each file based on initial upload response
                    for (const [filename, status] of Object.entries(response.file_status)) {
                        fileStatuses[filename] = status;
                        // Get error message if exists
                        const errorMsg = response.file_errors && response.file_errors[filename] ? response.file_errors[filename] : null;
                        updateFileStatusUI(filename, status, errorMsg);
                    }
                    
                    $('#attachmentBtn').prop('disabled', false);
                    
                    // Start polling for each file that's not processed or errored
                    for (const [filename, status] of Object.entries(fileStatuses)) {
                        if (status !== 'processed' && status !== 'error' && status !== 'timeout') {
                            pollFileStatus(filename);
                        }
                    }
                    
                    // Check if all files are processed
                    function checkAllFilesProcessed() {
                        const allProcessed = Object.values(fileStatuses).every(status => 
                            status === 'processed' || status === 'error' || status === 'timeout'
                        );
                        
                        if (allProcessed) {
                            // Stop polling since all files have reached a final state
                            window.shouldPollFileStatus = false;
                            
                            // If any files were processed successfully, reload the page
                            const anyProcessed = Object.values(fileStatuses).some(status => status === 'processed');
                            if (anyProcessed) {
                                setTimeout(function() {
                                    location.reload();
                                }, 1500);
                            }
                        }
                    }
                    
                    // Function to poll status for a single file
                    function pollFileStatus(filename, startTime = Date.now()) {
                        // If modal is closed or polling should be stopped, exit early
                        if (!window.shouldPollFileStatus) {
                            return;
                        }
                        
                        // Check if 5 minutes (300 seconds) have passed since start
                        const elapsedTime = (Date.now() - startTime) / 1000;
                        if (elapsedTime > 300) {
                            console.log(`File ${filename} processing timeout after ${elapsedTime.toFixed(1)} seconds`);
                            fileStatuses[filename] = 'timeout';
                            updateFileStatusUI(filename, 'timeout', 'Processing timed out after 5 minutes');
                            checkAllFilesProcessed();
                            return;
                        }
                        
                        // Update UI to show processing state
                        if (fileStatuses[filename] === 'uploading') {
                            fileStatuses[filename] = 'processing';
                            updateFileStatusUI(filename, 'processing');
                        }
                        
                        // Poll the API endpoint
                        $.ajax({
                            url: `/check_file_processed/${encodeURIComponent(filename)}`,
                            type: 'GET',
                            success: function(data) {
                                if (data.processed === true) {
                                    fileStatuses[filename] = 'processed';
                                    updateFileStatusUI(filename, 'processed');
                                    checkAllFilesProcessed();
                                } else if (data.processed === false && window.shouldPollFileStatus) {
                                    // Continue polling every 10 seconds instead of 3 seconds
                                    setTimeout(() => {
                                        // Double-check flag before continuing
                                        if (window.shouldPollFileStatus) {
                                            pollFileStatus(filename, startTime);
                                        }
                                    }, 10000);
                                } else {
                                    fileStatuses[filename] = 'error';
                                    updateFileStatusUI(filename, 'error');
                                    checkAllFilesProcessed();
                                }
                            },
                            error: function(xhr, status, error) {
                                console.error(`Error checking status for file ${filename}:`, {status, error, responseText: xhr.responseText});
                                fileStatuses[filename] = 'error';
                                updateFileStatusUI(filename, 'error', xhr.responseText || 'Error checking file status');
                                checkAllFilesProcessed();
                            }
                        });
                    }
                },
                error: function(xhr, status, error) {
                    // Try to get detailed error message from API
                    let errorMessage = error;
                    try {
                        if (xhr.responseJSON && xhr.responseJSON.detail) {
                            errorMessage = xhr.responseJSON.detail;
                        } else if (xhr.responseText) {
                            const errorObj = JSON.parse(xhr.responseText);
                            if (errorObj.detail) {
                                errorMessage = errorObj.detail;
                            }
                        }
                    } catch (e) {
                        // If parsing fails, use the original error
                    }
                    
                    $('#uploadStatus').html(`
                        <div class="alert alert-danger mt-3">
                            <div class="d-flex align-items-center">
                                <i class="fas fa-exclamation-circle me-2"></i>
                                <div>
                                    <strong>Upload failed</strong><br>
                                    ${errorMessage}
                                    <br><small class="text-muted">Status code: ${xhr.status}</small>
                                </div>
                            </div>
                        </div>
                    `);
                    $('#attachmentBtn').prop('disabled', false);
                    
                    // Log error to console for debugging
                    console.error("File upload failed:", {status: xhr.status, statusText: xhr.statusText, responseText: xhr.responseText});
                }
            });
            
            // Function to update the UI for a single file's status
            function updateFileStatusUI(filename, status, errorDetails) {
                // Find the card for this file
                const fileCard = $(`#fileStatusList .card:contains('${filename}')`);
                
                if (fileCard.length) {
                    let icon, statusClass, statusText, progressBarStyle, badgeClass, progressBarClass;
                    
                    switch(status) {
                        case 'uploading':
                            icon = '<i class="fa-solid fa-spinner fa-spin text-primary"></i>';
                            statusClass = 'status-uploading text-primary';
                            statusText = 'Uploading...';
                            progressBarStyle = 'width: 30%';
                            badgeClass = 'bg-primary';
                            progressBarClass = 'bg-primary progress-bar-striped progress-bar-animated';
                            break;
                        case 'processing':
                            icon = '<i class="fa-solid fa-clock fa-spin text-warning"></i>';
                            statusClass = 'status-processing text-warning';
                            statusText = 'Processing...';
                            progressBarStyle = 'width: 60%';
                            badgeClass = 'bg-warning';
                            progressBarClass = 'bg-warning progress-bar-striped progress-bar-animated';
                            break;
                        case 'processed':
                            icon = '<i class="fa-solid fa-circle-check text-success"></i>';
                            statusClass = 'status-processed text-success';
                            statusText = 'Processed';
                            progressBarStyle = 'width: 100%';
                            badgeClass = 'bg-success';
                            progressBarClass = 'bg-success';
                            break;
                        case 'error':
                            icon = '<i class="fa-solid fa-circle-xmark text-danger"></i>';
                            statusClass = 'status-error text-danger';
                            statusText = errorDetails ? errorDetails : 'Error uploading file';
                            progressBarStyle = 'width: 100%';
                            badgeClass = 'bg-danger';
                            progressBarClass = 'bg-danger';
                            break;
                        case 'timeout':
                            icon = '<i class="fa-solid fa-clock text-danger"></i>';
                            statusClass = 'status-error text-danger';
                            statusText = 'Timeout';
                            progressBarStyle = 'width: 100%';
                            badgeClass = 'bg-danger';
                            progressBarClass = 'bg-danger';
                            break;
                    }
                    
                    // Update the card content
                    const cardBody = fileCard.find('.card-body');
                    const iconAndName = cardBody.find('.text-truncate');
                    iconAndName.html(`${icon} <span class="ms-2 fw-medium">${filename}</span>`);
                    
                    // Update or create error message display
                    let errorDisplay = cardBody.find('.error-message-display');
                    if (status === 'error' && errorDetails) {
                        // Show detailed error message
                        if (errorDisplay.length === 0) {
                            cardBody.find('.d-flex.justify-content-between').after('<div class="error-message-display small text-danger mt-2 mb-1"></div>');
                            errorDisplay = cardBody.find('.error-message-display');
                        }
                        errorDisplay.html(`<i class="fa-solid fa-exclamation-triangle me-1"></i>${errorDetails}`).show();
                        // Update badge with simple text
                        cardBody.find('.badge').removeClass('bg-primary bg-warning bg-success bg-danger').addClass(badgeClass).text('Error');
                    } else if (status === 'timeout' && errorDetails) {
                        // Show timeout message
                        if (errorDisplay.length === 0) {
                            cardBody.find('.d-flex.justify-content-between').after('<div class="error-message-display small text-danger mt-2 mb-1"></div>');
                            errorDisplay = cardBody.find('.error-message-display');
                        }
                        errorDisplay.html(`<i class="fa-solid fa-clock me-1"></i>${errorDetails}`).show();
                        cardBody.find('.badge').removeClass('bg-primary bg-warning bg-success bg-danger').addClass(badgeClass).text('Timeout');
                    } else {
                        // Hide error display for non-error states
                        errorDisplay.hide();
                        cardBody.find('.badge').removeClass('bg-primary bg-warning bg-success bg-danger').addClass(badgeClass).text(statusText);
                    }
                    
                    // Update progress bar - completely reset all classes and styles
                    const progressBar = cardBody.find('.progress-bar');
                    progressBar.attr('style', progressBarStyle);
                    progressBar.removeClass('bg-primary bg-warning bg-success bg-danger progress-bar-striped progress-bar-animated');
                    progressBar.addClass(progressBarClass);
                }
            }
        });
        
        // Send message
        function sendMessage() {
            const messageInput = $('#messageInput');
            const message = messageInput.val().trim();
            if (!message) return;
            
            // Disable input and button during processing
            messageInput.prop('disabled', true);
            $('#sendBtn').prop('disabled', true).html('<i class="fas fa-spinner fa-spin"></i>');
            
            // Clear input
            messageInput.val('');
            
            // Add user message to UI immediately
            $('#chatContainer').append(`
                <div class="message-container">
                    <div class="d-flex w-100 justify-content-end">
                        <div class="user-message">${message}</div>
                        <div class="message-avatar user-avatar ms-2">
                            <i class="fa-solid fa-user"></i>
                        </div>
                    </div>
                </div>
            `);
            scrollToBottom();
            
            // Show loading indicator with typing animation
            const loadingId = Date.now();
            $('#chatContainer').append(`
                <div class="message-container" id="loading-${loadingId}">
                    <div class="d-flex w-100 flex-column">
                        <div class="d-flex">
                            <div class="message-avatar assistant-avatar">
                                <i class="fa-solid fa-robot"></i>
                            </div>
                            <div class="assistant-message">
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
                    </div>
                </div>
            `);
            scrollToBottom();
            
            // Send message to server
            // Get the currently selected model directly from the dropdown
            // Get selected model (if selector exists, otherwise it will be handled by backend)
            const selectedModel = $('#modelSelect').length ? $('#modelSelect').val() : null;
            
            $.ajax({
                url: '/send_message',
                type: 'POST',
                data: { 
                    message: message,
                    model: selectedModel 
                },
                success: function(response) {
                    // Remove loading indicator
                    $(`#loading-${loadingId}`).remove();
                    
                    // Add assistant message
                    // Parse content for model tag
                    let rawContent = response.assistant_message.content;
                    let content = rawContent;
                    let modelName = "";
                    let actualModel = selectedModel;
                    
                    // Extract model name if present
                    const modelRegex = /\*\*Model used:\*\* `([^`]+)`/;
                    const modelMatch = content.match(modelRegex);
                    
                    if (modelMatch && modelMatch[1]) {
                        modelName = "Model: " + modelMatch[1].trim();
                        actualModel = modelMatch[1].trim();
                        content = content.replace(modelRegex, '').trim();
                    }
                    
                    // Store clean content without model tag for follow-up questions
                    const cleanContent = content;
                    
                    const messageContainerId = `message-${Date.now()}`;
                    const messageHtml = `
                        <div class="message-container" id="${messageContainerId}">
                            <div class="d-flex w-100 flex-column">
                                ${modelName ? `<div class="model-tag">${modelName}</div>` : ''}
                                <div class="d-flex">
                                    <div class="message-avatar assistant-avatar">
                                        <i class="fa-solid fa-robot"></i>
                                    </div>
                                    <div class="assistant-message markdown-content">
                                        ${parseMarkdown(content)}
                                    </div>
                                </div>
                            </div>
                        </div>
                    `;
                    $('#chatContainer').append(messageHtml);
                    scrollToBottom();
                    
                    // Generate follow-up questions if enabled
                    if (window.ENABLE_FOLLOWUP_QUESTIONS && actualModel) {
                        const messageElement = $(`#${messageContainerId}`);
                        showFollowUpLoading(messageElement);
                        
                        // Get conversation history (last few exchanges)
                        const conversationHistory = [];
                        
                        // Fetch and render follow-up questions
                        fetchFollowUpQuestions(message, cleanContent, conversationHistory, actualModel)
                            .then(questions => {
                                // Remove loading indicator
                                messageElement.find('.followup-container').remove();
                                
                                if (questions && questions.length > 0) {
                                    renderFollowUpQuestions(questions, messageElement);
                                }
                            })
                            .catch(error => {
                                console.error('Error generating follow-up questions:', error);
                                messageElement.find('.followup-container').remove();
                            });
                    } else if (window.ENABLE_FOLLOWUP_QUESTIONS && !actualModel) {
                        console.warn('Follow-up questions enabled but no model specified');
                    }
                    
                    // Re-enable input and button
                    messageInput.prop('disabled', false).focus();
                    $('#sendBtn').prop('disabled', true).html('<i class="fas fa-paper-plane"></i>');
                },
                error: function(xhr, status, error) {
                    // Remove loading indicator
                    $(`#loading-${loadingId}`).remove();
                    
                    // Add error message
                    $('#chatContainer').append(`
                        <div class="message-container">
                            <div class="d-flex w-100 flex-column">
                                <div class="d-flex">
                                    <div class="message-avatar assistant-avatar">
                                        <i class="fa-solid fa-robot"></i>
                                    </div>
                                    <div class="assistant-message">
                                        <div class="d-flex align-items-center text-danger mb-2">
                                            <i class="fas fa-exclamation-circle me-2"></i>
                                            <strong>Error occurred</strong>
                                        </div>
                                        <p class="mb-0">I'm having trouble processing your request. Please try again later.</p>
                                        <small class="text-muted">${error || 'Connection error'}</small>
                                    </div>
                                </div>
                            </div>
                        </div>
                    `);
                    scrollToBottom();
                    
                    // Re-enable input and button
                    messageInput.prop('disabled', false).focus();
                    $('#sendBtn').prop('disabled', true).html('<i class="fas fa-paper-plane"></i>');
                }
            });
        }
        
        // Send message on button click
        $('#sendBtn').on('click', sendMessage);
        
        // Send message on Enter key
        $('#messageInput').on('keypress', function(e) {
            if (e.which === 13) { // Enter key
                sendMessage();
            }
        });
        
        
        // Model selection - only bind if the selector exists (when enabled)
        if ($('#modelSelect').length) {
            $('#modelSelect').on('change', function() {
                const model = $(this).val();
                
                // Save the model selection
                $.ajax({
                    url: '/select_model',
                    type: 'POST',
                    data: { model: model }
                });
            });
        }
        
        // Chat history toggle
        $('#chatHistoryCheck').on('change', function() {
            $.ajax({
                url: '/toggle_setting',
                type: 'POST',
                data: { 
                    setting: 'use_chat_history',
                    value: this.checked 
                }
            });
        });
        
        // Clear chat history
        $('#clearChatBtn').on('click', function() {
            $.ajax({
                url: '/clear_chat',
                type: 'POST',
                success: function() {
                    location.reload();
                }
            });
        });
        
        // Reset everything with confirmation dialog
        $('#resetEverythingBtn').on('click', function() {
            if (confirm('Are you sure you want to reset everything? This will clear all conversations, uploaded files, and settings.')) {
                $.ajax({
                    url: '/reset_everything',
                    type: 'POST',
                    success: function() {
                        location.reload();
                    }
                });
            }
        });
        
        // No need for complex initialization - the model is pre-selected from the backend
        // If there's text in the input, enable the send button
        if ($('#messageInput').val().trim() !== '') {
            $('#sendBtn').prop('disabled', false);
        }
    
    // Function to load and display suggestion questions
    function loadSuggestionQuestions() {
        $.ajax({
            url: '/example_questions',
            type: 'GET',
            success: function(questions) {
                const container = $('#suggestionQuestionsList');
                container.empty();
                
                if (questions && questions.length > 0) {
                    questions.forEach(function(question) {
                        const button = $('<button>')
                            .addClass('btn suggestion-question-btn')
                            .text(question)
                            .on('click', function() {
                                $('#messageInput').val(question);
                                $('#messageInput').trigger('input');
                                $('#messageInput').focus();
                                $('#sendBtn').click();
                            });
                        container.append(button);
                    });
                } else {
                    container.html('<p class="text-muted small">No suggestions available</p>');
                }
            },
            error: function(xhr, status, error) {
                console.error('Error loading example questions:', error);
                console.error('Response:', xhr.responseText);
                $('#suggestionQuestionsList').html('<p class="text-muted small">Unable to load suggestions</p>');
            }
        });
    }
    
    // Follow-Up Questions Functionality
    window.lastFollowupMessageId = null;
    
    /**
     * Fetch follow-up questions from the API
     * @param {string} userQuestion - The user's question
     * @param {string} aiResponse - The AI's response
     * @param {Array} conversationHistory - Recent conversation history
     * @param {string} model - The AI model used
     * @returns {Promise<Array>} - Promise resolving to array of questions
     */
    async function fetchFollowUpQuestions(userQuestion, aiResponse, conversationHistory, model) {
        try {
            const response = await $.ajax({
                url: '/suggest_followup',
                type: 'POST',
                contentType: 'application/json',
                data: JSON.stringify({
                    user_question: userQuestion,
                    ai_response: aiResponse,
                    conversation_history: conversationHistory || [],
                    session_id: 'ui_session_' + Date.now(),
                    model: model
                })
            });
            
            if (response.success && response.followup_questions && response.followup_questions.length > 0) {
                let questions = response.followup_questions;
                
                // Handle case where all questions come as a single string with \n separators
                if (questions.length === 1 && questions[0].includes('\\n')) {
                    console.log('[FOLLOWUP] Detected single string with \\n separators, splitting...');
                    const splitQuestions = questions[0].split('\\n\\n')
                        .map(q => q.trim())
                        .filter(q => q.length > 10);
                    
                    if (splitQuestions.length > 1) {
                        questions = splitQuestions;
                        console.log('[FOLLOWUP] Split into', questions.length, 'questions');
                    } else {
                        // Try splitting by single \n if \n\n didn't work
                        const singleSplit = questions[0].split('\\n')
                            .map(q => q.trim())
                            .filter(q => q.length > 10);
                        if (singleSplit.length > 1) {
                            questions = singleSplit;
                            console.log('[FOLLOWUP] Split by single \\n into', questions.length, 'questions');
                        }
                    }
                }
                
                console.log('[FOLLOWUP] Final questions array:', questions);
                return questions;
            }
            return [];
        } catch (error) {
            console.error('Error fetching follow-up questions:', error);
            return [];
        }
    }
    
    /**
     * Render follow-up questions component
     * @param {Array} questions - Array of question strings
     * @param {jQuery} messageElement - The message element to append to
     */
    function renderFollowUpQuestions(questions, messageElement) {
        console.log('[FOLLOWUP] Rendering questions:', questions);
        console.log('[FOLLOWUP] Number of questions received:', questions ? questions.length : 0);
        
        if (!questions || questions.length === 0) {
            console.log('[FOLLOWUP] No questions to render');
            return;
        }
        
        // Remove any existing follow-up containers from all messages
        $('.followup-container').remove();
        
        // Create follow-up container
        const container = $('<div>').addClass('followup-container');
        
        // Add header with lightbulb icon
        const header = $('<div>').addClass('followup-header');
        const icon = $('<i>').addClass('fas fa-lightbulb');
        const text = $('<span>').text('Suggested questions:');
        header.append(icon).append(text);
        container.append(header);
        
        // Add questions container
        const questionsContainer = $('<div>').addClass('followup-questions');
        
        questions.forEach((question, index) => {
            console.log(`[FOLLOWUP] Processing question ${index + 1}:`, question);
            if (question && question.trim()) {
                const questionCard = $('<button>')
                    .addClass('followup-question-card')
                    .attr('type', 'button')
                    .text(question.trim())
                    .on('click', function() {
                        handleFollowUpClick(question.trim());
                    });
                questionsContainer.append(questionCard);
                console.log(`[FOLLOWUP] Added question ${index + 1} to DOM`);
            } else {
                console.log(`[FOLLOWUP] Skipping empty question ${index + 1}`);
            }
        });
        
        container.append(questionsContainer);
        
        // Insert AFTER the message container (not inside it)
        messageElement.after(container);
        
        console.log('[FOLLOWUP] Container inserted after message element');
        
        // Store the message ID for tracking
        window.lastFollowupMessageId = messageElement.attr('id') || Date.now();
        
        // Scroll to show the new questions
        scrollToBottom();
    }
    
    /**
     * Show loading state for follow-up questions
     * @param {jQuery} messageElement - The message element to insert after
     */
    function showFollowUpLoading(messageElement) {
        const container = $('<div>').addClass('followup-container');
        const loadingDiv = $('<div>').addClass('followup-loading');
        loadingDiv.append($('<div>').addClass('spinner'));
        loadingDiv.append($('<span>').text('Generating suggested questions...'));
        container.append(loadingDiv);
        // Insert AFTER the message container (not inside it)
        messageElement.after(container);
    }
    
    /**
     * Handle click on a follow-up question
     * @param {string} question - The selected question
     */
    function handleFollowUpClick(question) {
        // Remove all follow-up containers
        $('.followup-container').remove();
        
        // Populate input with the question
        $('#messageInput').val(question);
        
        // Trigger input event to enable send button
        $('#messageInput').trigger('input');
        
        // Focus on input
        $('#messageInput').focus();
        
        // Auto-send the question
        setTimeout(() => {
            $('#sendBtn').click();
        }, 100);
    }
    
    // Expose functions globally for use in other parts of the code
    window.fetchFollowUpQuestions = fetchFollowUpQuestions;
    window.renderFollowUpQuestions = renderFollowUpQuestions;
    window.showFollowUpLoading = showFollowUpLoading;
    window.handleFollowUpClick = handleFollowUpClick;
    
    });
});
