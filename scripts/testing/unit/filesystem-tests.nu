#!/usr/bin/env nu

# Import unified libraries
use ../../lib/validators.nu
use ../../lib/logging.nu *


# Filesystem operation tests
# Tests for file and directory operations across modules

use ../lib/test-utils.nu *
use ../../lib/logging.nu *
use ../../lib/config.nu *

def main [] {
    print "Running filesystem operation tests..."

    # Set up test environment
    setup_test_env

    # Test basic file operations
    test_basic_file_operations

    # Test directory operations
    test_directory_operations

    # Test permission handling
    test_permission_handling

    # Test file existence checks
    test_file_existence_checks

    # Test config file operations
    test_config_file_operations

    # Test log file operations
    test_log_file_operations

    # Test cleanup operations
    test_cleanup_operations

    print "Filesystem operation tests completed"
}

def test_basic_file_operations [] {
    print "Testing basic file operations..."

    let test_file = "/tmp/nix-mox-test-file-ops.txt"
    let test_content = "Test file content\nLine 2\nLine 3"

    # Test file creation
    try {
        $test_content | save $test_file
        assert_true ($test_file | path exists) "File should be created"
        track_test "filesystem_file_creation" "unit" "passed" 0.1
    } catch {
        track_test "filesystem_file_creation" "unit" "failed" 0.1
    }

    # Test file reading
    try {
        let content = (open $test_file)
        assert_equal $content $test_content "File content should match"
        track_test "filesystem_file_reading" "unit" "passed" 0.1
    } catch {
        track_test "filesystem_file_reading" "unit" "failed" 0.1
    }

    # Test file appending
    try {
        "Additional line" | save --append $test_file
        let updated_content = (open $test_file)
        assert_true ($updated_content | str contains "Additional line") "Should append to file"
        track_test "filesystem_file_appending" "unit" "passed" 0.1
    } catch {
        track_test "filesystem_file_appending" "unit" "failed" 0.1
    }

    # Test file deletion
    try {
        rm $test_file
        assert_false ($test_file | path exists) "File should be deleted"
        track_test "filesystem_file_deletion" "unit" "passed" 0.1
    } catch {
        track_test "filesystem_file_deletion" "unit" "failed" 0.1
    }
}

def test_directory_operations [] {
    print "Testing directory operations..."

    let test_dir = "/tmp/nix-mox-test-dir"
    let nested_dir = $"($test_dir)/nested/deep"

    # Test directory creation
    try {
        mkdir $test_dir
        assert_true ($test_dir | path exists) "Directory should be created"
        track_test "filesystem_directory_creation" "unit" "passed" 0.1
    } catch {
        track_test "filesystem_directory_creation" "unit" "failed" 0.1
    }

    # Test nested directory creation
    try {
        mkdir $nested_dir
        assert_true ($nested_dir | path exists) "Nested directory should be created"
        track_test "filesystem_nested_directory_creation" "unit" "passed" 0.1
    } catch {
        track_test "filesystem_nested_directory_creation" "unit" "failed" 0.1
    }

    # Test directory listing
    try {
        "test1" | save $"($test_dir)/file1.txt"
        "test2" | save $"($test_dir)/file2.txt"
        let files = (ls $test_dir | get name)
        assert_true (($files | length) >= 2) "Should list directory contents"
        track_test "filesystem_directory_listing" "unit" "passed" 0.1
    } catch {
        track_test "filesystem_directory_listing" "unit" "failed" 0.1
    }

    # Test directory deletion
    try {
        rm -rf $test_dir
        assert_false ($test_dir | path exists) "Directory should be deleted"
        track_test "filesystem_directory_deletion" "unit" "passed" 0.1
    } catch {
        track_test "filesystem_directory_deletion" "unit" "failed" 0.1
    }
}

def test_permission_handling [] {
    print "Testing permission handling..."

    let test_file = "/tmp/nix-mox-test-permissions.txt"

    # Test file creation with content
    try {
        "test permissions" | save $test_file
        assert_true ($test_file | path exists) "Permission test file should be created"
        track_test "filesystem_permission_file_creation" "unit" "passed" 0.1
    } catch {
        track_test "filesystem_permission_file_creation" "unit" "failed" 0.1
    }

    # Test readable file
    try {
        let content = (open $test_file)
        assert_true ($content | is-not-empty) "File should be readable"
        track_test "filesystem_file_readable" "unit" "passed" 0.1
    } catch {
        track_test "filesystem_file_readable" "unit" "failed" 0.1
    }

    # Test file_exists function from common.nu
    try {
        let exists = file_exists $test_file
        assert_true $exists "file_exists should return true for existing file"
        track_test "filesystem_file_exists_function" "unit" "passed" 0.1
    } catch {
        track_test "filesystem_file_exists_function" "unit" "failed" 0.1
    }

    # Clean up
    rm -f $test_file
}

