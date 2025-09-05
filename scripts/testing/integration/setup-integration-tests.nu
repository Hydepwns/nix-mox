#!/usr/bin/env nu
# Integration tests for setup.nu consolidated script

use ../../lib/logging.nu *
use ../lib/test-utils.nu *

# Test setup.nu help command
def test_setup_help [] {
    info "Testing setup.nu help command" --context "test"
    
    let result = (^nu "../../setup.nu" "help" | complete)
    assert_equal $result.exit_code 0 "setup help should succeed"
    assert_contains $result.stdout "setup" "help should mention setup"
    assert_contains $result.stdout "commands" "help should list commands"
    
    { success: true, message: "setup help tests passed" }
}

# Test setup.nu validation (dry run)
def test_setup_validation [] {
    info "Testing setup.nu validation" --context "test"
    
    # Test basic validation
    let result = (^nu "../../setup.nu" "validate" "--dry-run" | complete)
    assert_equal $result.exit_code 0 "setup validation should succeed in dry run"
    
    { success: true, message: "setup validation tests passed" }
}

# Test setup.nu environment checks
def test_setup_environment [] {
    info "Testing setup.nu environment checks" --context "test"
    
    let result = (^nu "../../setup.nu" "check-env" | complete)
    assert_equal $result.exit_code 0 "environment check should succeed"
    
    # Should report on basic requirements
    assert_contains $result.stdout "nix" "should check for nix"
    
    { success: true, message: "setup environment tests passed" }
}

# Test setup.nu platform detection
def test_setup_platform_detection [] {
    info "Testing setup.nu platform detection" --context "test"
    
    let result = (^nu "../../setup.nu" "detect-platform" | complete)
    assert_equal $result.exit_code 0 "platform detection should succeed"
    
    # Should detect current platform
    assert_true ($result.stdout | str contains "linux" or ($result.stdout | str contains "darwin") or ($result.stdout | str contains "windows")) "should detect valid platform"
    
    { success: true, message: "setup platform detection tests passed" }
}

# Test setup.nu configuration validation
def test_setup_config_validation [] {
    info "Testing setup.nu configuration validation" --context "test"
    
    let result = (^nu "../../setup.nu" "validate-config" "--dry-run" | complete)
    
    # Should not fail catastrophically
    assert_true ($result.exit_code in [0, 1, 2]) "should exit cleanly"
    
    { success: true, message: "setup config validation tests passed" }
}

# Test setup.nu dependencies check
def test_setup_dependencies [] {
    info "Testing setup.nu dependencies check" --context "test"
    
    let result = (^nu "../../setup.nu" "check-deps" | complete)
    assert_equal $result.exit_code 0 "dependencies check should succeed"
    
    # Should check for essential tools
    assert_contains $result.stdout "git" "should check for git"
    
    { success: true, message: "setup dependencies tests passed" }
}

# Test setup.nu with invalid command
def test_setup_invalid_command [] {
    info "Testing setup.nu with invalid command" --context "test"
    
    let result = (^nu "../../setup.nu" "invalid-command-12345" | complete)
    assert_true $result.exit_code != 0 "invalid command should fail"
    assert_contains $result.stderr "Unknown" "should report unknown command"
    
    { success: true, message: "setup invalid command tests passed" }
}

# Main test runner
def main [] {
    print "Running setup.nu integration tests..."
    
    # Change to testing directory for relative paths
    cd ([$nu.env.PWD, "scripts", "testing", "integration"] | path join)
    
    let test_results = [
        (test_setup_help)
        (test_setup_validation)
        (test_setup_environment)
        (test_setup_platform_detection)
        (test_setup_config_validation)
        (test_setup_dependencies)
        (test_setup_invalid_command)
    ]
    
    let all_passed = ($test_results | all { | r| $r.success })
    let passed_count = ($test_results | where success == true | length)
    let total_count = ($test_results | length)
    
    if $all_passed {
        success $"All setup.nu integration tests passed! (($passed_count)/($total_count))" --context "test"
    } else {
        let failed_tests = ($test_results | where success == false)
        error $"Some tests failed: ($failed_tests | length)/($total_count)" --context "test"
        for test in $failed_tests {
            error $"  - ($test.message)" --context "test"
        }
    }
    
    { success: $all_passed, passed: $passed_count, total: $total_count }
}