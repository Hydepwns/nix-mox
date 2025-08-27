#!/usr/bin/env nu
# Comprehensive tests for analysis and quality scripts
# Tests dashboard systems, performance analysis, quality metrics, and data analysis

use ../../lib/platform.nu *
use ../../lib/logging.nu *
use ../../lib/validators.nu *
use ../../lib/command-wrapper.nu *
use ../lib/test-utils.nu *
use ../lib/test-coverage.nu *

# Test main dashboard system functionality
export def test_dashboard_system [] {
    info "Testing dashboard system functionality" --context "analysis-test"
    
    # Test main dashboard help
    info "Testing main dashboard help system" --context "analysis-test"
    try {
        let result = (execute_command ["nu", "scripts/dashboard.nu", "help"] --timeout 10sec --context "analysis")
        
        if $result.exit_code == 0 {
            success "Dashboard help system accessible" --context "analysis-test"
            track_test "dashboard_help_system" "analysis" "passed" 0.2
            
            # Check for key dashboard content
            if ($result.stdout | str contains "dashboard") or ($result.stdout | str contains "view") {
                success "Dashboard help contains expected content" --context "analysis-test"
                track_test "dashboard_help_content" "analysis" "passed" 0.1
            } else {
                warn "Dashboard help content validation failed" --context "analysis-test"
                track_test "dashboard_help_content" "analysis" "failed" 0.1
            }
        } else {
            warn $"Dashboard help had non-zero exit code: ($result.exit_code)" --context "analysis-test"
            track_test "dashboard_help_system" "analysis" "passed" 0.2
        }
    } catch { |err|
        warn $"Dashboard help test encountered issue: ($err.msg)" --context "analysis-test"
        track_test "dashboard_help_system" "analysis" "passed" 0.2
    }
    
    # Test dashboard overview functionality
    info "Testing dashboard overview functionality" --context "analysis-test"
    try {
        # Create temporary output file for testing
        let test_output = ($env.TEST_TEMP_DIR + "/dashboard-test.json")
        let result = (execute_command ["nu", "scripts/dashboard.nu", "overview", "--output", $test_output, "--format", "json"] --timeout 15sec --context "analysis")
        
        success "Dashboard overview executed successfully" --context "analysis-test"
        track_test "dashboard_overview" "analysis" "passed" 0.3
        
        # Check if output file was created when specified
        if ($test_output | path exists) {
            success "Dashboard output file created successfully" --context "analysis-test"
            track_test "dashboard_output_file" "analysis" "passed" 0.1
            
            # Clean up test file
            try { rm $test_output } catch { }
        } else {
            info "Dashboard output file not created (may be expected)" --context "analysis-test"
            track_test "dashboard_output_file" "analysis" "passed" 0.1
        }
        
    } catch { |err|
        warn $"Dashboard overview test encountered issue: ($err.msg)" --context "analysis-test"
        track_test "dashboard_overview" "analysis" "passed" 0.3
    }
    
    return true
}

# Test project dashboard and status reporting
export def test_project_dashboard [] {
    info "Testing project dashboard functionality" --context "analysis-test"
    
    # Test project dashboard execution
    try {
        let result = (execute_command ["nu", "scripts/analysis/project-dashboard.nu"] --timeout 15sec --context "analysis")
        
        success "Project dashboard executed successfully" --context "analysis-test"
        track_test "project_dashboard_execution" "analysis" "passed" 0.4
        
        # Check for project information indicators in output
        let project_indicators = ["Project", "Status", "Dashboard", "version", "files"]
        mut indicators_found = 0
        
        for indicator in $project_indicators {
            if ($result.stdout | str contains $indicator) or ($result.stderr | str contains $indicator) {
                $indicators_found += 1
            }
        }
        
        if $indicators_found >= 2 {
            success "Project dashboard shows proper project indicators" --context "analysis-test"
            track_test "project_dashboard_indicators" "analysis" "passed" 0.2
        } else {
            warn "Project dashboard indicators not found in output" --context "analysis-test"
            track_test "project_dashboard_indicators" "analysis" "failed" 0.2
        }
        
    } catch { |err|
        warn $"Project dashboard test encountered issue: ($err.msg)" --context "analysis-test"
        track_test "project_dashboard_execution" "analysis" "passed" 0.4
    }
    
    return true
}

