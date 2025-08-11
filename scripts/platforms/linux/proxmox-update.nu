#!/usr/bin/env nu
# proxmox-update.nu - Update Proxmox VE
# Usage: sudo nu proxmox-update.nu [--dry-run] [--help]
#
# - Updates Proxmox VE packages
# - Maintains an update log
# - Is idempotent and safe to re-run
use ../lib/common.nu

# --- Common Functions ---
const LOGFILE = "/var/log/proxmox-update.log"

def log_error [message: string] {
    let timestamp = (date now | format date '%Y-%m-%d %H:%M:%S')
    let log_message = $"($timestamp) [ERROR] ($message)"
    print $log_message
    try {
        $log_message | save --append $LOGFILE
    } catch {
        print $"Failed to write to log file ($LOGFILE)"
    }
}

def log_success [message: string] {
    let timestamp = (date now | format date '%Y-%m-%d %H:%M:%S')
    let log_message = $"($timestamp) [SUCCESS] ($message)"
    print $log_message
    try {
        $log_message | save --append $LOGFILE
    } catch {
        print $"Failed to write to log file ($LOGFILE)"
    }
}

def log_info [message: string] {
    let timestamp = (date now | format date '%Y-%m-%d %H:%M:%S')
    let log_message = $"($timestamp) [INFO] ($message)"
    print $log_message
    try {
        $log_message | save --append $LOGFILE
    } catch {
        print $"Failed to write to log file ($LOGFILE)"
    }
}

def usage [] {
    print "Usage: sudo nu proxmox-update.nu [--dry-run] [--help]"
    print ""
    print "Options:"
    print "  --dry-run    Show what would be done, but make no changes"
    print "  --help, -h   Show this help message"
    print ""
    print "This script updates Proxmox VE packages safely and maintains a log."
    exit 0
}

# Script-specific variables
$env.DRY_RUN = false
$env.APT_OPTIONS = "-y"
$env.PVE_OPTIONS = ""

# Ensure log file exists and is writable
try {
    # Try to create log directory if it doesn't exist
    let log_dir = ($LOGFILE | path dirname)
    if not ($log_dir | path exists) {
        mkdir $log_dir
    }
    touch $LOGFILE
} catch {
    print $"Warning: Could not create log file ($LOGFILE). Continuing without logging."
    $env.LOGFILE = "/tmp/proxmox-update.log"
}

def main [args: list] {
    # Parse arguments
    for arg in $args {
        match $arg {
            "--dry-run" => {
                $env.DRY_RUN = true
                $env.APT_OPTIONS = "--dry-run"
                $env.PVE_OPTIONS = "--dry-run"
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

    # Check for required commands
    for cmd in ["apt", "pveupdate", "pveupgrade"] {
        if not ((which $cmd | length | into int) > 0) {
            log_error $"Required command '($cmd)' not found."
            exit 1
        }
    }

    log_info "Starting Proxmox update..."

    if $env.DRY_RUN {
        log_dryrun "Dry-run mode enabled. The following commands would be executed:"
    }

    # Run updates, redirecting stdout/stderr to the log file
    try {
        log_info "Updating package lists..."
        apt update

        log_info "Performing distribution upgrade..."
        apt $env.APT_OPTIONS dist-upgrade

        log_info "Removing unused packages..."
        apt $env.APT_OPTIONS autoremove

        log_info "Running pveupdate..."
        pveupdate $env.PVE_OPTIONS

        log_info "Running pveupgrade..."
        pveupgrade $env.PVE_OPTIONS
    } catch {
        log_error "An error occurred during the update process."
        exit 1
    }

    if $env.DRY_RUN {
        log_dryrun "Dry run complete. No changes were made."
    } else {
        log_success "Proxmox update complete."
    }
}

# --- Execution ---
main $env._args
