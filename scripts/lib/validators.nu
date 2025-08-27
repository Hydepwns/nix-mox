#!/usr/bin/env nu
# Functional validation pipeline for nix-mox
# Consolidates validation logic using functional composition
# Replaces scattered validation patterns across scripts

use logging.nu *
use platform.nu *

# Core validation pipeline function
export def validate_pipeline [...validators: closure] {
    |input|
    $validators | reduce --fold $input { |validator, acc|
        $acc | do $validator
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
        let result = (nix store ping | complete)
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
    try {
        let result = (nix flake check --no-build $flake_path | complete)
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
        { name: "steam", validator: {|| try { validate_command "steam" } catch { validation_result false "Steam not found (optional)" } } },
        { name: "lutris", validator: {|| try { validate_command "lutris" } catch { validation_result false "Lutris not found (optional)" } } },
        { name: "gamemode", validator: {|| try { validate_command "gamemoderun" } catch { validation_result false "GameMode not found (optional)" } } },
        { name: "gaming_dir", validator: {|| try { validate_directory "flakes/gaming" } catch { validation_result false "Gaming directory not found (optional)" } } }
    ]
}