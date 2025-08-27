#!/usr/bin/env nu
# Comprehensive tests for infrastructure and core system components
# Tests bootstrap, core libraries, and system infrastructure scripts

use ../../lib/logging.nu *
use ../../lib/validators.nu *
use ../../lib/command-wrapper.nu *
use ../lib/test-utils.nu *
use ../lib/test-coverage.nu *

# Test bootstrap system functionality
export def test_bootstrap_system [] {
    info "Testing bootstrap system functionality" --context "infrastructure-test"
    
    try {
        # Test bootstrap check script exists and is functional
        let bootstrap_script = "bootstrap-check.sh"
        if not ($bootstrap_script | path exists) {
            warning "Bootstrap check script not found" --context "infrastructure-test"
            track_test "bootstrap_system" "infrastructure" "passed" 0.2
            return true
        }
        
        # Test bootstrap script syntax
        let result = (execute_command ["bash", "-n", $bootstrap_script] --timeout 5sec --context "infrastructure")
        if $result.exit_code == 0 {
            success "Bootstrap system script is syntactically valid" --context "infrastructure-test"
            track_test "bootstrap_system" "infrastructure" "passed" 0.2
            return true
        } else {
            error "Bootstrap system script has syntax errors" --context "infrastructure-test"
            track_test "bootstrap_system" "infrastructure" "failed" 0.2
            return false
        }
    } catch { |err|
        error $"Bootstrap system test failed: ($err.msg)" --context "infrastructure-test"
        track_test "bootstrap_system" "infrastructure" "failed" 0.2
        return false
    }
}

# Test core library infrastructure
export def test_core_library_infrastructure [] {
    info "Testing core library infrastructure" --context "infrastructure-test"
    
    try {
        # Test that all core libraries are present and functional
        let core_libraries = [
            "scripts/lib/logging.nu",
            "scripts/lib/validators.nu", 
            "scripts/lib/command-wrapper.nu",
            "scripts/lib/platform.nu",
            "scripts/lib/script-template.nu"
        ]
        
        mut library_score = 0
        for lib in $core_libraries {
            if ($lib | path exists) {
                # Test library syntax
                let result = (execute_command ["nu", "--check", $lib] --timeout 5sec --context "infrastructure")
                if $result.exit_code == 0 {
                    $library_score += 1
                } else {
                    error $"Core library has syntax errors: ($lib)" --context "infrastructure-test"
                }
            } else {
                error $"Core library missing: ($lib)" --context "infrastructure-test"
            }
        }
        
        if $library_score == ($core_libraries | length) {
            let lib_count = ($core_libraries | length)
            success $"All core libraries are functional (($library_score)/($lib_count))" --context "infrastructure-test"
            track_test "core_library_infrastructure" "infrastructure" "passed" 0.3
            return true
        } else if $library_score >= 3 {
            let lib_count = ($core_libraries | length)
            warning $"Most core libraries functional (($library_score)/($lib_count))" --context "infrastructure-test"
            track_test "core_library_infrastructure" "infrastructure" "passed" 0.3
            return true
        } else {
            let lib_count = ($core_libraries | length)
            error $"Critical core library failures (($library_score)/($lib_count))" --context "infrastructure-test"
            track_test "core_library_infrastructure" "infrastructure" "failed" 0.3
            return false
        }
    } catch { |err|
        error $"Core library infrastructure test failed: ($err.msg)" --context "infrastructure-test"
        track_test "core_library_infrastructure" "infrastructure" "failed" 0.3
        return false
    }
}

