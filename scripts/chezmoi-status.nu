#!/usr/bin/env nu

# Import unified libraries
use lib/unified-checks.nu
use lib/enhanced-error-handling.nu

# Show chezmoi status
# This script shows the current status of chezmoi configuration

def main [] {
    enhanced-error-handling log_info "Showing chezmoi status..." "chezmoi-status"
    
    let result = (enhanced-error-handling safe_exec "chezmoi status" "chezmoi-status")
    if $result.success {
        enhanced-error-handling log_success "Chezmoi status retrieved successfully" "chezmoi-status"
        enhanced-error-handling exit_with_success "Status displayed" "chezmoi-status"
    } else {
        enhanced-error-handling log_error "Failed to get chezmoi status" "chezmoi-status"
        enhanced-error-handling exit_with_error "Status check failed" 1 "chezmoi-status"
    }
}

main 