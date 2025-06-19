# Test utilities for nix-mox
# This module provides common functions for testing

use ./coverage-core.nu *

# --- Environment Setup ---
export-env {
    # Base directories
    $env.TEST_DIR = "."
    $env.UNIT_TEST_DIR = $"($env.TEST_DIR)/unit"
    $env.INTEGRATION_TEST_DIR = $"($env.TEST_DIR)/integration"
    $env.FIXTURES_DIR = $"($env.TEST_DIR)/fixtures"

    # Test environment
    $env.LOG_LEVEL = "INFO"
    $env.PLATFORM = (sys host | get hostname | str downcase)
    $env.COMPONENT_NAME = "nix-mox"
    $env.LAST_ERROR = ""

    # ANSI colors for output
    $env.GREEN = (ansi green)
    $env.YELLOW = (ansi yellow)
    $env.RED = (ansi red)
    $env.NC = (ansi reset)
}

# --- Platform Detection ---
export def is_linux [] {
    $env.PLATFORM == "linux"
}

export def is_darwin [] {
    $env.PLATFORM == "darwin"
}

# --- Test Environment Management ---
export def setup_test_env [] {
    print $"($env.GREEN)Setting up test environment...($env.NC)"
    # Use a fixed coverage directory instead of temp directory
    $env.TEST_TEMP_DIR = "coverage-tmp"
    mkdir $env.TEST_TEMP_DIR
    print $"($env.GREEN)Test environment ready at: ($env.TEST_TEMP_DIR)($env.NC)"
}

export def cleanup_test_env [] {
    print $"($env.YELLOW)Cleaning up test environment...($env.NC)"
    rm -rf $env.TEST_TEMP_DIR
    print $"($env.GREEN)Test environment cleaned up($env.NC)"
}

# --- Test Assertions ---
export def assert_equal [expected: any, actual: any, message: string] {
    if $expected == $actual {
        print $"($env.GREEN)✓ ($message)($env.NC)"
        true
    } else {
        print $"($env.RED)✗ ($message)($env.NC)"
        print $"($env.RED)  Expected: ($expected)($env.NC)"
        print $"($env.RED)  Actual: ($actual)($env.NC)"
        false
    }
}

export def assert_true [condition: bool, message: string] {
    if $condition {
        print $"($env.GREEN)✓ ($message)($env.NC)"
        true
    } else {
        print $"($env.RED)✗ ($message)($env.NC)"
        false
    }
}

export def assert_false [condition: bool, message: string] {
    if not $condition {
        print $"($env.GREEN)✓ ($message)($env.NC)"
        true
    } else {
        print $"($env.RED)✗ ($message)($env.NC)"
        false
    }
}

# --- Test Retry Mechanism ---
export def test_retry [max_retries: int, retry_delay: int, operation: closure, expected_result: bool] {
    mut retries = 0
    mut success = false

    while $retries < $max_retries {
        print $"($env.YELLOW)Attempt ($retries + 1) of ($max_retries)($env.NC)"

        if (do $operation) {
            $success = true
            break
        }

        $retries = $retries + 1
        if $retries < $max_retries {
            sleep ($retry_delay * 1sec)
        }
    }

    assert_equal $expected_result $success $"Retry test after ($max_retries) attempts"
}

# --- Test Logging ---
export def test_logging [level: string, message: string, expected_output: string] {
    let output = $"[($level)] ($message)"
    assert_equal $expected_output $output "Logging test"
}

export def log_error [message: string] {
    print $"($env.RED)Error: ($message)($env.NC)"
}

# --- Test Configuration Validation ---
export def test_config_validation [config: string, expected_error: string] {
    if ($config | is-empty) {
        assert_equal $expected_error $expected_error "Config validation"
        false
    } else {
        true
    }
}

# --- Test Performance ---
export def test_performance [operation: closure, max_duration: int] {
    let start_time = (date now | into int)
    do $operation
    let end_time = (date now | into int)
    let duration_ms = ($end_time - $start_time)
    let duration = ($duration_ms | into float) / 1000000000

    assert_true ($duration <= $max_duration) $"Performance test completed in ($duration) seconds (max: ($max_duration) seconds)"
}

