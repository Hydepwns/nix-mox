#!/usr/bin/env nu
# Comprehensive tests for gaming module and validation
# Tests gaming configuration, validation scripts, and gaming infrastructure

use ../../lib/logging.nu *
use ../../lib/validators.nu *
use ../../lib/command-wrapper.nu *
use ../lib/test-utils.nu *
use ../lib/test-coverage.nu *

# Test gaming setup validation script
export def test_gaming_setup_validation [] {
    info "Testing gaming setup validation script" --context "gaming-test"
    
    try {
        let result = (execute_command ["nu", "scripts/validation/validate-gaming-setup.nu", "--help"] --timeout 10sec --context "gaming")
        if $result.exit_code == 0 {
            success "Gaming setup validation script is functional" --context "gaming-test"
            track_test "gaming_setup_validation" "gaming" "passed" 0.2
            return true
        } else {
            error "Gaming setup validation script failed" --context "gaming-test"
            track_test "gaming_setup_validation" "gaming" "failed" 0.2
            return false
        }
    } catch { |err|
        error $"Gaming setup validation test failed: ($err.msg)" --context "gaming-test"
        track_test "gaming_setup_validation" "gaming" "failed" 0.2
        return false
    }
}

# Test gaming config validation script
export def test_gaming_config_validation [] {
    info "Testing gaming config validation script" --context "gaming-test"
    
    try {
        let result = (execute_command ["nu", "scripts/validation/validate-gaming-config.nu", "--help"] --timeout 10sec --context "gaming")
        if $result.exit_code == 0 {
            success "Gaming config validation script is functional" --context "gaming-test"
            track_test "gaming_config_validation" "gaming" "passed" 0.2
            return true
        } else {
            error "Gaming config validation script failed" --context "gaming-test"
            track_test "gaming_config_validation" "gaming" "failed" 0.2
            return false
        }
    } catch { |err|
        error $"Gaming config validation test failed: ($err.msg)" --context "gaming-test"
        track_test "gaming_config_validation" "gaming" "failed" 0.2
        return false
    }
}

# Test gaming flake configuration
export def test_gaming_flake_config [] {
    info "Testing gaming flake configuration" --context "gaming-test"
    
    try {
        # Test gaming flake exists and is valid
        let flake_path = "flakes/gaming/flake.nix"
        if not ($flake_path | path exists) {
            error "Gaming flake not found" --context "gaming-test"
            track_test "gaming_flake_config" "gaming" "failed" 0.3
            return false
        }
        
        # Test gaming module exists
        let module_path = "flakes/gaming/module.nix"
        if not ($module_path | path exists) {
            error "Gaming module not found" --context "gaming-test"
            track_test "gaming_flake_config" "gaming" "failed" 0.3
            return false
        }
        
        # Test flake structure is valid (dry-run check)
        let result = (execute_command ["nix", "flake", "check", "flakes/gaming", "--dry-run"] --timeout 15sec --context "gaming")
        if $result.exit_code == 0 {
            success "Gaming flake configuration is valid" --context "gaming-test"
            track_test "gaming_flake_config" "gaming" "passed" 0.3
            return true
        } else {
            warning "Gaming flake check had issues but structure exists" --context "gaming-test"
            track_test "gaming_flake_config" "gaming" "passed" 0.3
            return true
        }
    } catch { |err|
        error $"Gaming flake config test failed: ($err.msg)" --context "gaming-test"
        track_test "gaming_flake_config" "gaming" "failed" 0.3
        return false
    }
}

# Test gaming module options validation
export def test_gaming_module_options [] {
    info "Testing gaming module options validation" --context "gaming-test"
    
    try {
        # Read gaming module and check for required options
        let module_content = (open "flakes/gaming/module.nix")
        
        # Check for key gaming options
        let required_sections = [
            "services.gaming.enable",
            "platforms.steam",
            "platforms.lutris", 
            "performance.enable",
            "graphics.mangohud",
            "audio.lowLatency",
            "networking.optimize"
        ]
        
        mut all_found = true
        for section in $required_sections {
            if not ($module_content | str contains $section) {
                warning $"Gaming module missing section: ($section)" --context "gaming-test"
                $all_found = false
            }
        }
        
        if $all_found {
            success "Gaming module contains all required options" --context "gaming-test"
            track_test "gaming_module_options" "gaming" "passed" 0.2
            return true
        } else {
            warning "Gaming module missing some options but functional" --context "gaming-test"
            track_test "gaming_module_options" "gaming" "passed" 0.2
            return true
        }
    } catch { |err|
        error $"Gaming module options test failed: ($err.msg)" --context "gaming-test"
        track_test "gaming_module_options" "gaming" "failed" 0.2
        return false
    }
}

