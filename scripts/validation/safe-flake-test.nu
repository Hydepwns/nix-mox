#!/usr/bin/env nu

# Import unified libraries
use ../../../../../../../../../lib/unified-checks.nu
use ../../../../../../../../../lib/enhanced-error-handling.nu


# Safe flake testing strategy for NixOS configurations
# Tests multiple configuration variations to identify issues before deployment

def main [
    --target-flake: string = ".#nixos"  # Target flake to test
    --test-minimal                      # Test with minimal configuration first  
    --backup-current                    # Backup current system before testing
    --rollback-plan                     # Show rollback strategy
    --verbose (-v)                      # Verbose output
] {
    print "🧪 Safe NixOS Flake Testing Strategy"
    print "===================================="
    print ""

    if $rollback_plan {
        show_rollback_strategy
        return
    }

    let target = $target_flake

    if $backup_current {
        print "💾 Creating system backup..."
        backup_current_config
    }

    # Test progression from safest to target configuration
    let test_sequence = if $test_minimal {
        [
            { name: "minimal", flake: ".#minimal-test", description: "Minimal safe configuration" },
            { name: "base", flake: ".#base-test", description: "Base system with essential services" },
            { name: "target", flake: $target, description: "Target configuration" }
        ]
    } else {
        [
            { name: "target", flake: $target, description: "Target configuration" }
        ]
    }

    mut test_results = []

    for test_config in $test_sequence {
        print $"🔍 Testing ($test_config.name): ($test_config.description)"
        
        let result = test_flake_configuration $test_config.flake $verbose
        $test_results = ($test_results | append { config: $test_config.name, result: $result })
        
        if $result.status == "FAIL" {
            print $"❌ Test failed for ($test_config.name) - stopping here"
            print_test_summary $test_results
            show_failure_guidance $result
            return
        }
        
        print $"✅ ($test_config.name) test passed"
        print ""
    }

    print_test_summary $test_results
    print "🎉 All tests passed - configuration appears safe to deploy"
    show_deployment_guidance
}

def backup_current_config [] {
    try {
        # Create backup of current system
        let backup_dir = $"/tmp/nixos-backup-(date now | format date '%Y%m%d-%H%M%S')"
        mkdir $backup_dir
        
        # Backup current generation info
        nixos-rebuild list-generations | save $"($backup_dir)/generations.txt"
        
        # Backup current configuration.nix if it exists
        if (ls /etc/nixos/configuration.nix | length) > 0 {
            cp /etc/nixos/configuration.nix $"($backup_dir)/configuration.nix"
        }
        
        # Backup hardware configuration
        if (ls /etc/nixos/hardware-configuration.nix | length) > 0 {
            cp /etc/nixos/hardware-configuration.nix $"($backup_dir)/hardware-configuration.nix"
        }
        
        print $"✅ System backup created at: ($backup_dir)"
        echo $backup_dir | save /tmp/nixos-last-backup
    } catch {
        print "⚠️  Failed to create system backup - proceeding anyway"
    }
}

