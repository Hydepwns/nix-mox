# _common.nu - Common utility functions for nix-mox scripts

# Export constants for use in other scripts
export const RED = ansi red
export const GREEN = ansi green
export const YELLOW = ansi yellow
export const BLUE = ansi blue
export const NC = ansi reset

# Use nushell's native table syntax
export const LOG_LEVELS = {
    DEBUG: 0,
    INFO: 1,
    WARN: 2,
    ERROR: 3,
    SUCCESS: 4
}

# Get current log level from environment or use default
export def get_log_level [] {
    if ($env | get -i LOG_LEVEL | is-empty) {
        "INFO"
    } else {
        $env | get LOG_LEVEL
    }
}

# Get current timestamp
export def timestamp [] {
    date now | format date '%Y-%m-%d %H:%M:%S'
}

# Define the log function with more idiomatic pattern matching
export def log [level: string, message: string] {
    let current_level = (get_log_level)
    let level_value = ($LOG_LEVELS | get $level | default 0)
    let current_value = ($LOG_LEVELS | get $current_level | default 1)

    if ($level_value | into int) >= ($current_value | into int) {
        let color = match $level {
            "ERROR" => $RED,
            "WARN" => $YELLOW,
            "INFO" => $GREEN,
            "DEBUG" => $BLUE,
            "SUCCESS" => $GREEN,
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

# Basic logging functions (for scripts that need simple logging without full logging.nu)
# For advanced logging features, use logging.nu instead
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

# Additional logging functions for install/uninstall scripts
export def log_success [message: string] {
    log "SUCCESS" $message
}

export def log_dryrun [message: string] {
    log "DRY RUN" $message
}

# Enhanced logging functions that support log files
export def log_info [message: string, log_file: string = ""] {
    let log_string = (log "INFO" $message)
    if ($log_file | str length) > 0 {
        try {
            $log_string | save --append $log_file
        } catch {
            print $"Failed to write to log file ($log_file): Unknown error"
        }
    }
}

export def log_warn [message: string, log_file: string = ""] {
    let log_string = (log "WARN" $message)
    if ($log_file | str length) > 0 {
        try {
            $log_string | save --append $log_file
        } catch {
            print $"Failed to write to log file ($log_file): Unknown error"
        }
    }
}

export def log_error [message: string, log_file: string = ""] {
    let log_string = (log "ERROR" $message)
    if ($log_file | str length) > 0 {
        try {
            $log_string | save --append $log_file
        } catch {
            print $"Failed to write to log file ($log_file): Unknown error"
        }
    }
}

# Function to append command output to log file
export def append-to-log [log_file: string] {
    try {
        $in | save --append $log_file
    } catch {
        print $"Failed to append to log file ($log_file): Unknown error"
    }
}

export def handle_error [message: string] {
    print $"ERROR: ($message)"
    exit 1
}

export def check_root [] {
    if (whoami | str trim) == 'root' {
        "Running as root."
    } else {
        print "ERROR: This script must be run as root."
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
    if not ($path | path exists) {
        mkdir $path
    }
}

export def is_ci_mode [] {
    if ($env | get -i CI | is-empty) {
        false
    } else {
        ($env | get CI) == "true"
    }
}

# Usage function for scripts
export def usage [] {
    print "Usage: This script requires root privileges and supports --dry-run and --help options."
    print "Run with --help for specific usage information."
}

export def log_trace [message: string] {
    log "DEBUG" $message
}
