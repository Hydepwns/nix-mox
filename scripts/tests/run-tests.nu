#!/usr/bin/env nu
# Main test runner for nix-mox
# This script coordinates all test execution and reporting

export-env {
    use ./lib/test-utils.nu *
    use ./lib/test-coverage.nu *
    use ./lib/coverage-core.nu *
    use ./lib/test-common.nu *
}

# Import functions for direct use in this script
use ./lib/test-coverage.nu *
use ./lib/coverage-core.nu *

# --- Test Configuration ---
def setup_test_config [] {
    {
        run_unit_tests: true
        run_integration_tests: true
        run_storage_tests: true
        run_performance_tests: true
        generate_coverage: true
        export_format: "json"
        verbose: false
        parallel: false
        timeout: 300
        retry_failed: false
        max_retries: 3
    }
}

# --- Environment Setup ---
def ensure_test_env [] {
    # Set default TEST_TEMP_DIR if not already set
    if not ($env | get -i TEST_TEMP_DIR | is-not-empty) {
        $env.TEST_TEMP_DIR = "/tmp/nix-mox-tests"
    }

    # Ensure the test directory exists
    if not ($env.TEST_TEMP_DIR | path exists) {
        mkdir $env.TEST_TEMP_DIR
    }

    print $"($env.GREEN)Test environment configured at: ($env.TEST_TEMP_DIR)($env.NC)"
}

# --- Test Environment Management ---
def setup_test_env [] {
    print $"($env.GREEN)Setting up test environment...($env.NC)"
    if not ($env.TEST_TEMP_DIR | path exists) {
        mkdir $env.TEST_TEMP_DIR
    }
    print $"($env.GREEN)Test environment ready at: ($env.TEST_TEMP_DIR)($env.NC)"
}

def cleanup_test_env [] {
    print $"($env.YELLOW)Cleaning up test environment...($env.NC)"
    rm -rf $env.TEST_TEMP_DIR
    print $"($env.GREEN)Test environment cleaned up($env.NC)"
}

# --- Test Execution with Better Error Handling ---
def run_test_suite [suite_name: string, test_func: closure, config: record] {
    print $"($env.GREEN)Running ($suite_name) tests...($env.NC)"

    let start_time = (date now | into int)
    let result = (try {
        do $test_func
        { success: true, error_msg: "" }
    } catch {
        { success: false, error_msg: $env.LAST_ERROR }
    })

    let success = $result.success
    let error_msg = $result.error_msg

    let end_time = (date now | into int)
    let duration = (($end_time - $start_time) | into float) / 1000000000

    if $success {
        print $"($env.GREEN)✓ ($suite_name) tests completed successfully in ($duration)s($env.NC)"
        true
    } else {
        print $"($env.RED)✗ ($suite_name) tests failed after ($duration)s($env.NC)"
        if $config.verbose {
            print $"($env.RED)Error: ($error_msg)($env.NC)"
        }
        false
    }
}

def run_unit_tests [] {
    print "Running unit tests..."
    nu scripts/tests/unit/unit-tests.nu
    true
}

def run_integration_tests [] {
    print "Running integration tests..."
    nu scripts/tests/integration/integration-tests.nu
    true
}

def run_storage_tests [] {
    print "Running storage tests..."
    nu scripts/tests/storage/storage-tests.nu
    true
}

def run_performance_tests [] {
    print "Running performance tests..."
    nu scripts/tests/performance/performance-tests.nu
    true
}

def run_all_test_suites [config: record] {
    # Call setup_test_env from the imported module
    setup_test_env

    mut overall_success = true
    mut test_results = []

    # Run unit tests
    if $config.run_unit_tests {
        let unit_success = run_test_suite "unit" { run_unit_tests } $config
        $test_results = ($test_results | append { suite: "unit", success: $unit_success })
        $overall_success = ($overall_success and $unit_success)
    }

    # Run integration tests
    if $config.run_integration_tests {
        let integration_success = run_test_suite "integration" { run_integration_tests } $config
        $test_results = ($test_results | append { suite: "integration", success: $integration_success })
        $overall_success = ($overall_success and $integration_success)
    }

    # Run storage tests
    if $config.run_storage_tests {
        let storage_success = run_test_suite "storage" { run_storage_tests } $config
        $test_results = ($test_results | append { suite: "storage", success: $storage_success })
        $overall_success = ($overall_success and $storage_success)
    }

    # Run performance tests
    if $config.run_performance_tests {
        let performance_success = run_test_suite "performance" { run_performance_tests } $config
        $test_results = ($test_results | append { suite: "performance", success: $performance_success })
        $overall_success = ($overall_success and $performance_success)
    }

    # Generate coverage report
    if $config.generate_coverage {
        try {
            print $"($env.GREEN)Generating coverage report...($env.NC)"
            print "DEBUG: About to call generate_coverage_report"
            let result = do { generate_coverage_report }
            print "DEBUG: generate_coverage_report completed"

            # Export coverage report once and save to both locations
            print "DEBUG: About to export coverage report"
            let coverage_data = do { export_coverage_report $config.export_format }
            print $"DEBUG: Coverage data length: ($coverage_data | str length)"

            let coverage_path = $"($env.TEST_TEMP_DIR)/coverage.($config.export_format)"
            $coverage_data | save --force $coverage_path
            print $"($env.GREEN)Coverage report saved as ($coverage_path)($env.NC)"

            # Also save to /tmp for CI workflows to find
            let ci_coverage_path = $"/tmp/nix-mox-tests/coverage.($config.export_format)"
            if not ("/tmp/nix-mox-tests" | path exists) {
              mkdir "/tmp/nix-mox-tests"
            }
            $coverage_data | save --force $ci_coverage_path
            print $"($env.GREEN)CI coverage report saved as ($ci_coverage_path)($env.NC)"
        } catch {
            print $"($env.YELLOW)Warning: Failed to generate coverage report: ($env.LAST_ERROR)($env.NC)"
        }
    }

    # Print summary
    print_summary $test_results

    # Only clean up if coverage generation is disabled
    if not $config.generate_coverage {
        cleanup_test_env
    } else {
        print $"($env.YELLOW)Test environment preserved for coverage analysis at: ($env.TEST_TEMP_DIR)($env.NC)"
    }

    # Exit with appropriate code
    if $overall_success {
        exit 0
    } else {
        exit 1
    }
}

