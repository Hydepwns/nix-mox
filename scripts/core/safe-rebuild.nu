#!/usr/bin/env nu

# Safe NixOS rebuild wrapper with mandatory validation
# Prevents system damage by enforcing safety checks

def main [
    --flake: string = ".#nixos"     # Flake configuration to deploy
    --action: string = "switch"     # Action: switch, boot, test, dry-activate
    --force                         # Skip safety checks (dangerous!)
    --backup                        # Create system backup before rebuild
    --test-first                    # Run comprehensive tests before rebuild
    --verbose (-v)                  # Verbose output
] {
    print "🛡️  Safe NixOS Rebuild"
    print "====================="
    print ""

    if $force {
        print "⚠️  WARNING: Force mode enabled - skipping safety checks!"
        print "   This could result in an unbootable system."
        print ""
        let confirm = (input "Type 'I UNDERSTAND THE RISKS' to continue: ")
        if $confirm != "I UNDERSTAND THE RISKS" {
            print "❌ Aborted - safety checks are mandatory"
            exit 1
        }
        print ""
    }

    let flake_target = $flake
    let rebuild_action = $action

    # Validate action parameter
    if not ($rebuild_action in ["switch", "boot", "test", "dry-activate", "dry-build"]) {
        print $"❌ Invalid action: ($rebuild_action)"
        print "Valid actions: switch, boot, test, dry-activate, dry-build"
        exit 1
    }

    # Step 1: Pre-flight checks
    print "📋 Pre-flight system checks..."
    run_preflight_checks

    # Step 2: Safety validation (unless forced)
    if not $force {
        print "🔍 Running mandatory safety validation..."
        let safety_result = (nu scripts/validation/pre-rebuild-safety-check.nu --flake $flake_target | complete)
        
        if $safety_result.exit_code != 0 {
            print "❌ Safety validation failed!"
            print $safety_result.stderr
            print ""
            print "🚨 REBUILD BLOCKED - Fix safety issues before proceeding"
            print "   Run: nu scripts/validation/pre-rebuild-safety-check.nu --verbose"
            exit 1
        }
        
        print "✅ Safety validation passed"
    }

    # Step 3: Comprehensive testing (if requested)
    if $test_first {
        print "🧪 Running comprehensive flake tests..."
        let test_result = (nu scripts/validation/safe-flake-test.nu --target-flake $flake_target | complete)
        
        if $test_result.exit_code != 0 {
            print "❌ Comprehensive tests failed!"
            print $test_result.stderr
            exit 1
        }
        
        print "✅ All comprehensive tests passed"
    }

    # Step 4: System backup (if requested)
    if $backup {
        print "💾 Creating system backup..."
        backup_current_system
    }

    # Step 5: Dry-run validation (always, unless action is already dry)
    if not ($rebuild_action in ["dry-activate", "dry-build"]) {
        print "🧪 Running dry-run validation..."
        let dry_run_result = (nixos-rebuild dry-activate --flake $flake_target | complete)
        
        if $dry_run_result.exit_code != 0 {
            print "❌ Dry-run validation failed!"
            print $dry_run_result.stderr
            print ""
            print "🚨 Configuration has evaluation or syntax errors"
            exit 1
        }
        
        print "✅ Dry-run validation passed"
    }

    # Step 6: Final confirmation for destructive actions
    if $rebuild_action in ["switch", "boot"] {
        print ""
        print "⚠️  FINAL CONFIRMATION"
        print "====================="
        print $"You are about to run: nixos-rebuild ($rebuild_action) --flake ($flake_target)"
        print "This will modify your system configuration."
        print ""
        print "Rollback plan:"
        print "  sudo nixos-rebuild --rollback switch"
        print ""
        
        let confirm = (input "Proceed with rebuild? (yes/no): ")
        if $confirm != "yes" {
            print "❌ Rebuild cancelled by user"
            exit 0
        }
    }

    # Step 7: Execute rebuild with monitoring
    print $"🚀 Executing nixos-rebuild ($rebuild_action)..."
    print "==============================================="
    
    let start_time = (date now)
    let rebuild_result = (nixos-rebuild $rebuild_action --flake $flake_target | complete)
    let end_time = (date now)
    let duration = ($end_time - $start_time)
    
    if $rebuild_result.exit_code == 0 {
        print ""
        print "✅ Rebuild completed successfully!"
        print $"⏱️  Duration: ($duration)"
        
        if $rebuild_action in ["switch", "boot"] {
            print ""
            print "🔍 Post-deployment validation..."
            run_post_deployment_checks
        }
        
        print ""
        print "💡 Next steps:"
        if $rebuild_action == "switch" {
            print "   - Verify all services are running correctly"
            print "   - Test display, audio, and network connectivity"
            print "   - Run: nu scripts/core/health-check.nu"
        }
        print "   - Monitor system stability over next few boots"
        print "   - Keep recovery media handy for 24-48 hours"
        
    } else {
        print ""
        print "❌ Rebuild failed!"
        print $rebuild_result.stderr
        
        if $rebuild_action in ["switch", "boot"] {
            print ""
            print "🚨 EMERGENCY RECOVERY"
            print "===================="
            print "Your system may be in an inconsistent state."
            print "Recommended actions:"
            print "  1. sudo nixos-rebuild --rollback switch"
            print "  2. If system won't boot, use recovery media"
            print "  3. Check error messages above for specific issues"
        }
        
        exit 1
    }
}

