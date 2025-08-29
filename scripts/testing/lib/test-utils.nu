#!/usr/bin/env nu

# Import unified libraries
use ../../lib/validators.nu
use ../../lib/logging.nu *


# Test utilities for nix-mox
# Provides common testing functions and utilities

# --- Environment Setup ---
export def setup_test_env [] {
    # Set up test environment variables
    $env.TEST_TEMP_DIR = ($env | get TEMP? | default "coverage-tmp") + "/nix-mox-tests"
    $env.TEST_LOG_FILE = $env.TEST_TEMP_DIR + "/test.log"

    # Ensure test directory exists
    if not ($env.TEST_TEMP_DIR | path exists) {
        mkdir $env.TEST_TEMP_DIR
    }

    # Set up color codes for output
    $env.GREEN = (ansi green)
    $env.RED = (ansi red)
    $env.YELLOW = (ansi yellow)
    $env.BLUE = (ansi blue)
    $env.NC = (ansi reset)  # No Color
}

# Enhanced test isolation setup
export def setup_isolated_test_env [test_name: string] {
    # Create isolated test directory for this specific test
    let base_temp = ($env | get TEMP? | default "coverage-tmp")
    let test_id = (date now | format date "%Y%m%d_%H%M%S") + "_" + ($test_name | str replace -a " " "_")
    let isolated_dir = $base_temp + "/nix-mox-tests/" + $test_id
    
    if not ($isolated_dir | path exists) {
        mkdir $isolated_dir
    }
    
    # Store original environment state for restoration
    let original_env = {
        TEST_TEMP_DIR: ($env | get TEST_TEMP_DIR? | default null),
        TEST_LOG_FILE: ($env | get TEST_LOG_FILE? | default null),
        PWD: ($env.PWD),
        PATH: ($env.PATH)
    }
    
    # Set isolated environment
    $env.TEST_TEMP_DIR = $isolated_dir
    $env.TEST_LOG_FILE = $isolated_dir + "/test.log"
    $env.TEST_ISOLATED = true
    $env.TEST_ORIGINAL_ENV = ($original_env | to json)
    
    # Set up color codes if not present
    if not ($env | get GREEN?) {
        $env.GREEN = (ansi green)
        $env.RED = (ansi red)
        $env.YELLOW = (ansi yellow)
        $env.BLUE = (ansi blue)
        $env.NC = (ansi reset)
    }
    
    $isolated_dir
}

# Cleanup isolated test environment
export def cleanup_isolated_test_env [] {
    if ($env | get TEST_ISOLATED? | default false) {
        let test_dir = $env.TEST_TEMP_DIR
        
        # Restore original environment
        if ($env | get TEST_ORIGINAL_ENV?) {
            let original_env = ($env.TEST_ORIGINAL_ENV | from json)
            
            if ($original_env.TEST_TEMP_DIR != null) {
                $env.TEST_TEMP_DIR = $original_env.TEST_TEMP_DIR
            } else {
                hide-env TEST_TEMP_DIR
            }
            
            if ($original_env.TEST_LOG_FILE != null) {
                $env.TEST_LOG_FILE = $original_env.TEST_LOG_FILE
            } else {
                hide-env TEST_LOG_FILE
            }
        }
        
        # Remove isolation flags
        hide-env TEST_ISOLATED
        hide-env TEST_ORIGINAL_ENV
        
        # Clean up test directory
        if ($test_dir | path exists) {
            try {
                rm -rf $test_dir
            } catch {
                # If cleanup fails, at least warn about it
                print $"Warning: Could not clean up test directory ($test_dir)"
            }
        }
    }
}

# --- Assertion Functions ---
export def assert_true [condition: bool, message: string = ""] {
    let green = ($env | get GREEN? | default (ansi green))
    let nc = ($env | get NC? | default (ansi reset))

    if $condition {
        print $"($green)✓ PASS: ($message)($nc)"
        true
    } else {
        let red = ($env | get RED? | default (ansi red))
        print $"($red)✗ FAIL: ($message)($nc)"
        false
    }
}

export def assert_false [condition: bool, message: string = ""] {
    assert_true (not $condition) $message
}

export def assert_equal [actual: any, expected: any, message: string = ""] {
    let green = ($env | get GREEN? | default (ansi green))
    let red = ($env | get RED? | default (ansi red))
    let nc = ($env | get NC? | default (ansi reset))

    let result = ($actual == $expected)
    if $result {
        print $"($green)✓ PASS: ($message) - Expected: ($expected), Got: ($actual)($nc)"
        true
    } else {
        print $"($red)✗ FAIL: ($message) - Expected: ($expected), Got: ($actual)($nc)"
        false
    }
}

