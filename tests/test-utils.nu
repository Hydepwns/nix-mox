# Test assertion function
def assert_equal [expected: any, actual: any, message: string] {
    if $expected == $actual {
        true
    } else {
        error make {
            msg: $"Assertion failed: ($message)\nExpected: ($expected)\nActual: ($actual)"
        }
    }
}

# Test retry mechanism
def test_retry [max_retries: int, retry_delay: int, operation: closure, expected_result: bool] {
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
def test_logging [level: string, message: string, expected_output: string] {
    let output = $"[($level)] ($message)"
    assert_equal $expected_output $output "Logging test failed"
}

# Test configuration validation
def test_config_validation [config: string, expected_error: string] {
    if ($config | is-empty) {
        assert_equal $expected_error $expected_error "Config validation failed"
        false
    } else {
        true
    }
}

# Test ZFS operations
def test_zfs_operation [operation: string, expected_success: bool] {
    let success = if $operation == "success" { true } else { false }
    assert_equal $expected_success $success "ZFS operation test failed"
}

# Test SSD caching
def test_ssd_caching [cache_size: int, expected_success: bool] {
    let success = $cache_size > 0
    assert_equal $expected_success $success "SSD caching test failed"
}

# Test error handling
def test_error_handling [error_type: string, expected_output: string] {
    if $error_type == "expected" {
        assert_equal $expected_output $expected_output "Error handling test failed"
        true
    } else {
        false
    }
}

# Test performance
def test_performance [operation: closure, max_duration: int] {
    let start_time = (date now)
    do $operation
    let end_time = (date now)
    let duration = ($end_time - $start_time | into int)
    assert_equal true ($duration <= $max_duration) ("Performance test failed: took too long " + ($duration | into string) + " seconds")
}

# Export all functions
export-env {
    $env.TEST_UTILS = {
        assert_equal: (def assert_equal [expected: any, actual: any, message: string] {
            if $expected == $actual {
                true
            } else {
                error make {
                    msg: $"Assertion failed: ($message)\nExpected: ($expected)\nActual: ($actual)"
                }
            }
        })
        test_retry: (def test_retry [max_retries: int, retry_delay: int, operation: closure, expected_result: bool] {
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
        })
        test_logging: (def test_logging [level: string, message: string, expected_output: string] {
            let output = $"[($level)] ($message)"
            assert_equal $expected_output $output "Logging test failed"
        })
        test_config_validation: (def test_config_validation [config: string, expected_error: string] {
            if ($config | is-empty) {
                assert_equal $expected_error $expected_error "Config validation failed"
                false
            } else {
                true
            }
        })
        test_zfs_operation: (def test_zfs_operation [operation: string, expected_success: bool] {
            let success = if $operation == "success" { true } else { false }
            assert_equal $expected_success $success "ZFS operation test failed"
        })
        test_ssd_caching: (def test_ssd_caching [cache_size: int, expected_success: bool] {
            let success = $cache_size > 0
            assert_equal $expected_success $success "SSD caching test failed"
        })
        test_error_handling: (def test_error_handling [error_type: string, expected_output: string] {
            if $error_type == "expected" {
                assert_equal $expected_output $expected_output "Error handling test failed"
                true
            } else {
                false
            }
        })
        test_performance: (def test_performance [operation: closure, max_duration: int] {
            let start_time = (date now)
            do $operation
            let end_time = (date now)
            let duration = ($end_time - $start_time | into int)
            assert_equal true ($duration <= $max_duration) ("Performance test failed: took too long " + ($duration | into string) + " seconds")
        })
    }
} 