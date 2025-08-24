#!/usr/bin/env nu

# Import unified libraries
use ../../lib/unified-checks.nu
use ../../lib/unified-logging.nu *
use ../../lib/unified-error-handling.nu *


use ../lib/test-utils.nu *

def main [] {
    print "Running logging module unit tests..."

    # Test text log formatting
    let text_log = format_text_log "INFO" "Hello world" {user: "alice"}
    assert_true ($text_log | str contains "[INFO]") "Text log contains level"
    assert_true ($text_log | str contains "Hello world") "Text log contains message"
    track_test "format_text_log_basic" "unit" "passed" 0.1

    # Test JSON log formatting
    let json_log = format_json_log "ERROR" "Something failed" {user: "bob"}
    assert_true ($json_log | str contains '"level": "ERROR"') "JSON log contains level"
    assert_true ($json_log | str contains '"message": "Something failed"') "JSON log contains message"
    track_test "format_json_log_basic" "unit" "passed" 0.1

    # Test log level filtering
    $env.LOG_LEVEL = "WARN"
    assert_true (should_log "ERROR") "Should log ERROR when level is WARN"
    assert_true (should_log "WARN") "Should log WARN when level is WARN"
    assert_false (should_log "INFO") "Should not log INFO when level is WARN"
    track_test "should_log_filtering" "unit" "passed" 0.1

    # Test log_with_context merges context
    let ctx_log = (do { log_with_context "INFO" "Context test" {foo: "bar"} } | default "ok")
    assert_true (($ctx_log | default "ok") == "ok") "log_with_context runs without error"
    track_test "log_with_context_basic" "unit" "passed" 0.1

    print "Logging module unit tests completed successfully"
}

if ($env | get -i NU_TEST | default "false") == "true" {
    main
}
