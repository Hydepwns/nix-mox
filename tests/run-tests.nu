#!/usr/bin/env nu
# Main test runner for nix-mox
# This script coordinates all test execution and reporting

export-env {
    use ./lib/test-utils.nu *
    setup_test_env
}

use ./lib/test-utils.nu *
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
    }
}

# --- Test Execution ---
def run_test_suite [suite_name: string, test_func: closure] {
    print $"($env.GREEN)Running ($suite_name) tests...($env.NC)"
    do $test_func
}

def run_all_test_suites [config: record] {
    setup_test_env

    if $config.run_unit_tests {
        run_test_suite "unit" { run_unit_tests }
    }

    if $config.run_integration_tests {
        run_test_suite "integration" { run_integration_tests }
    }

    if $config.run_storage_tests {
        run_test_suite "storage" { run_storage_tests }
    }

    if $config.run_performance_tests {
        run_test_suite "performance" { run_performance_tests }
    }

    if $config.generate_coverage {
        print $"DEBUG: Listing files in ($env.TEST_TEMP_DIR) before coverage report:"
        ls $env.TEST_TEMP_DIR | get name | each { |f| print $"  ($f)" }
        print "DEBUG: Generating coverage report..."
        generate_coverage_report
        export_coverage_report $config.export_format | save --force $"coverage.($config.export_format)"
        print "DEBUG: Coverage report generated"
    } else {
        print "DEBUG: Coverage generation disabled"
    }

    cleanup_test_env
}

# --- Command Line Interface ---
def parse_args [args: list, config: record] {
    if ($args | length) > 0 {
        # If specific test types are requested, disable others
        let test_flags = ["--unit", "--integration", "--storage", "--performance"]
        let has_specific_tests = ($args | any { |arg| $test_flags | any { |flag| $arg == $flag } })

        let config = if $has_specific_tests {
            $config | upsert run_unit_tests ($args | any { |arg| $arg == "--unit" }) | upsert run_integration_tests ($args | any { |arg| $arg == "--integration" }) | upsert run_storage_tests ($args | any { |arg| $arg == "--storage" }) | upsert run_performance_tests ($args | any { |arg| $arg == "--performance" })
        } else {
            $config
        }

        # Only disable coverage if --no-coverage is explicitly passed
        let config = if ($args | any { |arg| $arg == "--no-coverage" }) {
            $config | upsert generate_coverage false
        } else {
            $config | upsert generate_coverage true
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

# --- Main Runner ---
def main [args: list] {
    # Set up the test temp directory globally
    $env.TEST_TEMP_DIR = "coverage-tmp"

    let config = setup_test_config
    let config = parse_args $args $config
    run_all_test_suites $config
}

# To run tests, use: nu -c "source run-tests.nu; run ['--unit']"
export def run [args: list] {
    main $args
}
