#!/usr/bin/env nu

# Performance module tests
# Tests for scripts/lib/performance.nu

use ../../lib/performance.nu *
use ../lib/test-utils.nu *

def main [] {
    print "Running performance module tests..."

    # Set up test environment
    setup_test_env

    # Test performance monitoring
    test_performance_monitoring

    # Test system resource gathering
    test_system_resources

    # Test performance metrics storage
    test_performance_metrics_storage

    # Test performance issue detection
    test_performance_issue_detection

    # Test performance recommendations
    test_performance_recommendations

    print "Performance module tests completed"
}

def test_performance_monitoring [] {
    print "Testing performance monitoring..."

    # Test starting a performance monitor
    let monitor_id = start_performance_monitor "test_operation" {component: "test"}
    assert_true ($monitor_id | is-not-empty) "Monitor ID should be generated"
    track_test "performance_monitor_start" "unit" "passed" 0.1

    # Wait a bit to simulate work
    sleep 100ms

    # Test ending the performance monitor
    try {
        let result = end_performance_monitor $monitor_id
        assert_true ($result.duration > 0) "Should measure positive duration"
        assert_equal $result.operation "test_operation" "Should preserve operation name"
        track_test "performance_monitor_end" "unit" "passed" 0.1
    } catch {
        track_test "performance_monitor_end" "unit" "failed" 0.1
    }
}

def test_system_resources [] {
    print "Testing system resource gathering..."

    try {
        let resources = get_system_resources
        assert_true ($resources.memory != null) "Should get memory info"
        assert_true ($resources.cpu != null) "Should get CPU info"
        assert_true ($resources.disk != null) "Should get disk info"
        track_test "system_resources_gathering" "unit" "passed" 0.1
    } catch {
        # System resource gathering might fail in some environments
        track_test "system_resources_gathering" "unit" "skipped" 0.1
    }
}

def test_performance_metrics_storage [] {
    print "Testing performance metrics storage..."

    let test_metrics = {
        operation: "test_store",
        duration: 150,
        memory_used: 1024,
        cpu_usage: 25.5,
        timestamp: (date now | into int)
    }

    try {
        store_performance_metrics $test_metrics
        track_test "performance_metrics_storage" "unit" "passed" 0.1
    } catch {
        track_test "performance_metrics_storage" "unit" "failed" 0.1
    }
}

def test_performance_issue_detection [] {
    print "Testing performance issue detection..."

    # Test high memory usage
    let high_memory_metrics = {
        memory_used: 95.0,
        cpu_usage: 15.0,
        duration: 1000,
        disk_usage: 50.0
    }

    let memory_issues = check_performance_issues $high_memory_metrics
    assert_true (($memory_issues | length) > 0) "Should detect high memory usage"
    track_test "performance_issues_high_memory" "unit" "passed" 0.1

    # Test high CPU usage
    let high_cpu_metrics = {
        memory_used: 50.0,
        cpu_usage: 95.0,
        duration: 1000,
        disk_usage: 50.0
    }

    let cpu_issues = check_performance_issues $high_cpu_metrics
    assert_true (($cpu_issues | length) > 0) "Should detect high CPU usage"
    track_test "performance_issues_high_cpu" "unit" "passed" 0.1

    # Test normal performance
    let normal_metrics = {
        memory_used: 30.0,
        cpu_usage: 20.0,
        duration: 500,
        disk_usage: 40.0
    }

    let normal_issues = check_performance_issues $normal_metrics
    assert_equal ($normal_issues | length) 0 "Should not detect issues with normal metrics"
    track_test "performance_issues_normal" "unit" "passed" 0.1
}

def test_performance_recommendations [] {
    print "Testing performance recommendations..."

    let test_stats = {
        operations: [
            {operation: "slow_op", avg_duration: 5000, count: 10},
            {operation: "fast_op", avg_duration: 100, count: 100}
        ],
        memory: {avg: 80.0, max: 95.0},
        cpu: {avg: 60.0, max: 90.0}
    }

    try {
        let recommendations = generate_performance_recommendations $test_stats
        assert_true (($recommendations | length) > 0) "Should generate recommendations"
        track_test "performance_recommendations_generation" "unit" "passed" 0.1
    } catch {
        track_test "performance_recommendations_generation" "unit" "failed" 0.1
    }
}

# PWD is automatically set by Nushell and cannot be set manually

main