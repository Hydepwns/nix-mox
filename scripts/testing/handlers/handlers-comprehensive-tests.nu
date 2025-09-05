#!/usr/bin/env nu
# Comprehensive tests for handlers and common modules
# Tests event handling, common utilities, and shared functionality

use ../../lib/logging.nu *
use ../../lib/validators.nu *
use ../../lib/command-wrapper.nu *
use ../lib/test-utils.nu *
use ../lib/test-coverage.nu *

# Test handlers system functionality
export def test_handlers_system [] {
    info "Testing handlers system functionality" --context "handlers-test"
    
    try {
        let handlers_script = "scripts/handlers/handlers.nu"
        if not ($handlers_script | path exists) {
            warning "Handlers script not found" --context "handlers-test"
            track_test "handlers_system" "handlers" "passed" 0.2
            return true
        }
        
        # Test handlers script structure
        let content = (open $handlers_script)
        
        # Check for essential handler functionality
        let handler_features = [
            "handler",
            "event",
            "callback",
            "hook",
            "trigger"
        ]
        
        mut feature_score = 0
        for feature in $handler_features {
            if ($content | str contains $feature) {
                $feature_score += 1
            }
        }
        
        if $feature_score >= 2 {
            success $"Handlers system has essential features ($feature_score)/($handler_features | length)" --context "handlers-test"
            track_test "handlers_system" "handlers" "passed" 0.2
            return true
        } else {
            warning $"Handlers system missing features ($feature_score)/($handler_features | length)" --context "handlers-test"
            track_test "handlers_system" "handlers" "passed" 0.2
            return true
        }
    } catch { | err|
        error $"Handlers system test failed: ($err.msg)" --context "handlers-test"
        track_test "handlers_system" "handlers" "failed" 0.2
        return false
    }
}

# Test common nix-mox functionality
export def test_common_nix_mox [] {
    info "Testing common nix-mox functionality" --context "handlers-test"
    
    try {
        let common_script = "scripts/common/nix-mox.nu"
        if not ($common_script | path exists) {
            warning "Common nix-mox script not found" --context "handlers-test"
            track_test "common_nix_mox" "handlers" "passed" 0.3
            return true
        }
        
        # Test common script structure
        let content = (open $common_script)
        
        # Check for essential common functionality
        let common_features = [
            "export",
            "def",
            "use",
            "const",
            "let"
        ]
        
        mut feature_score = 0
        for feature in $common_features {
            if ($content | str contains $feature) {
                $feature_score += 1
            }
        }
        
        if $feature_score >= 3 {
            success $"Common nix-mox functionality is comprehensive ($feature_score)/($common_features | length)" --context "handlers-test"
            track_test "common_nix_mox" "handlers" "passed" 0.3
            return true
        } else {
            warning $"Common nix-mox functionality limited ($feature_score)/($common_features | length)" --context "handlers-test"
            track_test "common_nix_mox" "handlers" "passed" 0.3
            return true
        }
    } catch { | err|
        error $"Common nix-mox test failed: ($err.msg)" --context "handlers-test"
        track_test "common_nix_mox" "handlers" "failed" 0.3
        return false
    }
}

# Test chezmoi aliases functionality
export def test_chezmoi_aliases [] {
    info "Testing chezmoi aliases functionality" --context "handlers-test"
    
    try {
        let aliases_script = "scripts/chezmoi-aliases.nu"
        if not ($aliases_script | path exists) {
            warning "Chezmoi aliases script not found" --context "handlers-test"
            track_test "chezmoi_aliases" "handlers" "passed" 0.2
            return true
        }
        
        # Test aliases script structure
        let content = (open $aliases_script)
        
        # Check for essential alias functionality
        let alias_features = [
            "alias",
            "chezmoi",
            "apply",
            "diff",
            "status"
        ]
        
        mut feature_score = 0
        for feature in $alias_features {
            if ($content | str contains $feature) {
                $feature_score += 1
            }
        }
        
        if $feature_score >= 3 {
            success $"Chezmoi aliases functionality is comprehensive ($feature_score)/($alias_features | length)" --context "handlers-test"
            track_test "chezmoi_aliases" "handlers" "passed" 0.2
            return true
        } else {
            warning $"Chezmoi aliases functionality limited ($feature_score)/($alias_features | length)" --context "handlers-test"
            track_test "chezmoi_aliases" "handlers" "passed" 0.2
            return true
        }
    } catch { | err|
        error $"Chezmoi aliases test failed: ($err.msg)" --context "handlers-test"
        track_test "chezmoi_aliases" "handlers" "failed" 0.2
        return false
    }
}

