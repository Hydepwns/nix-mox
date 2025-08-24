#!/usr/bin/env nu

# Import unified libraries
use lib/unified-checks.nu
use lib/enhanced-error-handling.nu

# Show chezmoi differences
# This script shows differences between chezmoi templates and current system

def main [] {
    enhanced-error-handling log_info "Checking chezmoi differences..." "chezmoi-diff"
    
    let result = (enhanced-error-handling safe_exec "chezmoi diff" "chezmoi-diff")
    if $result.success {
        enhanced-error-handling log_success "Chezmoi differences checked successfully" "chezmoi-diff"
        enhanced-error-handling exit_with_success "Differences checked" "chezmoi-diff"
    } else {
        enhanced-error-handling log_error "Failed to check chezmoi differences" "chezmoi-diff"
        enhanced-error-handling exit_with_error "Diff check failed" 1 "chezmoi-diff"
    }
}

main
