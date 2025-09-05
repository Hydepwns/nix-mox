#!/usr/bin/env nu
# Display safety validation functions
# Extracted from scripts/validation/validate-display-safety.nu for better organization

use ../../lib/logging.nu *

# ──────────────────────────────────────────────────────────
# CORE VALIDATION FUNCTIONS
# ──────────────────────────────────────────────────────────

# Validate stage-1 boot won't fail
export def validate_stage1_boot [] {
    info "Validating stage-1 boot configuration..." --context "display-safety"
    
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
            let has_gpu_module = ($required_modules | any {| m| $m in $modules})
            
            {
                name: "GPU Boot Modules"
                success: true
                message: (if $has_gpu_module { "GPU modules configured" } else { "No GPU modules in boot - may use auto-detection" })
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
                message: (if $systemd_boot { "systemd-boot enabled" } else { "Using alternative bootloader" })
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
            message: (if ($build_result.exit_code == 0) { 
                "Stage-1 (initrd) builds successfully" 
            } else { 
                "Stage-1 build FAILED - DO NOT REBUILD!" 
            })
            error: (if ($build_result.exit_code != 0) { $build_result.stderr } else { null })
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
        success: ($checks | all {| c| $c.success})
        checks: $checks
        critical: true  # Stage-1 failures are critical
    }
}

# Validate display manager configuration
export def validate_display_manager [] {
    info "Validating display manager configuration..." --context "display-safety"
    
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
        
        let dm_message = if (($enabled_dms | length) == 1) { 
            $"($enabled_dms | first) is enabled" 
        } else if (($enabled_dms | length) == 0) { 
            "WARNING: No display manager enabled!" 
        } else { 
            $"ERROR: Multiple display managers enabled: ($enabled_dms | str join ', ')" 
        }
        
        {
            name: "Display Manager"
            success: (($enabled_dms | length) == 1)
            message: $dm_message
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
                message: (if $enabled { $"X11 is enabled" } else { $"X11 is disabled (Wayland-only?)" })
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
export def validate_greeter_config [] {
    info "Validating greeter configuration..." --context "display-safety"
    
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
            message: (if (($enabled_desktops | length) >= 1) { $"Desktop: ($enabled_desktops | str join ', ')" } else { "WARNING: No desktop manager enabled!" })
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
                message: (if $enabled { $"Auto-login is enabled (potential security risk)" } else { $"Auto-login disabled (recommended)" })
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
        success: ($checks | all {| c| $c.success})
        checks: $checks
    }
}

# Validate X server configuration
export def validate_xserver_config [] {
    info "Validating X server configuration..." --context "display-safety"
    
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
                message: (if (($drivers | length) > 0) { $"Configured drivers: ($drivers | str join ', ')" } else { "WARNING: No video drivers configured!" })
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
                message: (if ($has_nvidia and $has_nouveau) { $"ERROR: Both nvidia and nouveau drivers configured - WILL CAUSE CONFLICTS!" } else { "No driver conflicts detected" })
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
        success: ($checks | all {| c| $c.success})
        checks: $checks
    }
}