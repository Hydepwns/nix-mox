#!/usr/bin/env nu
# Functional validation pipeline for nix-mox
# Consolidates validation logic using functional composition
# Replaces scattered validation patterns across scripts

use logging.nu *
use platform.nu *
use error-handling.nu *
use error-patterns.nu *

# Core validation pipeline function
export def validate_pipeline [...validators: closure] {
    |input|
    $validators | reduce --fold $input { |validator, acc|
        $acc | do $validator
    }
}

# Higher-order function for optional validators (functional composition)
export def optional_validator [validator: closure] {
    try { 
        let result = (null | do $validator)
        if $result.success {
            $result
        } else {
            validation_result true "Optional component missing (OK)"
        }
    } catch { 
        validation_result true "Optional component missing (OK)" 
    }
}

# Quiet command validator (no error logging for optional components)
export def validate_command_quiet [cmd: string] {
    |input|
    # Input type validation
    if ($cmd | is-empty) {
        return (validation_result false "Command name cannot be empty")
    }
    if ($cmd | describe) != "string" {
        return (validation_result false $"Command name must be a string, got ($cmd | describe)")
    }
    if ($cmd | str contains " ") {
        return (validation_result false "Command name cannot contain spaces")
    }
    
    let exists = (which $cmd | is-not-empty)
    if $exists {
        validation_result true $"Command ($cmd) found"
    } else {
        validation_result false $"Command ($cmd) missing"
    }
}

# Quiet file validator (no error logging for optional components)  
export def validate_file_quiet [path: string] {
    |input|
    # Input type validation
    if ($path | is-empty) {
        return (validation_result false "File path cannot be empty")
    }
    if ($path | describe) != "string" {
        return (validation_result false $"File path must be a string, got ($path | describe)")
    }
    if ($path | str length) > 4096 {
        return (validation_result false "File path too long (max 4096 characters)")
    }
    
    let exists = ($path | path exists)
    if $exists {
        validation_result true $"File ($path) found"
    } else {
        validation_result false $"File ($path) missing"
    }
}

# Quiet directory validator (no error logging for optional components)
export def validate_directory_quiet [path: string] {
    |input|
    # Input type validation
    if ($path | is-empty) {
        return (validation_result false "Directory path cannot be empty")
    }
    if ($path | describe) != "string" {
        return (validation_result false $"Directory path must be a string, got ($path | describe)")
    }
    if ($path | str length) > 4096 {
        return (validation_result false "Directory path too long (max 4096 characters)")
    }
    
    let exists = ($path | path exists) and (($path | path type) == "dir")
    if $exists {
        validation_result true $"Directory ($path) found"
    } else {
        validation_result false $"Directory ($path) missing"
    }
}

# Resilient network validator with timeout handling
export def validate_network_resilient [host: string = "8.8.8.8", timeout: int = 3] {
    |input|
    # Input type validation
    if ($host | is-empty) {
        return (validation_result false "Host cannot be empty")
    }
    if ($host | describe) != "string" {
        return (validation_result false $"Host must be a string, got ($host | describe)")
    }
    if ($timeout | describe) != "int" {
        return (validation_result false $"Timeout must be an integer, got ($timeout | describe)")
    }
    if $timeout < 1 or $timeout > 300 {
        return (validation_result false "Timeout must be between 1 and 300 seconds")
    }
    
    try {
        # Use shorter timeout for faster failure
        let result = (timeout $"($timeout)s" ping -c 1 -W ($timeout) $host | complete)
        if $result.exit_code == 0 {
            validation_result true $"Network connectivity OK"
        } else {
            validation_result false $"Network timeout"
        }
    } catch {
        validation_result false "Network check failed"
    }
}

# Validation result record
export def validation_result [success: bool, message: string, details: record = {}] {
    {
        success: $success,
        message: $message,
        timestamp: (date now),
        details: $details
    }
}

# Command existence validator
export def validate_command [cmd: string] {
    |input|
    # Input type validation
    if ($cmd | is-empty) {
        error "Command name cannot be empty" --context "validator"
        return (validation_result false "Command name cannot be empty")
    }
    if ($cmd | describe) != "string" {
        error $"Command name must be a string, got ($cmd | describe)" --context "validator"
        return (validation_result false $"Command name must be a string, got ($cmd | describe)")
    }
    if ($cmd | str contains " ") {
        error "Command name cannot contain spaces" --context "validator"
        return (validation_result false "Command name cannot contain spaces")
    }
    if ($cmd | str length) > 255 {
        error "Command name too long (max 255 characters)" --context "validator"
        return (validation_result false "Command name too long (max 255 characters)")
    }
    
    let exists = (which $cmd | is-not-empty)
    if $exists {
        debug $"Command '($cmd)' is available" --context "validator"
        validation_result true $"Command ($cmd) found"
    } else {
        error $"Required command '($cmd)' not found" --context "validator"
        validation_result false $"Command ($cmd) missing"
    }
}

