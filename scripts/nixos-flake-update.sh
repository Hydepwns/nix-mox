#!/bin/bash
# NixOS Flake Update & Rebuild Script
# Usage: sudo ./nixos-flake-update.sh
# Logs to /var/log/nixos-flake-update.log

set -euo pipefail

LOGFILE="/var/log/nixos-flake-update.log"
FLAKE_PATH="/etc/nixos"
HOSTNAME=$(hostname)

# Check for root
if [[ $EUID -ne 0 ]]; then
  echo "[ERROR] This script must be run as root." | tee -a "$LOGFILE"
  exit 1
fi

# Check for required commands
for cmd in nix nixos-rebuild; do
  if ! command -v $cmd &>/dev/null; then
    echo "[ERROR] Required command '$cmd' not found." | tee -a "$LOGFILE"
    exit 1
  fi
done

{
  echo "[INFO] Starting NixOS flake update: $(date)"
  nix flake update "$FLAKE_PATH"
  nixos-rebuild switch --flake "$FLAKE_PATH#$HOSTNAME"
  echo "[INFO] NixOS flake update complete: $(date)"
} 2>&1 | tee -a "$LOGFILE" 