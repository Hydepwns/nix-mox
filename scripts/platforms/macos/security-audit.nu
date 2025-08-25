#!/usr/bin/env nu

# Import unified libraries
use ../../lib/validators.nu
use ../../lib/logging.nu


# nix-mox macOS Security Audit Script
# This script performs a basic security audit of macOS settings

def main [] {
    print "🔒 Running macOS security audit..."

    # Check if we're on macOS
    if (sys | get host.name) != "Darwin" {
        error make {msg: "This script is only for macOS systems"}
    }

    # Check firewall status
    print "🔥 Checking firewall status..."
    check-firewall

    # Check Gatekeeper status
    print "🚪 Checking Gatekeeper status..."
    check-gatekeeper

    # Check SIP status
    print "🛡️  Checking System Integrity Protection..."
    check-sip

    # Check FileVault status
    print "🔐 Checking FileVault status..."
    check-filevault

    print "✅ Security audit complete!"
}

def check-firewall [] {
    let firewall_status = (sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate)
    print $"Firewall status: ($firewall_status)"

    if ($firewall_status | str contains "enabled") {
        print "✅ Firewall is enabled"
    } else {
        print "⚠️  Firewall is disabled"
        print "Enable with: sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on"
    }
}

def check-gatekeeper [] {
    let gatekeeper_status = (spctl --status)
    print $"Gatekeeper status: ($gatekeeper_status)"

    if ($gatekeeper_status | str contains "enabled") {
        print "✅ Gatekeeper is enabled"
    } else {
        print "⚠️  Gatekeeper is disabled"
    }
}

def check-sip [] {
    let sip_status = (csrutil status)
    print $"SIP status: ($sip_status)"

    if ($sip_status | str contains "enabled") {
        print "✅ System Integrity Protection is enabled"
    } else {
        print "⚠️  System Integrity Protection is disabled"
    }
}

def check-filevault [] {
    let filevault_status = (fdesetup status)
    print $"FileVault status: ($filevault_status)"

    if ($filevault_status | str contains "On") {
        print "✅ FileVault is enabled"
    } else {
        print "⚠️  FileVault is disabled"
        print "Enable with: sudo fdesetup enable"
    }
}

# Run main function
main
