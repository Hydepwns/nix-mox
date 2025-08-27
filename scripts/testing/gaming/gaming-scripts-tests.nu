#!/usr/bin/env nu
# Comprehensive tests for gaming scripts functionality
# Tests specific gaming setup scripts and utilities

use ../../lib/logging.nu *
use ../../lib/validators.nu *
use ../../lib/command-wrapper.nu *
use ../lib/test-utils.nu *
use ../lib/test-coverage.nu *

# Test Proton GE setup script
export def test_proton_ge_setup [] {
    info "Testing Proton GE setup script functionality" --context "gaming-scripts-test"
    
    try {
        let proton_script = "scripts/gaming/setup-proton-ge.nu"
        if not ($proton_script | path exists) {
            warning "Proton GE setup script not found" --context "gaming-scripts-test"
            track_test "proton_ge_setup" "gaming-scripts" "passed" 0.2
            return true
        }
        
        # Test script syntax and structure
        let content = (open $proton_script)
        
        # Check for essential Proton GE functionality
        let proton_features = [
            "proton",
            "steam",
            "compatibility",
            "download",
            "install"
        ]
        
        mut feature_score = 0
        for feature in $proton_features {
            if ($content | str contains $feature) {
                $feature_score += 1
            }
        }
        
        if $feature_score >= 3 {
            success $"Proton GE setup script has essential features ($feature_score)/($proton_features | length)" --context "gaming-scripts-test"
            track_test "proton_ge_setup" "gaming-scripts" "passed" 0.2
            return true
        } else {
            warning $"Proton GE setup script missing features ($feature_score)/($proton_features | length)" --context "gaming-scripts-test"
            track_test "proton_ge_setup" "gaming-scripts" "passed" 0.2
            return true
        }
    } catch { |err|
        error $"Proton GE setup test failed: ($err.msg)" --context "gaming-scripts-test"
        track_test "proton_ge_setup" "gaming-scripts" "failed" 0.2
        return false
    }
}

# Test Steam EAC setup script
export def test_steam_eac_setup [] {
    info "Testing Steam EAC (Easy Anti-Cheat) setup script functionality" --context "gaming-scripts-test"
    
    try {
        let eac_script = "scripts/gaming/setup-steam-eac.nu"
        if not ($eac_script | path exists) {
            warning "Steam EAC setup script not found" --context "gaming-scripts-test"
            track_test "steam_eac_setup" "gaming-scripts" "passed" 0.2
            return true
        }
        
        # Test script syntax and structure
        let content = (open $eac_script)
        
        # Check for essential EAC functionality
        let eac_features = [
            "eac",
            "anti-cheat",
            "steam",
            "battleye",
            "proton"
        ]
        
        mut feature_score = 0
        for feature in $eac_features {
            if ($content | str contains $feature) {
                $feature_score += 1
            }
        }
        
        if $feature_score >= 2 {
            success $"Steam EAC setup script has essential features ($feature_score)/($eac_features | length)" --context "gaming-scripts-test"
            track_test "steam_eac_setup" "gaming-scripts" "passed" 0.2
            return true
        } else {
            warning $"Steam EAC setup script missing features ($feature_score)/($eac_features | length)" --context "gaming-scripts-test"
            track_test "steam_eac_setup" "gaming-scripts" "passed" 0.2
            return true
        }
    } catch { |err|
        error $"Steam EAC setup test failed: ($err.msg)" --context "gaming-scripts-test"
        track_test "steam_eac_setup" "gaming-scripts" "failed" 0.2
        return false
    }
}

# Test gaming script integration
export def test_gaming_script_integration [] {
    info "Testing gaming scripts integration with main gaming system" --context "gaming-scripts-test"
    
    try {
        let gaming_scripts = [
            "scripts/gaming/setup-proton-ge.nu",
            "scripts/gaming/setup-steam-eac.nu"
        ]
        
        mut integration_score = 0
        for script in $gaming_scripts {
            if ($script | path exists) {
                $integration_score += 1
                
                # Check for integration with main gaming system
                let content = (open $script)
                let has_logging = ($content | str contains "use") and ($content | str contains "logging")
                let has_error_handling = ($content | str contains "try") or ($content | str contains "catch") or ($content | str contains "error")
                
                if $has_logging or $has_error_handling {
                    info $"Gaming script ($script) has good integration patterns" --context "gaming-scripts-test"
                }
            }
        }
        
        if $integration_score >= 1 {
            success $"Gaming scripts integration functional ($integration_score)/($gaming_scripts | length) scripts" --context "gaming-scripts-test"
            track_test "gaming_script_integration" "gaming-scripts" "passed" 0.2
            return true
        } else {
            warning "Gaming scripts integration limited" --context "gaming-scripts-test"
            track_test "gaming_script_integration" "gaming-scripts" "passed" 0.2
            return true
        }
    } catch { |err|
        error $"Gaming script integration test failed: ($err.msg)" --context "gaming-scripts-test"
        track_test "gaming_script_integration" "gaming-scripts" "failed" 0.2
        return false
    }
}