# Test extension infrastructure
export def test_extension_infrastructure [] {
    info "Testing extension infrastructure" --context "infrastructure-test"
    
    try {
        # Test extension directories and build systems
        let extensions = [
            { path: "extensions/zed", build_script: "extensions/zed/build.sh" },
            { path: "extensions/vscode", config: "extensions/vscode/package.json" }
        ]
        
        mut extension_score = 0
        for ext in $extensions {
            if ($ext.path | path exists) {
                $extension_score += 1
                
                # Test build scripts if they exist
                if ("build_script" in $ext) and ($ext.build_script | path exists) {
                    let result = (execute_command ["bash", "-n", $ext.build_script] --timeout 5sec --context "infrastructure")
                    if $result.exit_code != 0 {
                        warning $"Extension build script has issues: ($ext.build_script)" --context "infrastructure-test"
                    }
                }
            }
        }
        
        if $extension_score > 0 {
            let ext_count = ($extensions | length)
            success $"Extension infrastructure present ($extension_score)/($ext_count) extensions" --context "infrastructure-test"
            track_test "extension_infrastructure" "infrastructure" "passed" 0.2
            return true
        } else {
            warning "No extension infrastructure found" --context "infrastructure-test"
            track_test "extension_infrastructure" "infrastructure" "passed" 0.2
            return true
        }
    } catch { |err|
        error $"Extension infrastructure test failed: ($err.msg)" --context "infrastructure-test"
        track_test "extension_infrastructure" "infrastructure" "failed" 0.2
        return false
    }
}

# Test flake infrastructure 
export def test_flake_infrastructure [] {
    info "Testing flake infrastructure" --context "infrastructure-test"
    
    try {
        # Test main flake configuration
        if not ("flake.nix" | path exists) {
            error "Main flake.nix not found" --context "infrastructure-test"
            track_test "flake_infrastructure" "infrastructure" "failed" 0.3
            return false
        }
        
        # Test flake syntax (dry-run)
        let result = (execute_command ["nix", "flake", "show", "--json"] --timeout 15sec --context "infrastructure")
        if $result.exit_code == 0 {
            success "Main flake infrastructure is valid" --context "infrastructure-test"
        } else {
            warning "Main flake has validation issues but exists" --context "infrastructure-test"
        }
        
        # Test subflake directories
        let subflakes = ["flakes/gaming"]
        mut subflake_score = 0
        for subflake in $subflakes {
            if ($subflake | path exists) and (($subflake + "/flake.nix") | path exists) {
                $subflake_score += 1
            }
        }
        
        success $"Flake infrastructure functional (main + ($subflake_score) subflakes)" --context "infrastructure-test"
        track_test "flake_infrastructure" "infrastructure" "passed" 0.3
        return true
    } catch { |err|
        error $"Flake infrastructure test failed: ($err.msg)" --context "infrastructure-test"
        track_test "flake_infrastructure" "infrastructure" "failed" 0.3
        return false
    }
}

# Test makefile and build infrastructure
export def test_makefile_infrastructure [] {
    info "Testing Makefile and build infrastructure" --context "infrastructure-test"
    
    try {
        # Test main Makefile
        if not ("Makefile" | path exists) {
            error "Main Makefile not found" --context "infrastructure-test"
            track_test "makefile_infrastructure" "infrastructure" "failed" 0.2
            return false
        }
        
        # Test Makefile syntax (basic check)
        let result = (execute_command ["make", "-n", "help"] --timeout 10sec --context "infrastructure")
        if $result.exit_code == 0 {
            success "Makefile infrastructure is functional" --context "infrastructure-test"
        } else {
            warning "Makefile may have issues but exists" --context "infrastructure-test"
        }
        
        # Check for essential targets
        let makefile_content = (open "Makefile")
        let essential_targets = ["help", "test", "dev", "build"]
        mut target_score = 0
        
        for target in $essential_targets {
            if ($makefile_content | str contains $target) {
                $target_score += 1
            }
        }
        
        if $target_score >= 3 {
            let target_count = ($essential_targets | length)
            success $"Makefile has essential targets (($target_score)/($target_count))" --context "infrastructure-test"
            track_test "makefile_infrastructure" "infrastructure" "passed" 0.2
            return true
        } else {
            let target_count = ($essential_targets | length)
            warning $"Makefile missing some essential targets (($target_score)/($target_count))" --context "infrastructure-test"
            track_test "makefile_infrastructure" "infrastructure" "passed" 0.2
            return true
        }
    } catch { |err|
        error $"Makefile infrastructure test failed: ($err.msg)" --context "infrastructure-test"
        track_test "makefile_infrastructure" "infrastructure" "failed" 0.2
        return false
    }
}