export def assert_not_equal [actual: any, expected: any, message: string = ""] {
    let green = ($env | get GREEN? | default (ansi green))
    let red = ($env | get RED? | default (ansi red))
    let nc = ($env | get NC? | default (ansi reset))

    let result = ($actual != $expected)
    if $result {
        print $"($green)✓ PASS: ($message) - Values are different as expected($nc)"
        true
    } else {
        print $"($red)✗ FAIL: ($message) - Values are equal: ($actual)($nc)"
        false
    }
}

export def assert_contains [haystack: string, needle: string, message: string = ""] {
    let green = ($env | get GREEN? | default (ansi green))
    let red = ($env | get RED? | default (ansi red))
    let nc = ($env | get NC? | default (ansi reset))

    let result = ($haystack | str contains $needle)
    if $result {
        print $"($green)✓ PASS: ($message) - Found: ($needle)($nc)"
        true
    } else {
        print $"($red)✗ FAIL: ($message) - Not found: ($needle) in ($haystack)($nc)"
        false
    }
}

export def assert_empty [value: any, message: string = ""] {
    let green = ($env | get GREEN? | default (ansi green))
    let red = ($env | get RED? | default (ansi red))
    let nc = ($env | get NC? | default (ansi reset))

    let result = ($value | is-empty)
    if $result {
        print $"($green)✓ PASS: ($message) - Value is empty($nc)"
        true
    } else {
        print $"($red)✗ FAIL: ($message) - Value is not empty: ($value)($nc)"
        false
    }
}

export def assert_not_empty [value: any, message: string = ""] {
    let green = ($env | get GREEN? | default (ansi green))
    let red = ($env | get RED? | default (ansi red))
    let nc = ($env | get NC? | default (ansi reset))

    let result = (not ($value | is-empty))
    if $result {
        print $"($green)✓ PASS: ($message) - Value is not empty($nc)"
        true
    } else {
        print $"($red)✗ FAIL: ($message) - Value is empty($nc)"
        false
    }
}

# --- Performance Testing ---
export def benchmark [name: string, max_duration: float, code: closure] {
    let start_time = (date now | into int)

    try {
        do $code
        let end_time = (date now | into int)
        let duration = (($end_time - $start_time) | into float) / 1000000000

        if ($duration <= $max_duration) {
            print ($env.GREEN + "✓ Performance test passed: " + $name + " - " + ($duration | into string) + "s (max: " + ($max_duration | into string) + "s)" + $env.NC)
            true
        } else {
            print ($env.RED + "✗ Performance test failed: " + $name + " - " + ($duration | into string) + "s (max: " + ($max_duration | into string) + "s)" + $env.NC)
            false
        }
    } catch {
        print $"($env.RED)✗ Performance test error: ($name) - ($env.LAST_ERROR)($env.NC)"
        false
    }
}