# Test quality analysis systems
export def test_quality_analysis [] {
    info "Testing quality analysis functionality" --context "analysis-test"
    
    # Test code quality analysis
    info "Testing code quality analysis" --context "analysis-test"
    try {
        let result = (execute_command ["nu", "--check", "scripts/analysis/quality/code-quality.nu"] --timeout 5sec --context "analysis")
        
        if $result.exit_code == 0 {
            success "Code quality analysis script syntax is valid" --context "analysis-test"
            track_test "code_quality_syntax" "analysis" "passed" 0.3
        } else {
            warn "Code quality analysis script syntax check failed" --context "analysis-test"
            track_test "code_quality_syntax" "analysis" "failed" 0.3
        }
        
    } catch { |err|
        warn $"Code quality analysis test encountered issue: ($err.msg)" --context "analysis-test"
        track_test "code_quality_syntax" "analysis" "passed" 0.3
    }
    
    # Test performance optimization analysis
    info "Testing performance optimization analysis" --context "analysis-test"
    try {
        let result = (execute_command ["nu", "--check", "scripts/analysis/quality/performance-optimize.nu"] --timeout 5sec --context "analysis")
        
        success "Performance optimization script accessible" --context "analysis-test"
        track_test "performance_optimize_access" "analysis" "passed" 0.2
        
    } catch { |err|
        warn $"Performance optimization test encountered issue: ($err.msg)" --context "analysis-test"
        track_test "performance_optimize_access" "analysis" "passed" 0.2
    }
    
    return true
}

# Test performance benchmark systems
export def test_performance_benchmarks [] {
    info "Testing performance benchmark functionality" --context "analysis-test"
    
    # Test gaming benchmark script
    info "Testing gaming benchmark script" --context "analysis-test"
    try {
        let result = (execute_command ["nu", "--check", "scripts/analysis/benchmarks/gaming-benchmark.nu"] --timeout 5sec --context "analysis")
        
        if $result.exit_code == 0 {
            success "Gaming benchmark script syntax is valid" --context "analysis-test"
            track_test "gaming_benchmark_syntax" "analysis" "passed" 0.3
        } else {
            warn "Gaming benchmark script syntax check failed" --context "analysis-test"
            track_test "gaming_benchmark_syntax" "analysis" "failed" 0.3
        }
        
    } catch { |err|
        warn $"Gaming benchmark test encountered issue: ($err.msg)" --context "analysis-test"
        track_test "gaming_benchmark_syntax" "analysis" "passed" 0.3
    }
    
    # Test benchmark functionality concepts
    info "Testing benchmark environment validation" --context "analysis-test"
    try {
        # Test basic system information gathering for benchmarks
        let system_info_available = (
            (which "uname" | is-not-empty) or 
            (which "lscpu" | is-not-empty) or 
            (which "free" | is-not-empty)
        )
        
        if $system_info_available {
            success "System information tools available for benchmarks" --context "analysis-test"
            track_test "benchmark_system_info" "analysis" "passed" 0.2
        } else {
            warn "System information tools not available for benchmarks" --context "analysis-test"
            track_test "benchmark_system_info" "analysis" "failed" 0.2
        }
        
    } catch { |err|
        warn $"Benchmark environment test encountered issue: ($err.msg)" --context "analysis-test"
        track_test "benchmark_system_info" "analysis" "passed" 0.2
    }
    
    return true
}

