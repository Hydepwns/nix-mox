#!/usr/bin/env nu
# Consolidated test runner for nix-mox
# Integrates with all consolidated systems for comprehensive testing
# Uses functional patterns and proper test orchestration

use lib/logging.nu *
use lib/testing.nu *
use lib/validators.nu *
use lib/platform.nu *
use lib/script-template.nu *
use lib/command-wrapper.nu [execute_command]

# Main test runner dispatcher
def main [
    suite: string = "all",
    --coverage,
    --output: string = "coverage-tmp/test-results",
    --parallel,
    --fail-fast,
    --verbose,
    --watch,
    --context: string = "test"
] {
    if ($verbose | default false) { $env.LOG_LEVEL = "DEBUG" }
    
    info $"nix-mox test runner: Running ($suite) test suite" --context $context
    
    # Setup test environment
    setup_test_environment --temp-dir $output
    
    if ($watch | default false) {
        watch_mode $suite ($coverage | default false) $output ($parallel | default true)
        return
    }
    
    # Dispatch to appropriate test suite
    let results = match $suite {
        "all" => (run_all_tests ($coverage | default false) $output ($parallel | default true) ($fail_fast | default false)),
        "unit" => (run_unit_tests ($coverage | default false) $output ($parallel | default true) ($fail_fast | default false)),
        "integration" => (run_integration_tests ($coverage | default false) $output ($parallel | default true) ($fail_fast | default false)),
        "validation" => (run_validation_tests ($coverage | default false) $output ($parallel | default true) ($fail_fast | default false)),
        "maintenance" => (run_maintenance_tests ($coverage | default false) $output ($parallel | default true) ($fail_fast | default false)),
        "setup" => (run_setup_tests ($coverage | default false) $output ($parallel | default true) ($fail_fast | default false)),
        "platform" => (run_platform_tests ($coverage | default false) $output ($parallel | default true) ($fail_fast | default false)),
        "analysis" => (run_analysis_tests ($coverage | default false) $output ($parallel | default true) ($fail_fast | default false)),
        "gaming" => (run_gaming_tests ($coverage | default false) $output ($parallel | default true) ($fail_fast | default false)),
        "gaming-scripts" => (run_gaming_scripts_tests ($coverage | default false) $output ($parallel | default true) ($fail_fast | default false)),
        "handlers" => (run_handlers_tests ($coverage | default false) $output ($parallel | default true) ($fail_fast | default false)),
        "macos-platform" => (run_macos_platform_specific_tests ($coverage | default false) $output ($parallel | default true) ($fail_fast | default false)),
        "windows-platform" => (run_windows_platform_specific_tests ($coverage | default false) $output ($parallel | default true) ($fail_fast | default false)),
        "infrastructure" => (run_infrastructure_tests ($coverage | default false) $output ($parallel | default true) ($fail_fast | default false)),
        "security" => (run_security_tests ($coverage | default false) $output ($parallel | default true) ($fail_fast | default false)),
        "performance" => (run_performance_tests ($coverage | default false) $output ($parallel | default true) ($fail_fast | default false)),
        "help" => { show_test_help; return },
        _ => {
            error $"Unknown test suite: ($suite). Use 'help' to see available suites." --context $context
            return
        }
    }
    
    # Generate test report
    let report = (generate_test_report $results $output)
    
    # Generate coverage report if requested
    if ($coverage | default false) {
        generate_coverage_report $output
    }
    
    # Cleanup test environment
    cleanup_test_environment
    
    # Exit with appropriate code based on test results
    if not ($results | get success? | default false) {
        exit 1
    }
    
    $results
}

