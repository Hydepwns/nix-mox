#!/usr/bin/env nu
# Test runners module
# Extracted from scripts/test.nu for better modularity

use ../../lib/logging.nu *
use ../../lib/testing.nu *
use implementations.nu *

# ──────────────────────────────────────────────────────────
# MAIN TEST RUNNERS
# ──────────────────────────────────────────────────────────

export def run_all_tests [coverage: bool, output: string, parallel: bool, fail_fast: bool] {
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
    
    mut suite_results = []
    for suite in $test_suites {
        info ("Running test suite: " + $suite.name) --context "test-all"
        
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
        
        $suite_results = ($suite_results | append {
            suite: $suite.name,
            result: $result
        })
        
        if $fail_fast and (not $result.success) {
            error ("Test suite " + $suite.name + " failed, stopping due to fail-fast") --context "test-all"
            break
        }
    }
    
    let total_suites = ($suite_results | length)
    let passed_suites = ($suite_results | where { | r| $r.result.success } | length)
    let failed_suites = ($total_suites - $passed_suites)
    
    if $failed_suites == 0 {
        success "All test suites passed!" --context "test-all"
    } else {
        error "Some test suites failed" --context "test-all"
    }
    
    {
        success: ($failed_suites == 0),
        total_suites: $total_suites,
        passed_suites: $passed_suites,
        failed_suites: $failed_suites,
        suite_results: $suite_results,
        timestamp: "now"
    }
}

export def run_unit_tests [coverage: bool, output: string, parallel: bool, fail_fast: bool] {
    info "Starting running unit tests" --context "unit-tests"
    
    let unit_tests = [
        { name: "logging_tests", func: { test_logging_system } },
        { name: "platform_tests", func: { test_platform_detection } },
        { name: "validation_tests", func: { test_validation_functions } },
        { name: "command_wrapper_tests", func: { test_command_wrappers } },
        { name: "analysis_tests", func: { test_analysis_system } },
        { name: "validators_library_tests", func: { test_validators_library } },
        { name: "command_wrapper_library_tests", func: { test_command_wrapper_library } },
        { name: "analysis_library_tests", func: { test_analysis_library } },
        { name: "metrics_library_tests", func: { test_metrics_library } },
        { name: "completions_library_tests", func: { test_completions_library } },
        { name: "enhanced_error_handling_library_tests", func: { test_enhanced_error_handling_library } },
        { name: "platform_operations_library_tests", func: { test_platform_operations_library } },
        { name: "script_template_library_tests", func: { test_script_template_library } },
        { name: "testing_library_tests", func: { test_testing_library } }
    ]
    
    let results = (test_suite "unit_tests" $unit_tests --parallel $parallel --fail-fast $fail_fast)
    
    success ("Unit tests completed: " + ($results.passed | into string) + "/" + ($results.total | into string) + " passed") --context "unit-tests"
    
    $results
}

export def run_integration_tests [coverage: bool, output: string, parallel: bool, fail_fast: bool] {
    info "Starting running integration tests" --context "integration-tests"
    
    let integration_tests = [
        { name: "setup_integration", func: { test_setup_integration } },
        { name: "validation_integration", func: { test_validation_integration } },
        { name: "storage_integration", func: { test_storage_integration } },
        { name: "dashboard_integration", func: { test_dashboard_integration } },
        { name: "setup_consolidated_integration", func: { test_setup_consolidated_integration } },
        { name: "dashboard_consolidated_integration", func: { test_dashboard_consolidated_integration } },
        { name: "chezmoi_consolidated_integration", func: { test_chezmoi_consolidated_integration } }
    ]
    
    let results = (test_suite "integration_tests" $integration_tests --parallel $parallel --fail-fast $fail_fast)
    
    success ("Integration tests completed: " + ($results.passed | into string) + "/" + ($results.total | into string) + " passed") --context "integration-tests"
    
    $results
}

export def run_validation_tests [coverage: bool, output: string, parallel: bool, fail_fast: bool] {
    info "Starting running validation tests" --context "validation-tests"
    
    let validation_tests = [
        { name: "validation_safety_tests", func: { test_validation_safety } },
        { name: "maintenance_safety_tests", func: { test_maintenance_safety } },
        { name: "validation_basic", func: { test_validation_basic } },
        { name: "validation_config", func: { test_validation_config } },
        { name: "validation_platform", func: { test_validation_platform } }
    ]
    
    let results = (test_suite "validation_tests" $validation_tests --parallel $parallel --fail-fast $fail_fast)
    
    success ("Validation tests completed: " + ($results.passed | into string) + "/" + ($results.total | into string) + " passed") --context "validation-tests"
    
    $results
}

