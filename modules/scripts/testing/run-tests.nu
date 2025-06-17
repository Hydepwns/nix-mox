use ../../tests/lib/test-common.nu *

def main [] {
    print "Starting test suite..."

    # Run common tests
    print "\nRunning common tests..."
    test_log_functions

    # Run unit tests
    print "\nRunning unit tests..."
    source ../../tests/unit/unit-tests.nu
    main

    # Run integration tests
    print "\nRunning integration tests..."
    source ../../tests/integration/integration-tests.nu
    main

    # Run performance tests
    print "\nRunning performance tests..."
    source ../../tests/integration/performance-tests.nu
    main

    print "\nAll tests completed successfully! 🎉"
}

if ($env.NU_TEST? == "true") {
    main
} else {
    $env.NU_TEST = "true"
    main
}
