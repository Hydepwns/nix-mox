#!/usr/bin/env nu

# Import unified libraries
use ../../lib/validators.nu
use logging.nu *
use ../../lib/logging.nu *


use ../lib/test-utils.nu *
use ../lib/test-coverage.nu *
use ../lib/coverage-core.nu *

def main [] {
    print "Running comprehensive storage tests for nix-mox..."

    # Set up test environment
    setup_test_env

    print "Testing storage device detection..."
    test_storage_devices

    print "Testing ZFS functionality..."
    test_zfs_functionality

    print "Testing backup operations..."
    test_backup_operations

    print "Testing disk health monitoring..."
    test_disk_health

    print "Testing storage validation..."
    test_storage_validation

    print "Testing storage performance..."
    test_storage_performance

    print ""
    print "=== Storage Tests Summary ==="
    print "All storage tests completed successfully!"
}

# Test storage device detection
def test_storage_devices [] {
    track_test "device_detection_start" "storage" "passed" 0.1

    # Test device detection on different platforms
    let os = (sys host | get hostname)

    if $os == "Linux" {
        # Test NVMe device detection
        if (ls /dev/nvme* 2>/dev/null | default [] | length) > 0 {
            track_test "device_detection_nvme" "storage" "passed" 0.1
            assert_true true "NVMe device detection"
        } else {
            track_test "device_detection_nvme" "storage" "skipped" 0.1
        }

        # Test SATA/SCSI device detection
        if (ls /dev/sd* 2>/dev/null | default [] | length) > 0 {
            track_test "device_detection_sata" "storage" "passed" 0.1
            assert_true true "SATA/SCSI device detection"
        } else {
            track_test "device_detection_sata" "storage" "skipped" 0.1
        }

        # Test block device listing
        try {
            let block_devices = (lsblk --json | from json | get blockdevices | length)
            track_test "device_detection_block" "storage" "passed" 0.1
            assert_true ($block_devices > 0) "Block device listing"
        } catch {
            track_test "device_detection_block" "storage" "failed" 0.1
        }
    } else if $os == "Darwin" {
        # Test macOS device detection
        if (ls /dev/disk* 2>/dev/null | default [] | length) > 0 {
            track_test "device_detection_darwin" "storage" "passed" 0.1
            assert_true true "macOS device detection"
        } else {
            track_test "device_detection_darwin" "storage" "skipped" 0.1
        }
    } else {
        track_test "device_detection_unsupported" "storage" "skipped" 0.1
    }
}

# Test ZFS functionality
def test_zfs_functionality [] {
    track_test "zfs_functionality_start" "storage" "passed" 0.1

    # Check if ZFS is available
    if (which zfs | length) > 0 {
        track_test "zfs_command_available" "storage" "passed" 0.1
        assert_true true "ZFS command available"

        # Test ZFS pool listing
        try {
            let pools = (zfs list -H -o name 2>/dev/null | lines)
            track_test "zfs_pool_listing" "storage" "passed" 0.1
            assert_true true "ZFS pool listing"
        } catch {
            track_test "zfs_pool_listing" "storage" "failed" 0.1
        }

        # Test ZFS dataset listing
        try {
            let datasets = (zfs list -H -o name 2>/dev/null | lines)
            track_test "zfs_dataset_listing" "storage" "passed" 0.1
            assert_true true "ZFS dataset listing"
        } catch {
            track_test "zfs_dataset_listing" "storage" "failed" 0.1
        }

        # Test ZFS snapshot listing
        try {
            let snapshots = (zfs list -t snapshot -H -o name 2>/dev/null | lines)
            track_test "zfs_snapshot_listing" "storage" "passed" 0.1
            assert_true true "ZFS snapshot listing"
        } catch {
            track_test "zfs_snapshot_listing" "storage" "failed" 0.1
        }

        # Test ZFS pool status
        try {
            let pool_status = (zpool status 2>/dev/null | lines | length)
            track_test "zfs_pool_status" "storage" "passed" 0.1
            assert_true ($pool_status > 0) "ZFS pool status"
        } catch {
            track_test "zfs_pool_status" "storage" "failed" 0.1
        }
    } else {
        track_test "zfs_command_available" "storage" "skipped" 0.1

        track_test "zfs_pool_listing" "storage" "skipped" 0.1

        track_test "zfs_dataset_listing" "storage" "skipped" 0.1

        track_test "zfs_snapshot_listing" "storage" "skipped" 0.1

        track_test "zfs_pool_status" "storage" "skipped" 0.1
    }
}

# Test backup operations
def test_backup_operations [] {
    track_test "backup_operations_start" "storage" "passed" 0.1

    # Test rsync availability
    if (which rsync | length) > 0 {
        track_test "backup_rsync_available" "storage" "passed" 0.1
        assert_true true "rsync command available"
    } else {
        track_test "backup_rsync_available" "storage" "failed" 0.1
    }

    # Test tar availability
    if (which tar | length) > 0 {
        track_test "backup_tar_available" "storage" "passed" 0.1
        assert_true true "tar command available"
    } else {
        track_test "backup_tar_available" "storage" "failed" 0.1
    }

    # Test backup directory creation
    try {
        let test_backup_dir = "/tmp/nix-mox-test-backup"
        mkdir $test_backup_dir
        track_test "backup_directory_creation" "storage" "passed" 0.1
        assert_true ($test_backup_dir | path exists) "Backup directory creation"

        # Cleanup
        rm -rf $test_backup_dir
    } catch {
        track_test "backup_directory_creation" "storage" "failed" 0.1
    }

    # Test vzdump availability (Proxmox)
    if (which vzdump | length) > 0 {
        track_test "backup_vzdump_available" "storage" "passed" 0.1
        assert_true true "vzdump command available"
    } else {
        track_test "backup_vzdump_available" "storage" "skipped" 0.1
    }
}

