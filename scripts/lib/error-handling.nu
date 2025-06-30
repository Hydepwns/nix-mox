# Error handling module for nix-mox scripts
# Provides structured error handling with recovery suggestions

use ./common.nu *
use ./platform.nu *

# Error types and their recovery strategies
export const ERROR_TYPES = {
    PERMISSION_DENIED: {
        code: 1
        category: "permission"
        recovery: "Check file permissions and user privileges"
    }
    COMMAND_NOT_FOUND: {
        code: 2
        category: "dependency"
        recovery: "Install required command or check PATH"
    }
    CONFIG_INVALID: {
        code: 3
        category: "configuration"
        recovery: "Validate configuration file syntax and settings"
    }
    NETWORK_ERROR: {
        code: 4
        category: "network"
        recovery: "Check network connectivity and firewall settings"
    }
    DISK_SPACE: {
        code: 5
        category: "resource"
        recovery: "Free up disk space or expand storage"
    }
    TIMEOUT: {
        code: 6
        category: "performance"
        recovery: "Increase timeout or optimize operation"
    }
    PLATFORM_UNSUPPORTED: {
        code: 7
        category: "platform"
        recovery: "Use supported platform or check compatibility"
    }
    DEPENDENCY_MISSING: {
        code: 8
        category: "dependency"
        recovery: "Install missing dependencies"
    }
    VALIDATION_FAILED: {
        code: 9
        category: "validation"
        recovery: "Fix validation errors in input data"
    }
    UNKNOWN: {
        code: 255
        category: "unknown"
        recovery: "Check logs and contact support"
    }
}

# Generate unique error ID
export def generate_error_id [] {
    random uuid
}

# Create structured error record
export def create_error [message: string, type: string = "UNKNOWN", context: record = {}] {
    let error_id = generate_error_id
    let timestamp = (date now | format date '%Y-%m-%d %H:%M:%S')
    let error_info = $ERROR_TYPES | get $type | default ($ERROR_TYPES | get UNKNOWN)

    {
        id: $error_id
        timestamp: $timestamp
        message: $message
        type: $type
        code: $error_info.code
        category: $error_info.category
        recovery: $error_info.recovery
        context: $context
        script: ($env.SCRIPT_NAME? | default "unknown")
        platform: (detect_platform)
        user: (whoami)
    }
}

# Log error to structured log file
export def log_error_structured [error: record] {
    let log_file = ($env.ERROR_LOG_FILE? | default "logs/errors.json")

    # Ensure log directory exists
    let log_dir = ($log_file | path dirname)
    if not ($log_dir | path exists) {
        mkdir $log_dir
    }

    # Append error to log file
    try {
        $error | to json | save --append $log_file
    } catch { |err|
        print $"Failed to log error: ($err)"
    }
}

# Provide recovery suggestions based on error type
export def suggest_recovery [error: record] {
    print $"\n(ansi yellow_bold)Recovery Suggestions:(ansi reset)"
    print $"  ($error.recovery)"

    match $error.category {
        "permission" => { suggest_permission_recovery $error }
        "dependency" => { suggest_dependency_recovery $error }
        "configuration" => { suggest_config_recovery $error }
        "network" => { suggest_network_recovery $error }
        "resource" => { suggest_resource_recovery $error }
        "performance" => { suggest_performance_recovery $error }
        "platform" => { suggest_platform_recovery $error }
        "validation" => { suggest_validation_recovery $error }
        _ => { suggest_general_recovery $error }
    }
}

# Specific recovery suggestions
def suggest_permission_recovery [error: record] {
    print $"\n(ansi cyan)Permission Recovery Steps:(ansi reset)"
    print "  1. Check if you have sufficient privileges"
    print "  2. Use 'sudo' for operations requiring root access"
    print "  3. Verify file and directory permissions"
    print "  4. Check if user is in required groups"
}

def suggest_dependency_recovery [error: record] {
    print $"\n(ansi cyan)Dependency Recovery Steps:(ansi reset)"
    print "  1. Install missing package or command"
    print "  2. Check if PATH includes required directories"
    print "  3. Verify package installation status"
    print "  4. Update package lists and try again"
}

