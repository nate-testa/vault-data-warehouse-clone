/**
 * Applications Page JavaScript
 * Extracted from applications.html - 2025-01-21
 * 
 * Handles interactions on the applications page
 */

document.addEventListener('DOMContentLoaded', function() {
    // Handle clicks on disabled applications - prevent any action
    document.querySelectorAll('.app-card.disabled').forEach(function(card) {
        card.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            // Do nothing when clicking on disabled applications
            return false;
        });
    });
    
    // Log page access (username injected via template)
    const username = document.body.getAttribute('data-username') || 'Unknown';
    console.log('Applications page loaded for user: ' + username);
});
