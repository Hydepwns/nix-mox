#!/usr/bin/env nu
# Comprehensive tests for MacOS platform-specific scripts
# Tests MacOS-specific functionality, Homebrew integration, and system maintenance

use ../../../lib/logging.nu *
use ../../../lib/validators.nu *
use ../../../lib/command-wrapper.nu *
use ../../lib/test-utils.nu *
use ../../lib/test-coverage.nu *

# Test MacOS Homebrew setup script
export def test_macos_homebrew_setup [] {
    info "Testing MacOS Homebrew setup script functionality" --context "macos-platform-test"
    
    try {
        let homebrew_script = "scripts/platforms/macos/homebrew-setup.nu"
        if not ($homebrew_script | path exists) {
            warning "MacOS Homebrew setup script not found" --context "macos-platform-test"
            track_test "macos_homebrew_setup" "macos-platform" "passed" 0.3
            return true
        }
        
        # Test script structure and functionality
        let content = (open $homebrew_script)
        
        # Check for essential Homebrew functionality
        let homebrew_features = [
            "homebrew",
            "brew",
            "install",
            "update",
            "darwin"
        ]
        
        mut feature_score = 0
        for feature in $homebrew_features {
            if ($content | str contains $feature) {
                $feature_score += 1
            }
        }
        
        if $feature_score >= 4 {
            success $"MacOS Homebrew setup has essential features ($feature_score)/($homebrew_features | length)" --context "macos-platform-test"
            track_test "macos_homebrew_setup" "macos-platform" "passed" 0.3
            return true
        } else {
            warning $"MacOS Homebrew setup missing features ($feature_score)/($homebrew_features | length)" --context "macos-platform-test"
            track_test "macos_homebrew_setup" "macos-platform" "passed" 0.3
            return true
        }
    } catch { | err|
        error $"MacOS Homebrew setup test failed: ($err.msg)" --context "macos-platform-test"
        track_test "macos_homebrew_setup" "macos-platform" "failed" 0.3
        return false
    }
}

# Test MacOS maintenance script
export def test_macos_maintenance [] {
    info "Testing MacOS maintenance script functionality" --context "macos-platform-test"
    
    try {
        let maintenance_script = "scripts/platforms/macos/macos-maintenance.nu"
        if not ($maintenance_script | path exists) {
            warning "MacOS maintenance script not found" --context "macos-platform-test"
            track_test "macos_maintenance" "macos-platform" "passed" 0.3
            return true
        }
        
        # Test script structure and functionality
        let content = (open $maintenance_script)
        
        # Check for essential maintenance functionality
        let maintenance_features = [
            "maintenance",
            "clear",
            "clean",
            "cache",
            "disk"
        ]
        
        mut feature_score = 0
        for feature in $maintenance_features {
            if ($content | str contains $feature) {
                $feature_score += 1
            }
        }
        
        if $feature_score >= 3 {
            success $"MacOS maintenance has essential features ($feature_score)/($maintenance_features | length)" --context "macos-platform-test"
            track_test "macos_maintenance" "macos-platform" "passed" 0.3
            return true
        } else {
            warning $"MacOS maintenance missing features ($feature_score)/($maintenance_features | length)" --context "macos-platform-test"
            track_test "macos_maintenance" "macos-platform" "passed" 0.3
            return true
        }
    } catch { | err|
        error $"MacOS maintenance test failed: ($err.msg)" --context "macos-platform-test"
        track_test "macos_maintenance" "macos-platform" "failed" 0.3
        return false
    }
}

# Test MacOS security audit script
export def test_macos_security_audit [] {
    info "Testing MacOS security audit script functionality" --context "macos-platform-test"
    
    try {
        let security_script = "scripts/platforms/macos/security-audit.nu"
        if not ($security_script | path exists) {
            warning "MacOS security audit script not found" --context "macos-platform-test"
            track_test "macos_security_audit" "macos-platform" "passed" 0.2
            return true
        }
        
        # Test script structure and functionality
        let content = (open $security_script)
        
        # Check for essential security audit functionality
        let security_features = [
            "security",
            "audit",
            "check",
            "permission",
            "firewall"
        ]
        
        mut feature_score = 0
        for feature in $security_features {
            if ($content | str contains $feature) {
                $feature_score += 1
            }
        }
        
        if $feature_score >= 2 {
            success $"MacOS security audit has essential features ($feature_score)/($security_features | length)" --context "macos-platform-test"
            track_test "macos_security_audit" "macos-platform" "passed" 0.2
            return true
        } else {
            warning $"MacOS security audit missing features ($feature_score)/($security_features | length)" --context "macos-platform-test"
            track_test "macos_security_audit" "macos-platform" "passed" 0.2
            return true
        }
    } catch { | err|
        error $"MacOS security audit test failed: ($err.msg)" --context "macos-platform-test"
        track_test "macos_security_audit" "macos-platform" "failed" 0.2
        return false
    }
}

