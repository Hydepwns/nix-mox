#!/bin/bash
set -euo pipefail
LOGFILE="/var/log/proxmox-update.log"
{
  echo "[INFO] Starting Proxmox update: $(date)"
  apt update
  apt -y dist-upgrade
  apt -y autoremove
  pveupdate
  pveupgrade
  echo "[INFO] Proxmox update complete: $(date)"
} 2>&1 | tee -a "$LOGFILE" 