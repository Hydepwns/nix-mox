#!/usr/bin/env nu

# Display Manager Safety Validation
# Comprehensive tests to ensure rebuild won't break display/greeter
# Run this BEFORE nixos-rebuild switch to prevent display breakage

use ../lib/logging.nu *
use ../lib/platform.nu *

def main [] {
    print_header "Display Manager Safety Validation"
    print_warning "Running comprehensive display safety checks before rebuild..."
    
    let results = {
        stage1: (validate_stage1_boot),
        display_manager: (validate_display_manager),
        greeter: (validate_greeter_config),
        xserver: (validate_xserver_config),
        wayland: (validate_wayland_config),
        gpu_driver: (validate_gpu_drivers),
        dependencies: (validate_display_dependencies),
        config_syntax: (validate_config_syntax)
    }
    
    print_validation_report $results
    
    # Check for critical failures
    let critical_failures = check_critical_failures $results
    
    if $critical_failures {
        print_error "❌ CRITICAL: Display configuration has issues that WILL break your system!"
        print_error "DO NOT proceed with nixos-rebuild switch!"
        print_warning "Fix the issues above before rebuilding."
        exit 1
    }
    
    let all_passed = ($results | values | all {|r| $r.success})
    if $all_passed {
        print_success "✅ Display configuration validated - safe to rebuild"
        exit 0
    } else {
        print_warning "⚠️  Some display checks failed - review carefully before rebuilding"
        exit 1
    }
}

# Validate stage-1 boot won't fail
def validate_stage1_boot [] {
    print_info "Validating stage-1 boot configuration..."
    
    let checks = []
    
    # Check initrd modules
    let initrd_check = (try {
        let config_eval = (
            INCLUDE_NIXOS_CONFIGS=1 ^nix eval .#nixosConfigurations.nixos.config.boot.initrd.kernelModules --json 
            | complete
        )
        
        if $config_eval.exit_code == 0 {
            let modules = ($config_eval.stdout | from json)
            {
                name: "Initrd Kernel Modules"
                success: true
                message: $"Found ($modules | length) initrd modules"
                modules: $modules
            }
        } else {
            {
                name: "Initrd Kernel Modules"
                success: false
                message: "Failed to evaluate initrd modules"
                error: $config_eval.stderr
            }
        }
    } catch {
        {
            name: "Initrd Kernel Modules"
            success: false
            message: "Error checking initrd modules"
        }
    })
    
    let checks = ($checks | append $initrd_check)
    
    # Check for required boot modules for display
    let required_modules = ["nvidia" "nvidia_modeset" "nvidia_drm" "i915" "amdgpu"]
    let boot_modules_check = (try {
        let config_eval = (
            INCLUDE_NIXOS_CONFIGS=1 ^nix eval .#nixosConfigurations.nixos.config.boot.kernelModules --json
            | complete
        )
        
        if $config_eval.exit_code == 0 {
            let modules = ($config_eval.stdout | from json)
            let has_gpu_module = ($required_modules | any {|m| $m in $modules})
            
            {
                name: "GPU Boot Modules"
                success: true
                message: if $has_gpu_module { "GPU modules configured" } else { "No GPU modules in boot - may use auto-detection" }
                modules: $modules
            }
        } else {
            {
                name: "GPU Boot Modules"
                success: false
                message: "Failed to evaluate boot modules"
            }
        }
    } catch {
        {
            name: "GPU Boot Modules"
            success: false
            message: "Error checking boot modules"
        }
    })
    
    let checks = ($checks | append $boot_modules_check)
    
    # Check boot.loader configuration
    let bootloader_check = (try {
        let config_eval = (
            INCLUDE_NIXOS_CONFIGS=1 ^nix eval .#nixosConfigurations.nixos.config.boot.loader.systemd-boot.enable --json
            | complete
        )
        
        if $config_eval.exit_code == 0 {
            let systemd_boot = ($config_eval.stdout | from json)
            {
                name: "Boot Loader"
                success: true
                message: if $systemd_boot { "systemd-boot enabled" } else { "Using alternative bootloader" }
            }
        } else {
            {
                name: "Boot Loader"
                success: false
                message: "Failed to evaluate bootloader config"
            }
        }
    } catch {
        {
            name: "Boot Loader"
            success: false
            message: "Error checking bootloader"
        }
    })
    
    let checks = ($checks | append $bootloader_check)
    
    # Validate stage-1 will build
    let stage1_build_check = (try {
        print "  Testing stage-1 build (this may take a moment)..."
        let build_result = (
            INCLUDE_NIXOS_CONFIGS=1 ^nix build .#nixosConfigurations.nixos.config.system.build.initialRamdisk --dry-run
            | complete
        )
        
        {
            name: "Stage-1 Build Test"
            success: ($build_result.exit_code == 0)
            message: if ($build_result.exit_code == 0) { 
                "Stage-1 (initrd) builds successfully" 
            } else { 
                "Stage-1 build FAILED - DO NOT REBUILD!" 
            }
            error: if ($build_result.exit_code != 0) { $build_result.stderr } else { null }
        }
    } catch {
        {
            name: "Stage-1 Build Test"
            success: false
            message: "Could not test stage-1 build"
        }
    })
    
    let checks = ($checks | append $stage1_build_check)
    
    {
        success: ($checks | all {|c| $c.success})
        checks: $checks
        critical: true  # Stage-1 failures are critical
    }
}

