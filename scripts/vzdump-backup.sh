#!/bin/bash
# Proxmox vzdump Backup Script
# Usage: sudo ./vzdump-backup.sh
# Logs to /var/log/vzdump-backup.log

set -euo pipefail

LOGFILE="/var/log/vzdump-backup.log"
STORAGE="backup"

# Check for root
if [[ $EUID -ne 0 ]]; then
  echo "[ERROR] This script must be run as root." | tee -a "$LOGFILE"
  exit 1
fi

# Check for required commands
for cmd in vzdump qm pct; do
  if ! command -v $cmd &>/dev/null; then
    echo "[ERROR] Required command '$cmd' not found." | tee -a "$LOGFILE"
    exit 1
  fi
done

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