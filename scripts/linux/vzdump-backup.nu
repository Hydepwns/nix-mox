# vzdump-backup.nu - Backup Proxmox VMs using vzdump
# Usage: sudo nu vzdump-backup.nu [--dry-run] [--help]
#
# - Creates backups of all VMs using vzdump
# - Compresses backups using zstd
# - Maintains a backup log
# - Is idempotent and safe to re-run

use ../lib/common.nu

# Script-specific variables
$env.STORAGE = ($env.STORAGE? | default "backup")
$env.DRY_RUN = false

# Function to list and back up items (VMs or CTs)
def backup_items [list_cmd: string, item_type: string] {
    let ids = (do { nu -c $list_cmd } | complete | get stdout | lines | skip 1 | split column " " | get column1)

    if ($ids | length) == 0 {
        log_info $"No ($item_type)s found to back up."
        return
    }

    for id in $ids {
        log_info $"Processing backup for ($item_type) ($id)..."
        if $env.DRY_RUN {
            log_dryrun $"Would back up ($item_type) ($id) to storage '($env.STORAGE)'"
        } else {
            try {
                vzdump $id --storage $env.STORAGE --mode snapshot --compress zstd
                log_success $"Successfully backed up ($item_type) ($id)."
            } catch {
                log_error $"Failed to back up ($item_type) ($id)."
                return true
            }
        }
    }
    return false
}

def main [] {
    # Parse arguments
    let args = $env._args
    for arg in $args {
        match $arg {
            "--dry-run" => { $env.DRY_RUN = true }
            "--storage" => {
                let idx = ($args | find $arg | get 0)
                $env.STORAGE = ($args | get ($idx + 1))
            }
            "--help" | "-h" => { usage }
            _ => {
                log_error $"Unknown option: ($arg)"
                usage
            }
        }
    }

    check_root

    # Check for required commands
    for cmd in ["vzdump", "qm", "pct"] {
        if not ((which $cmd | length | into int) > 0) {
            log_error $"Required command '($cmd)' not found."
            exit 1
        }
    }

    log_info "Starting Proxmox backup process..."

    let backup_failed = false

    # Run backup process
    try {
        $env.backup_failed = (backup_items "qm list" "VM")
        if not $env.backup_failed {
            $env.backup_failed = (backup_items "pct list" "CT")
        }
    } catch {
        log_error $"An unexpected error occurred: ($env.LAST_ERROR)"
        exit 1
    }

    # Final status reporting
    if $env.backup_failed {
        log_error "vzdump backup completed with one or more errors."
        exit 1
    } else {
        if $env.DRY_RUN {
            log_dryrun "Dry run complete. No backups were performed."
        } else {
            log_success "vzdump backup completed successfully."
        }
    }
}

# --- Execution ---
main