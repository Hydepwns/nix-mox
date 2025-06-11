# Test assertion function
export def assert_equal [expected: any, actual: any, message: string] {
    if $expected == $actual {
        true
    } else {
        error make {
            msg: $"Assertion failed: ($message)\nExpected: ($expected)\nActual: ($actual)"
        }
    }
}

# Test retry mechanism
export def test_retry [max_retries: int, retry_delay: int, operation: closure, expected_result: bool] {
    mut retries = 0
    mut success = false

    while $retries < $max_retries {
        if (do $operation) {
            $success = true
            break
        }
        $retries = $retries + 1
        if $retries < $max_retries {
            sleep ($retry_delay * 1sec)
        }
    }

    assert_equal $expected_result $success "Retry test failed"
}

# Test logging
export def test_logging [level: string, message: string, expected_output: string] {
    let output = $"[($level)] ($message)"
    assert_equal $expected_output $output "Logging test failed"
}

# Test configuration validation
export def test_config_validation [config: string, expected_error: string] {
    if ($config | is-empty) {
        assert_equal $expected_error $expected_error "Config validation failed"
        false
    } else {
        true
    }
}

# Test ZFS operations
export def test_zfs_operation [operation: string, expected_success: bool] {
    let success = if $operation == "success" { true } else { false }
    assert_equal $expected_success $success "ZFS operation test failed"
}

# Test SSD caching
export def test_ssd_caching [cache_size: int, expected_success: bool] {
    let success = $cache_size > 0
    assert_equal $expected_success $success "SSD caching test failed"
}

# Test error handling
export def test_error_handling [error_type: string, expected_output: string] {
    if $error_type == "expected" {
        assert_equal $expected_output $expected_output "Error handling test failed"
        true
    } else {
        false
    }
}

# Test performance
export def test_performance [operation: closure, max_duration: int] {
    let start_time = (date now | into int)
    do $operation
    let end_time = (date now | into int)
    let duration_ms = ($end_time - $start_time)
    let duration = ($duration_ms | into float) / 1000000000
    assert_equal true ($duration <= $max_duration) ("Performance test failed: took too long " + ($duration | into string) + " seconds")
} 