# --- Test Summary ---
def print_summary [results: list] {
    print ""
    print $"($env.GREEN)=== Test Summary ===($env.NC)"

    let total_suites = ($results | length)
    let passed_suites = ($results | where { |r| $r.success } | length)
    let failed_suites = ($total_suites - $passed_suites)

    for result in $results {
        let status_color = if $result.success { $env.GREEN } else { $env.RED }
        let status_symbol = if $result.success { "✓" } else { "✗" }
        print $"($status_color)($status_symbol) ($result.suite) tests($env.NC)"
    }

    print ""
    print $"Total test suites: ($total_suites)"
    print $"Passed: ($passed_suites)"
    print $"Failed: ($failed_suites)"

    if $failed_suites > 0 {
        print $"($env.RED)Some tests failed!($env.NC)"
    } else {
        print $"($env.GREEN)All tests passed!($env.NC)"
    }
}

# --- Enhanced Command Line Interface ---
def parse_args [args: list, config: record] {
    if ($args | length) > 0 {
        # Handle help
        if ($args | any { |arg| $arg == "--help" or $arg == "-h" }) {
            print_help
            exit 0
        }

        # Handle verbose mode
        let config = if ($args | any { |arg| $arg == "--verbose" or $arg == "-v" }) {
            $config | upsert verbose true
        } else {
            $config
        }

        # Handle parallel execution
        let config = if ($args | any { |arg| $arg == "--parallel" or $arg == "-p" }) {
            $config | upsert parallel true
        } else {
            $config
        }

        # Handle timeout
        let timeout_args = ($args | where { |arg| $arg | str starts-with "--timeout=" })
        let config = if ($timeout_args | length) > 0 {
            let timeout_arg = ($timeout_args | get 0)
            let timeout_value = ($timeout_arg | str replace "--timeout=" "")
            $config | upsert timeout ($timeout_value | into int)
        } else {
            $config
        }

        # Handle retry failed tests
        let config = if ($args | any { |arg| $arg == "--retry-failed" }) {
            $config | upsert retry_failed true
        } else {
            $config
        }

        # Handle max retries
        let retry_args = ($args | where { |arg| $arg | str starts-with "--max-retries=" })
        let config = if ($retry_args | length) > 0 {
            let retry_arg = ($retry_args | get 0)
            let retry_value = ($retry_arg | str replace "--max-retries=" "")
            $config | upsert max_retries ($retry_value | into int)
        } else {
            $config
        }

        let test_flags = ["--unit", "--integration", "--storage", "--performance"]
        let has_specific_tests = ($args | any { |arg| $test_flags | any { |flag| $arg == $flag } })

        let config = if $has_specific_tests {
            $config | upsert run_unit_tests ($args | any { |arg| $arg == "--unit" }) | upsert run_integration_tests ($args | any { |arg| $arg == "--integration" }) | upsert run_storage_tests ($args | any { |arg| $arg == "--storage" }) | upsert run_performance_tests ($args | any { |arg| $arg == "--performance" })
        } else {
            $config
        }

        let config = if ($args | any { |arg| $arg == "--no-coverage" }) {
            $config | upsert generate_coverage false
        } else {
            $config
        }

        let format_args = ($args | where { |arg| $arg | str starts-with "--format=" })
        let config = if ($format_args | length) > 0 {
            let format_arg = ($format_args | get 0)
            $config | upsert export_format ($format_arg | str replace "--format=" "")
        } else {
            $config
        }

        $config
    } else {
        $config
    }
}

# --- Help Function ---
def print_help [] {
    print "nix-mox Test Runner"
    print "=================="
    print ""
    print "Usage: nu -c 'source scripts/tests/run-tests.nu; run [OPTIONS]'"
    print ""
    print "Options:"
    print "  --unit, --integration, --storage, --performance"
    print "    Run specific test suites (default: all)"
    print ""
    print "  --verbose, -v"
    print "    Enable verbose output"
    print ""
    print "  --parallel, -p"
    print "    Run tests in parallel (experimental)"
    print ""
    print "  --timeout=SECONDS"
    print "    Set timeout for test suites (default: 300)"
    print ""
    print "  --retry-failed"
    print "    Retry failed tests"
    print ""
    print "  --max-retries=N"
    print "    Maximum number of retries (default: 3)"
    print ""
    print "  --no-coverage"
    print "    Disable coverage report generation"
    print ""
    print "  --format=FORMAT"
    print "    Coverage report format: json, yaml, toml (default: json)"
    print ""
    print "  --help, -h"
    print "    Show this help message"
    print ""
    print "Examples:"
    print "  nu -c 'source scripts/tests/run-tests.nu; run [\"--unit\"]'"
    print "  nu -c 'source scripts/tests/run-tests.nu; run [\"--verbose\", \"--integration\"]'"
    print "  nu -c 'source scripts/tests/run-tests.nu; run [\"--no-coverage\", \"--parallel\"]'"
}

# --- Main Runner ---
def main [args: list] {
    let config = setup_test_config
    let config = parse_args $args $config

    # Ensure test environment is properly set up
    ensure_test_env

    run_all_test_suites $config
}

export def run [args: list] {
    main $args
}