# File existence validator
export def validate_file [path: string, --required = true] {
    |input|
    # Input type validation
    if ($path | is-empty) {
        let msg = "File path cannot be empty"
        if $required {
            error $msg --context "validator"
        }
        return (validation_result false $msg)
    }
    if ($path | describe) != "string" {
        let msg = $"File path must be a string, got ($path | describe)"
        if $required {
            error $msg --context "validator"
        }
        return (validation_result false $msg)
    }
    if ($path | str length) > 4096 {
        let msg = "File path too long (max 4096 characters)"
        if $required {
            error $msg --context "validator"
        }
        return (validation_result false $msg)
    }
    
    let exists = ($path | path exists)
    if $exists {
        debug $"File '($path)' exists" --context "validator"
        validation_result true $"File ($path) found"
    } else if $required {
        error $"Required file '($path)' not found" --context "validator"
        validation_result false $"File ($path) missing"
    } else {
        warn $"Optional file '($path)' not found" --context "validator"
        validation_result true $"Optional file ($path) missing (OK)"
    }
}

# Directory existence validator
export def validate_directory [path: string] {
    |input|
    # Input type validation
    if ($path | is-empty) {
        error "Directory path cannot be empty" --context "validator"
        return (validation_result false "Directory path cannot be empty")
    }
    if ($path | describe) != "string" {
        error $"Directory path must be a string, got ($path | describe)" --context "validator"
        return (validation_result false $"Directory path must be a string, got ($path | describe)")
    }
    if ($path | str length) > 4096 {
        error "Directory path too long (max 4096 characters)" --context "validator"
        return (validation_result false "Directory path too long (max 4096 characters)")
    }
    
    let exists = ($path | path exists) and (($path | path type) == "dir")
    if $exists {
        debug $"Directory '($path)' exists" --context "validator"
        validation_result true $"Directory ($path) found"
    } else {
        error $"Required directory '($path)' not found" --context "validator"
        validation_result false $"Directory ($path) missing"
    }
}

# Disk space validator
export def validate_disk_space [threshold: int = 80] {
    |input|
    # Input type validation
    if ($threshold | describe) != "int" {
        error $"Threshold must be an integer, got ($threshold | describe)" --context "validator"
        return (validation_result false $"Threshold must be an integer, got ($threshold | describe)")
    }
    if $threshold < 1 or $threshold > 100 {
        error "Threshold must be between 1 and 100" --context "validator"
        return (validation_result false "Threshold must be between 1 and 100")
    }
    
    try {
        let df_output = (^df -h / | lines | skip 1 | get 0 | split row -r '\s+')
        let usage = ($df_output | get 4 | str replace "%" "" | into int)
        if $usage < $threshold {
            let usage_msg = $"Disk usage ($usage)% is below threshold ($threshold)%"
            success $usage_msg --context "validator"
            validation_result true $"Disk space OK: ($usage)%"
        } else {
            let usage_msg = $"Disk usage ($usage)% exceeds threshold ($threshold)%"
            warn $usage_msg --context "validator"
            validation_result false $"Disk space critical: ($usage)%"
        }
    } catch { |err|
        error $"Failed to check disk space: ($err.msg)" --context "validator"
        validation_result false "Disk space check failed"
    }
}

# Memory usage validator
export def validate_memory [threshold: int = 80] {
    |input|
    # Input type validation
    if ($threshold | describe) != "int" {
        error $"Threshold must be an integer, got ($threshold | describe)" --context "validator"
        return (validation_result false $"Threshold must be an integer, got ($threshold | describe)")
    }
    if $threshold < 1 or $threshold > 100 {
        error "Threshold must be between 1 and 100" --context "validator"
        return (validation_result false "Threshold must be between 1 and 100")
    }
    
    try {
        let mem_info = (sys mem)
        let usage_percent = (($mem_info.used / $mem_info.total) * 100 | math round)
        
        if $usage_percent < $threshold {
            let mem_msg = $"Memory usage ($usage_percent)% is below threshold ($threshold)%"
            success $mem_msg --context "validator"
            validation_result true $"Memory usage OK: ($usage_percent)%"
        } else {
            let mem_msg = $"Memory usage ($usage_percent)% exceeds threshold ($threshold)%"
            warn $mem_msg --context "validator" 
            validation_result false $"Memory usage high: ($usage_percent)%"
        }
    } catch { |err|
        error $"Failed to check memory: ($err.msg)" --context "validator"
        validation_result false "Memory check failed"
    }
}

