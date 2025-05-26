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
  echo "[ERROR] This script must be run as root." | tee -a "$LOGFILE"
  exit 1
fi

# Check for required commands
for cmd in apt pveupdate pveupgrade; do
  if ! command -v $cmd &>/dev/null; then
    echo "[ERROR] Required command '$cmd' not found." | tee -a "$LOGFILE"
    exit 1
  fi
done

trap 'echo "[FAIL] Proxmox update failed: $(date)" | tee -a "$LOGFILE"' ERR

if [[ $DRY_RUN -eq 1 ]]; then
  echo "[DRY RUN] No changes were made." | tee -a "$LOGFILE"
  exit 0
else
  {
    echo "[INFO] Starting Proxmox update: $(date)"
    apt update
    apt -y dist-upgrade
    apt -y autoremove
    pveupdate
    pveupgrade
    echo "[SUCCESS] Proxmox update complete: $(date)"
  } 2>&1 | tee -a "$LOGFILE"
fi 