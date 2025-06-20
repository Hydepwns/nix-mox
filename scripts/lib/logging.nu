# Logging module for nix-mox
# This replaces the bash logging.sh with a more robust Nushell implementation

# Error codes
let ERROR_CODES = {
    SUCCESS: 0
    INVALID_ARGUMENT: 1
    FILE_NOT_FOUND: 2
    PERMISSION_DENIED: 3
    HANDLER_NOT_FOUND: 4
    DEPENDENCY_MISSING: 5
    EXECUTION_FAILED: 6
    TIMEOUT: 7
    INVALID_STATE: 8
    NETWORK_ERROR: 9
    CONFIGURATION_ERROR: 10
}

def get_timestamp [] {
    date now | format date "%Y-%m-%d %H:%M:%S"
}

def log [level: string, message: string] {
    # Skip logging if quiet mode is enabled
    if $env.QUIET {
        return
    }

    let timestamp = get_timestamp
    let log_message = $"[($timestamp)] [($level)] ($message)"

    # Write to log file if specified
    if $env.LOG_FILE != "" {
        $log_message | save --append $env.LOG_FILE
    }

    # Print to console based on level
    match $level {
        "ERROR" => { print -e $log_message }
        "WARN" => { print -e $log_message }
        _ => { print $log_message }
    }
}

def handle_error [code: int, message: string, details: list<string>] {
    mut error_code = $ERROR_CODES | get -i $code
    if $error_code == null {
        $error_code = $code
    }

    log "ERROR" $message
    for detail in $details {
        log "ERROR" $"Context: ($detail)"
    }

    match $error_code {
        1 => {
            log "INFO" "Try running with --help for usage information"
        }
        2 => {
            log "INFO" "Check if the file exists and you have the correct permissions"
        }
        3 => {
            log "INFO" "Try running with elevated privileges or check file permissions"
        }
        4 => {
            log "INFO" "Check if the handler script exists and is executable"
        }
        5 => {
            log "INFO" "Install the required dependencies and try again"
        }
        6 => {
            log "INFO" "Try running with --verbose for more details or check the script for errors"
        }
        7 => {
            log "INFO" "Try increasing the timeout with --timeout or optimize the script"
        }
        8 => {
            log "INFO" "The system is in an unexpected state. Try resetting or checking configuration"
        }
        9 => {
            log "INFO" "Check your network connection and try again"
        }
        10 => {
            log "INFO" "Check your configuration files for errors"
        }
        _ => {
            log "INFO" "An unexpected error occurred"
        }
    }

    exit $error_code
}

# Export the functions and constants
export-env {
    $env.ERROR_CODES = $ERROR_CODES
}

# Main function to handle logging operations
def main [] {
    let args = $in
    match $args.0 {
        "log" => { log $args.1 $args.2 }
        "error" => { handle_error $args.1 $args.2 ($args | skip 2) }
        _ => { print "Unknown logging operation" }
    }
} 