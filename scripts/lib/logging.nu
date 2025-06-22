# Enhanced logging module for nix-mox scripts
# Supports structured logging, multiple formats, and log rotation

use ./common.nu *

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
    let os = (sys).host.name
    match $os {
        "Linux" => "linux"
        "Windows" => "windows"
        "Darwin" => "darwin"
        _ => "unknown"
    }
}

# Get color for log level
def get_log_color [level: string] {
    match $level {
        "DEBUG" => { ansi blue }
        "INFO" => { ansi green }
        "WARN" => { ansi yellow }
        "ERROR" => { ansi red }
        "FATAL" => { ansi red_bold }
        _ => { ansi reset }
    }
}

# Set global logging context
export-env {
    $env.LOG_CONTEXT = {
        script: ($env.SCRIPT_NAME? | default "unknown")
        user: (whoami)
        platform: (detect_platform_simple)
        session_id: (random uuid)
    }
}

# Get current log level
export def get_log_level [] {
    $env.LOG_LEVEL? | default "INFO"
}

# Check if a log level should be output
export def should_log [level: string] {
    let current_level = get_log_level
    let level_value = $LOG_LEVELS | get $level | default 0
    let current_value = $LOG_LEVELS | get $current_level | default 1

    ($level_value | into int) >= ($current_value | into int)
}

# Get current timestamp with milliseconds
export def get_timestamp [] {
    date now | format date '%Y-%m-%d %H:%M:%S.%3f'
}

# Format log message for text output
export def format_text_log [level: string, message: string, context: record = {}] {
    let timestamp = get_timestamp
    let color = get_log_color $level
    let reset = ansi reset

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
        timestamp: get_timestamp
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
    let timestamp = get_timestamp
    let color = get_log_color $level
    let reset = ansi reset

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

        info $"Rotated log file to ($backup_file.gz)"
    } catch { |err|
        print $"Failed to rotate log file: ($err)"
    }
}

# Main logging function
export def log [level: string, message: string, context: record = {}] {
    if not (should_log $level) {
        return
    }

    # Get log format from config or environment
    let format = ($env.LOG_FORMAT? | default "text")

    # Format log message
    let log_entry = match $format {
        "json" => { format_json_log $level $message $context }
        "structured" => { format_structured_log $level $message $context }
        _ => { format_text_log $level $message $context }
    }

    # Output to console
    print $log_entry

    # Write to file if configured
    if ($env.LOG_FILE? | is-not-empty) {
        write_log_file $log_entry $env.LOG_FILE
    }
}

# Convenience logging functions
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

# Log with automatic context from function call
export def log_with_context [level: string, message: string, function: string = "", line: int = 0] {
    let context = {
        function: $function
        line: $line
        timestamp: get_timestamp
    }

    log $level $message $context
}

# Log performance metrics
export def log_performance [operation: string, duration: duration, context: record = {}] {
    let perf_context = ($context | upsert operation $operation | upsert duration_ms ($duration | into int) | upsert duration_sec (($duration | into int) / 1000))

    log "INFO" $"Performance: ($operation) completed in ($duration)" $perf_context
}

# Log command execution
export def log_command [command: string, args: list, context: record = {}] {
    let cmd_context = ($context | upsert command $command | upsert args ($args | str join " ") | upsert timestamp get_timestamp)

    log "DEBUG" $"Executing: ($command) ($args | str join ' ')" $cmd_context
}

# Log command result
export def log_command_result [command: string, exit_code: int, output: string, context: record = {}] {
    let result_context = ($context | upsert command $command | upsert exit_code $exit_code | upsert output_length ($output | str length) | upsert timestamp get_timestamp)

    let level = if $exit_code == 0 { "DEBUG" } else { "ERROR" }
    let message = $"Command result: ($command) exited with ($exit_code)"

    log $level $message $result_context
}

# Setup logging from configuration
export def setup_logging [config: record] {
    # Set log level
    $env.LOG_LEVEL = $config.logging.level

    # Set log format
    $env.LOG_FORMAT = $config.logging.format

    # Set log file if specified
    if $config.logging.file != null {
        $env.LOG_FILE = $config.logging.file
    }

    # Set script name for context
    $env.SCRIPT_NAME = ($env.SCRIPT_NAME? | default "unknown")

    info "Logging system initialized" {
        level: $config.logging.level
        format: $config.logging.format
        file: $config.logging.file
    }
}

# Create log context for a specific operation
export def create_log_context [operation: string, additional_context: record = {}] {
    let base_context = {
        operation: $operation
        timestamp: get_timestamp
        session_id: ($env.LOG_CONTEXT.session_id)
    }

    # Combine contexts using upsert
    mut result = $base_context
    for key in ($additional_context | columns) {
        let value = $additional_context | get $key
        $result = ($result | upsert $key $value)
    }

    $result
}

# Log structured data
export def log_data [level: string, message: string, data: any, context: record = {}] {
    let data_context = ($context | upsert data_type ($data | describe) | upsert data_size (if ($data | describe) == "string" { $data | str length } else { $data | length }))

    log $level $message $data_context

    # Log data details if in debug mode
    if (should_log "DEBUG") {
        debug "Data details" {
            data: $data
            context: $context
        }
    }
}

# Log error with stack trace
export def log_error_with_trace [message: string, error: any, context: record = {}] {
    let error_context = ($context | upsert error_type ($error | describe) | upsert error_message (if ($error | describe) == "string" { $error } else { $error | to json }))

    error $message $error_context
}

# Log security events
export def log_security_event [event_type: string, message: string, severity: string = "INFO", context: record = {}] {
    let security_context = ($context | upsert event_type $event_type | upsert severity $severity | upsert user (whoami) | upsert ip ($env.SSH_CLIENT? | default "unknown"))

    log $severity $"Security: ($message)" $security_context
}

# Log audit trail
export def log_audit [action: string, resource: string, result: string, context: record = {}] {
    let audit_context = ($context | upsert action $action | upsert resource $resource | upsert result $result | upsert user (whoami) | upsert timestamp get_timestamp)

    info $"Audit: ($action) on ($resource) - ($result)" $audit_context
}

# Get log statistics
export def get_log_stats [log_file: string] {
    if not ($log_file | path exists) {
        return { total: 0, by_level: {}, by_hour: {} }
    }

    try {
        let lines = (open $log_file | lines)
        let total = ($lines | length)

        # Parse log levels (assuming text format)
        let levels = ($lines | each { |line|
            if ($line | str contains "[DEBUG]") { "DEBUG" }
            else if ($line | str contains "[INFO]") { "INFO" }
            else if ($line | str contains "[WARN]") { "WARN" }
            else if ($line | str contains "[ERROR]") { "ERROR" }
            else if ($line | str contains "[FATAL]") { "FATAL" }
            else { "UNKNOWN" }
        })

        let by_level = ($levels | group-by | each { |group| { level: $group.0, count: ($group.1 | length) } })

        {
            total: $total
            by_level: $by_level
            file_size: (ls $log_file | get size.0)
        }
    } catch { |err|
        error $"Failed to get log stats: ($err)"
        { total: 0, by_level: [], file_size: 0 }
    }
}