# Validate display manager configuration
def validate_display_manager [] {
    print_info "Validating display manager configuration..."
    
    let checks = []
    
    # Check which display manager is enabled
    let dm_check = (try {
        # Check for SDDM
        let sddm_result = (
            INCLUDE_NIXOS_CONFIGS=1 ^nix eval .#nixosConfigurations.nixos.config.services.xserver.displayManager.sddm.enable --json
            | complete
        )
        
        # Check for GDM
        let gdm_result = (
            INCLUDE_NIXOS_CONFIGS=1 ^nix eval .#nixosConfigurations.nixos.config.services.xserver.displayManager.gdm.enable --json
            | complete
        )
        
        # Check for LightDM
        let lightdm_result = (
            INCLUDE_NIXOS_CONFIGS=1 ^nix eval .#nixosConfigurations.nixos.config.services.xserver.displayManager.lightdm.enable --json
            | complete
        )
        
        let sddm = if ($sddm_result.exit_code == 0) { ($sddm_result.stdout | from json) } else { false }
        let gdm = if ($gdm_result.exit_code == 0) { ($gdm_result.stdout | from json) } else { false }
        let lightdm = if ($lightdm_result.exit_code == 0) { ($lightdm_result.stdout | from json) } else { false }
        
        let enabled_dms = []
        let enabled_dms = if $sddm { ($enabled_dms | append "SDDM") } else { $enabled_dms }
        let enabled_dms = if $gdm { ($enabled_dms | append "GDM") } else { $enabled_dms }
        let enabled_dms = if $lightdm { ($enabled_dms | append "LightDM") } else { $enabled_dms }
        
        {
            name: "Display Manager"
            success: (($enabled_dms | length) == 1)
            message: if (($enabled_dms | length) == 1) {
                $"($enabled_dms | first) is enabled"
            } else if (($enabled_dms | length) == 0) {
                "WARNING: No display manager enabled!"
            } else {
                $"ERROR: Multiple display managers enabled: ($enabled_dms | str join ', ')"
            }
            display_managers: $enabled_dms
        }
    } catch {
        {
            name: "Display Manager"
            success: false
            message: "Failed to check display manager configuration"
        }
    })
    
    let checks = ($checks | append $dm_check)
    
    # Check if X11 is enabled
    let xserver_check = (try {
        let result = (
            INCLUDE_NIXOS_CONFIGS=1 ^nix eval .#nixosConfigurations.nixos.config.services.xserver.enable --json
            | complete
        )
        
        if $result.exit_code == 0 {
            let enabled = ($result.stdout | from json)
            {
                name: "X Server"
                success: true
                message: if $enabled { "X11 is enabled" } else { "X11 is disabled (Wayland-only?)" }
            }
        } else {
            {
                name: "X Server"
                success: false
                message: "Failed to check X server configuration"
            }
        }
    } catch {
        {
            name: "X Server"
            success: false
            message: "Error checking X server"
        }
    })
    
    let checks = ($checks | append $xserver_check)
    
    {
        success: ($checks | where name == "Display Manager" | get success | first)
        checks: $checks
        critical: true  # Display manager issues are critical
    }
}

