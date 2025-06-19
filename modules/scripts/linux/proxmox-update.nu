#!/usr/bin/env nu
# proxmox-update.nu - Update Proxmox VE
# Usage: sudo nu proxmox-update.nu [--dry-run] [--help]
#
# - Updates Proxmox VE packages
# - Maintains an update log
# - Is idempotent and safe to re-run

# --- Common Functions ---
def log_info [message: string, logfile: string] {
    let timestamp = (date now | format date '%Y-%m-%d %H:%M:%S')
    let log_message = $"($timestamp) [INFO] ($message)"
    print $log_message
    try {
        $log_message | save --append $logfile
    } catch {
        print $"Failed to write to log file ($logfile)"
    }
}

def log_error [message: string, logfile: string] {
    let timestamp = (date now | format date '%Y-%m-%d %H:%M:%S')
    let log_message = $"($timestamp) [ERROR] ($message)"
    print $log_message
    try {
        $log_message | save --append $logfile
    } catch {
        print $"Failed to write to log file ($logfile)"
    }
}

def log_success [message: string, logfile: string] {
    let timestamp = (date now | format date '%Y-%m-%d %H:%M:%S')
    let log_message = $"($timestamp) [SUCCESS] ($message)"
    print $log_message
    try {
        $log_message | save --append $logfile
    } catch {
        print $"Failed to write to log file ($logfile)"
    }
}

def log_dryrun [message: string, logfile: string] {
    let timestamp = (date now | format date '%Y-%m-%d %H:%M:%S')
    let log_message = $"($timestamp) [DRYRUN] ($message)"
    print $log_message
    try {
        $log_message | save --append $logfile
    } catch {
        print $"Failed to write to log file ($logfile)"
    }
}

def check_root [] {
    if (whoami | str trim) == 'root' {
        "Running as root."
    } else {
        print $"ERROR: This script must be run as root."
        exit 1
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

def append-to-log [logfile: string] {
    try {
        $in | save --append $logfile
    } catch {
        print $"Failed to append to log file ($logfile)"
    }
}

# Script-specific variables
const LOGFILE = "/var/log/proxmox-update.log"
$env.DRY_RUN = false
$env.APT_OPTIONS = "-y" # Default options for apt
$env.PVE_OPTIONS = ""   # Default options for pveupdate/pveupgrade

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
        log_error "An error occurred during the update process." $LOGFILE
        exit 1
    }

    if $env.DRY_RUN {
        log_dryrun "Dry run complete. No changes were made." $LOGFILE
    } else {
        log_success "Proxmox update complete." $LOGFILE
    }
}

# --- Execution ---
main $in