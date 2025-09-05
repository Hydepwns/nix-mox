#!/usr/bin/env nu

# Import unified libraries
use ../../lib/logging.nu *

# Windows/WSL-specific tests for nix-mox
# These tests verify Windows/WSL-only functionality

def main [] {
    print "🪟 Running Windows/WSL-specific tests..."

    # Robust platform detection
    let sysinfo = sys
    let platform = (
        if ($sysinfo | describe) == 'record' and ($sysinfo | columns | any {| c| $c == 'host'}) {
            $sysinfo.hostname
        } else {
            $sysinfo
        }
    )
    print ("Detected platform: " + $platform)

    # Test Windows/WSL-specific commands
    test_windows_commands
    test_nushell
    test_nix

    print "✅ Windows/WSL-specific tests completed successfully!"
}

def test_windows_commands [] {
    print "🔧 Testing Windows/WSL-specific commands..."
    let commands = ["powershell", "cmd", "wsl", "python", "python3"]

    for cmd in $commands {
        if (which $cmd | is-empty) {
            print ("❌ Command " + $cmd + " not found")
        } else {
            print ("✅ Command " + $cmd + " available")
        }
    }
}

def test_nushell [] {
    print "🐚 Testing Nushell..."
    print ("Nushell version: " + (version | get version))
    print "✅ Nushell is working"
}

def test_nix [] {
    print "🧪 Testing Nix installation..."

    if (which nix | is-empty) {
        print "❌ Nix is not installed"
    } else {
        print "✅ Nix is installed"
        nix --version
    }
}

# Run main function
main
