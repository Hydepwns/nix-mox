# uninstall.nu - Remove nix-mox scripts installed by install.nu
# This script is intended for non-NixOS systems. For NixOS, use the flake.
# Usage: sudo nu uninstall.nu [--dry-run] [--help]
#
# - Reads the install manifest at /etc/nix-mox/install_manifest.txt
# - Removes all files and directories listed in the manifest.
# - Is idempotent and safe to re-run.

use ../lib/common.nu

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
                log_error $"Unknown option: ($arg)"
                usage
            }
        }
    }

    check_root

    if not ($MANIFEST_FILE | path exists) {
        log_warning $"Install manifest not found at ($MANIFEST_FILE). Nothing to do."
        exit 0
    }

    if $env.DRY_RUN {
        log_dryrun "Dry-run mode enabled. No files will be changed."
    }

    log_info "Starting uninstallation..."

    # Read manifest into an array to process in reverse
    let items_to_remove = (open $MANIFEST_FILE | lines)

    # Iterate in reverse order to remove files before their parent directories
    for item in ($items_to_remove | reverse) {
        if ($item | str trim | is-empty) { continue }

        if $env.DRY_RUN {
            if ($item | path exists) {
                log_dryrun $"Would remove: ($item)"
            }
            continue
        }

        if ($item | path exists) {
            if ($item | path type) == "file" {
                log_info $"Removing file: ($item)"
                rm $item
            } else if ($item | path type) == "dir" {
                # Attempt to remove directory, will only succeed if empty
                try {
                    rmdir $item
                    log_info $"Removing empty directory: ($item)"
                } catch {
                    log_warning $"Directory not empty or does not exist, skipping: ($item)"
                }
            }
        } else {
            log_warning $"Item not found, skipping: ($item)"
        }
    }

    # Finally, remove the manifest file itself if not in dry run
    if not $env.DRY_RUN {
        log_info $"Removing manifest file: ($MANIFEST_FILE)"
        rm $MANIFEST_FILE
        # Try to remove the parent dir, will fail if not empty (which is fine)
        try {
            rmdir ($MANIFEST_FILE | path dirname)
        }
    }

    if $env.DRY_RUN {
        log_dryrun "Dry run complete."
    } else {
        log_success "Uninstallation complete."
    }
}

# --- Execution ---
main