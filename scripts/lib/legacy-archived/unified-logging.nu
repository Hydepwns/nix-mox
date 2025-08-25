# ⚠️  DEPRECATED: unified-logging.nu is deprecated!
# Use lib/logging.nu instead - this legacy library will be removed
# Consolidated logging system for nix-mox

# Log levels with numeric values for comparison
export const LOG_LEVELS = {
    TRACE: 0,
    DEBUG: 1,
    INFO: 2,
    SUCCESS: 3,
    WARN: 4,
    ERROR: 5,
    CRITICAL: 6
}

# ANSI color codes
export const COLORS = {
    TRACE: "dark_gray",
    DEBUG: "blue",
    INFO: "green",
    SUCCESS: "green",
    WARN: "yellow",
    ERROR: "red",
    CRITICAL: "red"
}

# Icons for different log levels
export const ICONS = {
    TRACE: "🔍",
    DEBUG: "🐛",
    INFO: "ℹ️",
    SUCCESS: "✅",
    WARN: "⚠️",
    ERROR: "❌",
    CRITICAL: "🚨"
}

# Get current log level from environment or use default
export def get_log_level [] {
    if ($env | get -o LOG_LEVEL | is-empty) {
        "INFO"
    } else {
        $env | get LOG_LEVEL
    }
}

# Get current timestamp
export def timestamp [] {
    date now | format date '%Y-%m-%d %H:%M:%S'
}

# Main unified logging function
export def log [level: string, message: string, context: string = "", log_file: string = ""] {
    let current_level = (get_log_level)
    let level_value = ($LOG_LEVELS | get $level | default 0)
    let current_value = ($LOG_LEVELS | get $current_level | default 2)

    if ($level_value | into int) >= ($current_value | into int) {
        let color = ($COLORS | get $level | default "white")
        let icon = ($ICONS | get $level | default "📝")
        let timestamp = (timestamp)
        let context_prefix = if ($context | str length) > 0 {
            "[$context] "
        } else {
            ""
        }
        
        let log_string = $"($timestamp) ($icon) ($context_prefix)($message)"
        let colored_string = $"(ansi $color)($log_string)(ansi reset)"
        
        print $colored_string
        
        # Write to log file if specified
        if ($log_file | str length) > 0 {
            try {
                $log_string | save --append $log_file
            } catch { |err|
                print $"(ansi red)Failed to write to log file ($log_file): ($err)(ansi reset)"
            }
        }
        
        $log_string
    } else {
        ""
    }
}

# Convenience functions for each log level
export def trace [message: string, context: string = "", log_file: string = ""] {
    log "TRACE" $message $context $log_file
}

export def debug [message: string, context: string = "", log_file: string = ""] {
    log "DEBUG" $message $context $log_file
}

export def info [message: string, context: string = "", log_file: string = ""] {
    log "INFO" $message $context $log_file
}

export def success [message: string, context: string = "", log_file: string = ""] {
    log "SUCCESS" $message $context $log_file
}

export def warn [message: string, context: string = "", log_file: string = ""] {
    log "WARN" $message $context $log_file
}

export def error [message: string, context: string = "", log_file: string = ""] {
    log "ERROR" $message $context $log_file
}

export def critical [message: string, context: string = "", log_file: string = ""] {
    log "CRITICAL" $message $context $log_file
}

# Legacy compatibility functions (deprecated - use above functions instead)
export def log_info [message: string, log_file: string = ""] {
    info $message "" $log_file
}

export def log_warn [message: string, log_file: string = ""] {
    warn $message "" $log_file
}

export def log_error [message: string, log_file: string = ""] {
    error $message "" $log_file
}

export def log_success [message: string, log_file: string = ""] {
    success $message "" $log_file
}

export def log_debug [message: string, log_file: string = ""] {
    debug $message "" $log_file
}

export def log_trace [message: string, log_file: string = ""] {
    trace $message "" $log_file
}

# Function to append command output to log file
export def append-to-log [log_file: string] {
    try {
        $in | save --append $log_file
    } catch { |err|
        error $"Failed to append to log file ($log_file): ($err)"
    }
}

# Dry run logging
export def dry_run [message: string, context: string = ""] {
    info $"DRY RUN: ($message)" $context
} 