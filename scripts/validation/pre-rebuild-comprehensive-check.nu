#!/usr/bin/env nu

# Import unified libraries
use ../lib/validators.nu
use ../lib/logging.nu


# Comprehensive Pre-Rebuild Safety Check
# Run this BEFORE any nixos-rebuild to prevent system breakage
# Covers: boot, display, storage, and configuration validation

use ../lib/logging.nu *
use ../lib/platform.nu *

def main [
    --verbose: bool = false  # Show detailed output
    --force: bool = false    # Skip non-critical warnings
] {
    print_header "Comprehensive Pre-Rebuild Safety Check"
    print_warning "This will validate your configuration before rebuild..."
    print ""
    
    # Run all validation checks
    let validations = [
        {
            name: "Configuration Syntax"
            script: "validate-config-syntax"
            critical: true
        }
        {
            name: "Display Safety"
            script: "validate-display-safety"
            critical: true
        }
        {
            name: "Storage Configuration"
            script: "validate-storage-config"
            critical: true
        }
        {
            name: "Gaming Setup"
            script: "validate-gaming-setup"
            critical: false
        }
        {
            name: "Network Configuration"
            script: "validate-network-config"
            critical: false
        }
    ]
    
    let results = ($validations | each {|validation|
        print $"\n(ansi blue)▶ Running ($validation.name) validation...(ansi reset)"
        
        let result = (run_validation $validation.script $verbose)
        
        {
            name: $validation.name
            critical: $validation.critical
            success: $result.success
            message: $result.message
            details: $result.details
        }
    })
    
    # Print summary
    print_summary $results
    
    # Determine overall status
    let critical_failures = ($results | where critical == true | where success == false)
    let warnings = ($results | where critical == false | where success == false)
    
    if (($critical_failures | length) > 0) {
        print ""
        print_error "❌ CRITICAL FAILURES DETECTED!"
        print_error "DO NOT PROCEED WITH REBUILD!"
        print ""
        print "Critical issues:"
        $critical_failures | each {|failure|
            print $"  • ($failure.name): ($failure.message)"
        }
        print ""
        print_error "Fix these issues before running nixos-rebuild"
        exit 1
    } else if ((($warnings | length) > 0) and (not $force)) {
        print ""
        print_warning "⚠️  Non-critical warnings detected:"
        $warnings | each {|warning|
            print $"  • ($warning.name): ($warning.message)"
        }
        print ""
        print "You can proceed with rebuild, but review these warnings."
        print "Use --force to skip this prompt."
        
        let response = (input "Continue with rebuild? (y/N): ")
        if ($response | str downcase) != "y" {
            print "Rebuild cancelled."
            exit 1
        }
    } else {
        print ""
        print_success "✅ All safety checks passed!"
        print_success "System is ready for nixos-rebuild"
        
        # Provide the rebuild command
        print ""
        print "You can now safely run:"
        print $"  (ansi green)sudo nixos-rebuild switch --flake .#nixos(ansi reset)"
        print ""
        print "Or for testing first:"
        print $"  (ansi yellow)sudo nixos-rebuild test --flake .#nixos(ansi reset)"
    }
}

# Run a validation script
def run_validation [script: string, verbose: bool] {
    let script_path = $"scripts/validation/($script).nu"
    
    # Check if script exists
    if not ($script_path | path exists) {
        # Try running built-in validations
        match $script {
            "validate-config-syntax" => { validate_config_syntax $verbose }
            "validate-display-safety" => { validate_display_safety_inline $verbose }
            "validate-storage-config" => { validate_storage_config_inline $verbose }
            "validate-gaming-setup" => { validate_gaming_setup_inline $verbose }
            "validate-network-config" => { validate_network_config_inline $verbose }
            _ => {
                {
                    success: false
                    message: $"Validation script not found: ($script_path)"
                    details: null
                }
            }
        }
    } else {
        # Run external validation script
        let result = (^nu $script_path | complete)
        
        {
            success: ($result.exit_code == 0)
            message: if ($result.exit_code == 0) { "Passed" } else { "Failed" }
            details: if $verbose { $result.stdout } else { null }
        }
    }
}

