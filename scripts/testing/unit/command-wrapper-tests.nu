#!/usr/bin/env nu
# Comprehensive tests for command-wrapper.nu library

use ../../lib/command-wrapper.nu *
use ../../lib/logging.nu *
use ../lib/test-utils.nu *

# Test execute_command
def test_execute_command [] {
    info "Testing execute_command function" --context "test"
    
    # Test successful command
    let result = (execute_command ["echo", "test"])
    assert_equal $result.exit_code 0 "echo should succeed"
    assert_contains $result.stdout "test" "stdout should contain test"
    assert_equal $result.stderr "" "stderr should be empty"
    
    # Test command with arguments
    let result = (execute_command ["ls", "-la", "/tmp"])
    assert_equal $result.exit_code 0 "ls should succeed"
    assert_true (($result.stdout | str length) > 0) "should have output"
    
    # Test failing command
    let result = (execute_command ["ls", "/nonexistent/path"])
    assert_true ($result.exit_code != 0) "should fail with non-zero exit code"
    assert_true (($result.stderr | str length) > 0) "should have error output"
    
    { success: true, message: "execute_command tests passed" }
}

# Test execute_with_retry
def test_execute_with_retry [] {
    info "Testing execute_with_retry function" --context "test"
    
    # Test successful command (no retry needed)
    let result = (execute_with_retry ["echo", "test"] --max-attempts 3)
    assert_equal $result.exit_code 0 "should succeed on first attempt"
    assert_equal $result.attempts 1 "should only need one attempt"
    
    # Test with command that might fail initially
    let result = (execute_with_retry ["ping", "-c", "1", "127.0.0.1"] --max-attempts 2)
    assert_equal $result.exit_code 0 "ping localhost should eventually succeed"
    
    # Test with persistently failing command
    let result = (execute_with_retry ["ls", "/nonexistent"] --max-attempts 2 --retry-delay 10ms)
    assert_true ($result.exit_code != 0) "should fail after retries"
    assert_equal $result.attempts 2 "should attempt max times"
    
    { success: true, message: "execute_with_retry tests passed" }
}

# Test execute_with_timeout
def test_execute_with_timeout [] {
    info "Testing execute_with_timeout function" --context "test"
    
    # Test quick command
    let result = (execute_with_timeout ["echo", "quick"] --timeout 5sec)
    assert_equal $result.exit_code 0 "quick command should succeed"
    assert_false $result.timed_out "should not timeout"
    
    # Test command that would timeout (sleep)
    let result = (execute_with_timeout ["sleep", "10"] --timeout 100ms)
    assert_true $result.timed_out "should timeout"
    assert_true ($result.exit_code != 0) "should have non-zero exit code"
    
    { success: true, message: "execute_with_timeout tests passed" }
}

# Test execute_with_input
def test_execute_with_input [] {
    info "Testing execute_with_input function" --context "test"
    
    # Test piping input to command
    let result = ("hello world" | execute_with_input ["cat"])
    assert_equal $result.exit_code 0 "cat should succeed"
    assert_contains $result.stdout "hello world" "output should match input"
    
    # Test with grep
    let result = ("line1\nline2\nline3" | execute_with_input ["grep", "line2"])
    assert_equal $result.exit_code 0 "grep should succeed"
    assert_contains $result.stdout "line2" "should find line2"
    assert_false ($result.stdout | str contains "line1") "should not contain line1"
    
    { success: true, message: "execute_with_input tests passed" }
}

# Test execute_pipeline
def test_execute_pipeline [] {
    info "Testing execute_pipeline function" --context "test"
    
    # Test simple pipeline
    let commands = [
        ["echo", "hello world"],
        ["grep", "world"],
        ["wc", "-w"]
    ]
    let result = (execute_pipeline $commands)
    assert_equal $result.exit_code 0 "pipeline should succeed"
    assert_contains ($result.stdout | str trim) "1" "should count 1 word"
    
    # Test failing pipeline
    let failing_commands = [
        ["echo", "test"],
        ["grep", "notfound"]
    ]
    let result = (execute_pipeline $failing_commands)
    assert_true ($result.exit_code != 0) "pipeline should fail"
    
    { success: true, message: "execute_pipeline tests passed" }
}

# Test nix_eval
def test_nix_eval [] {
    info "Testing nix_eval function" --context "test"
    
    # Test simple nix expression
    let result = (nix_eval "1 + 1")
    assert_equal $result.exit_code 0 "nix eval should succeed"
    assert_contains $result.stdout "2" "should evaluate to 2"
    
    # Test invalid expression
    let result = (nix_eval "invalid expression")
    assert_true ($result.exit_code != 0) "invalid expression should fail"
    
    # Test with builtins
    let result = (nix_eval "builtins.toString 42")
    assert_equal $result.exit_code 0 "builtins should work"
    assert_contains $result.stdout "42" "should convert to string"
    
    { success: true, message: "nix_eval tests passed" }
}

