#!/usr/bin/env nu

# Session Unlock Manager Diagnostic Test
# Identifies configuration conflicts causing display/unlock issues and phase 1 build faults

def main [] {
    print "🔍 Session Unlock Manager Diagnostic Test"
    print "=========================================="
    print ""

    let results = {
        display_manager_conflicts: (check_display_manager_conflicts),
        security_session_conflicts: (check_security_session_conflicts), 
        systemd_user_restrictions: (check_systemd_user_restrictions),
        pam_conflicts: (check_pam_conflicts),
        build_phase_analysis: (check_build_phase_issues),
        session_services: (check_session_services)
    }

    # Summary report
    print "📊 DIAGNOSTIC SUMMARY"
    print "====================="
    print ""

    for category in ($results | columns) {
        let data = ($results | get $category)
        print $"Category: ($category)"
        print $"  Status: ($data.status)"
        print $"  Issues: ($data.issues | length)"
        if ($data.issues | length) > 0 {
            for issue in $data.issues {
                print $"    - ($issue)"
            }
        }
        print ""
    }

    # Critical issues
    let critical_issues = ($results | values | where status == "CRITICAL" | length)
    let warning_issues = ($results | values | where status == "WARNING" | length)
    
    print $"🚨 Critical Issues: ($critical_issues)"
    print $"⚠️  Warning Issues: ($warning_issues)"
    
    if $critical_issues > 0 {
        print ""
        print "🔧 RECOMMENDED FIXES:"
        print "===================="
        generate_fixes $results
    }

    return $results
}

def check_display_manager_conflicts [] {
    print "Checking display manager conflicts..."
    
    mut issues = []
    mut status = "OK"
    
    try {
        # Check for multiple display manager definitions
        let sddm_files = (rg -l 'displayManager.*sddm' --type nix .)
        let gdm_files = (rg -l 'displayManager.*gdm' --type nix .)
        let lightdm_files = (rg -l 'displayManager.*lightdm' --type nix .)
        
        let total_dm_configs = ($sddm_files | length) + ($gdm_files | length) + ($lightdm_files | length)
        
        if $total_dm_configs > 1 {
            $issues = ($issues | append "Multiple display manager configurations found")
            $status = "CRITICAL"
        }
        
        # Check for conflicting X server configurations
        let xserver_configs = (rg -l 'services\.xserver.*displayManager' --type nix .)
        let new_displaymanager_configs = (rg -l 'services\.displayManager' --type nix .)
        
        if ($xserver_configs | length) > 0 and ($new_displaymanager_configs | length) > 0 {
            $issues = ($issues | append "Mixed old (xserver.displayManager) and new (displayManager) syntax")
            $status = "CRITICAL"
        }
        
        # Check for services.desktopManager.gnome conflicts with SDDM
        let gnome_sddm_conflict = (rg -l 'desktopManager\.gnome.*enable.*true' --type nix . | each { |file|
            let content = (open $file)
            if ($content | str contains "displayManager.sddm") {
                $file
            }
        } | compact)
        
        if ($gnome_sddm_conflict | length) > 0 {
            $issues = ($issues | append "GNOME desktop manager with SDDM display manager conflict")
            $status = "CRITICAL"
        }
        
        {
            status: $status,
            issues: $issues,
            details: {
                sddm_files: $sddm_files,
                gdm_files: $gdm_files,
                lightdm_files: $lightdm_files,
                xserver_configs: $xserver_configs,
                new_displaymanager_configs: $new_displaymanager_configs
            }
        }
    } catch { |e|
        {
            status: "ERROR",
            issues: [$"Failed to check display manager conflicts: ($e.msg)"],
            details: {}
        }
    }
}

def check_security_session_conflicts [] {
    print "Checking security-session conflicts..."
    
    mut issues = []
    mut status = "OK"
    
    try {
        # Check systemd user session restrictions
        let security_config = "config/profiles/security.nix"
        
        if ($security_config | path exists) {
            let content = (open $security_config)
            
            # Check for restrictive limits that could break sessions
            if ($content | str contains "DefaultLimitNOFILE=1024") {
                $issues = ($issues | append "Very restrictive file descriptor limits may break GUI sessions")
                $status = "WARNING"
            }
            
            if ($content | str contains "DefaultLimitNPROC=256") {
                $issues = ($issues | append "Very restrictive process limits may break desktop sessions")
                $status = "CRITICAL"
            }
            
            if ($content | str contains "users.mutableUsers = false") {
                $issues = ($issues | append "Immutable users may conflict with session managers")
                $status = "WARNING"
            }
            
            # Check for kernel hardening that might break graphics
            if ($content | str contains "lockdown=confidentiality") {
                $issues = ($issues | append "Kernel confidentiality lockdown may break GPU drivers")
                $status = "CRITICAL"
            }
            
            if ($content | str contains "kernel.perf_event_paranoid=3") {
                $issues = ($issues | append "Extreme perf restrictions may break compositors")
                $status = "WARNING"
            }
        }
        
        {
            status: $status,
            issues: $issues,
            details: {
                security_config_exists: ($security_config | path exists)
            }
        }
    } catch { |e|
        {
            status: "ERROR", 
            issues: [$"Failed to check security conflicts: ($e.msg)"],
            details: {}
        }
    }
}

