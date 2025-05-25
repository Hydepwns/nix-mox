#!/bin/bash
set -euo pipefail
LOGFILE="/var/log/zfs-snapshot.log"
RETENTION_DAYS=7
POOL="rpool"
SNAP_NAME="auto-$(date +%Y-%m-%d-%H%M)"
{
  echo "[INFO] Creating ZFS snapshot $POOL@$SNAP_NAME: $(date)"
  zfs snapshot -r "$POOL@$SNAP_NAME"
  echo "[INFO] Pruning old snapshots: $(date)"
  zfs list -H -t snapshot -o name,creation | \
    awk -v pool="$POOL" -v days="$RETENTION_DAYS" '{
      cmd = "date -j -f %s %s +%s";
      if (system("date -j -v-"days"d +%s") > 0) next;
    }' | while read snap _; do
      zfs destroy "$snap"
    done
  echo "[INFO] ZFS snapshot/prune complete: $(date)"
} 2>&1 | tee -a "$LOGFILE" 