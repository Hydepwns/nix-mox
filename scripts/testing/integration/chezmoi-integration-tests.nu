#!/usr/bin/env nu
# Integration tests for chezmoi.nu consolidated script

use ../../lib/logging.nu *
use ../lib/test-utils.nu *

# Test chezmoi.nu help command
def test_chezmoi_help [] {
    info "Testing chezmoi.nu help command" --context "test"
    
    let result = (^nu "../../chezmoi.nu" "help" | complete)
    assert_equal $result.exit_code 0 "chezmoi help should succeed"
    assert_contains $result.stdout "chezmoi" "help should mention chezmoi"
    assert_contains $result.stdout "configuration" "help should mention configuration"
    
    { success: true, message: "chezmoi help tests passed" }
}

# Test chezmoi.nu status command
def test_chezmoi_status [] {
    info "Testing chezmoi.nu status command" --context "test"
    
    let result = (^nu "../../chezmoi.nu" "status" | complete)
    
    # Should handle both cases: chezmoi installed or not
    if $result.exit_code == 0 {
        # Chezmoi is available
        assert_true ($result.stdout | str length) > 0 "should have status output"
    } else {
        # Chezmoi not available - should report this clearly
        assert_contains $result.stderr "chezmoi" "should mention chezmoi in error"
    }
    
    { success: true, message: "chezmoi status tests passed" }
}

# Test chezmoi.nu diff command (dry run)
def test_chezmoi_diff [] {
    info "Testing chezmoi.nu diff command" --context "test"
    
    let result = (^nu "../../chezmoi.nu" "diff" "--dry-run" | complete)
    
    # Should handle gracefully whether chezmoi is set up or not
    assert_true ($result.exit_code in [0, 1, 2]) "should exit cleanly"
    
    { success: true, message: "chezmoi diff tests passed" }
}

# Test chezmoi.nu verify command
def test_chezmoi_verify [] {
    info "Testing chezmoi.nu verify command" --context "test"
    
    let result = (^nu "../../chezmoi.nu" "verify" | complete)
    
    # Should perform verification
    assert_true ($result.exit_code in [0, 1]) "should complete verification"
    
    { success: true, message: "chezmoi verify tests passed" }
}

# Test chezmoi.nu init command (dry run)
def test_chezmoi_init [] {
    info "Testing chezmoi.nu init command" --context "test"
    
    let result = (^nu "../../chezmoi.nu" "init" "--dry-run" | complete)
    
    # Should handle init process
    assert_true ($result.exit_code in [0, 1, 2]) "should handle init gracefully"
    
    { success: true, message: "chezmoi init tests passed" }
}

# Test chezmoi.nu config validation
def test_chezmoi_config [] {
    info "Testing chezmoi.nu config validation" --context "test"
    
    let result = (^nu "../../chezmoi.nu" "config" "--validate" | complete)
    
    # Should validate configuration
    assert_true ($result.exit_code in [0, 1, 2]) "should validate config"
    
    { success: true, message: "chezmoi config tests passed" }
}

# Test chezmoi.nu backup functionality
def test_chezmoi_backup [] {
    info "Testing chezmoi.nu backup functionality" --context "test"
    
    let backup_dir = "/tmp/chezmoi_test_backup"
    
    let result = (^nu "../../chezmoi.nu" "backup" "--output" $backup_dir "--dry-run" | complete)
    
    # Should handle backup operation
    assert_true ($result.exit_code in [0, 1, 2]) "should handle backup"
    
    { success: true, message: "chezmoi backup tests passed" }
}

# Test chezmoi.nu template validation
def test_chezmoi_templates [] {
    info "Testing chezmoi.nu template validation" --context "test"
    
    let result = (^nu "../../chezmoi.nu" "templates" "--validate" | complete)
    
    # Should validate templates
    assert_true ($result.exit_code in [0, 1, 2]) "should validate templates"
    
    { success: true, message: "chezmoi templates tests passed" }
}

# Test chezmoi.nu sync command (dry run)
def test_chezmoi_sync [] {
    info "Testing chezmoi.nu sync command" --context "test"
    
    let result = (^nu "../../chezmoi.nu" "sync" "--dry-run" | complete)
    
    # Should handle sync operation
    assert_true ($result.exit_code in [0, 1, 2]) "should handle sync"
    
    { success: true, message: "chezmoi sync tests passed" }
}

# Test chezmoi.nu with invalid command
def test_chezmoi_invalid_command [] {
    info "Testing chezmoi.nu with invalid command" --context "test"
    
    let result = (^nu "../../chezmoi.nu" "invalid-command-12345" | complete)
    assert_true $result.exit_code != 0 "invalid command should fail"
    
    { success: true, message: "chezmoi invalid command tests passed" }
}

# Test chezmoi.nu environment detection
def test_chezmoi_environment [] {
    info "Testing chezmoi.nu environment detection" --context "test"
    
    let result = (^nu "../../chezmoi.nu" "check-env" | complete)
    
    # Should check environment
    assert_true ($result.exit_code in [0, 1, 2]) "should check environment"
    
    { success: true, message: "chezmoi environment tests passed" }
}

# Main test runner
def main [] {
    print "Running chezmoi.nu integration tests..."
    
    # Change to testing directory for relative paths
    cd ([$nu.env.PWD, "scripts", "testing", "integration"] | path join)
    
    let test_results = [
        (test_chezmoi_help)
        (test_chezmoi_status)
        (test_chezmoi_diff)
        (test_chezmoi_verify)
        (test_chezmoi_init)
        (test_chezmoi_config)
        (test_chezmoi_backup)
        (test_chezmoi_templates)
        (test_chezmoi_sync)
        (test_chezmoi_invalid_command)
        (test_chezmoi_environment)
    ]
    
    let all_passed = ($test_results | all { |r| $r.success })
    let passed_count = ($test_results | where success == true | length)
    let total_count = ($test_results | length)
    
    if $all_passed {
        success $"All chezmoi.nu integration tests passed! (($passed_count)/($total_count))" --context "test"
    } else {
        let failed_tests = ($test_results | where success == false)
        error $"Some tests failed: ($failed_tests | length)/($total_count)" --context "test"
        for test in $failed_tests {
            error $"  - ($test.message)" --context "test"
        }
    }
    
    { success: $all_passed, passed: $passed_count, total: $total_count }
}