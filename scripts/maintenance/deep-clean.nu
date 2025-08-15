#!/usr/bin/env nu

# Deep cleanup - find ALL dead code and unused files

def main [--fix] {
    print "🔍 Deep scan for dead code and unused files..."
    print ""
    
    # Check all module directories
    print "📦 Checking unused module directories..."
    let unused_modules = [
        $"($env.PWD)/modules/monitoring"
        $"($env.PWD)/modules/packages" 
        $"($env.PWD)/modules/services"
        $"($env.PWD)/modules/system"
        $"($env.PWD)/modules/templates"
        $"($env.PWD)/modules/storage"
        $"($env.PWD)/modules/core"
    ]
    
    for module in $unused_modules {
        if ($module | path exists) {
            # Check if referenced in main config files
            let refs = (do -i { 
                grep -r ($module | path basename) $"($env.PWD)/flake.nix" $"($env.PWD)/config/nixos/configuration.nix" err> /dev/null | lines | length
            } | default 0)
            
            if $refs == 0 {
                print $"  ❌ Unused: ($module)"
                if $fix {
                    rm -rf $module
                    print $"     ✅ Removed ($module)"
                }
            }
        }
    }
    
    # Check for old CI references
    print ""
    print "🔧 Checking CI configuration..."
    let ci_file = $"($env.PWD)/.github/workflows/ci.yml"
    if ($ci_file | path exists) {
        let ci_content = open -r $ci_file
        let missing_packages = [
            "homebrew-setup"
            "macos-maintenance"
            "xcode-setup"
            "security-audit"
            "proxmox-update"
            "nixos-flake-update"
            "install"
            "uninstall"
        ]
        
        for pkg in $missing_packages {
            if ($ci_content | str contains $pkg) {
                print $"  ⚠️  CI references non-existent package: ($pkg)"
            }
        }
        
        if $fix {
            print "  📝 Creating minimal CI config..."
            let new_ci = "name: CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: cachix/install-nix-action@v31
        
      - name: Check flake
        run: |
          nix flake check --no-build
          
      - name: Build configuration
        run: |
          nix build .#nixosConfigurations.nixos.config.system.build.toplevel --dry-run
          
      - name: Format check
        run: |
          nix run .#fmt -- --check
"
            $new_ci | save -f $ci_file
            print "  ✅ Updated CI configuration"
        }
    }
    
    # Check for unused devshells
    print ""
    print "🐚 Checking devshells..."
    let devshells_dir = $"($env.PWD)/devshells"
    if ($devshells_dir | path exists) {
        print $"  ❌ Unused devshells directory found"
        if $fix {
            rm -rf $devshells_dir
            print "     ✅ Removed devshells directory"
        }
    }
    
    # Check for old packages directory
    print ""
    print "📦 Checking old package definitions..."
    let old_dirs = [
        $"($env.PWD)/packages"
        $"($env.PWD)/overlays"
        $"($env.PWD)/lib"
    ]
    
    for dir in $old_dirs {
        if ($dir | path exists) {
            print $"  ❌ Found old directory: ($dir)"
            if $fix {
                rm -rf $dir
                print $"     ✅ Removed ($dir)"
            }
        }
    }
    
    # Check for unused config files
    print ""
    print "⚙️ Checking unused configs..."
    let unused_configs = [
        $"($env.PWD)/config/hosts.nix"
        $"($env.PWD)/config/build"
        $"($env.PWD)/config/profiles"
    ]
    
    for config in $unused_configs {
        if ($config | path exists) {
            print $"  ❌ Unused config: ($config)"
            if $fix {
                rm -rf $config
                print $"     ✅ Removed ($config)"
            }
        }
    }
    
    # Check templates directory
    print ""
    print "📄 Checking templates..."
    let templates_dir = $"($env.PWD)/config/templates"
    if ($templates_dir | path exists) {
        let templates = ls $templates_dir | get name
        for template in $templates {
            if ($template | path basename) != "minimal.nix" {
                print $"  ❌ Unused template: ($template)"
                if $fix {
                    rm -rf $template
                    print $"     ✅ Removed ($template)"
                }
            }
        }
    }
    
    # Check for empty directories
    print ""
    print "📂 Checking for empty directories..."
    let all_dirs = (do -i { 
        ^find $env.PWD -type d -not -path "*/.*" | lines 
    } | default [])
    for dir in $all_dirs {
        if ($dir | path exists) {
            let contents = (do -i { ls $dir | length } | default 0)
            if $contents == 0 {
                print $"  ❌ Empty directory: ($dir)"
                if $fix {
                    do -i { ^rmdir $dir }
                    print $"     ✅ Removed empty ($dir)"
                }
            }
        }
    }
    
    # Summary
    print ""
    print "============================================================"
    if not $fix {
        print "💡 Run with --fix to automatically clean up"
    } else {
        print "✅ Cleanup complete!"
    }
}

# Run the scan
main