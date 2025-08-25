#!/usr/bin/env nu
# Consolidated test runner for nix-mox
# Integrates with all consolidated systems for comprehensive testing
# Uses functional patterns and proper test orchestration

use lib/logging.nu *
use lib/testing.nu *
use lib/validators.nu *
use lib/platform.nu *
use lib/script-template.nu *

# Main test runner dispatcher
def main [
    suite: string = "all",
    --coverage: bool = false,
    --output: string = "coverage-tmp/test-results",
    --parallel: bool = true,
    --fail-fast: bool = false,
    --verbose: bool = false,
    --watch: bool = false,
    --context: string = "test"
] {
    if $verbose { $env.LOG_LEVEL = "DEBUG" }
    
    script_main "nix-mox test runner" $"Running ($suite) test suite" --context $context {||
        
        # Setup test environment
        setup_test_environment --temp-dir $output
        
        if $watch {
            watch_mode $suite $coverage $output $parallel
            return
        }
        
        # Dispatch to appropriate test suite
        let results = match $suite {
            "all" => (run_all_tests $coverage $output $parallel $fail_fast),
            "unit" => (run_unit_tests $coverage $output $parallel $fail_fast),
            "integration" => (run_integration_tests $coverage $output $parallel $fail_fast),
            "validation" => (run_validation_tests $coverage $output $parallel $fail_fast),
            "platform" => (run_platform_tests $coverage $output $parallel $fail_fast),
            "security" => (run_security_tests $coverage $output $parallel $fail_fast),
            "performance" => (run_performance_tests $coverage $output $parallel $fail_fast),
            "help" => { show_test_help; return },
            _ => {
                error $"Unknown test suite: ($suite). Use 'help' to see available suites."
                return
            }
        }
        
        # Generate test report
        let report = (generate_test_report $results $output)
        
        # Generate coverage report if requested
        if $coverage {
            generate_coverage_report $output
        }
        
        # Cleanup test environment
        cleanup_test_environment
        
        # Exit with appropriate code based on test results
        if not ($results | get -i success | default false) {
            exit 1
        }
        
        $results
    }
}

# Run all test suites
def run_all_tests [coverage: bool, output: string, parallel: bool, fail_fast: bool] {
    with_logging "running all test suites" --context "test-all" {||
        
        let test_suites = [
            { name: "validation", runner: {|| run_validation_tests $coverage $output $parallel $fail_fast } },
            { name: "unit", runner: {|| run_unit_tests $coverage $output $parallel $fail_fast } },
            { name: "platform", runner: {|| run_platform_tests $coverage $output $parallel $fail_fast } },
            { name: "integration", runner: {|| run_integration_tests $coverage $output $parallel $fail_fast } },
            { name: "security", runner: {|| run_security_tests $coverage $output $parallel $fail_fast } }
        ]
        
        mut all_results = []
        mut overall_success = true
        
        for suite in $test_suites {
            info $"Running test suite: ($suite.name)" --context "test-all"
            
            try {
                let result = (do $suite.runner)
                $all_results = ($all_results | append {
                    suite: $suite.name,
                    success: ($result | get -i success | default false),
                    results: $result
                })
                
                if not ($result | get -i success | default false) {
                    $overall_success = false
                    if $fail_fast {
                        break
                    }
                }
            } catch { |err|
                $all_results = ($all_results | append {
                    suite: $suite.name,
                    success: false,
                    error: $err.msg,
                    results: {}
                })
                $overall_success = false
                if $fail_fast {
                    break
                }
            }
        }
        
        let summary = {
            success: $overall_success,
            total_suites: ($test_suites | length),
            passed_suites: ($all_results | where success == true | length),
            failed_suites: ($all_results | where success == false | length),
            suite_results: $all_results,
            timestamp: (date now)
        }
        
        if $overall_success {
            success "All test suites passed!" --context "test-all"
        } else {
            error "Some test suites failed" --context "test-all"
        }
        
        $summary
    }
}

# Run unit tests
def run_unit_tests [coverage: bool, output: string, parallel: bool, fail_fast: bool] {
    with_logging "running unit tests" --context "unit-tests" {||
        
        let unit_tests = [
            { name: "logging_tests", func: {|| test_logging_system } },
            { name: "platform_tests", func: {|| test_platform_detection } },
            { name: "validation_tests", func: {|| test_validation_functions } },
            { name: "command_wrapper_tests", func: {|| test_command_wrappers } },
            { name: "analysis_tests", func: {|| test_analysis_functions } }
        ]
        
        let results = (test_suite "unit_tests" $unit_tests --parallel $parallel --fail-fast $fail_fast)
        
        success $"Unit tests completed: ($results.passed)/($results.total) passed" --context "unit-tests"
        
        $results
    }
}

