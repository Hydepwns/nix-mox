#!/usr/bin/env nu

# Import unified libraries
use ../../lib/validators.nu
use ../../lib/logging.nu *
use ../../lib/command-wrapper.nu *

# vzdump-backup.nu - Backup Proxmox VMs using vzdump
# Usage: sudo nu vzdump-backup.nu [--dry-run] [--storage <storage>] [--help]
#
# - Creates backups of all VMs and containers using vzdump
# - Compresses backups using zstd
# - Maintains a backup log
# - Is idempotent and safe to re-run

# --- Global Variables ---
const LOGFILE = "/var/log/vzdump-backup.log"

def update_state [field: string, value: any] {
    $env.STATE = ($env.STATE | upsert $field $value)
}

def main [] {
    $env.STATE = {
        dry_run: false
        storage: "backup"
        backup_failed: false
        created_files: []
    }

    # --- Argument Parsing ---
    let args = $env._args
    for arg in $args {
        match $arg {
            "--dry-run" => {
                $env.STATE = ($env.STATE | upsert dry_run true)
            }
            "--storage" => {
                let idx = ($args | find $arg | first)
                let new_storage = ($args | get ($idx + 1))
                if ($new_storage | is-empty) {
                    error "Storage name must be provided after --storage"
                    usage
                }
                $env.STATE = ($env.STATE | upsert storage $new_storage)
            }
            "--help" | "-h" => {
                usage
            }
            _ => {
                error $"Unknown option: ($arg)"
                usage
            }
        }
    }

    check_root

    if $env.STATE.dry_run {
        log_dryrun "Dry-run mode enabled. No backups will be performed."
    }

    # Check for required commands
    for cmd in ["vzdump", "qm", "pct"] {
        if not ((which $cmd | length | into int) > 0) {
            error $"Required command '($cmd)' not found."
            exit 1
        }
    }

    # Ensure log file exists and is writable
    try {
        let log_dir = ($LOGFILE | path dirname)
        if not ($log_dir | path exists) {
            mkdir $log_dir
        }
        touch $LOGFILE
    } catch {
        warn $"Could not create log file ($LOGFILE). Continuing without logging."
    }

    info "Starting Proxmox backup process..."

    # Run backup process
    try {
        # Backup VMs
        let vm_backup_failed = backup_items "qm list" "VM"
        $env.STATE = ($env.STATE | upsert backup_failed $vm_backup_failed)

        # Backup Containers
        let ct_backup_failed = backup_items "pct list" "CT"
        $env.STATE = ($env.STATE | upsert backup_failed ($env.STATE.backup_failed or $ct_backup_failed))
    } catch {
        error $"An unexpected error occurred: ($env.LAST_ERROR)"
        exit 1
    }

    # Final status reporting
    if $env.STATE.backup_failed {
        error "vzdump backup completed with one or more errors."
        exit 1
    } else {
        if $env.STATE.dry_run {
            log_dryrun "Dry run complete. No backups were performed."
        } else {
            success "vzdump backup completed successfully."
        }
    }

    return $env.STATE
}

def backup_items [list_cmd: string, item_type: string] {
    # Get list of items to backup
    let ids = (safe_command_with_fallback $"nu -c '($list_cmd)'" "" --context "proxmox-backup" | lines | skip 1 | split column " " | get column1)

    if ($ids | length) == 0 {
        info $"No ($item_type)s found to back up."
        return false
    }

    # Process each item and collect results
    let results = ($ids | each { | id|
        info $"Processing backup for ($item_type) ($id)..."

        if $env.STATE.dry_run {
            log_dryrun $"Would back up ($item_type) ($id) to storage '($env.STATE.storage)'"
            false
        } else {
            try {
                vzdump $id --storage $env.STATE.storage --mode snapshot --compress zstd
                success $"Successfully backed up ($item_type) ($id)."
                false
            } catch {
                error $"Failed to back up ($item_type) ($id): ($env.LAST_ERROR)"
                true
            }
        }
    })

    # Return true if any backup failed
    $results | any { | result| $result == true }
}

def usage [] {
    print "Usage: sudo nu vzdump-backup.nu [OPTIONS]"
    print ""
    print "Backup Proxmox VMs and containers using vzdump."
    print ""
    print "Options:"
    print "  --dry-run              Show what would be done, but make no changes"
    print "  --storage <storage>    Specify storage location (default: backup)"
    print "  --help, -h             Show this help message"
    print ""
    print "This script:"
    print "• Creates backups of all VMs and containers"
    print "• Uses snapshot mode for consistent backups"
    print "• Compresses backups using zstd"
    print "• Maintains a backup log at /var/log/vzdump-backup.log"
    print ""
    print "Examples:"
    print "  sudo nu vzdump-backup.nu"
    print "  sudo nu vzdump-backup.nu --dry-run"
    print "  sudo nu vzdump-backup.nu --storage local"
    exit 0
}

# --- Execution ---
try {
    main
} catch {
    error $"Backup failed: ($env.LAST_ERROR)"
    exit 1
}
