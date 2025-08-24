# Unified error handling system for nix-mox
# Consolidates all error handling functionality into one consistent module

use ./unified-logging.nu *

# Error codes for consistent error handling
export const ERROR_CODES = {
    SUCCESS: 0,
    GENERAL_ERROR: 1,
    INVALID_ARGUMENT: 2,
    FILE_NOT_FOUND: 3,
    PERMISSION_DENIED: 4,
    DEPENDENCY_MISSING: 5,
    NETWORK_ERROR: 6,
    TIMEOUT_ERROR: 7,
    CONFIGURATION_ERROR: 8,
    SECURITY_ERROR: 9,
    VALIDATION_ERROR: 10,
    HANDLER_NOT_FOUND: 11,
    EXECUTION_ERROR: 12,
    SYSTEM_ERROR: 13
}

# Error severity levels
export const ERROR_SEVERITY = {
    LOW: "low",
    MEDIUM: "medium",
    HIGH: "high",
    CRITICAL: "critical"
}

# Enhanced logging functions with icons and colors
export def log_with_level [level: string, message: string, context: string = ""] {
    """Unified logging with levels, icons, and colors"""
    let timestamp = (date now | format date '%H:%M:%S')
    let level_icon = match $level {
        "info" => "ℹ️",
        "success" => "✅",
        "warning" => "⚠️",
        "error" => "❌",
        "debug" => "🐛",
        "critical" => "🚨",
        _ => "📝"
    }
    
    let level_color = match $level {
        "info" => "blue",
        "success" => "green",
        "warning" => "yellow",
        "error" => "red",
        "debug" => "dark_gray",
        "critical" => "red_bold",
        _ => "white"
    }
    
    let context_prefix = if ($context | str length) > 0 {
        "[$context] "
    } else {
        ""
    }
    
    print $"(ansi $level_color)($level_icon) ($timestamp) ($context_prefix)($message)(ansi reset)"
}

export def log_info [message: string, context: string = ""] {
    """Log info message"""
    log_with_level "info" $message $context
}

export def log_success [message: string, context: string = ""] {
    """Log success message"""
    log_with_level "success" $message $context
}

export def log_warning [message: string, context: string = ""] {
    """Log warning message"""
    log_with_level "warning" $message $context
}

export def log_error [message: string, context: string = ""] {
    """Log error message"""
    log_with_level "error" $message $context
}

export def log_debug [message: string, context: string = ""] {
    """Log debug message"""
    log_with_level "debug" $message $context
}

export def log_critical [message: string, context: string = ""] {
    """Log critical message"""
    log_with_level "critical" $message $context
}

# Main unified error handling function
export def handle_error [error: record, context: string = ""] {
    """Unified error handling with consistent formatting and logging"""
    
    let error_code = $error.code? | default $ERROR_CODES.GENERAL_ERROR
    let error_message = $error.message? | default "Unknown error"
    let error_details = $error.details? | default ""
    let error_severity = $error.severity? | default $ERROR_SEVERITY.MEDIUM
    let error_help = $error.help? | default ""
    let error_debug = $error.debug? | default ""
    
    # Log the error with appropriate level based on severity
    let log_level = match $error_severity {
        "critical" => "critical",
        "high" => "error",
        "medium" => "warning",
        "low" => "info",
        _ => "error"
    }
    
    # Create error context
    let error_context = if ($context | str length) > 0 {
        $context
    } else {
        "error-handling"
    }
    
    # Log the error with enhanced formatting
    log_with_level $log_level $"Error $error_code: ($error_message)" $error_context
    
    # Log additional details if provided
    if ($error_details | str length) > 0 {
        log_debug $"Details: ($error_details)" $error_context
    }
    
    # Log debug information if provided
    if ($error_debug | str length) > 0 {
        log_debug $"Debug: ($error_debug)" $error_context
    }
    
    # Log help information if provided
    if ($error_help | str length) > 0 {
        log_info $"Help: ($error_help)" $error_context
    }
    
    # Exit with error code for critical and high severity errors
    if $error_severity in ["critical", "high"] {
        exit $error_code
    }
    
    # Return error record for non-exiting errors
    {
        code: $error_code,
        message: $error_message,
        severity: $error_severity,
        context: $error_context
    }
}