# Network connectivity validator
export def validate_network [host: string = "8.8.8.8"] {
    |input|
    # Input type validation
    if ($host | is-empty) {
        error "Host cannot be empty" --context "validator"
        return (validation_result false "Host cannot be empty")
    }
    if ($host | describe) != "string" {
        error $"Host must be a string, got ($host | describe)" --context "validator"
        return (validation_result false $"Host must be a string, got ($host | describe)")
    }
    if ($host | str length) > 253 {
        error "Host name too long (max 253 characters)" --context "validator"
        return (validation_result false "Host name too long (max 253 characters)")
    }
    
    try {
        let result = (ping -c 1 -W 5 $host | complete)
        if $result.exit_code == 0 {
            success $"Network connectivity to ($host) OK" --context "validator"
            validation_result true $"Network connectivity OK"
        } else {
            error $"Network connectivity to ($host) failed" --context "validator"
            validation_result false $"Network connectivity failed"
        }
    } catch { |err|
        error $"Network check failed: ($err.msg)" --context "validator"
        validation_result false "Network check error"
    }
}

# Nix store validator
export def validate_nix_store [] {
    |input|
    try {
        let result = (nix --extra-experimental-features "nix-command" store ping | complete)
        if $result.exit_code == 0 {
            success "Nix store is accessible" --context "validator"
            validation_result true "Nix store OK"
        } else {
            error "Nix store is not accessible" --context "validator"
            validation_result false "Nix store inaccessible"
        }
    } catch { |err|
        error $"Nix store check failed: ($err.msg)" --context "validator"
        validation_result false "Nix store check error"
    }
}

# Flake syntax validator
export def validate_flake_syntax [flake_path: string = "."] {
    |input|
    # Input type validation
    if ($flake_path | is-empty) {
        error "Flake path cannot be empty" --context "validator"
        return (validation_result false "Flake path cannot be empty")
    }
    if ($flake_path | describe) != "string" {
        error $"Flake path must be a string, got ($flake_path | describe)" --context "validator"
        return (validation_result false $"Flake path must be a string, got ($flake_path | describe)")
    }
    if ($flake_path | str length) > 4096 {
        error "Flake path too long (max 4096 characters)" --context "validator"
        return (validation_result false "Flake path too long (max 4096 characters)")
    }
    
    try {
        let result = (nix --extra-experimental-features "nix-command flakes" flake check --no-build $flake_path | complete)
        if $result.exit_code == 0 {
            success $"Flake syntax valid in ($flake_path)" --context "validator"
            validation_result true "Flake syntax OK"
        } else {
            error $"Flake syntax invalid in ($flake_path): ($result.stderr)" --context "validator"
            validation_result false $"Flake syntax error: ($result.stderr)"
        }
    } catch { |err|
        error $"Flake syntax check failed: ($err.msg)" --context "validator"
        validation_result false "Flake syntax check error"
    }
}

# Platform validator
export def validate_platform [expected_platforms: list<string>] {
    |input|
    # Input type validation
    if ($expected_platforms | describe) != "list<string>" {
        error $"Expected platforms must be a list of strings, got ($expected_platforms | describe)" --context "validator"
        return (validation_result false $"Expected platforms must be a list of strings, got ($expected_platforms | describe)")
    }
    if ($expected_platforms | is-empty) {
        error "Expected platforms list cannot be empty" --context "validator"
        return (validation_result false "Expected platforms list cannot be empty")
    }
    
    let platform_info = (get_platform)
    let platform_name = $platform_info.normalized
    
    if $platform_name in $expected_platforms {
        success $"Platform ($platform_name) is supported" --context "validator"
        validation_result true $"Platform OK: ($platform_name)"
    } else {
        error $"Platform ($platform_name) not in supported list: ($expected_platforms)" --context "validator"
        validation_result false $"Unsupported platform: ($platform_name)"
    }
}

