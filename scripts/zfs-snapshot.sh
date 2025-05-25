#!/bin/bash
# ZFS Snapshot & Prune Script
# Usage: sudo ./zfs-snapshot.sh
# Logs to /var/log/zfs-snapshot.log

set -euo pipefail

LOGFILE="/var/log/zfs-snapshot.log"
RETENTION_DAYS=7
POOL="rpool"
SNAP_NAME="auto-$(date +%Y-%m-%d-%H%M)"

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

# Avoid duplicate snapshot names
if zfs list -t snapshot | grep -q "$POOL@$SNAP_NAME"; then
  echo "[WARN] Snapshot $POOL@$SNAP_NAME already exists. Skipping creation." | tee -a "$LOGFILE"
else
  echo "[INFO] Creating ZFS snapshot $POOL@$SNAP_NAME: $(date)" | tee -a "$LOGFILE"
  zfs snapshot -r "$POOL@$SNAP_NAME"
fi

echo "[INFO] Pruning old snapshots: $(date)" | tee -a "$LOGFILE"
# Prune snapshots older than retention
zfs list -H -t snapshot -o name,creation | while read snap _; do
  # Extract date from snapshot name if possible
  if [[ "$snap" =~ $POOL@auto-([0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4}) ]]; then
    snap_date=${BASH_REMATCH[1]}
    snap_epoch=$(date -j -f "%Y-%m-%d-%H%M" "$snap_date" +%s 2>/dev/null || date -d "$snap_date" +%s 2>/dev/null || echo 0)
    cutoff_epoch=$(date -d "-$RETENTION_DAYS days" +%s)
    if [[ $snap_epoch -lt $cutoff_epoch ]]; then
      echo "[INFO] Destroying old snapshot $snap" | tee -a "$LOGFILE"
      zfs destroy "$snap"
    fi
  fi
done

echo "[INFO] ZFS snapshot/prune complete: $(date)" | tee -a "$LOGFILE" 