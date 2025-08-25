#!/usr/bin/env nu

# Import unified libraries
use ../../lib/validators.nu
use ../../lib/logging.nu


# nix-mox Xcode Setup Script
# This script helps set up Xcode command line tools on macOS

def main [] {
    print "🛠️  Setting up Xcode command line tools..."

    # Check if we're on macOS
    if (sys | get host.name) != "Darwin" {
        error make {msg: "This script is only for macOS systems"}
    }

    # Check if Xcode command line tools are installed
    if (xcode-select -p 2>/dev/null | is-empty) {
        print "❌ Xcode command line tools are not installed. Installing..."
        install-xcode-tools
    } else {
        print "✅ Xcode command line tools are already installed"
        let xcode_path = (xcode-select -p)
        print $"Path: ($xcode_path)"
    }

    # Check Xcode version
    print "📋 Checking Xcode version..."
    xcodebuild -version

    # Check available SDKs
    print "📦 Available SDKs:"
    xcodebuild -showsdks

    print "✅ Xcode setup complete!"
}

def install-xcode-tools [] {
    print "📥 Installing Xcode command line tools..."

    # Install Xcode command line tools
    xcode-select --install

    print "⏳ Installation started. Please complete the installation in the popup window."
    print "After installation, run this script again to verify the setup."
}

# Run main function
main