# Root privileges validator
export def validate_root_required [] {
    |input|
    let current_user = (whoami | str trim)
    if $current_user == "root" {
        success "Running with required root privileges" --context "validator"
        validation_result true "Root privileges OK"
    } else {
        error "Root privileges required but not running as root" --context "validator"
        validation_result false "Root privileges missing"
    }
}

# Environment variable validator
export def validate_env_var [var_name: string, --required = true] {
    |input|
    # Input type validation
    if ($var_name | is-empty) {
        let msg = "Environment variable name cannot be empty"
        if $required {
            error $msg --context "validator"
        }
        return (validation_result false $msg)
    }
    if ($var_name | describe) != "string" {
        let msg = $"Environment variable name must be a string, got ($var_name | describe)"
        if $required {
            error $msg --context "validator"
        }
        return (validation_result false $msg)
    }
    if ($var_name | str contains " ") {
        let msg = "Environment variable name cannot contain spaces"
        if $required {
            error $msg --context "validator"
        }
        return (validation_result false $msg)
    }
    if ($var_name | str length) > 255 {
        let msg = "Environment variable name too long (max 255 characters)"
        if $required {
            error $msg --context "validator"
        }
        return (validation_result false $msg)
    }
    
    let value = try { $env | get $var_name } catch { null }
    if ($value | is-not-empty) {
        success $"Environment variable ($var_name) is set" --context "validator"
        validation_result true $"Environment variable ($var_name) OK"
    } else if $required {
        error $"Required environment variable ($var_name) is not set" --context "validator"
        validation_result false $"Environment variable ($var_name) missing"
    } else {
        warn $"Optional environment variable ($var_name) is not set" --context "validator"
        validation_result true $"Optional environment variable ($var_name) missing (OK)"
    }
}

# Batch validation runner
export def run_validations [
    validations: list<record>,
    --fail-fast = false,
    --context: string = "validation"
] {
    # Input type validation
    if ($validations | describe) != "list<record>" {
        error $"Validations must be a list of records, got ($validations | describe)" --context $context
        return {success: false, error: "Invalid input type for validations"}
    }
    if ($validations | is-empty) {
        warn "No validations provided" --context $context
        return {success: true, total: 0, passed: 0, failed: 0, results: []}
    }
    if ($context | describe) != "string" {
        error $"Context must be a string, got ($context | describe)" --context "validation"
        return {success: false, error: "Invalid input type for context"}
    }
    
    info $"Running ($validations | length) validations..." --context $context
    
    let results = ($validations | each { |validation|
        try {
            let validator = ($validation.validator)
            let result = (null | do $validator)
            # Add name from validation to result
            $result | merge {name: $validation.name}
        } catch { |err|
            {
                success: false,
                message: $"Validation error: ($err.msg)",
                name: $validation.name
            }
        }
    })
    
    let all_success = ($results | all { |result| $result.success })
    
    let summary = {
        success: $all_success,
        total: ($validations | length),
        passed: ($results | where success == true | length),
        failed: ($results | where success == false | length),
        results: $results
    }
    
    if $all_success {
        let passed = $summary.passed
        let total = $summary.total
        let summary_msg = "All validations passed (" + ($passed | into string) + "/" + ($total | into string) + ")"
        success $summary_msg --context $context
    } else {
        let failed = $summary.failed
        let total = $summary.total  
        let failure_msg = "Validation failures: " + ($failed | into string) + "/" + ($total | into string) + " failed"
        error $failure_msg --context $context
    }
    
    $summary
}

# Input type validation helper for common patterns
export def validate_string_input [value: any, name: string, --max-length: int = 4096, --allow-empty = false] {
    if not $allow_empty and ($value | is-empty) {
        return (validation_result false $"($name) cannot be empty")
    }
    if ($value | describe) != "string" {
        return (validation_result false $"($name) must be a string, got ($value | describe)")
    }
    if ($value | str length) > $max_length {
        return (validation_result false $"($name) too long (max ($max_length) characters)")
    }
    validation_result true $"($name) input validation passed"
}

export def validate_integer_input [value: any, name: string, --min: int = 0, --max: int = 2147483647] {
    if ($value | describe) != "int" {
        return (validation_result false $"($name) must be an integer, got ($value | describe)")
    }
    if $value < $min or $value > $max {
        return (validation_result false $"($name) must be between ($min) and ($max)")
    }
    validation_result true $"($name) input validation passed"
}

