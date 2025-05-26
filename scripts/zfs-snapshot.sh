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
  echo "[ERROR] This script must be run as root." | tee -a "$LOGFILE"
  exit 1
fi

# Check for required command
if ! command -v zfs &>/dev/null; then
  echo "[ERROR] Required command 'zfs' not found." | tee -a "$LOGFILE"
  exit 1
fi

if [[ $DRY_RUN -eq 1 ]]; then
  echo "[DRY RUN] No changes will be made." | tee -a "$LOGFILE"
fi

trap 'echo "[FAIL] ZFS snapshot/prune failed: $(date)" | tee -a "$LOGFILE"' ERR

# Avoid duplicate snapshot names
if zfs list -t snapshot | grep -q "$POOL@$SNAP_NAME"; then
  echo "[WARN] Snapshot $POOL@$SNAP_NAME already exists. Skipping creation." | tee -a "$LOGFILE"
else
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "[DRY RUN] Would create ZFS snapshot $POOL@$SNAP_NAME: $(date)" | tee -a "$LOGFILE"
  else
    echo "[INFO] Creating ZFS snapshot $POOL@$SNAP_NAME: $(date)" | tee -a "$LOGFILE"
    if ! zfs snapshot -r "$POOL@$SNAP_NAME"; then
      echo "[ERROR] Failed to create snapshot $POOL@$SNAP_NAME" | tee -a "$LOGFILE"
      exit 1
    fi
  fi
fi

ALL_OK=1
echo "[INFO] Pruning old snapshots (older than $RETENTION_DAYS days): $(date)" | tee -a "$LOGFILE"
time_cutoff=$(date -d "-$RETENTION_DAYS days" +%s)
zfs list -H -t snapshot -o name,creation | while read snap _; do
  if [[ "$snap" =~ $POOL@auto-([0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4}) ]]; then
    snap_date=${BASH_REMATCH[1]}
    snap_epoch=$(date -j -f "%Y-%m-%d-%H%M" "$snap_date" +%s 2>/dev/null || date -d "$snap_date" +%s 2>/dev/null || echo 0)
    if [[ $snap_epoch -lt $time_cutoff ]]; then
      if [[ $DRY_RUN -eq 1 ]]; then
        echo "[DRY RUN] Would destroy old snapshot $snap" | tee -a "$LOGFILE"
      else
        if zfs destroy "$snap"; then
          echo "[INFO] Destroyed old snapshot $snap" | tee -a "$LOGFILE"
        else
          echo "[ERROR] Failed to destroy snapshot $snap" | tee -a "$LOGFILE"
          ALL_OK=0
        fi
      fi
    fi
  fi
done

if [[ $ALL_OK -eq 1 ]]; then
  echo "[SUCCESS] ZFS snapshot/prune complete: $(date)" | tee -a "$LOGFILE"
else
  echo "[FAIL] ZFS snapshot/prune completed with errors: $(date)" | tee -a "$LOGFILE"
  exit 1
fi 