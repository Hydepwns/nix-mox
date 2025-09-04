#!/usr/bin/env nu
# Consolidated chezmoi management script
# Replaces: chezmoi-apply.nu, chezmoi-status.nu, chezmoi-diff.nu, chezmoi-sync.nu
# Uses functional patterns and command wrapper library

use ./lib/logging.nu
use ./lib/command-wrapper.nu
use ./lib/validators.nu

# Main chezmoi command dispatcher
def main [
    ...args
] {
    let command = ($args | get 0 | default "help")
    let dry_run = ("--dry-run" in $args)
    let context = "chezmoi"
    info $"chezmoi ($command)" --context $context
    
    # Validate chezmoi is available
    let validation = (validate_command "chezmoi")
    if not $validation.success {
        print "chezmoi command not found - please install chezmoi first"
        return
    }
    
    # Dispatch to appropriate handler
    match $command {
        "apply" => (if $dry_run { chezmoi_apply --dry-run --context $context } else { chezmoi_apply --context $context }),
        "status" => (chezmoi_status --context $context),
        "diff" => (chezmoi_diff --context $context),
        "sync" => (chezmoi_sync --context $context),
        "update" => (chezmoi_sync --context $context),
        "verify" => (chezmoi_verify --context $context),
        "edit" => (chezmoi_edit --context $context),
        "help" => (show_help),
            _ => {
                print $"Unknown command: ($command). Use 'help' to see available commands."
                show_help
            }
        }
}

# Apply chezmoi configuration
def chezmoi_apply [--dry-run, --context: string = "chezmoi"] {
    info "Applying chezmoi configuration..." --context $context
    
    if $dry_run {
        print "Would apply chezmoi configuration"
        chezmoi_command "diff" --context $context --dry-run
    } else {
        let result = (chezmoi_command "apply" --context $context)
        if $result.exit_code == 0 {
            print "Chezmoi configuration applied successfully"
        } else {
            print "Failed to apply chezmoi configuration"
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
            print "Chezmoi configuration is up to date"
        } else {
            print "Chezmoi has pending changes:"
            print $result.stdout
        }
    } else {
        print "Failed to check chezmoi status"
    }
    $result
}

# Show chezmoi differences
def chezmoi_diff [--context: string = "chezmoi"] {
    info "Showing chezmoi differences..." --context $context
    
    let result = (chezmoi_command "diff" --context $context)
    if $result.exit_code == 0 {
        if ($result.stdout | str length) == 0 {
            print "No differences found"
        } else {
            print "Configuration differences:"
            print $result.stdout
        }
    } else {
        print "Failed to show chezmoi differences"
    }
    $result
}

# Sync chezmoi with remote repository
def chezmoi_sync [--dry-run, --context: string = "chezmoi"] {
    info "Syncing chezmoi with remote repository..." --context $context
    
    # First update from remote
    let update_result = (chezmoi_command "update" --context $context)
    if $update_result.exit_code != 0 {
        print "Failed to update from remote repository"
        return $update_result
    }
    
    # Then apply any changes
    let apply_result = (if $dry_run { chezmoi_apply --dry-run --context $context } else { chezmoi_apply --context $context })
    if $apply_result.exit_code == 0 {
        print "Chezmoi sync completed successfully"
    } else {
        print "Chezmoi sync failed during apply phase"
    }
    $apply_result
}

# Verify chezmoi configuration
def chezmoi_verify [--context: string = "chezmoi"] {
    info "Verifying chezmoi configuration..." --context $context
    
    let result = (chezmoi_command "verify" --context $context)
    if $result.exit_code == 0 {
        print "Chezmoi configuration verification passed"
    } else {
        print "Chezmoi configuration verification failed"
    }
    $result
}

# Edit chezmoi configuration
def chezmoi_edit [--context: string = "chezmoi"] {
    info "Opening chezmoi configuration for editing..." --context $context
    
    let result = (chezmoi_command "edit" --context $context)
    if $result.exit_code == 0 {
        print "Chezmoi edit session completed"
    } else {
        print "Failed to open chezmoi editor"
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