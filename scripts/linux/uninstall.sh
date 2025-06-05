#!/bin/bash
# uninstall.sh - Remove nix-mox scripts installed by install.sh
# This script is intended for non-NixOS systems. For NixOS, use the flake.
# Usage: sudo ./uninstall.sh [--dry-run] [--help]
#
# - Reads the install manifest at /etc/nix-mox/install_manifest.txt
# - Removes all files and directories listed in the manifest.
# - Is idempotent and safe to re-run.

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPTS_DIR/_common.sh"

# --- Global Variables ---
MANIFEST_FILE="/etc/nix-mox/install_manifest.txt"
DRY_RUN=0

main() {
    # --- Argument Parsing ---
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --dry-run)
          DRY_RUN=1
          shift
          ;;
        --help|-h)
          usage
          ;;
        *)
          log_error "Unknown option: $1"
          usage
          ;;
      esac
    done

    check_root

    if [[ ! -f "$MANIFEST_FILE" ]]; then
        log_warn "Install manifest not found at $MANIFEST_FILE. Nothing to do."
        exit 0
    fi
    
    if [[ $DRY_RUN -eq 1 ]]; then
        log_dryrun "Dry-run mode enabled. No files will be changed."
    fi

    log_info "Starting uninstallation..."
    
    # Read manifest into an array to process in reverse
    mapfile -t items_to_remove < "$MANIFEST_FILE"

    # Iterate in reverse order to remove files before their parent directories
    for ((i=${#items_to_remove[@]}-1; i>=0; i--)); do
        local item="${items_to_remove[i]}"
        
        if [[ -z "$item" ]]; then continue; fi

        if [[ $DRY_RUN -eq 1 ]]; then
            if [[ -e "$item" ]]; then
                log_dryrun "Would remove: $item"
            fi
            continue
        fi

        if [[ -f "$item" ]]; then
            log_info "Removing file: $item"
            rm -f "$item"
        elif [[ -d "$item" ]]; then
            # Attempt to remove directory, will only succeed if empty
            if rmdir "$item" 2>/dev/null; then
                log_info "Removing empty directory: $item"
            else
                log_warn "Directory not empty or does not exist, skipping: $item"
            fi
        else
            log_warn "Item not found, skipping: $item"
        fi
    done
    
    # Finally, remove the manifest file itself if not in dry run
    if [[ $DRY_RUN -eq 0 ]]; then
        log_info "Removing manifest file: $MANIFEST_FILE"
        rm -f "$MANIFEST_FILE"
        # Try to remove the parent dir, will fail if not empty (which is fine)
        rmdir "$(dirname "$MANIFEST_FILE")" 2>/dev/null || true
    fi

    if [[ $DRY_RUN -eq 1 ]]; then
        log_dryrun "Dry run complete."
    else
        log_success "Uninstallation complete."
    fi
}

# --- Execution ---
main "$@"