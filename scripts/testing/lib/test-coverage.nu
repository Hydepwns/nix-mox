#!/usr/bin/env nu

# Import unified libraries
use ../../../../../../../../../../lib/unified-checks.nu
use ../../../../../../../../../../lib/enhanced-error-handling.nu


# Test coverage utilities for nix-mox
# Provides coverage analysis and reporting functions

# --- Coverage Analysis ---
export def analyze_coverage [test_results: list] {
    let total_tests = ($test_results | length)
    let passed_tests = ($test_results | where status == "passed" | length)
    let failed_tests = ($test_results | where status == "failed" | length)
    let skipped_tests = ($test_results | where status == "skipped" | length)

    let pass_rate = if $total_tests > 0 {
        (($passed_tests | into float) / ($total_tests | into float)) * 100
    } else {
        0
    }

    # Performance metrics
    let durations = ($test_results | get duration | default 0)
    let avg_duration = if ($durations | length) > 0 {
        ($durations | math avg)
    } else {
        0
    }

    let slowest_test = if ($durations | length) > 0 {
        $durations | math max
    } else {
        0
    }

    let fastest_test = if ($durations | length) > 0 {
        $durations | math min
    } else {
        0
    }

    # Test distribution by speed
    let fast_tests = ($durations | where { |d| $d < 0.1 } | length)
    let medium_tests = ($durations | where { |d| $d >= 0.1 and $d < 1.0 } | length)
    let slow_tests = ($durations | where { |d| $d >= 1.0 } | length)

    # Category analysis
    let categories = ($test_results | group-by category | transpose category data)
    let category_stats = ($categories | each { |cat|
        let data = $cat.data
        let total = ($data | length)
        let passed = ($data | where status == "passed" | length)
        let pass_rate = if $total > 0 {
            (($passed | into float) / ($total | into float)) * 100
        } else {
            0
        }

        {
            category: $cat.category,
            total: $total,
            passed: $passed,
            failed: ($total - $passed),
            pass_rate: $pass_rate,
            avg_duration: (($data | get duration | default 0) | math avg)
        }
    })

    {
        summary: {
            total_tests: $total_tests,
            passed_tests: $passed_tests,
            failed_tests: $failed_tests,
            skipped_tests: $skipped_tests,
            pass_rate: $pass_rate,
            timestamp: (date now | into int)
        },
        performance: {
            avg_test_duration: $avg_duration,
            slowest_test: $slowest_test,
            fastest_test: $fastest_test,
            test_distribution: {
                fast: $fast_tests,
                medium: $medium_tests,
                slow: $slow_tests
            }
        },
        test_categories: $category_stats,
        recommendations: (generate_recommendations {
            coverage_rate: $pass_rate,
            performance_metrics: {
                avg_test_duration: $avg_duration,
                slowest_test: $slowest_test,
                fastest_test: $fastest_test,
                test_distribution: {
                    fast: $fast_tests,
                    medium: $medium_tests,
                    slow: $slow_tests
                }
            },
            test_categories: $category_stats
        })
    }
}

# --- Report Generation ---
export def generate_report [coverage_data: record, format: string = "json"] {
    let report = {
        summary: $coverage_data.summary,
        performance: $coverage_data.performance,
        test_categories: $coverage_data.test_categories,
        recommendations: $coverage_data.recommendations
    }

    match $format {
        "json" => { $report | to json },
        "yaml" => { $report | to yaml },
        "toml" => { $report | to toml },
        "html" => { generate_html_report $report },
        _ => { error make {msg: "Unsupported format. Use: json, yaml, toml, or html"} }
    }
}

