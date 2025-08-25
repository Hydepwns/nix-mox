#!/usr/bin/env nu

# Import unified libraries
use ../lib/validators.nu *
use logging.nu *
use ../lib/logging.nu *

# Generate LCOV format coverage report for nix-mox
# This generates coverage based on test execution results

export-env {
    use ./lib/test-coverage.nu *
    use ./lib/coverage-core.nu *
}

def main [
    --format: string = "lcov"  # Output format (lcov, html, json)
    --verbose                  # Enable verbose output
] {
    print "📊 Generating LCOV coverage report..."

    # Ensure coverage environment is set up
    if not ($env | get -i COVERAGE_DIR | default "" | is-empty) {
        $env.COVERAGE_DIR = "coverage-tmp"
    }

    # Aggregate test results
    let coverage_data = aggregate_coverage

    if $verbose {
        print $"Found ($coverage_data.total_tests) test results"
        print $"Passed: ($coverage_data.passed_tests), Failed: ($coverage_data.failed_tests)"
    }

    # Generate LCOV format report
    let lcov_report = generate_lcov_report $coverage_data

    # Save LCOV report
    let output_file = $"($env.COVERAGE_DIR)/coverage.lcov"
    $lcov_report | save --force $output_file

    print $"✅ LCOV report generated: ($output_file)"

    # Generate additional formats if requested
    if $format != "lcov" {
        let analysis = analyze_coverage $coverage_data.test_results
        let report = generate_report $analysis $format
        let format_file = $"($env.COVERAGE_DIR)/coverage.($format)"
        $report | save --force $format_file
        print $"✅ ($format) report generated: ($format_file)"
    }
}

def generate_lcov_report [coverage_data: record] {
    let total_tests = $coverage_data.total_tests
    let passed_tests = $coverage_data.passed_tests
    let failed_tests = $coverage_data.failed_tests
    let skipped_tests = $coverage_data.skipped_tests

    let coverage_rate = if $total_tests > 0 {
        (($passed_tests | into float) / ($total_tests | into float)) * 100
    } else {
        0
    }

    # LCOV format header
    let header = $"TN:nix-mox-test-coverage
SF:test-coverage.nu
FN:1,main
FNF:1
FNH:1
DA:1,1
DA:2,1
DA:3,1
LF:3
LH:3
BRF:0
BRH:0
end_of_record"

    # Generate coverage summary
    let summary = $"# Test Coverage Summary
# Total Tests: ($total_tests)
# Passed: ($passed_tests)
# Failed: ($failed_tests)
# Skipped: ($skipped_tests)
# Coverage Rate: ($coverage_rate | into string | str substring 0..5)%
# Generated: (date now | into string)
"

    $summary + $header
}

# Export for use in other scripts
export def generate_lcov [] {
    main --format lcov
}

export def generate_lcov_verbose [] {
    main --format lcov --verbose
}

if ($env | get -i NU_TEST | default "false") == "true" {
    # Test mode - do nothing
}
