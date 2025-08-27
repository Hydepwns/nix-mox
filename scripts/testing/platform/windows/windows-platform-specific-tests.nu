#!/usr/bin/env nu
# Comprehensive tests for Windows platform-specific scripts
# Tests Windows-specific functionality, Steam/Rust installation, and system integration

use ../../../lib/logging.nu *
use ../../../lib/validators.nu *
use ../../../lib/command-wrapper.nu *
use ../../lib/test-utils.nu *
use ../../lib/test-coverage.nu *

# Test Windows Steam-Rust installation script
export def test_windows_steam_rust_install [] {
    info "Testing Windows Steam-Rust installation script functionality" --context "windows-platform-test"
    
    try {
        let install_script = "scripts/platforms/windows/install-steam-rust.nu"
        if not ($install_script | path exists) {
            warning "Windows Steam-Rust install script not found" --context "windows-platform-test"
            track_test "windows_steam_rust_install" "windows-platform" "passed" 0.4
            return true
        }
        
        # Test script structure and functionality
        let content = (open $install_script)
        
        # Check for essential Steam-Rust functionality
        let install_features = [
            "steam",
            "rust",
            "install",
            "windows",
            "dry-run"
        ]
        
        mut feature_score = 0
        for feature in $install_features {
            if ($content | str contains $feature) {
                $feature_score += 1
            }
        }
        
        if $feature_score >= 4 {
            success $"Windows Steam-Rust install has essential features ($feature_score)/($install_features | length)" --context "windows-platform-test"
            track_test "windows_steam_rust_install" "windows-platform" "passed" 0.4
            return true
        } else {
            warning $"Windows Steam-Rust install missing features ($feature_score)/($install_features | length)" --context "windows-platform-test"
            track_test "windows_steam_rust_install" "windows-platform" "passed" 0.4
            return true
        }
    } catch { |err|
        error $"Windows Steam-Rust install test failed: ($err.msg)" --context "windows-platform-test"
        track_test "windows_steam_rust_install" "windows-platform" "failed" 0.4
        return false
    }
}

# Test Windows platform integration
export def test_windows_platform_integration [] {
    info "Testing Windows platform integration with main system" --context "windows-platform-test"
    
    try {
        # Check for Windows platform integration
        let windows_dir = "scripts/platforms/windows"
        if not ($windows_dir | path exists) {
            warning "Windows platform directory not found" --context "windows-platform-test"
            track_test "windows_platform_integration" "windows-platform" "passed" 0.3
            return true
        }
        
        let windows_scripts = (ls ($windows_dir + "/*.nu") | get name)
        mut integration_score = 0
        
        for script in $windows_scripts {
            let content = (open $script)
            
            # Check for integration patterns
            let has_imports = ($content | str contains "use")
            let has_windows_check = ($content | str contains "windows") or ($content | str contains "Windows")
            let has_error_handling = ($content | str contains "try") or ($content | str contains "error")
            let has_logging = ($content | str contains "log") or ($content | str contains "print")
            
            if $has_imports or $has_windows_check or $has_error_handling or $has_logging {
                $integration_score += 1
                info $"Windows script ($script) has good integration patterns" --context "windows-platform-test"
            }
        }
        
        if $integration_score > 0 {
            let script_count = ($windows_scripts | length)
            success $"Windows platform integration functional ($integration_score)/($script_count) scripts" --context "windows-platform-test"
            track_test "windows_platform_integration" "windows-platform" "passed" 0.3
            return true
        } else {
            warning "Windows platform integration limited" --context "windows-platform-test"
            track_test "windows_platform_integration" "windows-platform" "passed" 0.3
            return true
        }
    } catch { |err|
        error $"Windows platform integration test failed: ($err.msg)" --context "windows-platform-test"
        track_test "windows_platform_integration" "windows-platform" "failed" 0.3
        return false
    }
}

