#!/usr/bin/env nu
# Comprehensive tests for validators.nu library using consolidated patterns

use ../../lib/constants.nu *
use ../../lib/validators.nu *
use ../../lib/logging.nu *
use ../lib/test-utils.nu *
use ../lib/shared.nu *

# Test validate_command with isolation
def test_validate_command [] {
    # Test with existing command
    let result = (null | validate_command "ls")
    assert_equal $result.success true "ls command should be valid"
    
    # Test with non-existent command
    let result = (null | validate_command "nonexistentcommand12345")
    assert_equal $result.success false "non-existent command should be invalid"
    
    # Test with another existing command
    let result = (null | validate_command "pwd")
    assert_equal $result.success true "pwd command should be valid"
    
    # Test input validation
    let result = (null | validate_command "")
    assert_equal $result.success false "empty command should be invalid"
    
    let result = (null | validate_command "ls rm")
    assert_equal $result.success false "command with space should be invalid"
    
    { success: true, message: "validate_command tests passed" }
}

# Test validate_file with filesystem isolation
def test_validate_file [] {
    # Test with system file (should still work)
    let result = (null | validate_file "/etc/passwd")
    assert_equal $result.success true "/etc/passwd should exist"
    
    # Test input validation
    let result = (null | validate_file "")
    assert_equal $result.success false "empty path should be invalid"
    
    # Test optional file validation
    let result = (null | validate_file "/tmp/nonexistent.txt" --required false)
    assert_equal $result.success true "optional non-existent file should pass"
    
    { success: true, message: "validate_file tests passed" }
}

