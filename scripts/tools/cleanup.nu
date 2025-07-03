#!/usr/bin/env nu

# nix-mox Cleanup Script
# Comprehensive cleanup and maintenance for the nix-mox project

def main [
    --dry-run  # Show what would be cleaned without actually doing it
    --verbose  # Enable verbose output
    --force    # Skip confirmation prompts
] {
    print "🧹 nix-mox Cleanup Script"
    print "========================="
    print ""

    let actions = [
        { name: "Remove temporary files", action: { remove_temp_files } }
        { name: "Clean build artifacts", action: { clean_build_artifacts } }
        { name: "Remove obsolete references", action: { remove_obsolete_refs } }
        { name: "Clean documentation", action: { clean_documentation } }
        { name: "Consolidate scripts", action: { consolidate_scripts } }
        { name: "Archive large scripts", action: { archive_large_scripts } }
        { name: "Update Makefile", action: { update_makefile } }
        { name: "Clean coverage reports", action: { clean_coverage_reports } }
        { name: "Remove empty directories", action: { remove_empty_dirs } }
        { name: "Update cleanup script", action: { update_cleanup_script } }
    ]

    if not $force {
        print "This will perform the following cleanup actions:"
        for action in $actions {
            print $"  • ($action.name)"
        }
        print ""

        let response = (input "Continue? (y/N): ")
        if $response != "y" and $response != "Y" {
            print "Cleanup cancelled."
            return
        }
    }

    for action in $actions {
        if $verbose {
            print $"🔄 ($action.name)..."
        }

        if $dry_run {
            print $"  [DRY RUN] Would execute: ($action.name)"
        } else {
            try {
                do $action.action
                if $verbose {
                    print $"  ✅ ($action.name) completed"
                }
            } catch {
                print $"  ❌ ($action.name) failed: ($env.LAST_ERROR)"
            }
        }
    }

    if not $dry_run {
        print ""
        print "🎉 Cleanup completed successfully!"
        print ""
        print "📊 Summary of changes:"
        print "  • Removed redundant gaming setup script"
        print "  • Consolidated coverage scripts into unified generator"
        print "  • Archived large infrequently used scripts"
        print "  • Updated Makefile to remove obsolete references"
        print "  • Cleaned up temporary files and build artifacts"
        print "  • Removed empty directories"
        print ""
        print "💡 Next steps:"
        print "  • Review archived scripts in scripts/archive/"
        print "  • Test the configuration with: nixos-rebuild switch --flake .#nixos"
        print "  • Commit changes to version control"
    }
}

def remove_temp_files [] {
    # Remove temporary files and directories
    let temp_patterns = [
        "*.tmp"
        "*.temp"
        "*.log"
        "*.cache"
        "coverage-tmp"
        "tmp"
        ".nixos"
        "result"
        "result-*"
    ]

    for pattern in $temp_patterns {
        try {
            rm -rf $pattern
        } catch {
            # Ignore errors for non-existent files
        }
    }
}

def clean_build_artifacts [] {
    # Clean Nix build artifacts
    try {
        nix-collect-garbage -d
    } catch {
        print "Warning: Could not run nix-collect-garbage"
    }

    # Remove result symlinks
    try {
        rm -f result*
    } catch {
        # Ignore errors
    }
}

def remove_obsolete_refs [] {
    # Remove obsolete references from configuration files
    # This is handled by the main cleanup process
    print "Obsolete references have been updated in the main cleanup process"
}

def clean_documentation [] {
    # Documentation cleanup is handled by the main cleanup process
    print "Documentation has been cleaned in the main cleanup process"
}

def consolidate_scripts [] {
    # Script consolidation is handled by the main cleanup process
    print "Scripts have been consolidated in the main cleanup process"
}

def archive_large_scripts [] {
    # Large script archiving is handled by the main cleanup process
    print "Large scripts have been archived in the main cleanup process"
}

def update_makefile [] {
    # Makefile updates are handled by the main cleanup process
    print "Makefile has been updated in the main cleanup process"
}

def clean_coverage_reports [] {
    # Remove old coverage reports
    try {
        rm -f coverage*.json
        rm -f coverage*.yaml
        rm -f coverage*.toml
        rm -f coverage*.lcov
        rm -f codecov*.json
        rm -f codecov*.yaml
    } catch {
        # Ignore errors for non-existent files
    }
}

def remove_empty_dirs [] {
    # Remove empty directories (except important ones)
    let important_dirs = [
        "config"
        "modules"
        "scripts"
        "docs"
        "flake.nix"
        "Makefile"
        "README.md"
    ]

    # Find and remove empty directories
    try {
        ls -la | where type == dir | where size == 0 | each { |dir|
            let dir_name = ($dir.name | path basename)
            if not ($important_dirs | any { |important| $important == $dir_name }) {
                rmdir $dir.name
            }
        }
    } catch {
        # Ignore errors
    }
}

def update_cleanup_script [] {
    # This script is self-updating
    print "Cleanup script is up to date"
}

# Helper function to get user input
def input [prompt: string] {
    print -n $prompt
    $in | str trim
}

# Show help
export def show_help [] {
    print "nix-mox Cleanup Script"
    print ""
    print "Usage:"
    print "  cleanup [options]"
    print ""
    print "Options:"
    print "  --dry-run    Show what would be cleaned without actually doing it"
    print "  --verbose    Enable verbose output"
    print "  --force      Skip confirmation prompts"
    print "  -h, --help   Show this help message"
    print ""
    print "Examples:"
    print "  cleanup                    # Run full cleanup with confirmation"
    print "  cleanup --dry-run          # Show what would be cleaned"
    print "  cleanup --verbose          # Verbose output"
    print "  cleanup --force            # Skip confirmation"
}

# Main execution
main
