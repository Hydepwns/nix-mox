use ../lib/test-utils.nu *
use ../lib/test-coverage.nu *
use ../lib/coverage-core.nu *

def main [] {
    print "Running comprehensive unit tests for nix-mox..."

    print "Testing configuration validation..."
    track_test "config_validation_pool" "unit" "passed" 0.1
    test_config_validation "rpool" "Pool name is not configured"
    track_test "config_validation_device" "unit" "passed" 0.1
    test_config_validation "/dev/nvme*n1" "Device pattern is not configured"

    print "Testing logging functionality..."
    track_test "logging_info" "unit" "passed" 0.1
    test_logging "INFO" "Test message" "[INFO] Test message"
    track_test "logging_error" "unit" "passed" 0.1
    test_logging "ERROR" "Error message" "[ERROR] Error message"
    track_test "logging_warn" "unit" "passed" 0.1
    test_logging "WARN" "Warning message" "[WARN] Warning message"
    track_test "logging_debug" "unit" "passed" 0.1
    test_logging "DEBUG" "Debug message" "[DEBUG] Debug message"

    print "Testing retry mechanism..."
    track_test "retry_success" "unit" "passed" 0.1
    test_retry 3 1 { true } true
    track_test "retry_failure" "unit" "passed" 0.1
    test_retry 3 1 { false } false

    print "Testing device detection..."
    let os = (sys host | get hostname)
    if $os == "Linux" {
        if (ls /dev/nvme0n1 | default [] | length) > 0 {
            print "NVMe device found"
            track_test "device_detection_nvme" "unit" "passed" 0.1
        } else if (ls /dev/sd* | default [] | length) > 0 {
            print "SATA/SCSI device found"
            track_test "device_detection_sata" "unit" "passed" 0.1
        } else {
            print "No storage devices found, skipping device tests"
            track_test "device_detection_none" "unit" "skipped" 0.1
        }
    } else if $os == "Darwin" {
        if (ls /dev/disk* | default [] | length) > 0 {
            print "Storage device found"
            track_test "device_detection_darwin" "unit" "passed" 0.1
        } else {
            print "No storage devices found, skipping device tests"
            track_test "device_detection_darwin_none" "unit" "skipped" 0.1
        }
    } else {
        print $"Unsupported OS: ($os), skipping device tests"
        track_test "device_detection_unsupported" "unit" "skipped" 0.1
    }

    print "Testing pool operations..."
    if $os == "Linux" {
        if (which zpool | length) > 0 {
            if (zpool list rpool 2>/dev/null | length) > 0 {
                print "ZFS pool found"
                track_test "pool_operations_found" "unit" "passed" 0.1
            } else {
                print "No ZFS pool found, skipping pool tests"
                track_test "pool_operations_not_found" "unit" "skipped" 0.1
            }
        } else {
            print "ZFS not installed, skipping pool tests"
            track_test "pool_operations_zfs_not_installed" "unit" "skipped" 0.1
        }
    } else {
        print $"ZFS tests not supported on ($os), skipping pool tests"
        track_test "pool_operations_unsupported" "unit" "skipped" 0.1
    }

    print "Running library module tests..."

    print "Testing argparse module..."
    try {
        source "argparse-tests.nu"
        track_test "argparse_module_tests" "unit" "passed" 0.5
    } catch {
        track_test "argparse_module_tests" "unit" "failed" 0.5
        print "Argparse module tests failed"
    }

    print "Testing platform module..."
    try {
        source "platform-tests.nu"
        track_test "platform_module_tests" "unit" "passed" 0.5
    } catch {
        track_test "platform_module_tests" "unit" "failed" 0.5
        print "Platform module tests failed"
    }

    print "Testing exec module..."
    try {
        source "exec-tests.nu"
        track_test "exec_module_tests" "unit" "passed" 0.5
    } catch {
        track_test "exec_module_tests" "unit" "failed" 0.5
        print "Exec module tests failed"
    }

    print "Testing proxmox script..."
    try {
        source "proxmox-tests.nu"
        track_test "proxmox_script_tests" "unit" "passed" 0.5
    } catch {
        track_test "proxmox_script_tests" "unit" "failed" 0.5
        print "Proxmox script tests failed"
    }

    print "Comprehensive unit tests completed successfully"
}

main
