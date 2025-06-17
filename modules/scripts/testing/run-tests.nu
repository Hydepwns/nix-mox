# Main test runner for nix-mox
# This script coordinates all test execution and reporting

use ./lib/test-utils.nu *
use ./lib/test-coverage.nu *

# --- Test Configuration ---
export-env {
    $env.TEST_CONFIG = {
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

    wrap_test $suite_name $suite_name $test_func
}

def run_all_test_suites [] {
    setup_test_env

    if $env.TEST_CONFIG.run_unit_tests {
        run_test_suite "unit" { run_unit_tests }
    }

    if $env.TEST_CONFIG.run_integration_tests {
        run_test_suite "integration" { run_integration_tests }
    }

    if $env.TEST_CONFIG.run_storage_tests {
        run_test_suite "storage" { run_storage_tests }
    }

    if $env.TEST_CONFIG.run_performance_tests {
        run_test_suite "performance" { run_performance_tests }
    }

    if $env.TEST_CONFIG.generate_coverage {
        generate_coverage_report
        export_coverage_report $env.TEST_CONFIG.export_format | save coverage.($env.TEST_CONFIG.export_format)
    }

    cleanup_test_env
}

# --- Command Line Interface ---
def parse_args [args] {
    if ($args | length) > 0 {
        $env.TEST_CONFIG.run_unit_tests = $args | any { |arg| $arg == "--unit" }
        $env.TEST_CONFIG.run_integration_tests = $args | any { |arg| $arg == "--integration" }
        $env.TEST_CONFIG.run_storage_tests = $args | any { |arg| $arg == "--storage" }
        $env.TEST_CONFIG.run_performance_tests = $args | any { |arg| $arg == "--performance" }
        $env.TEST_CONFIG.generate_coverage = $args | any { |arg| $arg == "--coverage" }

        let format_arg = ($args | where { |arg| $arg | str starts-with "--format=" } | get 0)
        if ($format_arg | length) > 0 {
            $env.TEST_CONFIG.export_format = ($format_arg | str replace "--format=" "")
        }
    }
}

# --- Main Runner ---
def main [] {
    let args = $env._args
    parse_args $args
    run_all_test_suites
}

# Run if this file is executed directly
export def run [] {
    main
}
