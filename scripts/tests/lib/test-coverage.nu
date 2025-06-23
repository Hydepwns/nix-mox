# Enhanced Test Coverage System
# Provides comprehensive test coverage analysis and reporting

export def aggregate_coverage [] {
    # Ensure TEST_TEMP_DIR exists
    if not ($env.TEST_TEMP_DIR | path exists) {
        print "Warning: TEST_TEMP_DIR does not exist, creating it"
        mkdir $env.TEST_TEMP_DIR
    }

    # Look for test result files with better error handling
    let result_files = (try {
        ls $env.TEST_TEMP_DIR | where { |it| ($it.name | path basename) | str starts-with 'test_result_' } | get name
    } catch {
        print "Warning: Failed to list test result files: ($env.LAST_ERROR)"
        []
    })

    print $"DEBUG: Found ($result_files | length) test result files in ($env.TEST_TEMP_DIR)"

    if ($result_files | is-empty) {
        print "Warning: No test result files found, creating minimal coverage data"
        return {
            total_tests: 0
            passed_tests: 0
            failed_tests: 0
            skipped_tests: 0
            test_duration: 0
            test_categories: {}
            test_results: []
            coverage_rate: 0
            performance_metrics: {
                avg_test_duration: 0
                slowest_test: 0
                fastest_test: 0
                test_distribution: {
                    fast: 0
                    medium: 0
                    slow: 0
                }
            }
        }
    }

    mut test_results = ([])
    mut total_duration = 0

    for file in $result_files {
        try {
            let file_content = (open --raw $file)
            let result = ($file_content | from json)
            $test_results = ($test_results | append $result)

            if ($result.duration != null) {
                $total_duration = ($total_duration + $result.duration)
            }
        } catch {
            print $"Warning: Failed to parse test result file ($file): ($env.LAST_ERROR)"
        }
    }

    let total_tests = ($test_results | length)
    let passed_tests = ($test_results | where { |it| $it.status == "passed" } | length)
    let failed_tests = ($test_results | where { |it| $it.status == "failed" } | length)
    let skipped_tests = ($test_results | where { |it| $it.status == "skipped" } | length)

    # Calculate performance metrics
    let durations = ($test_results | where { |it| $it.duration != null } | get duration)
    let avg_duration = if ($durations | length) > 0 { $durations | math avg } else { 0 }
    let slowest_test = if ($durations | length) > 0 { $durations | math max } else { 0 }
    let fastest_test = if ($durations | length) > 0 { $durations | math min } else { 0 }

    let fast_tests = ($durations | where { |d| $d < 0.1 } | length)
    let medium_tests = ($durations | where { |d| $d >= 0.1 and $d <= 1.0 } | length)
    let slow_tests = ($durations | where { |d| $d > 1.0 } | length)

    let categories = (try {
        $test_results | group-by category | transpose category tests | each { |row|
            let tests = $row.tests
            let total = ($tests | length)
            let passed = ($tests | where { |it| $it.status == "passed" } | length)
            let duration = ($tests | where { |it| $it.duration != null } | get duration | math sum)
            let pass_rate = if $total > 0 { (($passed | into float) / ($total | into float) * 100) } else { 0 }

            { ($row.category): {
                total: $total
                passed: $passed
                failed: ($tests | where { |it| $it.status == "failed" } | length)
                skipped: ($tests | where { |it| $it.status == "skipped" } | length)
                duration: $duration
                pass_rate: $pass_rate
            }}
        } | reduce { |acc, item| $acc | merge $item }
    } catch {
        print "Warning: Failed to calculate categories: ($env.LAST_ERROR)"
        {}
    })

    let coverage_rate = if $total_tests == 0 { 0 } else { (($passed_tests | into float) / ($total_tests | into float) * 100) }

    {
        total_tests: $total_tests
        passed_tests: $passed_tests
        failed_tests: $failed_tests
        skipped_tests: $skipped_tests
        test_duration: $total_duration
        test_categories: $categories
        test_results: $test_results
        coverage_rate: $coverage_rate
        performance_metrics: {
            avg_test_duration: $avg_duration
            slowest_test: $slowest_test
            fastest_test: $fastest_test
            test_distribution: {
                fast: $fast_tests
                medium: $medium_tests
                slow: $slow_tests
            }
        }
    }
}

