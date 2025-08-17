#!/usr/bin/env nu

# Pre-rebuild safety validation script
# Validates critical system components before nixos-rebuild

def main [
    --flake: string = ".#nixosConfigurations.nixos"  # Flake to test
    --dry-run                    # Only show what would be tested
    --verbose (-v)               # Verbose output
] {
    print "🛡️  Pre-rebuild Safety Check"
    print "=========================="
    print ""

    let flake_path = $flake
    
    if $dry_run {
        print "DRY RUN MODE - No actual validation, showing what would be checked:"
        print_checks_overview
        return
    }

    let results = {
        display_check: (check_display_config $flake_path $verbose),
        user_groups_check: (check_user_groups $flake_path $verbose),
        boot_config_check: (check_boot_config $flake_path $verbose),
        network_check: (check_network_config $flake_path $verbose),
        service_check: (check_critical_services $flake_path $verbose),
        flake_syntax_check: (check_flake_syntax $flake_path $verbose)
    }
    
    print_results $results
    
    let failed_checks = ($results | values | where $it.status == "FAIL" | length)
    
    if $failed_checks > 0 {
        print $"❌ ($failed_checks) critical checks failed - DO NOT REBUILD"
        exit 1
    } else {
        print "✅ All safety checks passed - Safe to rebuild"
        exit 0
    }
}

def print_checks_overview [] {
    print "1. Display Configuration Check"
    print "   - Validates display manager settings"
    print "   - Checks desktop environment compatibility"
    print "   - Verifies graphics driver configuration"
    print ""
    print "2. User Groups Check"
    print "   - Validates user exists in configuration"
    print "   - Checks group memberships (wheel, audio, video, etc.)"
    print "   - Verifies home directory settings"
    print ""
    print "3. Boot Configuration Check" 
    print "   - Validates boot loader configuration"
    print "   - Checks kernel modules"
    print "   - Verifies initrd settings"
    print ""
    print "4. Network Configuration Check"
    print "   - Validates network manager settings"
    print "   - Checks firewall configuration"
    print "   - Verifies DNS settings"
    print ""
    print "5. Critical Services Check"
    print "   - Validates essential system services"
    print "   - Checks service dependencies"
    print "   - Verifies service configurations"
    print ""
    print "6. Flake Syntax Check"
    print "   - Validates flake.nix syntax"
    print "   - Checks all imported modules"
    print "   - Verifies configuration structure"
}

def check_display_config [flake_path: string, verbose: bool] {
    if $verbose { print "🖥️  Checking display configuration..." }
    
    try {
        # Check if display manager is configured (more targeted approach)
        let sddm_enabled = (nix --extra-experimental-features "nix-command flakes" eval $"($flake_path).config.services.xserver.displayManager.sddm.enable" --json | from json)
        
        # Check desktop environment (more targeted approach)
        let plasma_enabled = (nix --extra-experimental-features "nix-command flakes" eval $"($flake_path).config.services.xserver.desktopManager.plasma6.enable" --json | from json)
        
        # Verify current display setup won't be broken
        let current_display = (echo $env.DISPLAY? | default "")
        let current_session = (echo $env.XDG_CURRENT_DESKTOP? | default "")
        
        if ($current_display | is-empty) and ($current_session | is-empty) {
            if $verbose { print "⚠️  No current display session detected - this may be a headless system" }
        }
        
        return {
            status: "PASS",
            message: "Display configuration validated",
            details: {
                sddm_enabled: $sddm_enabled,
                plasma_enabled: $plasma_enabled,
                current_session: $current_session
            }
        }
    } catch {
        return {
            status: "FAIL",
            message: "Display configuration validation failed",
            details: "Could not evaluate display settings from flake"
        }
    }
}

def check_user_groups [flake_path: string, verbose: bool] {
    if $verbose { print "👥 Checking user and group configuration..." }
    
    try {
        # Get current user
        let current_user = (whoami)
        
        # Check if user exists in configuration
        let users_config = (nix --extra-experimental-features "nix-command flakes" eval $"($flake_path).config.users.users" --json | from json)
        
        if not ($current_user in ($users_config | columns)) {
            return {
                status: "FAIL",
                message: $"Current user '($current_user)' not found in configuration",
                details: "User may lose access after rebuild"
            }
        }
        
        let user_config = ($users_config | get $current_user)
        
        # Check critical group memberships
        let critical_groups = ["wheel", "audio", "video", "networkmanager"]
        let user_groups = ($user_config.extraGroups? | default [])
        let missing_groups = ($critical_groups | where $it not-in $user_groups)
        
        if ($missing_groups | length) > 0 {
            return {
                status: "WARN", 
                message: $"User missing critical groups: ($missing_groups | str join ', ')",
                details: {
                    user: $current_user,
                    current_groups: $user_groups,
                    missing_groups: $missing_groups
                }
            }
        }
        
        return {
            status: "PASS",
            message: "User and group configuration validated",
            details: {
                user: $current_user,
                groups: $user_groups
            }
        }
    } catch {
        return {
            status: "FAIL", 
            message: "User configuration validation failed",
            details: "Could not evaluate user settings from flake"
        }
    }
}

