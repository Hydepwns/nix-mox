#!/bin/bash
# ZFS Snapshot & Prune Script
# Usage: sudo ./zfs-snapshot.sh [--dry-run] [--retention DAYS] [--help]
# Logs to /var/log/zfs-snapshot.log
#
# Options:
#   --dry-run         Show what would be done, but make no changes
#   --retention DAYS  Set retention period in days (default: 7 or $RETENTION_DAYS)
#   --help            Show this help message

set -euo pipefail

LOGFILE="/var/log/zfs-snapshot.log"
RETENTION_DAYS="${RETENTION_DAYS:-7}"
POOL="rpool"
SNAP_NAME="auto-$(date +%Y-%m-%d-%H%M)"
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
    --retention)
      RETENTION_DAYS="$2"
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

# Check for required command
if ! command -v zfs &>/dev/null; then
  log_error "Required command 'zfs' not found." "$LOGFILE"
  exit 1
fi

if [[ $DRY_RUN -eq 1 ]]; then
  log_dryrun "No changes will be made." "$LOGFILE"
fi

trap 'log_error "ZFS snapshot/prune failed: $(date)" "$LOGFILE"' ERR

# Avoid duplicate snapshot names
if zfs list -t snapshot | grep -q "$POOL@$SNAP_NAME"; then
  log_warn "Snapshot $POOL@$SNAP_NAME already exists. Skipping creation." "$LOGFILE"
else
  if [[ $DRY_RUN -eq 1 ]]; then
    log_dryrun "Would create ZFS snapshot $POOL@$SNAP_NAME: $(date)" "$LOGFILE"
  else
    log_info "Creating ZFS snapshot $POOL@$SNAP_NAME: $(date)" "$LOGFILE"
    if ! zfs snapshot -r "$POOL@$SNAP_NAME"; then
      log_error "Failed to create snapshot $POOL@$SNAP_NAME" "$LOGFILE"
      exit 1
    fi
  fi
fi

ALL_OK=1
log_info "Pruning old snapshots (older than $RETENTION_DAYS days): $(date)" "$LOGFILE"
time_cutoff=$(date -d "-$RETENTION_DAYS days" +%s)
zfs list -H -t snapshot -o name,creation | while read snap _; do
  if [[ "$snap" =~ $POOL@auto-([0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4}) ]]; then
    snap_date=${BASH_REMATCH[1]}
    snap_epoch=$(date -j -f "%Y-%m-%d-%H%M" "$snap_date" +%s 2>/dev/null || date -d "$snap_date" +%s 2>/dev/null || echo 0)
    if [[ $snap_epoch -lt $time_cutoff ]]; then
      if [[ $DRY_RUN -eq 1 ]]; then
        log_dryrun "Would destroy old snapshot $snap" "$LOGFILE"
      else
        if zfs destroy "$snap"; then
          log_info "Destroyed old snapshot $snap" "$LOGFILE"
        else
          log_error "Failed to destroy snapshot $snap" "$LOGFILE"
          ALL_OK=0
        fi
      fi
    fi
  fi
done

if [[ $ALL_OK -eq 1 ]]; then
  log_success "ZFS snapshot/prune complete: $(date)" "$LOGFILE"
else
  log_error "ZFS snapshot/prune completed with errors: $(date)" "$LOGFILE"
  exit 1
fi 