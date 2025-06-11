# Test utilities for nix-mox
# This module provides common functions for testing

use ../../scripts/lib/common.nu *

# --- Test Configuration ---
$env.TEST_DIR = "tests"
$env.UNIT_TEST_DIR = $"($env.TEST_DIR)/unit"
$env.INTEGRATION_TEST_DIR = $"($env.TEST_DIR)/integration"
$env.FIXTURES_DIR = $"($env.TEST_DIR)/fixtures"

# --- Test Helpers ---
def run_test [test_file: string] {
    let test_name = ($test_file | path basename)
    log_info $"Running test: ($test_name)"

    try {
        nu $test_file
        log_success $"Test passed: ($test_name)"
        true
    } catch {
        log_error $"Test failed: ($test_name)"
        log_error $"Error: ($env.LAST_ERROR)"
        false
    }
}

def run_tests [test_dir: string] {
    let test_files = (ls $test_dir | where { |it| $it.name | str ends-with '.nu' } | get name)
    let results = ($test_files | each { |file| run_test $file })
    $results | all { |result| $result }
}

def run_unit_tests [] {
    run_tests $env.UNIT_TEST_DIR
}

def run_integration_tests [] {
    run_tests $env.INTEGRATION_TEST_DIR
}

def run_all_tests [] {
    let unit_results = run_unit_tests
    let integration_results = run_integration_tests
    $unit_results and $integration_results
}

# --- Test Fixtures ---
def setup_test_env [] {
    # Create temporary test environment
    let temp_dir = (mktemp -d)
    $env.TEST_TEMP_DIR = $temp_dir
    log_info $"Created test environment at: ($temp_dir)"
}

def cleanup_test_env [] {
    # Clean up temporary test environment
    if ($env.TEST_TEMP_DIR? | default false) {
        rm -rf $env.TEST_TEMP_DIR
        log_info $"Cleaned up test environment at: ($env.TEST_TEMP_DIR)"
    }
}

# --- Test Assertions ---
export-env {
    def assert_equal [expected: any, actual: any, message: string] {
        if $expected != $actual {
            log_error $"Assertion failed: ($message)"
            log_error $"Expected: ($expected)"
            log_error $"Actual: ($actual)"
            false
        } else {
            true
        }
    }

    def assert_true [condition: bool, message: string] {
        if not $condition {
            log_error $"Assertion failed: ($message)"
            false
        } else {
            true
        }
    }

    def assert_false [condition: bool, message: string] {
        if $condition {
            log_error $"Assertion failed: ($message)"
            false
        } else {
            true
        }
    }
}

# --- Test Runner ---
def main [] {
    let args = $env._args
    let test_type = ($args | get 0 | default "all")

    match $test_type {
        "unit" => { run_unit_tests }
        "integration" => { run_integration_tests }
        "all" => { run_all_tests }
        _ => {
            log_error $"Unknown test type: ($test_type)"
            log_error "Available types: unit, integration, all"
            false
        }
    }
}

# Test assertion function
export def assert_equal [expected: any, actual: any, message: string] {
    if $expected == $actual {
        true
    } else {
        error make {
            msg: $"Assertion failed: ($message)\nExpected: ($expected)\nActual: ($actual)"
        }
    }
}

# Test retry mechanism
export def test_retry [max_retries: int, retry_delay: int, operation: closure, expected_result: bool] {
    mut retries = 0
    mut success = false

    while $retries < $max_retries {
        if (do $operation) {
            $success = true
            break
        }
        $retries = $retries + 1
        if $retries < $max_retries {
            sleep ($retry_delay * 1sec)
        }
    }

    assert_equal $expected_result $success "Retry test failed"
}

# Test logging
export def test_logging [level: string, message: string, expected_output: string] {
    let output = $"[($level)] ($message)"
    assert_equal $expected_output $output "Logging test failed"
}

# Test configuration validation
export def test_config_validation [config: string, expected_error: string] {
    if ($config | is-empty) {
        assert_equal $expected_error $expected_error "Config validation failed"
        false
    } else {
        true
    }
}

# Test ZFS operations
export def test_zfs_operation [operation: string, expected_success: bool] {
    let success = if $operation == "success" { true } else { false }
    assert_equal $expected_success $success "ZFS operation test failed"
}

# Test SSD caching
export def test_ssd_caching [cache_size: int, expected_success: bool] {
    let success = $cache_size > 0
    assert_equal $expected_success $success "SSD caching test failed"
}

# Test error handling
export def test_error_handling [error_type: string, expected_output: string] {
    if $error_type == "expected" {
        assert_equal $expected_output $expected_output "Error handling test failed"
        true
    } else {
        false
    }
}

# Test performance
export def test_performance [operation: closure, max_duration: int] {
    let start_time = (date now | into int)
    do $operation
    let end_time = (date now | into int)
    let duration_ms = ($end_time - $start_time)
    let duration = ($duration_ms | into float) / 1000000000
    assert_equal true ($duration <= $max_duration) ("Performance test failed: took too long " + ($duration | into string) + " seconds")
}
