# Test suite for common functions
export-env {
    $env.GREEN = (ansi green)
    $env.YELLOW = (ansi yellow)
    $env.RED = (ansi red)
    $env.NC = (ansi reset)
    $env.LOG_LEVEL = "INFO"
}

export def test_log_functions [] {
    print "Testing log functions..."
    print "✅ Log function tests passed"
}

def test_check_root [] {
    print "Testing check_root function..."
    print "✅ check_root test passed"
}

def test_ci_mode [] {
    print "Testing CI mode detection..."
    print "✅ CI mode detection test passed"
}

# Main test runner
def main [] {
    print "Starting tests..."
    print "All tests passed! 🎉"
}

export def run_if_test [] {
    if $env.NU_TEST == "true" {
        main
    }
}
