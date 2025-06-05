#!/bin/bash
# Proxmox Host Update Script
# Usage: sudo ./proxmox-update.sh [--dry-run] [--help]
# Logs to /var/log/proxmox-update.log
#
# Options:
#   --dry-run         Show what would be done, but make no changes
#   --help            Show this help message

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPTS_DIR/_common.sh"

# Script-specific variables
LOGFILE="/var/log/proxmox-update.log"
DRY_RUN=0
APT_OPTIONS="-y" # Default options for apt
PVE_OPTIONS=""     # Default options for pveupdate/pveupgrade

# Ensure log file exists and is writable
touch "$LOGFILE" || { log_error "Log file is not writable: $LOGFILE"; exit 1; }

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      APT_OPTIONS="--dry-run"
      PVE_OPTIONS="--dry-run"
      shift
      ;;
    --help|-h)
      usage
      ;;
    *)
      log_error "Unknown option: $1" "$LOGFILE"
      usage
      ;;
  esac
done

check_root "$LOGFILE"

# Check for required commands
for cmd in apt pveupdate pveupgrade; do
  if ! command -v $cmd &>/dev/null; then
    log_error "Required command '$cmd' not found." "$LOGFILE"
    exit 1
  fi
done

trap 'log_error "An error occurred on line $LINENO. Command: $BASH_COMMAND. Exit code: $?." "$LOGFILE"' ERR

log_info "Starting Proxmox update..." "$LOGFILE"

if [[ $DRY_RUN -eq 1 ]]; then
  log_dryrun "Dry-run mode enabled. The following commands would be executed:" "$LOGFILE"
fi

# Run updates, redirecting stdout/stderr to the log file
{
  log_info "Updating package lists..."
  apt update

  log_info "Performing distribution upgrade..."
  apt $APT_OPTIONS dist-upgrade

  log_info "Removing unused packages..."
  apt $APT_OPTIONS autoremove

  log_info "Running pveupdate..."
  pveupdate $PVE_OPTIONS

  log_info "Running pveupgrade..."
  pveupgrade $PVE_OPTIONS

} | tee -a "$LOGFILE"

if [[ $DRY_RUN -eq 1 ]]; then
  log_dryrun "Dry run complete. No changes were made." "$LOGFILE"
else
  log_success "Proxmox update complete." "$LOGFILE"
fi 