# Run integration tests
def run_integration_tests [coverage: bool, output: string, parallel: bool, fail_fast: bool] {
    with_logging "running integration tests" --context "integration-tests" {||
        
        let integration_tests = [
            { name: "setup_integration", func: {|| test_setup_integration } },
            { name: "validation_integration", func: {|| test_validation_integration } },
            { name: "storage_integration", func: {|| test_storage_integration } },
            { name: "dashboard_integration", func: {|| test_dashboard_integration } }
        ]
        
        let results = (test_suite "integration_tests" $integration_tests --parallel false --fail-fast $fail_fast)
        
        success $"Integration tests completed: ($results.passed)/($results.total) passed" --context "integration-tests"
        
        $results
    }
}

# Run validation tests
def run_validation_tests [coverage: bool, output: string, parallel: bool, fail_fast: bool] {
    with_logging "running validation tests" --context "validation-tests" {||
        
        # Test our consolidated validation system
        let validation_suites = ["basic", "config", "platform"]
        
        mut validation_results = []
        mut all_passed = true
        
        for suite in $validation_suites {
            try {
                let result = (run-external "nu" "scripts/validate.nu" $suite | complete)
                let success = ($result.exit_code == 0)
                
                $validation_results = ($validation_results | append {
                    suite: $suite,
                    success: $success,
                    exit_code: $result.exit_code,
                    output: $result.stdout
                })
                
                if not $success {
                    $all_passed = false
                    if $fail_fast {
                        break
                    }
                }
            } catch { |err|
                $validation_results = ($validation_results | append {
                    suite: $suite,
                    success: false,
                    error: $err.msg
                })
                $all_passed = false
                if $fail_fast {
                    break
                }
            }
        }
        
        {
            success: $all_passed,
            total: ($validation_suites | length),
            passed: ($validation_results | where success == true | length),
            failed: ($validation_results | where success == false | length),
            results: $validation_results
        }
    }
}

# Run platform tests
def run_platform_tests [coverage: bool, output: string, parallel: bool, fail_fast: bool] {
    with_logging "running platform tests" --context "platform-tests" {||
        
        let platform_tests = [
            { name: "platform_detection", func: {|| test_platform_detection_accuracy } },
            { name: "platform_operations", func: {|| test_platform_operations } },
            { name: "cross_platform_compatibility", func: {|| test_cross_platform_compatibility } }
        ]
        
        let results = (test_suite "platform_tests" $platform_tests --parallel $parallel --fail-fast $fail_fast)
        
        success $"Platform tests completed: ($results.passed)/($results.total) passed" --context "platform-tests"
        
        $results
    }
}

# Run security tests
def run_security_tests [coverage: bool, output: string, parallel: bool, fail_fast: bool] {
    with_logging "running security tests" --context "security-tests" {||
        
        let security_tests = [
            { name: "script_security_scan", func: {|| test_script_security } },
            { name: "file_permissions_check", func: {|| test_file_permissions } },
            { name: "secret_detection", func: {|| test_secret_detection } }
        ]
        
        let results = (test_suite "security_tests" $security_tests --parallel $parallel --fail-fast $fail_fast)
        
        success $"Security tests completed: ($results.passed)/($results.total) passed" --context "security-tests"
        
        $results
    }
}

# Run performance tests
def run_performance_tests [coverage: bool, output: string, parallel: bool, fail_fast: bool] {
    with_logging "running performance tests" --context "performance-tests" {||
        
        let performance_tests = [
            { name: "logging_performance", func: {|| benchmark_logging_performance } },
            { name: "validation_performance", func: {|| benchmark_validation_performance } },
            { name: "platform_detection_performance", func: {|| benchmark_platform_detection } }
        ]
        
        mut benchmark_results = []
        
        for test in $performance_tests {
            let result = (benchmark_test $test.name --iterations 10 $test.func)
            $benchmark_results = ($benchmark_results | append $result)
        }
        
        {
            success: true,
            total: ($performance_tests | length),
            passed: ($benchmark_results | length),
            failed: 0,
            results: $benchmark_results,
            type: "performance"
        }
    }
}

# Watch mode for continuous testing
def watch_mode [suite: string, coverage: bool, output: string, parallel: bool] {
    info "Starting test watch mode..." --context "watch"
    info $"Monitoring test suite: ($suite)" --context "watch"
    info "Press Ctrl+C to stop" --context "watch"
    
    loop {
        clear
        info $"Running tests: ($suite)" --context "watch"
        
        let results = match $suite {
            "all" => (run_all_tests $coverage $output $parallel false),
            "unit" => (run_unit_tests $coverage $output $parallel false),
            "integration" => (run_integration_tests $coverage $output $parallel false),
            _ => (run_validation_tests $coverage $output $parallel false)
        }
        
        display_test_summary $results
        
        info "Waiting 10 seconds for next run..." --context "watch"
        sleep 10sec
    }
}

