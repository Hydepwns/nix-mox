#!/usr/bin/env nu
# Post-rebuild validation script
# Ensures all critical systems are functioning after NixOS rebuild

use ../lib/logging.nu *

# Main post-rebuild validation
export def validate_post_rebuild [
    --verbose = false           # Show detailed output
] {
    banner "Post-Rebuild System Validation" --context "post-rebuild"
    
    mut critical_issues = []
    mut warnings = []
    mut successes = []
    
    # 1. System boot and generation
    info "1. Checking system generation..." --context "post-rebuild"
    let gen_check = check_system_generation
    if $gen_check.success {
        $successes = ($successes | append "System generation updated")
        if $verbose {
            info $"  Current generation: ($gen_check.generation)" --context "post-rebuild"
        }
    } else {
        $warnings = ($warnings | append $gen_check.message)
    }
    
    # 2. Display system
    info "2. Validating display system..." --context "post-rebuild"
    let display_check = check_display_system
    if not $display_check.healthy {
        $critical_issues = ($critical_issues | append "Display system issues detected")
        $critical_issues = ($critical_issues | append $display_check.issues)
    } else {
        $successes = ($successes | append "Display system healthy")
    }
    
    # 3. Session management
    info "3. Checking session management..." --context "post-rebuild"
    let session_check = check_session_management
    if not $session_check.healthy {
        $warnings = ($warnings | append $session_check.issues)
    } else {
        $successes = ($successes | append "Session management working")
    }
    
    # 4. Reboot capability
    info "4. Testing reboot capability..." --context "post-rebuild"
    let reboot_check = check_reboot_capability
    if not $reboot_check.working {
        $warnings = ($warnings | append "Reboot functionality degraded")
        $warnings = ($warnings | append $reboot_check.issues)
    } else {
        $successes = ($successes | append "Reboot capability verified")
    }
    
    # 5. Network connectivity
    info "5. Checking network connectivity..." --context "post-rebuild"
    let network_check = check_network
    if not $network_check.connected {
        $warnings = ($warnings | append "Network connectivity issues")
    } else {
        $successes = ($successes | append "Network connected")
    }
    
    # 6. Critical services
    info "6. Checking critical services..." --context "post-rebuild"
    let services_check = check_critical_services
    if not $services_check.all_running {
        $warnings = ($warnings | append $services_check.failed_services)
    } else {
        $successes = ($successes | append "All critical services running")
    }
    
    # 7. File system mounts
    info "7. Validating file system mounts..." --context "post-rebuild"
    let mount_check = check_mounts
    if not $mount_check.healthy {
        $critical_issues = ($critical_issues | append $mount_check.issues)
    } else {
        $successes = ($successes | append "File systems mounted correctly")
    }
    
    # Report results
    print ""
    banner "Validation Summary" --context "post-rebuild"
    
    # Show successes
    if ($successes | length) > 0 {
        success "Passed checks:" --context "post-rebuild"
        for item in $successes {
            success $"  ✅ ($item)" --context "post-rebuild"
        }
    }
    
    # Show warnings
    if ($warnings | length) > 0 {
        print ""
        warn "Warnings detected:" --context "post-rebuild"
        for warning in $warnings {
            warn $"  ⚠️  ($warning)" --context "post-rebuild"
        }
    }
    
    # Show critical issues
    if ($critical_issues | length) > 0 {
        print ""
        error "CRITICAL ISSUES:" --context "post-rebuild"
        for issue in $critical_issues {
            error $"  ❌ ($issue)" --context "post-rebuild"
        }
        
        print ""
        error "System may be unstable! Consider rollback:" --context "post-rebuild"
        error "  sudo nixos-rebuild switch --rollback" --context "post-rebuild"
        
        return {
            success: false,
            critical_issues: $critical_issues,
            warnings: $warnings
        }
    }
    
    # Overall status
    print ""
    if ($warnings | length) > 0 {
        warn "✓ Rebuild successful with warnings" --context "post-rebuild"
    } else {
        success "✅ Rebuild validated successfully!" --context "post-rebuild"
    }
    
    return {
        success: true,
        critical_issues: [],
        warnings: $warnings
    }
}

# Check system generation
def check_system_generation [] {
    let current_gen = try {
        let result = (sudo nixos-rebuild list-generations | tail -1 | complete)
        if $result.exit_code == 0 {
            let gen_info = ($result.stdout | str trim)
            return {
                success: true,
                generation: $gen_info,
                message: ""
            }
        } else {
            return {
                success: false,
                generation: "unknown",
                message: "Could not query system generation"
            }
        }
    } catch {
        return {
            success: false,
            generation: "unknown",
            message: "Failed to check generation"
        }
    }
}

# Check display system health
def check_display_system [] {
    mut issues = []
    
    # Check display manager
    let dm_status = (systemctl is-active display-manager | complete)
    if ($dm_status.stdout | str trim) != "active" {
        $issues = ($issues | append "Display manager not active")
    }
    
    # Check for X11/Wayland session
    if "DISPLAY" in $env or "WAYLAND_DISPLAY" in $env {
        # Session exists
    } else {
        $issues = ($issues | append "No display session detected")
    }
    
    # Check for NVIDIA issues if using NVIDIA
    if (lsmod | grep nvidia | complete).exit_code == 0 {
        # Check for common NVIDIA issues
        let nvidia_check = (nvidia-smi | complete)
        if $nvidia_check.exit_code != 0 {
            $issues = ($issues | append "NVIDIA driver not responding")
        }
    }
    
    return {
        healthy: (($issues | length) == 0),
        issues: $issues
    }
}

