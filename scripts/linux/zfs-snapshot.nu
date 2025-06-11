# ZFS Snapshot & Prune Script
# Usage: sudo nu zfs-snapshot.nu [--dry-run] [--retention DAYS] [--pool NAME] [--help]
# Logs to /var/log/zfs-snapshot.log
#
# Options:
#   --dry-run         Show what would be done, but make no changes
#   --retention DAYS  Set retention period in days (default: 7 or $RETENTION_DAYS)
#   --pool NAME       Set ZFS pool name (default: rpool or $ZFS_POOL)
#   --help            Show this help message

use ../../scripts/_common.nu *

# Script-specific variables
const LOGFILE = "/var/log/zfs-snapshot.log"
let RETENTION_DAYS = ($env.RETENTION_DAYS? | default 7)
let POOL = ($env.ZFS_POOL? | default "rpool")
const SNAP_NAME_PREFIX = "auto-"
const SNAP_DATE_FORMAT = "%Y-%m-%d-%H%M"
let DRY_RUN = false

# Ensure log file exists and is writable
try {
    touch $LOGFILE
} catch {
    log_error $"Log file is not writable: ($LOGFILE)"
    exit 1
}

def main [] {
    # Parse arguments
    let args = $env._args
    for arg in $args {
        match $arg {
            "--dry-run" => { $DRY_RUN = true }
            "--retention" => {
                let idx = ($args | find $arg | get 0)
                $RETENTION_DAYS = ($args.($idx + 1) | into int)
            }
            "--pool" => {
                let idx = ($args | find $arg | get 0)
                $POOL = $args.($idx + 1)
            }
            "--help" | "-h" => { usage }
            _ => {
                log_error $"Unknown option: ($arg)" $LOGFILE
                usage
            }
        }
    }

    check_root $LOGFILE

    # Check for required command
    if not (which zfs | length) > 0 {
        log_error "Required command 'zfs' not found." $LOGFILE
        exit 1
    }

    # --- Snapshot Creation ---
    log_info $"Starting ZFS snapshot process for pool: ($POOL)" $LOGFILE
    let SNAP_NAME = $SNAP_NAME_PREFIX + (date now | format date $SNAP_DATE_FORMAT)
    let FULL_SNAP_NAME = $"($POOL)@($SNAP_NAME)"

    if (zfs list -t snapshot -H -o name | lines | where $it == $FULL_SNAP_NAME | length) > 0 {
        log_warn $"Snapshot ($FULL_SNAP_NAME) already exists. Skipping creation." $LOGFILE
    } else {
        if $DRY_RUN {
            log_dryrun "ZFS snapshot functionality" $LOGFILE
            log_dryrun $"Would create ZFS snapshot: ($FULL_SNAP_NAME)" $LOGFILE
        } else {
            log_info $"Creating ZFS snapshot: ($FULL_SNAP_NAME)..." $LOGFILE
            try {
                zfs snapshot -r $FULL_SNAP_NAME
                log_success $"Successfully created snapshot ($FULL_SNAP_NAME)." $LOGFILE
            } catch {
                log_error $"Failed to create snapshot ($FULL_SNAP_NAME). Proceeding to prune." $LOGFILE
            }
        }
    }

    # --- Snapshot Pruning ---
    let mut PRUNE_FAILED = false
    log_info $"Pruning snapshots in '($POOL)' older than ($RETENTION_DAYS) days with prefix '($SNAP_NAME_PREFIX)'..." $LOGFILE

    if not ($RETENTION_DAYS | into string | str contains "^[0-9]+$") {
        log_error $"Invalid retention period: '($RETENTION_DAYS)' is not a number. Skipping prune." $LOGFILE
        exit 1
    }

    let time_cutoff = ((date now) - ($RETENTION_DAYS * 24hr) | into int)

    # Use zfs list with parseable output (-p) to get creation timestamp as epoch
    let snapshots = (zfs list -p -H -t snapshot -o name,creation -S creation -r $POOL | lines | split column " " name creation)

    for snapshot in $snapshots {
        # Filter for our auto-generated snapshots
        if not ($snapshot.name | str contains $"@($SNAP_NAME_PREFIX)") {
            continue
        }

        if ($snapshot.creation | into int) < $time_cutoff {
            if $DRY_RUN {
                let created_date = (date -d $"@($snapshot.creation)" | format date "%Y-%m-%d %H:%M:%S")
                log_dryrun $"Would destroy old snapshot: ($snapshot.name) (created ($created_date))" $LOGFILE
            } else {
                let created_date = (date -d $"@($snapshot.creation)" | format date "%Y-%m-%d %H:%M:%S")
                log_info $"Destroying old snapshot: ($snapshot.name) (created ($created_date))..." $LOGFILE
                try {
                    zfs destroy $snapshot.name
                    log_success $"Destroyed snapshot: ($snapshot.name)" $LOGFILE
                } catch {
                    log_error $"Failed to destroy snapshot: ($snapshot.name)" $LOGFILE
                    $PRUNE_FAILED = true
                }
            }
        }
    }

    # --- Final Status ---
    if $PRUNE_FAILED {
        log_error $"ZFS snapshot/prune for pool '($POOL)' completed with errors during pruning." $LOGFILE
        exit 1
    } else {
        if $DRY_RUN {
            log_dryrun "Dry run complete. No changes were made." $LOGFILE
        } else {
            log_success $"ZFS snapshot/prune for pool '($POOL)' complete." $LOGFILE
        }
    }
}

# --- Execution ---
main 