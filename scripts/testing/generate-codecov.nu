#!/usr/bin/env nu
# Generate Codecov-compatible coverage report for nix-mox
# This generates coverage based on test execution results

export-env {
    use ./lib/test-coverage.nu *
    use ./lib/coverage-core.nu *
}

def main [
    --format: string = "json"  # Output format (json, yaml, toml)
    --verbose                  # Enable verbose output
] {
    print "📊 Generating Codecov coverage report..."

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

    # Analyze coverage data
    let analysis = analyze_coverage $coverage_data.test_results

    # Generate Codecov-compatible report
    let codecov_report = generate_codecov_report $analysis

    # Save Codecov report
    let output_file = $"($env.COVERAGE_DIR)/codecov.json"
    $codecov_report | save --force $output_file

    print $"✅ Codecov report generated: ($output_file)"

    # Generate additional format if requested
    if $format != "json" {
        let report = generate_report $analysis $format
        let format_file = $"($env.COVERAGE_DIR)/coverage.($format)"
        $report | save --force $format_file
        print $"✅ ($format) report generated: ($format_file)"
    }
}

def generate_codecov_report [analysis: record] {
    let summary = $analysis.summary
    let performance = $analysis.performance
    let categories = $analysis.test_categories

    # Calculate coverage percentage
    let coverage_percentage = if $summary.total_tests > 0 {
        (($summary.passed_tests | into float) / ($summary.total_tests | into float)) * 100
    } else {
        0
    }

    # Generate Codecov-compatible format
    {
        coverage: $coverage_percentage,
        total_tests: $summary.total_tests,
        passed_tests: $summary.passed_tests,
        failed_tests: $summary.failed_tests,
        skipped_tests: $summary.skipped_tests,
        timestamp: $summary.timestamp,
        performance: {
            avg_test_duration: $performance.avg_test_duration,
            slowest_test: $performance.slowest_test,
            fastest_test: $performance.fastest_test,
            test_distribution: $performance.test_distribution
        },
        categories: ($categories | each { |cat|
            {
                name: $cat.category,
                total: $cat.total,
                passed: $cat.passed,
                failed: $cat.failed,
                pass_rate: $cat.pass_rate,
                avg_duration: $cat.avg_duration
            }
        }),
        recommendations: $analysis.recommendations,
        metadata: {
            project: "nix-mox",
            coverage_type: "test_execution",
            generated_by: "nix-mox-test-suite",
            version: "1.0.0"
        }
    }
}

# Export for use in other scripts
export def generate_codecov [] {
    main --format json
}

export def generate_codecov_verbose [] {
    main --format json --verbose
}

export def generate_codecov_yaml [] {
    main --format yaml
}

export def generate_codecov_toml [] {
    main --format toml
}

if ($env | get -i NU_TEST | default "false") == "true" {
    # Test mode - do nothing
}
