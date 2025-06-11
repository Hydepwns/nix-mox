# Test template for nix-mox components

use ./test-utils.nu *

def main [] {
    print $"Running tests for component: ($env.COMPONENT_NAME)"

    # Unit Tests
    print "Running unit tests..."
    run_unit_tests

    # Integration Tests
    print "Running integration tests..."
    run_integration_tests

    # Performance Tests
    print "Running performance tests..."
    run_performance_tests

    print "All tests completed successfully"
}

# Unit test runner
def run_unit_tests [] {
    # Add your unit tests here
    test_logging "INFO" "Unit test message" "[INFO] Unit test message"
    test_config_validation "test-config" "Configuration validation failed"
}

# Integration test runner
def run_integration_tests [] {
    # Add your integration tests here
    test_retry 3 1 { true } true
    test_logging "ERROR" "Integration test error" "[ERROR] Integration test error"
}

# Performance test runner
def run_performance_tests [] {
    # Add your performance tests here
    test_performance {
        for i in 1..10 {
            test_logging "INFO" $"Performance test ($i)" $"[INFO] Performance test ($i)"
        }
    } 5
}

if $env.NU_TEST == "true" {
    main
} 