# Individual test functions
def test_logging_system [] {
    run_test "logging_system_test" {||
        # Test that logging functions work correctly
        info "Test log message" --context "test"
        success "Test success message" --context "test"
        warn "Test warning message" --context "test"
        
        # Test functional logging
        let result = (with_logging "test operation" --context "test" {|| 
            "operation completed"
        })
        
        assert_equal $result "operation completed" "with_logging should return operation result"
        true
    }
}

def test_platform_detection [] {
    run_test "platform_detection_test" {||
        let platform_info = (get_platform)
        
        assert_contains ["linux", "macos", "windows"] $platform_info.normalized "Platform should be detected"
        assert_not_equal $platform_info.arch "" "Architecture should be detected"
        
        true
    }
}

def test_validation_functions [] {
    run_test "validation_functions_test" {||
        # Test basic validation functions
        let nix_validation = (validate_command "nix")
        assert $nix_validation.success "Nix command should be available"
        
        let file_validation = (validate_file "flake.nix")
        assert $file_validation.success "flake.nix should exist"
        
        true
    }
}

def test_command_wrappers [] {
    run_test "command_wrappers_test" {||
        # Test command wrapper functions
        let result = (execute_command ["echo" "test"] --context "test")
        assert ($result.exit_code == 0) "Echo command should succeed"
        assert_contains $result.stdout "test" "Echo output should contain test"
        
        true
    }
}

def test_analysis_functions [] {
    run_test "analysis_functions_test" {||
        # Test analysis pipeline
        let test_data = { value: 42, name: "test" }
        let pipeline_result = (analysis_pipeline {|| $test_data })
        
        assert_equal $pipeline_result.value 42 "Analysis pipeline should preserve data"
        
        true
    }
}

# Integration test functions
def test_setup_integration [] {
    integration_test "setup_integration_test" 
        --setup {|| setup_test_environment }
        --teardown {|| cleanup_test_environment }
        {||
            # Test that setup system works end-to-end
            let result = (run-external "nu" "scripts/setup.nu" "automated" "--dry-run" "--component" "minimal" | complete)
            assert ($result.exit_code == 0) "Setup should complete successfully in dry-run mode"
            true
        }
}

def test_validation_integration [] {
    integration_test "validation_integration_test" {||
        # Test validation system integration
        let result = (run-external "nu" "scripts/validate.nu" "basic" | complete)
        assert ($result.exit_code == 0) "Basic validation should pass"
        true
    }
}

def test_storage_integration [] {
    integration_test "storage_integration_test" {||
        # Test storage system integration
        let result = (run-external "nu" "scripts/storage.nu" "validate" "--dry-run" | complete)
        assert ($result.exit_code == 0) "Storage validation should complete"
        true
    }
}

def test_dashboard_integration [] {
    integration_test "dashboard_integration_test" {||
        # Test dashboard system integration
        let result = (run-external "nu" "scripts/dashboard.nu" "overview" "--output" "tmp/test-dashboard.json" | complete)
        assert ($result.exit_code == 0) "Dashboard should generate successfully"
        assert ("tmp/test-dashboard.json" | path exists) "Dashboard output file should be created"
        true
    }
}

# Platform-specific test functions
def test_platform_detection_accuracy [] {
    run_test "platform_detection_accuracy" {||
        let platform_info = (get_platform)
        let platform_report = (platform_report)
        
        # Validate platform info structure
        assert_contains $platform_info "normalized" "Platform info should have normalized field"
        assert_contains $platform_info "arch" "Platform info should have arch field"
        
        # Validate platform report
        assert_contains $platform_report "platform" "Platform report should include platform info"
        assert_contains $platform_report "capabilities" "Platform report should include capabilities"
        
        true
    }
}

def test_platform_operations [] {
    run_test "platform_operations_test" {||
        # Test platform-specific operations
        let maintenance_result = (maintenance_pipeline)
        
        assert_contains $maintenance_result "platform" "Maintenance should include platform info"
        assert_contains $maintenance_result "completed_tasks" "Maintenance should report completed tasks"
        
        true
    }
}

def test_cross_platform_compatibility [] {
    run_test "cross_platform_compatibility" {||
        # Test that our scripts work across platforms
        let platform_info = (get_platform)
        
        # Test platform-aware file paths
        let paths = (get_platform_paths)
        assert_contains $paths "config_home" "Platform paths should include config_home"
        
        true
    }
}

# Security test functions
def test_script_security [] {
    run_test "script_security_scan" {||
        # Test security scanning functionality
        let security_analysis = (analyze_security_posture)
        
        assert_contains $security_analysis "file_permissions" "Security analysis should check file permissions"
        assert_contains $security_analysis "dangerous_patterns" "Security analysis should check for dangerous patterns"
        
        true
    }
}