# Inline configuration syntax validation
def validate_config_syntax [verbose: bool] {
    try {
        if $verbose { print "  Checking configuration syntax..." }
        
        let result = (
            INCLUDE_NIXOS_CONFIGS=1 ^nix eval .#nixosConfigurations.nixos.config.system.build.toplevel.drvPath
            | complete
        )
        
        if ($result.exit_code == 0) {
            {
                success: true
                message: "Configuration syntax is valid"
                details: if $verbose { $result.stdout } else { null }
            }
        } else {
            {
                success: false
                message: "Configuration has syntax errors"
                details: $result.stderr
            }
        }
    } catch {
        {
            success: false
            message: "Failed to validate configuration syntax"
            details: null
        }
    }
}

# Inline display safety validation
def validate_display_safety_inline [verbose: bool] {
    try {
        if $verbose { print "  Checking display manager configuration..." }
        
        # Check for display manager
        let dm_result = (
            INCLUDE_NIXOS_CONFIGS=1 ^nix eval .#nixosConfigurations.nixos.config.services.xserver.displayManager.sddm.enable --json
            | complete
        )
        
        # Check for X server
        let x_result = (
            INCLUDE_NIXOS_CONFIGS=1 ^nix eval .#nixosConfigurations.nixos.config.services.xserver.enable --json
            | complete
        )
        
        # Check video drivers
        let driver_result = (
            INCLUDE_NIXOS_CONFIGS=1 ^nix eval .#nixosConfigurations.nixos.config.services.xserver.videoDrivers --json
            | complete
        )
        
        let dm_enabled = if ($dm_result.exit_code == 0) { ($dm_result.stdout | from json) } else { false }
        let x_enabled = if ($x_result.exit_code == 0) { ($x_result.stdout | from json) } else { false }
        let drivers = if ($driver_result.exit_code == 0) { ($driver_result.stdout | from json) } else { [] }
        
        let has_display = ($dm_enabled or $x_enabled)
        let has_drivers = (($drivers | length) > 0)
        
        if ($has_display and $has_drivers) {
            {
                success: true
                message: "Display configuration is valid"
                details: if $verbose { $"Display manager: ($dm_enabled), X11: ($x_enabled), Drivers: ($drivers | str join ', ')" } else { null }
            }
        } else if (not $has_display) {
            {
                success: false
                message: "No display manager or X server enabled!"
                details: "System may boot to console only"
            }
        } else {
            {
                success: false
                message: "No video drivers configured!"
                details: "Display may not work properly"
            }
        }
    } catch {
        {
            success: false
            message: "Failed to validate display configuration"
            details: null
        }
    }
}

# Inline storage configuration validation
def validate_storage_config_inline [verbose: bool] {
    try {
        if $verbose { print "  Checking storage configuration..." }
        
        # Check root filesystem
        let root_result = (
            INCLUDE_NIXOS_CONFIGS=1 ^nix eval .#nixosConfigurations.nixos.config.fileSystems."/".device
            | complete
        )
        
        # Check boot filesystem
        let boot_result = (
            INCLUDE_NIXOS_CONFIGS=1 ^nix eval .#nixosConfigurations.nixos.config.fileSystems."/boot".device
            | complete
        )
        
        let root_device = if ($root_result.exit_code == 0) { $root_result.stdout } else { "unknown" }
        let boot_device = if ($boot_result.exit_code == 0) { $boot_result.stdout } else { "unknown" }
        
        # Check for placeholder UUIDs
        let has_placeholder = (
            ($root_device | str contains "YOUR-ROOT-UUID") or
            ($boot_device | str contains "YOUR-BOOT-UUID")
        )
        
        if $has_placeholder {
            {
                success: false
                message: "Storage configuration has placeholder UUIDs!"
                details: "Run nixos-generate-config to get proper UUIDs"
            }
        } else if (($root_device == "unknown") or ($boot_device == "unknown")) {
            {
                success: false
                message: "Could not validate storage configuration"
                details: null
            }
        } else {
            {
                success: true
                message: "Storage configuration looks valid"
                details: if $verbose { $"Root: ($root_device), Boot: ($boot_device)" } else { null }
            }
        }
    } catch {
        {
            success: false
            message: "Failed to validate storage configuration"
            details: null
        }
    }
}

