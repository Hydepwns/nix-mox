#!/usr/bin/env nu

# Import unified libraries
use ../../lib/unified-checks.nu
use ../../lib/unified-error-handling.nu


# nix-mox macOS Uninstallation Script
# This script handles the uninstallation of nix-mox on macOS systems

def main [] {
    print "🗑️  Uninstalling nix-mox from macOS..."

    # Check if we're on macOS
    if (sys | get host.name) != "Darwin" {
        error make {msg: "This script is only for macOS systems"}
    }

    # Remove nix-mox from Nix profile
    print "📦 Removing nix-mox from Nix profile..."
    nix profile remove github:your-username/nix-mox

    # Clean up any remaining files
    print "🧹 Cleaning up remaining files..."
    cleanup-files

    print "✅ nix-mox uninstallation complete!"
    print ""
    print "Note: If you want to completely remove Nix, run:"
    print "sudo rm -rf /nix"
    print "sudo rm -rf ~/.nix-profile"
    print "sudo rm -rf ~/.nix-defexpr"
}

def cleanup-files [] {
    # Remove any nix-mox specific files
    rm -rf ~/.config/nix-mox
    rm -rf ~/.local/share/nix-mox

    print "✅ Cleanup complete"
}

# Run main function
main
