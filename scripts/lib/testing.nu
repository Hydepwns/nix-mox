#!/usr/bin/env nu
# Functional testing framework for nix-mox
# Replaces test-utils.nu and provides composable testing patterns
# Uses functional composition and Nushell pipelines

use logging.nu *
use validators.nu *

# Test result record structure
export def test_result [
    name: string,
    success: bool,
    message: string = "",
    duration: duration = 0sec,
    details: record = {}
] {
    {
        name: $name,
        success: $success,
        message: $message,
        duration: $duration,
        timestamp: (date now),
        details: $details
    }
}

# Higher-order test runner with timing and error handling
export def run_test [test_name: string, test_func: closure, --timeout: duration = 30sec] {
    let start_time = (date now)
    debug $"Running test: ($test_name)" --context "test"
    
    try {
        # Run the test function directly
        let result = (do $test_func)
        let duration = ((date now) - $start_time)
        
        # Determine success based on result type
        let success = match ($result | describe) {
            "bool" => $result,
            "record" => ($result | get success? | default true),
            _ => true
        }
        
        if $success {
            success $"Test passed: ($test_name) in ($duration)" --context "test"
        } else {
            error $"Test failed: ($test_name) in ($duration)" --context "test"
        }
        
        test_result $test_name $success "" $duration { result: $result }
    } catch { |err|
        let duration = ((date now) - $start_time)
        error $"Test error: ($test_name) - ($err.msg)" --context "test"
        test_result $test_name false $err.msg $duration { error: $err }
    }
}

# Functional assertion library
export def assert [condition, message: string = ""] {
    if $condition {
        test_result "assertion" true $"Assertion passed: ($message)"
    } else {
        test_result "assertion" false $"Assertion failed: ($message)"
    }
}

export def assert_equal [actual: any, expected: any, message: string = ""] {
    let condition = ($actual == $expected)
    let detailed_message = if ($message | is-empty) {
        $"Expected ($expected), got ($actual)"
    } else {
        $"($message): Expected ($expected), got ($actual)"
    }
    assert $condition $detailed_message
}

export def assert_not_equal [actual: any, expected: any, message: string = ""] {
    let condition = ($actual != $expected)
    let detailed_message = if ($message | is-empty) {
        $"Expected not ($expected), but got ($actual)"
    } else {
        $"($message): Expected not ($expected), but got ($actual)"
    }
    assert $condition $detailed_message
}

export def assert_contains [haystack: any, needle: any, message: string = ""] {
    let condition = ($needle in $haystack)
    let detailed_message = if ($message | is-empty) {
        $"Expected ($haystack) to contain ($needle)"
    } else {
        $"($message): Expected to contain ($needle)"
    }
    assert $condition $detailed_message
}

export def assert_file_exists [path: string, message: string = ""] {
    let condition = ($path | path exists)
    let detailed_message = if ($message | is-empty) {
        $"File should exist: ($path)"
    } else {
        $"($message): File should exist: ($path)"
    }
    assert $condition $detailed_message
}

export def assert_command_exists [command: string, message: string = ""] {
    let condition = (which $command | is-not-empty)
    let detailed_message = if ($message | is-empty) {
        $"Command should exist: ($command)"
    } else {
        $"($message): Command should exist: ($command)"
    }
    assert $condition $detailed_message
}

# Test suite runner with functional composition
export def test_suite [
    suite_name: string,
    tests: list<record>,
    --fail-fast = false,
    --parallel = false,
    --timeout: duration = 60sec
] {
    info $"Running test suite: ($suite_name) with ($tests | length) tests" --context "test-suite"
    let start_time = (date now)
    
    let results = if $parallel {
        # Run tests in parallel
        $tests | par-each { |test|
            run_test $test.name $test.func --timeout ($test | get timeout? | default $timeout)
        }
    } else {
        # Run tests sequentially
        $tests | reduce --fold [] { |test, acc|
            let result = (run_test $test.name $test.func --timeout ($test | get timeout? | default $timeout))
            let new_acc = ($acc | append $result)
            
            if $fail_fast and (not $result.success) {
                return $new_acc
            }
            $new_acc
        }
    }
    
    let duration = ((date now) - $start_time)
    let passed = ($results | where success == true | length)
    let failed = ($results | where success == false | length)
    let total = ($results | length)
    
    let suite_success = ($failed == 0)
    
    if $suite_success {
        success $"Test suite passed: ($suite_name) - ($passed)/($total) tests in ($duration)" --context "test-suite"
    } else {
        error $"Test suite failed: ($suite_name) - ($failed)/($total) tests failed in ($duration)" --context "test-suite"
    }
    
    {
        suite: $suite_name,
        success: $suite_success,
        total: $total,
        passed: $passed,
        failed: $failed,
        duration: $duration,
        results: $results
    }
}

# Mock system for testing
export def mock_command [command: string, output: string, exit_code: int = 0] {
    let mock_key = $"MOCK_($command | str upcase)"
    $env | insert $mock_key { output: $output, exit_code: $exit_code }
}

export def run_mocked [command: string, ...args: string] {
    let mock_key = $"MOCK_($command | str upcase)"
    let mock_data = ($env | get $mock_key -o)
    
    if ($mock_data | is-not-empty) {
        {
            stdout: $mock_data.output,
            stderr: "",
            exit_code: $mock_data.exit_code
        }
    } else {
        run-external $command ...$args | complete
    }
}

