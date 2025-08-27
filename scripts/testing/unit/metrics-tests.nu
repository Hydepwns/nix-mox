#!/usr/bin/env nu
# Unit tests for metrics.nu library
# Tests real-time metrics collection and Prometheus integration

use ../../lib/metrics.nu *
use ../../lib/validators.nu *
use ../../lib/logging.nu *

# Test metric creation functions
export def test_create_counter [] {
    info "Testing create_counter function" --context "metrics-test"
    
    let counter = (create_counter "test_counter" "Test counter metric")
    
    # Validate counter structure
    let expected_fields = ["type", "name", "help", "labels", "value", "created_at"]
    for field in $expected_fields {
        if not ($field in $counter) {
            error $"Counter missing field: ($field)" --context "metrics-test"
            return false
        }
    }
    
    # Validate field values
    if $counter.type != "counter" {
        error $"Expected counter type, got ($counter.type)" --context "metrics-test"
        return false
    }
    
    if $counter.name != "test_counter" {
        error $"Expected name 'test_counter', got ($counter.name)" --context "metrics-test"
        return false
    }
    
    if $counter.value != 0 {
        error $"Expected initial value 0, got ($counter.value)" --context "metrics-test"
        return false
    }
    
    success "create_counter test passed" --context "metrics-test"
    return true
}

export def test_create_gauge [] {
    info "Testing create_gauge function" --context "metrics-test"
    
    let gauge = (create_gauge "test_gauge" "Test gauge metric")
    
    # Validate gauge structure
    let expected_fields = ["type", "name", "help", "labels", "value", "updated_at"]
    for field in $expected_fields {
        if not ($field in $gauge) {
            error $"Gauge missing field: ($field)" --context "metrics-test"
            return false
        }
    }
    
    # Validate field values
    if $gauge.type != "gauge" {
        error $"Expected gauge type, got ($gauge.type)" --context "metrics-test"
        return false
    }
    
    if $gauge.name != "test_gauge" {
        error $"Expected name 'test_gauge', got ($gauge.name)" --context "metrics-test"
        return false
    }
    
    success "create_gauge test passed" --context "metrics-test"
    return true
}

export def test_create_histogram [] {
    info "Testing create_histogram function" --context "metrics-test"
    
    let histogram = (create_histogram "test_histogram" "Test histogram metric")
    
    # Validate histogram structure
    let expected_fields = ["type", "name", "help", "buckets", "counts", "sum", "count"]
    for field in $expected_fields {
        if not ($field in $histogram) {
            error $"Histogram missing field: ($field)" --context "metrics-test"
            return false
        }
    }
    
    # Validate field values
    if $histogram.type != "histogram" {
        error $"Expected histogram type, got ($histogram.type)" --context "metrics-test"
        return false
    }
    
    if ($histogram.buckets | length) == 0 {
        error "Histogram should have default buckets" --context "metrics-test"
        return false
    }
    
    if ($histogram.counts | length) != ($histogram.buckets | length) {
        error "Histogram counts should match buckets length" --context "metrics-test"
        return false
    }
    
    success "create_histogram test passed" --context "metrics-test"
    return true
}

export def test_metric_with_labels [] {
    info "Testing metrics with labels" --context "metrics-test"
    
    let labels = { service: "nix-mox", environment: "test" }
    let counter = (create_counter "labeled_counter" "Counter with labels" $labels)
    
    if $counter.labels.service != "nix-mox" {
        error $"Expected service label 'nix-mox', got ($counter.labels.service)" --context "metrics-test"
        return false
    }
    
    if $counter.labels.environment != "test" {
        error $"Expected environment label 'test', got ($counter.labels.environment)" --context "metrics-test"
        return false
    }
    
    success "metric labels test passed" --context "metrics-test"
    return true
}

export def test_custom_histogram_buckets [] {
    info "Testing custom histogram buckets" --context "metrics-test"
    
    let custom_buckets = [0.01, 0.1, 1.0, 10.0, 100.0]
    let histogram = (create_histogram "custom_histogram" "Custom buckets histogram" $custom_buckets)
    
    if ($histogram.buckets | length) != ($custom_buckets | length) {
        error "Custom buckets length mismatch" --context "metrics-test"
        return false
    }
    
    # Check bucket values
    for i in 0..(($custom_buckets | length) - 1) {
        let expected = ($custom_buckets | get $i)
        let actual = ($histogram.buckets | get $i)
        if $actual != $expected {
            error $"Bucket ($i): expected ($expected), got ($actual)" --context "metrics-test"
            return false
        }
    }
    
    success "custom histogram buckets test passed" --context "metrics-test"
    return true
}

export def test_metric_timestamps [] {
    info "Testing metric timestamps" --context "metrics-test"
    
    let before_time = (date now | into int)
    let counter = (create_counter "timestamp_counter" "Counter timestamp test")
    let after_time = (date now | into int)
    
    # Check that created_at is within reasonable range
    if $counter.created_at < $before_time {
        error "Counter created_at timestamp too early" --context "metrics-test"
        return false
    }
    
    if $counter.created_at > $after_time {
        error "Counter created_at timestamp too late" --context "metrics-test"
        return false
    }
    
    # Test gauge timestamp
    let gauge = (create_gauge "timestamp_gauge" "Gauge timestamp test")
    if not ("updated_at" in $gauge) {
        error "Gauge missing updated_at timestamp" --context "metrics-test"
        return false
    }
    
    success "metric timestamps test passed" --context "metrics-test"
    return true
}

export def test_empty_labels_default [] {
    info "Testing empty labels default behavior" --context "metrics-test"
    
    let counter = (create_counter "no_labels_counter" "Counter without labels")
    
    if ($counter.labels | length) != 0 {
        error "Default labels should be empty" --context "metrics-test"
        return false
    }
    
    success "empty labels default test passed" --context "metrics-test"
    return true
}

# Main test runner
export def run_metrics_tests [] {
    banner "Running metrics.nu unit tests" --context "metrics-test"
    
    let tests = [
        test_create_counter,
        test_create_gauge,  
        test_create_histogram,
        test_metric_with_labels,
        test_custom_histogram_buckets,
        test_metric_timestamps,
        test_empty_labels_default
    ]
    
    mut passed = 0
    mut failed = 0
    
    for test_func in $tests {
        try {
            let result = (do $test_func)
            if $result {
                $passed += 1
            } else {
                $failed += 1
            }
        } catch { |err|
            error $"Test failed with error: ($err.msg)" --context "metrics-test"
            $failed += 1
        }
    }
    
    let total = $passed + $failed
    summary "Metrics tests completed" $passed $total --context "metrics-test"
    
    if $failed > 0 {
        error $"($failed) metrics tests failed" --context "metrics-test"
        return false
    }
    
    success "All metrics tests passed!" --context "metrics-test"
    return true
}

# If script is run directly, run tests
if ($env.PWD | str contains "scripts/testing/unit") {
    run_metrics_tests
}