# Inline gaming setup validation
def validate_gaming_setup_inline [verbose: bool] {
    try {
        if $verbose { print "  Checking gaming configuration..." }
        
        let gaming_result = (
            INCLUDE_NIXOS_CONFIGS=1 ^nix eval .#nixosConfigurations.nixos.config.services.gaming.enable --json
            | complete
        )
        
        let steam_result = (
            INCLUDE_NIXOS_CONFIGS=1 ^nix eval .#nixosConfigurations.nixos.config.programs.steam.enable --json
            | complete
        )
        
        let gaming_enabled = if ($gaming_result.exit_code == 0) { ($gaming_result.stdout | from json) } else { false }
        let steam_enabled = if ($steam_result.exit_code == 0) { ($steam_result.stdout | from json) } else { false }
        
        {
            success: true
            message: if ($gaming_enabled or $steam_enabled) { "Gaming support enabled" } else { "Gaming not configured" }
            details: if $verbose { $"Gaming service: ($gaming_enabled), Steam: ($steam_enabled)" } else { null }
        }
    } catch {
        {
            success: true  # Gaming is optional
            message: "Gaming configuration not checked"
            details: null
        }
    }
}

# Inline network configuration validation
def validate_network_config_inline [verbose: bool] {
    try {
        if $verbose { print "  Checking network configuration..." }
        
        let nm_result = (
            INCLUDE_NIXOS_CONFIGS=1 ^nix eval .#nixosConfigurations.nixos.config.networking.networkmanager.enable --json
            | complete
        )
        
        let dhcp_result = (
            INCLUDE_NIXOS_CONFIGS=1 ^nix eval .#nixosConfigurations.nixos.config.networking.useDHCP --json
            | complete
        )
        
        let nm_enabled = if ($nm_result.exit_code == 0) { ($nm_result.stdout | from json) } else { false }
        let dhcp_enabled = if ($dhcp_result.exit_code == 0) { ($dhcp_result.stdout | from json) } else { false }
        
        {
            success: true
            message: if ($nm_enabled or $dhcp_enabled) { "Network configured" } else { "Manual network configuration" }
            details: if $verbose { $"NetworkManager: ($nm_enabled), DHCP: ($dhcp_enabled)" } else { null }
        }
    } catch {
        {
            success: true  # Network is optional for basic boot
            message: "Network configuration not checked"
            details: null
        }
    }
}

# Print summary of validation results
def print_summary [results: list] {
    print ""
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print "            VALIDATION SUMMARY"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print ""
    
    $results | each {|result|
        let status = if $result.success {
            "(ansi green)✅ PASS(ansi reset)"
        } else if $result.critical {
            "(ansi red)❌ FAIL(ansi reset)"
        } else {
            "(ansi yellow)⚠️  WARN(ansi reset)"
        }
        
        let critical_tag = if $result.critical { " (ansi red)[CRITICAL](ansi reset)" } else { "" }
        
        print $"  ($status) ($result.name)($critical_tag)"
        
        if (not $result.success and ($result.details | is-not-empty)) {
            print $"      → ($result.details)"
        }
    }
    
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Helper functions
def print_header [title: string] {
    print $"(ansi blue)🛡️  ($title)(ansi reset)"
    print $"(ansi blue)════════════════════════════════════════(ansi reset)\n"
}

def print_info [message: string] {
    print $"(ansi cyan)ℹ️  ($message)(ansi reset)"
}

def print_success [message: string] {
    print $"(ansi green)($message)(ansi reset)"
}

def print_error [message: string] {
    print $"(ansi red)($message)(ansi reset)"
}

def print_warning [message: string] {
    print $"(ansi yellow)($message)(ansi reset)"
}

# Run main if called directly
if $env.FILE_PWD == (which $env.CURRENT_FILE | get path | first) {
    main
}