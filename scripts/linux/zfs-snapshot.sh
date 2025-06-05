#!/bin/bash
# ZFS Snapshot & Prune Script
# Usage: sudo ./zfs-snapshot.sh [--dry-run] [--retention DAYS] [--pool NAME] [--help]
# Logs to /var/log/zfs-snapshot.log
#
# Options:
#   --dry-run         Show what would be done, but make no changes
#   --retention DAYS  Set retention period in days (default: 7 or $RETENTION_DAYS)
#   --pool NAME       Set ZFS pool name (default: rpool or $ZFS_POOL)
#   --help            Show this help message

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPTS_DIR/_common.sh"

# Script-specific variables
LOGFILE="/var/log/zfs-snapshot.log"
RETENTION_DAYS="${RETENTION_DAYS:-7}"
POOL="${ZFS_POOL:-rpool}"
SNAP_NAME_PREFIX="auto-"
SNAP_DATE_FORMAT="%Y-%m-%d-%H%M"
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
    --retention)
      RETENTION_DAYS="$2"
      shift 2
      ;;
    --pool)
      POOL="$2"
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

# Check for required command
if ! command -v zfs &>/dev/null; then
  log_error "Required command 'zfs' not found." "$LOGFILE"
  exit 1
fi

trap 'log_error "An unexpected error occurred on line $LINENO. Command: $BASH_COMMAND." "$LOGFILE"' ERR

# --- Snapshot Creation ---
log_info "Starting ZFS snapshot process for pool: $POOL" "$LOGFILE"
SNAP_NAME="${SNAP_NAME_PREFIX}$(date +$SNAP_DATE_FORMAT)"
FULL_SNAP_NAME="$POOL@$SNAP_NAME"

if zfs list -t snapshot -H -o name | grep -q "^${FULL_SNAP_NAME}$"; then
  log_warn "Snapshot $FULL_SNAP_NAME already exists. Skipping creation." "$LOGFILE"
else
  if [[ $DRY_RUN -eq 1 ]]; then
    log_dryrun "Would create ZFS snapshot: $FULL_SNAP_NAME" "$LOGFILE"
  else
    log_info "Creating ZFS snapshot: $FULL_SNAP_NAME..." "$LOGFILE"
    if ! zfs snapshot -r "$FULL_SNAP_NAME"; then
      log_error "Failed to create snapshot $FULL_SNAP_NAME. Proceeding to prune." "$LOGFILE"
    else
      log_success "Successfully created snapshot $FULL_SNAP_NAME." "$LOGFILE"
    fi
  fi
fi

# --- Snapshot Pruning ---
PRUNE_FAILED=0
log_info "Pruning snapshots in '$POOL' older than $RETENTION_DAYS days with prefix '$SNAP_NAME_PREFIX'..." "$LOGFILE"

if ! [[ "$RETENTION_DAYS" =~ ^[0-9]+$ ]]; then
    log_error "Invalid retention period: '$RETENTION_DAYS' is not a number. Skipping prune." "$LOGFILE"
    exit 1
fi

time_cutoff=$(date -d "-$RETENTION_DAYS days" +%s)

# Use zfs list with parseable output (-p) to get creation timestamp as epoch
# -t snapshot: only list snapshots
# -H: no header
# -o name,creation: output only name and creation property
# -S creation: sort by creation time (descending)
# -r: recursive for the given pool
zfs list -p -H -t snapshot -o name,creation -S creation -r "$POOL" | while read -r snap_name snap_epoch; do
  # Filter for our auto-generated snapshots
  if ! [[ "$snap_name" =~ @${SNAP_NAME_PREFIX} ]]; then
    continue
  fi

  if [[ "$snap_epoch" -lt "$time_cutoff" ]]; then
    if [[ $DRY_RUN -eq 1 ]]; then
      log_dryrun "Would destroy old snapshot: $snap_name (created $(date -d "@$snap_epoch"))" "$LOGFILE"
    else
      log_info "Destroying old snapshot: $snap_name (created $(date -d "@$snap_epoch"))..." "$LOGFILE"
      if zfs destroy "$snap_name"; then
        log_success "Destroyed snapshot: $snap_name" "$LOGFILE"
      else
        log_error "Failed to destroy snapshot: $snap_name" "$LOGFILE"
        PRUNE_FAILED=1
      fi
    fi
  fi
done

# --- Final Status ---
if [[ $PRUNE_FAILED -eq 1 ]]; then
  log_error "ZFS snapshot/prune for pool '$POOL' completed with errors during pruning." "$LOGFILE"
  exit 1
else
  if [[ $DRY_RUN -eq 1 ]]; then
    log_dryrun "Dry run complete. No changes were made." "$LOGFILE"
  else
    log_success "ZFS snapshot/prune for pool '$POOL' complete." "$LOGFILE"
  fi
fi 