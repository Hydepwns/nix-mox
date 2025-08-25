#!/usr/bin/env nu
# Consolidated chezmoi management script
# Replaces: chezmoi-apply.nu, chezmoi-status.nu, chezmoi-diff.nu, chezmoi-sync.nu
# Uses functional patterns and command wrapper library

use lib/logging.nu *
use lib/command-wrapper.nu *
use lib/validators.nu *

# Main chezmoi command dispatcher
def main [
    ...args
] {
    let command = ($args | get -o 0 | default "help")
    let dry_run = ("--dry-run" in $args)
    let context = "chezmoi"
    info $"chezmoi ($command)" --context $context
    
    # Validate chezmoi is available
    let validation = (validate_command "chezmoi")
    if not $validation.success {
        error "chezmoi command not found - please install chezmoi first" --context $context
        return
    }
    
    # Dispatch to appropriate handler
    match $command {
        "apply" => (chezmoi_apply --dry-run $dry_run --context $context),
        "status" => (chezmoi_status --context $context),
        "diff" => (chezmoi_diff --context $context),
        "sync" => (chezmoi_sync --context $context),
        "update" => (chezmoi_sync --context $context),
        "verify" => (chezmoi_verify --context $context),
        "edit" => (chezmoi_edit --context $context),
        "help" => (show_help),
            _ => {
                error $"Unknown command: ($command). Use 'help' to see available commands." --context $context
                show_help
            }
        }
}

# Apply chezmoi configuration
def chezmoi_apply [--dry-run, --context: string = "chezmoi"] {
    info "Applying chezmoi configuration..." --context $context
    
    if $dry_run {
        dry_run "Would apply chezmoi configuration" --context $context
        chezmoi_command "diff" --context $context --dry-run $dry_run
    } else {
        let result = (chezmoi_command "apply" --context $context)
        if $result.exit_code == 0 {
            success "Chezmoi configuration applied successfully" --context $context
        } else {
            error "Failed to apply chezmoi configuration" --context $context
        }
        $result
    }
}

# Show chezmoi status
def chezmoi_status [--context: string = "chezmoi"] {
    info "Checking chezmoi status..." --context $context
    
    let result = (chezmoi_command "status" --context $context)
    if $result.exit_code == 0 {
        if ($result.stdout | str length) == 0 {
            success "Chezmoi configuration is up to date" --context $context
        } else {
            warn "Chezmoi has pending changes:" --context $context
            print $result.stdout
        }
    } else {
        error "Failed to check chezmoi status" --context $context
    }
    $result
}

# Show chezmoi differences
def chezmoi_diff [--context: string = "chezmoi"] {
    info "Showing chezmoi differences..." --context $context
    
    let result = (chezmoi_command "diff" --context $context)
    if $result.exit_code == 0 {
        if ($result.stdout | str length) == 0 {
            success "No differences found" --context $context
        } else {
            info "Configuration differences:" --context $context
            print $result.stdout
        }
    } else {
        error "Failed to show chezmoi differences" --context $context
    }
    $result
}

# Sync chezmoi with remote repository
def chezmoi_sync [--context: string = "chezmoi"] {
    info "Syncing chezmoi with remote repository..." --context $context
    
    # First update from remote
    let update_result = (chezmoi_command "update" --context $context)
    if $update_result.exit_code != 0 {
        error "Failed to update from remote repository" --context $context
        return $update_result
    }
    
    # Then apply any changes
    let apply_result = (chezmoi_apply --context $context)
    if $apply_result.exit_code == 0 {
        success "Chezmoi sync completed successfully" --context $context
    } else {
        error "Chezmoi sync failed during apply phase" --context $context
    }
    $apply_result
}

# Verify chezmoi configuration
def chezmoi_verify [--context: string = "chezmoi"] {
    info "Verifying chezmoi configuration..." --context $context
    
    let result = (chezmoi_command "verify" --context $context)
    if $result.exit_code == 0 {
        success "Chezmoi configuration verification passed" --context $context
    } else {
        error "Chezmoi configuration verification failed" --context $context
    }
    $result
}

# Edit chezmoi configuration
def chezmoi_edit [--context: string = "chezmoi"] {
    info "Opening chezmoi configuration for editing..." --context $context
    
    let result = (chezmoi_command "edit" --context $context)
    if $result.exit_code == 0 {
        success "Chezmoi edit session completed" --context $context
    } else {
        error "Failed to open chezmoi editor" --context $context
    }
    $result
}

# Show help information
def show_help [] {
    print "Consolidated Chezmoi Management Script"
    print "====================================="
    print ""
    print "Usage: nu chezmoi.nu <command> [options]"
    print ""
    print "Commands:"
    print "  apply      Apply chezmoi configuration to system"
    print "  status     Show current chezmoi status"
    print "  diff       Show differences between current and target state"
    print "  sync       Sync with remote repository and apply changes"
    print "  update     Alias for sync"
    print "  verify     Verify chezmoi configuration"
    print "  edit       Edit chezmoi configuration"
    print "  help       Show this help message"
    print ""
    print "Options:"
    print "  --dry-run  Show what would be done without making changes (apply only)"
    print "  --context  Set logging context (default: chezmoi)"
    print ""
    print "Examples:"
    print "  nu chezmoi.nu apply                # Apply configuration"
    print "  nu chezmoi.nu apply --dry-run      # Show what would be applied"
    print "  nu chezmoi.nu status               # Check status"
    print "  nu chezmoi.nu sync                 # Sync and apply"
}

# Main entry point when script is executed
# Use: nu scripts/chezmoi.nu apply