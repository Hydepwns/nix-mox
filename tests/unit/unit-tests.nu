use ../lib/test-utils.nu *

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
    let os = (sys host | get name)
    if $os == "Linux" {
        # Linux-specific device checks
        if (ls /dev/nvme0n1 | default [] | length) > 0 {
            print "NVMe device found"
        } else if (ls /dev/sd* | default [] | length) > 0 {
            print "SATA/SCSI device found"
        } else {
            print "No storage devices found, skipping device tests"
        }
    } else if $os == "Darwin" {
        # macOS-specific device checks
        if (ls /dev/disk* | default [] | length) > 0 {
            print "Storage device found"
        } else {
            print "No storage devices found, skipping device tests"
        }
    } else {
        print $"Unsupported OS: ($os), skipping device tests"
    }

    # Test pool operations
    print "Testing pool operations..."
    if $os == "Linux" {
        if (which zpool | length) > 0 {
            if (zpool list rpool 2>/dev/null | length) > 0 {
                print "ZFS pool found"
            } else {
                print "No ZFS pool found, skipping pool tests"
            }
        } else {
            print "ZFS not installed, skipping pool tests"
        }
    } else {
        print $"ZFS tests not supported on ($os), skipping pool tests"
    }

    print "Unit tests completed successfully"
}

if $env.NU_TEST? == "true" {
    main
}
main