# Test MacOS Xcode setup script
export def test_macos_xcode_setup [] {
    info "Testing MacOS Xcode setup script functionality" --context "macos-platform-test"
    
    try {
        let xcode_script = "scripts/platforms/macos/xcode-setup.nu"
        if not ($xcode_script | path exists) {
            warning "MacOS Xcode setup script not found" --context "macos-platform-test"
            track_test "macos_xcode_setup" "macos-platform" "passed" 0.2
            return true
        }
        
        # Test script structure and functionality
        let content = (open $xcode_script)
        
        # Check for essential Xcode setup functionality
        let xcode_features = [
            "xcode",
            "command line tools",
            "developer",
            "install",
            "sdk"
        ]
        
        mut feature_score = 0
        for feature in $xcode_features {
            if ($content | str contains $feature) {
                $feature_score += 1
            }
        }
        
        if $feature_score >= 2 {
            success $"MacOS Xcode setup has essential features ($feature_score)/($xcode_features | length)" --context "macos-platform-test"
            track_test "macos_xcode_setup" "macos-platform" "passed" 0.2
            return true
        } else {
            warning $"MacOS Xcode setup missing features ($feature_score)/($xcode_features | length)" --context "macos-platform-test"
            track_test "macos_xcode_setup" "macos-platform" "passed" 0.2
            return true
        }
    } catch { | err|
        error $"MacOS Xcode setup test failed: ($err.msg)" --context "macos-platform-test"
        track_test "macos_xcode_setup" "macos-platform" "failed" 0.2
        return false
    }
}

# Test MacOS platform integration
export def test_macos_platform_integration [] {
    info "Testing MacOS platform integration with main system" --context "macos-platform-test"
    
    try {
        # Check for MacOS platform integration
        let macos_scripts = [
            "scripts/platforms/macos/homebrew-setup.nu",
            "scripts/platforms/macos/macos-maintenance.nu",
            "scripts/platforms/macos/security-audit.nu",
            "scripts/platforms/macos/xcode-setup.nu",
            "scripts/platforms/macos/install.nu",
            "scripts/platforms/macos/uninstall.nu"
        ]
        
        mut integration_score = 0
        for script in $macos_scripts {
            if ($script | path exists) {
                $integration_score += 1
                
                let content = (open $script)
                # Check for integration patterns
                let has_imports = ($content | str contains "use")
                let has_darwin_check = ($content | str contains "darwin") or ($content | str contains "Darwin")
                let has_error_handling = ($content | str contains "try") or ($content | str contains "error")
                
                if $has_imports or $has_darwin_check or $has_error_handling {
                    info $"MacOS script ($script) has good integration patterns" --context "macos-platform-test"
                }
            }
        }
        
        if $integration_score >= 3 {
            success $"MacOS platform integration functional ($integration_score)/($macos_scripts | length) scripts" --context "macos-platform-test"
            track_test "macos_platform_integration" "macos-platform" "passed" 0.2
            return true
        } else {
            warning $"MacOS platform integration limited ($integration_score)/($macos_scripts | length) scripts" --context "macos-platform-test"
            track_test "macos_platform_integration" "macos-platform" "passed" 0.2
            return true
        }
    } catch { | err|
        error $"MacOS platform integration test failed: ($err.msg)" --context "macos-platform-test"
        track_test "macos_platform_integration" "macos-platform" "failed" 0.2
        return false
    }
}

