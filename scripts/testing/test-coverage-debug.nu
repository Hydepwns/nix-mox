#!/usr/bin/env nu

# Import unified libraries
use ../lib/unified-checks.nu
use ../lib/unified-logging.nu *
use ../lib/unified-error-handling.nu *

# Debug script to test coverage system
export-env {
    use ./lib/test-coverage.nu *
    use ./lib/coverage-core.nu *
}

def main [] {
    print "🧪 Testing coverage system..."

    # Set up test environment
    $env.TEST_TEMP_DIR = "coverage-tmp/nix-mox-tests"
    if not ($env.TEST_TEMP_DIR | path exists) {
        mkdir $env.TEST_TEMP_DIR
    }

    # Create some test results
    print "Creating test results..."
    track_test "debug_test_1" "unit" "passed" 0.1
    track_test "debug_test_2" "unit" "passed" 0.2
    track_test "debug_test_3" "integration" "failed" 0.3
    track_test "debug_test_4" "unit" "skipped" 0.1

    # Generate coverage report
    print "Generating coverage report..."
    let coverage_data = aggregate_coverage
    print $"Found ($coverage_data.total_tests) tests"
    print $"Passed: ($coverage_data.passed_tests)"
    print $"Failed: ($coverage_data.failed_tests)"
    print $"Skipped: ($coverage_data.skipped_tests)"

    # Export coverage report
    print "Exporting coverage report..."
    let report = export_coverage_report "json"
    print $"Report length: ($report | str length)"

    # Save to coverage-tmp
    if not ("coverage-tmp" | path exists) {
        mkdir "coverage-tmp"
    }
    $report | save --force "coverage-tmp/codecov.json"

    print "✅ Coverage system test completed"
    print "📁 Check coverage-tmp/codecov.json for the generated report"
}
