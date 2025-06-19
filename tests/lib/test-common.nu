# Test suite for common functions

# Source the common functions
use ../../modules/scripts/testing/lib/test-common.nu *

export-env {
    # Set up environment variables
    $env.GREEN = (ansi green)
    $env.YELLOW = (ansi yellow)
    $env.RED = (ansi red)
    $env.NC = (ansi reset)
    $env.LOG_LEVEL = "INFO"
}

# Test log functions
export def test_log_functions [] {
    print "Testing log functions..."

    # Test info
    let info_output = (info "This is an info message")
    if not ($info_output | str contains "INFO") {
        print "❌ info test failed"
        exit 1
    }

    # Test warn
    let warn_output = (warn "This is a warning message")
    if not ($warn_output | str contains "WARN") {
        print "❌ warn test failed"
        exit 1
    }

    # Test error
    let error_output = (error "This is an error message")
    if not ($error_output | str contains "ERROR") {
        print "❌ error test failed"
        exit 1
    }

    print "✅ Log function tests passed"
}

# Test check_root function
def test_check_root [] {
    print "Testing check_root function..."

    # Test as root (should succeed)
    let root_result = (check_root)
    print $"Debug: Error message is: ($root_result)"
    if not ($root_result | str contains "Running as root") {
        print "❌ check_root test failed (should succeed when root)"
        exit 1
    }

    print "✅ check_root test passed"
}

# Test CI mode detection
def test_ci_mode [] {
    print "Testing CI mode detection..."

    # Test with CI=true
    $env.CI = "true"
    let ci_result = (is_ci_mode)
    if not $ci_result {
        print "❌ CI mode detection test failed (should detect CI mode)"
        exit 1
    }

    # Test without CI=true
    $env.CI = ""
    let no_ci_result = (is_ci_mode)
    if $no_ci_result {
        print "❌ CI mode detection test failed (should not detect CI mode)"
        exit 1
    }

    print "✅ CI mode detection test passed"
}

# Main test runner
def main [] {
    print "Starting tests..."
    test_log_functions
    test_check_root
    test_ci_mode
    print "All tests passed! 🎉"
}

# Run tests if NU_TEST is set
# def run_if_test [] {
#     if $env.NU_TEST == "true" {
#         main
#     }
# }
# run_if_test
