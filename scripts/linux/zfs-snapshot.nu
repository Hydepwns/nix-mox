# ZFS Snapshot & Prune Script
# Usage: sudo nu zfs-snapshot.nu [--dry-run] [--retention DAYS] [--pool NAME] [--help]
#
# Options:
#   --dry-run         Show what would be done, but make no changes
#   --retention DAYS  Set retention period in days (default: 7 or $RETENTION_DAYS)
#   --pool NAME       Set ZFS pool name (default: rpool or $ZFS_POOL)
#   --help            Show this help message

use ../lib/common.nu

# Script-specific variables
$env.RETENTION_DAYS = ($env.RETENTION_DAYS? | default 7)
$env.POOL = ($env.ZFS_POOL? | default "rpool")
const SNAP_NAME_PREFIX = "auto-"
const SNAP_DATE_FORMAT = "%Y-%m-%d-%H%M"
$env.DRY_RUN = false

def main [] {
    # Parse arguments
    let args = $env._args
    for arg in $args {
        match $arg {
            "--dry-run" => { $env.DRY_RUN = true }
            "--retention" => {
                let idx = ($args | find $arg | get 0)
                $env.RETENTION_DAYS = ($args | get ($idx + 1) | into int)
            }
            "--pool" => {
                let idx = ($args | find $arg | get 0)
                $env.POOL = ($args | get ($idx + 1))
            }
            "--help" | "-h" => { usage }
            _ => {
                log_error $"Unknown option: ($arg)"
                usage
            }
        }
    }

    check_root

    # Check for required command
    if not ((which zfs | length | into int) > 0) {
        log_error "Required command 'zfs' not found."
        exit 1
    }

    # --- Snapshot Creation ---
    log_info $"Starting ZFS snapshot process for pool: ($env.POOL)"
    let SNAP_NAME = $SNAP_NAME_PREFIX + (date now | format date $SNAP_DATE_FORMAT)
    let FULL_SNAP_NAME = $"($env.POOL)@($SNAP_NAME)"

    if (zfs list -t snapshot -H -o name | lines | where $it == $FULL_SNAP_NAME | length) > 0 {
        log_warning $"Snapshot ($FULL_SNAP_NAME) already exists. Skipping creation."
    } else {
        if $env.DRY_RUN {
            log_dryrun "ZFS snapshot functionality"
            log_dryrun $"Would create ZFS snapshot: ($FULL_SNAP_NAME)"
        } else {
            log_info $"Creating ZFS snapshot: ($FULL_SNAP_NAME)..."
            try {
                zfs snapshot -r $FULL_SNAP_NAME
                log_success $"Successfully created snapshot ($FULL_SNAP_NAME)."
            } catch {
                log_error $"Failed to create snapshot ($FULL_SNAP_NAME). Proceeding to prune."
            }
        }
    }

    # --- Snapshot Pruning ---
    $env.PRUNE_FAILED = false
    log_info $"Pruning snapshots in '($env.POOL)' older than ($env.RETENTION_DAYS) days with prefix '($SNAP_NAME_PREFIX)'..."

    if not ($env.RETENTION_DAYS | into string | str contains "^[0-9]+$") {
        log_error $"Invalid retention period: '($env.RETENTION_DAYS)' is not a number. Skipping prune."
        exit 1
    }

    let time_cutoff = ((date now) - ($env.RETENTION_DAYS * 24hr) | into int)

    # Use zfs list with parseable output (-p) to get creation timestamp as epoch
    let snapshots = (zfs list -p -H -t snapshot -o name,creation -S creation -r $env.POOL | lines | split column " " name creation)

    for snapshot in $snapshots {
        # Filter for our auto-generated snapshots
        if not ($snapshot.name | str contains $"@($SNAP_NAME_PREFIX)") {
            continue
        }

        if ($snapshot.creation | into int) < $time_cutoff {
            if $env.DRY_RUN {
                let created_date = (date now | format date "%Y-%m-%d %H:%M:%S")
                log_dryrun $"Would destroy old snapshot: ($snapshot.name) (created ($created_date))"
            } else {
                let created_date = (date now | format date "%Y-%m-%d %H:%M:%S")
                log_info $"Destroying old snapshot: ($snapshot.name) (created ($created_date))..."
                try {
                    zfs destroy $snapshot.name
                    log_success $"Destroyed snapshot: ($snapshot.name)"
                } catch {
                    log_error $"Failed to destroy snapshot: ($snapshot.name)"
                    $env.PRUNE_FAILED = true
                }
            }
        }
    }

    # --- Final Status ---
    if $env.PRUNE_FAILED {
        log_error $"ZFS snapshot/prune for pool '($env.POOL)' completed with errors during pruning."
        exit 1
    } else {
        if $env.DRY_RUN {
            log_dryrun "Dry run complete. No changes were made."
        } else {
            log_success $"ZFS snapshot/prune for pool '($env.POOL)' complete."
        }
    }
}

# --- Execution ---
main