# ──────────────────────────────────────────────────────────
# ENHANCED VALIDATORS WITH ERROR HANDLING
# ──────────────────────────────────────────────────────────

# Enhanced command validator with comprehensive error handling
export def validate_command_enhanced [cmd: string] {
    let result = (safe_command_exec "which" [$cmd])
    if ($result.stdout | str trim | is-not-empty) {
        {
            command: $cmd,
            path: ($result.stdout | str trim),
            available: true
        }
    } else {
        error $"Command not found: ($cmd)"
        {
            command: $cmd,
            path: "",
            available: false
        }
    }
}

# Enhanced file validator with detailed error reporting
export def validate_file_enhanced [
    path: string,
    --required = true,
    --must_be_readable = false,
    --must_be_writable = false,
    --max_size_mb: int = 1024
] {
    let validation_chain = validate_path $path $required true false
    
    if (is_error $validation_chain) {
        return $validation_chain
    }
    
    let additional_checks = []
    
    if $must_be_readable {
        let additional_checks = ($additional_checks | append {|| validate_permissions $path ["read"]})
    }
    
    if $must_be_writable {
        let parent_dir = ($path | path dirname)
        let additional_checks = ($additional_checks | append {|| validate_permissions $parent_dir ["write"]})
    }
    
    if ($path | path exists) {
        let additional_checks = ($additional_checks | append {||
            try {
                let size_bytes = (ls $path | get size | first)
                let size_mb = ($size_bytes / 1024 / 1024)
                
                if ($size_mb <= $max_size_mb) {
                    validation_result true $"File size OK: ($size_mb)MB"
                } else {
                    validation_result false $"File too large: ($size_mb)MB, max allowed ($max_size_mb)MB"
                }
            } catch { |err|
                create_error $"Failed to check file size: ($err.msg)" "filesystem" "LOW" "E_SIZE_CHECK_FAILED" {path: $path}
            }
        })
    }
    
    if ($additional_checks | is-not-empty) {
        validate_all $additional_checks
    } else {
        create_success $"File validation passed: ($path)" {path: $path}
    }
}

# Enhanced directory validator with space checks
export def validate_directory_enhanced [
    path: string,
    --must_be_writable = false,
    --min_space_mb: int = 100
] {
    let path_result = (validate_path $path true false true)
    if (is_success $path_result) {
        mut validations = []
        
        if $must_be_writable {
            $validations = ($validations | append {|| validate_permissions $path ["write"]})
        }
        
        if $min_space_mb > 0 {
            $validations = ($validations | append {||
                try {
                    let df_result = (^df $path | lines | skip 1 | get 0 | split row -r '\s+')
                    let available_kb = ($df_result | get 3 | into int)
                    let available_mb = $available_kb / 1024
                    
                    if ($available_mb >= $min_space_mb) {
                        validation_result true $"Directory has sufficient space: ($available_mb)MB available"
                    } else {
                        validation_result false $"Directory has insufficient space: ($available_mb)MB available, need ($min_space_mb)MB"
                    }
                } catch { |err|
                    validation_result false $"Failed to check directory space: ($err.msg)"
                }
            })
        }
        
        if ($validations | is-not-empty) {
            # Run the validations and return first result for now
            let first_validation = ($validations | first)
            do $first_validation
        } else {
            validation_result true $"Directory validation passed: ($path)"
        }
    } else {
        $path_result
    }
}

# Enhanced network validator with retry and circuit breaker
export def validate_network_enhanced [
    host: string,
    --timeout: int = 5,
    --retry_attempts: int = 3,
    --use_circuit_breaker = true
] {
    let network_check = {||
        safe_network_check $host $timeout
    }
    
    if $use_circuit_breaker {
        with_circuit_breaker $network_check 3 60sec $"network_($host)"
    } else {
        retry_with_backoff $network_check $retry_attempts 1sec 10sec 2.0
    }
}

# Enhanced system resource validator
export def validate_system_enhanced [
    --min_disk_gb: int = 1,
    --min_memory_gb: int = 1,
    --max_cpu_percent: int = 90,
    --max_load_average: float = 5.0
] {
    let resource_result = (validate_system_resources ($min_disk_gb * 1024) ($min_memory_gb * 1024) $max_cpu_percent)
    if (is_success $resource_result) {
        try {
            let load_avg = (sys host | get load_average | first)
            if ($load_avg <= $max_load_average) {
                validation_result true $"System load acceptable: ($load_avg)"
            } else {
                validation_result false $"System load too high: ($load_avg), max allowed ($max_load_average)"
            }
        } catch { |err|
            validation_result false $"Failed to check system load: ($err.msg)"
        }
    } else {
        $resource_result
    }
}

