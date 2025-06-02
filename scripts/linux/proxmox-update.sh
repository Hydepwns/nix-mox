#!/bin/bash
# Proxmox Host Update Script
# Usage: sudo ./proxmox-update.sh [--dry-run] [--help]
# Logs to /var/log/proxmox-update.log
#
# Options:
#   --dry-run         Show what would be done, but make no changes
#   --help            Show this help message

set -euo pipefail

LOGFILE="/var/log/proxmox-update.log"
DRY_RUN=0

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

# Parse arguments
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
      echo "Unknown option: $1" >&2
      usage
      ;;
  esac
done

# Check for root
if [[ $EUID -ne 0 ]]; then
  log_error "This script must be run as root." "$LOGFILE"
  exit 1
fi

# Check for required commands
for cmd in apt pveupdate pveupgrade; do
  if ! command -v $cmd &>/dev/null; then
    log_error "Required command '$cmd' not found." "$LOGFILE"
    exit 1
  fi
done

trap 'log_error "Proxmox update failed: $(date)" "$LOGFILE"' ERR

if [[ $DRY_RUN -eq 1 ]]; then
  log_dryrun "No changes were made." "$LOGFILE"
  exit 0
else
  {
    log_info "Starting Proxmox update: $(date)"
    apt update
    apt -y dist-upgrade
    apt -y autoremove
    pveupdate
    pveupgrade
    log_success "Proxmox update complete: $(date)" "$LOGFILE"
  } 2>&1 | tee -a "$LOGFILE"
fi 