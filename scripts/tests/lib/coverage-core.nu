
export def track_test [name: string, category: string, status: string, duration: float] {

    let test_result = {
        name: $name
        category: $category
        status: $status
        duration: $duration
        timestamp: (date now | into int)
    }

    let filename = $"($env.TEST_TEMP_DIR)/test_result_($name | str replace '.nu' '' | str replace '-' '_').json"
    $test_result | to json | save --force $filename
}

export def aggregate_coverage [] {
    let result_files = (ls $env.TEST_TEMP_DIR | where { |it| ($it.name | path basename) | str starts-with 'test_result_' } | get name)
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
