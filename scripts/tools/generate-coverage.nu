#!/usr/bin/env nu

# Generate coverage reports for nix-mox
# Usage: nu scripts/generate-coverage.nu [--format json|yaml|toml] [--output path]

def main [
    --format: string = "json"  # Output format: json, yaml, or toml
    --output: string = "coverage-report"  # Output file path (without extension)
    --verbose  # Enable verbose output
] {
    if $verbose {
        print "Generating coverage report..."
        print $"Format: ($format)"
        print $"Output: ($output).($format)"
    }

    # Set up test environment
    $env.TEST_TEMP_DIR = "/tmp/nix-mox-coverage-local"
    if not ($env.TEST_TEMP_DIR | path exists) {
        mkdir $env.TEST_TEMP_DIR
    }

    # Run tests with coverage tracking
    if $verbose {
        print "Running tests with coverage tracking..."
    }

    try {
        # Run tests from project root
        nu -c "source scripts/tests/run-tests.nu; run ['--unit', '--integration']"
    } catch {
        if $verbose {
            print $"Warning: Some tests failed: ($env.LAST_ERROR)"
        }
    }

    # Generate coverage report
    if $verbose {
        print "Generating coverage report..."
    }

    # Generate coverage from project root
    nu -c "source scripts/tests/lib/test-coverage.nu; let coverage = aggregate_coverage; $coverage | to json | save --force coverage-data.json"
    let coverage = (open coverage-data.json | from json)

    let report = {
        summary: {
            total_tests: $coverage.total_tests
            passed_tests: $coverage.passed_tests
            failed_tests: $coverage.failed_tests
            skipped_tests: $coverage.skipped_tests
            test_duration: $coverage.test_duration
            pass_rate: (if $coverage.total_tests == 0 { 0 } else { (($coverage.passed_tests | into float) / ($coverage.total_tests | into float) * 100) })
        }
        categories: $coverage.test_categories
        results: $coverage.test_results
        metadata: {
            generated_at: (date now | into string)
            version: "1.0.0"
            format: $format
        }
    }

    # Export in requested format
    let output_file = $"($output).($format)"
    match $format {
        "json" => { $report | to json | save --force $output_file }
        "yaml" => { $report | to yaml | save --force $output_file }
        "toml" => { $report | to toml | save --force $output_file }
        _ => {
            error make {
                msg: $"Unsupported format '($format)'. Use: json, yaml, or toml"
            }
        }
    }

    if $verbose {
        print $"Coverage report saved to: ($output_file)"
        print $"Total tests: ($coverage.total_tests)"
        print $"Passed: ($coverage.passed_tests)"
        print $"Failed: ($coverage.failed_tests)"
        print $"Skipped: ($coverage.skipped_tests)"
        let pass_rate = (if $coverage.total_tests == 0 { 0 } else { (($coverage.passed_tests | into float) / ($coverage.total_tests | into float) * 100) })
        print $"Pass rate: ($pass_rate | into string -d 2)%"
    }

    # Clean up temporary file
    rm -f coverage-data.json

    # Also generate a human-readable summary
    nu -c "source scripts/tests/lib/test-coverage.nu; generate_coverage_report"
}

# Helper function to show coverage summary
export def show_coverage_summary [] {
    nu -c "source scripts/tests/lib/test-coverage.nu; generate_coverage_report"
}

# Helper function to export coverage for CI
export def export_for_ci [format: string = "json"] {
    nu -c "source scripts/tests/lib/test-coverage.nu; export_coverage_report $format"
}