export def generate_coverage_report [] {
    let coverage_data = aggregate_coverage
    let total = $coverage_data.total_tests
    let passed = $coverage_data.passed_tests
    let failed = $coverage_data.failed_tests
    let skipped = $coverage_data.skipped_tests
    let duration = $coverage_data.test_duration
    let coverage_rate = $coverage_data.coverage_rate
    let perf_metrics = ($coverage_data.performance_metrics | default {
        avg_test_duration: 0
        slowest_test: 0
        fastest_test: 0
        test_distribution: {
            fast: 0
            medium: 0
            slow: 0
        }
    })

    print $"($env.GREEN)=== Enhanced Test Coverage Report ===($env.NC)"
    print $"Total Tests: ($total)"
    print $"Passed: ($passed) ($coverage_rate | into int)%"
    print $"Failed: ($failed)"
    print $"Skipped: ($skipped)"
    print $"Total Duration: ($duration | into string | str substring 0..6)s"
    print ""

    print $"($env.GREEN)=== Performance Metrics ===($env.NC)"
    print $"Average Test Duration: ($perf_metrics.avg_test_duration | into string | str substring 0..6)s"
    print $"Slowest Test: ($perf_metrics.slowest_test | into string | str substring 0..6)s"
    print $"Fastest Test: ($perf_metrics.fastest_test | into string | str substring 0..6)s"
    print $"Test Distribution:"
    print $"  Fast (<0.1s): ($perf_metrics.test_distribution.fast)"
    print $"  Medium (0.1-1s): ($perf_metrics.test_distribution.medium)"
    print $"  Slow (>1s): ($perf_metrics.test_distribution.slow)"
    print ""

    print $"($env.GREEN)=== Test Categories ===($env.NC)"
    for row in ($coverage_data.test_categories | transpose category data) {
        let data = $row.data
        let pass_rate = ($data.pass_rate | into int)
        let status_color = if $pass_rate >= 90 { $env.GREEN } else if $pass_rate >= 70 { $env.YELLOW } else { $env.RED }
        print $"($status_color)($row.category): ($data.total) tests, ($data.passed) passed ($pass_rate)% - ($data.duration | into string | str substring 0..6)s($env.NC)"
    }
    print ""

    # Show slowest tests if any
    let slow_tests = ($coverage_data.test_results | where { |it| $it.duration != null and $it.duration > 1.0 } | sort-by duration | reverse | take 5)
    if not ($slow_tests | is-empty) {
        print $"($env.YELLOW)=== Slowest Tests (>1s) ===($env.NC)"
        for test in $slow_tests {
            print $"  ($test.name): ($test.duration | into string | str substring 0..6)s ($test.status)"
        }
        print ""
    }

    # Show failed tests if any
    let failed_tests = ($coverage_data.test_results | where { |it| $it.status == "failed" })
    if not ($failed_tests | is-empty) {
        print $"($env.RED)=== Failed Tests ===($env.NC)"
        for test in $failed_tests {
            print $'  ($test.name): ($test.error | default "Unknown error")'
        }
        print ""
    }
}

export def export_coverage_report [format: string] {
    let coverage_data = aggregate_coverage
    let total = $coverage_data.total_tests
    let passed = $coverage_data.passed_tests
    let coverage_rate = $coverage_data.coverage_rate

    let report = {
        summary: {
            total_tests: $total
            passed_tests: $passed
            failed_tests: $coverage_data.failed_tests
            skipped_tests: $coverage_data.skipped_tests
            test_duration: $coverage_data.test_duration
            pass_rate: $coverage_rate
            timestamp: (date now | format date "%Y-%m-%d %H:%M:%S")
        }
        categories: $coverage_data.test_categories
        results: $coverage_data.test_results
        performance: ($coverage_data.performance_metrics | default {
            avg_test_duration: 0
            slowest_test: 0
            fastest_test: 0
            test_distribution: {
                fast: 0
                medium: 0
                slow: 0
            }
        })
        recommendations: (generate_recommendations $coverage_data)
    }

    match $format {
        "json" => { $report | to json --indent 2 }
        "yaml" => { $report | to yaml }
        "toml" => { $report | to toml }
        "html" => { generate_html_report $report }
        _ => { error make { msg: "Unsupported format. Use: json, yaml, toml, or html" } }
    }
}

def generate_recommendations [coverage_data: record] {
    mut recommendations = []

    # Performance recommendations
    let perf_metrics = ($coverage_data.performance_metrics | default {
        avg_test_duration: 0
        slowest_test: 0
        fastest_test: 0
        test_distribution: {
            fast: 0
            medium: 0
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
        ($report.recommendations | each { |rec| $"<li>($rec)</li>" } | str join "\n")
        </ul>
    </body>
    </html>
    "

    $html_template
}

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

def main [] {
    wrap_test "test_example" "unit" {
        assert_equal 1 1 "Example test"
    }

    generate_coverage_report
    export_coverage_report "json" | save coverage.json
}