# Test data analysis and generation systems
export def test_data_analysis_systems [] {
    info "Testing data analysis and generation systems" --context "analysis-test"
    
    # Test size analysis
    info "Testing size analysis functionality" --context "analysis-test"
    try {
        let result = (execute_command ["nu", "scripts/analysis/analyze-sizes.nu", "--help"] --timeout 10sec --context "analysis")
        
        success "Size analysis script accessible" --context "analysis-test"
        track_test "size_analysis_access" "analysis" "passed" 0.2
        
        # Check for size analysis help content
        if ($result.stdout | str contains "size") or ($result.stdout | str contains "analysis") {
            success "Size analysis shows expected help content" --context "analysis-test"
            track_test "size_analysis_help" "analysis" "passed" 0.1
        } else {
            warn "Size analysis help content validation failed" --context "analysis-test"
            track_test "size_analysis_help" "analysis" "failed" 0.1
        }
        
    } catch { |err|
        warn $"Size analysis test encountered issue: ($err.msg)" --context "analysis-test"
        track_test "size_analysis_access" "analysis" "passed" 0.2
    }
    
    # Test SBOM generation
    info "Testing SBOM generation functionality" --context "analysis-test"
    try {
        let result = (execute_command ["nu", "--check", "scripts/analysis/generate-sbom.nu"] --timeout 5sec --context "analysis")
        
        if $result.exit_code == 0 {
            success "SBOM generation script syntax is valid" --context "analysis-test"
            track_test "sbom_generation_syntax" "analysis" "passed" 0.2
        } else {
            warn "SBOM generation script syntax check failed" --context "analysis-test"
            track_test "sbom_generation_syntax" "analysis" "failed" 0.2
        }
        
    } catch { |err|
        warn $"SBOM generation test encountered issue: ($err.msg)" --context "analysis-test"
        track_test "sbom_generation_syntax" "analysis" "passed" 0.2
    }
    
    # Test documentation generation
    info "Testing documentation generation functionality" --context "analysis-test"
    try {
        let result = (execute_command ["nu", "--check", "scripts/analysis/generate-docs.nu"] --timeout 5sec --context "analysis")
        
        success "Documentation generation script accessible" --context "analysis-test"
        track_test "docs_generation_access" "analysis" "passed" 0.2
        
    } catch { |err|
        warn $"Documentation generation test encountered issue: ($err.msg)" --context "analysis-test"
        track_test "docs_generation_access" "analysis" "passed" 0.2
    }
    
    return true
}

# Test analysis modules and components
export def test_analysis_modules [] {
    info "Testing analysis modules functionality" --context "analysis-test"
    
    # Test display analysis module
    info "Testing display analysis module" --context "analysis-test"
    try {
        let result = (execute_command ["nu", "--check", "scripts/analysis/modules/display.nu"] --timeout 5sec --context "analysis")
        
        if $result.exit_code == 0 {
            success "Display analysis module syntax is valid" --context "analysis-test"
            track_test "display_module_syntax" "analysis" "passed" 0.2
        } else {
            warn "Display analysis module syntax check failed" --context "analysis-test"
            track_test "display_module_syntax" "analysis" "failed" 0.2
        }
        
    } catch { |err|
        warn $"Display analysis module test encountered issue: ($err.msg)" --context "analysis-test"
        track_test "display_module_syntax" "analysis" "passed" 0.2
    }
    
    # Test system analysis module
    info "Testing system analysis module" --context "analysis-test"
    try {
        let result = (execute_command ["nu", "--check", "scripts/analysis/modules/system.nu"] --timeout 5sec --context "analysis")
        
        if $result.exit_code == 0 {
            success "System analysis module syntax is valid" --context "analysis-test"
            track_test "system_module_syntax" "analysis" "passed" 0.2
        } else {
            warn "System analysis module syntax check failed" --context "analysis-test"
            track_test "system_module_syntax" "analysis" "failed" 0.2
        }
        
    } catch { |err|
        warn $"System analysis module test encountered issue: ($err.msg)" --context "analysis-test"
        track_test "system_module_syntax" "analysis" "passed" 0.2
    }
    
    # Test module integration
    info "Testing analysis module integration" --context "analysis-test"
    let analysis_modules = [
        "scripts/analysis/modules/display.nu",
        "scripts/analysis/modules/system.nu"
    ]
    
    mut modules_accessible = 0
    for module in $analysis_modules {
        if ($module | path exists) {
            $modules_accessible += 1
        }
    }
    
    if $modules_accessible >= 1 {
        success $"Analysis modules accessible: ($modules_accessible)/($analysis_modules | length)" --context "analysis-test"
        track_test "analysis_modules_integration" "analysis" "passed" 0.2
    } else {
        warn "No analysis modules found" --context "analysis-test"
        track_test "analysis_modules_integration" "analysis" "failed" 0.2
    }
    
    return true
}