# Batch validator with enhanced error reporting
export def run_validations_enhanced [
    validations: list<record>,
    --fail_fast = false,
    --context: string = "validation",
    --retry_failed = false,
    --max_retries: int = 2
] {
    # Input validation with enhanced error handling
    let input_validation = if (($validations | describe) == "list<record>") {
        validation_result true "Validations input is valid"
    } else {
        validation_result false $"Validations must be a list of records, got ($validations | describe)"
    }
    
    if (not $input_validation.success) {
        error $input_validation.message --context $context
        return $input_validation
    }
    
    if ($validations | is-empty) {
        return (validation_result true "No validations to run" {
            total: 0,
            passed: 0,
            failed: 0,
            results: []
        })
    }
    
    info $"Running ($validations | length) enhanced validations..." --context $context
    
    let results = ($validations | each { |validation|
        let validator_name = ($validation | get name? | default "unnamed")
        let validator_func = ($validation | get validator? | default null)
        
        if ($validator_func == null) {
            create_error $"No validator function provided for ($validator_name)" "validation" "HIGH" "E_NO_VALIDATOR" {name: $validator_name}
        } else {
            let run_validator = {||
                try {
                    let result = (null | do $validator_func)
                    
                    # Convert old-style validation results to new error handling format
                    if ($result | get success? | default false) {
                        create_success ($result | get message? | default "Validation passed") $result
                    } else {
                        create_error ($result | get message? | default "Validation failed") "validation" "MEDIUM" "E_VALIDATION_FAILED" {
                            validator: $validator_name,
                            result: $result
                        }
                    }
                } catch { |err|
                    create_error $"Validator ($validator_name) threw exception: ($err.msg)" "validation" "HIGH" "E_VALIDATOR_EXCEPTION" {
                        validator: $validator_name,
                        error: $err.msg
                    }
                }
            }
            
            let final_result = if $retry_failed {
                retry_with_backoff $run_validator $max_retries 1sec 5sec 1.5
            } else {
                do $run_validator
            }
            
            # Add validator name to result
            if (is_success $final_result) {
                $final_result | merge {validator_name: $validator_name}
            } else {
                let error_data = ($final_result | get error)
                let enhanced_error = ($error_data | merge {validator_name: $validator_name})
                $final_result | merge {error: $enhanced_error}
            }
        }
    })
    
    let successes = ($results | where {|r| is_success $r})
    let failures = ($results | where {|r| is_error $r})
    let passed_count = ($successes | length)
    let failed_count = ($failures | length)
    let total_count = ($results | length)
    
    # Log all errors
    $failures | each {|failure| log_error $failure $context}
    
    let summary = {
        total: $total_count,
        passed: $passed_count,
        failed: $failed_count,
        success_rate: (($passed_count * 100.0) / ($total_count * 1.0) | math round --precision 2),
        results: $results
    }
    
    if ($failed_count == 0) {
        success $"All ($total_count) enhanced validations passed!" --context $context
        validation_result true "All validations passed" $summary
    } else {
        let failure_summary = ($failures | each {|f| 
            $"($f.message? | default 'validation failed')"
        } | str join "; ")
        
        error $"($failed_count) of ($total_count) validations failed" --context $context
        validation_result false $"Validation batch failed: ($failure_summary)" $summary
    }
}

# Predefined validation suites
export def basic_system_validations [] {
    [
        { name: "nix", validator: {|| validate_command "nix" } },
        { name: "git", validator: {|| validate_command "git" } },
        { name: "disk_space", validator: {|| validate_disk_space 80 } },
        { name: "memory", validator: {|| validate_memory 80 } }
    ]
}

export def nix_environment_validations [] {
    [
        { name: "nix_command", validator: {|| validate_command "nix" } },
        { name: "flake_file", validator: {|| validate_file "flake.nix" } },
        { name: "nix_store", validator: {|| validate_nix_store } },
        { name: "flake_syntax", validator: {|| validate_flake_syntax } }
    ]
}