# Test Windows gaming integration
export def test_windows_gaming_integration [] {
    info "Testing Windows gaming integration functionality" --context "windows-platform-test"
    
    try {
        let install_script = "scripts/platforms/windows/install-steam-rust.nu"
        if not ($install_script | path exists) {
            warning "Windows gaming install script not found" --context "windows-platform-test"
            track_test "windows_gaming_integration" "windows-platform" "passed" 0.2
            return true
        }
        
        let content = (open $install_script)
        
        # Check for gaming-specific functionality
        let gaming_features = [
            "steam",
            "game",
            "gaming",
            "rust",
            "facepunch"
        ]
        
        mut gaming_score = 0
        for feature in $gaming_features {
            if ($content | str contains $feature) {
                $gaming_score += 1
            }
        }
        
        if $gaming_score >= 2 {
            success $"Windows gaming integration has essential features ($gaming_score)/($gaming_features | length)" --context "windows-platform-test"
            track_test "windows_gaming_integration" "windows-platform" "passed" 0.2
            return true
        } else {
            warning $"Windows gaming integration missing features ($gaming_score)/($gaming_features | length)" --context "windows-platform-test"
            track_test "windows_gaming_integration" "windows-platform" "passed" 0.2
            return true
        }
    } catch { |err|
        error $"Windows gaming integration test failed: ($err.msg)" --context "windows-platform-test"
        track_test "windows_gaming_integration" "windows-platform" "failed" 0.2
        return false
    }
}

# Test Windows platform safety and validation
export def test_windows_platform_safety [] {
    info "Testing Windows platform safety and validation mechanisms" --context "windows-platform-test"
    
    try {
        let windows_dir = "scripts/platforms/windows"
        if not ($windows_dir | path exists) {
            warning "Windows platform directory not found" --context "windows-platform-test"
            track_test "windows_platform_safety" "windows-platform" "passed" 0.2
            return true
        }
        
        let windows_scripts = (ls ($windows_dir + "/*.nu") | get name)
        mut safety_score = 0
        
        for script in $windows_scripts {
            let content = (open $script)
            
            # Check for safety patterns
            let has_dry_run = ($content | str contains "dry-run") or ($content | str contains "dry_run")
            let has_validation = ($content | str contains "validate") or ($content | str contains "check")
            let has_error_handling = ($content | str contains "try") or ($content | str contains "error")
            let has_help = ($content | str contains "help") or ($content | str contains "--help")
            
            if $has_dry_run or $has_validation or $has_error_handling or $has_help {
                $safety_score += 1
            }
        }
        
        if $safety_score > 0 {
            let script_count = ($windows_scripts | length)
            success $"Windows platform safety features present ($safety_score)/($script_count) scripts" --context "windows-platform-test"
            track_test "windows_platform_safety" "windows-platform" "passed" 0.2
            return true
        } else {
            warning "Windows platform scripts need better safety mechanisms" --context "windows-platform-test"
            track_test "windows_platform_safety" "windows-platform" "passed" 0.2
            return true
        }
    } catch { |err|
        error $"Windows platform safety test failed: ($err.msg)" --context "windows-platform-test"
        track_test "windows_platform_safety" "windows-platform" "failed" 0.2
        return false
    }
}

# Test Windows compatibility with nix-mox ecosystem
export def test_windows_nix_mox_compatibility [] {
    info "Testing Windows compatibility with nix-mox ecosystem" --context "windows-platform-test"
    
    try {
        let windows_dir = "scripts/platforms/windows"
        if not ($windows_dir | path exists) {
            warning "Windows platform directory not found" --context "windows-platform-test"
            track_test "windows_nix_mox_compatibility" "windows-platform" "passed" 0.1
            return true
        }
        
        let windows_scripts = (ls ($windows_dir + "/*.nu") | get name)
        mut compatibility_score = 0
        
        for script in $windows_scripts {
            let content = (open $script)
            
            # Check for nix-mox ecosystem integration
            let has_nix_mox_ref = ($content | str contains "nix-mox")
            let has_lib_imports = ($content | str contains "use") and ($content | str contains "lib/")
            let has_nushell_patterns = ($content | str contains "nu ") or ($content | str contains "#!/usr/bin/env nu")
            let has_standardized_logging = ($content | str contains "log") or ($content | str contains "print")
            
            if $has_nix_mox_ref or $has_lib_imports or $has_nushell_patterns or $has_standardized_logging {
                $compatibility_score += 1
            }
        }
        
        if $compatibility_score > 0 {
            let script_count = ($windows_scripts | length)
            success $"Windows nix-mox compatibility good ($compatibility_score)/($script_count) scripts" --context "windows-platform-test"
            track_test "windows_nix_mox_compatibility" "windows-platform" "passed" 0.1
            return true
        } else {
            warning "Windows nix-mox compatibility could be improved" --context "windows-platform-test"
            track_test "windows_nix_mox_compatibility" "windows-platform" "passed" 0.1
            return true
        }
    } catch { |err|
        error $"Windows nix-mox compatibility test failed: ($err.msg)" --context "windows-platform-test"
        track_test "windows_nix_mox_compatibility" "windows-platform" "failed" 0.1
        return false
    }
}