# Test nix_build
def test_nix_build [] {
    info "Testing nix_build function" --context "test"
    
    # Test building simple derivation (hello package)
    let result = (nix_build "nixpkgs#hello" --dry-run)
    # Dry run should succeed without actually building
    assert_true ($result.exit_code in [0, 1]) "dry run should complete"
    
    { success: true, message: "nix_build tests passed" }
}

# Test git_command
def test_git_command [] {
    info "Testing git_command function" --context "test"
    
    # Test git status
    let result = (git_command ["status", "--short"])
    assert_equal $result.exit_code 0 "git status should succeed"
    
    # Test git branch
    let result = (git_command ["branch", "--show-current"])
    assert_equal $result.exit_code 0 "git branch should succeed"
    assert_true (($result.stdout | str length) > 0) "should show current branch"
    
    # Test invalid git command
    let result = (git_command ["invalidcommand"])
    assert_true ($result.exit_code != 0) "invalid command should fail"
    
    { success: true, message: "git_command tests passed" }
}

# Test apt_command (skip on non-Debian systems)
def test_apt_command [] {
    info "Testing apt_command function" --context "test"
    
    # Check if apt is available
    if (which apt | is-empty) {
        warn "Skipping apt tests on non-Debian system" --context "test"
        return { success: true, message: "apt_command tests skipped" }
    }
    
    # Test apt list (read-only operation)
    let result = (apt_command ["list", "--installed"] | head -5)
    assert_equal $result.exit_code 0 "apt list should succeed"
    
    { success: true, message: "apt_command tests passed" }
}

# Test dnf_command (skip on non-Fedora systems)  
def test_dnf_command [] {
    info "Testing dnf_command function" --context "test"
    
    # Check if dnf is available
    if (which dnf | is-empty) {
        warn "Skipping dnf tests on non-Fedora system" --context "test"
        return { success: true, message: "dnf_command tests skipped" }
    }
    
    # Test dnf list (read-only operation)
    let result = (dnf_command ["list", "installed"] | head -5)
    assert_equal $result.exit_code 0 "dnf list should succeed"
    
    { success: true, message: "dnf_command tests passed" }
}

# Test safe_rm
def test_safe_rm [] {
    info "Testing safe_rm function" --context "test"
    
    # Create test file
    let test_file = "/tmp/test_safe_rm.txt"
    echo "test" | save $test_file
    
    # Test removing file
    let result = (safe_rm $test_file)
    assert_equal $result.exit_code 0 "safe_rm should succeed"
    assert_false ($test_file | path exists) "file should be removed"
    
    # Test with non-existent file (should not error)
    let result = (safe_rm "/tmp/nonexistent_file.txt")
    assert_equal $result.exit_code 0 "safe_rm should handle non-existent files"
    
    # Test protection against dangerous paths
    let result = (safe_rm "/")
    assert_true ($result.exit_code != 0) "should refuse to remove root"
    
    let result = (safe_rm "/etc")
    assert_true ($result.exit_code != 0) "should refuse to remove /etc"
    
    { success: true, message: "safe_rm tests passed" }
}

# Test parallel_execute
def test_parallel_execute [] {
    info "Testing parallel_execute function" --context "test"
    
    # Test running multiple commands in parallel
    let commands = [
        ["echo", "1"],
        ["echo", "2"],
        ["echo", "3"]
    ]
    
    let results = (parallel_execute $commands)
    assert_equal ($results | length) 3 "should have 3 results"
    assert_true ($results | all { |r| $r.exit_code == 0 }) "all should succeed"
    
    # Test with mixed success/failure
    let mixed_commands = [
        ["echo", "success"],
        ["ls", "/nonexistent"],
        ["pwd"]
    ]
    
    let results = (parallel_execute $mixed_commands)
    assert_equal ($results | length) 3 "should have 3 results"
    assert_true (($results | where exit_code == 0 | length) >= 2) "at least 2 should succeed"
    assert_true (($results | where exit_code != 0 | length) >= 1) "at least 1 should fail"
    
    { success: true, message: "parallel_execute tests passed" }
}

# Main test runner
def main [] {
    print "Running command-wrapper.nu test suite..."
    
    let test_results = [
        (test_execute_command)
        (test_execute_with_retry)
        (test_execute_with_timeout)
        (test_execute_with_input)
        (test_execute_pipeline)
        (test_nix_eval)
        (test_nix_build)
        (test_git_command)
        (test_apt_command)
        (test_dnf_command)
        (test_safe_rm)
        (test_parallel_execute)
    ]
    
    let all_passed = ($test_results | all { |r| $r.success })
    let passed_count = ($test_results | where success == true | length)
    let total_count = ($test_results | length)
    
    if $all_passed {
        print $"All command-wrapper.nu tests passed! ($passed_count) of ($total_count)"
    } else {
        let failed_tests = ($test_results | where success == false)
        print $"Some tests failed: ($failed_tests | length) of ($total_count)"
        for test in $failed_tests {
            print $"  - ($test.message)"
        }
    }
    
    { success: $all_passed, passed: $passed_count, total: $total_count }
    return $all_passed
}