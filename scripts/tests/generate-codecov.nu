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

    # Ensure coverage-tmp directory exists
    if not ("coverage-tmp" | path exists) {
        mkdir "coverage-tmp"
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

    # Save in multiple formats and locations for CI compatibility
    $codecov_report | to json | save --force "coverage-tmp/codecov.json"
    $codecov_report | to yaml | save --force "coverage-tmp/codecov.yml"
    
    # Also save to the test temp directory
    $codecov_report | to json | save --force $"($env.TEST_TEMP_DIR)/codecov.json"
    $codecov_report | to yaml | save --force $"($env.TEST_TEMP_DIR)/codecov.yml"

    # Create a minimal coverage report if no tests were run
    if $total == 0 {
        print "⚠️ No tests found, creating minimal coverage report"
        let minimal_report = {
            coverage: {
                total: 1
                passed: 0
                rate: 0
                timestamp: (date now | into int)
                platform: (sys host | get name)
                version: "1.0.0"
            }
            results: [{
                name: "no_tests_run"
                status: "skipped"
                duration: 0
                category: "system"
                timestamp: (date now | into int)
            }]
            categories: {}
        }
        
        $minimal_report | to json | save --force "coverage-tmp/codecov.json"
        $minimal_report | to json | save --force $"($env.TEST_TEMP_DIR)/codecov.json"
    }

    print "Codecov reports generated:"
    print "  - coverage-tmp/codecov.json"
    print "  - coverage-tmp/codecov.yml"
    print "  - ($env.TEST_TEMP_DIR)/codecov.json"
    print "  - ($env.TEST_TEMP_DIR)/codecov.yml"

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
