#!/usr/bin/env nu

# Import unified libraries
use lib/unified-checks.nu
use lib/enhanced-error-handling.nu

# Apply chezmoi configuration
# This script applies chezmoi templates to the system

def main [] {
    enhanced-error-handling log_info "Applying chezmoi configuration..." "chezmoi-apply"
    
    let result = (enhanced-error-handling safe_exec "chezmoi apply" "chezmoi-apply")
    if $result.success {
        enhanced-error-handling log_success "Chezmoi configuration applied successfully" "chezmoi-apply"
        enhanced-error-handling exit_with_success "Configuration applied" "chezmoi-apply"
    } else {
        enhanced-error-handling log_error "Failed to apply chezmoi configuration" "chezmoi-apply"
        enhanced-error-handling exit_with_error "Configuration failed" 1 "chezmoi-apply"
    }
}

main
