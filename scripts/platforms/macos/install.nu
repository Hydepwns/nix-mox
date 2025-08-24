#!/usr/bin/env nu

# Import unified libraries
use ../../lib/unified-checks.nu
use ../../lib/unified-error-handling.nu


# nix-mox macOS Installation Script
# This script handles the installation of nix-mox on macOS systems

def main [] {
    print "🍎 Installing nix-mox on macOS..."

    # Check if we're on macOS
    if (sys | get host.name) != "Darwin" {
        error make {msg: "This script is only for macOS systems"}
    }

    # Check architecture
    let arch = (sys | get host.arch)
    print $"Detected architecture: ($arch)"

    # Check if Nix is installed
    if (which nix | is-empty) {
        print "❌ Nix is not installed. Installing Nix first..."
        install-nix
    } else {
        print "✅ Nix is already installed"
    }

    # Check if Homebrew is installed (optional but recommended)
    if (which brew | is-empty) {
        print "⚠️  Homebrew is not installed. Consider installing it for additional tools."
        print "   Run: /bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    } else {
        print "✅ Homebrew is installed"
    }

    # Install nix-mox
    print "📦 Installing nix-mox..."
    nix profile install github:your-username/nix-mox

    print "✅ nix-mox installation complete!"
    print ""
    print "Next steps:"
    print "1. Run 'nix-mox-setup' to configure your environment"
    print "2. Run 'nix-mox-help' to see available commands"
    print "3. Check out the documentation at https://github.com/your-username/nix-mox"
}

def install-nix [] {
    print "📥 Installing Nix..."

    # Download and run the Nix installer
    curl -L https://nixos.org/nix/install | sh

    # Note: Nix will be available in new shell sessions
    # You may need to restart your terminal or run: source ~/.nix-profile/etc/profile.d/nix.sh
    print "✅ Nix installation complete. Restart your terminal or run: source ~/.nix-profile/etc/profile.d/nix.sh"
}

# Run main function
main