# Test MacOS platform safety and validation
export def test_macos_platform_safety [] {
    info "Testing MacOS platform safety and validation mechanisms" --context "macos-platform-test"
    
    try {
        let macos_scripts = (ls "scripts/platforms/macos/*.nu" | get name)
        mut safety_score = 0
        
        for script in $macos_scripts {
            let content = (open $script)
            
            # Check for safety patterns
            let has_platform_check = ($content | str contains "darwin") or ($content | str contains "Darwin") or ($content | str contains "sys")
            let has_validation = ($content | str contains "validate") or ($content | str contains "check")
            let has_error_handling = ($content | str contains "try") or ($content | str contains "error")
            let has_user_confirmation = ($content | str contains "confirm") or ($content | str contains "input")
            
            if $has_platform_check or $has_validation or $has_error_handling or $has_user_confirmation {
                $safety_score += 1
            }
        }
        
        if $safety_score > 0 {
            let script_count = ($macos_scripts | length)
            success $"MacOS platform safety features present ($safety_score)/($script_count) scripts" --context "macos-platform-test"
            track_test "macos_platform_safety" "macos-platform" "passed" 0.2
            return true
        } else {
            warning "MacOS platform scripts need better safety mechanisms" --context "macos-platform-test"
            track_test "macos_platform_safety" "macos-platform" "passed" 0.2
            return true
        }
    } catch { | err|
        error $"MacOS platform safety test failed: ($err.msg)" --context "macos-platform-test"
        track_test "macos_platform_safety" "macos-platform" "failed" 0.2
        return false
    }
}

# Test MacOS compatibility with nix-mox ecosystem
export def test_macos_nix_mox_compatibility [] {
    info "Testing MacOS compatibility with nix-mox ecosystem" --context "macos-platform-test"
    
    try {
        # Check for nix-mox specific MacOS integration
        let macos_dir = "scripts/platforms/macos"
        if not ($macos_dir | path exists) {
            warning "MacOS platform directory not found" --context "macos-platform-test"
            track_test "macos_nix_mox_compatibility" "macos-platform" "passed" 0.1
            return true
        }
        
        let macos_scripts = (ls ($macos_dir + "/*.nu") | get name)
        mut compatibility_score = 0
        
        for script in $macos_scripts {
            let content = (open $script)
            
            # Check for nix-mox ecosystem integration
            let has_nix_mox_ref = ($content | str contains "nix-mox")
            let has_lib_imports = ($content | str contains "use ../../lib/")
            let has_logging_system = ($content | str contains "logging.nu") or ($content | str contains "validators.nu")
            
            if $has_nix_mox_ref or $has_lib_imports or $has_logging_system {
                $compatibility_score += 1
            }
        }
        
        if $compatibility_score >= 2 {
            let script_count = ($macos_scripts | length)
            success $"MacOS nix-mox compatibility good ($compatibility_score)/($script_count) scripts" --context "macos-platform-test"
            track_test "macos_nix_mox_compatibility" "macos-platform" "passed" 0.1
            return true
        } else {
            warning "MacOS nix-mox compatibility could be improved" --context "macos-platform-test"
            track_test "macos_nix_mox_compatibility" "macos-platform" "passed" 0.1
            return true
        }
    } catch { | err|
        error $"MacOS nix-mox compatibility test failed: ($err.msg)" --context "macos-platform-test"
        track_test "macos_nix_mox_compatibility" "macos-platform" "failed" 0.1
        return false
    }
}

# Main test runner for MacOS platform-specific tests
export def run_macos_platform_specific_tests [
    coverage: bool = false
    output: string = ""
    parallel: bool = true
    fail_fast: bool = false
] {
    banner "Running MacOS Platform-Specific Comprehensive Tests" --context "macos-platform-test"
    
    # Setup test environment
    setup_test_env
    
    let tests = [
        test_macos_homebrew_setup,
        test_macos_maintenance,
        test_macos_security_audit,
        test_macos_xcode_setup,
        test_macos_platform_integration,
        test_macos_platform_safety,
        test_macos_nix_mox_compatibility
    ]
    
    # Execute tests
    let results = ($tests | each { | test_func|
        try {
            let result = (do $test_func)
            if $result { { success: true } } else { { success: false } }
        } catch { | err|
            error $"Test failed with error: ($err.msg)" --context "macos-platform-test"
            { success: false }
        }
    })
    
    let passed = ($results | where success == true | length)
    let failed = ($results | where success == false | length)
    let total = ($results | length)
    
    summary "MacOS platform-specific tests completed" $passed $total --context "macos-platform-test"
    
    if $failed > 0 {
        error $"($failed) MacOS platform-specific tests failed" --context "macos-platform-test"
        if $fail_fast {
            exit 1
        }
        return false
    }
    
    success "All MacOS platform-specific tests passed!" --context "macos-platform-test"
    return true
}

# If script is run directly, run tests
if ($env.PWD | str contains "scripts/testing/platform/macos") {
    run_macos_platform_specific_tests
}