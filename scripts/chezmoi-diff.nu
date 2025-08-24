#!/usr/bin/env nu

# Import unified libraries
use lib/unified-checks.nu
use lib/unified-error-handling.nu

# Show chezmoi differences
# This script shows differences between chezmoi templates and current system

def main [] {
    unified-error-handling log_info "Checking chezmoi differences..." "chezmoi-diff"
    
    let result = (unified-error-handling safe_exec "chezmoi diff" "chezmoi-diff")
    if $result.success {
        unified-error-handling log_success "Chezmoi differences checked successfully" "chezmoi-diff"
        unified-error-handling exit_with_success "Differences checked" "chezmoi-diff"
    } else {
        unified-error-handling log_error "Failed to check chezmoi differences" "chezmoi-diff"
        unified-error-handling exit_with_error "Diff check failed" 1 "chezmoi-diff"
    }
}

main