# ──────────────────────────────────────────────────────────
# SPECIALIZED TEST RUNNERS
# ──────────────────────────────────────────────────────────

export def run_maintenance_tests [coverage: bool, output: string, parallel: bool, fail_fast: bool] {
    info "Starting running maintenance tests" --context "maintenance-tests"
    
    let maintenance_tests = [
        { name: "maintenance_safety_tests", func: { test_maintenance_safety } }
    ]
    
    let results = (test_suite "maintenance_tests" $maintenance_tests --parallel $parallel --fail-fast $fail_fast)
    
    success ("Maintenance tests completed: " + ($results.passed | into string) + "/" + ($results.total | into string) + " passed") --context "maintenance-tests"
    
    $results
}

export def run_setup_tests [coverage: bool, output: string, parallel: bool, fail_fast: bool] {
    info "Starting running setup tests" --context "setup-tests"
    
    let setup_tests = [
        { name: "setup_safety_tests", func: { test_setup_safety } }
    ]
    
    let results = (test_suite "setup_tests" $setup_tests --parallel $parallel --fail-fast $fail_fast)
    
    success ("Setup tests completed: " + ($results.passed | into string) + "/" + ($results.total | into string) + " passed") --context "setup-tests"
    
    $results
}

export def run_platform_tests [coverage: bool, output: string, parallel: bool, fail_fast: bool] {
    info "Starting running platform tests" --context "platform-tests"
    
    let platform_tests = [
        { name: "platform_detection", func: { test_platform_detection_comprehensive } },
        { name: "platform_operations", func: { test_platform_operations_comprehensive } },
        { name: "cross_platform_compatibility", func: { test_cross_platform_compatibility } },
        { name: "nixos_tests", func: { test_nixos_platform_specific } },
        { name: "homebrew_tests", func: { test_homebrew_platform_specific } },
        { name: "powershell_tests", func: { test_powershell_platform_specific } },
        { name: "platform_comprehensive_tests", func: { test_platform_comprehensive } }
    ]
    
    let results = (test_suite "platform_tests" $platform_tests --parallel $parallel --fail-fast $fail_fast)
    
    success ("Platform tests completed: " + ($results.passed | into string) + "/" + ($results.total | into string) + " passed") --context "platform-tests"
    
    $results
}

# ──────────────────────────────────────────────────────────
# STUB RUNNERS (to be implemented)
# ──────────────────────────────────────────────────────────

export def run_analysis_tests [coverage: bool, output: string, parallel: bool, fail_fast: bool] {
    info "Starting running analysis tests" --context "analysis-tests"
    let analysis_tests = [
        { name: "analysis_comprehensive_tests", func: { test_analysis_comprehensive } }
    ]
    let results = (test_suite "analysis_tests" $analysis_tests --parallel $parallel --fail-fast $fail_fast)
    success ("Analysis tests completed: " + ($results.passed | into string) + "/" + ($results.total | into string) + " passed") --context "analysis-tests"
    $results
}

export def run_gaming_tests [coverage: bool, output: string, parallel: bool, fail_fast: bool] {
    info "Starting running gaming tests" --context "gaming-tests"
    let gaming_tests = [
        { name: "gaming_comprehensive_tests", func: { test_gaming_comprehensive } }
    ]
    let results = (test_suite "gaming_tests" $gaming_tests --parallel $parallel --fail-fast $fail_fast)
    success ("Gaming tests completed: " + ($results.passed | into string) + "/" + ($results.total | into string) + " passed") --context "gaming-tests"
    $results
}

export def run_gaming_scripts_tests [coverage: bool, output: string, parallel: bool, fail_fast: bool] {
    info "Starting running gaming scripts tests" --context "gaming-scripts-tests"
    let gaming_scripts_tests = [
        { name: "gaming_scripts_comprehensive_tests", func: { test_gaming_scripts_comprehensive } }
    ]
    let results = (test_suite "gaming_scripts_tests" $gaming_scripts_tests --parallel $parallel --fail-fast $fail_fast)
    success ("Gaming scripts tests completed: " + ($results.passed | into string) + "/" + ($results.total | into string) + " passed") --context "gaming-scripts-tests"
    $results
}

