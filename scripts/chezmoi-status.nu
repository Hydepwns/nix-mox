#!/usr/bin/env nu

# Import unified libraries
use lib/unified-checks.nu
use lib/unified-error-handling.nu

# Show chezmoi status
# This script shows the current status of chezmoi configuration

def main [] {
    unified-error-handling log_info "Showing chezmoi status..." "chezmoi-status"
    
    let result = (unified-error-handling safe_exec "chezmoi status" "chezmoi-status")
    if $result.success {
        unified-error-handling log_success "Chezmoi status retrieved successfully" "chezmoi-status"
        unified-error-handling exit_with_success "Status displayed" "chezmoi-status"
    } else {
        unified-error-handling log_error "Failed to get chezmoi status" "chezmoi-status"
        unified-error-handling exit_with_error "Status check failed" 1 "chezmoi-status"
    }
}

main 