def suggest_config_recovery [error: record] {
    print $"\n(ansi cyan)Configuration Recovery Steps:(ansi reset)"
    print "  1. Validate configuration file syntax"
    print "  2. Check for missing required fields"
    print "  3. Verify configuration file permissions"
    print "  4. Use configuration validation tools"
}

def suggest_network_recovery [error: record] {
    print $"\n(ansi cyan)Network Recovery Steps:(ansi reset)"
    print "  1. Check network connectivity"
    print "  2. Verify firewall settings"
    print "  3. Check DNS resolution"
    print "  4. Test with different network"
}

def suggest_resource_recovery [error: record] {
    print $"\n(ansi cyan)Resource Recovery Steps:(ansi reset)"
    print "  1. Free up disk space"
    print "  2. Check available memory"
    print "  3. Monitor resource usage"
    print "  4. Consider resource limits"
}

def suggest_performance_recovery [error: record] {
    print $"\n(ansi cyan)Performance Recovery Steps:(ansi reset)"
    print "  1. Increase timeout values"
    print "  2. Optimize operation parameters"
    print "  3. Check system load"
    print "  4. Consider running during off-peak hours"
}

def suggest_platform_recovery [error: record] {
    print $"\n(ansi cyan)Platform Recovery Steps:(ansi reset)"
    print "  1. Check platform compatibility"
    print "  2. Use supported platform version"
    print "  3. Install platform-specific dependencies"
    print "  4. Consider alternative approaches"
}

def suggest_validation_recovery [error: record] {
    print $"\n(ansi cyan)Validation Recovery Steps:(ansi reset)"
    print "  1. Fix input data format"
    print "  2. Check required fields"
    print "  3. Validate data types"
    print "  4. Use validation tools"
}

def suggest_general_recovery [error: record] {
    print $"\n(ansi cyan)General Recovery Steps:(ansi reset)"
    print "  1. Check script logs for details"
    print "  2. Verify system requirements"
    print "  3. Try running with --debug flag"
    print "  4. Contact support with error ID: ($error.id)"
}

# Main error handling function
export def handle_script_error [message: string, type: string = "UNKNOWN", context: record = {}, exit_on_error: bool = true] {
    let error = create_error $message $type $context

    # Log error using common module
    error $"Error ID: ($error.id)"
    error $"Type: ($error.type)"
    error $"Message: ($error.message)"

    # Log to structured file
    log_error_structured $error

    # Show recovery suggestions
    suggest_recovery $error

    # Exit if requested
    if $exit_on_error {
        exit $error.code
    }

    $error
}

# Validate error type
export def validate_error_type [type: string] {
    $ERROR_TYPES | get -i $type | is-not-empty
}

# Get error statistics
export def get_error_stats [log_file: string = "logs/errors.json"] {
    if not ($log_file | path exists) {
        return { total: 0, by_type: {}, by_category: {} }
    }

    try {
        let errors = (open $log_file | lines | each { |line| $line | from json })

        let by_type = ($errors | group-by type | each { |group| { type: $group.0, count: ($group.1 | length) } })
        let by_category = ($errors | group-by category | each { |group| { category: $group.0, count: ($group.1 | length) } })

        {
            total: ($errors | length)
            by_type: $by_type
            by_category: $by_category
        }
    } catch { |err|
        error $"Failed to read error stats: ($err)"
        { total: 0, by_type: [], by_category: [] }
    }
}

# Clean old error logs
export def clean_error_logs [days: int = 30] {
    let log_file = ($env.ERROR_LOG_FILE? | default "logs/errors.json")

    if not ($log_file | path exists) {
        return
    }

    try {
        let cutoff_date = ((date now) - ($days * 24hr))
        let errors = (open $log_file | lines | each { |line| $line | from json })

        let recent_errors = ($errors | where { |error|
            let error_date = ($error.timestamp | into datetime)
            $error_date > $cutoff_date
        })

        # Save filtered errors back
        $recent_errors | each { |error| $error | to json } | save $log_file

        let removed_count = ($errors | length) - ($recent_errors | length)
        info $"Cleaned ($removed_count) old error entries"
    } catch { |err|
        error $"Failed to clean error logs: ($err)"
    }
}
