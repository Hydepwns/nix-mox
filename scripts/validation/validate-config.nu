#!/usr/bin/env nu

# NixOS Configuration Validation Script
# Validates configuration before rebuilding

def main [] {
    print "🔍 Validating NixOS configuration..."
    
    # Check if we're in the right directory
    if not (ls | where name =~ "flake.nix" | length > 0) {
        error make {msg: "Not in nix-mox directory. Please run from the project root."}
    }
    
    # Check for syntax errors
    print "📝 Checking Nix syntax..."
    let syntax_check = (nix eval --file config/nixos/configuration.nix --raw 2>&1)
    if $syntax_check =~ "error:" {
        error make {msg: $"Syntax error found: ($syntax_check)"}
    } else {
        print "✅ Nix syntax is valid"
    }
    
    # Check for evaluation errors
    print "🔧 Checking configuration evaluation..."
    let eval_check = (nixos-rebuild dry-activate --flake .#nixos 2>&1)
    if $eval_check =~ "error:" {
        error make {msg: $"Configuration evaluation error: ($eval_check)"}
    } else {
        print "✅ Configuration evaluates successfully"
    }
    
    # Check for common issues
    print "🔍 Checking for common configuration issues..."
    
    # Check if X11 and Wayland are both enabled
    let x11_enabled = (grep -c "services.xserver.enable = true" config/nixos/configuration.nix | into int)
    let wayland_enabled = (grep -c "wayland = true" config/nixos/configuration.nix | into int)
    
    if $x11_enabled > 0 and $wayland_enabled > 0 {
        print "⚠️  Warning: Both X11 and Wayland appear to be enabled"
    }
    
    # Check for duplicate package managers
    let npm_count = (grep -c "nodePackages.npm" config/nixos/configuration.nix | into int)
    let pnpm_count = (grep -c "nodePackages.pnpm" config/nixos/configuration.nix | into int)
    let yarn_count = (grep -c "nodePackages.yarn" config/nixos/configuration.nix | into int)
    
    if ($npm_count + $pnpm_count + $yarn_count) > 1 {
        print "⚠️  Warning: Multiple Node.js package managers detected"
    }
    
    # Check for X11 tools in Wayland setup
    let x11_tools = (grep -c "glxinfo\|xrandr\|xset" config/nixos/configuration.nix | into int)
    if $x11_tools > 0 {
        print "⚠️  Warning: X11 tools detected in Wayland configuration"
    }
    
    # Check for missing dependencies
    print "📦 Checking for potential missing dependencies..."
    
    # Check if Niri is properly configured
    let niri_config = (grep -c "programs.niri" config/nixos/configuration.nix | into int)
    if $niri_config == 0 {
        print "⚠️  Warning: Niri configuration not found"
    }
    
    # Check for display manager configuration
    let gdm_config = (grep -c "services.displayManager.gdm" config/nixos/configuration.nix | into int)
    if $gdm_config == 0 {
        print "⚠️  Warning: Display manager configuration not found"
    }
    
    print "✅ Configuration validation complete!"
    print ""
    print "🚀 Ready to rebuild. Run: sudo nixos-rebuild switch --flake .#nixos"
}

# Run validation
main 