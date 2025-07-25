#!/usr/bin/env nu

use ../lib/test-utils.nu *
use ../../lib/config.nu *

def main [] {
    print "Running config module unit tests..."

    # Test merge_config deep merge
    let base = {a: 1, b: {c: 2}}
    let override = {b: {d: 3}, e: 4}
    let merged = merge_config $base $override
    assert_equal ($merged.b.d) 3 "merge_config deep merge"
    assert_equal ($merged.a) 1 "merge_config preserves base"
    assert_equal ($merged.e) 4 "merge_config adds new key"
    track_test "merge_config_basic" "unit" "passed" 0.1

    # Test validate_config valid
    let valid = validate_config $DEFAULT_CONFIG
    assert_true $valid.valid "validate_config passes for default config"
    track_test "validate_config_valid" "unit" "passed" 0.1

    # Test validate_config invalid
    let invalid = validate_config {foo: 1}
    assert_false $invalid.valid "validate_config fails for missing keys"
    track_test "validate_config_invalid" "unit" "passed" 0.1

    # Test get_config_value
    let val = get_config_value $DEFAULT_CONFIG "logging.level"
    assert_equal $val "INFO" "get_config_value retrieves nested value"
    let fallback = get_config_value $DEFAULT_CONFIG "foo.bar" "baz"
    assert_equal $fallback "baz" "get_config_value returns default for missing path"
    track_test "get_config_value_basic" "unit" "passed" 0.1

    # Test set_config_value
    let updated = set_config_value $DEFAULT_CONFIG "logging.level" "DEBUG"
    assert_equal (get_config_value $updated "logging.level") "DEBUG" "set_config_value updates value"
    track_test "set_config_value_basic" "unit" "passed" 0.1

    print "Config module unit tests completed successfully"
}

if ($env | get -i NU_TEST | default "false") == "true" {
    main
}
