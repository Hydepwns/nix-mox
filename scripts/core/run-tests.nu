module run-tests {
    use ../../tests/lib/test-common.nu

    export def main [] {
        print "Starting test suite..."

        # Run common tests
        print "\nRunning common tests..."
        test_log_functions

        # Run unit tests
        print "\nRunning unit tests..."
        test_unit_tests

        # Run integration tests
        print "\nRunning integration tests..."
        test_integration_tests

        # Run performance tests
        print "\nRunning performance tests..."
        test_performance_tests

        print "\nAll tests completed successfully! 🎉"
    }
}

if $env.NU_TEST? == "true" {
    use run-tests
    main
} else {
    $env.NU_TEST = "true"
    use run-tests
    main
}
