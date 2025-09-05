# NixOS Flake Update & Rebuild Script
# Usage: sudo nu nixos-flake-update.nu [--dry-run] [--flake-path PATH] [--help]
# Logs to /var/log/nixos-flake-update.log
#
# Options:
#   --dry-run         Show what would be done, but make no changes
#   --flake-path PATH Set flake path (default: /etc/nixos or $FLAKE_PATH)
#   --help            Show this help message
use logging.nu *
use ../../lib/logging.nu *

# Script-specific variables
$env.FLAKE_PATH = ($env.FLAKE_PATH | default "/etc/nixos")
$env.HOSTNAME = (hostname)
$env.DRY_RUN = false

def main [] {
    # Parse arguments
    let args = $env._args
    for arg in $args {
        match $arg {
            "--dry-run" => {
                $env.DRY_RUN = true
            }
            "--flake-path" => {
                let idx = ($args | find $arg | first)
                $env.FLAKE_PATH = ($args | get ($idx + 1))
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

    # Check for required commands
    for cmd in ["nix", "git"] {
        if not ((which $cmd | length | into int) > 0) {
            error $"Required command '($cmd)' not found."
            exit 1
        }
    }

    info $"Starting NixOS flake update process for ($env.FLAKE_PATH)..."

    if not ($env.FLAKE_PATH + "/.git" | path exists) {
        warn $"Flake path '($env.FLAKE_PATH)' is not a git repository. Cannot check for changes."
    }

    # Get the state of the lock file before the update
    $env.pre_update_hash = ""
    if ($env.FLAKE_PATH + "/flake.lock" | path exists) {
        try {
            $env.pre_update_hash = (git -C $env.FLAKE_PATH rev-parse HEAD:flake.lock)
        } catch {
            $env.pre_update_hash = ((ls -D $env.FLAKE_PATH/flake.lock).modified | into int)
        }
    }

    if $env.DRY_RUN {
        log_dryrun $"Dry-run mode: Would attempt to update flake inputs at '($env.FLAKE_PATH)'."
        log_dryrun "Dry-run mode: Would rebuild system if flake inputs changed."
        exit 0
    }

    # Run update and rebuild, redirecting all output to the log file
    info "Updating flake inputs..."
    try {
        nix flake update $env.FLAKE_PATH

        # Get the state of the lock file after the update
        $env.post_update_hash = ""
        if ($env.FLAKE_PATH + "/flake.lock" | path exists) {
            try {
                $env.post_update_hash = (git -C $env.FLAKE_PATH rev-parse HEAD:flake.lock)
            } catch {
                $env.post_update_hash = ((ls -D $env.FLAKE_PATH/flake.lock).modified | into int)
            }
        }

        if $env.pre_update_hash == $env.post_update_hash {
            info "No changes to flake.lock detected. System is up to date."
        } else {
            info "flake.lock changed. Rebuilding system..."
            nixos-rebuild switch --flake $"($env.FLAKE_PATH)#($env.HOSTNAME)"
            success "NixOS system rebuild complete."
        }
    } catch {
        error $"An unexpected error occurred: ($env.LAST_ERROR)"
        exit 1
    }

    success "NixOS flake update process finished."
}

# --- Execution ---
main