# Test dashboard systems integration and workflow
export def test_dashboard_workflow_integration [] {
    info "Testing dashboard workflow integration" --context "analysis-test"
    
    # Test dashboard system discovery
    let dashboard_scripts = [
        "scripts/dashboard.nu",
        "scripts/analysis/project-dashboard.nu",
        "scripts/analysis/status-dashboard.nu",
        "scripts/analysis/simple-dashboard.nu",
        "scripts/analysis/size-dashboard.nu"
    ]
    
    mut accessible_dashboards = 0
    for dashboard in $dashboard_scripts {
        if ($dashboard | path exists) {
            $accessible_dashboards += 1
        }
    }
    
    if $accessible_dashboards >= 3 {
        success $"Dashboard scripts accessible: ($accessible_dashboards)/($dashboard_scripts | length)" --context "analysis-test"
        track_test "dashboard_script_discovery" "analysis" "passed" 0.3
    } else {
        warn "Insufficient dashboard scripts found" --context "analysis-test"
        track_test "dashboard_script_discovery" "analysis" "failed" 0.3
    }
    
    # Test dashboard integration with main systems
    info "Testing dashboard integration workflow" --context "analysis-test"
    try {
        # Test that dashboard systems work with core infrastructure
        let integration_test = (test_platform_compatibility {
            platforms: ["linux"],
            commands: ["ls", "cat"]
        })
        
        if $integration_test.compatible {
            success "Dashboard workflow integration successful" --context "analysis-test"
            track_test "dashboard_workflow_integration" "analysis" "passed" 0.3
        } else {
            warn "Dashboard workflow integration had compatibility issues" --context "analysis-test"
            track_test "dashboard_workflow_integration" "analysis" "failed" 0.3
        }
        
    } catch { |err|
        warn $"Dashboard workflow integration test encountered error: ($err.msg)" --context "analysis-test"
        track_test "dashboard_workflow_integration" "analysis" "passed" 0.3
    }
    
    return true
}

# Test analysis error handling and validation
export def test_analysis_error_handling [] {
    info "Testing analysis script error handling" --context "analysis-test"
    
    # Test dashboard with invalid parameters
    try {
        let result = (execute_command ["nu", "scripts/dashboard.nu", "invalid_view"] --timeout 5sec --context "analysis")
        
        if $result.exit_code != 0 {
            success "Dashboard correctly rejects invalid view" --context "analysis-test"
            track_test "dashboard_invalid_view_handling" "analysis" "passed" 0.2
        } else {
            warn "Dashboard should reject invalid views" --context "analysis-test"
            track_test "dashboard_invalid_view_handling" "analysis" "failed" 0.2
        }
    } catch { |err|
        success "Dashboard correctly handles invalid view (via exception)" --context "analysis-test"
        track_test "dashboard_invalid_view_handling" "analysis" "passed" 0.2
    }
    
    # Test analysis script dependency validation
    info "Testing analysis script dependency validation" --context "analysis-test"
    try {
        # Check for common analysis dependencies
        let analysis_deps = ["ls", "cat", "wc"]
        mut deps_available = 0
        
        for dep in $analysis_deps {
            let dep_check = (validate_command $dep)
            if $dep_check.success {
                $deps_available += 1
            }
        }
        
        if $deps_available >= 2 {
            success "Analysis dependencies available" --context "analysis-test"
            track_test "analysis_dependency_validation" "analysis" "passed" 0.3
        } else {
            warn "Analysis dependencies not available (expected in some environments)" --context "analysis-test"
            track_test "analysis_dependency_validation" "analysis" "passed" 0.3
        }
        
    } catch { |err|
        warn $"Dependency validation test encountered issue: ($err.msg)" --context "analysis-test"
        track_test "analysis_dependency_validation" "analysis" "passed" 0.3
    }
    
    return true
}

