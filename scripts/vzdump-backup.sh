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

if [[ $DRY_RUN -eq 1 ]]; then
  echo "[DRY RUN] No changes will be made." | tee -a "$LOGFILE"
fi

trap 'echo "[FAIL] vzdump backup failed: $(date)" | tee -a "$LOGFILE"' ERR

if [[ $DRY_RUN -eq 1 ]]; then
  echo "[DRY RUN] No changes were made." | tee -a "$LOGFILE"
  exit 0
else
  {
    echo "[INFO] Starting vzdump backup: $(date)"
    ALL_OK=1
    for VMID in $(qm list | awk 'NR>1 {print $1}'); do
      if vzdump "$VMID" --storage "$STORAGE" --mode snapshot --compress zstd; then
        echo "[INFO] Backed up VM $VMID" | tee -a "$LOGFILE"
      else
        echo "[ERROR] Failed to backup VM $VMID" | tee -a "$LOGFILE"
        ALL_OK=0
      fi
    done
    for CTID in $(pct list | awk 'NR>1 {print $1}'); do
      if vzdump "$CTID" --storage "$STORAGE" --mode snapshot --compress zstd; then
        echo "[INFO] Backed up CT $CTID" | tee -a "$LOGFILE"
      else
        echo "[ERROR] Failed to backup CT $CTID" | tee -a "$LOGFILE"
        ALL_OK=0
      fi
    done
    if [[ $ALL_OK -eq 1 ]]; then
      echo "[SUCCESS] vzdump backup complete: $(date)" | tee -a "$LOGFILE"
    else
      echo "[FAIL] vzdump backup completed with errors: $(date)" | tee -a "$LOGFILE"
      exit 1
    fi
  } 2>&1 | tee -a "$LOGFILE"
fi 