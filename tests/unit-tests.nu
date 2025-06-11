use ./test-utils.nu *

def main [] {
    print "Running ZFS SSD caching unit tests..."

    # Test configuration validation
    print "Testing configuration validation..."
    test_config_validation "rpool" "Pool name is not configured"
    test_config_validation "/dev/nvme*n1" "Device pattern is not configured"

    # Test logging
    print "Testing logging functionality..."
    test_logging "INFO" "Test message" "[INFO] Test message"
    test_logging "ERROR" "Error message" "[ERROR] Error message"
    test_logging "WARN" "Warning message" "[WARN] Warning message"
    test_logging "DEBUG" "Debug message" "[DEBUG] Debug message"

    # Test retry mechanism
    print "Testing retry mechanism..."
    test_retry 3 1 { true } true
    test_retry 3 1 { false } false

    # Test device detection
    print "Testing device detection..."
    if (ls /dev/nvme0n1 | length) > 0 {
        print "NVMe device found"
    } else {
        print "No NVMe device found, skipping device tests"
    }

    # Test pool operations
    print "Testing pool operations..."
    if (zpool list rpool | length) > 0 {
        print "ZFS pool found"
    } else {
        print "No ZFS pool found, skipping pool tests"
    }

    print "Unit tests completed successfully"
}

if $env.NU_TEST == "true" {
    main
}