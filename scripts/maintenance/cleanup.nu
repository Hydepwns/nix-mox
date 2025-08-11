#!/usr/bin/env nu

# nix-mox Cleanup Script
# Performs various cleanup tasks to maintain the nix-mox configuration

def main [] {
    print "🧹 Starting nix-mox cleanup..."
    # Clean temporary build artifacts
    cleanup_temp_files
    # Clean old user/group entries
    cleanup_user_groups
    # Validate configuration consistency
    validate_configuration
    # Check for obsolete references
    check_obsolete_references
    print "✅ Cleanup completed!"
}

def cleanup_temp_files [] {
    print "📁 Cleaning temporary files..."
    # Remove build artifacts
    if ("tmp/result-*" | path exists) {
        rm -rf tmp/result-*
        print "  ✓ Removed build artifacts"
    }

    # Remove coverage temp files
    if ("coverage-tmp/nix-mox-tests/*" | path exists) {
        rm -rf coverage-tmp/nix-mox-tests/*
        print "  ✓ Removed coverage temp files"
    }

    # Remove result symlinks
    if ("result" | path exists) {
        rm -f result
        print "  ✓ Removed result symlink"
    }
}

def cleanup_user_groups [] {
    print "👥 Checking for old user/group entries..."
    # Check for old display manager users
    let old_users = ["lightdm", "gdm"]
    let old_groups = ["lightdm", "gdm"]

    for user in $old_users {
        if (id $user 2>/dev/null | str length) > 0 {
            print $"  ⚠️  Found old user: ($user) - consider removing manually"
        }
    }

    for group in $old_groups {
        if (getent group $group 2>/dev/null | str length) > 0 {
            print $"  ⚠️  Found old group: ($group) - consider removing manually"
        }
    }
}

def validate_configuration [] {
    print "🔍 Validating configuration consistency..."
    # Check for conflicting display managers
    let config_files = ["config/profiles/base.nix", "modules/templates/base/common.nix"]

    for file in $config_files {
        if ($file | path exists) {
            let content = open $file
            let lightdm_count = ($content | grep -c "lightdm" | into int)
            let sddm_count = ($content | grep -c "sddm" | into int)

            if $lightdm_count > 0 {
                print $"  ⚠️  Found ($lightdm_count) LightDM references in ($file)"
            }
            if $sddm_count > 0 {
                print $"  ✓ Found ($sddm_count) SDDM references in ($file)"
            }
        }
    }

    # Check for plasma5 vs plasma6 references
    let plasma5_count = (grep -r "plasma5" config/ modules/ | str length)
    let plasma6_count = (grep -r "plasma6" config/ modules/ | str length)

    if $plasma5_count > 0 {
        print $"  ⚠️  Found ($plasma5_count) plasma5 references"
    }
    if $plasma6_count > 0 {
        print $"  ✓ Found ($plasma6_count) plasma6 references"
    }
}

def check_obsolete_references [] {
    print "🔍 Checking for obsolete references..."
    # Check for removed desktop template and profile

    if ("config/templates/desktop.nix" | path exists) {
        print "  ⚠️  Found obsolete desktop.nix template"
    } else {
        print "  ✓ Obsolete desktop.nix template removed"
    }

    if ("config/profiles/desktop.nix" | path exists) {
        print "  ⚠️  Found obsolete desktop.nix profile"
    } else {
        print "  ✓ Obsolete desktop.nix profile removed"
    }

    # Check for old documentation references
    let docs_files = ["docs/guides/nixos-on-proxmox.md", "QUICK_START.md"]

    for file in $docs_files {
        if ($file | path exists) {
            let content = open $file
            let lightdm_refs = ($content | grep -c "lightdm" | into int)
            let plasma5_refs = ($content | grep -c "plasma5" | into int)

            if $lightdm_refs > 0 {
                print $"  ⚠️  Found ($lightdm_refs) LightDM references in ($file)"
            }
            if $plasma5_refs > 0 {
                print $"  ⚠️  Found ($plasma5_refs) plasma5 references in ($file)"
            }
        }
    }
}

# Show help
export def show_help [] {
    print "nix-mox Core Cleanup Script"
    print ""
    print "Usage:"
    print "  cleanup.nu                  # Run core cleanup"
    print "  cleanup.nu --help           # Show this help"
    print ""
    print "What it does:"
    print "  • Cleans temporary build artifacts"
    print "  • Checks for old user/group entries"
    print "  • Validates configuration consistency"
    print "  • Checks for obsolete references"
    print ""
    print "Examples:"
    print "  nu scripts/maintenance/cleanup.nu  # Run cleanup"
print "  nu scripts/maintenance/cleanup.nu --help  # Show help"
}

# Check for help flag
if ($env | get --ignore-errors ARGS | default [] | any { |arg| $arg == "--help" or $arg == "-h" }) {
    show_help
    exit 0
}

# Export the main function
export def cleanup [] {
    main
}
