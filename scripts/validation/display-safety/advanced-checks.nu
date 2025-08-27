#!/usr/bin/env nu
# Advanced display safety validation checks
# Extracted from scripts/validation/validate-display-safety.nu for better organization

use ../../lib/logging.nu *

# =============================================================================
# ADVANCED VALIDATION FUNCTIONS
# =============================================================================

# Validate Wayland configuration
export def validate_wayland_config [] {
    info "Checking Wayland configuration..." --context "display-safety"
    
    let checks = []
    
    # Check if Wayland is enabled for GDM
    let gdm_wayland_check = (try {
        let result = (
            INCLUDE_NIXOS_CONFIGS=1 ^nix eval .#nixosConfigurations.nixos.config.services.xserver.displayManager.gdm.wayland --json
            | complete
        )
        
        if $result.exit_code == 0 {
            let enabled = ($result.stdout | from json)
            {
                name: "GDM Wayland"
                success: true
                message: if $enabled { "Wayland enabled for GDM" } else { "Wayland disabled for GDM" }
            }
        } else {
            {
                name: "GDM Wayland"
                success: true
                message: "GDM not configured"
            }
        }
    } catch {
        {
            name: "GDM Wayland"
            success: true
            message: "GDM not configured"
        }
    })
    
    let checks = ($checks | append $gdm_wayland_check)
    
    # Check for Wayland session availability
    let wayland_session_check = {
        name: "Wayland Sessions"
        success: true
        message: "Wayland sessions depend on desktop environment"
    }
    
    let checks = ($checks | append $wayland_session_check)
    
    {
        success: true  # Wayland is optional
        checks: $checks
    }
}

# Validate GPU drivers are properly configured
export def validate_gpu_drivers [] {
    info "Validating GPU driver configuration..." --context "display-safety"
    
    let checks = []
    
    # Check NVIDIA configuration
    let nvidia_check = (try {
        let nvidia_enable = (
            INCLUDE_NIXOS_CONFIGS=1 ^nix eval .#nixosConfigurations.nixos.config.hardware.nvidia.modesetting.enable --json
            | complete
        )
        
        let blacklist = (
            INCLUDE_NIXOS_CONFIGS=1 ^nix eval .#nixosConfigurations.nixos.config.boot.blacklistedKernelModules --json
            | complete
        )
        
        if $nvidia_enable.exit_code == 0 {
            let modesetting = ($nvidia_enable.stdout | from json)
            let blacklisted = if ($blacklist.exit_code == 0) { ($blacklist.stdout | from json) } else { [] }
            let nouveau_blacklisted = ("nouveau" in $blacklisted)
            
            {
                name: "NVIDIA Configuration"
                success: true
                message: $"NVIDIA modesetting: ($modesetting), nouveau blacklisted: ($nouveau_blacklisted)"
                warning: if (not $nouveau_blacklisted) { "nouveau not blacklisted - may conflict with nvidia" } else { null }
            }
        } else {
            {
                name: "NVIDIA Configuration"
                success: true
                message: "NVIDIA not configured"
            }
        }
    } catch {
        {
            name: "NVIDIA Configuration"
            success: true
            message: "NVIDIA configuration not checked"
        }
    })
    
    let checks = ($checks | append $nvidia_check)
    
    # Check graphics hardware support
    let graphics_check = (try {
        let result = (
            INCLUDE_NIXOS_CONFIGS=1 ^nix eval .#nixosConfigurations.nixos.config.hardware.graphics.enable --json
            | complete
        )
        
        if $result.exit_code == 0 {
            let enabled = ($result.stdout | from json)
            {
                name: "Graphics Hardware"
                success: $enabled
                message: if $enabled { "Graphics hardware support enabled" } else { "WARNING: Graphics hardware support disabled!" }
            }
        } else {
            {
                name: "Graphics Hardware"
                success: false
                message: "Failed to check graphics hardware configuration"
            }
        }
    } catch {
        {
            name: "Graphics Hardware"
            success: false
            message: "Error checking graphics hardware"
        }
    })
    
    let checks = ($checks | append $graphics_check)
    
    {
        success: ($checks | all {|c| $c.success})
        checks: $checks
        critical: true  # GPU driver issues are critical
    }
}

# Validate display dependencies
export def validate_display_dependencies [] {
    info "Checking display dependencies..." --context "display-safety"
    
    let checks = []
    
    # Check for required packages
    let packages_check = (try {
        let result = (
            INCLUDE_NIXOS_CONFIGS=1 ^nix eval .#nixosConfigurations.nixos.config.environment.systemPackages --apply 'builtins.map (p: p.name or "unknown")'
            | complete
        )
        
        if $result.exit_code == 0 {
            {
                name: "System Packages"
                success: true
                message: "System packages configured"
            }
        } else {
            {
                name: "System Packages"
                success: false
                message: "Failed to evaluate system packages"
            }
        }
    } catch {
        {
            name: "System Packages"
            success: false
            message: "Error checking system packages"
        }
    })
    
    let checks = ($checks | append $packages_check)
    
    {
        success: ($checks | all {|c| $c.success})
        checks: $checks
    }
}

# Validate configuration syntax
export def validate_config_syntax [] {
    info "Validating configuration syntax..." --context "display-safety"
    
    let checks = []
    
    # Try to evaluate the full configuration
    let syntax_check = (try {
        print "  Testing full configuration evaluation..."
        let result = (
            INCLUDE_NIXOS_CONFIGS=1 ^nix eval .#nixosConfigurations.nixos.config.system.build.toplevel.drvPath
            | complete
        )
        
        {
            name: "Configuration Syntax"
            success: ($result.exit_code == 0)
            message: if ($result.exit_code == 0) {
                "Configuration syntax is valid"
            } else {
                "Configuration has syntax errors!"
            }
            error: if ($result.exit_code != 0) { $result.stderr } else { null }
        }
    } catch {
        {
            name: "Configuration Syntax"
            success: false
            message: "Failed to validate configuration syntax"
        }
    })
    
    let checks = ($checks | append $syntax_check)
    
    {
        success: ($checks | all {|c| $c.success})
        checks: $checks
        critical: true  # Syntax errors are critical
    }
}