def check_systemd_user_restrictions [] {
    print "Checking systemd user restrictions..."
    
    mut issues = []
    mut status = "OK"
    
    try {
        let security_config = "config/profiles/security.nix"
        
        if ($security_config | path exists) {
            let content = (open $security_config)
            
            # Check for user session restrictions that break unlock managers
            if ($content | str contains "user.extraConfig") {
                if ($content | str contains "DefaultLimitNOFILE=1024") and ($content | str contains "DefaultLimitNPROC=256") {
                    $issues = ($issues | append "User session limits too restrictive for GUI unlock managers")
                    $status = "CRITICAL"
                }
            }
        }
        
        {
            status: $status,
            issues: $issues,
            details: {}
        }
    } catch { |e|
        {
            status: "ERROR",
            issues: [$"Failed to check systemd restrictions: ($e.msg)"],
            details: {}
        }
    }
}

def check_pam_conflicts [] {
    print "Checking PAM configuration conflicts..."
    
    mut issues = []
    mut status = "OK"
    
    try {
        let security_config = "config/profiles/security.nix"
        
        if ($security_config | path exists) {
            let content = (open $security_config)
            
            # Check for commented out PAM configurations that might indicate conflicts
            if ($content | str contains "# pam.services") {
                $issues = ($issues | append "PAM services configuration commented out - may cause auth issues")
                $status = "WARNING"
            }
            
            # Check for loginLimits that might affect GUI sessions
            if ($content | str contains 'item = "nproc"; value = "512"') {
                $issues = ($issues | append "Process limits may be too low for modern desktop environments")
                $status = "WARNING"  
            }
        }
        
        {
            status: $status,
            issues: $issues,
            details: {}
        }
    } catch { |e|
        {
            status: "ERROR",
            issues: [$"Failed to check PAM conflicts: ($e.msg)"],
            details: {}
        }
    }
}

def check_build_phase_issues [] {
    print "Checking build phase 1 issues..."
    
    mut issues = []
    mut status = "OK"
    
    try {
        # Check for conflicting module imports
        let config_file = "config/nixos/configuration.nix"
        
        if ($config_file | path exists) {
            let content = (open $config_file)
            
            # Check if we're importing conflicting profiles
            let imports = ($content | rg 'imports = \[' -A 10 | rg '\.\./profiles/')
            
            if ($imports | str contains "security.nix") and ($imports | str contains "gaming.nix") {
                $issues = ($issues | append "Gaming and security profiles may have conflicting systemd settings")
                $status = "WARNING"
            }
        }
        
        # Check for duplicate service definitions in different files
        let display_common = "modules/templates/base/common/display.nix"  
        let display_base = "modules/templates/base/common.nix"
        
        if ($display_common | path exists) and ($display_base | path exists) {
            let common_content = (open $display_common)
            let base_content = (open $display_base)
            
            if ($common_content | str contains "displayManager.sddm") and ($base_content | str contains "displayManager.sddm") {
                $issues = ($issues | append "Duplicate SDDM configuration in display.nix and common.nix")
                $status = "CRITICAL"
            }
        }
        
        {
            status: $status,
            issues: $issues,
            details: {}
        }
    } catch { |e|
        {
            status: "ERROR",
            issues: [$"Failed to check build phase issues: ($e.msg)"],
            details: {}
        }
    }
}

def check_session_services [] {
    print "Checking session service configuration..."
    
    mut issues = []
    mut status = "OK"
    
    try {
        # Check if we have proper desktop environment setup
        let has_desktop = (rg -l 'desktopManager\.' --type nix .) 
        let has_window_manager = (rg -l 'windowManager\.' --type nix .)
        
        if ($has_desktop | length) == 0 and ($has_window_manager | length) == 0 {
            $issues = ($issues | append "No desktop environment or window manager configured")
            $status = "CRITICAL"
        }
        
        # Check for X11 vs Wayland conflicts with unlock managers
        let x11_configs = (rg -l 'services\.xserver' --type nix .)
        let wayland_configs = (rg -l "wayland" --type nix .)
        
        if ($x11_configs | length) > 0 and ($wayland_configs | length) > 0 {
            $issues = ($issues | append "Mixed X11/Wayland configuration may cause session issues")
            $status = "WARNING"
        }
        
        {
            status: $status,
            issues: $issues,
            details: {
                has_desktop: ($has_desktop | length),
                has_window_manager: ($has_window_manager | length),
                x11_configs: ($x11_configs | length),
                wayland_configs: ($wayland_configs | length)
            }
        }
    } catch { |e|
        {
            status: "ERROR",
            issues: [$"Failed to check session services: ($e.msg)"],
            details: {}
        }
    }
}

def generate_fixes [results] {
    let critical_categories = ($results | columns | where {|col| ($results | get $col).status == "CRITICAL"})
    
    for category in $critical_categories {
        match $category {
            "display_manager_conflicts" => {
                print "1. Fix display manager conflicts:"
                print "   - Remove duplicate SDDM configs from display.nix OR common.nix"  
                print "   - Use only new displayManager syntax, not xserver.displayManager"
                print "   - Don't mix GNOME desktop manager with SDDM display manager"
            }
            "security_session_conflicts" => {
                print "2. Fix security session conflicts:"
                print "   - Increase systemd user process limits to at least 1024"
                print "   - Consider relaxing kernel lockdown to 'integrity' instead of 'confidentiality'"
                print "   - Adjust perf_event_paranoid to 2 instead of 3"
            }
            "systemd_user_restrictions" => {
                print "3. Fix systemd user restrictions:"
                print "   - Increase DefaultLimitNPROC for user sessions to 512+"
                print "   - Increase DefaultLimitNOFILE for user sessions to 2048+"
            }
            "build_phase_analysis" => {
                print "4. Fix build phase issues:"
                print "   - Remove duplicate service definitions"
                print "   - Resolve profile conflicts between security and gaming"
            }
            "session_services" => {
                print "5. Fix session services:"
                print "   - Configure a proper desktop environment"
                print "   - Resolve X11/Wayland conflicts"
            }
        }
        print ""
    }
}