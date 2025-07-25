#!/usr/bin/env nu

# Test utilities for nix-mox
# Provides common testing functions and utilities

# --- Environment Setup ---
export def setup_test_env [] {
    # Set up test environment variables
    $env.TEST_TEMP_DIR = ($env | get -i TEMP | default "/tmp") + "/nix-mox-tests"
    $env.TEST_LOG_FILE = $env.TEST_TEMP_DIR + "/test.log"

    # Create test directories
    mkdir $env.TEST_TEMP_DIR

    # Set up color codes for output
    $env.GREEN = (ansi green)
    $env.RED = (ansi red)
    $env.YELLOW = (ansi yellow)
    $env.BLUE = (ansi blue)
    $env.NC = (ansi reset)  # No Color
}

# --- Assertion Functions ---
export def assert_true [condition: bool, message: string = ""] {
    let green = ($env | get -i GREEN | default (ansi green))
    let nc = ($env | get -i NC | default (ansi reset))

    if $condition {
        print $"($green)✓ PASS: ($message)($nc)"
        true
    } else {
        let red = ($env | get -i RED | default (ansi red))
        print $"($red)✗ FAIL: ($message)($nc)"
        false
    }
}

export def assert_false [condition: bool, message: string = ""] {
    assert_true (not $condition) $message
}

export def assert_equal [actual: any, expected: any, message: string = ""] {
    let green = ($env | get -i GREEN | default (ansi green))
    let red = ($env | get -i RED | default (ansi red))
    let nc = ($env | get -i NC | default (ansi reset))

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
    let green = ($env | get -i GREEN | default (ansi green))
    let red = ($env | get -i RED | default (ansi red))
    let nc = ($env | get -i NC | default (ansi reset))

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
    let green = ($env | get -i GREEN | default (ansi green))
    let red = ($env | get -i RED | default (ansi red))
    let nc = ($env | get -i NC | default (ansi reset))

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
    let green = ($env | get -i GREEN | default (ansi green))
    let red = ($env | get -i RED | default (ansi red))
    let nc = ($env | get -i NC | default (ansi reset))

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
    let green = ($env | get -i GREEN | default (ansi green))
    let red = ($env | get -i RED | default (ansi red))
    let nc = ($env | get -i NC | default (ansi reset))

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
    let test_temp_dir = ($env | get -i TEST_TEMP_DIR | default "/tmp/nix-mox-tests");
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
    nu scripts/tests/unit/unit-tests.nu
}

export def run_integration_tests [] {
    print $"($env.GREEN)Running integration tests...($env.NC)"
    run_tests "scripts/tests/integration" "integration"
}

export def run_storage_tests [] {
    print $"($env.GREEN)Running storage tests...($env.NC)"
    let storage_test_dir = "scripts/tests/storage"
    if ($storage_test_dir | path exists) {
        run_tests $storage_test_dir "storage"
    } else {
        print $"($env.YELLOW)Storage test directory not found: ($storage_test_dir)($env.NC)"
        true
    }
}

export def run_performance_tests [] {
    print $"($env.GREEN)Running performance tests...($env.NC)"
    let performance_test_dir = "scripts/tests/performance"
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
    mut attempt = 1
    mut last_result = null
    mut passed = false
    while $attempt <= $max_attempts {
        let result = (do $test_func)
        if $result == $expected_result {
            print $"($env.GREEN)✓ PASS: test_retry succeeded on attempt ($attempt)($env.NC)"
            $passed = true
            break
        } else {
            print $"($env.YELLOW)Retry ($attempt) failed, retrying...($env.NC)"
            $last_result = $result
            if $attempt < $max_attempts {
                sleep ($delay | into int)
            }
        }
        let next_attempt = $attempt + 1
        $attempt = $next_attempt
    }
    if not $passed {
        print $"($env.RED)✗ FAIL: test_retry did not succeed after ($max_attempts) attempts. Last result: ($last_result)($env.NC)"
    }
    $passed
}

export def test_logging [level: string, message: string, expected_output: string] {
    let log_prefix = match $level {
        "DEBUG" => "[DEBUG] ",
        "INFO" => "[INFO] ",
        "WARN" => "[WARN] ",
        "ERROR" => "[ERROR] ",
        _ => "[LOG] "
    }
    let output = $"($log_prefix)($message)"
    if $output == $expected_output {
        print $"($env.GREEN)✓ PASS: test_logging output matched($env.NC)"
        true
    } else {
        print $"($env.RED)✗ FAIL: test_logging output did not match. Got: ($output), Expected: ($expected_output)($env.NC)"
        false
    }
}

export def test_config_validation [config_value: string, error_message: string] {
    if ($config_value | is-empty) {
        print $"($env.RED)✗ FAIL: test_config_validation - ($error_message)($env.NC)"
        false
    } else {
        print $"($env.GREEN)✓ PASS: test_config_validation - config is valid($env.NC)"
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
