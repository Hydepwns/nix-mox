#!/usr/bin/env nu
# NixOS Configuration Validator
# Ensures configuration will not cause session management issues

use ../lib/logging.nu *

# Main validation function
export def validate_nixos_config [
    --config-file: string = "config/nixos/configuration.nix",
    --fix = false              # Attempt to fix issues
] {
    banner "NixOS Configuration Validation" --context "config-validator"
    
    mut issues = []
    mut warnings = []
    mut fixes_needed = []
    
    # Check if configuration file exists
    if not ($config_file | path exists) {
        error $"Configuration file not found: ($config_file)" --context "config-validator"
        return { valid: false, issues: ["Configuration file not found"] }
    }
    
    let config_content = (open $config_file)
    
    # 1. Check for PolicyKit configuration
    info "Checking PolicyKit configuration..." --context "config-validator"
    if not ($config_content | str contains "security.polkit.enable = true") {
        $issues = ($issues | append "PolicyKit not explicitly enabled")
        $fixes_needed = ($fixes_needed | append {
            issue: "PolicyKit not enabled",
            fix: "security.polkit.enable = true;"
        })
    }
    
    # 2. Check for PolicyKit extra config
    if not ($config_content | str contains "security.polkit.extraConfig") {
        $warnings = ($warnings | append "No PolicyKit extra configuration for wheel group")
        $fixes_needed = ($fixes_needed | append {
            issue: "Missing PolicyKit rules for wheel group",
            fix: 'security.polkit.extraConfig = ''''
  polkit.addRule(function(action, subject) {
    if ((action.id == "org.freedesktop.login1.reboot" ||
         action.id == "org.freedesktop.login1.power-off") &&
        subject.isInGroup("wheel")) {
      return polkit.Result.YES;
    }
  });
'''';'
        })
    }
    
    # 3. Check for service restart prevention
    info "Checking service restart configuration..." --context "config-validator"
    let critical_services = [
        "systemd-logind",
        "polkit",
        "display-manager"
    ]
    
    for service in $critical_services {
        if not ($config_content | str contains $"($service).restartIfChanged = false") {
            $warnings = ($warnings | append $"Service ($service) may restart during rebuild")
            $fixes_needed = ($fixes_needed | append {
                issue: $"($service) may restart",
                fix: $"systemd.services.($service).restartIfChanged = false;"
            })
        }
    }
    
    # 4. Check for session management module
    if not ($config_content | str contains "services.sessionManagement.enable") {
        $warnings = ($warnings | append "Session management module not enabled")
        $fixes_needed = ($fixes_needed | append {
            issue: "Session management module not enabled",
            fix: "services.sessionManagement.enable = true;"
        })
    }
    
    # 5. Check for display manager configuration
    info "Checking display manager configuration..." --context "config-validator"
    if ($config_content | str contains "plasma6.enable = true") {
        if not ($config_content | str contains "sddm.enable = true") {
            $issues = ($issues | append "Plasma 6 enabled but SDDM not explicitly enabled")
        }
    }
    
    # 6. Check for D-Bus configuration
    if not ($config_content | str contains "services.dbus.enable = true") {
        $warnings = ($warnings | append "D-Bus not explicitly enabled")
        $fixes_needed = ($fixes_needed | append {
            issue: "D-Bus not explicitly enabled",
            fix: "services.dbus.enable = true;"
        })
    }
    
    # Report results
    print ""
    if ($issues | length) == 0 and ($warnings | length) == 0 {
        success "✅ Configuration validated successfully!" --context "config-validator"
        return { valid: true, issues: [], warnings: [] }
    }
    
    if ($issues | length) > 0 {
        error "Critical issues found:" --context "config-validator"
        for issue in $issues {
            error $"  ❌ ($issue)" --context "config-validator"
        }
    }
    
    if ($warnings | length) > 0 {
        warn "Warnings:" --context "config-validator"
        for warning in $warnings {
            warn $"  ⚠️  ($warning)" --context "config-validator"
        }
    }
    
    # Show fixes
    if ($fixes_needed | length) > 0 {
        print ""
        info "Suggested configuration additions:" --context "config-validator"
        print "```nix"
        for fix in $fixes_needed {
            print $"  ($fix.fix)"
            print ""
        }
        print "```"
    }
    
    # Apply fixes if requested
    if $fix and ($fixes_needed | length) > 0 {
        apply_fixes $config_file $fixes_needed
    }
    
    return {
        valid: (($issues | length) == 0),
        issues: $issues,
        warnings: $warnings,
        fixes: $fixes_needed
    }
}

# Apply fixes to configuration
def apply_fixes [config_file: string, fixes: list] {
    info "Applying fixes to configuration..." --context "config-validator"
    
    # Read current configuration
    mut content = (open $config_file)
    
    # Create backup
    let backup_file = $"($config_file).backup.(date now | format date '%Y%m%d_%H%M%S')"
    $content | save $backup_file
    info $"Created backup: ($backup_file)" --context "config-validator"
    
    # Apply fixes by adding them before the final closing brace
    let fix_block = ($fixes | each { | fix| $"  # Auto-added by validator\n  ($fix.fix)" } | str join "\n\n")
    
    # Find the last closing brace and insert fixes before it
    if ($content | str contains "}\n") {
        let parts = ($content | split row "}\n")
        let new_content = if ($parts | length) >= 2 {
            let main_part = ($parts | range 0..-2 | str join "}\n")
            let last_part = ($parts | last)
            $"($main_part)\n\n($fix_block)\n}\n($last_part)"
        } else {
            $content
        }
        
        $new_content | save -f $config_file
        success "Configuration updated with fixes" --context "config-validator"
    } else {
        error "Could not automatically apply fixes - manual edit required" --context "config-validator"
    }
}

# Check module imports
export def check_module_imports [] {
    info "Checking NixOS module imports..." --context "config-validator"
    
    let config_file = "config/nixos/configuration.nix"
    let config_content = (open $config_file)
    
    # Check if session-management module is imported
    let has_relative_import = ($config_content | str contains "./modules/session-management.nix")
    let has_simple_import = ($config_content | str contains "session-management.nix")
    
    if not ($has_relative_import or $has_simple_import) {
        warn "Session management module not imported" --context "config-validator"
        
        info "Add to imports section:" --context "config-validator"
        print "```nix"
        print "  imports = ["
        print "    # ... other imports ..."
        print "    ../../modules/session-management.nix"
        print "  ];"
        print "```"
        
        return false
    }
    
    success "Module imports look good" --context "config-validator"
    return true
}

# Validate before rebuild
export def validate_for_rebuild [] {
    banner "Pre-Rebuild Configuration Check" --context "config-validator"
    
    # Run all validations
    let config_valid = validate_nixos_config
    let modules_ok = check_module_imports
    
    if not $config_valid.valid {
        error "Configuration has critical issues that will cause problems!" --context "config-validator"
        error "DO NOT REBUILD until these are fixed!" --context "config-validator"
        return false
    }
    
    if ($config_valid.warnings | length) > 0 {
        warn "Configuration has warnings but should be safe to rebuild" --context "config-validator"
        
        print ""
        let answer = (input "Continue with rebuild? (y/N): ")
        if $answer != "y" {
            info "Rebuild cancelled" --context "config-validator"
            return false
        }
    }
    
    success "Configuration validated - safe to rebuild!" --context "config-validator"
    return true
}

# Main function
def main [
    --fix = false,
    --check-imports = false,
    --pre-rebuild = false
] {
    if $pre_rebuild {
        validate_for_rebuild
    } else if $check_imports {
        check_module_imports
    } else {
        validate_nixos_config --fix=$fix
    }
}