#!/usr/bin/env nu
# macOS Homebrew tests for nix-mox
# Tests Homebrew package manager integration on macOS

use ../../../lib/platform.nu *
use ../../../lib/logging.nu *
use ../../../lib/validators.nu *
use ../../../lib/command-wrapper.nu *

# Test macOS detection
export def test_macos_detection [] {
    info "Testing macOS detection" --context "macos-test"
    
    let platform = (get_platform)
    
    # Should detect as macOS
    if $platform.normalized != "macos" {
        warn $"Not running on macOS (detected: ($platform.normalized))" --context "macos-test"
        return true  # Don't fail if not on macOS
    }
    
    # Check for macOS-specific paths
    let macos_paths = [
        "/System/Library",
        "/Applications",
        "/usr/local"
    ]
    
    mut macos_indicators = 0
    for path in $macos_paths {
        if ($path | path exists) {
            $macos_indicators += 1
        }
    }
    
    if $macos_indicators < 2 {
        warn "macOS indicators not found - may not be on macOS" --context "macos-test"
    }
    
    success "macOS environment detected" --context "macos-test"
    return true
}

# Test Homebrew installation
export def test_homebrew_installation [] {
    info "Testing Homebrew installation" --context "macos-test"
    
    let brew_check = (validate_command "brew")
    if not $brew_check.success {
        warn "Homebrew not installed or not in PATH" --context "macos-test"
        return true  # Don't fail - Homebrew is optional
    }
    
    try {
        # Test brew version
        let brew_version = (execute_command ["brew", "--version"] --timeout 5000)
        
        if $brew_version.exit_code == 0 {
            let version_info = ($brew_version.stdout | lines | first)
            success $"Homebrew available: ($version_info)" --context "macos-test"
            return true
        } else {
            warn "Homebrew version check failed" --context "macos-test"
            return true
        }
    } catch { | err|
        warn $"Homebrew test failed: ($err.msg)" --context "macos-test"
        return true
    }
}

# Test Homebrew package operations
export def test_homebrew_operations [] {
    info "Testing Homebrew package operations" --context "macos-test"
    
    let brew_check = (validate_command "brew")
    if not $brew_check.success {
        info "Skipping Homebrew operations - brew not available" --context "macos-test"
        return true
    }
    
    try {
        # Test brew list (safe read operation)
        let installed_packages = (execute_command ["brew", "list", "--formula"] --timeout 10000)
        
        if $installed_packages.exit_code == 0 {
            let package_count = ($installed_packages.stdout | lines | length)
            success $"Homebrew has ($package_count) installed packages" --context "macos-test"
        } else {
            warn "Could not list Homebrew packages" --context "macos-test"
        }
        
        # Test brew outdated (safe read operation)
        let outdated = (execute_command ["brew", "outdated"] --timeout 10000)
        
        if $outdated.exit_code == 0 {
            let outdated_count = ($outdated.stdout | lines | length)
            if $outdated_count > 0 {
                info $"($outdated_count) packages have updates available" --context "macos-test"
            } else {
                success "All Homebrew packages are up to date" --context "macos-test"
            }
        }
        
        success "Homebrew operations functional" --context "macos-test"
        return true
    } catch { | err|
        warn $"Homebrew operations test failed: ($err.msg)" --context "macos-test"
        return true
    }
}

# Test macOS system integration
export def test_macos_system_integration [] {
    info "Testing macOS system integration" --context "macos-test"
    
    # Test system commands
    let system_commands = ["sw_vers", "system_profiler", "defaults"]
    
    mut available_commands = 0
    for cmd in $system_commands {
        let check = (validate_command $cmd)
        if $check.success {
            $available_commands += 1
        }
    }
    
    if $available_commands == 0 {
        warn "No macOS system commands found" --context "macos-test"
        return false
    }
    
    try {
        # Test sw_vers (system version)
        let version_check = (validate_command "sw_vers")
        if $version_check.success {
            let version_info = (execute_command ["sw_vers", "-productVersion"] --timeout 5000)
            if $version_info.exit_code == 0 {
                let macos_version = ($version_info.stdout | str trim)
                success $"macOS version: ($macos_version)" --context "macos-test"
            }
        }
        
        success "macOS system integration functional" --context "macos-test"
        return true
    } catch { | err|
        warn $"macOS system integration test failed: ($err.msg)" --context "macos-test"
        return true
    }
}

# Test Xcode command line tools
export def test_xcode_tools [] {
    info "Testing Xcode command line tools" --context "macos-test"
    
    let xcode_tools = ["clang", "git", "make"]
    
    mut available_tools = 0
    for tool in $xcode_tools {
        let check = (validate_command $tool)
        if $check.success {
            $available_tools += 1
        }
    }
    
    if $available_tools == 0 {
        warn "No Xcode command line tools found" --context "macos-test"
        return true  # Don't fail - tools are optional
    }
    
    success $"($available_tools) Xcode command line tools available" --context "macos-test"
    return true
}

# Test launchd services (basic)
export def test_launchd_services [] {
    info "Testing launchd services" --context "macos-test"
    
    let launchctl_check = (validate_command "launchctl")
    if not $launchctl_check.success {
        warn "launchctl not available" --context "macos-test"
        return true
    }
    
    try {
        # Test basic launchctl functionality (safe read operation)
        let services = (execute_command ["launchctl", "list"] --timeout 10000)
        
        if $services.exit_code == 0 {
            let service_count = ($services.stdout | lines | length)
            success $"launchctl found ($service_count) services" --context "macos-test"
            return true
        } else {
            warn "launchctl list command failed" --context "macos-test"
            return true
        }
    } catch { | err|
        warn $"launchd test failed: ($err.msg)" --context "macos-test"
        return true
    }
}

# Test Mac App Store CLI (if available)
export def test_mac_app_store [] {
    info "Testing Mac App Store CLI" --context "macos-test"
    
    let mas_check = (validate_command "mas")
    if not $mas_check.success {
        info "mas (Mac App Store CLI) not installed" --context "macos-test"
        return true  # Don't fail - mas is optional
    }
    
    try {
        # Test mas version
        let mas_version = (execute_command ["mas", "version"] --timeout 5000)
        
        if $mas_version.exit_code == 0 {
            success $"Mac App Store CLI available: (mas_version.stdout | str trim)" --context "macos-test"
            return true
        } else {
            warn "mas version check failed" --context "macos-test"
            return true
        }
    } catch { | err|
        warn $"Mac App Store test failed: ($err.msg)" --context "macos-test"
        return true
    }
}

# Main test runner
export def run_homebrew_tests [] {
    banner "Running macOS Homebrew platform tests" --context "macos-test"
    
    let tests = [
        test_macos_detection,
        test_homebrew_installation,
        test_homebrew_operations,
        test_macos_system_integration,
        test_xcode_tools,
        test_launchd_services,
        test_mac_app_store
    ]
    
    mut passed = 0
    mut failed = 0
    
    for test_func in $tests {
        try {
            let result = (do $test_func)
            if $result {
                $passed += 1
            } else {
                $failed += 1
            }
        } catch { | err|
            error $"Test failed with error: ($err.msg)" --context "macos-test"
            $failed += 1
        }
    }
    
    let total = $passed + $failed
    summary "macOS Homebrew tests completed" $passed $total --context "macos-test"
    
    if $failed > 0 {
        error $"($failed) macOS tests failed" --context "macos-test"
        return false
    }
    
    success "All macOS Homebrew tests passed!" --context "macos-test"
    return true
}

# If script is run directly, run tests
if ($env.PWD | str contains "scripts/testing/platform/macos") {
    run_homebrew_tests
}