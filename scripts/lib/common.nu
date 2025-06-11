# _common.nu - Common utility functions for nix-mox scripts

# Export constants for use in other scripts
export const RED = ansi red
export const GREEN = ansi green
export const YELLOW = ansi yellow
export const BLUE = ansi blue
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

# Get current timestamp
export def timestamp [] {
    date now | format date '%Y-%m-%d %H:%M:%S'
}

# Define the log function with more idiomatic pattern matching
export def log [level: string, message: string] {
    let current_level = get_log_level
    let level_value = $LOG_LEVELS | get $level | default 0
    let current_value = $LOG_LEVELS | get $current_level | default 1
    if ($level_value | into int) >= ($current_value | into int) {
        let color = match $level {
            "ERROR" => $RED
            "WARN" => $YELLOW
            "INFO" => $GREEN
            "DEBUG" => $BLUE
            _ => $NC
        }
        let timestamp = (timestamp)
        let log_string = $"($timestamp) [($color)($level)($NC)] ($message)"
        print $log_string
        $log_string
    } else {
        ""
    }
}

# Define convenience logging functions
export def info [message: string] {
    log "INFO" $message
}

export def warn [message: string] {
    log "WARN" $message
}

export def error [message: string] {
    log "ERROR" $message
}

export def debug [message: string] {
    log "DEBUG" $message
}

export def handle_error [message: string] {
    print $"ERROR: ($message)"
    exit 1
}

export def check_root [] {
    if (whoami | str trim) == 'root' {
        "Running as root."
    } else {
        print $"ERROR: This script must be run as root."
        exit 1
    }
}

export def file_exists [path: string] {
    $path | path exists
}

export def dir_exists [path: string] {
    ($path | path exists) and (($path | path type) == 'dir')
}

export def ensure_dir [path: string] {
    if not (dir_exists $path) {
        mkdir $path
    }
}

export def is_ci_mode [] {
    $env.CI? == "true"
}
