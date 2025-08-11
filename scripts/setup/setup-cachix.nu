#!/usr/bin/env nu

# Setup script for Cachix credentials
# This script helps you configure Cachix for your nix-mox project

def main [] {
    print "🔧 nix-mox Cachix Setup"
    print "========================"

    # Check if cachix is installed
    if (which cachix | is-empty) {
        print "❌ Cachix is not installed. Please install it first:"
        print "   nix-env -iA cachix -f https://cachix.org/api/v1/install"
        exit 1
    }
    print "✅ Cachix is installed"

    # Check if user is logged in
    let auth_status = (cachix whoami 2>/dev/null | str trim)
    if ($auth_status | is-empty) {
        print "❌ You are not logged in to Cachix"
        print "   Please run: cachix authtoken <your-token>"
        print ""
        print "To get your auth token:"
        print "1. Go to https://app.cachix.org/"
        print "2. Log in to your account"
        print "3. Go to your nix-mox cache"
        print "4. Navigate to Settings → Auth Tokens"
        print "5. Generate a new token"
        exit 1
    }
    print $"✅ Logged in as: ($auth_status)"

    # Check if nix-mox cache exists
    let cache_exists = (cachix list | str contains "nix-mox")
    if not $cache_exists {
        print "❌ nix-mox cache not found in your account"
        print "   Please create it at https://app.cachix.org/"
        exit 1
    }
    print "✅ nix-mox cache found"

    # Get cache info
    print ""
    print "📋 Cache Information:"
    print "====================="
    let cache_info = (cachix show nix-mox)
    print $cache_info

    # Get signing key
    print ""
    print "🔑 Signing Key:"
    print "=============="
    let signing_key = (cachix show nix-mox | lines | where ($it | str starts-with "Public key:") | first | str replace "Public key: " "")
    print $"Signing Key: ($signing_key)"

    # Get auth token
    print ""
    print "🎫 Auth Token:"
    print "============="
    print "To get your auth token, run: cachix authtoken"
    print ""

    print "📝 GitHub Secrets Setup:"
    print "========================"
    print "Add these secrets to your GitHub repository:"
    print ""
    print "1. Go to your repository on GitHub"
    print "2. Navigate to Settings → Secrets and variables → Actions"
    print "3. Add these secrets:"
    print ""
    print "   CACHIX_AUTH_TOKEN: (your auth token)"
    print $"   CACHIX_SIGNING_KEY: ($signing_key)"
    print ""
    print "✅ Setup complete!"
}

# Run the main function
main
