#!/usr/bin/env nu
# NixOS configuration pre-commit check
# Validates configuration files to prevent reboot/session issues

use ../../lib/logging.nu *

# Main configuration check
export def check_nixos_config [
    --staged-only = false,      # Only check staged files
    --verbose = false           # Show verbose output
] {
    let files_to_check = if $staged_only {
        # Get staged .nix files in config directory
        try {
            let staged_files = (git diff --cached --name-only --diff-filter=ACMR | lines | where ($it | str contains "config/") | where ($it | str ends-with ".nix"))
            if ($staged_files | length) == 0 {
                success "No config files in staging area" --context "nixos-config"
                return 0
            }
            $staged_files
        } catch {
            warn "Could not get staged files, checking all config files" --context "nixos-config"
            (glob "config/**/*.nix")
        }
    } else {
        (glob "config/**/*.nix")
    }
    
    mut critical_issues = []
    mut warnings = []
    
    for file in $files_to_check {
        if not ($file | path exists) {
            continue
        }
        
        if $verbose {
            info $"Checking ($file)..." --context "nixos-config"
        }
        
        let content = (open $file)
        
        # Check for session management issues
        let issues = check_session_config $file $content
        if ($issues.critical | length) > 0 {
            $critical_issues = ($critical_issues | append $issues.critical)
        }
        if ($issues.warnings | length) > 0 {
            $warnings = ($warnings | append $issues.warnings)
        }
    }
    
    # Check main configuration specifically
    if ("config/nixos/configuration.nix" | path exists) {
        let main_config = (open "config/nixos/configuration.nix")
        let main_issues = check_main_configuration $main_config
        
        if ($main_issues.critical | length) > 0 {
            $critical_issues = ($critical_issues | append $main_issues.critical)
        }
        if ($main_issues.warnings | length) > 0 {
            $warnings = ($warnings | append $main_issues.warnings)
        }
    }
    
    # Report results
    if ($critical_issues | length) == 0 and ($warnings | length) == 0 {
        success "NixOS configuration validated successfully! ✅" --context "nixos-config"
        return 0
    }
    
    if ($critical_issues | length) > 0 {
        error $"Found ($critical_issues | length) critical configuration issues:" --context "nixos-config"
        for issue in $critical_issues {
            error $"  ❌ ($issue)" --context "nixos-config"
        }
        error "" --context "nixos-config"
        error "These issues WILL cause problems after rebuild!" --context "nixos-config"
    }
    
    if ($warnings | length) > 0 {
        warn $"Found ($warnings | length) configuration warnings:" --context "nixos-config"
        for warning in $warnings {
            warn $"  ⚠️  ($warning)" --context "nixos-config"
        }
    }
    
    if ($critical_issues | length) > 0 {
        return 1
    } else {
        return 0
    }
}

# Check for session management configuration issues
def check_session_config [file: string, content: string] {
    mut critical = []
    mut warnings = []
    
    # Check if this is a desktop/display configuration
    if ($content | str contains "services.xserver") or ($content | str contains "plasma") {
        
        # Critical: PolicyKit must be enabled for GUI
        if ($content | str contains "plasma6.enable = true") or ($content | str contains "plasma5.enable = true") {
            if not ($content | str contains "security.polkit.enable = true") {
                $critical = ($critical | append $"($file): Plasma enabled but PolicyKit not explicitly enabled")
            }
        }
        
        # Warning: Service restart prevention
        if ($content | str contains "systemd-logind") {
            if not ($content | str contains "restartIfChanged = false") {
                $warnings = ($warnings | append $"($file): systemd-logind may restart during rebuild")
            }
        }
    }
    
    return {
        critical: $critical,
        warnings: $warnings
    }
}

# Check main configuration for required settings
def check_main_configuration [content: string] {
    mut critical = []
    mut warnings = []
    
    # Critical checks
    if not ($content | str contains "security.polkit.enable") {
        $critical = ($critical | append "PolicyKit not configured - will cause reboot issues")
    }
    
    if not ($content | str contains "services.dbus.enable") {
        $warnings = ($warnings | append "D-Bus not explicitly enabled")
    }
    
    # Check for proper PolicyKit rules
    if not ($content | str contains "security.polkit.extraConfig") {
        $warnings = ($warnings | append "No PolicyKit extra rules for wheel group")
    }
    
    # Check for service restart prevention
    let critical_services = ["systemd-logind", "polkit", "display-manager"]
    for service in $critical_services {
        if not ($content | str contains $"($service).restartIfChanged = false") {
            $warnings = ($warnings | append $"($service) may restart during rebuild causing session issues")
        }
    }
    
    # Check for session management module
    if not ($content | str contains "session-management") {
        $warnings = ($warnings | append "Session management module not imported")
    }
    
    return {
        critical: $critical,
        warnings: $warnings
    }
}

# Generate fix suggestions
export def suggest_fixes [] {
    banner "NixOS Configuration Fix Suggestions" --context "nixos-config"
    
    print "Add to your configuration.nix:"
    print ""
    print "```nix"
    print "{ config, lib, pkgs, ... }:"
    print ""
    print "{"
    print "  # Import session management module"
    print "  imports = ["
    print "    ./hardware-configuration.nix"
    print "    ../../modules/session-management.nix"
    print "  ];"
    print ""
    print "  # Enable session management fixes"
    print "  services.sessionManagement = {"
    print "    enable = true;"
    print "    ensureRebootCapability = true;"
    print "    preventServiceRestartIssues = true;"
    print "  };"
    print ""
    print "  # Explicit PolicyKit configuration"
    print "  security.polkit.enable = true;"
    print "  security.polkit.extraConfig = ''''"
    print "    polkit.addRule(function(action, subject) {"
    print "      if ((action.id == \"org.freedesktop.login1.reboot\" ||"
    print "           action.id == \"org.freedesktop.login1.power-off\") &&"
    print "          subject.isInGroup(\"wheel\")) {"
    print "        return polkit.Result.YES;"
    print "      }"
    print "    });"
    print "  '''';"
    print ""
    print "  # Prevent service restarts during rebuild"
    print "  systemd.services = {"
    print "    systemd-logind.restartIfChanged = false;"
    print "    polkit.restartIfChanged = false;"
    print "    display-manager.restartIfChanged = false;"
    print "  };"
    print "}"
    print "```"
}

# Main function for CLI usage
def main [
    action: string = "check",  # check or suggest-fixes
    --staged-only = false,
    --verbose = false
] {
    if $action == "check" {
        check_nixos_config --staged-only=$staged_only --verbose=$verbose
    } else if $action == "suggest-fixes" {
        suggest_fixes
    } else {
        error $"Unknown action: ($action). Use: check or suggest-fixes" --context "nixos-config"
        exit 1
    }
}