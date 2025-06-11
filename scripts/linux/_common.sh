# Common functions for nix-mox Linux scripts (Bash)

# Color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

# Log levels
LOG_LEVELS=(DEBUG INFO WARN ERROR)
LOG_LEVEL="INFO"

# Get current timestamp
timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Get log level index
log_level_index() {
    local level="$1"
    for i in "${!LOG_LEVELS[@]}"; do
        if [[ "${LOG_LEVELS[$i]}" == "$level" ]]; then
            echo "$i"
            return
        fi
    done
    echo "0"
}

# Main log function
log() {
    local level="$1"
    shift
    local msg="$*"
    local color="$NC"
    local level_idx
    local current_idx
    
    case "$level" in
        ERROR) color="$RED" ;;
        WARN)  color="$YELLOW" ;;
        INFO)  color="$GREEN" ;;
        DEBUG) color="$BLUE" ;;
    esac
    
    level_idx=$(log_level_index "$level")
    current_idx=$(log_level_index "$LOG_LEVEL")
    
    if (( level_idx >= current_idx )); then
        echo -e "$(timestamp) [${color}${level}${NC}] $msg"
    fi
}

info()  { log INFO  "$*"; }
warn()  { log WARN  "$*"; }
error() { log ERROR "$*"; }
debug() { log DEBUG "$*"; }

# Check if running as root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        error "This script must be run as root."
        exit 1
    fi
}

# File/dir utilities
file_exists() { [ -f "$1" ]; }
dir_exists()  { [ -d "$1" ]; }
ensure_dir()   { dir_exists "$1" || mkdir -p "$1"; }

# Check if running in CI mode
is_ci_mode() {
    [ "${CI:-}" = "true" ]
} 