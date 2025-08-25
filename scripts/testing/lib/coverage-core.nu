#!/usr/bin/env nu

# Import unified libraries
use ../../lib/validators.nu
use logging.nu *
use ../../lib/logging.nu *


# Core coverage tracking functions for nix-mox
# Provides basic test result tracking and aggregation

export def track_test [name: string, category: string, status: string, duration: float] {
    let test_result = {
        name: $name,
        category: $category,
        status: $status,
        duration: $duration,
        timestamp: (date now | into int)
    }

    # Ensure TEST_TEMP_DIR exists before saving
    let test_temp_dir = ($env | get -o TEST_TEMP_DIR | default "coverage-tmp/nix-mox-tests")
    if not ($test_temp_dir | path exists) {
        mkdir $test_temp_dir
    }

    let filename = $"($test_temp_dir)/test_result_($name | str replace '.nu' '' | str replace '-' '_').json"
    $test_result | to json | save --force $filename
}

export def aggregate_coverage [] {
    let test_temp_dir = ($env | get -o TEST_TEMP_DIR | default "coverage-tmp/nix-mox-tests")
    let result_files = (ls $test_temp_dir | where { |it| ($it.name | path basename) | str starts-with 'test_result_' } | get name)

    mut test_results = []

    for file in $result_files {
        let file_content = (open --raw $file)
        let result = ($file_content | from json)
        $test_results = ($test_results | append $result)
    }

    print $"DEBUG: Found ($test_results | length) test results"

    let total_tests = ($test_results | length)
    let passed_tests = ($test_results | where { |it| $it.status == "passed" } | length)
    let failed_tests = ($test_results | where { |it| $it.status == "failed" } | length)
    let skipped_tests = ($test_results | where { |it| $it.status == "skipped" } | length)

    let durations = ($test_results | where { |it| $it.duration != null } | get duration)
    let total_duration = if ($durations | length) > 0 {
        $durations | math sum
    } else {
        0
    }

    let grouped = ($test_results | group-by category | transpose category tests | each { |row|
        { ($row.category): ($row.tests | length) }
    })

    let categories = if ($grouped | length) > 0 {
        $grouped | reduce { |acc, item| $acc | merge $item }
    } else {
        {}
    }

    {
        total_tests: $total_tests,
        passed_tests: $passed_tests,
        failed_tests: $failed_tests,
        skipped_tests: $skipped_tests,
        test_duration: $total_duration,
        test_categories: $categories,
        test_results: $test_results
    }
}
