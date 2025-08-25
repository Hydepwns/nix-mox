#!/usr/bin/env nu
# Automated migration script for converting legacy unified libraries to consolidated libraries
# This script performs systematic find/replace operations across the codebase

use lib/logging.nu *

# Define migration patterns
const MIGRATION_PATTERNS = [
    # Primary library replacements
    {
        old: "use ../lib/validators.nu",
        new: "use ../lib/validators.nu",
        description: "Replace unified-checks with validators"
    },
    {
        old: "use ../../lib/validators.nu",
        new: "use ../../lib/validators.nu",
        description: "Replace unified-checks with validators (nested)"
    },
    {
        old: "use ../../../lib/validators.nu",
        new: "use ../../../lib/validators.nu",
        description: "Replace unified-checks with validators (deeply nested)"
    },
    {
        old: "use ../lib/logging.nu",
        new: "use ../lib/logging.nu",
        description: "Replace unified-error-handling with logging"
    },
    {
        old: "use ../../lib/logging.nu",
        new: "use ../../lib/logging.nu",
        description: "Replace unified-error-handling with logging (nested)"
    },
    {
        old: "use ../../../lib/logging.nu",
        new: "use ../../../lib/logging.nu",
        description: "Replace unified-error-handling with logging (deeply nested)"
    },
    {
        old: "use ../lib/logging.nu",
        new: "use ../lib/logging.nu",
        description: "Replace unified-logging with logging"
    },
    {
        old: "use ../../lib/logging.nu",
        new: "use ../../lib/logging.nu",
        description: "Replace unified-logging with logging (nested)"
    },
    {
        old: "use ../../../lib/logging.nu",
        new: "use ../../../lib/logging.nu",
        description: "Replace unified-logging with logging (deeply nested)"
    },
    {
        old: "use ../lib/logging.nu",
        new: "use ../lib/logging.nu",
        description: "Replace common with logging"
    },
    {
        old: "use ../../lib/logging.nu",
        new: "use ../../lib/logging.nu",
        description: "Replace common with logging (nested)"
    },
    {
        old: "use lib/testing.nu",
        new: "use lib/testing.nu",
        description: "Replace test-common with testing"
    },
    {
        old: "use ../lib/testing.nu",
        new: "use ../lib/testing.nu",
        description: "Replace test-common with testing"
    },
    {
        old: "use ../../lib/testing.nu",
        new: "use ../../lib/testing.nu",
        description: "Replace test-common with testing (nested)"
    },
    # Function name replacements
    {
        old: "validate_command",
        new: "validate_command",
        description: "Replace validate_command with validate_command"
    },
    {
        old: "validate_file",
        new: "validate_file",
        description: "Replace validate_file with validate_file"
    },
    {
        old: "validate_directory",
        new: "validate_directory",
        description: "Replace validate_directory with validate_directory"
    },
    {
        old: "validate_permissions",
        new: "validate_permissions",
        description: "Replace validate_permissions with validate_permissions"
    },
    {
        old: "validate_prerequisites",
        new: "validate_prerequisites",
        description: "Replace validate_prerequisites with validate_prerequisites"
    },
    {
        old: "detect_platform",
        new: "detect_platform",
        description: "Replace detect_platform with detect_platform"
    },
    {
        old: "validate_nix_environment",
        new: "validate_nix_environment",
        description: "Replace validate_nix_environment with validate_nix_environment"
    },
    {
        old: "error",
        new: "error",
        description: "Replace error with error"
    },
    {
        old: "error",
        new: "error",
        description: "Replace error with error"
    },
    {
        old: "info",
        new: "info",
        description: "Replace info with info"
    },
    {
        old: "warn",
        new: "warn",
        description: "Replace warn with warn"
    },
    {
        old: "error",
        new: "error",
        description: "Replace error with error"
    },
    {
        old: "success",
        new: "success",
        description: "Replace success with success"
    },
    {
        old: "debug",
        new: "debug",
        description: "Replace debug with debug"
    },
    {
        old: "trace",
        new: "trace",
        description: "Replace trace with trace"
    },
    {
        old: "critical",
        new: "critical",
        description: "Replace critical with critical"
    },
    {
        old: "log",
        new: "log",
        description: "Replace log with log"
    }
]

# Function to check if a file needs migration
def validate_file_needs_migration [file_path: string] {
    let content = (open $file_path)
    
    $MIGRATION_PATTERNS | any { |pattern|
        $content | str contains $pattern.old
    }
}