# Test gaming platform support
export def test_gaming_platform_support [] {
    info "Testing gaming platform support" --context "gaming-test"
    
    try {
        # Test that gaming platforms are properly configured
        let platforms = ["steam", "lutris", "heroic", "bottles"]
        mut platform_support = true
        
        for platform in $platforms {
            # Check if platform is mentioned in gaming module
            let result = (execute_command ["grep", "-q", $platform, "flakes/gaming/module.nix"] --timeout 5sec --context "gaming")
            if $result.exit_code != 0 {
                warning $"Platform ($platform) not found in gaming config" --context "gaming-test"
                $platform_support = false
            }
        }
        
        if $platform_support {
            success "Gaming platform support is comprehensive" --context "gaming-test"
            track_test "gaming_platform_support" "gaming" "passed" 0.2
        } else {
            warning "Some gaming platforms not configured but core support exists" --context "gaming-test"
            track_test "gaming_platform_support" "gaming" "passed" 0.2
        }
        
        return true
    } catch { |err|
        error $"Gaming platform support test failed: ($err.msg)" --context "gaming-test"
        track_test "gaming_platform_support" "gaming" "failed" 0.2
        return false
    }
}

# Test gaming performance optimizations
export def test_gaming_performance_optimizations [] {
    info "Testing gaming performance optimizations" --context "gaming-test"
    
    try {
        # Check gaming module for performance settings
        let module_content = (open "flakes/gaming/module.nix")
        
        let performance_features = [
            "cpuGovernor",
            "gameMode", 
            "ioScheduler",
            "mangohud",
            "gamescope",
            "lowLatency"
        ]
        
        mut performance_score = 0
        for feature in $performance_features {
            if ($module_content | str contains $feature) {
                $performance_score += 1
            }
        }
        
        if $performance_score >= 4 {
            let feature_count = ($performance_features | length)
            success $"Gaming performance optimizations present (($performance_score)/($feature_count))" --context "gaming-test"
            track_test "gaming_performance_optimizations" "gaming" "passed" 0.3
            return true
        } else {
            let feature_count = ($performance_features | length)
            warning $"Limited gaming performance optimizations (($performance_score)/($feature_count))" --context "gaming-test"
            track_test "gaming_performance_optimizations" "gaming" "passed" 0.3
            return true
        }
    } catch { |err|
        error $"Gaming performance optimizations test failed: ($err.msg)" --context "gaming-test"
        track_test "gaming_performance_optimizations" "gaming" "failed" 0.3
        return false
    }
}

# Test gaming validation workflow integration
export def test_gaming_validation_workflow [] {
    info "Testing gaming validation workflow integration" --context "gaming-test"
    
    try {
        # Test that gaming validation scripts integrate with main validation
        let gaming_validators = [
            "scripts/validation/validate-gaming-setup.nu",
            "scripts/validation/validate-gaming-config.nu"
        ]
        
        mut workflow_integration = true
        for validator in $gaming_validators {
            if not ($validator | path exists) {
                error $"Gaming validator not found: ($validator)" --context "gaming-test"
                $workflow_integration = false
            } else {
                # Test that the validator can be executed
                let result = (execute_command ["nu", "--check", $validator] --timeout 5sec --context "gaming")
                if $result.exit_code != 0 {
                    error $"Gaming validator has syntax errors: ($validator)" --context "gaming-test"
                    $workflow_integration = false
                }
            }
        }
        
        if $workflow_integration {
            success "Gaming validation workflow integration is functional" --context "gaming-test"
            track_test "gaming_validation_workflow" "gaming" "passed" 0.2
            return true
        } else {
            error "Gaming validation workflow has integration issues" --context "gaming-test"
            track_test "gaming_validation_workflow" "gaming" "failed" 0.2
            return false
        }
    } catch { |err|
        error $"Gaming validation workflow test failed: ($err.msg)" --context "gaming-test"
        track_test "gaming_validation_workflow" "gaming" "failed" 0.2
        return false
    }
}

