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
        "critical" => "CRITICAL",
        "high" => "ERROR",
        "medium" => "WARN",
        "low" => "INFO",
        _ => "ERROR"
    }
    
    # Create error context
    let error_context = if ($context | str length) > 0 {
        $context
    } else {
        "error-handling"
    }
    
    # Log the error
    log $log_level $"Error $error_code: ($error_message)" $error_context
    
    # Log additional details if provided
    if ($error_details | str length) > 0 {
        debug $"Details: ($error_details)" $error_context
    }
    
    # Log debug information if provided
    if ($error_debug | str length) > 0 {
        debug $"Debug: ($error_debug)" $error_context
    }
    
    # Log help information if provided
    if ($error_help | str length) > 0 {
        info $"Help: ($error_help)" $error_context
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

# Safe execution wrapper
export def safe_exec [command: string, context: string = "", timeout: duration = 30sec] {
    """Safely execute a command with error handling"""
    try {
        let result = (nu -c $command)
        {
            success: true,
            output: $result,
            error: "",
            exit_code: 0
        }
    } catch { |err|
        {
            success: false,
            output: "",
            error: $err,
            exit_code: -1
        }
    }
}

# Require command to exist
export def require_command [command: string, context: string = ""] {
    if (which $command | length) == 0 {
        handle_dependency_error $command $context
        false
    } else {
        true
    }
}

# Require file to exist
export def require_file [file_path: string, context: string = ""] {
    if not ($file_path | path exists) {
        handle_file_error $file_path "file access" $context
        false
    } else {
        true
    }
}

# Require directory to exist
export def require_directory [dir_path: string, context: string = ""] {
    if not (($dir_path | path exists) and (($dir_path | path type) == "dir")) {
        handle_error {
            code: $ERROR_CODES.FILE_NOT_FOUND,
            message: $"Directory not found: ($dir_path)",
            severity: $ERROR_SEVERITY.HIGH,
            help: "Check if the directory exists and the path is correct"
        } $context
        false
    } else {
        true
    }
} 