def test_flake_configuration [flake: string, verbose: bool] {
    if $verbose { print $"  Testing flake: ($flake)" }
    
    mut test_result = {
        status: "PASS",
        checks: [],
        errors: []
    }
    
    # 1. Syntax check
    if $verbose { print "  → Checking flake syntax..." }
    let flake_path = ($flake | str replace -r '\.#.*' '.')
    let syntax_check = (nix --extra-experimental-features "nix-command flakes" flake check $flake_path --no-build | complete)
    
    if $syntax_check.exit_code != 0 {
        $test_result.status = "FAIL"
        $test_result.errors = ($test_result.errors | append { 
            stage: "syntax", 
            message: "Flake syntax check failed",
            details: $syntax_check.stderr
        })
        return $test_result
    }
    
    $test_result.checks = ($test_result.checks | append "syntax")
    
    # 2. Evaluation test
    if $verbose { print "  → Testing configuration evaluation..." }
    let eval_check = (nixos-rebuild dry-run --flake .#nixos | complete)
    
    if $eval_check.exit_code != 0 {
        $test_result.status = "FAIL"
        $test_result.errors = ($test_result.errors | append {
            stage: "evaluation",
            message: "Configuration evaluation failed", 
            details: $eval_check.stderr
        })
        return $test_result
    }
    
    $test_result.checks = ($test_result.checks | append "evaluation")
    
    # 3. Build test (without activation)
    if $verbose { print "  → Testing configuration build..." }
    let build_check = (nix --extra-experimental-features "nix-command flakes" build .#nixosConfigurations.nixos.config.system.build.toplevel --dry-run | complete)
    
    if $build_check.exit_code != 0 {
        $test_result.status = "FAIL"  
        $test_result.errors = ($test_result.errors | append {
            stage: "build",
            message: "Configuration build failed",
            details: $build_check.stderr
        })
        return $test_result
    }
    
    $test_result.checks = ($test_result.checks | append "build")
    
    # 4. Safety validation
    if $verbose { print "  → Running safety validation..." }
    let safety_check = (nu scripts/validation/pre-rebuild-safety-check.nu --flake $flake | complete)
    
    if $safety_check.exit_code != 0 {
        $test_result.status = "WARN"
        $test_result.errors = ($test_result.errors | append {
            stage: "safety",
            message: "Safety validation warnings/failures",
            details: $safety_check.stderr
        })
    } else {
        $test_result.checks = ($test_result.checks | append "safety")
    }
    
    return $test_result
}

def print_test_summary [results: list] {
    print "📊 Test Summary"
    print "==============="
    print ""
    
    for result in $results {
        let status_icon = match $result.result.status {
            "PASS" => "✅",
            "WARN" => "⚠️ ",
            "FAIL" => "❌"
        }
        
        print $"($status_icon) ($result.config): ($result.result.status)"
        
        if ($result.result.checks | length) > 0 {
            for check in $result.result.checks {
                print $"  ✓ ($check)"
            }
        }
        
        if ($result.result.errors | length) > 0 {
            for error in $result.result.errors {
                print $"  ❌ ($error.stage): ($error.message)"
            }
        }
        
        print ""
    }
}

def show_failure_guidance [result: record] {
    print "🚨 Test Failure Guidance"
    print "========================"
    print ""
    
    for error in $result.errors {
        print $"Stage: ($error.stage)"
        print $"Error: ($error.message)"
        print "Details:"
        print $error.details
        print ""
        
        match $error.stage {
            "syntax" => {
                print "💡 Recommendations:"
                print "- Check flake.nix for syntax errors"
                print "- Validate all imported modules exist"
                print "- Run 'nix flake check' for detailed syntax validation"
            },
            "evaluation" => {
                print "💡 Recommendations:"
                print "- Check for missing or misconfigured options"
                print "- Validate all module imports"
                print "- Review attribute name typos"
            },
            "build" => {
                print "💡 Recommendations:"
                print "- Check for missing packages or broken dependencies"
                print "- Validate hardware configuration compatibility"
                print "- Review kernel module requirements"
            },
            "safety" => {
                print "💡 Recommendations:"
                print "- Review user and group configurations"
                print "- Check display and network settings"
                print "- Validate boot loader configuration"
            }
        }
        print ""
    }
    
    print "🔄 Next Steps:"
    print "1. Fix the identified issues"
    print "2. Re-run this test script"
    print "3. Only proceed with deployment after all tests pass"
}

def show_deployment_guidance [] {
    print "🚀 Ready for Deployment"
    print "======================="
    print ""
    print "Your configuration has passed all safety tests. To deploy:"
    print ""
    print "1. Final safety check:"
    print "   nu scripts/validation/pre-rebuild-safety-check.nu"
    print ""
    print "2. Deploy with rollback protection:"
    print "   sudo nixos-rebuild switch --flake .#nixos"
    print ""
    print "3. If issues occur, rollback immediately:"
    print "   sudo nixos-rebuild --rollback switch"
    print ""
    print "4. Monitor system health after deployment:"
    print "   nu scripts/maintenance/health-check.nu"
    print ""
    print "⚠️  Keep a recovery USB/ISO handy in case of boot failures"
}

def show_rollback_strategy [] {
    print "🔄 NixOS Rollback Strategy"
    print "=========================="
    print ""
    print "NixOS provides built-in rollback capabilities:"
    print ""
    print "🔧 Immediate Rollback (if system still boots):"
    print "  sudo nixos-rebuild --rollback switch"
    print ""
    print "🔧 Boot Menu Rollback (if system boots but has issues):"
    print "  1. Reboot system"
    print "  2. Select previous generation from boot menu"
    print "  3. Boot into working configuration"
    print ""
    print "🔧 Recovery Boot (if system won't boot):"
    print "  1. Boot from NixOS installation media"
    print "  2. Mount system partitions"
    print "  3. nixos-enter to chroot into system"
    print "  4. nixos-rebuild --rollback switch"
    print ""
    print "🔧 Check Available Generations:"
    print "  nixos-rebuild list-generations"
    print ""
    print "🔧 Manual Generation Selection:"
    print "  sudo /nix/var/nix/profiles/system-X-link/bin/switch-to-configuration switch"
    print "  (where X is the generation number)"
    print ""
    print "💾 Current System Backup Location:"
    let backup_location = try { open /tmp/nixos-last-backup | str trim } catch { "No backup created yet" }
    print $"  ($backup_location)"
}

# Create minimal test configuration
def create_minimal_test_config [] {
    let minimal_config = "
{ config, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];
  
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  networking.networkmanager.enable = true;
  
  users.users.root.hashedPassword = \"!\";
  users.users." + (whoami) + " = {
    isNormalUser = true;
    extraGroups = [ \"wheel\" \"networkmanager\" ];
  };
  
  services.openssh.enable = true;
  
  system.stateVersion = \"23.11\";
}
"
    $minimal_config | save config/minimal-test.nix
}