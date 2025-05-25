#!/bin/bash
set -euo pipefail
LOGFILE="/var/log/nixos-flake-update.log"
FLAKE_PATH="/etc/nixos"
HOSTNAME=$(hostname)
{
  echo "[INFO] Starting NixOS flake update: $(date)"
  nix flake update "$FLAKE_PATH"
  nixos-rebuild switch --flake "$FLAKE_PATH#$HOSTNAME"
  echo "[INFO] NixOS flake update complete: $(date)"
} 2>&1 | tee -a "$LOGFILE" 