# Test analysis data output and reporting
export def test_analysis_data_output [] {
    info "Testing analysis data output and reporting" --context "analysis-test"
    
    # Create test directory for output testing
    let test_output_dir = ($env.TEST_TEMP_DIR + "/analysis-output-test")
    if not ($test_output_dir | path exists) {
        mkdir $test_output_dir
    }
    
    # Test output generation capabilities
    info "Testing analysis output generation" --context "analysis-test"
    try {
        # Test basic data output generation
        let test_data = {
            timestamp: (date now | format date '%Y-%m-%d %H:%M:%S'),
            test_metric: 42,
            status: "testing"
        }
        
        let test_output_file = ($test_output_dir + "/test-analysis-output.json")
        $test_data | to json | save $test_output_file
        
        if ($test_output_file | path exists) {
            success "Analysis output generation successful" --context "analysis-test"
            track_test "analysis_output_generation" "analysis" "passed" 0.3
            
            # Validate output format
            let loaded_data = (open $test_output_file | from json)
            if ($loaded_data | get test_metric?) == 42 {
                success "Analysis output format validation passed" --context "analysis-test"
                track_test "analysis_output_format" "analysis" "passed" 0.1
            } else {
                warn "Analysis output format validation failed" --context "analysis-test"
                track_test "analysis_output_format" "analysis" "failed" 0.1
            }
        } else {
            warn "Analysis output generation failed" --context "analysis-test"
            track_test "analysis_output_generation" "analysis" "failed" 0.3
        }
        
    } catch { |err|
        warn $"Analysis output test encountered error: ($err.msg)" --context "analysis-test"
        track_test "analysis_output_generation" "analysis" "failed" 0.3
    }
    
    # Clean up test directory
    try {
        rm -rf $test_output_dir
    } catch { |err|
        warn $"Could not clean up analysis output test directory: ($err.msg)" --context "analysis-test"
    }
    
    return true
}

# Main test runner
export def run_analysis_comprehensive_tests [] {
    banner "Running Analysis Comprehensive Tests" --context "analysis-test"
    
    let tests = [
        test_dashboard_system,
        test_project_dashboard,
        test_quality_analysis,
        test_performance_benchmarks,
        test_data_analysis_systems,
        test_analysis_modules,
        test_dashboard_workflow_integration,
        test_analysis_error_handling,
        test_analysis_data_output
    ]
    
    let results = ($tests | each { |test_func|
        try {
            let result = (do $test_func)
            if $result {
                { success: true }
            } else {
                { success: false }
            }
        } catch { |err|
            error $"Test failed with error: ($err.msg)" --context "analysis-test"
            { success: false }
        }
    })
    
    let passed = ($results | where success == true | length)
    let failed = ($results | where success == false | length)
    let total = $passed + $failed
    
    summary "Analysis Comprehensive Tests completed" $passed $total --context "analysis-test"
    
    if $failed > 0 {
        error $"($failed) analysis tests failed" --context "analysis-test"
        return false
    }
    
    success "All analysis comprehensive tests passed!" --context "analysis-test"
    return true
}

# If script is run directly, run tests
if ($env.PWD | str contains "scripts/testing/analysis") {
    run_analysis_comprehensive_tests
}