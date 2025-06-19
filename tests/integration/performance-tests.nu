use ../lib/test-utils.nu *

export def test_performance_tests [] {
    print "Running ZFS SSD caching performance tests..."

    # Test retry performance
    print "Testing retry performance..."
    test_performance { test_retry 3 1 { true } true } 5

    # Test logging performance
    print "Testing logging performance..."
    test_performance {
        for i in 1..100 {
            test_logging "INFO" "Test message ($i)" "[INFO] Test message ($i)"
        }
    } 10

    # Test configuration validation performance
    print "Testing configuration validation performance..."
    test_performance {
        for i in 1..100 {
            test_config_validation "test($i)" "Configuration validation failed"
        }
    } 10

    # Test resource utilization
    print "Testing resource utilization..."
    if (which top | length) > 0 {
        # Monitor CPU and memory usage during operations
        if (top -b -n 1 | str contains "zfs") {
            print "ZFS processes found"
        } else {
            print "No ZFS processes found"
        }
    } else {
        print "top command not available, skipping resource utilization test"
    }

    print "Performance tests completed successfully"
}

if ($env.NU_TEST? == "true") {
    test_performance_tests
}
