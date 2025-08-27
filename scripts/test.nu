#!/usr/bin/env nu
# Modular test system for nix-mox
# Refactored from monolithic 1037-line file into focused modules
# Uses functional patterns and proper test orchestration

use lib/logging.nu *
use lib/testing.nu *
use lib/validators.nu *
use lib/platform.nu *
use lib/script-template.nu *
use lib/command-wrapper.nu [execute_command]
use lib/constants.nu *

# Import test modules
use testing/modules/runners.nu *
use testing/modules/implementations.nu *
use testing/modules/benchmarks.nu *

# Main test runner dispatcher
def main [
    suite: string = "all",
    --coverage,
    --output: string = "coverage-tmp/test-results",
    --parallel,
    --fail-fast,
    --verbose,
    --help
] {
    if $help {
        show_test_help
        return
    }
    
    if $verbose { $env.LOG_LEVEL = "DEBUG" }
    
    banner "nix-mox test runner" $CONTEXTS.test
    
    # Set up test environment
    setup_test_environment $output

    # Route to appropriate test runner
    let result = match $suite {
        "all" => (run_all_tests ($coverage | default false) $output ($parallel | default true) ($fail_fast | default false)),
        "unit" => (run_unit_tests ($coverage | default false) $output ($parallel | default true) ($fail_fast | default false)),
        "integration" => (run_integration_tests ($coverage | default false) $output ($parallel | default true) ($fail_fast | default false)),
        "validation" => (run_validation_tests ($coverage | default false) $output ($parallel | default true) ($fail_fast | default false)),
        "maintenance" => (run_maintenance_tests ($coverage | default false) $output ($parallel | default true) ($fail_fast | default false)),
        "setup" => (run_setup_tests ($coverage | default false) $output ($parallel | default true) ($fail_fast | default false)),
        "platform" => (run_platform_tests ($coverage | default false) $output ($parallel | default true) ($fail_fast | default false)),
        "analysis" => (run_analysis_tests ($coverage | default false) $output ($parallel | default true) ($fail_fast | default false)),
        "gaming" => (run_gaming_tests ($coverage | default false) $output ($parallel | default true) ($fail_fast | default false)),
        "gaming-scripts" => (run_gaming_scripts_tests ($coverage | default false) $output ($parallel | default true) ($fail_fast | default false)),
        "handlers" => (run_handlers_tests ($coverage | default false) $output ($parallel | default true) ($fail_fast | default false)),
        "macos-platform" => (run_macos_platform_specific_tests ($coverage | default false) $output ($parallel | default true) ($fail_fast | default false)),
        "windows-platform" => (run_windows_platform_specific_tests ($coverage | default false) $output ($parallel | default true) ($fail_fast | default false)),
        "infrastructure" => (run_infrastructure_tests ($coverage | default false) $output ($parallel | default true) ($fail_fast | default false)),
        "security" => (run_security_tests ($coverage | default false) $output ($parallel | default true) ($fail_fast | default false)),
        "performance" => (run_performance_tests ($coverage | default false) $output ($parallel | default true) ($fail_fast | default false)),
        "help" => { show_test_help; return },
        _ => {
            error $"Unknown test suite: ($suite)" --context "test"
            show_test_help
            return
        }
    }
    
    # Save test report
    save_test_report $result $output
    
    # Display summary
    display_test_summary $result
    
    $result
}

# Set up test environment
def setup_test_environment [output: string] {
    info $"Test environment setup: ($output)" --context "test-env"
    
    # Create output directory
    try {
        mkdir ($output | path dirname)
    } catch { |_| null }
    
    # Set up test-specific environment variables
    $env.NIX_MOX_TEST_MODE = "true"
    $env.NIX_MOX_TEST_OUTPUT = $output
}

# Save test report
def save_test_report [result: record, output: string] {
    let report_file = $"($output)/test-report.json"
    
    try {
        $result | to json | save $report_file
        success $"Test report saved: ($report_file)" --context "test-report"
    } catch { |err|
        warn $"Failed to save test report: ($err.msg)" --context "test-report"
    }
}

# Display test summary
def display_test_summary [result: record] {
    if $result.success {
        success "All tests passed!" --context "test-summary"
    } else {
        error "Some tests failed!" --context "test-summary"
    }
    
    # Display result table
    $result
}

# Show test help
def show_test_help [] {
    print "nix-mox Test System"
    print "==================="
    print ""
    print "Usage: nu test.nu [suite] [options]"
    print ""
    print "Available test suites:"
    [
        { suite: "all", description: "Run all test suites (default)" }
        { suite: "unit", description: "Run unit tests only" }
        { suite: "integration", description: "Run integration tests" }
        { suite: "validation", description: "Run validation system tests" }
        { suite: "maintenance", description: "Run maintenance safety tests" }
        { suite: "setup", description: "Run setup safety tests" }
        { suite: "platform", description: "Run platform compatibility tests" }
        { suite: "analysis", description: "Run analysis system tests" }
        { suite: "gaming", description: "Run gaming system tests" }
        { suite: "gaming-scripts", description: "Run gaming scripts tests" }
        { suite: "handlers", description: "Run handler tests" }
        { suite: "macos-platform", description: "Run macOS platform tests" }
        { suite: "windows-platform", description: "Run Windows platform tests" }
        { suite: "infrastructure", description: "Run infrastructure tests" }
        { suite: "security", description: "Run security analysis tests" }
        { suite: "performance", description: "Run performance benchmarks" }
    ] | table
    
    print ""
    print "Options:"
    print "  --coverage         - Enable coverage collection"
    print "  --output PATH      - Test output directory (default: coverage-tmp/test-results)"
    print "  --parallel         - Run tests in parallel (default: true)"
    print "  --fail-fast        - Stop on first failure"
    print "  --verbose          - Enable verbose output"
    print "  --help             - Show this help"
    print ""
    print "Examples:"
    print "  nu test.nu                          # Run all tests"
    print "  nu test.nu unit --verbose           # Run unit tests with verbose output"
    print "  nu test.nu integration --coverage   # Run integration tests with coverage"
    print "  nu test.nu performance              # Run performance benchmarks"
}

# Helper functions for test environment setup
export def setup_test_env [test_dir: string = "coverage-tmp/nix-mox-tests"] {
    info $"Test environment setup: ($test_dir)" --context "test-env"
    
    try {
        mkdir $test_dir
    } catch { |_| null }
    
    $env.NIX_MOX_TEST_DIR = $test_dir
}

export def cleanup_test_env [test_dir: string = "coverage-tmp/nix-mox-tests"] {
    try {
        rm -rf $test_dir
        debug $"Cleaned up test directory: ($test_dir)" --context "test-env"
    } catch { |_| null }
}

# Legacy compatibility functions for existing scripts
export def run_unit_tests_legacy [] { run_unit_tests false "coverage-tmp/test-results" true false }
export def run_integration_tests_legacy [] { run_integration_tests false "coverage-tmp/test-results" true false }
export def run_validation_tests_legacy [] { run_validation_tests false "coverage-tmp/test-results" true false }