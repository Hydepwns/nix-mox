#!/usr/bin/env nu
# Consolidated logging system for nix-mox
# Replaces common.nu, unified-logging.nu, and unified-error-handling.nu logging functions
# Uses functional patterns and Nushell pipelines for DRY, composable logging

# Log levels with numeric values for filtering
export const LOG_LEVELS = {
    TRACE: 0,
    DEBUG: 1,
    INFO: 2,
    SUCCESS: 3,
    WARN: 4,
    ERROR: 5,
    CRITICAL: 6
}

# Visual styling for terminal output
const STYLES = {
    TRACE: { color: "dark_gray", icon: "🔍" },
    DEBUG: { color: "blue", icon: "🐛" },
    INFO: { color: "cyan", icon: "ℹ️" },
    SUCCESS: { color: "green", icon: "✅" },
    WARN: { color: "yellow", icon: "⚠️" },
    ERROR: { color: "red", icon: "❌" },
    CRITICAL: { color: "red", icon: "🚨" }
}

# Get current log level from environment
export def get_log_level [] {
    $env | get LOG_LEVEL? | default "INFO"
}

# Core logging function with functional composition
export def log [
    level: string,
    message: string,
    --context: string = "",
    --file: string = "",
    --no-timestamp = false
] {
    let current_level = (get_log_level)
    let level_value = ($LOG_LEVELS | get $level | default 2)
    let current_value = ($LOG_LEVELS | get $current_level | default 2)

    if $level_value >= $current_value {
        let style = ($STYLES | get $level)
        let timestamp = if $no_timestamp { "" } else { 
            $" (date now | format date '%H:%M:%S')" 
        }
        let context_part = if ($context | is-empty) { "" } else { $"[($context)] " }
        
        let log_message = $"($timestamp) ($style.icon) ($context_part)($message)"
        let colored_message = $"(ansi ($style.color))($log_message)(ansi reset)"
        
        print $colored_message
        
        # Write to file if specified
        if not ($file | is-empty) {
            try {
                $log_message | save --append $file
            } catch { | err|
                print $"(ansi red)Log file error: ($err)(ansi reset)"
            }
        }
        
        $log_message
    } else {
        ""
    }
}

# Higher-order function for operation logging
export def with_logging [
    operation: string, 
    --context: string = "main",
    --level: string = "info"
] {
    | action: closure|
    
    log $level $"Starting: ($operation)" --context $context
    let start_time = (date now)
    
    try {
        let result = (do $action)
        let duration = ((date now) - $start_time)
        log "SUCCESS" $"Completed: ($operation) in ($duration)" --context $context
        $result
    } catch { | err|
        log "ERROR" $"Failed: ($operation) - ($err.msg)" --context $context
        $err
    }
}

# Functional pipeline for conditional logging
export def log_if [condition: bool] {
    | level: string, message: string, context: string = ""|
    if $condition {
        log $level $message --context $context
    }
}

# Convenience functions with functional composition
export def trace [message: string, --context: string = "", --file: string = ""] {
    log "TRACE" $message --context $context --file $file
}

export def debug [message: string, --context: string = "", --file: string = ""] {
    log "DEBUG" $message --context $context --file $file
}

export def info [message: string, --context: string = "", --file: string = ""] {
    log "INFO" $message --context $context --file $file
}

export def success [message: string, --context: string = "", --file: string = ""] {
    log "SUCCESS" $message --context $context --file $file
}

export def warn [message: string, --context: string = "", --file: string = ""] {
    log "WARN" $message --context $context --file $file
}

export def error [message: string, --context: string = "", --file: string = ""] {
    log "ERROR" $message --context $context --file $file
}

export def critical [message: string, --context: string = "", --file: string = ""] {
    log "CRITICAL" $message --context $context --file $file
}

# Legacy compatibility (deprecated but maintained for gradual migration)
export def log_info [message: string, log_file: string = ""] {
    info $message --file $log_file
}

export def log_warn [message: string, log_file: string = ""] {
    warn $message --file $log_file
}

export def log_error [message: string, log_file: string = ""] {
    error $message --file $log_file
}

export def log_success [message: string, log_file: string = ""] {
    success $message --file $log_file
}

export def log_debug [message: string, log_file: string = ""] {
    debug $message --file $log_file
}

export def log_trace [message: string, log_file: string = ""] {
    trace $message --file $log_file
}

# Pipeline function for log file writing
export def save_to_log [file_path: string] {
    try {
        $in | save --append $file_path
    } catch { | err|
        error $"Failed to write to log file ($file_path): ($err.msg)"
    }
}

# Functional dry-run logging
export def dry_run [message: string, --context: string = ""] {
    info $"DRY RUN: ($message)" --context $context
}

# Batch logging for multiple messages
export def log_batch [messages: list<record>] {
    $messages | each { | msg|
        log $msg.level $msg.message --context ($msg | get context? | default "") --file ($msg | get file? | default "")
    }
}

# Additional helper functions for consistent formatting

# Banner/header formatting
export def banner [title: string, subtitle: string = "", --context: string = ""] {
    let title_length = ($title | str length)
    let separator = (seq 1 $title_length | each { "=" } | str join)
    
    info $title --context $context
    info $separator --context $context
    if not ($subtitle | is-empty) {
        info $subtitle --context $context
    }
    info "" --context $context
}

# Progress indicators with context
export def progress [current: int, total: int, message: string, --context: string = ""] {
    let percentage = (($current * 100) / $total | math round)
    let progress_msg = $"[($current)/($total)] ($percentage)% - ($message)"
    info $progress_msg --context $context
}

# Status report with formatted items
export def status_report [items: list<record>, --context: string = ""] {
    info "Status Report:" --context $context
    $items | each { | item|
        let status_icon = if $item.success { "✅" } else { "❌" }
        let status_msg = $"  ($status_icon) ($item.name): ($item.message)"
        if $item.success {
            success $status_msg --context $context
        } else {
            error $status_msg --context $context
        }
    }
}

# Section headers for script organization
export def section [name: string, --context: string = ""] {
    info "" --context $context
    info $"=== ($name) ===" --context $context
}

# Step logging for multi-step processes
export def step [step_number: int, total_steps: int, description: string, --context: string = ""] {
    let step_msg = $"Step ($step_number)/($total_steps): ($description)"
    info $step_msg --context $context
}

# Summary logging for completion status
export def summary [title: string, success_count: int, total_count: int, --context: string = ""] {
    let percentage = if $total_count > 0 { (($success_count * 100) / $total_count | math round) } else { 0 }
    let perc_str = ($percentage | into string)
    let summary_msg = $"($title): ($success_count)/($total_count) successful ($perc_str)%"
    
    if $success_count == $total_count {
        success $summary_msg --context $context
    } else if $success_count > 0 {
        warn $summary_msg --context $context
    } else {
        error $summary_msg --context $context
    }
}