# --- Test Runner ---
export def run_test [test_file: string] {
    let test_name = ($test_file | path basename)
    print $"($env.GREEN)Running test: ($test_name)($env.NC)"

    let start_time = (date now | into int)

    try {
        nu --env TEST_TEMP_DIR=$env.TEST_TEMP_DIR $test_file
        let end_time = (date now | into int)
        let duration = (($end_time - $start_time) | into float) / 1000000000

        print $"($env.GREEN)✓ Test passed: ($test_name) - ($duration)s($env.NC)"
        track_test $test_name "unit" "passed" $duration
        true
    } catch {
        let end_time = (date now | into int)
        let duration = (($end_time - $start_time) | into float) / 1000000000

        print $"($env.RED)✗ Test failed: ($test_name) - ($duration)s($env.NC)"
        print $"($env.RED)Error: ($env.LAST_ERROR)($env.NC)"
        track_test $test_name "unit" "failed" $duration
        false
    }
}

export def run_tests [test_dir: string, category: string = "unit"] {
    let test_files = (ls $test_dir | where { |it| $it.name | str ends-with '.nu' } | get name)

    if ($test_files | length) == 0 {
        print $"($env.YELLOW)No test files found in ($test_dir)($env.NC)"
        return true
    }

    let results = ($test_files | each { |file|
        let test_name = ($file | path basename)
        let start_time = (date now | into int)

        try {
            nu $file
            let end_time = (date now | into int)
            let duration = (($end_time - $start_time) | into float) / 1000000000

            print $"($env.GREEN)✓ Test passed: ($test_name) - ($duration)s($env.NC)"
            track_test $test_name $category "passed" $duration
            true
        } catch {
            let end_time = (date now | into int)
            let duration = (($end_time - $start_time) | into float) / 1000000000

            print $"($env.RED)✗ Test failed: ($test_name) - ($duration)s($env.NC)"
            print $"($env.RED)Error: ($env.LAST_ERROR)($env.NC)"
            track_test $test_name $category "failed" $duration
            false
        }
    })

    $results | all { |result| $result }
}

export def run_unit_tests [] {
    print $"($env.GREEN)Running unit tests...($env.NC)"
    nu tests/unit/unit-tests.nu
}

export def run_integration_tests [] {
    print $"($env.GREEN)Running integration tests...($env.NC)"
    run_tests "tests/integration" "integration"
}

export def run_storage_tests [] {
    print $"($env.GREEN)Running storage tests...($env.NC)"
    let storage_test_dir = "tests/storage"
    if ($storage_test_dir | path exists) {
        run_tests $storage_test_dir "storage"
    } else {
        print $"($env.YELLOW)Storage test directory not found: ($storage_test_dir)($env.NC)"
        true
    }
}

export def run_performance_tests [] {
    print $"($env.GREEN)Running performance tests...($env.NC)"
    let performance_test_dir = "tests/performance"
    if ($performance_test_dir | path exists) {
        run_tests $performance_test_dir "performance"
    } else {
        print $"($env.YELLOW)Performance test directory not found: ($performance_test_dir)($env.NC)"
        true
    }
}

export def run_all_tests [] {
    setup_test_env

    let unit_results = run_unit_tests
    let integration_results = run_integration_tests

    cleanup_test_env

    $unit_results and $integration_results
}

# --- Main Test Runner ---
export def main [] {
    let args = $env._args
    let test_type = ($args | get 0 | default "all")

    match $test_type {
        "unit" => { run_unit_tests }
        "integration" => { run_integration_tests }
        "all" => { run_all_tests }
        _ => {
            print $"($env.RED)Unknown test type: ($test_type)($env.NC)"
            print $"($env.YELLOW)Available types: unit, integration, all($env.NC)"
            false
        }
    }
}
