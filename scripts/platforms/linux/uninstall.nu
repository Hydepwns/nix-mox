# uninstall.nu - Remove nix-mox scripts installed by install.nu
# This script is intended for non-NixOS systems. For NixOS, use the flake.
# Usage: sudo nu uninstall.nu [--dry-run] [--help]
#
# - Reads the install manifest at /etc/nix-mox/install_manifest.txt
# - Removes all files and directories listed in the manifest.
# - Is idempotent and safe to re-run.
use logging.nu *
use ../../lib/logging.nu *

# --- Global Variables ---
const MANIFEST_FILE = "/etc/nix-mox/install_manifest.txt"
$env.DRY_RUN = false

def main [] {
    # --- Argument Parsing ---
    let args = $env._args
    for arg in $args {
        match $arg {
            "--dry-run" => { $env.DRY_RUN = true }
            "--help" | "-h" => { usage }
            _ => {
                error $"Unknown option: ($arg)" "uninstall"
                usage
            }
        }
    }

    # Check if running as root
    if (whoami | str trim) != 'root' {
        error "This script must be run as root." "uninstall"
        exit 1
    }

    if not ($MANIFEST_FILE | path exists) {
        warn $"Install manifest not found at ($MANIFEST_FILE). Nothing to do." "uninstall"
        exit 0
    }

    if $env.DRY_RUN {
        dry_run "Dry-run mode enabled. No files will be changed." "uninstall"
    }

    info "Starting uninstallation..." "uninstall"

    # Read manifest into an array to process in reverse
    let items_to_remove = (open $MANIFEST_FILE | lines)

    # Iterate in reverse order to remove files before their parent directories
    for item in ($items_to_remove | reverse) {
        if ($item | str trim | is-empty) {
            continue
        }

        if $env.DRY_RUN {
            if ($item | path exists) {
                dry_run $"Would remove: ($item)" "uninstall"
            }
            continue
        }

        if ($item | path exists) {
            if ($item | path type) == "file" {
                info $"Removing file: ($item)" "uninstall"
                rm $item
            } else if ($item | path type) == "dir" {
                # Attempt to remove directory, will only succeed if empty
                try {
                    rmdir $item
                    info $"Removing empty directory: ($item)" "uninstall"
                } catch {
                    warn $"Directory not empty or does not exist, skipping: ($item)" "uninstall"
                }
            }
        } else {
            warn $"Item not found, skipping: ($item)" "uninstall"
        }
    }

    # Finally, remove the manifest file itself if not in dry run
    if not $env.DRY_RUN {
        info $"Removing manifest file: ($MANIFEST_FILE)" "uninstall"
        rm $MANIFEST_FILE
        # Try to remove the parent dir, will fail if not empty (which is fine)
        try {
            rmdir ($MANIFEST_FILE | path dirname)
        }
    }

    if $env.DRY_RUN {
        dry_run "Dry run complete." "uninstall"
    } else {
        success "Uninstallation complete." "uninstall"
    }
}

# --- Execution ---
main