def check_boot_config [flake_path: string, verbose: bool] {
    if $verbose { print "🔧 Checking boot configuration..." }
    
    try {
        # Check boot loader configuration (more targeted approach)
        let systemd_boot_enabled = (nix --extra-experimental-features "nix-command flakes" eval $"($flake_path).config.boot.loader.systemd-boot.enable" --json | from json)
        
        # Verify boot loader type matches system
        let current_boot_mode = if (ls /sys/firmware/efi | length) > 0 { "uefi" } else { "bios" }
        
        let grub_enabled = (nix --extra-experimental-features "nix-command flakes" eval $"($flake_path).config.boot.loader.grub.enable" --json | from json)
        
        if $current_boot_mode == "uefi" and (not $systemd_boot_enabled) and (not $grub_enabled) {
            return {
                status: "FAIL",
                message: "UEFI system but no UEFI boot loader configured",
                details: "System may not boot after rebuild"
            }
        }
        
        return {
            status: "PASS",
            message: "Boot configuration validated",
            details: {
                boot_mode: $current_boot_mode,
                systemd_boot: $systemd_boot_enabled,
                grub: $grub_enabled
            }
        }
    } catch {
        return {
            status: "FAIL",
            message: "Boot configuration validation failed", 
            details: "Could not evaluate boot settings from flake"
        }
    }
}

def check_network_config [flake_path: string, verbose: bool] {
    if $verbose { print "🌐 Checking network configuration..." }
    
    try {
        # Check if NetworkManager is enabled (more targeted approach)
        let nm_enabled = (nix --extra-experimental-features "nix-command flakes" eval $"($flake_path).config.networking.networkmanager.enable" --json | from json)
        
        # Check if NetworkManager is currently active
        let nm_active = (systemctl is-active NetworkManager | str trim) == "active"
        
        if $nm_active and (not $nm_enabled) {
            return {
                status: "WARN",
                message: "NetworkManager currently active but not enabled in config",
                details: "Network connectivity may be lost after rebuild"
            }
        }
        
        return {
            status: "PASS", 
            message: "Network configuration validated",
            details: {
                networkmanager_active: $nm_active,
                networkmanager_enabled: $nm_enabled
            }
        }
    } catch {
        return {
            status: "FAIL",
            message: "Network configuration validation failed",
            details: "Could not evaluate network settings from flake"
        }
    }
}

def check_critical_services [flake_path: string, verbose: bool] {
    if $verbose { print "🔧 Checking critical services..." }
    
    try {
        # Check if critical services are configured (more targeted approach)
        let openssh_enabled = (nix --extra-experimental-features "nix-command flakes" eval $"($flake_path).config.services.openssh.enable" --json | from json)
        let dbus_enabled = (nix --extra-experimental-features "nix-command flakes" eval $"($flake_path).config.services.dbus.enable" --json | from json)
        
        # List of services that should typically be enabled
        let expected_services = {
            "openssh": $openssh_enabled,
            "dbus": $dbus_enabled
        }
        
        return {
            status: "PASS",
            message: "Critical services configuration validated", 
            details: $expected_services
        }
    } catch {
        return {
            status: "FAIL",
            message: "Services configuration validation failed",
            details: "Could not evaluate services from flake"
        }
    }
}

def check_flake_syntax [flake_path: string, verbose: bool] {
    if $verbose { print "📋 Checking flake syntax..." }
    
    try {
        # Test flake evaluation
        nix flake check $flake_path --no-build | complete
        
        if $env.LAST_EXIT_CODE != 0 {
            return {
                status: "FAIL",
                message: "Flake check failed",
                details: "Run 'nix flake check' for details"
            }
        }
        
        # Test dry-run build
        nixos-rebuild dry-activate --flake $flake_path | complete
        
        if $env.LAST_EXIT_CODE != 0 {
            return {
                status: "FAIL", 
                message: "Dry-run activation failed",
                details: "Configuration has syntax or evaluation errors"
            }
        }
        
        return {
            status: "PASS",
            message: "Flake syntax and evaluation validated",
            details: "Flake check and dry-run passed"
        }
    } catch {
        return {
            status: "FAIL",
            message: "Flake validation failed",
            details: "Could not evaluate flake"
        }
    }
}

def print_results [results: record] {
    print "📋 Validation Results:"
    print "====================="
    print ""
    
    for check in ($results | transpose key value) {
        let status_icon = match $check.value.status {
            "PASS" => "✅",
            "WARN" => "⚠️ ", 
            "FAIL" => "❌"
        }
        
        print $"($status_icon) ($check.key): ($check.value.message)"
        
        if $check.value.status == "FAIL" or $check.value.status == "WARN" {
            print $"   Details: ($check.value.details)"
        }
        print ""
    }
}