// Main JavaScript for the Flask application
// Shared utilities and general-purpose functions

document.addEventListener('DOMContentLoaded', function() {
    // Scroll chat to bottom when page loads
    const chatContainer = document.getElementById('chatContainer');
    if (chatContainer) {
        chatContainer.scrollTop = chatContainer.scrollHeight;
    }
    
    // Initialize any tooltip or popover components
    const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    const tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
        return new bootstrap.Tooltip(tooltipTriggerEl);
    });
    
    // Handle Enter key in message input (general handler)
    const messageInput = document.getElementById('messageInput');
    if (messageInput) {
        messageInput.addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                e.preventDefault();
                const sendBtn = document.getElementById('sendBtn');
                if (sendBtn) sendBtn.click();
            }
        });
    }
    
    // Module-specific initialization is handled by module scripts
});

// ============================================================================
// SHARED UTILITY FUNCTIONS
// ============================================================================

/**
 * Scroll to bottom of chat
 */
function scrollToBottom() {
    const chatContainer = $('#chatMessages');
    if (chatContainer.length) {
        // Use requestAnimationFrame for better performance
        requestAnimationFrame(() => {
            const scrollHeight = chatContainer[0].scrollHeight;
            const currentScroll = chatContainer.scrollTop();
            const containerHeight = chatContainer.height();
            
            // Only scroll if we're not already at the bottom (within 50px tolerance)
            if (scrollHeight - currentScroll - containerHeight > 50) {
                chatContainer.animate({
                    scrollTop: scrollHeight
                }, 400);
            }
        });
    }
}

/**
 * Escape HTML to prevent XSS
 */
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

/**
 * Download file helper
 */
function downloadFile(content, filename, mimeType) {
    try {
        const blob = new Blob([content], { type: mimeType });
        const url = URL.createObjectURL(blob);
        
        const a = document.createElement('a');
        a.href = url;
        a.download = filename;
        a.style.display = 'none';
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
        
    } catch (error) {
        console.error('Download failed:', error);
        throw error;
    }
}