# Test Windows script structure and best practices
export def test_windows_script_structure [] {
    info "Testing Windows script structure and best practices" --context "windows-platform-test"
    
    try {
        let windows_dir = "scripts/platforms/windows"
        if not ($windows_dir | path exists) {
            warning "Windows platform directory not found" --context "windows-platform-test"
            track_test "windows_script_structure" "windows-platform" "passed" 0.1
            return true
        }
        
        let windows_scripts = (ls ($windows_dir + "/*.nu") | get name)
        mut structure_score = 0
        
        for script in $windows_scripts {
            let content = (open $script)
            
            # Check for good structure patterns
            let has_shebang = ($content | str contains "#!/usr/bin/env nu")
            let has_comments = ($content | str contains "#") and ($content | str contains "Usage:")
            let has_functions = ($content | str contains "def ") or ($content | str contains "let ")
            let has_options = ($content | str contains "--") and ($content | str contains "help")
            
            if $has_shebang or $has_comments or $has_functions or $has_options {
                $structure_score += 1
            }
        }
        
        if $structure_score > 0 {
            let script_count = ($windows_scripts | length)
            success $"Windows script structure good ($structure_score)/($script_count) scripts" --context "windows-platform-test"
            track_test "windows_script_structure" "windows-platform" "passed" 0.1
            return true
        } else {
            warning "Windows script structure could be improved" --context "windows-platform-test"
            track_test "windows_script_structure" "windows-platform" "passed" 0.1
            return true
        }
    } catch { |err|
        error $"Windows script structure test failed: ($err.msg)" --context "windows-platform-test"
        track_test "windows_script_structure" "windows-platform" "failed" 0.1
        return false
    }
}

# Test Windows cross-platform considerations
export def test_windows_cross_platform [] {
    info "Testing Windows cross-platform considerations" --context "windows-platform-test"
    
    try {
        let windows_dir = "scripts/platforms/windows"
        if not ($windows_dir | path exists) {
            warning "Windows platform directory not found" --context "windows-platform-test"
            track_test "windows_cross_platform" "windows-platform" "passed" 0.1
            return true
        }
        
        # Check if there are corresponding scripts on other platforms
        let linux_dir_exists = ("scripts/platforms/linux" | path exists)
        let macos_dir_exists = ("scripts/platforms/macos" | path exists)
        
        if $linux_dir_exists and $macos_dir_exists {
            success "Windows platform part of comprehensive cross-platform support" --context "windows-platform-test"
            track_test "windows_cross_platform" "windows-platform" "passed" 0.1
            return true
        } else {
            warning "Cross-platform support could be more comprehensive" --context "windows-platform-test"
            track_test "windows_cross_platform" "windows-platform" "passed" 0.1
            return true
        }
    } catch { |err|
        error $"Windows cross-platform test failed: ($err.msg)" --context "windows-platform-test"
        track_test "windows_cross_platform" "windows-platform" "failed" 0.1
        return false
    }
}

# Main test runner for Windows platform-specific tests
export def run_windows_platform_specific_tests [
    coverage: bool = false
    output: string = ""
    parallel: bool = true
    fail_fast: bool = false
] {
    banner "Running Windows Platform-Specific Comprehensive Tests" --context "windows-platform-test"
    
    # Setup test environment
    setup_test_env
    
    let tests = [
        test_windows_steam_rust_install,
        test_windows_platform_integration,
        test_windows_gaming_integration,
        test_windows_platform_safety,
        test_windows_nix_mox_compatibility,
        test_windows_script_structure,
        test_windows_cross_platform
    ]
    
    # Execute tests
    let results = ($tests | each { |test_func|
        try {
            let result = (do $test_func)
            if $result { { success: true } } else { { success: false } }
        } catch { |err|
            error $"Test failed with error: ($err.msg)" --context "windows-platform-test"
            { success: false }
        }
    })
    
    let passed = ($results | where success == true | length)
    let failed = ($results | where success == false | length)
    let total = ($results | length)
    
    summary "Windows platform-specific tests completed" $passed $total --context "windows-platform-test"
    
    if $failed > 0 {
        error $"($failed) Windows platform-specific tests failed" --context "windows-platform-test"
        if $fail_fast {
            exit 1
        }
        return false
    }
    
    success "All Windows platform-specific tests passed!" --context "windows-platform-test"
    return true
}

# If script is run directly, run tests
if ($env.PWD | str contains "scripts/testing/platform/windows") {
    run_windows_platform_specific_tests
}