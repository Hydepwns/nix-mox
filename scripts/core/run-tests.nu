def main [] {
    print "Starting test suite..."

    # Run common tests
    print "\nRunning common tests..."
    source ../../tests/lib/test-common.nu

    # Run unit tests
    print "\nRunning unit tests..."
    source ../../tests/unit/unit-tests.nu

    # Run integration tests
    print "\nRunning integration tests..."
    source ../../tests/integration/integration-tests.nu

    # Run performance tests
    print "\nRunning performance tests..."
    source ../../tests/integration/performance-tests.nu

    print "\nAll tests completed successfully! 🎉"
}

if $env.NU_TEST? == "true" {
    main
} else {
    $env.NU_TEST = "true"
    main
}