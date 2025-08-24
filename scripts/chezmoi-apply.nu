#!/usr/bin/env nu

# Import unified libraries
use lib/unified-checks.nu
use lib/unified-error-handling.nu

# Apply chezmoi configuration
# This script applies chezmoi templates to the system

def main [] {
    unified-error-handling log_info "Applying chezmoi configuration..." "chezmoi-apply"
    
    let result = (unified-error-handling safe_exec "chezmoi apply" "chezmoi-apply")
    if $result.success {
        unified-error-handling log_success "Chezmoi configuration applied successfully" "chezmoi-apply"
        unified-error-handling exit_with_success "Configuration applied" "chezmoi-apply"
    } else {
        unified-error-handling log_error "Failed to apply chezmoi configuration" "chezmoi-apply"
        unified-error-handling exit_with_error "Configuration failed" 1 "chezmoi-apply"
    }
}

main
