#!/usr/bin/env nu
# Comprehensive reboot/shutdown diagnostics
# Tests all components required for system reboot functionality

use ../../lib/logging.nu *

# Main diagnostic function
export def diagnose_reboot [] {
    banner "System Reboot Diagnostics" --context "reboot-diag"
    
    mut issues = []
    mut warnings = []
    
    # 1. Check systemd-logind
    info "1. Checking systemd-logind service..." --context "reboot-diag"
    let logind_check = check_systemd_logind
    if not $logind_check.healthy {
        $issues = ($issues | append $logind_check.issues)
    }
    if ($logind_check.warnings | length) > 0 {
        $warnings = ($warnings | append $logind_check.warnings)
    }
    
    # 2. Check PolicyKit
    info "2. Checking PolicyKit service..." --context "reboot-diag"
    let polkit_check = check_polkit
    if not $polkit_check.healthy {
        $issues = ($issues | append $polkit_check.issues)
    }
    
    # 3. Check DBus
    info "3. Checking DBus session..." --context "reboot-diag"
    let dbus_check = check_dbus_session
    if not $dbus_check.healthy {
        $issues = ($issues | append $dbus_check.issues)
    }
    
    # 4. Check session permissions
    info "4. Checking session permissions..." --context "reboot-diag"
    let session_check = check_session_permissions
    if not $session_check.healthy {
        $issues = ($issues | append $session_check.issues)
    }
    
    # 5. Check KDE components
    info "5. Checking KDE power management..." --context "reboot-diag"
    let kde_check = check_kde_components
    if not $kde_check.healthy {
        $warnings = ($warnings | append $kde_check.issues)
    }
    
    # 6. Test reboot methods
    info "6. Testing reboot methods..." --context "reboot-diag"
    let reboot_test = test_reboot_methods
    if not $reboot_test.all_working {
        $warnings = ($warnings | append $reboot_test.failures)
    }
    
    # Report results
    print ""
    banner "Diagnostic Results" --context "reboot-diag"
    
    if ($issues | length) == 0 and ($warnings | length) == 0 {
        success "✅ All reboot systems functioning correctly!" --context "reboot-diag"
        return {
            healthy: true,
            issues: [],
            warnings: []
        }
    }
    
    if ($issues | length) > 0 {
        error "Critical Issues Found:" --context "reboot-diag"
        for issue in $issues {
            error $"  ❌ ($issue)" --context "reboot-diag"
        }
    }
    
    if ($warnings | length) > 0 {
        warn "Warnings:" --context "reboot-diag"
        for warning in $warnings {
            warn $"  ⚠️  ($warning)" --context "reboot-diag"
        }
    }
    
    # Provide solutions
    print ""
    banner "Recommended Fixes" --context "reboot-diag"
    suggest_fixes $issues $warnings
    
    return {
        healthy: (($issues | length) == 0),
        issues: $issues,
        warnings: $warnings
    }
}

# Check systemd-logind status
def check_systemd_logind [] {
    mut issues = []
    mut warnings = []
    
    # Check if service is running
    let status = (systemctl status systemd-logind | complete)
    if $status.exit_code != 0 {
        $issues = ($issues | append "systemd-logind service not running")
    } else {
        let status_text = $status.stdout
        if ($status_text | str contains "active (running)") {
            info "  ✓ systemd-logind is active" --context "reboot-diag"
        } else {
            $issues = ($issues | append "systemd-logind not in active state")
        }
        
        # Check for recent errors
        if ($status_text | str contains "error") or ($status_text | str contains "failed") {
            $warnings = ($warnings | append "systemd-logind has recent errors in logs")
        }
    }
    
    # Check for active sessions
    let sessions = (loginctl list-sessions --no-legend | complete)
    if $sessions.exit_code != 0 {
        $issues = ($issues | append "Cannot query login sessions")
    } else {
        let session_count = ($sessions.stdout | lines | length)
        info ("  ✓ Found " + ($session_count | into string) + " active sessions") --context "reboot-diag"
        
        if $session_count == 0 {
            $warnings = ($warnings | append "No active login sessions found")
        }
    }
    
    # Check seat assignment
    let seat = (loginctl show-seat seat0 | complete)
    if $seat.exit_code != 0 {
        $warnings = ($warnings | append "No seat0 configured (might affect GUI reboot)")
    }
    
    return {
        healthy: (($issues | length) == 0),
        issues: $issues,
        warnings: $warnings
    }
}

