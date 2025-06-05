#!/bin/bash
# _common.sh - Common utility functions for nix-mox scripts

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Standardized logging functions
# Usage: log_info "Message" ["logfile_path"]
# log_warn, log_error, log_success, log_dryrun follow the same pattern.
# log_msg is the base function.
log_msg() {
    local level="$1"
    local color="$2"
    local msg="$3"
    local logfile="${4:-}" # Optional log file argument
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    local formatted="[$timestamp] [$level] $msg"
    
    if [[ -t 1 && -n "$color" ]]; then # Only use colors if stdout is a terminal
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

# Function to check if running as root
# Exits if not root.
# Usage: check_root ["logfile_path"]
check_root() {
    local logfile="${1:-}" # Optional log file argument
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root." "$logfile"
        exit 1
    fi
}

# Function for script usage message
# Relies on comments at the start of the calling script.
# Usage: usage
usage() {
  local script_path
  # Resolve the actual script path, following symlinks
  script_path=$(readlink -f "${BASH_SOURCE[1]}")
  grep '^#' "$script_path" | cut -c 3-
  exit 0
} 