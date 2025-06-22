#!/usr/bin/env nu
# Generate codecov-compatible coverage reports

use ./lib/test-coverage.nu
use ./lib/coverage-core.nu

def main [] {
    print "Generating codecov coverage report..."

    # Set up test environment if not already set
    if ($env.TEST_TEMP_DIR? | is-empty) {
        $env.TEST_TEMP_DIR = "coverage-tmp/nix-mox-tests"
    }

    # Ensure coverage directory exists
    if not ($env.TEST_TEMP_DIR | path exists) {
        mkdir $env.TEST_TEMP_DIR
    }

    # Generate the coverage report
    let coverage_data = aggregate_coverage
    let total = $coverage_data.total_tests
    let passed = $coverage_data.passed_tests
    let pass_rate = if $total == 0 { 0 } else { (($passed | into float) / ($total | into float) * 100) }

    # Create codecov-compatible format
    let codecov_report = {
        coverage: {
            total: $total
            passed: $passed
            rate: $pass_rate
            timestamp: (date now | into int)
            platform: (sys host | get name)
            version: "1.0.0"
        }
        results: ($coverage_data.test_results | each { |test|
            {
                name: $test.name
                status: $test.status
                duration: $test.duration
                category: $test.category
                timestamp: $test.timestamp
            }
        })
        categories: $coverage_data.test_categories
    }

    # Save in multiple formats
    $codecov_report | to json | save --force "coverage-tmp/codecov.json"
    $codecov_report | to yaml | save --force "coverage-tmp/codecov.yml"

    print "Codecov reports generated:"
    print "  - coverage-tmp/codecov.json"
    print "  - coverage-tmp/codecov.yml"

    # Print summary
    print $"Coverage Summary:"
    print $"  Total Tests: ($total)"
    print $"  Passed: ($passed)"
    print $"  Pass Rate: ($pass_rate)%"
}

if ($env.NU_TEST? == "true") {
    main
}
main
