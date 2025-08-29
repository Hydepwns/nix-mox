#!/usr/bin/env nu

# Import unified libraries
use ../../lib/validators.nu
use ../../lib/logging.nu


# nix-mox macOS Maintenance Script
# This script performs common macOS system maintenance tasks

def main [] {
    print "🔧 Running macOS system maintenance..."

    # Check if we're on macOS
    if (sys | get host.name) != "Darwin" {
        error make {msg: "This script is only for macOS systems"}
    }

    # Clear system caches
    print "🧹 Clearing system caches..."
    clear_system_caches

    # Clean up Homebrew
    print "🍺 Cleaning up Homebrew..."
    clean_homebrew

    # Check disk space
    print "💾 Checking disk space..."
    check_disk_space

    print "✅ macOS maintenance complete!"
}

def clear_system_caches [] {
    # Clear various system caches
    sudo rm -rf /Library/Caches/*
    sudo rm -rf ~/Library/Caches/*
    sudo rm -rf /System/Library/Caches/*

    # Clear DNS cache
    sudo dscacheutil -flushcache
    sudo killall -HUP mDNSResponder

    print "✅ System caches cleared"
}

def clean_homebrew [] {
    if (which brew | is-empty) {
        print "⚠️  Homebrew not installed, skipping Homebrew cleanup"
        return
    }

    # Clean up Homebrew
    brew cleanup
    brew autoremove

    print "✅ Homebrew cleanup complete"
}

def check_disk_space [] {
    # Get disk usage information
    df -h | where Filesystem =~ "/dev/"

    print "✅ Disk space check complete"
}

# Run main function
main
