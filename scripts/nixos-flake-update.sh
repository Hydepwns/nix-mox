#!/bin/bash
# NixOS Flake Update & Rebuild Script
# Usage: sudo ./nixos-flake-update.sh [--dry-run] [--flake-path PATH] [--help]
# Logs to /var/log/nixos-flake-update.log
#
# Options:
#   --dry-run         Show what would be done, but make no changes
#   --flake-path PATH Set flake path (default: /etc/nixos or $FLAKE_PATH)
#   --help            Show this help message

set -euo pipefail

LOGFILE="/var/log/nixos-flake-update.log"
FLAKE_PATH="${FLAKE_PATH:-/etc/nixos}"
HOSTNAME=$(hostname)
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
    --flake-path)
      FLAKE_PATH="$2"
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
for cmd in nix nixos-rebuild; do
  if ! command -v $cmd &>/dev/null; then
    echo "[ERROR] Required command '$cmd' not found." | tee -a "$LOGFILE"
    exit 1
  fi
done

trap 'echo "[FAIL] NixOS flake update failed: $(date)" | tee -a "$LOGFILE"' ERR

if [[ $DRY_RUN -eq 1 ]]; then
  echo "[DRY RUN] No changes were made." | tee -a "$LOGFILE"
  exit 0
else
  {
    echo "[INFO] Starting NixOS flake update: $(date)"
    nix flake update "$FLAKE_PATH"
    nixos-rebuild switch --flake "$FLAKE_PATH#$HOSTNAME"
    echo "[SUCCESS] NixOS flake update complete: $(date)"
  } 2>&1 | tee -a "$LOGFILE"
fi 