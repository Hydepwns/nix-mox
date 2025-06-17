# Test coverage reporting for nix-mox
# This module provides functions for tracking and reporting test coverage

use ../../common.nu *
use ./test-utils.nu *

# --- Coverage Data Structure ---
export-env {
    $env.COVERAGE_DATA = {
        total_tests: 0
        passed_tests: 0
        failed_tests: 0
        skipped_tests: 0
        test_duration: 0
        test_categories: {
            unit: 0
            integration: 0
            storage: 0
            performance: 0
        }
        test_results: []
    }
}

# --- Coverage Tracking ---
export def track_test [name: string, category: string, status: string, duration: float] {
    $env.COVERAGE_DATA.total_tests = $env.COVERAGE_DATA.total_tests + 1
    $env.COVERAGE_DATA.test_duration = $env.COVERAGE_DATA.test_duration + $duration

    if $status == "passed" {
        $env.COVERAGE_DATA.passed_tests = $env.COVERAGE_DATA.passed_tests + 1
    } else if $status == "failed" {
        $env.COVERAGE_DATA.failed_tests = $env.COVERAGE_DATA.failed_tests + 1
    } else if $status == "skipped" {
        $env.COVERAGE_DATA.skipped_tests = $env.COVERAGE_DATA.skipped_tests + 1
    }

    let current_count = ($env.COVERAGE_DATA.test_categories | get $category)
    $env.COVERAGE_DATA.test_categories = ($env.COVERAGE_DATA.test_categories | upsert $category ($current_count + 1))

    $env.COVERAGE_DATA.test_results = ($env.COVERAGE_DATA.test_results | append {
        name: $name
        category: $category
        status: $status
        duration: $duration
    })
}

# --- Coverage Reporting ---
export def generate_coverage_report [] {
    let total = $env.COVERAGE_DATA.total_tests
    let passed = $env.COVERAGE_DATA.passed_tests
    let failed = $env.COVERAGE_DATA.failed_tests
    let skipped = $env.COVERAGE_DATA.skipped_tests
    let duration = $env.COVERAGE_DATA.test_duration

    let pass_rate = if $total == 0 { 0 } else { (($passed | into float) / ($total | into float) * 100) }

    print $"($env.GREEN)=== Test Coverage Report ===($env.NC)"
    print $"Total Tests: ($total)"
    print $"Passed: ($passed) (($pass_rate)%)"
    print $"Failed: ($failed)"
    print $"Skipped: ($skipped)"
    print $"Total Duration: ($duration) seconds"
    print ""

    print $"($env.GREEN)=== Test Categories ===($env.NC)"
    for row in ($env.COVERAGE_DATA.test_categories | transpose category count) {
        print $"($row.category): ($row.count) tests"
    }
    print ""

    print $"($env.GREEN)=== Test Results ===($env.NC)"
    for result in $env.COVERAGE_DATA.test_results {
        let status_color = if $result.status == "passed" { $env.GREEN } else if $result.status == "failed" { $env.RED } else { $env.YELLOW }
        print $"($status_color)($result.name) ($result.status) - ($result.duration)s($env.NC)"
    }
}

# --- Coverage Export ---
export def export_coverage_report [format: string] {
    let total = $env.COVERAGE_DATA.total_tests
    let passed = $env.COVERAGE_DATA.passed_tests
    let pass_rate = if $total == 0 { 0 } else { (($passed | into float) / ($total | into float) * 100) }

    let report = {
        summary: {
            total_tests: $total
            passed_tests: $passed
            failed_tests: $env.COVERAGE_DATA.failed_tests
            skipped_tests: $env.COVERAGE_DATA.skipped_tests
            test_duration: $env.COVERAGE_DATA.test_duration
            pass_rate: $pass_rate
        }
        categories: $env.COVERAGE_DATA.test_categories
        results: $env.COVERAGE_DATA.test_results
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