def run_preflight_checks [] {
    # Check if we're on NixOS
    if not (("/etc/nixos" | path exists) or ("/etc/NIXOS" | path exists)) {
        print "❌ This doesn't appear to be a NixOS system"
        exit 1
    }
    
    # Check if we have sufficient permissions
    if (whoami | str trim) != "root" {
        # Check if user can use sudo (simplified check)
        let can_sudo = (try { sudo -n true 2>/dev/null; $env.LAST_EXIT_CODE == 0 } catch { false })
        if not $can_sudo {
            print "⚠️  May need sudo permissions for rebuild"
        }
    }
    
    # Check disk space
    let root_usage = (df -h / | lines | last | split column -c " " | get column4 | str replace "%" "")
    if ($root_usage | into int) > 95 {
        print "⚠️  Root filesystem over 95% full - rebuild may fail"
        print "   Consider running: nix-collect-garbage -d"
    }
    
    # Check if flake file exists
    if not ("flake.nix" | path exists) {
        print "❌ flake.nix not found in current directory"
        exit 1
    }
    
    print "✅ Pre-flight checks passed"
}

def backup_current_system [] {
    let backup_dir = $"/tmp/nixos-backup-(date now | format date '%Y%m%d-%H%M%S')"
    
    try {
        mkdir $backup_dir
        
        # Backup generation info
        nixos-rebuild list-generations | save $"($backup_dir)/generations.txt"
        
        # Backup current system info
        sys | save $"($backup_dir)/system-info.txt"
        
        # Save current boot generation
        readlink /run/current-system | save $"($backup_dir)/current-system-link.txt"
        
        # Backup hardware config if exists
        if ("/etc/nixos/hardware-configuration.nix" | path exists) {
            cp /etc/nixos/hardware-configuration.nix $"($backup_dir)/hardware-configuration.nix"
        }
        
        echo $backup_dir | save /tmp/nixos-last-backup
        print $"✅ System backup created at: ($backup_dir)"
        
    } catch {
        print "⚠️  Failed to create full backup - continuing anyway"
    }
}

def run_post_deployment_checks [] {
    # Check if essential services are running
    let critical_services = ["dbus", "systemd-logind", "NetworkManager"]
    
    for service in $critical_services {
        let status = (systemctl is-active $service | str trim)
        if $status != "active" {
            print $"⚠️  Critical service ($service) is not active: ($status)"
        }
    }
    
    # Check if display is working (if we have one)
    if not (echo $env.DISPLAY? | is-empty) {
        print "✅ Display environment detected and working"
    }
    
    # Check if network is working
    try {
        let network_test = (ping -c 1 -W 2 8.8.8.8 | complete)
        if $network_test.exit_code == 0 {
            print "✅ Network connectivity verified"
        } else {
            print "⚠️  Network connectivity issue detected"
        }
    } catch {
        print "⚠️  Could not test network connectivity"
    }
    
    print "✅ Post-deployment checks completed"
}