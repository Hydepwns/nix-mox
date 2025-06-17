# Test coverage reporting for nix-mox
# This module provides functions for tracking and reporting test coverage

use ../../common.nu *
use ./coverage-core.nu *

# --- Coverage Reporting ---
export def generate_coverage_report [] {
    let coverage_data = aggregate_coverage
    let total = $coverage_data.total_tests
    let passed = $coverage_data.passed_tests
    let failed = $coverage_data.failed_tests
    let skipped = $coverage_data.skipped_tests
    let duration = $coverage_data.test_duration

    let pass_rate = if $total == 0 { 0 } else { (($passed | into float) / ($total | into float) * 100) }
    let pass_percentage = ($pass_rate | into int)

    print $"($env.GREEN)=== Test Coverage Report ===($env.NC)"
    print $"Total Tests: ($total)"
    print $"Passed: ($passed) ($pass_percentage)%"
    print $"Failed: ($failed)"
    print $"Skipped: ($skipped)"
    print $"Total Duration: ($duration) seconds"
    print ""

    print $"($env.GREEN)=== Test Categories ===($env.NC)"
    for row in ($coverage_data.test_categories | transpose category count) {
        print $"($row.category): ($row.count) tests"
    }
    print ""

    print $"($env.GREEN)=== Test Results ===($env.NC)"
    for result in $coverage_data.test_results {
        let status_color = if $result.status == "passed" { $env.GREEN } else if $result.status == "failed" { $env.RED } else { $env.YELLOW }
        print $"($status_color)($result.name) ($result.status) - ($result.duration)s($env.NC)"
    }
}

# --- Coverage Export ---
export def export_coverage_report [format: string] {
    let coverage_data = aggregate_coverage
    let total = $coverage_data.total_tests
    let passed = $coverage_data.passed_tests
    let pass_rate = if $total == 0 { 0 } else { (($passed | into float) / ($total | into float) * 100) }

    let report = {
        summary: {
            total_tests: $total
            passed_tests: $passed
            failed_tests: $coverage_data.failed_tests
            skipped_tests: $coverage_data.skipped_tests
            test_duration: $coverage_data.test_duration
            pass_rate: $pass_rate
        }
        categories: $coverage_data.test_categories
        results: $coverage_data.test_results
    }

    match $format {
        "json" => { $report | to json }
        "yaml" => { $report | to yaml }
        "toml" => { $report | to toml }
        _ => { error make { msg: "Unsupported format. Use: json, yaml, or toml" } }
    }
}

# --- Coverage Integration ---
export def wrap_test [name: string, category: string, test_func: closure] {
    let start_time = (date now | into int)

    try {
        do $test_func
        let end_time = (date now | into int)
        let duration = (($end_time - $start_time) | into float) / 1000000000

        track_test $name $category "passed" $duration
        true
    } catch {
        let end_time = (date now | into int)
        let duration = (($end_time - $start_time) | into float) / 1000000000

        track_test $name $category "failed" $duration
        false
    }
}

# --- Main Coverage Runner ---
def main [] {
    # Example usage
    wrap_test "test_example" "unit" {
        assert_equal 1 1 "Example test"
    }

    generate_coverage_report
    export_coverage_report "json" | save coverage.json
}
# End of file
