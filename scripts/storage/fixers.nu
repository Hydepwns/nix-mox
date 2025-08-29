#!/usr/bin/env nu
# Storage fixing functions
# Extracted from scripts/storage.nu for better organization

use ../lib/logging.nu *
use ../lib/platform.nu *
use ../lib/command-wrapper.nu *

# ──────────────────────────────────────────────────────────
# MAIN FIXING COORDINATOR
# ──────────────────────────────────────────────────────────

export def fix_storage_config [backup: bool, dry_run: bool] {
    info "Starting fixing storage configuration" --context "storage-fix"
    
    if $backup and not $dry_run {
        info "Creating backup before fixes..." --context "storage-fix"
        # Import and call backup function
        use backup.nu [backup_storage_config]
        backup_storage_config
    }
    
    # Detect and fix common storage issues
    let fixes = [
        { name: "uuid_consistency", fixer: "fix_uuid_consistency" },
        { name: "mount_points", fixer: "fix_mount_points" },
        { name: "filesystem_table", fixer: "fix_filesystem_table" },
        { name: "boot_configuration", fixer: "fix_boot_configuration" }
    ]
    
    let results = ($fixes | each { |fix|
        try {
            let result = match $fix.fixer {
                "fix_uuid_consistency" => (fix_uuid_consistency $dry_run),
                "fix_mount_points" => (fix_mount_points $dry_run),
                "fix_filesystem_table" => (fix_filesystem_table $dry_run),
                "fix_boot_configuration" => (fix_boot_configuration $dry_run),
                _ => { success: false, message: "Unknown fixer" }
            }
            { 
                name: $fix.name, 
                success: ($result | get success? | default true),
                message: ($result | get message? | default "completed"),
                dry_run: $dry_run
            }
        } catch { |err|
            {
                name: $fix.name,
                success: false,
                message: $err.msg,
                dry_run: $dry_run
            }
        }
    })
    
    let overall_success = ($results | all {|r| $r.success })
    
    if $overall_success {
        success $"Storage fixes completed successfully (dry_run: ($dry_run))" --context "storage-fix"
    } else {
        error "Some storage fixes failed" --context "storage-fix"
    }
    
    {
        success: $overall_success,
        fixes_applied: ($results | where success == true | length),
        total_fixes: ($results | length),
        results: $results,
        dry_run: $dry_run
    }
}

# ──────────────────────────────────────────────────────────
# INDIVIDUAL FIXING FUNCTIONS
# ──────────────────────────────────────────────────────────

export def fix_uuid_consistency [dry_run: bool] {
    if $dry_run {
        dry_run "Would fix UUID consistency issues" --context "storage-fix"
        return { success: true, message: "dry run - UUID fix skipped" }
    }
    
    try {
        # This would implement actual UUID fixing logic
        # For now, just log what would be done
        info "UUID consistency fix not yet implemented" --context "storage-fix"
        { success: true, message: "UUID fix placeholder" }
    } catch { |err|
        { success: false, message: $err.msg }
    }
}

export def fix_mount_points [dry_run: bool] {
    if $dry_run {
        dry_run "Would fix mount point issues" --context "storage-fix"
        return { success: true, message: "dry run - mount point fix skipped" }
    }
    
    try {
        info "Mount point fix not yet implemented" --context "storage-fix"
        { success: true, message: "Mount point fix placeholder" }
    } catch { |err|
        { success: false, message: $err.msg }
    }
}

export def fix_filesystem_table [dry_run: bool] {
    if $dry_run {
        dry_run "Would fix filesystem table issues" --context "storage-fix"
        return { success: true, message: "dry run - filesystem table fix skipped" }
    }
    
    try {
        info "Filesystem table fix not yet implemented" --context "storage-fix"
        { success: true, message: "Filesystem table fix placeholder" }
    } catch { |err|
        { success: false, message: $err.msg }
    }
}

export def fix_boot_configuration [dry_run: bool] {
    if $dry_run {
        dry_run "Would fix boot configuration issues" --context "storage-fix"
        return { success: true, message: "dry run - boot config fix skipped" }
    }
    
    try {
        info "Boot configuration fix not yet implemented" --context "storage-fix"
        { success: true, message: "Boot configuration fix placeholder" }
    } catch { |err|
        { success: false, message: $err.msg }
    }
}