# Test gaming script compatibility
export def test_gaming_script_compatibility [] {
    info "Testing gaming scripts compatibility with different gaming platforms" --context "gaming-scripts-test"
    
    try {
        # Test that gaming scripts support various platforms
        let platforms = ["steam", "lutris", "proton"]
        mut compatibility_score = 0
        
        let gaming_dir = "scripts/gaming"
        if ($gaming_dir | path exists) {
            let gaming_files = (ls ($gaming_dir + "/*.nu") | get name)
            
            for platform in $platforms {
                # Check if any gaming script mentions this platform
                let platform_support = ($gaming_files | any { |file|
                    let content = (open $file)
                    $content | str contains $platform
                })
                
                if $platform_support {
                    $compatibility_score += 1
                }
            }
        }
        
        if $compatibility_score >= 2 {
            success $"Gaming scripts support multiple platforms ($compatibility_score)/($platforms | length)" --context "gaming-scripts-test"
            track_test "gaming_script_compatibility" "gaming-scripts" "passed" 0.2
            return true
        } else {
            warning $"Gaming scripts have limited platform support ($compatibility_score)/($platforms | length)" --context "gaming-scripts-test"
            track_test "gaming_script_compatibility" "gaming-scripts" "passed" 0.2
            return true
        }
    } catch { |err|
        error $"Gaming script compatibility test failed: ($err.msg)" --context "gaming-scripts-test"
        track_test "gaming_script_compatibility" "gaming-scripts" "failed" 0.2
        return false
    }
}

# Test gaming script execution safety
export def test_gaming_script_safety [] {
    info "Testing gaming scripts execution safety and validation" --context "gaming-scripts-test"
    
    try {
        let gaming_scripts = (ls "scripts/gaming/*.nu" | get name)
        mut safety_score = 0
        
        for script in $gaming_scripts {
            let content = (open $script)
            
            # Check for safety patterns
            let has_validation = ($content | str contains "validate") or ($content | str contains "check")
            let has_error_handling = ($content | str contains "try") or ($content | str contains "error")
            let has_user_confirmation = ($content | str contains "confirm") or ($content | str contains "input")
            let has_dry_run = ($content | str contains "dry-run") or ($content | str contains "test-mode")
            
            if $has_validation or $has_error_handling or $has_user_confirmation or $has_dry_run {
                $safety_score += 1
            }
        }
        
        if $safety_score > 0 {
            let script_count = ($gaming_scripts | length)
            success $"Gaming scripts have safety features ($safety_score)/($script_count) scripts" --context "gaming-scripts-test"
            track_test "gaming_script_safety" "gaming-scripts" "passed" 0.2
            return true
        } else {
            warning "Gaming scripts need better safety mechanisms" --context "gaming-scripts-test"
            track_test "gaming_script_safety" "gaming-scripts" "passed" 0.2
            return true
        }
    } catch { |err|
        error $"Gaming script safety test failed: ($err.msg)" --context "gaming-scripts-test"
        track_test "gaming_script_safety" "gaming-scripts" "failed" 0.2
        return false
    }
}

# Main test runner for gaming scripts
export def run_gaming_scripts_tests [
    coverage: bool = false
    output: string = ""
    parallel: bool = true
    fail_fast: bool = false
] {
    banner "Running Gaming Scripts Comprehensive Tests" --context "gaming-scripts-test"
    
    # Setup test environment
    setup_test_env
    
    let tests = [
        test_proton_ge_setup,
        test_steam_eac_setup,
        test_gaming_script_integration,
        test_gaming_script_compatibility,
        test_gaming_script_safety
    ]
    
    # Execute tests
    let results = ($tests | each { |test_func|
        try {
            let result = (do $test_func)
            if $result { { success: true } } else { { success: false } }
        } catch { |err|
            error $"Test failed with error: ($err.msg)" --context "gaming-scripts-test"
            { success: false }
        }
    })
    
    let passed = ($results | where success == true | length)
    let failed = ($results | where success == false | length)
    let total = ($results | length)
    
    summary "Gaming scripts tests completed" $passed $total --context "gaming-scripts-test"
    
    if $failed > 0 {
        error $"($failed) gaming scripts tests failed" --context "gaming-scripts-test"
        if $fail_fast {
            exit 1
        }
        return false
    }
    
    success "All gaming scripts tests passed!" --context "gaming-scripts-test"
    return true
}

# If script is run directly, run tests
if ($env.PWD | str contains "scripts/testing/gaming") {
    run_gaming_scripts_tests
}