# Check PolicyKit status
def check_polkit [] {
    mut issues = []
    
    # Check if service is running
    let status = (systemctl status polkit | complete)
    if $status.exit_code != 0 {
        $issues = ($issues | append "PolicyKit service not running")
    } else {
        if ($status.stdout | str contains "active (running)") {
            info "  ✓ PolicyKit is active" --context "reboot-diag"
        } else {
            $issues = ($issues | append "PolicyKit not in active state")
        }
    }
    
    # Test PolicyKit actions
    let reboot_action = (pkaction --action-id org.freedesktop.login1.reboot --verbose | complete)
    if $reboot_action.exit_code != 0 {
        $issues = ($issues | append "Cannot query reboot PolicyKit action")
    } else {
        if ($reboot_action.stdout | str contains "implicit active:   yes") {
            info "  ✓ Reboot action allowed for active sessions" --context "reboot-diag"
        } else {
            $issues = ($issues | append "Reboot not allowed for active sessions")
        }
    }
    
    # Check power-off action
    let poweroff_action = (pkaction --action-id org.freedesktop.login1.power-off --verbose | complete)
    if $poweroff_action.exit_code != 0 {
        $issues = ($issues | append "Cannot query power-off PolicyKit action")
    }
    
    return {
        healthy: (($issues | length) == 0),
        issues: $issues
    }
}

# Check DBus session
def check_dbus_session [] {
    mut issues = []
    
    # Check session bus
    if "DBUS_SESSION_BUS_ADDRESS" in $env {
        info ("  ✓ DBus session address: " + ($env.DBUS_SESSION_BUS_ADDRESS | str substring 0..50) + "...") --context "reboot-diag"
    } else {
        $issues = ($issues | append "DBUS_SESSION_BUS_ADDRESS not set")
    }
    
    # Test DBus communication
    let dbus_test = (qdbus | complete)
    if $dbus_test.exit_code != 0 {
        $issues = ($issues | append "Cannot communicate with DBus")
    } else {
        let services = ($dbus_test.stdout | lines | length)
        info ("  ✓ DBus has " + ($services | into string) + " services registered") --context "reboot-diag"
    }
    
    # Check for systemd on DBus
    let systemd_dbus = (qdbus org.freedesktop.systemd1 | complete)
    if $systemd_dbus.exit_code != 0 {
        $issues = ($issues | append "systemd not accessible via DBus")
    }
    
    # Check for KDE on DBus
    let kde_dbus = (qdbus org.kde.Shutdown | complete)
    if $kde_dbus.exit_code != 0 {
        $issues = ($issues | append "KDE Shutdown service not on DBus")
    }
    
    return {
        healthy: (($issues | length) == 0),
        issues: $issues
    }
}

