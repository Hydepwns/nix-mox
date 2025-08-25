#!/usr/bin/env nu

# Import unified libraries
use ../../lib/validators.nu
use logging.nu *
use ../../lib/logging.nu *


# Error handling module tests
# Tests for scripts/lib/error-handling.nu
use ../lib/test-utils.nu *

def main [] {
    print "Running error handling module tests..."
    
    # Set up test environment
    setup_test_env
    
    # Test error ID generation
    test_error_id_generation
    
    # Test error creation
    test_error_creation
    
    # Test error logging
    test_error_logging
    
    # Test recovery suggestions
    test_recovery_suggestions
    
    # Test error type validation
    test_error_type_validation
    
    # Test error handling with exit
    test_error_handling_exit
    
    print "Error handling module tests completed"
}

def test_error_id_generation [] {
    print "Testing error ID generation..."
    
    let error_id1 = generate_error_id
    let error_id2 = generate_error_id
    
    assert_not_equal $error_id1 $error_id2 "Error IDs should be unique"
    assert_true (($error_id1 | str length) > 0) "Error ID should not be empty"
    track_test "error_id_generation" "unit" "passed" 0.1
}

def test_error_creation [] {
    print "Testing error creation..."
    
    let error = create_error "Test error message" "TEST_ERROR" {component: "test"}
    
    assert_equal $error.message "Test error message" "Error message should match"
    assert_equal $error.type "TEST_ERROR" "Error type should match"
    assert_equal $error.context.component "test" "Error context should be preserved"
    assert_true ($error.id | is-not-empty) "Error should have ID"
    assert_true ($error.timestamp | is-not-empty) "Error should have timestamp"
    track_test "error_creation_basic" "unit" "passed" 0.1
}

def test_error_logging [] {
    print "Testing error logging..."
    
    let error = create_error "Test log error" "LOG_TEST" {source: "test"}
    
    # Test that error_structured doesn't crash
    try {
        error_structured $error
        track_test "error_logging_structured" "unit" "passed" 0.1
    } catch {
        track_test "error_logging_structured" "unit" "failed" 0.1
    }
}

def test_recovery_suggestions [] {
    print "Testing recovery suggestions..."
    
    # Test permission error recovery
    let perm_error = create_error "Permission denied" "PERMISSION" {}
    let perm_suggestions = suggest_recovery $perm_error
    assert_true (($perm_suggestions | length) > 0) "Permission error should have suggestions"
    track_test "recovery_permission_suggestions" "unit" "passed" 0.1
    
    # Test dependency error recovery
    let dep_error = create_error "Missing dependency" "DEPENDENCY" {}
    let dep_suggestions = suggest_recovery $dep_error
    assert_true (($dep_suggestions | length) > 0) "Dependency error should have suggestions"
    track_test "recovery_dependency_suggestions" "unit" "passed" 0.1
    
    # Test config error recovery
    let config_error = create_error "Invalid config" "CONFIG" {}
    let config_suggestions = suggest_recovery $config_error
    assert_true (($config_suggestions | length) > 0) "Config error should have suggestions"
    track_test "recovery_config_suggestions" "unit" "passed" 0.1
    
    # Test unknown error recovery
    let unknown_error = create_error "Unknown issue" "UNKNOWN" {}
    let unknown_suggestions = suggest_recovery $unknown_error
    assert_true (($unknown_suggestions | length) > 0) "Unknown error should have general suggestions"
    track_test "recovery_unknown_suggestions" "unit" "passed" 0.1
}

def test_error_type_validation [] {
    print "Testing error type validation..."
    
    let valid_types = ["PERMISSION", "DEPENDENCY", "CONFIG", "NETWORK", "RESOURCE", "PERFORMANCE", "PLATFORM", "VALIDATION", "UNKNOWN"]
    
    for type in $valid_types {
        let is_valid = validate_error_type $type
        assert_true $is_valid $"($type) should be valid error type"
    }
    
    let invalid_is_valid = validate_error_type "INVALID_TYPE"
    assert_false $invalid_is_valid "INVALID_TYPE should not be valid"
    
    track_test "error_type_validation" "unit" "passed" 0.1
}

def test_error_handling_exit [] {
    print "Testing error handling with exit control..."
    
    # Test error handling without exit (should not crash)
    try {
        handle_script_error "Test error" "TEST" {} false
        track_test "error_handling_no_exit" "unit" "passed" 0.1
    } catch {
        track_test "error_handling_no_exit" "unit" "failed" 0.1
    }
}

# PWD is automatically set by Nushell and cannot be set manually

main