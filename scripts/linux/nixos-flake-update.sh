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

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_common.sh
source "$SCRIPTS_DIR/_common.sh"

# Script-specific variables
LOGFILE="/var/log/nixos-flake-update.log"
FLAKE_PATH="${FLAKE_PATH:-/etc/nixos}"
HOSTNAME=$(hostname)
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
    --flake-path)
      FLAKE_PATH="$2"
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
for cmd in nix git; do
  if ! command -v $cmd &>/dev/null; then
    log_error "Required command '$cmd' not found." "$LOGFILE"
    exit 1
  fi
done

trap 'log_error "An unexpected error occurred on line $LINENO. Command: $BASH_COMMAND." "$LOGFILE"' ERR

log_info "Starting NixOS flake update process for $FLAKE_PATH..." "$LOGFILE"

if [[ ! -d "$FLAKE_PATH/.git" ]]; then
    log_warn "Flake path '$FLAKE_PATH' is not a git repository. Cannot check for changes."
fi

# Get the state of the lock file before the update
pre_update_hash=""
if [[ -f "$FLAKE_PATH/flake.lock" ]]; then
    pre_update_hash=$(git -C "$FLAKE_PATH" rev-parse HEAD:flake.lock 2>/dev/null || date -r "$FLAKE_PATH/flake.lock" +%s)
fi

if [[ $DRY_RUN -eq 1 ]]; then
    log_dryrun "Dry-run mode: Would attempt to update flake inputs at '$FLAKE_PATH'." "$LOGFILE"
    log_dryrun "Dry-run mode: Would rebuild system if flake inputs changed." "$LOGFILE"
    exit 0
fi

# Run update and rebuild, redirecting all output to the log file
{
    log_info "Updating flake inputs..."
    nix flake update "$FLAKE_PATH"

    # Get the state of the lock file after the update
    post_update_hash=""
    if [[ -f "$FLAKE_PATH/flake.lock" ]]; then
        post_update_hash=$(git -C "$FLAKE_PATH" rev-parse HEAD:flake.lock 2>/dev/null || date -r "$FLAKE_PATH/flake.lock" +%s)
    fi

    if [[ "$pre_update_hash" == "$post_update_hash" ]]; then
        log_info "No changes to flake.lock detected. System is up to date."
    else
        log_info "flake.lock changed. Rebuilding system..."
        nixos-rebuild switch --flake "$FLAKE_PATH#$(hostname)"
        log_success "NixOS system rebuild complete."
    fi

} | tee -a "$LOGFILE"

log_success "NixOS flake update process finished." "$LOGFILE" 