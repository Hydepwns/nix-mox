#!/bin/bash
# Proxmox vzdump Backup Script
# Usage: sudo ./vzdump-backup.sh [--dry-run] [--storage NAME] [--help]
# Logs to /var/log/vzdump-backup.log
#
# Options:
#   --dry-run         Show what would be done, but make no changes
#   --storage NAME    Set backup storage name (default: backup or $STORAGE)
#   --help            Show this help message

set -euo pipefail

LOGFILE="/var/log/vzdump-backup.log"
STORAGE="${STORAGE:-backup}"
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
log_info()    { log_msg "INFO"    "$GREEN"  "$1" "$2"; }
log_warn()    { log_msg "WARN"    "$YELLOW" "$1" "$2"; }
log_error()   { log_msg "ERROR"   "$RED"    "$1" "$2"; }
log_success() { log_msg "SUCCESS" "$GREEN"  "$1" "$2"; }
log_dryrun()  { log_msg "DRY RUN" "$YELLOW" "$1" "$2"; }

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
    --storage)
      STORAGE="$2"
      shift 2
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
for cmd in vzdump qm pct; do
  if ! command -v $cmd &>/dev/null; then
    log_error "Required command '$cmd' not found." "$LOGFILE"
    exit 1
  fi
done

if [[ $DRY_RUN -eq 1 ]]; then
  log_dryrun "No changes will be made." "$LOGFILE"
fi

trap 'log_error "vzdump backup failed: $(date)" "$LOGFILE"' ERR

if [[ $DRY_RUN -eq 1 ]]; then
  log_dryrun "No changes were made." "$LOGFILE"
  exit 0
else
  {
    log_info "Starting vzdump backup: $(date)" "$LOGFILE"
    ALL_OK=1
    for VMID in $(qm list | awk 'NR>1 {print $1}'); do
      if vzdump "$VMID" --storage "$STORAGE" --mode snapshot --compress zstd; then
        log_info "Backed up VM $VMID" "$LOGFILE"
      else
        log_error "Failed to backup VM $VMID" "$LOGFILE"
        ALL_OK=0
      fi
    done
    for CTID in $(pct list | awk 'NR>1 {print $1}'); do
      if vzdump "$CTID" --storage "$STORAGE" --mode snapshot --compress zstd; then
        log_info "Backed up CT $CTID" "$LOGFILE"
      else
        log_error "Failed to backup CT $CTID" "$LOGFILE"
        ALL_OK=0
      fi
    done
    if [[ $ALL_OK -eq 1 ]]; then
      log_success "vzdump backup complete: $(date)" "$LOGFILE"
    else
      log_error "vzdump backup completed with errors: $(date)" "$LOGFILE"
      exit 1
    fi
  } 2>&1 | tee -a "$LOGFILE"
fi 