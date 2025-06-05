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

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPTS_DIR/_common.sh"

# Script-specific variables
LOGFILE="/var/log/vzdump-backup.log"
STORAGE="${STORAGE:-backup}"
DRY_RUN=0

# Ensure log file exists and is writable
touch "$LOGFILE" || { log_error "Log file is not writable: $LOGFILE"; exit 1; }

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
      log_error "Unknown option: $1" "$LOGFILE"
      usage
      ;;
  esac
done

check_root "$LOGFILE"

# Check for required commands
for cmd in vzdump qm pct; do
  if ! command -v $cmd &>/dev/null; then
    log_error "Required command '$cmd' not found." "$LOGFILE"
    exit 1
  fi
done

# --- Main Logic ---

# Function to list and back up items (VMs or CTs)
# Takes list_command, item_type (e.g., "VM"), and a reference to an error flag
backup_items() {
  local list_cmd="$1"
  local item_type="$2"
  local -n backup_failed_ref="$3"

  local ids
  ids=$($list_cmd | awk 'NR>1 {print $1}' || true)

  if [[ -z "$ids" ]]; then
    log_info "No ${item_type}s found to back up."
    return
  fi

  for id in $ids; do
    log_info "Processing backup for $item_type $id..."
    if [[ $DRY_RUN -eq 1 ]]; then
      log_dryrun "Would back up $item_type $id to storage '$STORAGE'"
    else
      if vzdump "$id" --storage "$STORAGE" --mode snapshot --compress zstd; then
        log_success "Successfully backed up $item_type $id."
      else
        log_error "Failed to back up $item_type $id."
        backup_failed_ref=1
      fi
    fi
  done
}

# --- Execution ---

trap 'log_error "An unexpected error occurred on line $LINENO. Command: $BASH_COMMAND." "$LOGFILE"' ERR

log_info "Starting Proxmox backup process..." "$LOGFILE"

BACKUP_FAILED=0

# Run backup process and redirect all output to the log file
{
  backup_items "qm list" "VM" BACKUP_FAILED
  backup_items "pct list" "CT" BACKUP_FAILED
} | tee -a "$LOGFILE"

# Final status reporting
if [[ $BACKUP_FAILED -eq 1 ]]; then
  log_error "vzdump backup completed with one or more errors." "$LOGFILE"
  exit 1
else
  if [[ $DRY_RUN -eq 1 ]]; then
    log_dryrun "Dry run complete. No backups were performed." "$LOGFILE"
  else
    log_success "vzdump backup completed successfully." "$LOGFILE"
  fi
fi 