# Convenience functions for common error types
export def handle_file_error [file_path: string, operation: string, context: string = ""] {
    if not ($file_path | path exists) {
        handle_error {
            code: $ERROR_CODES.FILE_NOT_FOUND,
            message: $"File not found: ($file_path)",
            details: $"Operation: ($operation)",
            severity: $ERROR_SEVERITY.HIGH,
            help: "Check if the file exists and the path is correct"
        } $context
    }
}

export def handle_permission_error [operation: string, context: string = ""] {
    handle_error {
        code: $ERROR_CODES.PERMISSION_DENIED,
        message: $"Permission denied for operation: ($operation)",
        severity: $ERROR_SEVERITY.HIGH,
        help: "Check if you have the required permissions or run with elevated privileges"
    } $context
}

export def handle_dependency_error [dependency: string, context: string = ""] {
    handle_error {
        code: $ERROR_CODES.DEPENDENCY_MISSING,
        message: $"Required dependency not found: ($dependency)",
        severity: $ERROR_SEVERITY.HIGH,
        help: $"Please install ($dependency) and try again"
    } $context
}

export def handle_network_error [operation: string, details: string = "", context: string = ""] {
    handle_error {
        code: $ERROR_CODES.NETWORK_ERROR,
        message: $"Network error during ($operation)",
        details: $details,
        severity: $ERROR_SEVERITY.MEDIUM,
        help: "Check your network connection and try again"
    } $context
}

export def handle_timeout_error [operation: string, timeout: string = "", context: string = ""] {
    let timeout_details = if ($timeout | str length) > 0 { $"Timeout: ($timeout)" } else { "" }
    handle_error {
        code: $ERROR_CODES.TIMEOUT_ERROR,
        message: $"Timeout during ($operation)",
        details: $timeout_details,
        severity: $ERROR_SEVERITY.MEDIUM,
        help: "The operation took too long. Try again or increase timeout settings"
    } $context
}

export def handle_config_error [config_path: string, details: string = "", context: string = ""] {
    handle_error {
        code: $ERROR_CODES.CONFIGURATION_ERROR,
        message: $"Configuration error in ($config_path)",
        details: $details,
        severity: $ERROR_SEVERITY.HIGH,
        help: "Check the configuration file syntax and required fields"
    } $context
}

export def handle_security_error [operation: string, details: string = "", context: string = ""] {
    handle_error {
        code: $ERROR_CODES.SECURITY_ERROR,
        message: $"Security issue detected in ($operation)",
        details: $details,
        severity: $ERROR_SEVERITY.CRITICAL,
        help: "Review the operation for security implications"
    } $context
}

export def handle_validation_error [validation_type: string, details: string = "", context: string = ""] {
    handle_error {
        code: $ERROR_CODES.VALIDATION_ERROR,
        message: $"Validation failed for ($validation_type)",
        details: $details,
        severity: $ERROR_SEVERITY.MEDIUM,
        help: "Check the input data and validation requirements"
    } $context
}

# Legacy compatibility functions (deprecated - use above functions instead)
export def handle_error_simple [message: string, context: string = ""] {
    handle_error {
        code: $ERROR_CODES.GENERAL_ERROR,
        message: $message,
        severity: $ERROR_SEVERITY.MEDIUM
    } $context
}

export def handle_error_with_code [code: int, message: string, details: string = "", context: string = ""] {
    handle_error {
        code: $code,
        message: $message,
        details: $details,
        severity: $ERROR_SEVERITY.HIGH
    } $context
}