# Check session permissions
def check_session_permissions [] {
    mut issues = []
    
    # Get current user
    let username = (whoami)
    info ("  ✓ Current user: " + $username) --context "reboot-diag"
    
    # Check groups
    let groups = (groups)
    info ("  ✓ Groups: " + $groups) --context "reboot-diag"
    
    if not ($groups | str contains "wheel") {
        $issues = ($issues | append "User not in wheel group (may affect sudo/reboot)")
    }
    
    # Check current session
    let session_info = (loginctl show-session | complete)
    if $session_info.exit_code == 0 {
        let session_props = ($session_info.stdout | lines)
        
        # Check if session is active
        let active_lines = ($session_props | where ($it | str starts-with "Active="))
        if ($active_lines | length) > 0 {
            let active = ($active_lines | first | str replace "Active=" "")
            if $active != "yes" {
                $issues = ($issues | append "Current session not marked as active")
            }
        }
        
        # Check session type
        let type_lines = ($session_props | where ($it | str starts-with "Type="))
        if ($type_lines | length) > 0 {
            let type = ($type_lines | first | str replace "Type=" "")
            info ("  ✓ Session type: " + $type) --context "reboot-diag"
        }
        
        # Check remote status
        let remote_lines = ($session_props | where ($it | str starts-with "Remote="))
        if ($remote_lines | length) > 0 {
            let remote = ($remote_lines | first | str replace "Remote=" "")
            if $remote == "yes" {
                $issues = ($issues | append "Session marked as remote (may affect reboot permissions)")
            }
        }
    }
    
    return {
        healthy: (($issues | length) == 0),
        issues: $issues
    }
}

# Check KDE components
def check_kde_components [] {
    mut issues = []
    
    # Check KDE session
    if "KDE_SESSION_VERSION" in $env {
        info ("  ✓ KDE Session version: " + $env.KDE_SESSION_VERSION) --context "reboot-diag"
    } else {
        $issues = ($issues | append "Not running in KDE session")
    }
    
    # Check PowerDevil (KDE power management)
    let powerdevil = (systemctl --user status plasma-powerdevil | complete)
    if $powerdevil.exit_code != 0 {
        $issues = ($issues | append "KDE PowerDevil not running")
    } else {
        if ($powerdevil.stdout | str contains "active (running)") {
            info "  ✓ KDE PowerDevil is active" --context "reboot-diag"
        } else {
            $issues = ($issues | append "KDE PowerDevil not active")
        }
    }
    
    # Check KDE Shutdown service on DBus
    let kde_shutdown = (qdbus org.kde.Shutdown /Shutdown | complete)
    if $kde_shutdown.exit_code != 0 {
        $issues = ($issues | append "KDE Shutdown service not available")
    } else {
        let methods = ($kde_shutdown.stdout | lines | where ($it | str contains "logout"))
        info ("  ✓ KDE Shutdown has " + ($methods | length | into string) + " logout methods") --context "reboot-diag"
    }
    
    # Check ksmserver (KDE session manager)
    let ksmserver = (qdbus org.kde.ksmserver | complete)
    if $ksmserver.exit_code != 0 {
        $issues = ($issues | append "KDE session manager (ksmserver) not running")
    }
    
    return {
        healthy: (($issues | length) == 0),
        issues: $issues
    }
}

# Test different reboot methods
def test_reboot_methods [] {
    mut working = []
    mut failures = []
    
    info "Testing reboot methods (dry run)..." --context "reboot-diag"
    
    # Test systemctl reboot (without actually rebooting)
    let systemctl_test = (systemctl --dry-run reboot | complete)
    if $systemctl_test.exit_code == 0 {
        $working = ($working | append "systemctl reboot")
        info "  ✓ systemctl reboot would work" --context "reboot-diag"
    } else {
        $failures = ($failures | append "systemctl reboot requires authentication or failed")
    }
    
    # Test loginctl
    let loginctl_test = (loginctl reboot --no-wall --dry-run | complete)
    if $loginctl_test.exit_code == 0 {
        $working = ($working | append "loginctl reboot")
        info "  ✓ loginctl reboot would work" --context "reboot-diag"
    } else {
        $failures = ($failures | append "loginctl reboot failed")
    }
    
    # Test KDE logout methods
    let kde_test = (qdbus org.kde.Shutdown /Shutdown | complete)
    if $kde_test.exit_code == 0 {
        $working = ($working | append "KDE Shutdown DBus")
        info "  ✓ KDE Shutdown DBus interface available" --context "reboot-diag"
    } else {
        $failures = ($failures | append "KDE Shutdown DBus not available")
    }
    
    # Check if we can query shutdown command
    let shutdown_test = (which shutdown)
    if ($shutdown_test | length) > 0 {
        $working = ($working | append "shutdown command")
        info "  ✓ shutdown command available" --context "reboot-diag"
    }
    
    return {
        all_working: (($failures | length) == 0),
        working_methods: $working,
        failures: $failures
    }
}

