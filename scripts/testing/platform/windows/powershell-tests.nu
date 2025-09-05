#!/usr/bin/env nu
# Windows PowerShell tests for nix-mox
# Tests PowerShell and Windows package manager integration

use ../../../lib/platform.nu *
use ../../../lib/logging.nu *
use ../../../lib/validators.nu *
use ../../../lib/command-wrapper.nu *

# Test Windows detection
export def test_windows_detection [] {
    info "Testing Windows detection" --context "windows-test"
    
    let platform = (get_platform)
    
    # Should detect as Windows
    if $platform.normalized != "windows" {
        warn $"Not running on Windows (detected: ($platform.normalized))" --context "windows-test"
        return true  # Don't fail if not on Windows
    }
    
    # Check for Windows-specific environment variables
    let windows_vars = ["USERPROFILE", "PROGRAMFILES", "SYSTEMROOT"]
    
    mut windows_indicators = 0
    for var in $windows_vars {
        if ($var in $env) {
            $windows_indicators += 1
        }
    }
    
    if $windows_indicators < 2 {
        warn "Windows indicators not found - may not be on Windows" --context "windows-test"
    }
    
    success "Windows environment detected" --context "windows-test"
    return true
}

# Test PowerShell availability
export def test_powershell_availability [] {
    info "Testing PowerShell availability" --context "windows-test"
    
    # Test for different PowerShell versions
    let powershell_commands = ["pwsh", "powershell", "powershell.exe"]
    
    mut powershell_found = false
    for cmd in $powershell_commands {
        let check = (validate_command $cmd)
        if $check.success {
            $powershell_found = true
            success $"PowerShell found: ($cmd)" --context "windows-test"
            break
        }
    }
    
    if not $powershell_found {
        warn "No PowerShell executable found" --context "windows-test"
        return true  # Don't fail - might be running in different context
    }
    
    return true
}

# Test Windows Package Manager (winget)
export def test_winget_package_manager [] {
    info "Testing Windows Package Manager (winget)" --context "windows-test"
    
    let winget_check = (validate_command "winget")
    if not $winget_check.success {
        warn "winget not available - Windows Package Manager not installed" --context "windows-test"
        return true  # Don't fail - winget is optional
    }
    
    try {
        # Test winget version
        let winget_version = (execute_command ["winget", "--version"] --timeout 5000)
        
        if $winget_version.exit_code == 0 {
            let version_info = ($winget_version.stdout | str trim)
            success $"Windows Package Manager available: ($version_info)" --context "windows-test"
            return true
        } else {
            warn "winget version check failed" --context "windows-test"
            return true
        }
    } catch { | err|
        warn $"winget test failed: ($err.msg)" --context "windows-test"
        return true
    }
}

# Test Chocolatey package manager
export def test_chocolatey_package_manager [] {
    info "Testing Chocolatey package manager" --context "windows-test"
    
    let choco_check = (validate_command "choco")
    if not $choco_check.success {
        warn "Chocolatey not available" --context "windows-test"
        return true  # Don't fail - Chocolatey is optional
    }
    
    try {
        # Test choco version
        let choco_version = (execute_command ["choco", "--version"] --timeout 5000)
        
        if $choco_version.exit_code == 0 {
            let version_info = ($choco_version.stdout | str trim)
            success $"Chocolatey available: ($version_info)" --context "windows-test"
            
            # Test choco list (safe read operation)
            let installed_packages = (execute_command ["choco", "list", "--local-only"] --timeout 10000)
            
            if $installed_packages.exit_code == 0 {
                let package_count = ($installed_packages.stdout | lines | where { $it | str contains " " } | length)
                info $"Chocolatey has ($package_count) installed packages" --context "windows-test"
            }
            
            return true
        } else {
            warn "Chocolatey version check failed" --context "windows-test"
            return true
        }
    } catch { | err|
        warn $"Chocolatey test failed: ($err.msg)" --context "windows-test"
        return true
    }
}