# --- Test Tracking ---
export def track_test [name: string, category: string, status: string, duration: float] {
    let test_result = {
        name: $name,
        category: $category,
        status: $status,
        duration: $duration,
        timestamp: (date now | into int)
    }

    # Create the test temp directory if it doesn't exist
    let test_temp_dir = ($env | get TEST_TEMP_DIR? | default "coverage-tmp/nix-mox-tests");
    if not ($test_temp_dir | path exists) {
        mkdir $test_temp_dir
    }

    let filename = $"($test_temp_dir)/test_result_($name | str replace '.nu' '' | str replace '-' '_').json"
    $test_result | to json | save --force $filename
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

# Enhanced isolated test runner
export def run_isolated_test [test_func: closure, test_name: string, category: string = "unit"] {
    # Setup isolated environment
    let test_dir = (setup_isolated_test_env $test_name)
    let start_time = (date now | into int)
    
    print $"($env.GREEN)Running isolated test: ($test_name)($env.NC)"
    print $"  Test directory: ($test_dir)"
    
    let result = try {
        # Run the test function in isolation
        let test_result = (do $test_func)
        let end_time = (date now | into int)
        let duration = (($end_time - $start_time) | into float) / 1000000000
        
        print $"($env.GREEN)✓ Isolated test passed: ($test_name) - ($duration)s($env.NC)"
        track_test $test_name $category "passed" $duration
        {success: true, duration: $duration, error: null}
    } catch { |err|
        let end_time = (date now | into int)
        let duration = (($end_time - $start_time) | into float) / 1000000000
        
        print $"($env.RED)✗ Isolated test failed: ($test_name) - ($duration)s($env.NC)"
        print $"($env.RED)Error: ($err.msg)($env.NC)"
        track_test $test_name $category "failed" $duration
        {success: false, duration: $duration, error: $err.msg}
    }
    
    # Always cleanup, even if test failed
    cleanup_isolated_test_env
    
    $result.success
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
    nu scripts/testing/unit/unit-tests.nu
}

export def run_integration_tests [] {
    print $"($env.GREEN)Running integration tests...($env.NC)"
    run_tests "scripts/testing/integration" "integration"
}

export def run_storage_tests [] {
    print $"($env.GREEN)Running storage tests...($env.NC)"
    let storage_test_dir = "scripts/testing/storage"
    if ($storage_test_dir | path exists) {
        run_tests $storage_test_dir "storage"
    } else {
        print $"($env.YELLOW)Storage test directory not found: ($storage_test_dir)($env.NC)"
        true
    }
}

export def run_performance_tests [] {
    print $"($env.GREEN)Running performance tests...($env.NC)"
    let performance_test_dir = "scripts/testing/performance"
    if ($performance_test_dir | path exists) {
        run_tests $performance_test_dir "performance"
    } else {
        print $"($env.YELLOW)Performance test directory not found: ($performance_test_dir)($env.NC)"
        true
    }
}

export def run_all_tests [] {
    let unit_results = run_unit_tests
    let integration_results = run_integration_tests
    $unit_results and $integration_results
}

# --- Core Test Functions ---
export def test_retry [max_attempts: int, delay: int, test_func: closure, expected_result: bool] {
    let green = ($env | get GREEN? | default (ansi green))
    let yellow = ($env | get YELLOW? | default (ansi yellow))
    let red = ($env | get RED? | default (ansi red))
    let nc = ($env | get NC? | default (ansi reset))
    
    mut attempt = 1
    mut last_result = null
    mut passed = false
    while $attempt <= $max_attempts {
        let result = (do $test_func)
        if $result == $expected_result {
            print $"($green)✓ PASS: test_retry succeeded on attempt ($attempt)($nc)"
            $passed = true
            break
        } else {
            print $"($yellow)Retry ($attempt) failed, retrying...($nc)"
            $last_result = $result
            if $attempt < $max_attempts {
                sleep ($delay | into int)
            }
        }
        let next_attempt = $attempt + 1
        $attempt = $next_attempt
    }
    if not $passed {
        print $"($red)✗ FAIL: test_retry did not succeed after ($max_attempts) attempts. Last result: ($last_result)($nc)"
    }
    $passed
}

export def test_logging [level: string, message: string, expected_output: string] {
    let green = ($env | get GREEN? | default (ansi green))
    let red = ($env | get RED? | default (ansi red))
    let nc = ($env | get NC? | default (ansi reset))
    
    let log_prefix = match $level {
        "DEBUG" => "[DEBUG] ",
        "INFO" => "[INFO] ",
        "WARN" => "[WARN] ",
        "ERROR" => "[ERROR] ",
        _ => "[LOG] "
    }
    let output = $"($log_prefix)($message)"
    if $output == $expected_output {
        print $"($green)✓ PASS: test_logging output matched($nc)"
        true
    } else {
        print $"($red)✗ FAIL: test_logging output did not match. Got: ($output), Expected: ($expected_output)($nc)"
        false
    }
}

export def test_config_validation [config_value: string, error_message: string] {
    let green = ($env | get GREEN? | default (ansi green))
    let red = ($env | get RED? | default (ansi red))
    let nc = ($env | get NC? | default (ansi reset))
    
    if ($config_value | is-empty) {
        print $"($red)✗ FAIL: test_config_validation - ($error_message)($nc)"
        false
    } else {
        print $"($green)✓ PASS: test_config_validation - config is valid($nc)"
        true
    }
}

# --- Main Test Runner ---
export def main [] {
    let args = $env._args
    let test_type = ($args | get 0 | default "all")

    match $test_type {
        "unit" => { run_unit_tests },
        "integration" => { run_integration_tests },
        "all" => { run_all_tests },
        _ => {
            print $"($env.RED)Unknown test type: ($test_type)($env.NC)"
            print $"($env.YELLOW)Available types: unit, integration, all($env.NC)"
            false
        }
    }
}