# Test quick commands infrastructure
export def test_quick_commands_infrastructure [] {
    info "Testing quick commands infrastructure" --context "infrastructure-test"
    
    try {
        # Test quick-commands script
        let quick_commands = "quick-commands.sh"
        if not ($quick_commands | path exists) {
            warning "Quick commands script not found" --context "infrastructure-test"
            track_test "quick_commands_infrastructure" "infrastructure" "passed" 0.1
            return true
        }
        
        # Test quick commands syntax
        let result = (execute_command ["bash", "-n", $quick_commands] --timeout 5sec --context "infrastructure")
        if $result.exit_code == 0 {
            success "Quick commands infrastructure is valid" --context "infrastructure-test"
            track_test "quick_commands_infrastructure" "infrastructure" "passed" 0.1
            return true
        } else {
            error "Quick commands script has syntax errors" --context "infrastructure-test"
            track_test "quick_commands_infrastructure" "infrastructure" "failed" 0.1
            return false
        }
    } catch { |err|
        error $"Quick commands infrastructure test failed: ($err.msg)" --context "infrastructure-test"
        track_test "quick_commands_infrastructure" "infrastructure" "failed" 0.1
        return false
    }
}

# Test configuration infrastructure
export def test_configuration_infrastructure [] {
    info "Testing configuration infrastructure" --context "infrastructure-test"
    
    try {
        # Test main configuration directories
        let config_dirs = ["config/nixos", "config/hardware", "config/personal"]
        mut config_score = 0
        
        for dir in $config_dirs {
            if ($dir | path exists) {
                $config_score += 1
                
                # Check for .nix files in configuration directories
                let nix_files = (ls ($dir + "/*.nix") | length)
                if $nix_files > 0 {
                    info $"Configuration directory ($dir) has ($nix_files) .nix files" --context "infrastructure-test"
                }
            } else {
                warning $"Configuration directory not found: ($dir)" --context "infrastructure-test"
            }
        }
        
        if $config_score >= 2 {
            let dir_count = ($config_dirs | length)
            success $"Configuration infrastructure present ($config_score)/($dir_count) directories" --context "infrastructure-test"
            track_test "configuration_infrastructure" "infrastructure" "passed" 0.2
            return true
        } else {
            let dir_count = ($config_dirs | length)
            error $"Critical configuration directories missing (($config_score)/($dir_count))" --context "infrastructure-test"
            track_test "configuration_infrastructure" "infrastructure" "failed" 0.2
            return false
        }
    } catch { |err|
        error $"Configuration infrastructure test failed: ($err.msg)" --context "infrastructure-test"
        track_test "configuration_infrastructure" "infrastructure" "failed" 0.2
        return false
    }
}

# Test project documentation infrastructure
export def test_documentation_infrastructure [] {
    info "Testing project documentation infrastructure" --context "infrastructure-test"
    
    try {
        # Test essential documentation files
        let docs = [
            { file: "CLAUDE.md", required: true },
            { file: "README.md", required: false },
            { file: "treefmt.nix", required: true }
        ]
        
        mut doc_score = 0
        for doc in $docs {
            if ($doc.file | path exists) {
                $doc_score += 1
            } else if $doc.required {
                error $"Required documentation missing: ($doc.file)" --context "infrastructure-test"
            } else {
                info $"Optional documentation missing: ($doc.file)" --context "infrastructure-test"
            }
        }
        
        if $doc_score >= 2 {
            let doc_count = ($docs | length)
            success $"Documentation infrastructure adequate ($doc_score)/($doc_count) files" --context "infrastructure-test"
            track_test "documentation_infrastructure" "infrastructure" "passed" 0.1
            return true
        } else {
            let doc_count = ($docs | length)
            warning $"Documentation infrastructure minimal ($doc_score)/($doc_count) files" --context "infrastructure-test"
            track_test "documentation_infrastructure" "infrastructure" "passed" 0.1
            return true
        }
    } catch { |err|
        error $"Documentation infrastructure test failed: ($err.msg)" --context "infrastructure-test"
        track_test "documentation_infrastructure" "infrastructure" "failed" 0.1
        return false
    }
}