# --- Export Coverage Report ---
export def export_coverage_report [format: string = "json"] {
    use ./coverage-core.nu *
    let raw = aggregate_coverage
    let coverage_data = {
        summary: {
            total_tests: $raw.total_tests,
            passed_tests: $raw.passed_tests,
            failed_tests: $raw.failed_tests,
            skipped_tests: $raw.skipped_tests,
            pass_rate: (if $raw.total_tests > 0 { ($raw.passed_tests | into float) / ($raw.total_tests | into float) * 100 } else { 0 }),
            timestamp: (date now | into int)
        },
        performance: {
            avg_test_duration: (if $raw.total_tests > 0 { $raw.test_duration / $raw.total_tests } else { 0 }),
            slowest_test: (if ($raw.test_results | length) > 0 { ($raw.test_results | get duration | math max) } else { 0 }),
            fastest_test: (if ($raw.test_results | length) > 0 { ($raw.test_results | get duration | math min) } else { 0 }),
            test_distribution: {
                fast: ($raw.test_results | where { |t| $t.duration < 0.1 } | length),
                medium: ($raw.test_results | where { |t| $t.duration >= 0.1 and $t.duration < 1.0 } | length),
                slow: ($raw.test_results | where { |t| $t.duration >= 1.0 } | length)
            }
        },
        test_categories: $raw.test_categories,
        recommendations: []
    }
    generate_report $coverage_data $format
}

def generate_recommendations [coverage_data: record] {
    mut recommendations = []

    # Performance recommendations
    let perf_metrics = ($coverage_data.performance_metrics | default {
        avg_test_duration: 0,
        slowest_test: 0,
        fastest_test: 0,
        test_distribution: {
            fast: 0,
            medium: 0,
            slow: 0
        }
    })

    let avg_duration = $perf_metrics.avg_test_duration
    if $avg_duration > 1.0 {
        $recommendations = ($recommendations | append "Consider optimizing slow tests (>1s average)")
    }

    let slow_tests = $perf_metrics.test_distribution.slow
    if $slow_tests > 10 {
        $recommendations = ($recommendations | append "High number of slow tests detected - consider parallelization")
    }

    # Coverage recommendations
    let coverage_rate = $coverage_data.coverage_rate
    if $coverage_rate < 80 {
        $recommendations = ($recommendations | append "Low test coverage - consider adding more tests")
    }

    # Category-specific recommendations
    for row in ($coverage_data.test_categories | transpose category data) {
        let data = $row.data
        if $data.pass_rate < 90 {
            $recommendations = ($recommendations | append $"Low pass rate in ($row.category) category - investigate failures")
        }
    }

    if ($recommendations | is-empty) {
        $recommendations = ($recommendations | append "Test suite is performing well - no immediate improvements needed")
    }

    $recommendations
}

def generate_html_report [report: record] {
    let html_template = $"
    <!DOCTYPE html>
    <html>
    <head>
        <title>nix-mox Test Coverage Report</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 20px; }
            .header { background: #f0f0f0; padding: 20px; border-radius: 5px; }
            .metric { display: inline-block; margin: 10px; padding: 10px; background: #e8f5e8; border-radius: 3px; }
            .failed { background: #ffe8e8; }
            .warning { background: #fff8e8; }
            .success { background: #e8f5e8; }
            table { border-collapse: collapse; width: 100%; }
            th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
            th { background-color: #f2f2f2; }
        </style>
    </head>
    <body>
        <div class='header'>
            <h1>nix-mox Test Coverage Report</h1>
            <p>Generated: ($report.summary.timestamp)</p>
        </div>

        <h2>Summary</h2>
        <div class='metric'>Total Tests: ($report.summary.total_tests)</div>
        <div class='metric success'>Passed: ($report.summary.passed_tests)</div>
        <div class='metric failed'>Failed: ($report.summary.failed_tests)</div>
        <div class='metric warning'>Skipped: ($report.summary.skipped_tests)</div>
        <div class='metric'>Coverage Rate: ($report.summary.pass_rate | into int)%</div>

        <h2>Performance Metrics</h2>
        <div class='metric'>Average Duration: ($report.performance.avg_test_duration | into string | str substring 0..6)s</div>
        <div class='metric'>Slowest Test: ($report.performance.slowest_test | into string | str substring 0..6)s</div>
        <div class='metric'>Fastest Test: ($report.performance.fastest_test | into string | str substring 0..6)s</div>

        <h2>Recommendations</h2>
        <ul>
        ($report.recommendations | each { |rec| "<li>($rec)</li>" } | str join "\n")
        </ul>
    </body>
    </html>
    "

    $html_template
}

# --- Test Wrapper ---
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
