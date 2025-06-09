#!/usr/bin/env bash

# Common functions and variables for nix-mox scripts

# Log levels
declare -A LOG_LEVELS=(
    ["DEBUG"]=0
    ["INFO"]=1
    ["WARN"]=2
    ["ERROR"]=3
)

# Default log level
LOG_LEVEL=${LOG_LEVEL:-"INFO"}

# Logging function
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Check if the log level is enabled
    if [ "${LOG_LEVELS[$level]}" -ge "${LOG_LEVELS[$LOG_LEVEL]}" ]; then
        echo "[$timestamp] [$level] $message"
    fi
}

# Error handling
handle_error() {
    local exit_code=$1
    local error_message=$2
    
    log "ERROR" "$error_message"
    exit $exit_code
}

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        handle_error 1 "This script must be run as root"
    fi
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if a file exists
file_exists() {
    [ -f "$1" ]
}

# Check if a directory exists
directory_exists() {
    [ -d "$1" ]
}

# Create directory if it doesn't exist
ensure_directory() {
    local dir="$1"
    if ! directory_exists "$dir"; then
        mkdir -p "$dir"
        log "INFO" "Created directory: $dir"
    fi
}

# Check if running in CI
is_ci() {
    [ "${CI:-false}" = "true" ]
}

# Set log level based on CI environment
if is_ci; then
    LOG_LEVEL="DEBUG"
fi 