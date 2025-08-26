#!/usr/bin/env nu
# Comprehensive tests for validators.nu library

use ../../lib/validators.nu *
use ../../lib/logging.nu *
use ../../lib/platform.nu *
use ../lib/test-utils.nu *

# Test validate_command
def test_validate_command [] {
    info "Testing validate_command function" --context "test"
    
    # Test with existing command
    let result = (null | validate_command "ls")
    assert_equal $result.success true "ls command should be valid"
    
    # Test with non-existent command
    let result = (null | validate_command "nonexistentcommand12345")
    assert_equal $result.success false "non-existent command should be invalid"
    
    # Test with another existing command
    let result = (null | validate_command "pwd")
    assert_equal $result.success true "pwd command should be valid"
    
    { success: true, message: "validate_command tests passed" }
}

# Test validate_file
def test_validate_file [] {
    info "Testing validate_file function" --context "test"
    
    # Test with existing file
    let result = (null | validate_file "/etc/passwd")
    assert_equal $result.success true "/etc/passwd should exist"
    
    # Test with non-existent file
    let result = (null | validate_file "/nonexistent/file.txt")
    assert_equal $result.success false "non-existent file should fail validation"
    
    # Test with current script file
    let current_file = ($env.PWD | path join "scripts/testing/unit/validators-tests.nu")
    let result = (null | validate_file $current_file)
    assert_equal $result.success true "current script should exist"
    
    { success: true, message: "validate_file tests passed" }
}

# Test validate_directory
def test_validate_directory [] {
    info "Testing validate_directory function" --context "test"
    
    # Test with existing directory
    let result = (null | validate_directory "/tmp")
    assert_equal $result.success true "/tmp directory should exist"
    
    # Test with non-existent directory
    let result = (null | validate_directory "/nonexistent/directory")
    assert_equal $result.success false "non-existent directory should fail"
    
    # Test with file path (not a directory)
    let result = (null | validate_directory "/etc/passwd")
    assert_equal $result.success false "file path should fail directory validation"
    
    { success: true, message: "validate_directory tests passed" }
}

# Test validate_platform
def test_validate_platform_func [] {
    info "Testing validate_platform function" --context "test"
    
    # Test with current platform
    let platform_info = (get_platform)
    let result = (null | validate_platform [$platform_info.normalized])
    assert_equal $result.success true "current platform should be valid"
    
    # Test with all platforms
    let result = (null | validate_platform ["linux", "darwin", "windows"])
    assert_equal $result.success true "should accept current platform from list"
    
    # Test with invalid platform
    let result = (null | validate_platform ["invalidplatform"])
    assert_equal $result.success false "invalid platform should fail"
    
    { success: true, message: "validate_platform tests passed" }
}

# Test validate_disk_space
def test_validate_disk_space [] {
    info "Testing validate_disk_space function" --context "test"
    
    # Test with high threshold (should pass)
    let result = (null | validate_disk_space 99)
    assert_equal $result.success true "99% threshold should pass on most systems"
    
    # Test with very low threshold (should fail)
    let result = (null | validate_disk_space 1)
    assert_equal $result.success false "1% threshold should fail on most systems"
    
    # Test with reasonable threshold
    let result = (null | validate_disk_space 80)
    assert_true ($result.success in [true, false]) "80% threshold result should be boolean"
    
    { success: true, message: "validate_disk_space tests passed" }
}

# Test validate_memory
def test_validate_memory [] {
    info "Testing validate_memory function" --context "test"
    
    # Test with high threshold (should pass)
    let result = (null | validate_memory 99)
    assert_equal $result.success true "99% memory threshold should pass"
    
    # Test with very low threshold (should fail on busy systems)
    let result = (null | validate_memory 1)
    # This might pass or fail depending on system state
    assert_true ($result.success in [true, false]) "memory validation should return boolean"
    
    { success: true, message: "validate_memory tests passed" }
}

# Test validate_network
def test_validate_network [] {
    info "Testing validate_network function" --context "test"
    
    # Test localhost connectivity
    let result = (null | validate_network "127.0.0.1")
    assert_equal $result.success true "localhost should be reachable"
    
    # Test invalid host
    let result = (null | validate_network "999.999.999.999")
    assert_equal $result.success false "invalid IP should fail"
    
    { success: true, message: "validate_network tests passed" }
}