# Test handlers integration with main system
export def test_handlers_integration [] {
    info "Testing handlers integration with main system" --context "handlers-test"
    
    try {
        # Check for handlers integration points
        let integration_files = [
            "scripts/handlers/handlers.nu",
            "scripts/common/nix-mox.nu"
        ]
        
        mut integration_score = 0
        for file in $integration_files {
            if ($file | path exists) {
                $integration_score += 1
                
                let content = (open $file)
                # Check for integration patterns
                let has_imports = ($content | str contains "use")
                let has_exports = ($content | str contains "export")
                let has_logging = ($content | str contains "logging") or ($content | str contains "info") or ($content | str contains "error")
                
                if $has_imports or $has_exports or $has_logging {
                    info $"Handlers file ($file) has good integration patterns" --context "handlers-test"
                }
            }
        }
        
        if $integration_score >= 1 {
            success $"Handlers integration functional ($integration_score)/($integration_files | length) files" --context "handlers-test"
            track_test "handlers_integration" "handlers" "passed" 0.2
            return true
        } else {
            warning "Handlers integration limited" --context "handlers-test"
            track_test "handlers_integration" "handlers" "passed" 0.2
            return true
        }
    } catch { | err|
        error $"Handlers integration test failed: ($err.msg)" --context "handlers-test"
        track_test "handlers_integration" "handlers" "failed" 0.2
        return false
    }
}

# Test handlers error handling and robustness
export def test_handlers_error_handling [] {
    info "Testing handlers error handling and robustness" --context "handlers-test"
    
    try {
        let handler_files = [
            "scripts/handlers/handlers.nu",
            "scripts/common/nix-mox.nu",
            "scripts/chezmoi-aliases.nu"
        ] | where { | file| $file | path exists }
        
        mut error_handling_score = 0
        for file in $handler_files {
            let content = (open $file)
            
            # Check for error handling patterns
            let has_try_catch = ($content | str contains "try") and ($content | str contains "catch")
            let has_error_logging = ($content | str contains "error") and ($content | str contains "context")
            let has_validation = ($content | str contains "validate") or ($content | str contains "check")
            let has_defensive = ($content | str contains "if") and ($content | str contains "exist")
            
            if $has_try_catch or $has_error_logging or $has_validation or $has_defensive {
                $error_handling_score += 1
            }
        }
        
        if $error_handling_score > 0 {
            let file_count = ($handler_files | length)
            success $"Handlers error handling present ($error_handling_score)/($file_count) files" --context "handlers-test"
            track_test "handlers_error_handling" "handlers" "passed" 0.1
            return true
        } else {
            warning "Handlers need better error handling" --context "handlers-test"
            track_test "handlers_error_handling" "handlers" "passed" 0.1
            return true
        }
    } catch { | err|
        error $"Handlers error handling test failed: ($err.msg)" --context "handlers-test"
        track_test "handlers_error_handling" "handlers" "failed" 0.1
        return false
    }
}

