#!/usr/bin/env nu
# Functional script template system for nix-mox
# Provides standardized patterns for script creation
# Eliminates boilerplate and ensures consistency

use logging.nu *
use validators.nu *
use command-wrapper.nu *

# Standard script main function wrapper
export def script_main [
    name: string,
    description: string,
    --context: string = "main",
    --validations: list<record> = [],
    --prereqs: list<string> = [],
    --platform: list<string> = ["linux", "macos", "windows"]
] {
    | operation: closure|
    
    info $"($name): ($description)" --context $context
    
    # Run platform validation
    if ($platform | length) > 0 {
        let platform_check = (validate_platform $platform)
        if not $platform_check.success {
            error $platform_check.message --context $context
            return
        }
    }
    
    # Run prerequisite checks
    for $prereq in $prereqs {
        let prereq_check = (validate_command $prereq)
        if not $prereq_check.success {
            error $prereq_check.message --context $context
            return
        }
    }
    
    # Run additional validations
    if ($validations | length) > 0 {
        let validation_results = (run_validations $validations --context $context)
        if not $validation_results.success {
            error "Pre-execution validations failed" --context $context
            return
        }
    }
    
    # Execute main operation
    do $operation
}

# Standard argument parser with common patterns
export def parse_standard_args [custom_args: record = {}] {
    let base_args = {
        help: { short: "h", description: "Show help message", flag: true },
        dry_run: { short: "n", description: "Dry run mode", flag: true },
        verbose: { short: "v", description: "Verbose output", flag: true },
        context: { short: "c", description: "Logging context", default: "script" }
    }
    
    $base_args | merge $custom_args
}

# Environment setup function
export def setup_script_environment [
    --log-level: string = "INFO",
    --log-file: string = ""
] {
    # Set log level
    $env.LOG_LEVEL = $log_level
    
    # Set log file if specified
    if not ($log_file | is-empty) {
        $env.LOG_FILE = $log_file
    }
    
    # Ensure required directories exist
    let dirs = ["logs", "tmp", "coverage-tmp"]
    for $dir in $dirs {
        if not ($dir | path exists) {
            mkdir $dir
        }
    }
}

# Standard error handler
export def handle_script_error [
    error_msg: string,
    --exit-code: int = 1,
    --context: string = "error"
] {
    critical $error_msg --context $context
    exit $exit_code
}

# Success handler
export def handle_script_success [
    success_msg: string = "Operation completed successfully",
    --context: string = "success"
] {
    success $success_msg --context $context
}

# Standard help formatter
export def format_help [
    name: string,
    description: string,
    usage: string,
    commands: list<record> = [],
    options: list<record> = [],
    examples: list<record> = []
] {
    print $"($name)"
    let length = ($name | str length)
    let separator = (seq 1 $length | each { "=" } | str join)
    print $separator
    print ""
    print $description
    print ""
    
    if not ($usage | is-empty) {
        print $"Usage: ($usage)"
        print ""
    }
    
    if ($commands | length) > 0 {
        print "Commands:"
        for $cmd in $commands {
            print $"  ($cmd.name | fill -w 12) ($cmd.description)"
        }
        print ""
    }
    
    if ($options | length) > 0 {
        print "Options:"
        for $opt in $options {
            let short = if "short" in $opt { $"-($opt.short), " } else { "    " }
            print $"  ($short)--($opt.name | fill -w 12) ($opt.description)"
        }
        print ""
    }
    
    if ($examples | length) > 0 {
        print "Examples:"
        for $ex in $examples {
            print $"  ($ex.command)"
            if "description" in $ex {
                print $"    ($ex.description)"
            }
        }
        print ""
    }
}

# Configuration loader with validation
export def load_script_config [
    config_file: string = "nix-mox.json",
    --required = false
] {
    if ($config_file | path exists) {
        try {
            let config = (open $config_file | from json)
            debug $"Loaded configuration from ($config_file)" --context "config"
            $config
        } catch { | err|
            if $required {
                handle_script_error $"Failed to load required config file ($config_file): ($err.msg)"
            } else {
                warn $"Failed to load optional config file ($config_file): ($err.msg)" --context "config"
                {}
            }
        }
    } else {
        if $required {
            handle_script_error $"Required config file not found: ($config_file)"
        } else {
            debug $"Optional config file not found: ($config_file)" --context "config"
            {}
        }
    }
}

# Performance measurement wrapper
export def measure_performance [operation_name: string] {
    | operation: closure|
    let start_time = (date now)
    let start_memory = (sys mem | get used)
    
    debug $"Starting performance measurement for: ($operation_name)" --context "perf"
    
    try {
        let result = (do $operation)
        let end_time = (date now)
        let end_memory = (sys mem | get used)
        let duration = ($end_time - $start_time)
        let memory_delta = ($end_memory - $start_memory)
        
        info $"Performance: ($operation_name) completed in ($duration), memory delta: ($memory_delta)" --context "perf"
        $result
    } catch { | err|
        let end_time = (date now)
        let duration = ($end_time - $start_time)
        warn $"Performance: ($operation_name) failed after ($duration): ($err.msg)" --context "perf"
        $err
    }
}

# Safe file operations
export def safe_write_file [file_path: string, content: string, --backup = true] {
    if $backup and ($file_path | path exists) {
        let backup_path = $"($file_path).backup.(date now | format date '%Y%m%d-%H%M%S')"
        cp $file_path $backup_path
        debug $"Created backup: ($backup_path)" --context "file-ops"
    }
    
    try {
        $content | save --force $file_path
        success $"File written successfully: ($file_path)" --context "file-ops"
    } catch { | err|
        handle_script_error $"Failed to write file ($file_path): ($err.msg)"
    }
}

# Interactive confirmation
export def confirm [message: string, --default = false] {
    let prompt = if $default {
        $"($message) [Y/n]: "
    } else {
        $"($message) [y/N]: "
    }
    
    let response = (input $prompt | str downcase | str trim)
    
    match $response {
        "" => $default,
        "y" | "yes" => true,
        "n" | "no" => false,
        _ => {
            warn "Invalid response. Please enter y/yes or n/no."
            confirm $message --default $default
        }
    }
}

# Standard script cleanup
export def cleanup_on_exit [] {
    debug "Performing script cleanup..." --context "cleanup"
    
    # Clean up temporary files
    let temp_patterns = ["tmp/*", "coverage-tmp/*", "*.tmp"]
    for $pattern in $temp_patterns {
        try {
            let files = (glob $pattern)
            if ($files | length) > 0 {
                $files | each { | file| rm -f $file }
                debug $"Cleaned up temporary files: ($pattern)" --context "cleanup"
            }
        } catch {
            # Ignore cleanup errors
        }
    }
}