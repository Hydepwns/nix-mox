#!/usr/bin/env nu
# zfs-snapshot.nu - ZFS Snapshot & Prune Script
# Usage: sudo nu zfs-snapshot.nu [--dry-run] [--retention DAYS] [--pool NAME] [--help]
#
# - Creates ZFS snapshots with automatic naming
# - Prunes old snapshots based on retention policy
# - Maintains a backup log
# - Is idempotent and safe to re-run
use ../lib/common.nu

# --- Global Variables ---
const SNAP_NAME_PREFIX = "auto-"
const SNAP_DATE_FORMAT = "%Y-%m-%d-%H%M"
const LOGFILE = "/var/log/zfs-snapshot.log"

def update-state [field: string, value: any] {
    $env.STATE = ($env.STATE | upsert $field $value)
}

def main [] {
    $env.STATE = {
        dry_run: false
        retention_days: 7
        pool: "rpool"
        prune_failed: false
        created_files: []
    }

    # --- Argument Parsing ---
    let args = $env._args
    for arg in $args {
        match $arg {
            "--dry-run" => {
                $env.STATE = ($env.STATE | upsert dry_run true)
            }
            "--retention" => {
                let idx = ($args | find $arg | get 0)
                let new_retention = ($args | get ($idx + 1))
                if ($new_retention | is-empty) {
                    log_error "Retention days must be provided after --retention"
                    usage
                }
                $env.STATE = ($env.STATE | upsert retention_days ($new_retention | into int))
            }
            "--pool" => {
                let idx = ($args | find $arg | get 0)
                let new_pool = ($args | get ($idx + 1))
                if ($new_pool | is-empty) {
                    log_error "Pool name must be provided after --pool"
                    usage
                }
                $env.STATE = ($env.STATE | upsert pool $new_pool)
            }
            "--help" | "-h" => {
                usage
            }
            _ => {
                log_error $"Unknown option: ($arg)"
                usage
            }
        }
    }

    check_root

    if $env.STATE.dry_run {
        log_dryrun "Dry-run mode enabled. No changes will be made."
    }

    # Check for required command
    if not ((which zfs | length | into int) > 0) {
        log_error "Required command 'zfs' not found."
        exit 1
    }

    # Ensure log file exists and is writable
    try {
        let log_dir = ($LOGFILE | path dirname)
        if not ($log_dir | path exists) {
            mkdir $log_dir
        }
        touch $LOGFILE
    } catch {
        log_warn $"Could not create log file ($LOGFILE). Continuing without logging."
    }

    # --- Snapshot Creation ---
    log_info $"Starting ZFS snapshot process for pool: ($env.STATE.pool)"
    create_snapshot

    # --- Snapshot Pruning ---
    log_info $"Pruning snapshots in '($env.STATE.pool)' older than ($env.STATE.retention_days) days with prefix '($SNAP_NAME_PREFIX)'..."
    prune_snapshots

    # --- Final Status ---
    if $env.STATE.prune_failed {
        log_error $"ZFS snapshot/prune for pool '($env.STATE.pool)' completed with errors during pruning."
        exit 1
    } else {
        if $env.STATE.dry_run {
            log_dryrun "Dry run complete. No changes were made."
        } else {
            log_success $"ZFS snapshot/prune for pool '($env.STATE.pool)' complete."
        }
    }

    return $env.STATE
}

def create_snapshot [] {
    let snap_name = $SNAP_NAME_PREFIX + (date now | format date $SNAP_DATE_FORMAT)
    let full_snap_name = $"($env.STATE.pool)@($snap_name)"

    # Check if snapshot already exists
    let existing_snapshots = (zfs list -t snapshot -H -o name | lines)
    if ($existing_snapshots | any { |snap| $snap == $full_snap_name }) {
        log_warn $"Snapshot ($full_snap_name) already exists. Skipping creation."
        return
    }

    if $env.STATE.dry_run {
        log_dryrun $"Would create ZFS snapshot: ($full_snap_name)"
    } else {
        log_info $"Creating ZFS snapshot: ($full_snap_name)..."
        try {
            zfs snapshot -r $full_snap_name
            log_success $"Successfully created snapshot ($full_snap_name)."
        } catch {
            log_error $"Failed to create snapshot ($full_snap_name): ($env.LAST_ERROR)"
        }
    }
}

def prune_snapshots [] {
    # Validate retention period
    if not ($env.STATE.retention_days | into string | str contains "^[0-9]+$") {
        log_error $"Invalid retention period: '($env.STATE.retention_days)' is not a number. Skipping prune."
        exit 1
    }

    # Calculate time cutoff
    let time_cutoff = ((date now) - ($env.STATE.retention_days * 24hr) | into int)

    # Get snapshots with creation timestamps
    let snapshots = (zfs list -p -H -t snapshot -o name,creation -S creation -r $env.STATE.pool | lines | split column " " name creation)

    # Process each snapshot
    let results = ($snapshots | each { |snapshot|
        # Filter for our auto-generated snapshots
        if not ($snapshot.name | str contains $"@($SNAP_NAME_PREFIX)") {
            false
        } else if ($snapshot.creation | into int) < $time_cutoff {
            if $env.STATE.dry_run {
                let created_date = (date now | format date "%Y-%m-%d %H:%M:%S")
                log_dryrun $"Would destroy old snapshot: ($snapshot.name) (created ($created_date))"
                false
            } else {
                let created_date = (date now | format date "%Y-%m-%d %H:%M:%S")
                log_info $"Destroying old snapshot: ($snapshot.name) (created ($created_date))..."
                try {
                    zfs destroy $snapshot.name
                    log_success $"Destroyed snapshot: ($snapshot.name)"
                    false
                } catch {
                    log_error $"Failed to destroy snapshot: ($snapshot.name): ($env.LAST_ERROR)"
                    true
                }
            }
        } else {
            false
        }
    })

    # Update state if any pruning failed
    if ($results | any { |result| $result == true }) {
        $env.STATE = ($env.STATE | upsert prune_failed true)
    }
}

def usage [] {
    print "Usage: sudo nu zfs-snapshot.nu [OPTIONS]"
    print ""
    print "Create and prune ZFS snapshots with automatic naming."
    print ""
    print "Options:"
    print "  --dry-run              Show what would be done, but make no changes"
    print "  --retention DAYS       Set retention period in days (default: 7)"
    print "  --pool NAME            Set ZFS pool name (default: rpool)"
    print "  --help, -h             Show this help message"
    print ""
    print "This script:"
    print "• Creates snapshots with prefix 'auto-' and timestamp"
    print "• Uses recursive snapshotting (-r flag)"
    print "• Prunes snapshots older than retention period"
    print "• Maintains a backup log at /var/log/zfs-snapshot.log"
    print ""
    print "Examples:"
    print "  sudo nu zfs-snapshot.nu"
    print "  sudo nu zfs-snapshot.nu --dry-run"
    print "  sudo nu zfs-snapshot.nu --retention 30 --pool tank"
    exit 0
}

# --- Execution ---
try {
    main
} catch {
    log_error $"ZFS snapshot operation failed: ($env.LAST_ERROR)"
    exit 1
}