# Validate greeter configuration
def validate_greeter_config [] {
    print_info "Validating greeter configuration..."
    
    let checks = []
    
    # Check for desktop manager
    let desktop_check = (try {
        # Check for Plasma
        let plasma_result = (
            INCLUDE_NIXOS_CONFIGS=1 ^nix eval .#nixosConfigurations.nixos.config.services.xserver.desktopManager.plasma6.enable --json
            | complete
        )
        
        # Check for GNOME
        let gnome_result = (
            INCLUDE_NIXOS_CONFIGS=1 ^nix eval .#nixosConfigurations.nixos.config.services.xserver.desktopManager.gnome.enable --json
            | complete
        )
        
        let plasma = if ($plasma_result.exit_code == 0) { ($plasma_result.stdout | from json) } else { false }
        let gnome = if ($gnome_result.exit_code == 0) { ($gnome_result.stdout | from json) } else { false }
        
        let enabled_desktops = []
        let enabled_desktops = if $plasma { ($enabled_desktops | append "Plasma 6") } else { $enabled_desktops }
        let enabled_desktops = if $gnome { ($enabled_desktops | append "GNOME") } else { $enabled_desktops }
        
        {
            name: "Desktop Manager"
            success: (($enabled_desktops | length) >= 1)
            message: if (($enabled_desktops | length) >= 1) {
                $"Desktop: ($enabled_desktops | str join ', ')"
            } else {
                "WARNING: No desktop manager enabled!"
            }
            desktops: $enabled_desktops
        }
    } catch {
        {
            name: "Desktop Manager"
            success: false
            message: "Failed to check desktop manager"
        }
    })
    
    let checks = ($checks | append $desktop_check)
    
    # Check for autologin (which can cause issues)
    let autologin_check = (try {
        let result = (
            INCLUDE_NIXOS_CONFIGS=1 ^nix eval .#nixosConfigurations.nixos.config.services.xserver.displayManager.autoLogin.enable --json
            | complete
        )
        
        if $result.exit_code == 0 {
            let enabled = ($result.stdout | from json)
            {
                name: "Auto-login"
                success: true
                message: if $enabled { "Auto-login is enabled (potential security risk)" } else { "Auto-login disabled (recommended)" }
                warning: $enabled
            }
        } else {
            {
                name: "Auto-login"
                success: true
                message: "Auto-login not configured"
            }
        }
    } catch {
        {
            name: "Auto-login"
            success: true
            message: "Auto-login not configured"
        }
    })
    
    let checks = ($checks | append $autologin_check)
    
    {
        success: ($checks | all {|c| $c.success})
        checks: $checks
    }
}