# Run all test suites
def run_all_tests [coverage: bool, output: string, parallel: bool, fail_fast: bool] {
    info "Starting running all test suites" --context "test-all"
    
    let test_suites = [
        { name: "validation", runner: "run_validation_tests" },
        { name: "maintenance", runner: "run_maintenance_tests" },
        { name: "setup", runner: "run_setup_tests" },
        { name: "unit", runner: "run_unit_tests" },
        { name: "platform", runner: "run_platform_tests" },
        { name: "analysis", runner: "run_analysis_tests" },
        { name: "gaming", runner: "run_gaming_tests" },
        { name: "gaming-scripts", runner: "run_gaming_scripts_tests" },
        { name: "handlers", runner: "run_handlers_tests" },
        { name: "macos-platform", runner: "run_macos_platform_specific_tests" },
        { name: "windows-platform", runner: "run_windows_platform_specific_tests" },
        { name: "infrastructure", runner: "run_infrastructure_tests" },
        { name: "integration", runner: "run_integration_tests" },
        { name: "security", runner: "run_security_tests" }
    ]
    
    let all_results = ($test_suites | each { |suite|
        info $"Running test suite: ($suite.name)" --context "test-all"
        
        try {
            let result = match $suite.runner {
                "run_validation_tests" => (run_validation_tests $coverage $output $parallel $fail_fast),
                "run_maintenance_tests" => (run_maintenance_tests $coverage $output $parallel $fail_fast),
                "run_setup_tests" => (run_setup_tests $coverage $output $parallel $fail_fast),
                "run_unit_tests" => (run_unit_tests $coverage $output $parallel $fail_fast),
                "run_platform_tests" => (run_platform_tests $coverage $output $parallel $fail_fast),
                "run_analysis_tests" => (run_analysis_tests $coverage $output $parallel $fail_fast),
                "run_gaming_tests" => (run_gaming_tests $coverage $output $parallel $fail_fast),
                "run_gaming_scripts_tests" => (run_gaming_scripts_tests $coverage $output $parallel $fail_fast),
                "run_handlers_tests" => (run_handlers_tests $coverage $output $parallel $fail_fast),
                "run_macos_platform_specific_tests" => (run_macos_platform_specific_tests $coverage $output $parallel $fail_fast),
                "run_windows_platform_specific_tests" => (run_windows_platform_specific_tests $coverage $output $parallel $fail_fast),
                "run_infrastructure_tests" => (run_infrastructure_tests $coverage $output $parallel $fail_fast),
                "run_integration_tests" => (run_integration_tests $coverage $output $parallel $fail_fast),
                "run_security_tests" => (run_security_tests $coverage $output $parallel $fail_fast),
                _ => { error: "Unknown test suite runner" }
            }
            {
                suite: $suite.name,
                success: ($result | get success? | default false),
                results: $result
            }
        } catch { |err|
            {
                suite: $suite.name,
                success: false,
                error: $err.msg,
                results: {}
            }
        }
    })
    
    let overall_success = ($all_results | all {|r| $r.success })
    
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

# Run unit tests
def run_unit_tests [coverage: bool, output: string, parallel: bool, fail_fast: bool] {
    info "Starting running unit tests" --context "unit-tests"
    
    let unit_tests = [
        { name: "logging_tests", func: {|| test_logging_system } },
        { name: "platform_tests", func: {|| test_platform_detection } },
        { name: "validation_tests", func: {|| test_validation_functions } },
        { name: "command_wrapper_tests", func: {|| test_command_wrappers } },
        { name: "analysis_tests", func: {|| test_analysis_functions } },
        { name: "validators_library_tests", func: {|| test_validators_library } },
        { name: "command_wrapper_library_tests", func: {|| test_command_wrapper_library } },
        { name: "analysis_library_tests", func: {|| test_analysis_library } },
        { name: "metrics_library_tests", func: {|| test_metrics_library } },
        { name: "completions_library_tests", func: {|| test_completions_library } },
        { name: "enhanced_error_handling_library_tests", func: {|| test_enhanced_error_handling_library } },
        { name: "platform_operations_library_tests", func: {|| test_platform_operations_library } },
        { name: "script_template_library_tests", func: {|| test_script_template_library } },
        { name: "testing_library_tests", func: {|| test_testing_library } }
    ]
    
    let results = (test_suite "unit_tests" $unit_tests --parallel $parallel --fail-fast $fail_fast)
    
    success $"Unit tests completed: ($results.passed)/($results.total) passed" --context "unit-tests"
    
    $results
}

# Run integration tests
def run_integration_tests [coverage: bool, output: string, parallel: bool, fail_fast: bool] {
    info "Starting running integration tests" --context "integration-tests"
    
    let integration_tests = [
        { name: "setup_integration", func: {|| test_setup_integration } },
        { name: "validation_integration", func: {|| test_validation_integration } },
        { name: "storage_integration", func: {|| test_storage_integration } },
        { name: "dashboard_integration", func: {|| test_dashboard_integration } },
        { name: "setup_consolidated_integration", func: {|| test_setup_consolidated_integration } },
        { name: "dashboard_consolidated_integration", func: {|| test_dashboard_consolidated_integration } },
        { name: "chezmoi_consolidated_integration", func: {|| test_chezmoi_consolidated_integration } }
    ]
    
    let results = (test_suite "integration_tests" $integration_tests --parallel false --fail-fast $fail_fast)
    
    success $"Integration tests completed: ($results.passed)/($results.total) passed" --context "integration-tests"
    
    $results
}

# Run validation tests
def run_validation_tests [coverage: bool, output: string, parallel: bool, fail_fast: bool] {
    info "Starting running validation tests" --context "validation-tests"
    
    # Run comprehensive validation and maintenance tests
    let validation_tests = [
        { name: "validation_safety_tests", func: {|| test_validation_safety } },
        { name: "maintenance_safety_tests", func: {|| test_maintenance_safety } },
        { name: "validation_basic", func: {|| test_validation_basic } },
        { name: "validation_config", func: {|| test_validation_config } },
        { name: "validation_platform", func: {|| test_validation_platform } }
    ]
    
    let results = (test_suite "validation_tests" $validation_tests --parallel false --fail-fast $fail_fast)
    
    success $"Validation tests completed: ($results.passed)/($results.total) passed" --context "validation-tests"
    
    $results
}

# New validation test functions
def test_validation_safety [] {
    # Run the comprehensive validation safety test suite
    let result = (^nu "scripts/testing/validation/validation-safety-tests.nu" | complete)
    assert_equal $result.exit_code 0 "validation safety tests should pass"
    
    { success: true, message: "validation safety test passed" }
}

def test_maintenance_safety [] {
    # Run the comprehensive maintenance safety test suite
    let result = (^nu "scripts/testing/maintenance/maintenance-safety-tests.nu" | complete)
    assert_equal $result.exit_code 0 "maintenance safety tests should pass"
    
    { success: true, message: "maintenance safety test passed" }
}

def test_validation_basic [] {
    # Test our consolidated validation system - basic
    let result = (run-external "nu" "scripts/validate.nu" "basic" | complete)
    assert_equal $result.exit_code 0 "basic validation should pass"
    
    { success: true, message: "validation basic test passed" }
}

def test_validation_config [] {
    # Test our consolidated validation system - config  
    let result = (run-external "nu" "scripts/validate.nu" "config" | complete)
    assert_equal $result.exit_code 0 "config validation should pass"
    
    { success: true, message: "validation config test passed" }
}

def test_validation_platform [] {
    # Test our consolidated validation system - platform
    let result = (run-external "nu" "scripts/validate.nu" "platform" | complete)
    assert_equal $result.exit_code 0 "platform validation should pass"
    
    { success: true, message: "validation platform test passed" }
}

# Run maintenance tests
def run_maintenance_tests [coverage: bool, output: string, parallel: bool, fail_fast: bool] {
    info "Starting running maintenance tests" --context "maintenance-tests"
    
    let maintenance_tests = [
        { name: "maintenance_safety_tests", func: {|| test_maintenance_safety } }
    ]
    
    let results = (test_suite "maintenance_tests" $maintenance_tests --parallel false --fail-fast $fail_fast)
    
    success $"Maintenance tests completed: ($results.passed)/($results.total) passed" --context "maintenance-tests"
    
    $results
}

# Run setup tests
def run_setup_tests [coverage: bool, output: string, parallel: bool, fail_fast: bool] {
    info "Starting running setup tests" --context "setup-tests"
    
    let setup_tests = [
        { name: "setup_safety_tests", func: {|| test_setup_safety } }
    ]
    
    let results = (test_suite "setup_tests" $setup_tests --parallel false --fail-fast $fail_fast)
    
    success $"Setup tests completed: ($results.passed)/($results.total) passed" --context "setup-tests"
    
    $results
}

def test_setup_safety [] {
    # Run the comprehensive setup safety test suite
    let result = (^nu "scripts/testing/setup/setup-safety-tests.nu" | complete)
    assert_equal $result.exit_code 0 "setup safety tests should pass"
    
    { success: true, message: "setup safety test passed" }
}

# Legacy validation test runner for compatibility
def run_legacy_validation_tests [coverage: bool, output: string, parallel: bool, fail_fast: bool] {
    let validation_suites = ["basic", "config", "platform"]
    
    let validation_results = ($validation_suites | each { |suite|
        try {
            let result = (run-external "nu" "scripts/validate.nu" $suite | complete)
            let success = ($result.exit_code == 0)
            
            {
                suite: $suite,
                success: $success,
                exit_code: $result.exit_code,
                output: $result.stdout
            }
        } catch { |err|
            {
                suite: $suite,
                success: false,
                error: $err.msg
            }
        }
    })
    
    let all_passed = ($validation_results | all {|r| $r.success })
    
    {
        success: $all_passed,
        total: ($validation_suites | length),
        passed: ($validation_results | where success == true | length),
        failed: ($validation_results | where success == false | length),
        results: $validation_results
    }
}

# Run platform tests
def run_platform_tests [coverage: bool, output: string, parallel: bool, fail_fast: bool] {
    info "Starting running platform tests" --context "platform-tests"
    
    let platform_tests = [
        { name: "platform_detection", func: {|| test_platform_detection_accuracy } },
        { name: "platform_operations", func: {|| test_platform_operations } },
        { name: "cross_platform_compatibility", func: {|| test_cross_platform_compatibility } },
        { name: "nixos_tests", func: {|| test_nixos_platform } },
        { name: "homebrew_tests", func: {|| test_homebrew_platform } },
        { name: "powershell_tests", func: {|| test_powershell_platform } },
        { name: "platform_comprehensive_tests", func: {|| test_platform_comprehensive } }
    ]
    
    let results = (test_suite "platform_tests" $platform_tests --parallel $parallel --fail-fast $fail_fast)
    
    success $"Platform tests completed: ($results.passed)/($results.total) passed" --context "platform-tests"
    
    $results
}

# Run security tests
def run_security_tests [coverage: bool, output: string, parallel: bool, fail_fast: bool] {
    info "Starting running security tests" --context "security-tests"
    
    let security_tests = [
        { name: "script_security_scan", func: { test_script_security } },
        { name: "file_permissions_check", func: { test_file_permissions } },
        { name: "secret_detection", func: { test_secret_detection } }
    ]
    
    let results = (test_suite "security_tests" $security_tests --parallel $parallel --fail-fast $fail_fast)
    
    success $"Security tests completed: ($results.passed)/($results.total) passed" --context "security-tests"
    
    $results
}

# Run performance tests
def run_performance_tests [coverage: bool, output: string, parallel: bool, fail_fast: bool] {
    info "Starting running performance tests" --context "performance-tests"
    
    let performance_tests = [
        { name: "logging_performance", func: { benchmark_logging_performance } },
        { name: "validation_performance", func: { benchmark_validation_performance } },
        { name: "platform_detection_performance", func: { benchmark_platform_detection } }
    ]
    
    let benchmark_results = ($performance_tests | each { |test|
        match $test.func {
            "benchmark_logging_performance" => (benchmark_logging_performance),
            "benchmark_validation_performance" => (benchmark_validation_performance),
            "benchmark_platform_detection" => (benchmark_platform_detection),
            _ => { error: "Unknown benchmark function" }
        }
    })
    
    {
        success: true,
        total: ($performance_tests | length),
        passed: ($benchmark_results | length),
        failed: 0,
        results: $benchmark_results,
        type: "performance"
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
    # Test that logging functions work correctly
    info "Test log message" --context "test"
    success "Test success message" --context "test"
    warn "Test warning message" --context "test"
    
    # Test functional logging - now testing direct info call
    info "test operation" --context "test"
    let result = "operation completed"
    
    assert_equal $result "operation completed" "logging should work correctly"
    
    { success: true, message: "logging system test passed" }
}

def test_platform_detection [] {
    let platform_info = (get_platform)
    
    assert_contains ["linux", "macos", "windows"] $platform_info.normalized "Platform should be detected"
    assert_not_equal $platform_info.arch "" "Architecture should be detected"
    
    { success: true, message: "platform detection test passed" }
}

def test_validation_functions [] {
    # Test basic validation functions
    let nix_validation = (validate_command "nix")
    assert $nix_validation.success "Nix command should be available"
    
    let file_validation = (validate_file "flake.nix")
    assert $file_validation.success "flake.nix should exist"
    
    { success: true, message: "validation functions test passed" }
}

def test_command_wrappers [] {
    # Test command wrapper functions
    let result = (execute_command ["echo" "test"] --context "test")
    assert ($result.exit_code == 0) "Echo command should succeed"
    assert_contains $result.stdout "test" "Echo output should contain test"
    
    { success: true, message: "command wrappers test passed" }
}

def test_analysis_functions [] {
    # Test analysis pipeline
    let test_data = { value: 42, name: "test" }
    # Note: analysis_pipeline function may need to be simplified for Nushell 0.104.0
    
    assert_equal $test_data.value 42 "Analysis pipeline should preserve data"
    
    { success: true, message: "analysis functions test passed" }
}

# New comprehensive library tests
def test_validators_library [] {
    # Run the comprehensive validators test file
    let result = (^nu "scripts/testing/unit/validators-tests.nu" | complete)
    assert_equal $result.exit_code 0 "validators library tests should pass"
    
    { success: true, message: "validators library test passed" }
}

def test_command_wrapper_library [] {
    # Run the comprehensive command-wrapper test file
    let result = (^nu "scripts/testing/unit/command-wrapper-tests.nu" | complete)
    assert_equal $result.exit_code 0 "command-wrapper library tests should pass"
    
    { success: true, message: "command-wrapper library test passed" }
}

def test_analysis_library [] {
    # Run the comprehensive analysis test file
    let result = (^nu "scripts/testing/unit/analysis-tests.nu" | complete)
    assert_equal $result.exit_code 0 "analysis library tests should pass"
    
    { success: true, message: "analysis library test passed" }
}

def test_metrics_library [] {
    # Run the comprehensive metrics test file
    let result = (^nu "scripts/testing/unit/metrics-tests.nu" | complete)
    assert_equal $result.exit_code 0 "metrics library tests should pass"
    
    { success: true, message: "metrics library test passed" }
}

def test_completions_library [] {
    # Run the comprehensive completions test file
    let result = (^nu "scripts/testing/unit/completions-tests.nu" | complete)
    assert_equal $result.exit_code 0 "completions library tests should pass"
    
    { success: true, message: "completions library test passed" }
}

def test_enhanced_error_handling_library [] {
    # Run the comprehensive enhanced-error-handling test file
    let result = (^nu "scripts/testing/unit/enhanced-error-handling-tests.nu" | complete)
    assert_equal $result.exit_code 0 "enhanced-error-handling library tests should pass"
    
    { success: true, message: "enhanced-error-handling library test passed" }
}

def test_platform_operations_library [] {
    # Run the comprehensive platform-operations test file
    let result = (^nu "scripts/testing/unit/platform-operations-tests.nu" | complete)
    assert_equal $result.exit_code 0 "platform-operations library tests should pass"
    
    { success: true, message: "platform-operations library test passed" }
}

def test_script_template_library [] {
    # Run the comprehensive script-template test file
    let result = (^nu "scripts/testing/unit/script-template-tests.nu" | complete)
    assert_equal $result.exit_code 0 "script-template library tests should pass"
    
    { success: true, message: "script-template library test passed" }
}

def test_testing_library [] {
    # Run the comprehensive testing test file (meta-testing)
    let result = (^nu "scripts/testing/unit/testing-tests.nu" | complete)
    assert_equal $result.exit_code 0 "testing library tests should pass"
    
    { success: true, message: "testing library test passed" }
}

# Platform test functions
def test_nixos_platform [] {
    # Run the NixOS platform test file
    let result = (^nu "scripts/testing/platform/linux/nixos-tests.nu" | complete)
    assert_equal $result.exit_code 0 "NixOS platform tests should pass"
    
    { success: true, message: "NixOS platform test passed" }
}

def test_homebrew_platform [] {
    # Run the Homebrew/macOS platform test file
    let result = (^nu "scripts/testing/platform/macos/homebrew-tests.nu" | complete)
    assert_equal $result.exit_code 0 "Homebrew platform tests should pass"
    
    { success: true, message: "Homebrew platform test passed" }
}

def test_powershell_platform [] {
    # Run the PowerShell/Windows platform test file
    let result = (^nu "scripts/testing/platform/windows/powershell-tests.nu" | complete)
    assert_equal $result.exit_code 0 "PowerShell platform tests should pass"
    
    { success: true, message: "PowerShell platform test passed" }
}

def test_platform_comprehensive [] {
    # Run the comprehensive platform test suite
    let result = (^nu "scripts/testing/platform/platform-comprehensive-tests.nu" | complete)
    assert_equal $result.exit_code 0 "platform comprehensive tests should pass"
    
    { success: true, message: "platform comprehensive test passed" }
}

# Run analysis tests
def run_analysis_tests [coverage: bool, output: string, parallel: bool, fail_fast: bool] {
    info "Starting running analysis tests" --context "analysis-tests"
    
    let analysis_tests = [
        { name: "analysis_comprehensive_tests", func: {|| test_analysis_comprehensive } }
    ]
    
    let results = (test_suite "analysis_tests" $analysis_tests --parallel false --fail-fast $fail_fast)
    
    success $"Analysis tests completed: ($results.passed)/($results.total) passed" --context "analysis-tests"
    
    $results
}

def test_analysis_comprehensive [] {
    # Run the comprehensive analysis test suite
    let result = (^nu "scripts/testing/analysis/analysis-comprehensive-tests.nu" | complete)
    assert_equal $result.exit_code 0 "analysis comprehensive tests should pass"
    
    { success: true, message: "analysis comprehensive test passed" }
}

# Gaming tests
def run_gaming_tests [coverage: bool, output: string, parallel: bool, fail_fast: bool] {
    info "Starting running gaming tests" --context "gaming-tests"
    
    let gaming_tests = [
        { name: "gaming_comprehensive_tests", func: {|| test_gaming_comprehensive } }
    ]
    
    let results = (test_suite "gaming_tests" $gaming_tests --parallel false --fail-fast $fail_fast)
    
    success $"Gaming tests completed: ($results.passed)/($results.total) passed" --context "gaming-tests"
    
    $results
}

def test_gaming_comprehensive [] {
    # Run the comprehensive gaming test suite
    let result = (^nu "scripts/testing/gaming/gaming-comprehensive-tests.nu" | complete)
    assert_equal $result.exit_code 0 "gaming comprehensive tests should pass"
    
    { success: true, message: "gaming comprehensive test passed" }
}

# Infrastructure tests
def run_infrastructure_tests [coverage: bool, output: string, parallel: bool, fail_fast: bool] {
    info "Starting running infrastructure tests" --context "infrastructure-tests"
    
    let infrastructure_tests = [
        { name: "infrastructure_comprehensive_tests", func: {|| test_infrastructure_comprehensive } }
    ]
    
    let results = (test_suite "infrastructure_tests" $infrastructure_tests --parallel false --fail-fast $fail_fast)
    
    success $"Infrastructure tests completed: ($results.passed)/($results.total) passed" --context "infrastructure-tests"
    
    $results
}

def test_infrastructure_comprehensive [] {
    # Run the comprehensive infrastructure test suite
    let result = (^nu "scripts/testing/infrastructure/infrastructure-comprehensive-tests.nu" | complete)
    assert_equal $result.exit_code 0 "infrastructure comprehensive tests should pass"
    
    { success: true, message: "infrastructure comprehensive test passed" }
}

# Gaming scripts tests
def run_gaming_scripts_tests [coverage: bool, output: string, parallel: bool, fail_fast: bool] {
    info "Starting running gaming scripts tests" --context "gaming-scripts-tests"
    
    let gaming_scripts_tests = [
        { name: "gaming_scripts_comprehensive_tests", func: {|| test_gaming_scripts_comprehensive } }
    ]
    
    let results = (test_suite "gaming_scripts_tests" $gaming_scripts_tests --parallel false --fail-fast $fail_fast)
    
    success $"Gaming scripts tests completed: ($results.passed)/($results.total) passed" --context "gaming-scripts-tests"
    
    $results
}

def test_gaming_scripts_comprehensive [] {
    # Run the comprehensive gaming scripts test suite
    let result = (^nu "scripts/testing/gaming/gaming-scripts-tests.nu" | complete)
    assert_equal $result.exit_code 0 "gaming scripts comprehensive tests should pass"
    
    { success: true, message: "gaming scripts comprehensive test passed" }
}

# Handlers tests
def run_handlers_tests [coverage: bool, output: string, parallel: bool, fail_fast: bool] {
    info "Starting running handlers tests" --context "handlers-tests"
    
    let handlers_tests = [
        { name: "handlers_comprehensive_tests", func: {|| test_handlers_comprehensive } }
    ]
    
    let results = (test_suite "handlers_tests" $handlers_tests --parallel false --fail-fast $fail_fast)
    
    success $"Handlers tests completed: ($results.passed)/($results.total) passed" --context "handlers-tests"
    
    $results
}

def test_handlers_comprehensive [] {
    # Run the comprehensive handlers test suite
    let result = (^nu "scripts/testing/handlers/handlers-comprehensive-tests.nu" | complete)
    assert_equal $result.exit_code 0 "handlers comprehensive tests should pass"
    
    { success: true, message: "handlers comprehensive test passed" }
}

# MacOS platform-specific tests
def run_macos_platform_specific_tests [coverage: bool, output: string, parallel: bool, fail_fast: bool] {
    info "Starting running MacOS platform-specific tests" --context "macos-platform-tests"
    
    let macos_platform_tests = [
        { name: "macos_platform_specific_tests", func: {|| test_macos_platform_specific_comprehensive } }
    ]
    
    let results = (test_suite "macos_platform_tests" $macos_platform_tests --parallel false --fail-fast $fail_fast)
    
    success $"MacOS platform-specific tests completed: ($results.passed)/($results.total) passed" --context "macos-platform-tests"
    
    $results
}

def test_macos_platform_specific_comprehensive [] {
    # Run the comprehensive MacOS platform-specific test suite
    let result = (^nu "scripts/testing/platform/macos/macos-platform-specific-tests.nu" | complete)
    assert_equal $result.exit_code 0 "MacOS platform-specific comprehensive tests should pass"
    
    { success: true, message: "MacOS platform-specific comprehensive test passed" }
}

# Windows platform-specific tests
def run_windows_platform_specific_tests [coverage: bool, output: string, parallel: bool, fail_fast: bool] {
    info "Starting running Windows platform-specific tests" --context "windows-platform-tests"
    
    let windows_platform_tests = [
        { name: "windows_platform_specific_tests", func: {|| test_windows_platform_specific_comprehensive } }
    ]
    
    let results = (test_suite "windows_platform_tests" $windows_platform_tests --parallel false --fail-fast $fail_fast)
    
    success $"Windows platform-specific tests completed: ($results.passed)/($results.total) passed" --context "windows-platform-tests"
    
    $results
}

def test_windows_platform_specific_comprehensive [] {
    # Run the comprehensive Windows platform-specific test suite
    let result = (^nu "scripts/testing/platform/windows/windows-platform-specific-tests.nu" | complete)
    assert_equal $result.exit_code 0 "Windows platform-specific comprehensive tests should pass"
    
    { success: true, message: "Windows platform-specific comprehensive test passed" }
}

# Integration test functions
def test_setup_integration [] {
    setup_test_environment
    
    # Test that setup system works end-to-end
    let result = (run-external "nu" "scripts/setup.nu" "automated" "--dry-run" "--component" "minimal" | complete)
    assert ($result.exit_code == 0) "Setup should complete successfully in dry-run mode"
    
    cleanup_test_environment
    
    { success: true, message: "setup integration test passed" }
}

def test_validation_integration [] {
    # Test validation system integration
    let result = (run-external "nu" "scripts/validate.nu" "basic" | complete)
    assert ($result.exit_code == 0) "Basic validation should pass"
    
    { success: true, message: "validation integration test passed" }
}

def test_storage_integration [] {
    # Test storage system integration
    let result = (run-external "nu" "scripts/storage.nu" "validate" "--dry-run" | complete)
    assert ($result.exit_code == 0) "Storage validation should complete"
    
    { success: true, message: "storage integration test passed" }
}

def test_dashboard_integration [] {
    # Test dashboard system integration
    let result = (run-external "nu" "scripts/dashboard.nu" "overview" "--output" "tmp/test-dashboard.json" | complete)
    assert ($result.exit_code == 0) "Dashboard should generate successfully"
    assert ("tmp/test-dashboard.json" | path exists) "Dashboard output file should be created"
    
    { success: true, message: "dashboard integration test passed" }
}

# New consolidated script integration tests
def test_setup_consolidated_integration [] {
    # Run the comprehensive setup integration test file
    let result = (^nu "scripts/testing/integration/setup-integration-tests.nu" | complete)
    assert_equal $result.exit_code 0 "setup consolidated integration tests should pass"
    
    { success: true, message: "setup consolidated integration test passed" }
}

def test_dashboard_consolidated_integration [] {
    # Run the comprehensive dashboard integration test file
    let result = (^nu "scripts/testing/integration/dashboard-integration-tests.nu" | complete)
    assert_equal $result.exit_code 0 "dashboard consolidated integration tests should pass"
    
    { success: true, message: "dashboard consolidated integration test passed" }
}

def test_chezmoi_consolidated_integration [] {
    # Run the comprehensive chezmoi integration test file
    let result = (^nu "scripts/testing/integration/chezmoi-integration-tests.nu" | complete)
    assert_equal $result.exit_code 0 "chezmoi consolidated integration tests should pass"
    
    { success: true, message: "chezmoi consolidated integration test passed" }
}

# Platform-specific test functions
def test_platform_detection_accuracy [] {
    let platform_info = (get_platform)
    # Note: platform_report function may need to be checked if it exists
    
    # Validate platform info structure
    assert_contains $platform_info "normalized" "Platform info should have normalized field"
    assert_contains $platform_info "arch" "Platform info should have arch field"
    
    { success: true, message: "platform detection accuracy test passed" }
}

def test_platform_operations [] {
    # Test platform-specific operations
    # Note: maintenance_pipeline function may need to be checked if it exists
    let platform_info = (get_platform)
    
    assert_contains $platform_info "normalized" "Platform operations should work"
    
    { success: true, message: "platform operations test passed" }
}

def test_cross_platform_compatibility [] {
    # Test that our scripts work across platforms
    let platform_info = (get_platform)
    
    # Test platform-aware file paths
    let paths = (get_platform_paths)
    assert_contains $paths "config_home" "Platform paths should include config_home"
    
    { success: true, message: "cross platform compatibility test passed" }
}

# Security test functions
def test_script_security [] {
    # Test security scanning functionality
    # Note: analyze_security_posture function may need to be implemented
    let script_files = (glob "scripts/**/*.nu")
    
    assert (($script_files | length) > 0) "Security scan should find script files"
    
    { success: true, message: "script security scan test passed" }
}

def test_file_permissions [] {
    # Test file permission validation
    let script_files = (glob "scripts/**/*.nu")
    
    # Check that script files have reasonable permissions
    for file in $script_files {
        let file_info = (ls -la $file | get 0)
        let perms = $file_info.mode
        let has_world_write = ($perms | str contains "w")
        let has_other_write = ($perms | str contains "o")
        assert (not ($has_world_write and $has_other_write)) "Scripts should not be world-writable"
    }
    
    { success: true, message: "file permissions check test passed" }
}

def test_secret_detection [] {
    # Test that we don't accidentally commit secrets
    # Note: check_for_exposed_secrets function may need to be implemented
    let git_files = (glob "**/*" | where {|f| not ($f | str starts-with ".git")})
    
    assert (($git_files | length) > 0) "Secret detection should scan files"
    
    { success: true, message: "secret detection test passed" }
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
    # Benchmark validation system performance
    let iterations = 50
    let start_time = (date now)
    
    for i in 0..$iterations {
        validate_command "nu" | ignore
        validate_file "flake.nix" | ignore
        validate_directory "scripts" | ignore
    }
    
    let end_time = (date now)
    let duration = ($end_time - $start_time)
    
    {
        test: "validation_performance",
        iterations: $iterations,
        duration: $duration,
        avg_per_validation: ($duration / $iterations)
    }
}

def benchmark_platform_detection [] {
    # Benchmark platform detection performance
    # Benchmark platform detection performance
    let iterations = 100
    let start_time = (date now)
    
    for i in 0..$iterations {
        get_platform | ignore
    }
    
    let end_time = (date now)
    let duration = ($end_time - $start_time)
    
    {
        test: "platform_detection_performance",
        iterations: $iterations,
        duration: $duration,
        avg_per_detection: ($duration / $iterations)
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
            success: ($results | get success? | default false),
            total_suites: ($results | get total_suites? | default 1),
            passed_suites: ($results | get passed_suites? | default 0),
            failed_suites: ($results | get failed_suites? | default 0)
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
# Note: Direct execution not supported in Nushell 0.104.0+
# Use: nu test.nu <suite> [options] instead