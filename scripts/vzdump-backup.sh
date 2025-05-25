#!/bin/bash
set -euo pipefail
LOGFILE="/var/log/vzdump-backup.log"
STORAGE="backup"
{
  echo "[INFO] Starting vzdump backup: $(date)"
  for VMID in $(qm list | awk 'NR>1 {print $1}'); do
    vzdump "$VMID" --storage "$STORAGE" --mode snapshot --compress zstd
  done
  for CTID in $(pct list | awk 'NR>1 {print $1}'); do
    vzdump "$CTID" --storage "$STORAGE" --mode snapshot --compress zstd
  done
  echo "[INFO] vzdump backup complete: $(date)"
} 2>&1 | tee -a "$LOGFILE" 