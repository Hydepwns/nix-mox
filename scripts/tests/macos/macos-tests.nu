#!/usr/bin/env nu

# macOS-specific tests for nix-mox
# These tests verify macOS-only functionality

def main [] {
    print "🍎 Running macOS-specific tests..."

    # Check if we're on macOS
    let os_info = (sys host | get long_os_version)
    if not ($os_info | str contains "macOS") {
        error make {msg: "These tests are only for macOS systems"}
    }

    # Test macOS-specific commands
    test-macos-commands

    # Test Homebrew functionality (if available)
    test-homebrew-functionality

    # Test Xcode functionality
    test-xcode-functionality

    # Test macOS security features
    test-macos-security

    print "✅ macOS-specific tests completed successfully!"
}

def test-macos-commands [] {
    print "🔧 Testing macOS-specific commands..."

    # Test common macOS commands
    let commands = [
        "sw_vers"
        "system_profiler"
        "defaults"
        "launchctl"
        "pmset"
        "ioreg"
    ]

    for cmd in $commands {
        if (which $cmd | is-empty) {
            print $"❌ Command ($cmd) not found"
        } else {
            print $"✅ Command ($cmd) available"
        }
    }
}

def test-homebrew-functionality [] {
    print "🍺 Testing Homebrew functionality..."

    # Check if Homebrew is available
    if (which brew | is-empty) {
        print "⚠️  Homebrew not available, skipping Homebrew tests"
        return
    }

    # Test Homebrew commands
    let brew_commands = [
        "brew"
        "mas"
    ]

    for cmd in $brew_commands {
        if (which $cmd | is-empty) {
            print $"❌ Homebrew command ($cmd) not found"
        } else {
            print $"✅ Homebrew command ($cmd) available"
        }
    }
}

def test-xcode-functionality [] {
    print "🛠️  Testing Xcode functionality..."

    # Check if Xcode command line tools are available
    if (which xcodebuild | is-empty) {
        print "⚠️  Xcode command line tools not available, skipping Xcode tests"
        return
    }

    # Test Xcode commands
    let xcode_commands = [
        "xcodebuild"
        "xcrun"
        "xcode-select"
    ]

    for cmd in $xcode_commands {
        if (which $cmd | is-empty) {
            print $"❌ Xcode command ($cmd) not found"
        } else {
            print $"✅ Xcode command ($cmd) available"
        }
    }
}

def test-macos-security [] {
    print "🔒 Testing macOS security features..."

    # Test security commands
    let security_commands = [
        "spctl"
        "csrutil"
        "fdesetup"
    ]

    for cmd in $security_commands {
        if (which $cmd | is-empty) {
            print $"❌ Security command ($cmd) not found"
        } else {
            print $"✅ Security command ($cmd) available"
        }
    }
}

# Run main function
main