def test_file_existence_checks [] {
    print "Testing file existence checks..."

    let existing_file = "/tmp/nix-mox-test-exists.txt"
    let nonexistent_file = "/tmp/nix-mox-test-does-not-exist.txt"

    # Create test file
    "exists" | save $existing_file

    # Test existing file
    try {
        assert_true ($existing_file | path exists) "Existing file should return true"
        assert_true (file_exists $existing_file) "file_exists should work for existing file"
        track_test "filesystem_existing_file_check" "unit" "passed" 0.1
    } catch {
        track_test "filesystem_existing_file_check" "unit" "failed" 0.1
    }

    # Test nonexistent file
    try {
        assert_false ($nonexistent_file | path exists) "Nonexistent file should return false"
        assert_false (file_exists $nonexistent_file) "file_exists should work for nonexistent file"
        track_test "filesystem_nonexistent_file_check" "unit" "passed" 0.1
    } catch {
        track_test "filesystem_nonexistent_file_check" "unit" "failed" 0.1
    }

    # Test directory existence
    let test_dir = "/tmp/nix-mox-test-dir-exists"
    mkdir $test_dir

    try {
        assert_true ($test_dir | path exists) "Existing directory should return true"
        assert_true (dir_exists $test_dir) "dir_exists should work for existing directory"
        track_test "filesystem_directory_exists_check" "unit" "passed" 0.1
    } catch {
        track_test "filesystem_directory_exists_check" "unit" "failed" 0.1
    }

    # Clean up
    rm -f $existing_file
    rm -rf $test_dir
}

def test_config_file_operations [] {
    print "Testing config file operations..."

    let config_file = "/tmp/nix-mox-test-config.json"
    let test_config = {
        logging: {level: "INFO", file: "/tmp/test.log"},
        storage: {pool: "rpool", devices: ["/dev/sda"]},
        performance: {enabled: true}
    }

    # Test config saving
    try {
        save_config $test_config $config_file
        assert_true ($config_file | path exists) "Config file should be saved"
        track_test "filesystem_config_save" "unit" "passed" 0.1
    } catch {
        track_test "filesystem_config_save" "unit" "failed" 0.1
    }

    # Test config loading
    try {
        let loaded_config = load_config_file $config_file
        assert_equal ($loaded_config.logging.level) "INFO" "Config should be loaded correctly"
        track_test "filesystem_config_load" "unit" "passed" 0.1
    } catch {
        track_test "filesystem_config_load" "unit" "failed" 0.1
    }

    # Clean up
    rm -f $config_file
}

def test_log_file_operations [] {
    print "Testing log file operations..."

    let log_file = "/tmp/nix-mox-test-log.txt"

    # Test log file creation and writing
    try {
        info "Test log message" --context "filesystem-test"
        assert_true ($log_file | path exists) "Log file should be created"
        track_test "filesystem_log_file_creation" "unit" "passed" 0.1
    } catch {
        track_test "filesystem_log_file_creation" "unit" "failed" 0.1
    }

    # Test log file content
    try {
        let log_content = (open $log_file)
        assert_true ($log_content | str contains "Test log message") "Log content should be written"
        track_test "filesystem_log_file_content" "unit" "passed" 0.1
    } catch {
        track_test "filesystem_log_file_content" "unit" "failed" 0.1
    }

    # Test log file appending
    try {
        warn "Warning message" --context "filesystem-test"
        let updated_content = (open $log_file)
        assert_true ($updated_content | str contains "Warning message") "Log should append new messages"
        track_test "filesystem_log_file_appending" "unit" "passed" 0.1
    } catch {
        track_test "filesystem_log_file_appending" "unit" "failed" 0.1
    }

    # Clean up
    rm -f $log_file
}

def test_cleanup_operations [] {
    print "Testing cleanup operations..."

    # Create test files and directories
    let cleanup_dir = "/tmp/nix-mox-test-cleanup"
    mkdir $cleanup_dir

    let test_files = [
        $"($cleanup_dir)/file1.txt",
        $"($cleanup_dir)/file2.log",
        $"($cleanup_dir)/file3.tmp"
    ]

    for file in $test_files {
        "cleanup test" | save $file
    }

    # Test that files were created
    try {
        let created_files = ($test_files | where {|f| $f | path exists})
        assert_equal ($created_files | length) 3 "All test files should be created"
        track_test "filesystem_cleanup_setup" "unit" "passed" 0.1
    } catch {
        track_test "filesystem_cleanup_setup" "unit" "failed" 0.1
    }

    # Test ensure_dir function
    let ensure_test_dir = "/tmp/nix-mox-test-ensure"
    try {
        ensure_dir $ensure_test_dir
        assert_true ($ensure_test_dir | path exists) "ensure_dir should create directory"
        track_test "filesystem_ensure_directory" "unit" "passed" 0.1
    } catch {
        track_test "filesystem_ensure_directory" "unit" "failed" 0.1
    }

    # Test bulk cleanup
    try {
        rm -rf $cleanup_dir
        rm -rf $ensure_test_dir
        assert_false ($cleanup_dir | path exists) "Cleanup directory should be removed"
        assert_false ($ensure_test_dir | path exists) "Ensure directory should be removed"
        track_test "filesystem_bulk_cleanup" "unit" "passed" 0.1
    } catch {
        track_test "filesystem_bulk_cleanup" "unit" "failed" 0.1
    }
}

main