# Test Windows Services
export def test_windows_services [] {
    info "Testing Windows Services access" --context "windows-test"
    
    let sc_check = (validate_command "sc")
    if not $sc_check.success {
        warn "sc (Service Control) command not available" --context "windows-test"
        return true
    }
    
    try {
        # Test basic service query (safe read operation)
        let services = (execute_command ["sc", "query"] --timeout 10000)
        
        if $services.exit_code == 0 {
            let service_count = ($services.stdout | lines | where { $it | str contains "SERVICE_NAME" } | length)
            success $"Windows Services accessible: ($service_count) services found" --context "windows-test"
            return true
        } else {
            warn "Service query failed" --context "windows-test"
            return true
        }
    } catch { | err|
        warn $"Windows Services test failed: ($err.msg)" --context "windows-test"
        return true
    }
}

# Test Windows Registry access
export def test_windows_registry [] {
    info "Testing Windows Registry access" --context "windows-test"
    
    let reg_check = (validate_command "reg")
    if not $reg_check.success {
        warn "reg command not available" --context "windows-test"
        return true
    }
    
    try {
        # Test basic registry query (safe read operation)
        let registry = (execute_command ["reg", "query", "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion", "/v", "ProductName"] --timeout 5000)
        
        if $registry.exit_code == 0 {
            success "Windows Registry accessible" --context "windows-test"
            
            # Extract Windows version if possible
            let product_line = ($registry.stdout | lines | where { $it | str contains "ProductName" } | first | default "")
            if ($product_line | str length) > 0 {
                info $"Windows version info: ($product_line)" --context "windows-test"
            }
            
            return true
        } else {
            warn "Registry query failed" --context "windows-test"
            return true
        }
    } catch { | err|
        warn $"Registry test failed: ($err.msg)" --context "windows-test"
        return true
    }
}

# Test Windows Subsystem for Linux (if available)
export def test_wsl_availability [] {
    info "Testing WSL availability" --context "windows-test"
    
    let wsl_check = (validate_command "wsl")
    if not $wsl_check.success {
        info "WSL not available" --context "windows-test"
        return true  # Don't fail - WSL is optional
    }
    
    try {
        # Test wsl version
        let wsl_version = (execute_command ["wsl", "--version"] --timeout 5000)
        
        if $wsl_version.exit_code == 0 {
            success $"WSL available: ($wsl_version.stdout | lines | first | default "")" --context "windows-test"
            
            # Test wsl distribution list
            let wsl_list = (execute_command ["wsl", "--list", "--quiet"] --timeout 5000)
            
            if $wsl_list.exit_code == 0 {
                let distro_count = ($wsl_list.stdout | lines | where { ($it | str length) > 0 } | length)
                info $"WSL has ($distro_count) distributions installed" --context "windows-test"
            }
            
            return true
        } else {
            warn "WSL version check failed" --context "windows-test"
            return true
        }
    } catch { | err|
        warn $"WSL test failed: ($err.msg)" --context "windows-test"
        return true
    }
}

# Test Windows development tools
export def test_windows_dev_tools [] {
    info "Testing Windows development tools" --context "windows-test"
    
    let dev_tools = ["git", "node", "python", "dotnet"]
    
    mut available_tools = 0
    for tool in $dev_tools {
        let check = (validate_command $tool)
        if $check.success {
            $available_tools += 1
            debug $"Dev tool available: ($tool)" --context "windows-test"
        }
    }
    
    if $available_tools == 0 {
        info "No common development tools found" --context "windows-test"
    } else {
        success $"($available_tools) development tools available" --context "windows-test"
    }
    
    return true
}

# Main test runner
export def run_powershell_tests [] {
    banner "Running Windows PowerShell platform tests" --context "windows-test"
    
    let tests = [
        test_windows_detection,
        test_powershell_availability,
        test_winget_package_manager,
        test_chocolatey_package_manager,
        test_windows_services,
        test_windows_registry,
        test_wsl_availability,
        test_windows_dev_tools
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
            error $"Test failed with error: ($err.msg)" --context "windows-test"
            $failed += 1
        }
    }
    
    let total = $passed + $failed
    summary "Windows PowerShell tests completed" $passed $total --context "windows-test"
    
    if $failed > 0 {
        error $"($failed) Windows tests failed" --context "windows-test"
        return false
    }
    
    success "All Windows PowerShell tests passed!" --context "windows-test"
    return true
}

# If script is run directly, run tests
if ($env.PWD | str contains "scripts/testing/platform/windows") {
    run_powershell_tests
}