# Test validate_permission
def test_validate_permission [] {
    info "Testing validate_permission function" --context "test"
    
    # Test readable file
    let result = (null | validate_permission "/etc/passwd" "read")
    assert_equal $result.success true "/etc/passwd should be readable"
    
    # Test writable directory
    let result = (null | validate_permission "/tmp" "write")
    assert_equal $result.success true "/tmp should be writable"
    
    # Test execute permission on directory
    let result = (null | validate_permission "/usr/bin" "execute")
    assert_equal $result.success true "/usr/bin should be executable"
    
    { success: true, message: "validate_permission tests passed" }
}

# Test validate_env_var
def test_validate_env_var [] {
    info "Testing validate_env_var function" --context "test"
    
    # Test existing env var
    let result = (null | validate_env_var "PATH")
    assert_equal $result.success true "PATH should exist"
    
    # Test non-existent env var
    let result = (null | validate_env_var "NONEXISTENT_VAR_12345")
    assert_equal $result.success false "non-existent var should fail"
    
    # Test optional env var
    let result = (null | validate_env_var "OPTIONAL_VAR_12345" --required false)
    assert_equal $result.success true "optional non-existent var should pass"
    
    { success: true, message: "validate_env_var tests passed" }
}

# Test run_validations
def test_run_validations [] {
    info "Testing run_validations batch runner" --context "test"
    
    let validations = [
        { name: "command", validator: {|| validate_command "echo" } },
        { name: "platform", validator: {|| validate_platform ["linux", "darwin", "windows"] } },
        { name: "disk", validator: {|| validate_disk_space 99 } }
    ]
    
    let result = (run_validations $validations --context "test-batch")
    assert_equal $result.success true "all validations should pass"
    assert_equal $result.total 3 "should run 3 validations"
    assert_equal $result.passed 3 "all 3 should pass"
    assert_equal $result.failed 0 "none should fail"
    
    # Test with failing validation
    let validations_with_failure = [
        { name: "good", validator: {|| validation_result true "good" } },
        { name: "bad", validator: {|| validation_result false "bad" } }
    ]
    
    let result = (run_validations $validations_with_failure --context "test-mixed")
    assert_equal $result.success false "should fail with mixed results"
    assert_equal $result.passed 1 "one should pass"
    assert_equal $result.failed 1 "one should fail"
    
    { success: true, message: "run_validations tests passed" }
}

# Test validation_result helper
def test_validation_result [] {
    info "Testing validation_result helper" --context "test"
    
    let success_result = (validation_result true "test passed")
    assert_equal $success_result.success true "success result should be true"
    assert_equal $success_result.message "test passed" "message should match"
    
    let failure_result = (validation_result false "test failed")
    assert_equal $failure_result.success false "failure result should be false"
    assert_equal $failure_result.message "test failed" "message should match"
    
    { success: true, message: "validation_result tests passed" }
}

# Test compose_validators
def test_compose_validators [] {
    info "Testing compose_validators function" --context "test"
    
    let validator1 = {|| validation_result true "v1" }
    let validator2 = {|| validation_result true "v2" }
    
    let composed = (compose_validators [$validator1, $validator2])
    let result = (null | do $composed)
    assert_equal $result.success true "composed validators should pass"
    
    # Test with one failing
    let failing = {|| validation_result false "fail" }
    let composed_fail = (compose_validators [$validator1, $failing])
    let result = (null | do $composed_fail)
    assert_equal $result.success false "composed should fail if any fails"
    
    { success: true, message: "compose_validators tests passed" }
}

# Main test runner
def main [] {
    print "Running validators.nu test suite..."
    
    let test_results = [
        (test_validate_command)
        (test_validate_file)
        (test_validate_directory)
        (test_validate_platform_func)
        (test_validate_disk_space)
        (test_validate_memory)
        (test_validate_network)
        (test_validate_permission)
        (test_validate_env_var)
        (test_run_validations)
        (test_validation_result)
        (test_compose_validators)
    ]
    
    let all_passed = ($test_results | all { |r| $r.success })
    let passed_count = ($test_results | where success == true | length)
    let total_count = ($test_results | length)
    
    if $all_passed {
        success $"All validators.nu tests passed! (($passed_count)/($total_count))" --context "test"
    } else {
        let failed_tests = ($test_results | where success == false)
        error $"Some tests failed: ($failed_tests | length)/($total_count)" --context "test"
        for test in $failed_tests {
            error $"  - ($test.message)" --context "test"
        }
    }
    
    { success: $all_passed, passed: $passed_count, total: $total_count }
}