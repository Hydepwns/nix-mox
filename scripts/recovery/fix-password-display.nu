#!/usr/bin/env nu

# Comprehensive Fix for Password and Display Issues
# This script addresses both the password change and black screen problems

def show_banner [] {
    print "(ansi red)🔧 nix-mox Password & Display Fix(ansi reset)"
    print "(ansi yellow)========================================(ansi reset)"
    print ""
}

def check_current_password [] {
    print "(ansi blue)🔍 Checking current password state...(ansi reset)"
    
    let shadow_line = (try {
        sudo cat /etc/shadow | grep nixos
    } catch {
        "Could not read shadow file"
    })
    
    print $"  Current password hash: ($shadow_line)"
    print ""
    
    $shadow_line
}

def backup_configuration [] {
    print "(ansi blue)💾 Creating configuration backup...(ansi reset)"
    
    let timestamp = (date now | format date "%Y%m%d_%H%M%S")
    let backup_dir = "/tmp/nix-mox-backups"
    
    try {
        mkdir $backup_dir
    } catch {
        # Directory might already exist
    }
    
    let backup_files = [
        "config/personal/hydepwns.nix"
        "config/nixos/configuration.nix"
        "flake.nix"
    ]
    
    $backup_files | each {|file|
        if ($file | path exists) {
            let backup_path = $"($backup_dir)/($file | path basename)_($timestamp)"
            cp $file $backup_path
            print $"  ✅ Backed up ($file) to ($backup_path)"
        } else {
            print $"  ⚠️  File not found: ($file)"
        }
    }
    
    print ""
}

def fix_password_configuration [] {
    print "(ansi blue)🔧 Fixing password configuration...(ansi reset)"
    
    # Check if the configuration already has the fix
    let config_content = (try {
        open "config/personal/hydepwns.nix"
    } catch {
        ""
    })
    
    if ($config_content | str contains "CRITICAL: Don't set password here") {
        print "  ✅ Password configuration already fixed"
    } else {
        print "  ⚠️  Password configuration needs fixing"
        print "  📝 Please apply the configuration changes manually"
        print "  📖 See docs/PASSWORD_RECOVERY.md for details"
    }
    
    print ""
}

def fix_display_configuration [] {
    print "(ansi blue)🔧 Fixing display configuration...(ansi reset)"
    
    # Check if the configuration already has the fix
    let config_content = (try {
        open "config/nixos/configuration.nix"
    } catch {
        ""
    })
    
    let fixes_applied = {
        wayland_disabled: ($config_content | str contains "wayland.enable = false")
        autologin_enabled: ($config_content | str contains "autoLogin")
        force_composition_disabled: ($config_content | str contains "forceFullCompositionPipeline = false")
    }
    
    print $"  Wayland disabled: (if $fixes_applied.wayland_disabled { '(ansi green)✅' } else { '(ansi red)❌' })"
    print $"  Auto-login enabled: (if $fixes_applied.autologin_enabled { '(ansi green)✅' } else { '(ansi red)❌' })"
    print $"  Force composition disabled: (if $fixes_applied.force_composition_disabled { '(ansi green)✅' } else { '(ansi red)❌' })"
    
    if ($fixes_applied | values | all {|v| $v}) {
        print "  ✅ Display configuration already fixed"
    } else {
        print "  ⚠️  Display configuration needs fixing"
        print "  📝 Please apply the configuration changes manually"
    }
    
    print ""
}

def test_configuration [] {
    print "(ansi blue)🧪 Testing configuration...(ansi reset)"
    
    print "  Testing NixOS configuration evaluation..."
    let test_result = (try {
        nixos-rebuild dry-activate --flake .#nixos
        {
            success: true
            message: "Configuration evaluation successful"
        }
    } catch {|err|
        {
            success: false
            message: $"Configuration evaluation failed: ($err)"
        }
    })
    
    if $test_result.success {
        print "  ✅ Configuration test passed"
    } else {
        print "  ❌ Configuration test failed"
        print $"  Error: ($test_result.message)"
    }
    
    print ""
    
    $test_result
}

def apply_fixes [] {
    print "(ansi blue)🚀 Applying fixes...(ansi reset)"
    
    print "  This will rebuild your system with the fixes"
    print "  ⚠️  Make sure you have a backup before proceeding"
    print ""
    
    let confirm = (input "Do you want to proceed? (y/N): ")
    
    if ($confirm | str downcase) == "y" {
        print "  🔄 Rebuilding system..."
        
        let rebuild_result = (try {
            sudo nixos-rebuild switch --flake .#nixos
            {
                success: true
                message: "System rebuilt successfully"
            }
        } catch {|err|
            {
                success: false
                message: $"Rebuild failed: ($err)"
            }
        })
        
        if $rebuild_result.success {
            print "  ✅ System rebuilt successfully"
            print "  🔄 Please reboot to apply all changes"
        } else {
            print "  ❌ Rebuild failed"
            print $"  Error: ($rebuild_result.message)"
        }
    } else {
        print "  ⏸️  Rebuild cancelled"
    }
    
    print ""
}

def show_recovery_instructions [] {
    print "(ansi yellow)📋 Recovery Instructions(ansi reset)"
    print ""
    print "If you're currently experiencing issues:"
    print ""
    print "1. **Password Issues**:"
    print "   - Press Ctrl+Alt+F1 to switch to console"
    print "   - Login as root or nixos user"
    print "   - Run: passwd nixos"
    print "   - Set a new password"
    print ""
    print "2. **Display Issues**:"
    print "   - Press Ctrl+Alt+F1 to switch to console"
    print "   - Run: sudo systemctl restart display-manager"
    print "   - Press Ctrl+Alt+F7 to return to display"
    print ""
    print "3. **If display doesn't work**:"
    print "   - Stay in console (Ctrl+Alt+F1)"
    print "   - Run: sudo nixos-rebuild boot --flake .#nixos"
    print "   - Reboot: sudo reboot"
    print ""
}

def main [] {
    show_banner
    
    backup_configuration
    check_current_password
    fix_password_configuration
    fix_display_configuration
    
    let config_test = test_configuration
    
    if $config_test.success {
        apply_fixes
    } else {
        print "(ansi red)❌ Cannot proceed due to configuration errors(ansi reset)"
        print "Please fix the configuration issues first"
    }
    
    show_recovery_instructions
    
    print "(ansi green)✅ Fix script completed(ansi reset)"
}

# Run main function
main 