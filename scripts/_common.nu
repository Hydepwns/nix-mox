# _common.nu - Common utility functions for nix-mox scripts

# Export constants for use in other scripts
export const RED = ansi red
export const GREEN = ansi green
export const YELLOW = ansi yellow
export const NC = ansi reset

# Use nushell's native table syntax
export const LOG_LEVELS = {
    DEBUG: 0
    INFO: 1
    WARN: 2
    ERROR: 3
}

# Get current log level from environment or use default
export def get_log_level [] {
    $env.LOG_LEVEL? | default "INFO"
}

# Define the log function with more idiomatic pattern matching
export def log [level: string, message: string] {
    let current_level = get_log_level
    let level_value = $LOG_LEVELS | get $level | default -1

    if $level_value >= ($LOG_LEVELS | get $current_level) {
        let color = match $level {
            "ERROR" => $RED
            "WARN" => $YELLOW
            "INFO" => $GREEN
            _ => $NC
        }
        let timestamp = (date now | format date '%Y-%m-%d %H:%M:%S')
        $"($timestamp) [($color)($level)($NC)] ($message)"
    } else {
        ""
    }
}

# Define convenience logging functions
export def log_info [message: string] {
    log "INFO" $message
}

export def log_warn [message: string] {
    log "WARN" $message
}

export def log_error [message: string] {
    log "ERROR" $message
}

export def handle_error [message: string] {
    let error_msg = log "ERROR" $message
    print $error_msg
    exit 1
}

export def check_root [] {
    if (is-admin) {
        "ok"
    } else {
        "This script must be run as root."
    }
}

export def file_exists [path: string] {
    $path | path exists
}

export def dir_exists [path: string] {
    $path | path exists
}

export def ensure_dir [path: string] {
    if not ($path | path exists) {
        mkdir $path
    }
}

export def is_ci_mode [] {
    $env.CI? == "true"
}