# Check session management
def check_session_management [] {
    mut issues = []
    
    # Check systemd-logind
    let logind = (systemctl is-active systemd-logind | complete)
    if ($logind.stdout | str trim) != "active" {
        $issues = ($issues | append "systemd-logind not active")
    }
    
    # Check PolicyKit
    let polkit = (systemctl is-active polkit | complete)
    if ($polkit.stdout | str trim) != "active" {
        $issues = ($issues | append "PolicyKit not active")
    }
    
    # Check active sessions
    let sessions = (loginctl list-sessions --no-legend | complete)
    if $sessions.exit_code != 0 or (($sessions.stdout | lines | length) == 0) {
        $issues = ($issues | append "No active login sessions")
    }
    
    return {
        healthy: (($issues | length) == 0),
        issues: $issues
    }
}

# Check reboot capability
def check_reboot_capability [] {
    mut issues = []
    mut methods_working = []
    
    # Test systemctl reboot (dry run)
    let systemctl_test = (systemctl --dry-run reboot | complete)
    if $systemctl_test.exit_code == 0 {
        $methods_working = ($methods_working | append "systemctl")
    } else {
        $issues = ($issues | append "systemctl reboot not available")
    }
    
    # Test KDE shutdown interface if in KDE
    if "KDE_SESSION_VERSION" in $env {
        let kde_test = (qdbus org.kde.LogoutPrompt | complete)
        if $kde_test.exit_code == 0 {
            $methods_working = ($methods_working | append "KDE logout")
        } else {
            $issues = ($issues | append "KDE logout interface not available")
        }
    }
    
    # Check PolicyKit permissions
    let pk_test = (pkaction --action-id org.freedesktop.login1.reboot --verbose | complete)
    if $pk_test.exit_code != 0 or not ($pk_test.stdout | str contains "implicit active:   yes") {
        $issues = ($issues | append "PolicyKit reboot permission issues")
    }
    
    return {
        working: (($methods_working | length) > 0),
        methods: $methods_working,
        issues: $issues
    }
}

# Check network connectivity
def check_network [] {
    # Check if we can reach common DNS servers
    let dns_test = (ping -c 1 -W 2 8.8.8.8 | complete)
    let connected = $dns_test.exit_code == 0
    
    # Check NetworkManager if available
    let nm_status = (systemctl is-active NetworkManager | complete)
    let nm_active = ($nm_status.stdout | str trim) == "active"
    
    return {
        connected: $connected,
        network_manager: $nm_active
    }
}

# Check critical services
def check_critical_services [] {
    let critical_services = [
        "systemd-journald",
        "systemd-logind",
        "dbus",
        "polkit",
        "NetworkManager",
        "display-manager"
    ]
    
    mut failed = []
    
    for service in $critical_services {
        let status = (systemctl is-active $service | complete)
        if ($status.stdout | str trim) != "active" {
            # Some services might not exist, only report if they exist but aren't active
            let exists = (systemctl list-unit-files $service | complete)
            if $exists.exit_code == 0 {
                $failed = ($failed | append $service)
            }
        }
    }
    
    return {
        all_running: (($failed | length) == 0),
        failed_services: $failed
    }
}

# Check file system mounts
def check_mounts [] {
    mut issues = []
    
    # Check root is mounted
    let root_mount = (mount | grep " / " | complete)
    if $root_mount.exit_code != 0 {
        $issues = ($issues | append "Root filesystem not properly mounted")
    }
    
    # Check boot if it should be mounted
    if ("/boot" | path exists) {
        let boot_mount = (mount | grep " /boot " | complete)
        if $boot_mount.exit_code != 0 {
            $issues = ($issues | append "/boot not mounted")
        }
    }
    
    # Check for read-only file systems that shouldn't be
    let ro_check = (mount | grep " / " | grep "ro," | complete)
    if $ro_check.exit_code == 0 {
        $issues = ($issues | append "Root filesystem is read-only")
    }
    
    return {
        healthy: (($issues | length) == 0),
        issues: $issues
    }
}

# Auto-fix common issues
export def auto_fix_post_rebuild [] {
    banner "Attempting Auto-Fix for Common Issues" --context "post-rebuild"
    
    mut fixed = []
    
    # Fix 1: Restart critical services
    info "Restarting critical services..." --context "post-rebuild"
    let services = ["polkit", "systemd-logind", "display-manager"]
    
    for service in $services {
        let restart = (sudo systemctl restart $service | complete)
        if $restart.exit_code == 0 {
            $fixed = ($fixed | append $"Restarted ($service)")
        }
    }
    
    # Fix 2: Reset KDE session if in KDE
    if "KDE_SESSION_VERSION" in $env {
        info "Resetting KDE components..." --context "post-rebuild"
        systemctl --user restart plasma-plasmashell
        systemctl --user restart plasma-powerdevil
        $fixed = ($fixed | append "Reset KDE session components")
    }
    
    # Fix 3: Clear system caches
    info "Clearing system caches..." --context "post-rebuild"
    sudo rm -rf /var/cache/fontconfig/*
    fc-cache -f
    $fixed = ($fixed | append "Cleared font cache")
    
    # Report fixes
    if ($fixed | length) > 0 {
        success "Applied fixes:" --context "post-rebuild"
        for fix in $fixed {
            success $"  ✓ ($fix)" --context "post-rebuild"
        }
        
        warn "Please log out and back in for all changes to take effect" --context "post-rebuild"
    }
    
    return $fixed
}

# Main function
def main [
    --auto-fix = false,         # Automatically fix issues
    --verbose = false           # Verbose output
] {
    let result = validate_post_rebuild --verbose=$verbose
    
    if not $result.success and $auto_fix {
        print ""
        auto_fix_post_rebuild
        print ""
        info "Re-running validation..." --context "post-rebuild"
        validate_post_rebuild --verbose=$verbose
    }
}