# Suggest fixes based on issues found
def suggest_fixes [issues: list, warnings: list] {
    mut fixes = []
    
    # Analyze issues and suggest fixes
    for issue in $issues {
        if ($issue | str contains "systemd-logind") {
            $fixes = ($fixes | append "sudo systemctl restart systemd-logind")
        }
        if ($issue | str contains "PolicyKit") {
            $fixes = ($fixes | append "sudo systemctl restart polkit")
        }
        if ($issue | str contains "DBus") {
            $fixes = ($fixes | append "Log out and log back in to reset DBus session")
        }
        if ($issue | str contains "wheel group") {
            $fixes = ($fixes | append "sudo usermod -a -G wheel $(whoami)")
        }
        if ($issue | str contains "PowerDevil") {
            $fixes = ($fixes | append "systemctl --user restart plasma-powerdevil")
        }
        if ($issue | str contains "active session") {
            $fixes = ($fixes | append "loginctl activate $(loginctl list-sessions --no-legend | head -1 | awk '{print $1}')")
        }
    }
    
    if ($fixes | length) > 0 {
        info "Suggested fixes:" --context "reboot-diag"
        for fix in ($fixes | uniq) {
            info ("  → " + $fix) --context "reboot-diag"
        }
    }
    
    # Always suggest safe reboot methods
    print ""
    info "Working reboot methods:" --context "reboot-diag"
    info "  1. Terminal: sudo reboot" --context "reboot-diag"
    info "  2. Terminal: systemctl reboot" --context "reboot-diag"
    info "  3. Terminal: loginctl reboot" --context "reboot-diag"
    info "  4. KDE: qdbus org.kde.Shutdown /Shutdown logoutAndReboot" --context "reboot-diag"
    
    # Suggest configuration fixes
    print ""
    info "To prevent this in future NixOS rebuilds, add to configuration.nix:" --context "reboot-diag"
    print '```nix
security.polkit.enable = true;
security.polkit.extraConfig = ''''
  polkit.addRule(function(action, subject) {
    if ((action.id == "org.freedesktop.login1.reboot" ||
         action.id == "org.freedesktop.login1.power-off") &&
        subject.isInGroup("wheel")) {
      return polkit.Result.YES;
    }
  });
'''';

# Ensure session management works
services.xserver.displayManager.sddm.enable = true;
services.xserver.desktopManager.plasma6.enable = true;
systemd.services.systemd-logind.restartTriggers = [];
```'
}

# Export monitoring function
export def monitor_reboot_capability [] {
    # This runs continuously monitoring reboot capability
    info "Monitoring reboot capability (Ctrl+C to stop)..." --context "reboot-monitor"
    
    loop {
        let timestamp = (date now | format date "%Y-%m-%d %H:%M:%S")
        
        # Quick check of critical services
        let logind_ok = ((systemctl is-active systemd-logind | complete).stdout | str trim) == "active"
        let polkit_ok = ((systemctl is-active polkit | complete).stdout | str trim) == "active"
        let dbus_ok = "DBUS_SESSION_BUS_ADDRESS" in $env
        
        let status = if $logind_ok and $polkit_ok and $dbus_ok {
            "✅"
        } else {
            "❌"
        }
        
        print ("[" + $timestamp + "] " + $status + " Logind: " + $logind_ok + " | PolicyKit: " + $polkit_ok + " | DBus: " + $dbus_ok)
        
        sleep 5sec
    }
}

# Main function
def main [] {
    diagnose_reboot
}