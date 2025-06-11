# vzdump-backup.nu - Backup Proxmox VMs using vzdump
# Usage: sudo nu vzdump-backup.nu [--dry-run] [--help]
#
# - Creates backups of all VMs using vzdump
# - Compresses backups using zstd
# - Maintains a backup log
# - Is idempotent and safe to re-run

use ../../scripts/_common.nu *

# Proxmox vzdump Backup Script
# Usage: sudo nu vzdump-backup.nu [--dry-run] [--storage NAME] [--help]
# Logs to /var/log/vzdump-backup.log
#
# Options:
#   --dry-run         Show what would be done, but make no changes
#   --storage NAME    Set backup storage name (default: backup or $STORAGE)
#   --help            Show this help message

# Script-specific variables
const LOGFILE = "/var/log/vzdump-backup.log"
let STORAGE = ($env.STORAGE? | default "backup")
let DRY_RUN = false

# Ensure log file exists and is writable
try {
    touch $LOGFILE
} catch {
    log_error $"Log file is not writable: ($LOGFILE)"
    exit 1
}

# Function to list and back up items (VMs or CTs)
def backup_items [list_cmd: string, item_type: string] {
    let ids = (do $list_cmd | lines | skip 1 | split column " " | get column1)

    if ($ids | length) == 0 {
        log_info $"No ($item_type)s found to back up." $LOGFILE
        return
    }

    for id in $ids {
        log_info $"Processing backup for ($item_type) ($id)..." $LOGFILE
        if $DRY_RUN {
            log_dryrun $"Would back up ($item_type) ($id) to storage '($STORAGE)'" $LOGFILE
        } else {
            try {
                vzdump $id --storage $STORAGE --mode snapshot --compress zstd
                log_success $"Successfully backed up ($item_type) ($id)." $LOGFILE
            } catch {
                log_error $"Failed to back up ($item_type) ($id)." $LOGFILE
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
            "--dry-run" => { $DRY_RUN = true }
            "--storage" => {
                let idx = ($args | find $arg | get 0)
                $STORAGE = $args.($idx + 1)
            }
            "--help" | "-h" => { usage }
            _ => {
                log_error $"Unknown option: ($arg)" $LOGFILE
                usage
            }
        }
    }

    check_root $LOGFILE

    # Check for required commands
    for cmd in ["vzdump", "qm", "pct"] {
        if not (which $cmd | length) > 0 {
            log_error $"Required command '($cmd)' not found." $LOGFILE
            exit 1
        }
    }

    log_info "Starting Proxmox backup process..." $LOGFILE

    let mut backup_failed = false

    # Run backup process and redirect all output to the log file
    try {
        $backup_failed = (backup_items "qm list" "VM")
        if not $backup_failed {
            $backup_failed = (backup_items "pct list" "CT")
        }
    } catch {
        log_error $"An unexpected error occurred: ($env.LAST_ERROR)" $LOGFILE
        exit 1
    }

    # Final status reporting
    if $backup_failed {
        log_error "vzdump backup completed with one or more errors." $LOGFILE
        exit 1
    } else {
        if $DRY_RUN {
            log_dryrun "Dry run complete. No backups were performed." $LOGFILE
        } else {
            log_success "vzdump backup completed successfully." $LOGFILE
        }
    }
}

# --- Execution ---
main 