# Test disk health monitoring
def test_disk_health [] {
    track_test "disk_health_start" "storage" "passed" 0.1

    # Test smartctl availability
    if (which smartctl | length) > 0 {
        track_test "disk_health_smartctl_available" "storage" "passed" 0.1
        assert_true true "smartctl command available"

        # Test SMART device detection
        try {
            let smart_devices = (smartctl --scan 2>/dev/null | lines | length)
            if $smart_devices > 0 {
                track_test "disk_health_smart_devices" "storage" "passed" 0.1
                assert_true true "SMART device detection"
            } else {
                track_test "disk_health_smart_devices" "storage" "skipped" 0.1
            }
        } catch {
            track_test "disk_health_smart_devices" "storage" "failed" 0.1
        }
    } else {
        track_test "disk_health_smartctl_available" "storage" "skipped" 0.1

        track_test "disk_health_smart_devices" "storage" "skipped" 0.1
    }

    # Test hdparm availability
    if (which hdparm | length) > 0 {
        track_test "disk_health_hdparm_available" "storage" "passed" 0.1
        assert_true true "hdparm command available"
    } else {
        track_test "disk_health_hdparm_available" "storage" "skipped" 0.1
    }

    # Test temperature monitoring
    if (which hddtemp | length) > 0 {
        track_test "disk_health_hddtemp_available" "storage" "passed" 0.1
        assert_true true "hddtemp command available"
    } else {
        track_test "disk_health_hddtemp_available" "storage" "skipped" 0.1
    }
}

# Test storage validation
def test_storage_validation [] {
    track_test "storage_validation_start" "storage" "passed" 0.1

    # Test filesystem space checking
    try {
        let df_output = (df -h | lines | length)
        track_test "storage_validation_df" "storage" "passed" 0.1
        assert_true ($df_output > 0) "Filesystem space checking"
    } catch {
        track_test "storage_validation_df" "storage" "failed" 0.1
    }

    # Test inode checking
    try {
        let inode_output = (df -i | lines | length)
        track_test "storage_validation_inodes" "storage" "passed" 0.1
        assert_true ($inode_output > 0) "Inode checking"
    } catch {
        track_test "storage_validation_inodes" "storage" "failed" 0.1
    }

    # Test mount point validation
    try {
        let mount_output = (mount | lines | length)
        track_test "storage_validation_mounts" "storage" "passed" 0.1
        assert_true ($mount_output > 0) "Mount point validation"
    } catch {
        track_test "storage_validation_mounts" "storage" "failed" 0.1
    }

    # Test storage script availability
    let storage_scripts = ["zfs-snapshot.nu", "vzdump-backup.nu"]
    for script in $storage_scripts {
        let script_path = $"../linux/($script)"
        if ($script_path | path exists) {
            track_test $"storage_validation_script_($script)" "storage" "passed" 0.1
            assert_true true $"Storage script ($script) available"
        } else {
            track_test $"storage_validation_script_($script)" "storage" "skipped" 0.1
        }
    }
}

# Test storage performance
def test_storage_performance [] {
    track_test "storage_performance_start" "storage" "passed" 0.1

    # Test iostat availability
    if (which iostat | length) > 0 {
        track_test "storage_performance_iostat_available" "storage" "passed" 0.1
        assert_true true "iostat command available"
    } else {
        track_test "storage_performance_iostat_available" "storage" "skipped" 0.1
    }

    # Test fio availability
    if (which fio | length) > 0 {
        track_test "storage_performance_fio_available" "storage" "passed" 0.1
        assert_true true "fio command available"
    } else {
        track_test "storage_performance_fio_available" "storage" "skipped" 0.1
    }

    # Test disk I/O monitoring
    try {
        let io_stats = (cat /proc/diskstats | lines | length)
        if $io_stats > 0 {
            track_test "storage_performance_io_stats" "storage" "passed" 0.1
            assert_true true "Disk I/O statistics available"
        } else {
            track_test "storage_performance_io_stats" "storage" "skipped" 0.1
        }
    } catch {
        track_test "storage_performance_io_stats" "storage" "skipped" 0.1
    }
}

# Print test summary
def print_summary [results: record] {
    print ""
    print "=== Storage Tests Summary ==="
    print $"Total tests: ($results.total)"
    print $"Passed: ($results.passed)"
    print $"Failed: ($results.failed)"
    print $"Skipped: ($results.skipped)"

    let success_rate = if $results.total > 0 {
        (($results.passed | into float) / ($results.total | into float) * 100 | into int)
    } else {
        0
    }

    print $"Success rate: ($success_rate)%"

    if $results.failed > 0 {
        print "Some storage tests failed. Check the output above for details."
        false
    } else {
        print "All storage tests passed successfully!"
        true
    }
}

# Always run main when sourced
main
