#!/bin/bash
# Proxmox Host Update Script
# Usage: sudo ./proxmox-update.sh
# Logs to /var/log/proxmox-update.log

set -euo pipefail

LOGFILE="/var/log/proxmox-update.log"

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

{
  echo "[INFO] Starting Proxmox update: $(date)"
  apt update
  apt -y dist-upgrade
  apt -y autoremove
  pveupdate
  pveupgrade
  echo "[INFO] Proxmox update complete: $(date)"
} 2>&1 | tee -a "$LOGFILE" 