# Function to apply migrations to content
def apply_migrations [content: string] {
    $MIGRATION_PATTERNS | reduce --fold $content { |pattern, acc|
        $acc | str replace --all $pattern.old $pattern.new
    }
}

# Function to migrate a single file
def migrate_file [file_path: string] {
    debug $"Processing: ($file_path)" --context "migration"
    
    let original_content = (open $file_path)
    let modified_content = (apply_migrations $original_content)
    
    if $original_content != $modified_content {
        $modified_content | save -f $file_path
        success $"✓ Migrated: ($file_path)" --context "migration"
        return { status: "migrated", file: $file_path }
    } else {
        debug $"  No changes needed: ($file_path)" --context "migration"
        return { status: "skipped", file: $file_path }
    }
}

# Process a single file in dry-run mode
def dry_run_file [file_path: string] {
    let content = (open $file_path)
    
    let changes = ($MIGRATION_PATTERNS | where { |pattern|
        $content | str contains $pattern.old
    })
    
    if ($changes | length) > 0 {
        info $"Would migrate: ($file_path)" --context "migration"
        $changes | each { |pattern|
            trace $"  Would apply: ($pattern.description)" --context "migration"
        }
        return { status: "would_migrate", file: $file_path, changes: $changes }
    } else {
        return { status: "would_skip", file: $file_path, changes: [] }
    }
}

# Main migration function
def main [
    --dry-run  # Show what would be changed without modifying files
    --pattern: string = "*.nu"  # File pattern to process
    --directory: string = "scripts"  # Directory to process
] {
    banner "Consolidated Library Migration" "Migrating legacy unified libraries to modern consolidated libraries" --context "migration"
    
    if $dry_run {
        warn "DRY RUN MODE - No files will be modified" --context "migration"
    }
    
    # Find all .nu files in the specified directory
    info $"Searching for ($pattern) files in ($directory)..." --context "migration"
    let files = (glob $"($directory)/**/*.nu" | where { |f| 
        not ($f | str contains "scripts/lib/")  # Skip library files
    } | sort)
    
    info $"Found ($files | length) files to process" --context "migration"
    
    # Process each file
    let results = if $dry_run {
        $files | each { |file|
            try {
                dry_run_file $file
            } catch { |err|
                error $"Failed to process ($file): ($err.msg)" --context "migration"
                { status: "error", file: $file, error: $err.msg }
            }
        }
    } else {
        $files | each { |file|
            try {
                migrate_file $file
            } catch { |err|
                error $"Failed to migrate ($file): ($err.msg)" --context "migration"
                { status: "error", file: $file, error: $err.msg }
            }
        }
    }
    
    # Calculate summary statistics
    let migrated_count = if $dry_run {
        $results | where status == "would_migrate" | length
    } else {
        $results | where status == "migrated" | length
    }
    
    let skipped_count = if $dry_run {
        $results | where status == "would_skip" | length
    } else {
        $results | where status == "skipped" | length
    }
    
    let error_count = ($results | where status == "error" | length)
    
    # Summary
    section "Migration Summary" --context "migration"
    if $dry_run {
        info $"Would migrate: ($migrated_count) files" --context "migration"
        info $"Would skip: ($skipped_count) files" --context "migration"
    } else {
        success $"Migrated: ($migrated_count) files" --context "migration"
        info $"Skipped: ($skipped_count) files (no changes needed)" --context "migration"
    }
    
    if $error_count > 0 {
        error $"Errors: ($error_count) files" --context "migration"
    }
    
    # Suggest next steps
    section "Next Steps" --context "migration"
    info "1. Run tests to verify migrated scripts: make test" --context "migration"
    info "2. Check for any manual fixes needed: grep -r 'unified-' scripts/" --context "migration"
    info "3. Remove legacy libraries when ready: rm scripts/lib/unified-*.nu" --context "migration"
    
    if $error_count > 0 {
        exit 1
    }
}

# Run with help if requested
if ($env.HELP? | default false) {
    print "Usage: nu migrate-to-consolidated.nu [OPTIONS]"
    print ""
    print "Options:"
    print "  --dry-run     Show what would be changed without modifying files"
    print "  --pattern     File pattern to process (default: *.nu)"
    print "  --directory   Directory to process (default: scripts)"
    print ""
    print "Examples:"
    print "  # Dry run to see what would change"
    print "  nu migrate-to-consolidated.nu --dry-run"
    print ""
    print "  # Migrate all .nu files in scripts directory"
    print "  nu migrate-to-consolidated.nu"
    print ""
    print "  # Migrate specific directory"
    print "  nu migrate-to-consolidated.nu --directory scripts/testing"
    exit 0
}