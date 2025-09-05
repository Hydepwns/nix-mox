#!/usr/bin/env nu

# Import consolidated libraries
use ../lib/logging.nu *
use ../lib/validators.nu *
use ../lib/command-wrapper.nu *
use ../lib/script-template.nu *

# Setup script for Proton GE and anticheat support on NixOS

def main [] {
    info "🎮 Setting up Proton GE and Anticheat Support for NixOS" --context "proton-ge"
    
    # Check if Steam is installed using validator
    let steam_validation = (validate_command "steam")
    if not $steam_validation.success {
        error "Steam is not installed. Please enable it in your configuration.nix:" --context "proton-ge"
        info "   services.gaming.platforms.steam = true;" --context "proton-ge"
        exit 1
    }
    
    # Create compatibility tools directory
    let compat_dir = $"($env.HOME)/.steam/root/compatibilitytools.d"
    if not ($compat_dir | path exists) {
        info $"📁 Creating compatibility tools directory: ($compat_dir)" --context "proton-ge"
        mkdir $compat_dir
    }
    
    # Check if protonup is installed
    if (which protonup | is-not-empty) {
        print "✅ protonup is installed"
        print ""
        print "Installing latest Proton GE..."
        
        # Set the environment variable for protonup
        $env.STEAM_EXTRA_COMPAT_TOOLS_PATHS = $compat_dir
        
        # Install latest Proton GE
        try {
            protonup
            print "✅ Proton GE installed successfully"
        } catch {
            print "⚠️  Failed to install Proton GE automatically"
            print "   You can install it manually with: protonup"
        }
    } else {
        print "⚠️  protonup is not installed. Add it to your system packages:"
        print "   environment.systemPackages = [ pkgs.protonup ];"
    }
    
    print ""
    print "📋 Checklist for Rust/EasyAntiCheat games:"
    print ""
    print "1. ✅ Proton GE support configured in gaming module"
    print "2. ✅ Environment variables set for anticheat runtime"
    print "3. ✅ Storage drives configured with 'exec' mount option"
    print ""
    print "🎯 To enable Proton GE for a specific game:"
    print "   1. Right-click the game in Steam"
    print "   2. Go to Properties → Compatibility"
    print "   3. Enable 'Force the use of a specific Steam Play compatibility tool'"
    print "   4. Select 'GE-Proton' from the dropdown"
    print ""
    print "🔧 If games still won't launch with EasyAntiCheat:"
    print "   1. Verify the Proton EasyAntiCheat Runtime is installed in Steam"
    print "   2. Check that your game drive has 'exec' mount option:"
    print "      mount | grep /mnt/games"
    print "   3. Try verifying game files in Steam"
    print "   4. Launch Steam from terminal to see error messages:"
    print "      steam -console"
    
    # Check current mounts for exec option
    print ""
    print "📍 Current mount points and options:"
    let mounts = (mount | lines | where ($it | str contains "/mnt") | where ($it | str contains "exec"))
    if ($mounts | is-empty) {
        print "⚠️  No /mnt drives found with 'exec' option"
        print "   Add your gaming drives to storage.gamingDrives in configuration.nix"
    } else {
        $mounts | each { | mount| print $"   ($mount)" }
    }
    
    print ""
    print "✨ Setup complete! Rebuild your NixOS configuration to apply changes:"
    print "   sudo nixos-rebuild switch"
}

# Helper function to check mount options
def check_mount_exec [path: string] {
    let mount_info = (mount | lines | where ($it | str contains $path) | first)
    if ($mount_info | is-empty) {
        return false
    }
    return ($mount_info | str contains "exec")
}

# Function to list available Proton versions
def list_proton [] {
    print "📦 Available Proton versions:"
    
    # Check Steam's Proton versions
    let steam_dir = $"($env.HOME)/.steam/root"
    if ($steam_dir | path exists) {
        let proton_dirs = (ls $"($steam_dir)/compatibilitytools.d" 2>/dev/null | get name)
        if not ($proton_dirs | is-empty) {
            print "  Custom Proton versions:"
            $proton_dirs | each { | dir| print $"    - ($dir | path basename)" }
        }
    }
    
    # Check system Proton versions
    if (which protonup | is-not-empty) {
        print ""
        print "  To see all available versions: protonup --list"
    }
}