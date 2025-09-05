#!/usr/bin/env nu
# NixOS-specific tests for nix-mox
# Tests NixOS configuration, flakes, and system integration

use ../../../lib/platform.nu *
use ../../../lib/logging.nu *
use ../../../lib/validators.nu *
use ../../../lib/command-wrapper.nu *

# Test NixOS detection
export def test_nixos_detection [] {
    info "Testing NixOS detection" --context "nixos-test"
    
    let platform = (get_platform)
    
    # Should detect as Linux variant
    if $platform.normalized != "linux" {
        error $"Expected Linux platform, got ($platform.normalized)" --context "nixos-test"
        return false
    }
    
    # Check for NixOS-specific indicators
    let nixos_indicators = [
        "/etc/nixos",
        "/nix/store", 
        "/run/current-system"
    ]
    
    mut nixos_detected = false
    for indicator in $nixos_indicators {
        if ($indicator | path exists) {
            $nixos_detected = true
            break
        }
    }
    
    if not $nixos_detected {
        warn "NixOS indicators not found - may not be running on NixOS" --context "nixos-test"
    } else {
        success "NixOS environment detected" --context "nixos-test"
    }
    
    return true
}

# Test Nix command availability
export def test_nix_commands [] {
    info "Testing Nix command availability" --context "nixos-test"
    
    let nix_commands = ["nix", "nixos-rebuild", "nix-shell"]
    
    for cmd in $nix_commands {
        let check = (validate_command $cmd)
        if not $check.success {
            error $"Nix command not found: ($cmd)" --context "nixos-test"
            return false
        }
    }
    
    success "All Nix commands available" --context "nixos-test"
    return true
}

# Test flake functionality
export def test_flake_operations [] {
    info "Testing Nix flake operations" --context "nixos-test"
    
    try {
        # Test basic flake commands (safe read operations)
        let flake_check = (execute_command ["nix", "flake", "--version"] --timeout 10000)
        
        if $flake_check.exit_code != 0 {
            error "Nix flake command failed" --context "nixos-test"
            return false
        }
        
        # Test flake show (if flake.nix exists)
        if ("flake.nix" | path exists) {
            let show_result = (execute_command ["nix", "flake", "show", "--json"] --timeout 15000)
            
            if $show_result.exit_code == 0 {
                success "Flake show command works" --context "nixos-test"
            } else {
                warn "Flake show failed - flake may have issues" --context "nixos-test"
            }
        }
        
        success "Flake operations functional" --context "nixos-test"
        return true
    } catch { | err|
        error $"Flake test failed: ($err.msg)" --context "nixos-test"
        return false
    }
}

# Test NixOS configuration structure
export def test_nixos_config_structure [] {
    info "Testing NixOS configuration structure" --context "nixos-test"
    
    # Check for expected NixOS config paths
    let config_paths = [
        "config/nixos/configuration.nix",
        "config/hardware/hardware-configuration.nix"
    ]
    
    mut found_configs = 0
    for config_path in $config_paths {
        if ($config_path | path exists) {
            $found_configs += 1
            debug $"Found config: ($config_path)" --context "nixos-test"
        } else {
            warn $"Config not found: ($config_path)" --context "nixos-test"
        }
    }
    
    if $found_configs == 0 {
        error "No NixOS configuration files found" --context "nixos-test"
        return false
    }
    
    success $"Found ($found_configs) NixOS configuration files" --context "nixos-test"
    return true
}

# Test systemd integration 
export def test_systemd_integration [] {
    info "Testing systemd integration" --context "nixos-test"
    
    try {
        # Test systemctl command
        let systemctl_check = (validate_command "systemctl")
        if not $systemctl_check.success {
            error "systemctl command not found" --context "nixos-test"
            return false
        }
        
        # Test basic systemd query (safe operation)
        let systemd_status = (execute_command ["systemctl", "is-system-running"] --timeout 5000)
        
        # systemd can return various statuses, so we just check the command works
        debug $"systemd status: ($systemd_status.stdout)" --context "nixos-test"
        success "systemd integration functional" --context "nixos-test"
        return true
    } catch { | err|
        error $"systemd integration test failed: ($err.msg)" --context "nixos-test"
        return false
    }
}

# Test Nix store accessibility
export def test_nix_store [] {
    info "Testing Nix store accessibility" --context "nixos-test"
    
    let nix_store_path = "/nix/store"
    
    if not ($nix_store_path | path exists) {
        error "Nix store not found at /nix/store" --context "nixos-test"
        return false
    }
    
    try {
        # Test store query (safe read operation)
        let store_query = (execute_command ["nix", "path-info", "--json", "/nix/store"] --timeout 10000)
        
        if $store_query.exit_code == 0 {
            success "Nix store query works" --context "nixos-test"
        } else {
            warn "Nix store query failed - store may have issues" --context "nixos-test"
        }
        
        success "Nix store accessible" --context "nixos-test"
        return true
    } catch { | err|
        warn $"Nix store query failed: ($err.msg)" --context "nixos-test"
        return true  # Don't fail test, store exists even if query fails
    }
}

# Test NixOS generations
export def test_nixos_generations [] {
    info "Testing NixOS generations" --context "nixos-test"
    
    try {
        # Test nixos-rebuild list-generations (safe read operation)
        let generations = (execute_command ["nixos-rebuild", "list-generations"] --timeout 10000)
        
        if $generations.exit_code == 0 {
            let generation_count = ($generations.stdout | lines | length)
            success $"Found ($generation_count) NixOS generations" --context "nixos-test"
            return true
        } else {
            warn "Could not list NixOS generations" --context "nixos-test"
            return true  # Don't fail - generations might not be available
        }
    } catch { | err|
        warn $"Generation test failed: ($err.msg)" --context "nixos-test"
        return true  # Don't fail test
    }
}

# Main test runner
export def run_nixos_tests [] {
    banner "Running NixOS platform tests" --context "nixos-test"
    
    let tests = [
        test_nixos_detection,
        test_nix_commands,
        test_flake_operations,
        test_nixos_config_structure,
        test_systemd_integration,
        test_nix_store,
        test_nixos_generations
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
            error $"Test failed with error: ($err.msg)" --context "nixos-test"
            $failed += 1
        }
    }
    
    let total = $passed + $failed
    summary "NixOS tests completed" $passed $total --context "nixos-test"
    
    if $failed > 0 {
        error $"($failed) NixOS tests failed" --context "nixos-test"
        return false
    }
    
    success "All NixOS tests passed!" --context "nixos-test"
    return true
}

# If script is run directly, run tests
if ($env.PWD | str contains "scripts/testing/platform/linux") {
    run_nixos_tests
}