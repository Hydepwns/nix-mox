#!/bin/bash
# WARNING: This script is deprecated for Nix/NixOS users!
# Use `nix run .#uninstall` or `nix profile install .#uninstall` instead.
# This script is only for legacy/manual uninstalls on non-NixOS systems.
# uninstall.sh - Remove automation scripts for Proxmox + NixOS + Windows
# Usage: sudo ./uninstall.sh [--help]
#
# - Removes all .sh scripts from /usr/local/sbin
# - Removes systemd timer/service for nixos-flake-update if on NixOS
# - Optionally removes Windows/NuShell scripts from a user-specified directory
# - Idempotent and safe to re-run

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Standardized logging functions
log_msg() {
    local level="$1"
    local color="$2"
    local msg="$3"
    local logfile="${4:-}"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    local formatted="[$timestamp] [$level] $msg"
    if [[ -n "$color" ]]; then
        echo -e "${color}${formatted}${NC}"
    else
        echo "$formatted"
    fi
    if [[ -n "$logfile" ]]; then
        echo "$formatted" >> "$logfile"
    fi
}
log_info()    { log_msg "INFO"    "$GREEN"  "$1" "${2:-}"; }
log_warn()    { log_msg "WARN"    "$YELLOW" "$1" "${2:-}"; }
log_error()   { log_msg "ERROR"   "$RED"    "$1" "${2:-}"; }
log_success() { log_msg "SUCCESS" "$GREEN"  "$1" "${2:-}"; }
log_dryrun()  { log_msg "DRY RUN" "$YELLOW" "$1" "${2:-}"; }

usage() {
    grep '^#' "$0" | cut -c 3-
    exit 0
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root"
    exit 1
fi

if [[ "${1:-}" == "--help" ]]; then
    usage
fi

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPTS_DIR")"

# 1. Remove .sh scripts from /usr/local/sbin
log_info "Removing shell scripts from /usr/local/sbin..."
for script in "$SCRIPTS_DIR"/*.sh; do
    if [[ -f "$script" ]]; then
        base="$(basename "$script")"
        if [[ -f "/usr/local/sbin/$base" ]]; then
            rm -f "/usr/local/sbin/$base"
            log_info "Removed: $base"
        fi
    fi
done

# 2. Remove systemd timer/service for nixos-flake-update if on NixOS
if grep -q 'ID=nixos' /etc/os-release 2>/dev/null; then
    log_info "Detected NixOS. Removing systemd timer/service for nixos-flake-update..."
    
    if systemctl is-active --quiet nixos-flake-update.timer; then
        if ! systemctl disable --now nixos-flake-update.timer; then
            log_error "Failed to disable nixos-flake-update.timer"
            exit 1
        fi
    fi
    
    rm -f /etc/systemd/system/nixos-flake-update.timer
    rm -f /etc/systemd/system/nixos-flake-update.service
    
    if ! systemctl daemon-reload; then
        log_error "Failed to reload systemd daemon"
        exit 1
    fi
    
    log_info "nixos-flake-update.timer disabled and removed"
fi

# 3. Optionally remove Windows/NuShell scripts
read -r -p "Remove Windows/NuShell scripts (install-steam-rust.nu, run-steam-rust.bat, InstallSteamRust.xml) from a directory? [y/N] " yn
if [[ "$yn" =~ ^[Yy]$ ]]; then
    read -r -p "Enter target directory (e.g., /mnt/windows/scripts): " win_dir
    
    # Validate directory path
    if [[ ! "$win_dir" =~ ^/ ]]; then
        log_error "Please provide an absolute path"
        exit 1
    fi
    
    if [[ ! -d "$win_dir" ]]; then
        log_error "Directory does not exist: $win_dir"
        exit 1
    fi
    
    for f in install-steam-rust.nu run-steam-rust.bat InstallSteamRust.xml; do
        if [[ -f "$win_dir/$f" ]]; then
            if ! rm -f "$win_dir/$f"; then
                log_error "Failed to remove: $f"
                exit 1
            fi
            log_info "Removed: $f from $win_dir/"
        fi
    done
fi

log_info "Uninstall complete."