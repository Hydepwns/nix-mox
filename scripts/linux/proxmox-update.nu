# proxmox-update.nu - Update Proxmox VE
# Usage: sudo nu proxmox-update.nu [--dry-run] [--help]
#
# - Updates Proxmox VE packages
# - Maintains an update log
# - Is idempotent and safe to re-run

use ../../scripts/_common.nu *

# Script-specific variables
const LOGFILE = "/var/log/proxmox-update.log"
$env.DRY_RUN = false
$env.APT_OPTIONS = "-y" # Default options for apt
$env.PVE_OPTIONS = ""   # Default options for pveupdate/pveupgrade

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
            "--dry-run" => {
                $env.DRY_RUN = true
                $env.APT_OPTIONS = "--dry-run"
                $env.PVE_OPTIONS = "--dry-run"
            }
            "--help" | "-h" => { usage }
            _ => {
                log_error $"Unknown option: ($arg)" $LOGFILE
                usage
            }
        }
    }

    check_root

    # Check for required commands
    for cmd in ["apt", "pveupdate", "pveupgrade"] {
        if not ((which $cmd | length | into int) > 0) {
            log_error $"Required command '($cmd)' not found." $LOGFILE
            exit 1
        }
    }

    log_info "Starting Proxmox update..." $LOGFILE

    if $env.DRY_RUN {
        log_dryrun "Dry-run mode enabled. The following commands would be executed:" $LOGFILE
    }

    # Run updates, redirecting stdout/stderr to the log file
    try {
        log_info "Updating package lists..." $LOGFILE
        apt update | append-to-log $LOGFILE

        log_info "Performing distribution upgrade..." $LOGFILE
        apt $env.APT_OPTIONS dist-upgrade | append-to-log $LOGFILE

        log_info "Removing unused packages..." $LOGFILE
        apt $env.APT_OPTIONS autoremove | append-to-log $LOGFILE

        log_info "Running pveupdate..." $LOGFILE
        pveupdate $env.PVE_OPTIONS | append-to-log $LOGFILE

        log_info "Running pveupgrade..." $LOGFILE
        pveupgrade $env.PVE_OPTIONS | append-to-log $LOGFILE
    } catch {
        log_error $"An error occurred: ($env.LAST_ERROR)" $LOGFILE
        exit 1
    }

    if $env.DRY_RUN {
        log_dryrun "Dry run complete. No changes were made." $LOGFILE
    } else {
        log_success "Proxmox update complete." $LOGFILE
    }
}

# --- Execution ---
main 