# Enhanced safe execution wrapper
export def safe_exec [command: string, context: string = "", timeout: duration = 30sec] {
    """Safely execute a command with error handling"""
    try {
        let result = (nu -c $command | complete)
        if $result.exit_code == 0 {
            {
                success: true,
                output: $result.stdout,
                error: $result.stderr,
                exit_code: $result.exit_code
            }
        } else {
            log_error $"Command failed with exit code ($result.exit_code)" $context
            {
                success: false,
                output: $result.stdout,
                error: $result.stderr,
                exit_code: $result.exit_code
            }
        }
    } catch { |err|
        log_error $"Command execution failed: ($err.msg)" $context
        {
            success: false,
            output: "",
            error: $err.msg,
            exit_code: -1
        }
    }
}

# Enhanced require functions with better feedback
export def require_command [command: string, context: string = ""] {
    """Require a command to be available, exit if not"""
    let cmd_exists = (which $command | length)
    if $cmd_exists == 0 {
        handle_dependency_error $command $context
        false
    } else {
        log_success $"Command '$command' available" $context
        true
    }
}

export def require_file [file_path: string, context: string = ""] {
    """Require a file to exist, exit if not"""
    if not ($file_path | path exists) {
        handle_file_error $file_path "file access" $context
        false
    } else {
        log_success $"File '$file_path' exists" $context
        true
    }
}

export def require_directory [dir_path: string, context: string = ""] {
    """Require a directory to exist, exit if not"""
    if not (($dir_path | path exists) and (($dir_path | path type) == "dir")) {
        handle_error {
            code: $ERROR_CODES.FILE_NOT_FOUND,
            message: $"Directory not found: ($dir_path)",
            severity: $ERROR_SEVERITY.HIGH,
            help: "Check if the directory exists and the path is correct"
        } $context
        false
    } else {
        log_success $"Directory '$dir_path' exists" $context
        true
    }
}

# Exit functions for convenience
export def exit_with_error [message: string, exit_code: int = 1, context: string = ""] {
    """Exit with error message and code"""
    log_error $message $context
    exit $exit_code
}

export def exit_with_success [message: string, context: string = ""] {
    """Exit with success message"""
    log_success $message $context
    exit 0
}

# Environment validation
export def validate_environment [requirements: list] {
    """Validate environment requirements"""
    mut all_valid = true
    mut results = {}
    
    for req in $requirements {
        let valid = match $req.type {
            "command" => {
                let cmd_exists = (which $req.value | length)
                $cmd_exists > 0
            },
            "file" => ($req.value | path exists),
            "directory" => (($req.value | path exists) and (($req.value | path type) == "dir")),
            "permission" => {
                let perms = (ls -la $req.path | get mode | get 0)
                $perms | str contains $req.value
            },
            _ => false
        }
        
        $results = ($results | upsert $req.name $valid)
        if not $valid {
            $all_valid = false
            log_warning $"Requirement '$($req.name)' not met" "environment"
        } else {
            log_success $"Requirement '$($req.name)' met" "environment"
        }
    }
    
    {
        all_valid: $all_valid,
        results: $results
    }
}

# Retry functionality
export def retry_command [command: string, max_attempts: int = 3, delay: int = 1, context: string = ""] {
    """Retry a command with exponential backoff"""
    mut attempt = 1
    
    while $attempt <= $max_attempts {
        log_info $"Attempt ($attempt)/($max_attempts): ($command)" $context
        
        let result = (safe_exec $command $context)
        if $result.success {
            log_success $"Command succeeded on attempt ($attempt)" $context
            return $result
        }
        
        if $attempt < $max_attempts {
            let wait_time = ($delay * $attempt)
            log_warning $"Command failed, retrying in ($wait_time) seconds..." $context
            sleep ($wait_time | into duration)
        }
        
        $attempt = $attempt + 1
    }
    
    log_error $"Command failed after ($max_attempts) attempts" $context
    return {
        success: false,
        output: "",
        error: "Max retry attempts exceeded",
        exit_code: -1
    }
} 