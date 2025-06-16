# Test template for nix-mox components
# This file serves as a template for creating new test files
# Copy this file and modify it for your specific component tests

use ../lib/test-utils.nu *

def main [] {
    print $"Running tests for component: ($env.COMPONENT_NAME)"

    # Run all test suites
    let unit_results = run_unit_tests
    let integration_results = run_integration_tests

    # Return overall test status
    $unit_results and $integration_results
}

# Unit test suite
def run_unit_tests [] {
    print "Running unit tests..."

    # Example unit tests
    let test1 = test_logging "INFO" "Unit test message" "[INFO] Unit test message"
    let test2 = test_config_validation "test-config" "Configuration validation failed"

    # Return true if all tests passed
    $test1 and $test2
}

# Integration test suite
def run_integration_tests [] {
    print "Running integration tests..."

    # Example integration tests
    let test1 = test_retry 3 1 { true } true
    let test2 = test_logging "ERROR" "Integration test error" "[ERROR] Integration test error"

    # Return true if all tests passed
    $test1 and $test2
}

# Run tests if this file is executed directly
if ($env.NU_TEST? == "true") {
    main
}