#!/bin/bash
# install.sh - Bootstrap automation scripts for Proxmox + NixOS + Windows
# Usage: sudo ./install.sh [--help]
#
# - Installs all .sh scripts to /usr/local/sbin and sets permissions
# - Installs systemd timer/service for nixos-flake-update if on NixOS
# - Optionally copies Windows/NuShell scripts to a user-specified directory
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

DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=1
    log_info "Dry-run mode enabled. No changes will be made."
fi

INSTALLED_SCRIPTS=()
SYSTEMD_INSTALLED=0

# 1. Install .sh scripts to /usr/local/sbin
log_info "Installing shell scripts to /usr/local/sbin..."
for script in "$SCRIPTS_DIR"/*.sh; do
    if [[ -f "$script" ]]; then
        base="$(basename "$script")"
        if [[ $DRY_RUN -eq 1 ]]; then
            echo "[DRY-RUN] Would install $base to /usr/local/sbin/"
        else
            if [[ -f "/usr/local/sbin/$base" ]]; then
                log_warn "Overwriting existing script: $base"
            fi
            if install -m 755 "$script" "/usr/local/sbin/$base"; then
                log_info "Installed: $base"
                INSTALLED_SCRIPTS+=("$base")
            else
                log_error "Failed to install: $base"
                # Rollback previously installed scripts
                for prev in "${INSTALLED_SCRIPTS[@]}"; do
                    rm -f "/usr/local/sbin/$prev"
                    log_warn "Rolled back: $prev"
                done
                exit 1
            fi
        fi
    fi
done

# 2. Install systemd timer/service for nixos-flake-update if on NixOS
if grep -q 'ID=nixos' /etc/os-release 2>/dev/null; then
    log_info "Detected NixOS. Installing systemd timer/service for nixos-flake-update..."
    
    if [[ ! -f "$ROOT_DIR/nixos-flake-update.timer" ]] || [[ ! -f "$ROOT_DIR/nixos-flake-update.service" ]]; then
        log_error "Required systemd files not found in $ROOT_DIR"
        # Rollback scripts if any were installed
        if [[ $DRY_RUN -ne 1 ]]; then
            for prev in "${INSTALLED_SCRIPTS[@]}"; do
                rm -f "/usr/local/sbin/$prev"
                log_warn "Rolled back: $prev"
            done
        fi
        exit 1
    fi
    
    if [[ $DRY_RUN -eq 1 ]]; then
        echo "[DRY-RUN] Would install nixos-flake-update.timer and service to /etc/systemd/system/ and enable timer."
    else
        if install -m 644 "$ROOT_DIR/nixos-flake-update.timer" /etc/systemd/system/ && \
           install -m 644 "$ROOT_DIR/nixos-flake-update.service" /etc/systemd/system/; then
            if systemctl daemon-reload && systemctl enable --now nixos-flake-update.timer; then
                log_info "nixos-flake-update.timer enabled and started"
                SYSTEMD_INSTALLED=1
            else
                log_error "Failed to enable/start nixos-flake-update.timer"
                # Rollback systemd units and scripts
                rm -f /etc/systemd/system/nixos-flake-update.timer
                rm -f /etc/systemd/system/nixos-flake-update.service
                for prev in "${INSTALLED_SCRIPTS[@]}"; do
                    rm -f "/usr/local/sbin/$prev"
                    log_warn "Rolled back: $prev"
                done
                exit 1
            fi
        else
            log_error "Failed to install systemd files"
            # Rollback scripts
            for prev in "${INSTALLED_SCRIPTS[@]}"; do
                rm -f "/usr/local/sbin/$prev"
                log_warn "Rolled back: $prev"
            done
            exit 1
        fi
    fi
fi

# 3. Optionally copy Windows/NuShell scripts
read -r -p "Copy Windows/NuShell scripts (scripts/install-steam-rust.nu, scripts/run-steam-rust.bat, scripts/InstallSteamRust.xml) to a Windows-accessible directory? [y/n] " yn
if [[ "$yn" =~ ^[Yy]$ ]]; then
    read -r -p "Enter target directory (e.g., /mnt/windows/scripts): " win_dir
    
    if [[ ! "$win_dir" =~ ^/ ]]; then
        log_error "Please provide an absolute path"
        # Rollback if not dry-run
        if [[ $DRY_RUN -ne 1 ]]; then
            for prev in "${INSTALLED_SCRIPTS[@]}"; do
                rm -f "/usr/local/sbin/$prev"
                log_warn "Rolled back: $prev"
            done
            if [[ $SYSTEMD_INSTALLED -eq 1 ]]; then
                rm -f /etc/systemd/system/nixos-flake-update.timer
                rm -f /etc/systemd/system/nixos-flake-update.service
                log_warn "Rolled back systemd units"
            fi
        fi
        exit 1
    fi
    
    if [[ $DRY_RUN -eq 1 ]]; then
        echo "[DRY-RUN] Would create directory $win_dir and copy Windows/NuShell scripts."
    else
        if ! mkdir -p "$win_dir"; then
            log_error "Failed to create directory: $win_dir"
            # Rollback
            for prev in "${INSTALLED_SCRIPTS[@]}"; do
                rm -f "/usr/local/sbin/$prev"
                log_warn "Rolled back: $prev"
            done
            if [[ $SYSTEMD_INSTALLED -eq 1 ]]; then
                rm -f /etc/systemd/system/nixos-flake-update.timer
                rm -f /etc/systemd/system/nixos-flake-update.service
                log_warn "Rolled back systemd units"
            fi
            exit 1
        fi
        for f in install-steam-rust.nu run-steam-rust.bat InstallSteamRust.xml; do
            if [[ ! -f "$SCRIPTS_DIR/$f" ]]; then
                log_warn "File not found: $f"
                continue
            fi
            if ! cp "$SCRIPTS_DIR/$f" "$win_dir/"; then
                log_error "Failed to copy: $f"
                # Rollback
                for prev in "${INSTALLED_SCRIPTS[@]}"; do
                    rm -f "/usr/local/sbin/$prev"
                    log_warn "Rolled back: $prev"
                done
                if [[ $SYSTEMD_INSTALLED -eq 1 ]]; then
                    rm -f /etc/systemd/system/nixos-flake-update.timer
                    rm -f /etc/systemd/system/nixos-flake-update.service
                    log_warn "Rolled back systemd units"
                fi
                exit 1
            fi
            log_info "Copied: $f to $win_dir/"
        done
    fi
fi

if [[ $DRY_RUN -eq 1 ]]; then
    log_info "Dry-run complete. No changes were made."
else
    log_info "Install complete."
    log_info "For Windows/NuShell automation, see nix-mox/USAGE.md for further setup instructions."
fi