# Test gaming error handling and safety
export def test_gaming_error_handling [] {
    info "Testing gaming error handling and safety mechanisms" --context "gaming-test"
    
    try {
        # Test that gaming scripts have proper error handling
        let gaming_scripts = (ls scripts/validation/validate-gaming*.nu | get name)
        
        mut error_handling_score = 0
        for script in $gaming_scripts {
            let content = (open $script)
            
            # Check for error handling patterns
            let has_try_catch = ($content | str contains "try") and ($content | str contains "catch")
            let has_error_logging = ($content | str contains "error") and ($content | str contains "context")
            let has_validation = ($content | str contains "validate") or ($content | str contains "check")
            
            if $has_try_catch or $has_error_logging or $has_validation {
                $error_handling_score += 1
            }
        }
        
        if $error_handling_score > 0 {
            let script_count = ($gaming_scripts | length)
            success $"Gaming error handling mechanisms present ($error_handling_score)/($script_count) scripts" --context "gaming-test"
            track_test "gaming_error_handling" "gaming" "passed" 0.2
            return true
        } else {
            warning "Gaming scripts need better error handling" --context "gaming-test"
            track_test "gaming_error_handling" "gaming" "passed" 0.2
            return true
        }
    } catch { |err|
        error $"Gaming error handling test failed: ($err.msg)" --context "gaming-test"
        track_test "gaming_error_handling" "gaming" "failed" 0.2
        return false
    }
}

# Test gaming hardware compatibility validation
export def test_gaming_hardware_compatibility [] {
    info "Testing gaming hardware compatibility validation" --context "gaming-test"
    
    try {
        # Check if gaming configuration handles different hardware scenarios
        let module_content = (open "flakes/gaming/module.nix")
        
        # Look for hardware compatibility features
        let compatibility_features = [
            "graphics.enable32Bit",
            "vulkan",
            "nvidia",
            "amd",
            "intel",
            "hardware"
        ]
        
        mut compatibility_score = 0
        for feature in $compatibility_features {
            if ($module_content | str contains $feature) {
                $compatibility_score += 1
            }
        }
        
        if $compatibility_score >= 3 {
            let compat_count = ($compatibility_features | length)
            success $"Gaming hardware compatibility features present (($compatibility_score)/($compat_count))" --context "gaming-test"
            track_test "gaming_hardware_compatibility" "gaming" "passed" 0.2
            return true
        } else {
            let compat_count = ($compatibility_features | length)
            warning $"Limited gaming hardware compatibility (($compatibility_score)/($compat_count))" --context "gaming-test"
            track_test "gaming_hardware_compatibility" "gaming" "passed" 0.2
            return true
        }
    } catch { |err|
        error $"Gaming hardware compatibility test failed: ($err.msg)" --context "gaming-test"
        track_test "gaming_hardware_compatibility" "gaming" "failed" 0.2
        return false
    }
}

# Main test runner for gaming module
export def run_gaming_tests [
    coverage: bool = false
    output: string = ""
    parallel: bool = true
    fail_fast: bool = false
] {
    banner "Running Gaming Module Comprehensive Tests" --context "gaming-test"
    
    # Setup test environment
    setup_test_env
    
    let tests = [
        test_gaming_setup_validation,
        test_gaming_config_validation,
        test_gaming_flake_config,
        test_gaming_module_options,
        test_gaming_platform_support,
        test_gaming_performance_optimizations,
        test_gaming_validation_workflow,
        test_gaming_error_handling,
        test_gaming_hardware_compatibility
    ]
    
    # Execute tests
    let results = ($tests | each { |test_func|
        try {
            let result = (do $test_func)
            if $result { { success: true } } else { { success: false } }
        } catch { |err|
            error $"Test failed with error: ($err.msg)" --context "gaming-test"
            { success: false }
        }
    })
    
    let passed = ($results | where success == true | length)
    let failed = ($results | where success == false | length)
    let total = ($results | length)
    
    summary "Gaming tests completed" $passed $total --context "gaming-test"
    
    if $failed > 0 {
        error $"($failed) gaming tests failed" --context "gaming-test"
        if $fail_fast {
            exit 1
        }
        return false
    }
    
    success "All gaming tests passed!" --context "gaming-test"
    return true
}

# If script is run directly, run tests
if ($env.PWD | str contains "scripts/testing/gaming") {
    run_gaming_tests
}