# Test environment setup
export def setup_test_environment [
    --temp-dir: string = "coverage-tmp/nix-mox-tests",
    --clean = true
] {
    if $clean and ($temp_dir | path exists) {
        rm -rf $temp_dir
    }
    
    mkdir $temp_dir
    $env.NIX_MOX_TEST_DIR = $temp_dir
    $env.NIX_MOX_TEST_MODE = "true"
    
    info $"Test environment setup: ($temp_dir)" --context "test-env"
}

# Cleanup test environment
export def cleanup_test_environment [] {
    let test_dir = ($env | get NIX_MOX_TEST_DIR? | default "coverage-tmp/nix-mox-tests")
    
    if ($test_dir | path exists) {
        rm -rf $test_dir
        debug $"Cleaned up test directory: ($test_dir)" --context "test-env"
    }
    
    # Remove test environment variables if they exist
    try { hide-env NIX_MOX_TEST_DIR }
    try { hide-env NIX_MOX_TEST_MODE }
}

# Property-based testing helper
export def property_test [
    property_name: string,
    generator: closure,
    property_check: closure,
    --iterations: int = 100
] {
    info $"Running property test: ($property_name) with ($iterations) iterations" --context "property-test"
    
    let failures = (0..$iterations | each { |i|
        let test_data = (do $generator)
        try {
            let result = ($test_data | do $property_check)
            if not $result {
                { iteration: $i, data: $test_data }
            } else {
                null
            }
        } catch { |err|
            { iteration: $i, data: $test_data, error: $err.msg }
        }
    } | where $it != null)
    
    let success = ($failures | length) == 0
    if $success {
        success $"Property test passed: ($property_name)" --context "property-test"
    } else {
        error $"Property test failed: ($property_name) - ($failures | length) failures" --context "property-test"
    }
    
    test_result $property_name $success "" 0sec { failures: $failures, iterations: $iterations }
}

# Benchmark testing
export def benchmark_test [
    test_name: string,
    --iterations: int = 10,
    --warmup: int = 3
] {
    |benchmark_func: closure|
    
    info $"Running benchmark: ($test_name)" --context "benchmark"
    
    # Warmup runs
    for _ in 0..$warmup {
        do $benchmark_func | ignore
    }
    
    # Actual benchmark runs
    let times = (0..$iterations | each { |_|
        let start = (date now)
        do $benchmark_func | ignore
        let end = (date now)
        $end - $start
    })
    
    let avg_time = ($times | math avg)
    let min_time = ($times | math min)
    let max_time = ($times | math max)
    
    info $"Benchmark results: ($test_name) - avg: ($avg_time), min: ($min_time), max: ($max_time)" --context "benchmark"
    
    test_result $test_name true "Benchmark completed" $avg_time {
        average: $avg_time,
        minimum: $min_time,
        maximum: $max_time,
        iterations: $iterations,
        all_times: $times
    }
}

# Integration test helpers
export def integration_test [
    test_name: string,
    --setup: closure,
    --teardown: closure
] {
    |test_func: closure|
    
    try {
        # Setup
        if ($setup | is-not-empty) { do $setup }
        
        # Run test
        let result = (run_test $test_name $test_func)
        
        # Always run teardown
        if ($teardown | is-not-empty) {
            try { do $teardown } catch { |err|
                warn $"Teardown failed: ($err.msg)" --context "integration"
            }
        }
        
        $result
    } catch { |err|
        # Ensure teardown runs even if setup fails
        if ($teardown | is-not-empty) {
            try { do $teardown } catch { |_| null }
        }
        test_result $test_name false $"Integration test setup/execution failed: ($err.msg)"
    }
}

# Test report generation
export def generate_test_report [
    results: list<record>,
    --format: string = "json",
    --output-file: string = "test-report"
] {
    let summary = {
        timestamp: (date now),
        total_tests: ($results | length),
        passed: ($results | where success == true | length),
        failed: ($results | where success == false | length),
        total_duration: ($results | get duration | math sum),
        results: $results
    }
    
    match $format {
        "json" => {
            $summary | to json | save $"($output_file).json"
            info $"Test report saved: ($output_file).json" --context "test-report"
        },
        "xml" => {
            # Convert to JUnit XML format
            let xml_content = (test_results_to_junit_xml $summary)
            $xml_content | save $"($output_file).xml"
            info $"Test report saved: ($output_file).xml" --context "test-report"
        },
        _ => {
            error $"Unsupported format: ($format)" --context "test-report"
        }
    }
    
    $summary
}

# Helper to convert results to JUnit XML (simplified)
def test_results_to_junit_xml [summary: record] {
    let tests = ($summary.results | each { |test|
        if $test.success {
            $"    <testcase name=\"($test.name)\" time=\"($test.duration | into int)\" />"
        } else {
            $"    <testcase name=\"($test.name)\" time=\"($test.duration | into int)\">
      <failure message=\"($test.message)\"></failure>
    </testcase>"
        }
    } | str join "\n")
    
    $"<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<testsuite name=\"nix-mox-tests\" tests=\"($summary.total_tests)\" failures=\"($summary.failed)\" time=\"($summary.total_duration | into int)\">
($tests)
</testsuite>"
}