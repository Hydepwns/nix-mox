#!/usr/bin/env nu

# Linux-specific tests for nix-mox
# These tests verify Linux-only functionality

def main [] {
    print "🐧 Running Linux-specific tests..."

    # Check if we're on Linux
    if (sys | get host.name) != "Linux" {
        error make {msg: "These tests are only for Linux systems"}
    }

    # Test Linux-specific commands
    test-linux-commands

    # Test ZFS functionality (if available)
    test-zfs-functionality

    # Test systemd functionality
    test-systemd-functionality

    print "✅ Linux-specific tests completed successfully!"
}

def test-linux-commands [] {
    print "🔧 Testing Linux-specific commands..."

    # Test common Linux commands
    let commands = [
        "ls"
        "cat"
        "grep"
        "ps"
        "df"
        "mount"
    ]

    for cmd in $commands {
        if (which $cmd | is-empty) {
            print $"❌ Command ($cmd) not found"
        } else {
            print $"✅ Command ($cmd) available"
        }
    }
}

def test-zfs-functionality [] {
    print "💾 Testing ZFS functionality..."

    # Check if ZFS is available
    if (which zfs | is-empty) {
        print "⚠️  ZFS not available, skipping ZFS tests"
        return
    }

    # Test ZFS commands
    let zfs_commands = [
        "zfs"
        "zpool"
    ]

    for cmd in $zfs_commands {
        if (which $cmd | is-empty) {
            print $"❌ ZFS command ($cmd) not found"
        } else {
            print $"✅ ZFS command ($cmd) available"
        }
    }
}

def test-systemd-functionality [] {
    print "⚙️  Testing systemd functionality..."

    # Check if systemd is available
    if (which systemctl | is-empty) {
        print "⚠️  systemd not available, skipping systemd tests"
        return
    }

    # Test systemd commands
    let systemd_commands = [
        "systemctl"
        "journalctl"
        "loginctl"
    ]

    for cmd in $systemd_commands {
        if (which $cmd | is-empty) {
            print $"❌ systemd command ($cmd) not found"
        } else {
            print $"✅ systemd command ($cmd) available"
        }
    }
}

# Run main function
main
