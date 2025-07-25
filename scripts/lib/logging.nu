# Enhanced logging module for nix-mox scripts
# Supports structured logging, multiple formats, and log rotation
use ./common.nu

# Log levels with numeric values
export const LOG_LEVELS = {
    DEBUG: 0
    INFO: 1
    WARN: 2
    ERROR: 3
    FATAL: 4
}

# Log format types
export const LOG_FORMATS = {
    TEXT: "text"
    JSON: "json"
    STRUCTURED: "structured"
}

# Simple platform detection
def detect_platform_simple [] {
    let os = $nu.os-info.name
    match $os {
        "Linux" => "linux"
        "Darwin" => "macos"
        "Windows_NT" => "windows"
        _ => "unknown"
    }
}

# Get color for log level
def get_log_color [level: string] {
    match $level {
        "DEBUG" => (ansi blue)
        "INFO" => (ansi green)
        "WARN" => (ansi yellow)
        "ERROR" => (ansi red)
        "FATAL" => (ansi red_bold)
        _ => (ansi reset)
    }
}

# Set global logging context
export-env {
    $env.LOG_CONTEXT = {
        script: "unknown"
        user: (whoami)
        platform: (detect_platform_simple)
        session_id: (random uuid)
    }
}

# Get current log level
export def get_log_level [] {
    $env | get -i LOG_LEVEL | default "INFO"
}

# Check if a log level should be output
export def should_log [level: string] {
    let current_level = (get_log_level)
    let level_value = ($LOG_LEVELS | get $level | default 0 | into int)
    let current_value = ($LOG_LEVELS | get $current_level | default 1 | into int)
    $level_value >= $current_value
}

# Get current timestamp with milliseconds
export def get_timestamp [] {
    date now | format date '%Y-%m-%d %H:%M:%S.%3f'
}

# Format log message for text output
export def format_text_log [level: string, message: string, context: record = {}] {
    let timestamp = (get_timestamp)
    let color = (get_log_color $level)
    let reset = (ansi reset)
    let context_str = if ($context | is-empty) {
        ""
    } else {
        $" [($context | to json -r)]"
    }
    $"($timestamp) ($color)[($level)]($reset) ($message)($context_str)"
}

# Format log message for JSON output
export def format_json_log [level: string, message: string, context: record = {}] {
    let log_entry = {
        timestamp: (get_timestamp)
        level: $level
        message: $message
        context: $context
        script: ($env.LOG_CONTEXT.script)
        user: ($env.LOG_CONTEXT.user)
        platform: ($env.LOG_CONTEXT.platform)
        session_id: ($env.LOG_CONTEXT.session_id)
    }
    $log_entry | to json
}

# Format log message for structured output
export def format_structured_log [level: string, message: string, context: record = {}] {
    let timestamp = (get_timestamp)
    let color = (get_log_color $level)
    let reset = (ansi reset)
    let context_str = if ($context | is-empty) {
        ""
    } else {
        let context_parts = ($context | each { |it| $"($it.key)=($it.value)" })
        $" [($context_parts | str join ' ')]"
    }
    $"($timestamp) ($color)[($level)]($reset) ($message)($context_str)"
}

# Write log to file with rotation
export def write_log_file [log_entry: string, log_file: string] {
    # Ensure log directory exists
    let log_dir = ($log_file | path dirname)
    if not ($log_dir | path exists) {
        mkdir $log_dir
    }

    # Check if log file needs rotation
    if ($log_file | path exists) {
        let file_size = (ls $log_file | get size.0 | into int)
        let max_size = 10MB  # 10MB default

        if $file_size > $max_size {
            rotate_log_file $log_file
        }
    }

    # Write log entry
    try {
        $log_entry | save --append $log_file
    } catch { |err|
        print $"Failed to write to log file ($log_file): ($err)"
        print $log_entry
    }
}

# Rotate log file
export def rotate_log_file [log_file: string] {
    let timestamp = (date now | format date '%Y%m%d-%H%M%S')
    let backup_file = $"($log_file).($timestamp)"

    try {
        mv $log_file $backup_file

        # Compress old log file
        if (which gzip | length) > 0 {
            gzip $backup_file
        }

        $"Rotated log file to ($backup_file).gz"
    } catch { |err|
        print $"Failed to rotate log file: ($err)"
    }
}

# Main logging function
export def log [level: string, message: string, context: record = {}] {
    if ($level | is-empty) {
        return
    }

    # Get log format from config or environment
    let format = ($env | get -i LOG_FORMAT | default "text")

    # Check if we should log this level
    if not (should_log $level) {
        return
    }

    # Format the log message
    let formatted_message = match $format {
        "json" => (format_json_log $level $message $context)
        "structured" => (format_structured_log $level $message $context)
        _ => (format_text_log $level $message $context)
    }

    # Output to console
    print $formatted_message

    # Write to file if configured
    let log_file = ($env | get -i LOG_FILE | default "")
    if ($log_file | str length) > 0 {
        write_log_file $formatted_message $log_file
    }
}

# Convenience functions for different log levels
export def debug [message: string, context: record = {}] {
    log "DEBUG" $message $context
}

export def info [message: string, context: record = {}] {
    log "INFO" $message $context
}

export def warn [message: string, context: record = {}] {
    log "WARN" $message $context
}

export def error [message: string, context: record = {}] {
    log "ERROR" $message $context
}

export def fatal [message: string, context: record = {}] {
    log "FATAL" $message $context
}

# Structured logging with automatic context
export def log_with_context [level: string, message: string, context: record = {}] {
    let full_context = ($env.LOG_CONTEXT | merge $context)
    log $level $message $full_context
}

# Performance logging
export def log_performance [operation: string, duration: duration, context: record = {}] {
    let perf_context = ($context | merge {
        operation: $operation
        duration_ms: ($duration | into int)
    })
    log "INFO" $"Performance: ($operation) took ($duration)" $perf_context
}

# Error logging with stack trace
export def log_error_with_trace [message: string, error: any, context: record = {}] {
    let error_context = ($context | merge {
        error_type: ($error | describe)
        error_message: ($error | to text)
    })
    log "ERROR" $message $error_context
}

# Initialize logging system
export def init_logging [config: record = {}] {
    # Set default log level
    if ($config.log_level | is-not-empty) {
        $env.LOG_LEVEL = $config.log_level
    }

    # Set log format
    if ($config.format | is-not-empty) {
        $env.LOG_FORMAT = $config.format
    }

    # Set log file
    if ($config.log_file | is-not-empty) {
        $env.LOG_FILE = $config.log_file
    }

    # Update context
    if ($config.script_name | is-not-empty) {
        $env.LOG_CONTEXT.script = $config.script_name
    }

    info "Logging system initialized"
}
