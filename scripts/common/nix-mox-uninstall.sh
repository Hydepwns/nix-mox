#!/usr/bin/env bash

set -euo pipefail

# Default values
VERBOSE=false
FORCE=false
LOG_FILE="/var/log/nix-mox/uninstall.log"

# Logging function
log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    if [[ "$level" == "debug" && "$VERBOSE" != "true" ]]; then
        return
    fi
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -l|--log-file)
            LOG_FILE="$2"
            shift 2
            ;;
        *)
            log "error" "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Main uninstall function
uninstall() {
    log "info" "Starting nix-mox uninstallation..."

    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        log "error" "This script must be run as root"
        exit 1
    fi

    # Remove installed files
    log "info" "Removing installed files..."
    if [[ "$FORCE" == "true" ]]; then
        rm -f /usr/local/bin/nix-mox
        rm -f /usr/local/bin/nix-mox-uninstall
    else
        log "warn" "Use --force to remove installed files"
    fi

    # Remove configuration files
    log "info" "Removing configuration files..."
    rm -rf /etc/nix-mox

    # Remove log files
    log "info" "Removing log files..."
    rm -rf /var/log/nix-mox

    log "info" "nix-mox has been successfully uninstalled."
}

# Run the uninstall function
uninstall