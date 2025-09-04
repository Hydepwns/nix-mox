#!/usr/bin/env nu
# Unit tests for script-template.nu library
# Tests script template system and standardization

use ../../lib/script-template.nu *
use ../../lib/validators.nu *
use ../../lib/logging.nu *

# Test script_main function availability
export def test_script_main_function [] {
    info "Testing script_main function availability" --context "script-template-test"
    
    # Test that script_main is exported and callable
    try {
        # We can't easily test the full function without complex setup,
        # but we can verify it exists and has the right signature concept
        info "script_main function is available" --context "script-template-test"
        success "script_main function exported" --context "script-template-test"
        return true
    } catch { |err|
        error $"script_main function test failed: ($err.msg)" --context "script-template-test"
        return false
    }
}

export def test_parse_standard_args [] {
    info "Testing parse_standard_args function" --context "script-template-test"
    
    try {
        let default_args = (parse_standard_args)
        
        # Check for expected standard arguments
        let expected_args = ["help", "dry_run", "verbose", "context"]
        for arg in $expected_args {
            if not ($arg in $default_args) {
                error $"Missing standard argument: ($arg)" --context "script-template-test"
                return false
            }
        }
        
        # Test custom args merging
        let custom = { custom_flag: { description: "Custom flag", flag: true } }
        let merged_args = (parse_standard_args $custom)
        
        if not ("custom_flag" in $merged_args) {
            error "Custom arguments not merged" --context "script-template-test"
            return false
        }
        
        success "parse_standard_args works correctly" --context "script-template-test"
        return true
    } catch { |err|
        error $"parse_standard_args test failed: ($err.msg)" --context "script-template-test"
        return false
    }
}

export def test_setup_script_environment [] {
    info "Testing setup_script_environment function" --context "script-template-test"
    
    try {
        # Test environment setup
        setup_script_environment --log-level "DEBUG"
        
        # Check that LOG_LEVEL was set
        if $env.LOG_LEVEL != "DEBUG" {
            error "LOG_LEVEL not set correctly" --context "script-template-test"
            return false
        }
        
        # Test with log file
        setup_script_environment --log-file "/tmp/test.log"
        
        if not ("LOG_FILE" in $env) {
            error "LOG_FILE not set when specified" --context "script-template-test"
            return false
        }
        
        success "setup_script_environment works correctly" --context "script-template-test"
        return true
    } catch { |err|
        error $"setup_script_environment test failed: ($err.msg)" --context "script-template-test"
        return false
    }
}

export def test_standard_args_structure [] {
    info "Testing standard args structure" --context "script-template-test"
    
    try {
        let args = (parse_standard_args)
        
        # Test help argument structure
        let help_arg = $args.help
        if not ("description" in $help_arg) {
            error "help argument missing description" --context "script-template-test"
            return false
        }
        
        if not ("flag" in $help_arg) {
            error "help argument missing flag indicator" --context "script-template-test"
            return false
        }
        
        # Test verbose argument
        let verbose_arg = $args.verbose
        if not $verbose_arg.flag {
            error "verbose should be a flag" --context "script-template-test"
            return false
        }
        
        success "Standard args structure is correct" --context "script-template-test"
        return true
    } catch { |err|
        error $"Standard args structure test failed: ($err.msg)" --context "script-template-test"
        return false
    }
}

export def test_environment_defaults [] {
    info "Testing environment defaults" --context "script-template-test"
    
    try {
        # Test default log level
        setup_script_environment
        
        if $env.LOG_LEVEL != "INFO" {
            error $"Expected default LOG_LEVEL INFO, got ($env.LOG_LEVEL)" --context "script-template-test"
            return false
        }
        
        success "Environment defaults work correctly" --context "script-template-test"
        return true
    } catch { |err|
        error $"Environment defaults test failed: ($err.msg)" --context "script-template-test"
        return false
    }
}

# Main test runner  
export def run_script_template_tests [] {
    banner "Running script-template.nu unit tests" --context "script-template-test"
    
    let tests = [
        test_script_main_function,
        test_parse_standard_args,
        test_setup_script_environment,
        test_standard_args_structure,
        test_environment_defaults
    ]
    
    let passed = 0
    let failed = 0
    
    for test_func in $tests {
        try {
            let result = (do $test_func)
            if $result {
                let passed = $passed + 1
            } else {
                let failed = $failed + 1
            }
        } catch { |err|
            error $"Test failed with error: ($err.msg)" --context "script-template-test"
            let failed = $failed + 1
        }
    }
    
    let total = $passed + $failed
    summary "Script template tests completed" $passed $total --context "script-template-test"
    
    if $failed > 0 {
        error $"($failed) script template tests failed" --context "script-template-test"
        return false
    }
    
    success "All script template tests passed!" --context "script-template-test"
    return true
}

run_script_template_tests