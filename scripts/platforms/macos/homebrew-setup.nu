#!/usr/bin/env nu

# Import unified libraries
use ../../lib/validators.nu
use ../../lib/logging.nu


# nix-mox Homebrew Setup Script
# This script helps set up and manage Homebrew on macOS

def main [] {
    print "🍺 Setting up Homebrew for nix-mox..."

    # Check if we're on macOS
    if (sys | get host.name) != "Darwin" {
        error make {msg: "This script is only for macOS systems"}
    }

    # Check if Homebrew is installed
    if (which brew | is-empty) {
        print "❌ Homebrew is not installed. Installing Homebrew..."
        install_homebrew
    } else {
        print "✅ Homebrew is already installed"
    }

    # Update Homebrew
    print "🔄 Updating Homebrew..."
    brew update

    # Install common development tools
    print "📦 Installing common development tools..."
    let common_tools = ["git", "curl", "neovim", "chezmoi", "wget", "jq", "yq", "htop", "tmux", "zsh", "nu", "eza"]
    for tool in $common_tools {
        if (brew list | where name == $tool | is-empty) {
            print $"Installing ($tool)..."
            brew install $tool
        } else {
            print $"✅ ($tool) is already installed"
        }
    }

    # Add useful taps
    print "🔧 Adding useful Homebrew taps..."
    let taps = ["homebrew/cask", "homebrew/core", "homebrew/services"]
    for tap in $taps {
        if (brew tap | where name == $tap | is-empty) {
            print $"Adding tap ($tap)..."
            brew tap $tap
        } else {
            print $"✅ Tap ($tap) is already added"
        }
    }

    print "✅ Homebrew setup complete!"
    print ""
    print "Next steps:"
    print "1. Run 'brew doctor' to check for issues"
    print "2. Run 'brew outdated' to see outdated packages"
    print "3. Run 'brew upgrade' to upgrade packages"
}

def install_homebrew [] {
    print "📥 Installing Homebrew..."

    # Install Homebrew
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH
    if (sys | get host.arch) == "aarch64" {
        # Apple Silicon
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval (/opt/homebrew/bin/brew shellenv)
    } else {
        # Intel Mac
        echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
        eval (/usr/local/bin/brew shellenv)
    }

    print "✅ Homebrew installation complete"
}

# Run main function
main
