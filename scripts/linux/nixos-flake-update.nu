# NixOS Flake Update & Rebuild Script
# Usage: sudo nu nixos-flake-update.nu [--dry-run] [--flake-path PATH] [--help]
# Logs to /var/log/nixos-flake-update.log
#
# Options:
#   --dry-run         Show what would be done, but make no changes
#   --flake-path PATH Set flake path (default: /etc/nixos or $FLAKE_PATH)
#   --help            Show this help message

use ../../scripts/_common.nu *

# Script-specific variables
const LOGFILE = "/var/log/nixos-flake-update.log"
let FLAKE_PATH = ($env.FLAKE_PATH? | default "/etc/nixos")
let HOSTNAME = (hostname)
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
            "--flake-path" => {
                let idx = ($args | find $arg | get 0)
                $FLAKE_PATH = $args.($idx + 1)
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
    for cmd in ["nix", "git"] {
        if not (which $cmd | length) > 0 {
            log_error $"Required command '($cmd)' not found." $LOGFILE
            exit 1
        }
    }

    log_info $"Starting NixOS flake update process for ($FLAKE_PATH)..." $LOGFILE

    if not ($FLAKE_PATH + "/.git" | path exists) {
        log_warn $"Flake path '($FLAKE_PATH)' is not a git repository. Cannot check for changes." $LOGFILE
    }

    # Get the state of the lock file before the update
    let mut pre_update_hash = ""
    if ($FLAKE_PATH + "/flake.lock" | path exists) {
        try {
            $pre_update_hash = (git -C $FLAKE_PATH rev-parse HEAD:flake.lock)
        } catch {
            $pre_update_hash = ((ls -D $FLAKE_PATH/flake.lock).modified | into int)
        }
    }

    if $DRY_RUN {
        log_dryrun $"Dry-run mode: Would attempt to update flake inputs at '($FLAKE_PATH)'." $LOGFILE
        log_dryrun "Dry-run mode: Would rebuild system if flake inputs changed." $LOGFILE
        exit 0
    }

    # Run update and rebuild, redirecting all output to the log file
    log_info "Updating flake inputs..." $LOGFILE
    try {
        nix flake update $FLAKE_PATH | tee -a $LOGFILE

        # Get the state of the lock file after the update
        let mut post_update_hash = ""
        if ($FLAKE_PATH + "/flake.lock" | path exists) {
            try {
                $post_update_hash = (git -C $FLAKE_PATH rev-parse HEAD:flake.lock)
            } catch {
                $post_update_hash = ((ls -D $FLAKE_PATH/flake.lock).modified | into int)
            }
        }

        if $pre_update_hash == $post_update_hash {
            log_info "No changes to flake.lock detected. System is up to date." $LOGFILE
        } else {
            log_info "flake.lock changed. Rebuilding system..." $LOGFILE
            nixos-rebuild switch --flake $"($FLAKE_PATH)#($HOSTNAME)" | tee -a $LOGFILE
            log_success "NixOS system rebuild complete." $LOGFILE
        }
    } catch {
        log_error $"An unexpected error occurred: ($env.LAST_ERROR)" $LOGFILE
        exit 1
    }

    log_success "NixOS flake update process finished." $LOGFILE
}

# --- Execution ---
main 