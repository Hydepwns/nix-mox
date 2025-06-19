# Core coverage logic for nix-mox
# This file provides file-based coverage tracking

export-env {
    use ./test-common.nu *
    setup_test_env
}

use ./test-common.nu *

# --- Coverage Tracking ---
export def track_test [name: string, category: string, status: string, duration: float] {
    let coverage_dir = $env.TEST_TEMP_DIR
    let test_result = {
        name: $name
        category: $category
        status: $status
        duration: $duration
        timestamp: (date now | into int)
    }

    # Write individual test result to a file
    let filename = $"($coverage_dir)/test_result_($name | str replace '.nu' '' | str replace '-' '_').json"
    $test_result | to json | save --force $filename
    print $"DEBUG: Created coverage file: ($filename)"
}

# --- Coverage Aggregation ---
export def aggregate_coverage [] {
    let coverage_dir = $env.TEST_TEMP_DIR
    print $"DEBUG: aggregate_coverage called with coverage_dir = ($coverage_dir)"

    let all_files = (ls $coverage_dir | get name)
    print $"DEBUG: All files in ($coverage_dir): ($all_files)"

    let result_files = (ls $coverage_dir | where { |it| ($it.name | path basename) | str starts-with 'test_result_' } | get name)
    mut test_results = ([])
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
    let total_duration = ($test_results | where { |it| $it.duration != null } | get duration | math sum)

    let categories = ($test_results | group-by category | transpose category tests | each { |row|
        { ($row.category): ($row.tests | length) }
    } | reduce { |acc, item| $acc | merge $item })

    {
        total_tests: $total_tests
        passed_tests: $passed_tests
        failed_tests: $failed_tests
        skipped_tests: $skipped_tests
        test_duration: $total_duration
        test_categories: $categories
        test_results: $test_results
    }
}