def test_file_permissions [] {
    run_test "file_permissions_check" {||
        # Test file permission validation
        let script_files = (glob "scripts/**/*.nu")
        
        # Check that script files have reasonable permissions
        for file in $script_files {
            let perms = (ls -la $file | get mode | get 0)
            assert (not ($perms | str contains "w" and $perms | str contains "o")) "Scripts should not be world-writable"
        }
        
        true
    }
}

def test_secret_detection [] {
    run_test "secret_detection_test" {||
        # Test that we don't accidentally commit secrets
        let secret_check = (check_for_exposed_secrets)
        
        # This is a placeholder - in real implementation would be more sophisticated
        assert_contains $secret_check "patterns_checked" "Secret detection should report patterns checked"
        
        true
    }
}

# Performance benchmarks
def benchmark_logging_performance [] {
    # Benchmark logging system performance
    let iterations = 1000
    let start_time = (date now)
    
    for i in 0..$iterations {
        info $"Test message ($i)" --context "benchmark"
    }
    
    let end_time = (date now)
    let duration = ($end_time - $start_time)
    
    {
        test: "logging_performance",
        iterations: $iterations,
        duration: $duration,
        avg_per_message: ($duration / $iterations)
    }
}

def benchmark_validation_performance [] {
    # Benchmark validation system performance
    benchmark_test "validation_performance" --iterations 50 {||
        validate_command "nu"
        validate_file "flake.nix"
        validate_directory "scripts"
    }
}

def benchmark_platform_detection [] {
    # Benchmark platform detection performance
    benchmark_test "platform_detection_performance" --iterations 100 {||
        get_platform | ignore
        platform_report | ignore
    }
}

# Report generation
def generate_test_report [results: record, output_dir: string] {
    let report_file = $"($output_dir)/test-report.json"
    
    let test_report = {
        metadata: {
            generated_at: (date now),
            generator: "nix-mox test runner",
            version: "2.0.0"
        },
        summary: {
            success: ($results | get -i success | default false),
            total_suites: ($results | get -i total_suites | default 1),
            passed_suites: ($results | get -i passed_suites | default 0),
            failed_suites: ($results | get -i failed_suites | default 0)
        },
        results: $results
    }
    
    $test_report | to json | save $report_file
    success $"Test report saved: ($report_file)" --context "test-report"
    
    $test_report
}

def generate_coverage_report [output_dir: string] {
    info "Generating coverage report..." --context "coverage"
    
    try {
        let coverage_result = (run-external "nu" "scripts/coverage.nu" "all" "--output" $output_dir | complete)
        if $coverage_result.exit_code == 0 {
            success "Coverage report generated successfully" --context "coverage"
        } else {
            warn "Coverage report generation had issues" --context "coverage"
        }
    } catch { |err|
        error $"Failed to generate coverage report: ($err.msg)" --context "coverage"
    }
}

def display_test_summary [results: record] {
    print "=== Test Summary ==="
    print ""
    
    if "success" in $results {
        let status = if $results.success { "PASSED" } else { "FAILED" }
        let color = if $results.success { "green" } else { "red" }
        print $"Overall Status: (ansi $color)($status)(ansi reset)"
    }
    
    if "total_suites" in $results {
        print $"Test Suites: ($results.passed_suites)/($results.total_suites) passed"
    }
    
    if "total" in $results {
        print $"Tests: ($results.passed)/($results.total) passed"
    }
    
    print ""
}

def show_test_help [] {
    format_help "nix-mox test runner" "Consolidated testing system with full integration" "nu test.nu <suite> [options]" [
        { name: "all", description: "Run all test suites (default)" }
        { name: "unit", description: "Run unit tests only" }
        { name: "integration", description: "Run integration tests" }
        { name: "validation", description: "Run validation system tests" }
        { name: "platform", description: "Run platform compatibility tests" }
        { name: "security", description: "Run security analysis tests" }
        { name: "performance", description: "Run performance benchmarks" }
    ] [
        { name: "coverage", description: "Generate coverage report" }
        { name: "output", description: "Output directory for results (default: coverage-tmp/test-results)" }
        { name: "parallel", description: "Run tests in parallel (default: true)" }
        { name: "fail-fast", description: "Stop on first failure" }
        { name: "verbose", description: "Enable verbose output" }
        { name: "watch", description: "Continuous testing mode" }
    ] [
        { command: "nu test.nu all --coverage", description: "Run all tests with coverage" }
        { command: "nu test.nu unit --parallel", description: "Run unit tests in parallel" }
        { command: "nu test.nu integration --fail-fast", description: "Run integration tests, stop on failure" }
        { command: "nu test.nu all --watch", description: "Continuous testing mode" }
    ]
}

# If script is run directly, call main with arguments
if not ($nu.scope.args | is-empty) {
    main ...$nu.scope.args
}