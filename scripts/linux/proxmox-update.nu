# proxmox-update.nu - Update Proxmox VE
# Usage: sudo nu proxmox-update.nu [--dry-run] [--help]
#
# - Updates Proxmox VE packages
# - Maintains an update log
# - Is idempotent and safe to re-run

use ../../scripts/_common.nu *

# Script-specific variables
const LOGFILE = "/var/log/proxmox-update.log"
let DRY_RUN = false
let APT_OPTIONS = "-y" # Default options for apt
let PVE_OPTIONS = ""   # Default options for pveupdate/pveupgrade

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
                $DRY_RUN = true
                $APT_OPTIONS = "--dry-run"
                $PVE_OPTIONS = "--dry-run"
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
    for cmd in ["apt", "pveupdate", "pveupgrade"] {
        if not (which $cmd | length) > 0 {
            log_error $"Required command '($cmd)' not found." $LOGFILE
            exit 1
        }
    }

    log_info "Starting Proxmox update..." $LOGFILE

    if $DRY_RUN {
        log_dryrun "Dry-run mode enabled. The following commands would be executed:" $LOGFILE
    }

    # Run updates, redirecting stdout/stderr to the log file
    try {
        log_info "Updating package lists..." $LOGFILE
        apt update | tee -a $LOGFILE

        log_info "Performing distribution upgrade..." $LOGFILE
        apt $APT_OPTIONS dist-upgrade | tee -a $LOGFILE

        log_info "Removing unused packages..." $LOGFILE
        apt $APT_OPTIONS autoremove | tee -a $LOGFILE

        log_info "Running pveupdate..." $LOGFILE
        pveupdate $PVE_OPTIONS | tee -a $LOGFILE

        log_info "Running pveupgrade..." $LOGFILE
        pveupgrade $PVE_OPTIONS | tee -a $LOGFILE
    } catch {
        log_error $"An error occurred: ($env.LAST_ERROR)" $LOGFILE
        exit 1
    }

    if $DRY_RUN {
        log_dryrun "Dry run complete. No changes were made." $LOGFILE
    } else {
        log_success "Proxmox update complete." $LOGFILE
    }
}

# --- Execution ---
main 