export def run_handlers_tests [coverage: bool, output: string, parallel: bool, fail_fast: bool] {
    info "Starting running handlers tests" --context "handlers-tests"
    let handlers_tests = [
        { name: "handlers_comprehensive_tests", func: { test_handlers_comprehensive } }
    ]
    let results = (test_suite "handlers_tests" $handlers_tests --parallel $parallel --fail-fast $fail_fast)
    success ("Handlers tests completed: " + ($results.passed | into string) + "/" + ($results.total | into string) + " passed") --context "handlers-tests"
    $results
}

export def run_macos_platform_specific_tests [coverage: bool, output: string, parallel: bool, fail_fast: bool] {
    info "Starting running MacOS platform-specific tests" --context "macos-platform-tests"
    let macos_platform_tests = [
        { name: "macos_platform_specific_tests", func: { test_macos_platform_specific } }
    ]
    let results = (test_suite "macos_platform_tests" $macos_platform_tests --parallel $parallel --fail-fast $fail_fast)
    success ("MacOS platform-specific tests completed: " + ($results.passed | into string) + "/" + ($results.total | into string) + " passed") --context "macos-platform-tests"
    $results
}

export def run_windows_platform_specific_tests [coverage: bool, output: string, parallel: bool, fail_fast: bool] {
    info "Starting running Windows platform-specific tests" --context "windows-platform-tests"
    let windows_platform_tests = [
        { name: "windows_platform_specific_tests", func: { test_windows_platform_specific } }
    ]
    let results = (test_suite "windows_platform_tests" $windows_platform_tests --parallel $parallel --fail-fast $fail_fast)
    success ("Windows platform-specific tests completed: " + ($results.passed | into string) + "/" + ($results.total | into string) + " passed") --context "windows-platform-tests"
    $results
}

export def run_infrastructure_tests [coverage: bool, output: string, parallel: bool, fail_fast: bool] {
    info "Starting running infrastructure tests" --context "infrastructure-tests"
    let infrastructure_tests = [
        { name: "infrastructure_comprehensive_tests", func: { test_infrastructure_comprehensive } }
    ]
    let results = (test_suite "infrastructure_tests" $infrastructure_tests --parallel $parallel --fail-fast $fail_fast)
    success ("Infrastructure tests completed: " + ($results.passed | into string) + "/" + ($results.total | into string) + " passed") --context "infrastructure-tests"
    $results
}

export def run_security_tests [coverage: bool, output: string, parallel: bool, fail_fast: bool] {
    info "Starting running security tests" --context "security-tests"
    
    let security_tests = [
        { name: "script_security_scan", func: { test_script_security } },
        { name: "file_permissions_check", func: { test_file_permissions } },
        { name: "secret_detection", func: { test_secret_detection } }
    ]
    
    let results = (test_suite "security_tests" $security_tests --parallel $parallel --fail-fast $fail_fast)
    
    success ("Security tests completed: " + ($results.passed | into string) + "/" + ($results.total | into string) + " passed") --context "security-tests"
    
    $results
}

export def run_performance_tests [coverage: bool, output: string, parallel: bool, fail_fast: bool] {
    info "Starting running performance tests" --context "performance-tests"
    
    let performance_tests = [
        { name: "logging_performance", func: { benchmark_logging_performance } },
        { name: "validation_performance", func: { benchmark_validation_performance } },
        { name: "platform_detection_performance", func: { benchmark_platform_detection } }
    ]
    
    let benchmark_results = ($performance_tests | each { | test|
        match $test.func {
            _ => {
                info ("Running benchmark: " + $test.name) --context "performance"
                try {
                    do $test.func
                } catch { | err|
                    error ("Benchmark " + $test.name + " failed: " + $err.msg) --context "performance"
                    { success: false, error: $err.msg, benchmark: $test.name }
                }
            }
        }
    })
    
    success "Performance tests completed" --context "performance-tests"
    
    {
        success: true,
        total: ($performance_tests | length),
        passed: ($benchmark_results | where success | length),
        results: $benchmark_results
    }
}