export def gaming_setup_validations [] {
    [
        { name: "steam", validator: {|| optional_validator {|| validate_command_quiet "steam" } } },
        { name: "lutris", validator: {|| optional_validator {|| validate_command_quiet "lutris" } } },
        { name: "gamemode", validator: {|| optional_validator {|| validate_command_quiet "gamemoderun" } } },
        { name: "gaming_dir", validator: {|| optional_validator {|| validate_directory_quiet "flakes/gaming" } } }
    ]
}

# Additional validators with enhanced input validation

# Port validator
export def validate_port [port: int] {
    |input|
    # Input type validation
    if ($port | describe) != "int" {
        error $"Port must be an integer, got ($port | describe)" --context "validator"
        return (validation_result false $"Port must be an integer, got ($port | describe)")
    }
    if $port < 1 or $port > 65535 {
        error "Port must be between 1 and 65535" --context "validator"
        return (validation_result false "Port must be between 1 and 65535")
    }
    
    validation_result true $"Port ($port) is valid"
}

# URL validator
export def validate_url [url: string] {
    |input|
    # Input type validation
    if ($url | is-empty) {
        error "URL cannot be empty" --context "validator"
        return (validation_result false "URL cannot be empty")
    }
    if ($url | describe) != "string" {
        error $"URL must be a string, got ($url | describe)" --context "validator"
        return (validation_result false $"URL must be a string, got ($url | describe)")
    }
    if ($url | str length) > 2048 {
        error "URL too long (max 2048 characters)" --context "validator"
        return (validation_result false "URL too long (max 2048 characters)")
    }
    if not (($url | str starts-with "http://") or ($url | str starts-with "https://") or ($url | str starts-with "ftp://")) {
        error "URL must start with http://, https://, or ftp://" --context "validator"
        return (validation_result false "URL must start with http://, https://, or ftp://")
    }
    
    validation_result true $"URL ($url) is valid"
}

# Permission validator
export def validate_permission [path: string, permission: string] {
    |input|
    # Input type validation
    if ($path | is-empty) {
        error "Path cannot be empty" --context "validator"
        return (validation_result false "Path cannot be empty")
    }
    if ($path | describe) != "string" {
        error $"Path must be a string, got ($path | describe)" --context "validator"
        return (validation_result false $"Path must be a string, got ($path | describe)")
    }
    if ($permission | is-empty) {
        error "Permission cannot be empty" --context "validator"
        return (validation_result false "Permission cannot be empty")
    }
    if ($permission | describe) != "string" {
        error $"Permission must be a string, got ($permission | describe)" --context "validator"
        return (validation_result false $"Permission must be a string, got ($permission | describe)")
    }
    if not ($permission in ["read", "write", "execute"]) {
        error "Permission must be one of: read, write, execute" --context "validator"
        return (validation_result false "Permission must be one of: read, write, execute")
    }
    
    try {
        match $permission {
            "read" => {
                let readable = ($path | path exists)
                if $readable {
                    validation_result true $"($path) is readable"
                } else {
                    validation_result false $"($path) is not readable or does not exist"
                }
            }
            "write" => {
                # Test write permission by trying to create a temporary file
                let test_file = ($path | path join ".permission_test")
                try {
                    "test" | save --force $test_file
                    rm -f $test_file
                    validation_result true $"($path) is writable"
                } catch {
                    validation_result false $"($path) is not writable"
                }
            }
            "execute" => {
                let executable = ($path | path exists)
                if $executable {
                    validation_result true $"($path) is executable"
                } else {
                    validation_result false $"($path) is not executable or does not exist"
                }
            }
        }
    } catch { |err|
        error $"Failed to check permission: ($err.msg)" --context "validator"
        validation_result false "Permission check failed"
    }
}

# Compose validators function
export def compose_validators [validators: list<closure>] {
    # Input type validation
    if ($validators | describe) != "list<closure>" {
        error $"Validators must be a list of closures, got ($validators | describe)" --context "validator"
        return {|| validation_result false "Invalid validator composition"}
    }
    if ($validators | is-empty) {
        warn "Empty validator list provided" --context "validator"
        return {|| validation_result true "No validators to run"}
    }
    
    {|input|
        let results = ($validators | each { |validator|
            $input | do $validator
        })
        
        let all_success = ($results | all { |result| $result.success })
        let failed_results = ($results | where success == false)
        
        if $all_success {
            validation_result true "All composed validators passed"
        } else {
            let first_failure = ($failed_results | first)
            validation_result false $"Composed validation failed: ($first_failure.message)"
        }
    }
}