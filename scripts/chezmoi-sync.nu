#!/usr/bin/env nu

# Import unified libraries
use lib/unified-checks.nu
use lib/unified-error-handling.nu

# Sync chezmoi with remote repository
# This script syncs chezmoi templates with the remote repository

def main [] {
    unified-error-handling log_info "Syncing chezmoi with remote repository..." "chezmoi-sync"
    
    let result = (unified-error-handling safe_exec "chezmoi update" "chezmoi-sync")
    if $result.success {
        unified-error-handling log_success "Chezmoi synced successfully" "chezmoi-sync"
        unified-error-handling exit_with_success "Sync completed" "chezmoi-sync"
    } else {
        unified-error-handling log_error "Failed to sync chezmoi" "chezmoi-sync"
        unified-error-handling exit_with_error "Sync failed" 1 "chezmoi-sync"
    }
}

main