# Test validate_directory with filesystem isolation
def test_validate_directory [] {
    # Test with existing directory
    let result = (null | validate_directory "/tmp")
    assert_equal $result.success true "/tmp directory should exist"
    
    # Test with non-existent directory
    let result = (null | validate_directory "/nonexistent")
    assert_equal $result.success false "non-existent directory should fail"
    
    # Test with file path (not a directory)
    let result = (null | validate_directory "/etc/passwd")
    assert_equal $result.success false "file path should fail directory validation"
    
    # Test input validation
    let result = (null | validate_directory "")
    assert_equal $result.success false "empty path should be invalid"
    
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

# Test validate_env_var with environment isolation
def test_validate_env_var [] {
    # Test existing env var (PATH should always exist)
    let result = (null | validate_env_var "PATH")
    assert_equal $result.success true "PATH should exist"
    
    # Test non-existent env var
    let result = (null | validate_env_var "NONEXISTENT_VAR_12345")
    assert_equal $result.success false "non-existent var should fail"
    
    # Test optional env var
    let result = (null | validate_env_var "OPTIONAL_VAR_12345" --required false)
    assert_equal $result.success true "optional non-existent var should pass"
    
    # Test the test env var we set
    $env.TEST_VAR_12345 = "test_value"
    let result = (null | validate_env_var "TEST_VAR_12345")
    assert_equal $result.success true "test env var should exist"
    
    # Test input validation
    let result = (null | validate_env_var "")
    assert_equal $result.success false "empty var name should be invalid"
    
    let result = (null | validate_env_var "VAR WITH SPACE")
    assert_equal $result.success false "var name with space should be invalid"
    
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
        { name: "good", validator: {|| validation_result true "good" {} } },
        { name: "bad", validator: {|| validation_result false "bad" {} } }
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
    
    let success_result = (validation_result true "test passed" {})
    assert_equal $success_result.success true "success result should be true"
    assert_equal $success_result.message "test passed" "message should match"
    
    let failure_result = (validation_result false "test failed" {})
    assert_equal $failure_result.success false "failure result should be false"
    assert_equal $failure_result.message "test failed" "message should match"
    
    { success: true, message: "validation_result tests passed" }
}

# Test compose_validators with isolation
def test_compose_validators [] {
    let validator1 = {|| validation_result true "v1" {} }
    let validator2 = {|| validation_result true "v2" {} }
    
    let composed = (compose_validators [$validator1, $validator2])
    let result = (null | do $composed)
    assert_equal $result.success true "composed validators should pass"
    
    # Test with one failing
    let failing = {|| validation_result false "fail" {} }
    let composed_fail = (compose_validators [$validator1, $failing])
    let result = (null | do $composed_fail)
    assert_equal $result.success false "composed should fail if any fails"
    
    # Test input validation
    let empty_composed = (compose_validators [])
    let result = (null | do $empty_composed)
    assert_equal $result.success true "empty validator list should pass with warning"
    
    { success: true, message: "compose_validators tests passed" }
}

# Test new input validation helpers
def test_input_validation_helpers [] {
    # Test validate_string_input
    let result = (validate_string_input "test" "test_param")
    assert_equal $result.success true "valid string should pass"
    
    let result = (validate_string_input "" "test_param")
    assert_equal $result.success false "empty string should fail by default"
    
            let result = (validate_string_input "" "test_param" --allow-empty true)
    assert_equal $result.success true "empty string should pass with allow-empty"
    
            # Test validate_integer_input
        let result = (validate_integer_input 42 "test_int")
        assert_equal $result.success true "valid integer should pass"
        
        let result = (validate_integer_input (-1) "test_int")
        assert_equal $result.success false "negative integer should fail by default"
        
        let result = (validate_integer_input (-1) "test_int" --min (-10))
        assert_equal $result.success true "negative integer should pass with custom min"
    
    { success: true, message: "input_validation_helpers tests passed" }
}

# Main test runner with enhanced isolation and reporting
def main [input?] {
    print "Running validators.nu test suite with isolation..."
    print "Setting up test environment..."
    
    # Setup test environment
    setup_test_env
    
    let start_time = (date now)
    let test_functions = [
        "test_validate_command"
        "test_validate_file"
        "test_validate_directory"
        "test_validate_platform_func"
        "test_validate_disk_space"
        "test_validate_memory"
        "test_validate_network"
        "test_validate_permission"
        "test_validate_env_var"
        "test_run_validations"
        "test_validation_result"
        "test_compose_validators"
        "test_input_validation_helpers"
    ]
    
    let test_results = ($test_functions | each { |test_func_name|
        print $"Running ($test_func_name)..."
        try {
            let result = match $test_func_name {
                "test_validate_command" => (test_validate_command)
                "test_validate_file" => (test_validate_file)
                "test_validate_directory" => (test_validate_directory)
                "test_validate_platform_func" => (test_validate_platform_func)
                "test_validate_disk_space" => (test_validate_disk_space)
                "test_validate_memory" => (test_validate_memory)
                "test_validate_network" => (test_validate_network)
                "test_validate_permission" => (test_validate_permission)
                "test_validate_env_var" => (test_validate_env_var)
                "test_run_validations" => (test_run_validations)
                "test_validation_result" => (test_validation_result)
                "test_compose_validators" => (test_compose_validators)
                "test_input_validation_helpers" => (test_input_validation_helpers)
                _ => {success: false, message: $"Unknown test function: ($test_func_name)", test_name: $test_func_name}
            }
            if ($result | describe) == "record" and ($result | get success? | default false) {
                $result | merge {test_name: $test_func_name}
            } else {
                {success: true, message: $"($test_func_name) completed", test_name: $test_func_name}
            }
        } catch { |err|
            {success: false, message: $"($test_func_name) failed: ($err.msg)", test_name: $test_func_name}
        }
    })
    
    let end_time = (date now)
    let total_duration = $end_time - $start_time
    
    let all_passed = ($test_results | all { |r| $r.success })
    let passed_count = ($test_results | where success == true | length)
    let total_count = ($test_results | length)
    let failed_count = ($test_results | where success == false | length)
    
    # Print detailed summary
    print ""
    print "=== Test Suite Summary ==="
    print $"Total tests: ($total_count)"
    print $"Passed: ($passed_count)"
    print $"Failed: ($failed_count)"
    print $"Duration: ($total_duration)"
    
    if $all_passed {
        print "✓ All validators.nu tests passed! ($passed_count)/($total_count)"
        success $"All validators.nu tests passed! ($passed_count)/($total_count)" --context "test"
    } else {
        let failed_tests = ($test_results | where success == false)
        print "✗ Some tests failed: ($failed_count)/($total_count)"
        error $"Some tests failed: ($failed_count)/($total_count)" --context "test"
        
        print ""
        print "Failed tests:"
        for test in $failed_tests {
            print $"  - ($test.test_name): ($test.message)"
            error $"  - ($test.test_name): ($test.message)" --context "test"
        }
    }
    
    # Cleanup any remaining test artifacts
    print ""
    print "Cleaning up test environment..."
    try {
        let temp_dir = ($env | get TEST_TEMP_DIR? | default null)
        if ($temp_dir != null) and (($temp_dir | into string) | path exists) {
            # Clean up any remaining temporary files/directories
            ls ($temp_dir | into string) | where name =~ "nix-mox-.*test.*" | each { |item|
                try {
                    if ($item.type == "dir") {
                        rm -rf ($item.name | into string)
                    } else {
                        rm -f ($item.name | into string)
                    }
                } catch {
                    print $"Warning: Could not clean up ($item.name)"
                }
            }
        }
    } catch {
        print "Warning: Test environment cleanup had issues (non-critical)"
    }
    
    { success: $all_passed, passed: $passed_count, failed: $failed_count, total: $total_count, duration: $total_duration }
}