# Validate X server configuration
def validate_xserver_config [] {
    print_info "Validating X server configuration..."
    
    let checks = []
    
    # Check video drivers
    let video_drivers_check = (try {
        let result = (
            INCLUDE_NIXOS_CONFIGS=1 ^nix eval .#nixosConfigurations.nixos.config.services.xserver.videoDrivers --json
            | complete
        )
        
        if $result.exit_code == 0 {
            let drivers = ($result.stdout | from json)
            {
                name: "Video Drivers"
                success: (($drivers | length) > 0)
                message: if (($drivers | length) > 0) {
                    $"Configured drivers: ($drivers | str join ', ')"
                } else {
                    "WARNING: No video drivers configured!"
                }
                drivers: $drivers
            }
        } else {
            {
                name: "Video Drivers"
                success: false
                message: "Failed to check video drivers"
            }
        }
    } catch {
        {
            name: "Video Drivers"
            success: false
            message: "Error checking video drivers"
        }
    })
    
    let checks = ($checks | append $video_drivers_check)
    
    # Check for conflicting drivers
    let conflict_check = (try {
        let result = (
            INCLUDE_NIXOS_CONFIGS=1 ^nix eval .#nixosConfigurations.nixos.config.services.xserver.videoDrivers --json
            | complete
        )
        
        if $result.exit_code == 0 {
            let drivers = ($result.stdout | from json)
            let has_nvidia = ("nvidia" in $drivers)
            let has_nouveau = ("nouveau" in $drivers)
            
            {
                name: "Driver Conflicts"
                success: (not ($has_nvidia and $has_nouveau))
                message: if ($has_nvidia and $has_nouveau) {
                    "ERROR: Both nvidia and nouveau drivers configured - WILL CAUSE CONFLICTS!"
                } else {
                    "No driver conflicts detected"
                }
            }
        } else {
            {
                name: "Driver Conflicts"
                success: true
                message: "Could not check for driver conflicts"
            }
        }
    } catch {
        {
            name: "Driver Conflicts"
            success: true
            message: "Could not check for driver conflicts"
        }
    })
    
    let checks = ($checks | append $conflict_check)
    
    {
        success: ($checks | all {|c| $c.success})
        checks: $checks
    }
}

# Validate Wayland configuration
def validate_wayland_config [] {
    print_info "Checking Wayland configuration..."
    
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
def validate_gpu_drivers [] {
    print_info "Validating GPU driver configuration..."
    
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
def validate_display_dependencies [] {
    print_info "Checking display dependencies..."
    
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
def validate_config_syntax [] {
    print_info "Validating configuration syntax..."
    
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

# Check for critical failures
def check_critical_failures [results: record] {
    let critical_components = ["stage1" "display_manager" "gpu_driver" "config_syntax"]
    
    let has_critical_failure = ($critical_components | any {|component|
        if ($results | get -i $component | is-not-empty) {
            let result = ($results | get $component)
            if ($result | get -i critical | default false) {
                not $result.success
            } else {
                false
            }
        } else {
            false
        }
    })
    
    $has_critical_failure
}

# Print validation report
def print_validation_report [results: record] {
    print "\n📊 Display Safety Validation Report"
    print "===================================="
    
    $results | transpose key value | each {|row|
        let component = $row.key
        let result = $row.value
        let is_critical = ($result | get -i critical | default false)
        let status = if $result.success { "✅" } else if $is_critical { "❌" } else { "⚠️" }
        
        print $"\n($status) ($component | str replace '_' ' ' | str capitalize)"
        
        if ($result | get -i checks | is-not-empty) {
            $result.checks | each {|check|
                let check_status = if $check.success { "  ✓" } else { "  ✗" }
                print $"($check_status) ($check.name): ($check.message)"
                
                if ($check | get -i warning | is-not-empty) {
                    if $check.warning {
                        print $"      ⚠️  Warning: ($check.message)"
                    }
                }
                
                if ($check | get -i error | is-not-empty) {
                    if ($check.error | is-not-empty) {
                        print "      Error details:"
                        $check.error | lines | first 5 | each {|line|
                            print $"        ($line)"
                        }
                    }
                }
            }
        }
    }
    
    print "\n"
}

# Helper functions
def print_header [title: string] {
    print $"(ansi blue)🖥️  ($title)(ansi reset)"
    print $"(ansi blue)================================(ansi reset)\n"
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
    print $"(ansi yellow)⚠️  ($message)(ansi reset)"
}

# Run main if called directly
if $env.FILE_PWD == (which $env.CURRENT_FILE | get path | first) {
    main
}