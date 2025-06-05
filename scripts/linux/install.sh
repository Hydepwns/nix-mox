#!/bin/bash
# install.sh - Install nix-mox scripts
# This script is intended for non-NixOS systems. For NixOS, use the flake.
# Usage: sudo ./install.sh [--dry-run] [--windows-dir /path/to/win/dir] [--help]
#
# - Installs all .sh scripts to /usr/local/bin
# - Creates an install manifest at /etc/nix-mox/install_manifest.txt
# - Is idempotent and safe to re-run

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPTS_DIR/_common.sh"

# --- Global Variables ---
INSTALL_DIR="/usr/local/bin"
MANIFEST_DIR="/etc/nix-mox"
MANIFEST_FILE="$MANIFEST_DIR/install_manifest.txt"
DRY_RUN=0
WINDOWS_DIR=""
# This array tracks files created *by this specific run* for cleanup on failure.
declare -a CREATED_THIS_RUN

# --- Functions ---
cleanup() {
    # This function is called on ERR or EXIT to roll back this run's changes.
    if [[ ${#CREATED_THIS_RUN[@]} -eq 0 ]]; then
        return
    fi

    log_warn "An error occurred. Rolling back changes made during this installation run..."
    # Iterate in reverse to remove files before directories
    for ((i=${#CREATED_THIS_RUN[@]}-1; i>=0; i--)); do
        local item="${CREATED_THIS_RUN[i]}"
        if [[ -f "$item" ]]; then
            log_warn "Removing file: $item"
            rm -f "$item"
        elif [[ -d "$item" ]]; then
            # Only remove dir if it's empty
            if rmdir "$item" 2>/dev/null; then
                log_warn "Removing directory: $item"
            else
                log_warn "Directory not empty, skipping removal: $item"
            fi
        fi
    done
    log_warn "Rollback complete."
}

add_to_manifest() {
    # Adds a file or directory path to the manifest for the uninstaller.
    local file_path="$1"
    if [[ $DRY_RUN -eq 1 ]]; then return; fi
    # Ensure file exists before adding
    if ! grep -qxF "$file_path" "$MANIFEST_FILE"; then
        echo "$file_path" >> "$MANIFEST_FILE"
    fi
}

main() {
    # --- Argument Parsing ---
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --dry-run)
          DRY_RUN=1
          shift
          ;;
        --windows-dir)
          WINDOWS_DIR="$2"
          if [[ ! "$WINDOWS_DIR" =~ ^/ ]]; then
              log_error "Windows path must be absolute."
              exit 1
          fi
          shift 2
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

    if [[ $DRY_RUN -eq 1 ]]; then
        log_dryrun "Dry-run mode enabled. No files will be changed."
    else
        # Prepare manifest directory and file
        mkdir -p "$MANIFEST_DIR"
        CREATED_THIS_RUN+=("$MANIFEST_DIR")
        touch "$MANIFEST_FILE"
        CREATED_THIS_RUN+=("$MANIFEST_FILE")
    fi

    # 1. Install Linux scripts
    log_info "Installing Linux scripts to $INSTALL_DIR..."
    for script in "$SCRIPTS_DIR"/*.sh; do
        if [[ "$(basename "$script")" == "_common.sh" || "$(basename "$script")" == "install.sh" || "$(basename "$script")" == "uninstall.sh" ]]; then
            continue
        fi
        
        local dest_path="$INSTALL_DIR/$(basename "$script" .sh)"
        if [[ $DRY_RUN -eq 1 ]]; then
            log_dryrun "Would install '$script' to '$dest_path'"
        else
            log_info "Installing '$script' to '$dest_path'..."
            install -m 755 "$script" "$dest_path"
            CREATED_THIS_RUN+=("$dest_path")
            add_to_manifest "$dest_path"
        fi
    done

    # 2. Copy Windows scripts if requested
    if [[ -n "$WINDOWS_DIR" ]]; then
        log_info "Copying Windows scripts to $WINDOWS_DIR..."
        local win_scripts_src="$SCRIPTS_DIR/../windows"
        
        if [[ $DRY_RUN -eq 1 ]]; then
            log_dryrun "Would create directory '$WINDOWS_DIR' and copy files into it."
        else
            mkdir -p "$WINDOWS_DIR"
            CREATED_THIS_RUN+=("$WINDOWS_DIR")
            add_to_manifest "$WINDOWS_DIR"

            for f in "$win_scripts_src"/*; do
                local dest_file="$WINDOWS_DIR/$(basename "$f")"
                log_info "Copying '$f' to '$dest_file'..."
                cp "$f" "$dest_file"
                CREATED_THIS_RUN+=("$dest_file")
                add_to_manifest "$dest_file"
            done
        fi
    fi

    # If we got this far, the installation was successful. Clear the trap.
    trap - ERR EXIT

    if [[ $DRY_RUN -eq 1 ]]; then
        log_dryrun "Dry run complete."
    else
        log_success "Installation complete."
        log_info "An install manifest has been created at: $MANIFEST_FILE"
        log_info "Use uninstall.sh to remove all installed files."
    fi
}

# --- Execution ---
trap cleanup ERR EXIT
main "$@"