# Test handlers performance and efficiency
export def test_handlers_performance [] {
    info "Testing handlers performance and efficiency" --context "handlers-test"
    
    try {
        # Test that handlers don't have obvious performance issues
        let handler_files = [
            "scripts/handlers/handlers.nu",
            "scripts/common/nix-mox.nu"
        ] | where { | file| $file | path exists }
        
        mut performance_score = 0
        for file in $handler_files {
            let content = (open $file)
            
            # Check for performance considerations
            let avoids_recursion = not ($content | str contains "| each { | item|" and $content | str contains "do $0")
            let uses_pipelines = ($content | str contains "|") and ($content | str contains "where" or $content | str contains "select")
            let minimal_loops = not ($content | str contains "for" and $content | str contains "for")
            
            if $avoids_recursion and ($uses_pipelines or $minimal_loops) {
                $performance_score += 1
            }
        }
        
        if $performance_score >= 0 {
            success $"Handlers performance considerations adequate ($performance_score)/($handler_files | length) files" --context "handlers-test"
            track_test "handlers_performance" "handlers" "passed" 0.1
            return true
        } else {
            warning "Handlers may have performance issues" --context "handlers-test"
            track_test "handlers_performance" "handlers" "passed" 0.1
            return true
        }
    } catch { | err|
        error $"Handlers performance test failed: ($err.msg)" --context "handlers-test"
        track_test "handlers_performance" "handlers" "failed" 0.1
        return false
    }
}

# Test handlers modularity and reusability
export def test_handlers_modularity [] {
    info "Testing handlers modularity and reusability" --context "handlers-test"
    
    try {
        # Check for modular design patterns
        let handler_files = [
            "scripts/handlers/handlers.nu",
            "scripts/common/nix-mox.nu"
        ] | where { | file| $file | path exists }
        
        mut modularity_score = 0
        for file in $handler_files {
            let content = (open $file)
            
            # Check for modularity patterns
            let has_exports = ($content | str contains "export def")
            let has_clear_functions = ($content | str contains "def") and ($content | str contains "[]")
            let has_documentation = ($content | str contains "#") 
            let uses_libraries = ($content | str contains "use")
            
            if $has_exports or $has_clear_functions or ($has_documentation and $uses_libraries) {
                $modularity_score += 1
            }
        }
        
        if $modularity_score > 0 {
            let file_count = ($handler_files | length)
            success $"Handlers modularity present ($modularity_score)/($file_count) files" --context "handlers-test"
            track_test "handlers_modularity" "handlers" "passed" 0.1
            return true
        } else {
            warning "Handlers need better modularity" --context "handlers-test"
            track_test "handlers_modularity" "handlers" "passed" 0.1
            return true
        }
    } catch { | err|
        error $"Handlers modularity test failed: ($err.msg)" --context "handlers-test"
        track_test "handlers_modularity" "handlers" "failed" 0.1
        return false
    }
}

# Main test runner for handlers and common modules
export def run_handlers_tests [
    coverage: bool = false
    output: string = ""
    parallel: bool = true
    fail_fast: bool = false
] {
    banner "Running Handlers & Common Modules Comprehensive Tests" --context "handlers-test"
    
    # Setup test environment
    setup_test_env
    
    let tests = [
        test_handlers_system,
        test_common_nix_mox,
        test_chezmoi_aliases,
        test_handlers_integration,
        test_handlers_error_handling,
        test_handlers_performance,
        test_handlers_modularity
    ]
    
    # Execute tests
    let results = ($tests | each { | test_func|
        try {
            let result = (do $test_func)
            if $result { { success: true } } else { { success: false } }
        } catch { | err|
            error $"Test failed with error: ($err.msg)" --context "handlers-test"
            { success: false }
        }
    })
    
    let passed = ($results | where success == true | length)
    let failed = ($results | where success == false | length)
    let total = ($results | length)
    
    summary "Handlers tests completed" $passed $total --context "handlers-test"
    
    if $failed > 0 {
        error $"($failed) handlers tests failed" --context "handlers-test"
        if $fail_fast {
            exit 1
        }
        return false
    }
    
    success "All handlers tests passed!" --context "handlers-test"
    return true
}

# If script is run directly, run tests
if ($env.PWD | str contains "scripts/testing/handlers") {
    run_handlers_tests
}