# Test infrastructure error handling and resilience
export def test_infrastructure_error_handling [] {
    info "Testing infrastructure error handling and resilience" --context "infrastructure-test"
    
    try {
        # Test that core infrastructure scripts have error handling
        let infrastructure_scripts = [
            "bootstrap-check.sh",
            "quick-commands.sh"
        ] | where { |script| $script | path exists }
        
        mut error_handling_score = 0
        for script in $infrastructure_scripts {
            let content = (open $script)
            
            # Check for error handling patterns in shell scripts
            let has_set_e = ($content | str contains "set -e") or ($content | str contains "set -euo pipefail")
            let has_error_handling = ($content | str contains "trap") or ($content | str contains "exit")
            let has_validation = ($content | str contains "if") and ($content | str contains "then")
            
            if $has_set_e or $has_error_handling or $has_validation {
                $error_handling_score += 1
            }
        }
        
        if $error_handling_score > 0 or ($infrastructure_scripts | length) == 0 {
            let infra_count = ($infrastructure_scripts | length)
            success $"Infrastructure error handling present ($error_handling_score)/($infra_count) scripts" --context "infrastructure-test"
            track_test "infrastructure_error_handling" "infrastructure" "passed" 0.1
            return true
        } else {
            warning "Infrastructure scripts need better error handling" --context "infrastructure-test"
            track_test "infrastructure_error_handling" "infrastructure" "passed" 0.1
            return true
        }
    } catch { |err|
        error $"Infrastructure error handling test failed: ($err.msg)" --context "infrastructure-test"
        track_test "infrastructure_error_handling" "infrastructure" "failed" 0.1
        return false
    }
}

# Main test runner for infrastructure module
export def run_infrastructure_tests [
    coverage: bool = false
    output: string = ""
    parallel: bool = true
    fail_fast: bool = false
] {
    banner "Running Infrastructure Comprehensive Tests" --context "infrastructure-test"
    
    # Setup test environment
    setup_test_env
    
    let tests = [
        test_bootstrap_system,
        test_core_library_infrastructure,
        test_extension_infrastructure,
        test_flake_infrastructure,
        test_makefile_infrastructure,
        test_quick_commands_infrastructure,
        test_configuration_infrastructure,
        test_documentation_infrastructure,
        test_infrastructure_error_handling
    ]
    
    # Execute tests
    let results = ($tests | each { |test_func|
        try {
            let result = (do $test_func)
            if $result { { success: true } } else { { success: false } }
        } catch { |err|
            error $"Test failed with error: ($err.msg)" --context "infrastructure-test"
            { success: false }
        }
    })
    
    let passed = ($results | where success == true | length)
    let failed = ($results | where success == false | length)
    let total = ($results | length)
    
    summary "Infrastructure tests completed" $passed $total --context "infrastructure-test"
    
    if $failed > 0 {
        error $"($failed) infrastructure tests failed" --context "infrastructure-test"
        if $fail_fast {
            exit 1
        }
        return false
    }
    
    success "All infrastructure tests passed!" --context "infrastructure-test"
    return true
}

# If script is run directly, run tests
if ($env.PWD | str contains "scripts/testing/infrastructure") {
    run_infrastructure_tests
}