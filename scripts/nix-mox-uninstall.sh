#!/usr/bin/env bash

# shellcheck source=scripts/_common.sh
set -euo pipefail

# Determine the directory where the script is located
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
source "$SCRIPTS_DIR/_common.sh"

# Default values
VERBOSE=false
FORCE=false
LOG_FILE="/var/log/nix-mox/uninstall.log"

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
    check_root
    
    # Remove installed files
    log "info" "Removing installed files..."
    rm -f /usr/local/bin/nix-mox
    rm -f /usr/local/bin/nix-mox-uninstall
    
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