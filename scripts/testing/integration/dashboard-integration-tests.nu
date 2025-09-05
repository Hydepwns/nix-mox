#!/usr/bin/env nu
# Integration tests for dashboard.nu consolidated script

use ../../lib/logging.nu *
use ../lib/test-utils.nu *

# Test dashboard.nu help command
def test_dashboard_help [] {
    info "Testing dashboard.nu help command" --context "test"
    
    let result = (^nu "../../dashboard.nu" "help" | complete)
    assert_equal $result.exit_code 0 "dashboard help should succeed"
    assert_contains $result.stdout "dashboard" "help should mention dashboard"
    assert_contains $result.stdout "system" "help should mention system monitoring"
    
    { success: true, message: "dashboard help tests passed" }
}

# Test dashboard.nu system overview (quick mode)
def test_dashboard_system_overview [] {
    info "Testing dashboard.nu system overview" --context "test"
    
    let result = (^nu "../../dashboard.nu" "system" "--quick" | complete)
    assert_equal $result.exit_code 0 "system overview should succeed"
    
    # Should contain basic system info
    assert_contains $result.stdout "CPU" "should show CPU info"
    assert_contains $result.stdout "Memory" "should show memory info"
    assert_contains $result.stdout "Disk" "should show disk info"
    
    { success: true, message: "dashboard system overview tests passed" }
}

# Test dashboard.nu performance metrics
def test_dashboard_performance [] {
    info "Testing dashboard.nu performance metrics" --context "test"
    
    let result = (^nu "../../dashboard.nu" "performance" "--snapshot" | complete)
    assert_equal $result.exit_code 0 "performance metrics should succeed"
    
    # Should show performance data
    assert_contains $result.stdout "%" "should show percentage values"
    
    { success: true, message: "dashboard performance tests passed" }
}

# Test dashboard.nu security status
def test_dashboard_security [] {
    info "Testing dashboard.nu security status" --context "test"
    
    let result = (^nu "../../dashboard.nu" "security" "--quick" | complete)
    assert_equal $result.exit_code 0 "security status should succeed"
    
    # Should show security information
    assert_true ($result.stdout | str length) > 0 "should have security output"
    
    { success: true, message: "dashboard security tests passed" }
}

# Test dashboard.nu network status
def test_dashboard_network [] {
    info "Testing dashboard.nu network status" --context "test"
    
    let result = (^nu "../../dashboard.nu" "network" "--brief" | complete)
    assert_equal $result.exit_code 0 "network status should succeed"
    
    # Should show network interfaces
    assert_contains $result.stdout "lo" "should show loopback interface"
    
    { success: true, message: "dashboard network tests passed" }
}

# Test dashboard.nu processes view
def test_dashboard_processes [] {
    info "Testing dashboard.nu processes view" --context "test"
    
    let result = (^nu "../../dashboard.nu" "processes" "--limit" "5" | complete)
    assert_equal $result.exit_code 0 "processes view should succeed"
    
    # Should show process information
    assert_contains $result.stdout "PID" "should show process IDs"
    
    { success: true, message: "dashboard processes tests passed" }
}

# Test dashboard.nu export functionality
def test_dashboard_export [] {
    info "Testing dashboard.nu export functionality" --context "test"
    
    let export_file = "/tmp/dashboard_test_export.json"
    
    let result = (^nu "../../dashboard.nu" "export" "--format" "json" "--output" $export_file | complete)
    assert_equal $result.exit_code 0 "export should succeed"
    
    # Check if export file was created
    if ($export_file | path exists) {
        let content = (open $export_file | from json)
        assert_true ("timestamp" in ($content | columns)) "export should have timestamp"
        
        # Clean up
        rm $export_file
    }
    
    { success: true, message: "dashboard export tests passed" }
}

# Test dashboard.nu with invalid command
def test_dashboard_invalid_command [] {
    info "Testing dashboard.nu with invalid command" --context "test"
    
    let result = (^nu "../../dashboard.nu" "invalid-command-12345" | complete)
    assert_true $result.exit_code != 0 "invalid command should fail"
    
    { success: true, message: "dashboard invalid command tests passed" }
}

# Test dashboard.nu configuration validation
def test_dashboard_config [] {
    info "Testing dashboard.nu configuration" --context "test"
    
    let result = (^nu "../../dashboard.nu" "config" "--validate" | complete)
    
    # Should not crash
    assert_true ($result.exit_code in [0, 1, 2]) "should handle config validation gracefully"
    
    { success: true, message: "dashboard config tests passed" }
}

# Main test runner
def main [] {
    print "Running dashboard.nu integration tests..."
    
    # Change to testing directory for relative paths
    cd ([$nu.env.PWD, "scripts", "testing", "integration"] | path join)
    
    let test_results = [
        (test_dashboard_help)
        (test_dashboard_system_overview)
        (test_dashboard_performance)
        (test_dashboard_security)
        (test_dashboard_network)
        (test_dashboard_processes)
        (test_dashboard_export)
        (test_dashboard_invalid_command)
        (test_dashboard_config)
    ]
    
    let all_passed = ($test_results | all { | r| $r.success })
    let passed_count = ($test_results | where success == true | length)
    let total_count = ($test_results | length)
    
    if $all_passed {
        success $"All dashboard.nu integration tests passed! (($passed_count)/($total_count))" --context "test"
    } else {
        let failed_tests = ($test_results | where success == false)
        error $"Some tests failed: ($failed_tests | length)/($total_count)" --context "test"
        for test in $failed_tests {
            error $"  - ($test.message)" --context "test"
        }
    }
    
    { success: $all_passed, passed: $passed_count, total: $total_count }
}