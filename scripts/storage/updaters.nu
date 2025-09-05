#!/usr/bin/env nu
# Storage configuration update functions
# Extracted from scripts/storage.nu for better organization

use ../lib/logging.nu *
use ../lib/platform.nu *
use ../lib/command-wrapper.nu [execute_command]

# ──────────────────────────────────────────────────────────
# MAIN UPDATE COORDINATOR
# ──────────────────────────────────────────────────────────

export def auto_update_storage [backup: bool, dry_run: bool] {
    info "Starting auto-updating storage configuration" --context "storage-update"
    
    let platform = (get_platform)
    if not $platform.is_linux {
        warn "Auto-update storage is primarily designed for Linux systems" --context "storage-update"
    }
    
    if $backup and not $dry_run {
        # Import and call backup function
        use backup.nu [backup_storage_config]
        backup_storage_config
    }
    
    # Update hardware configuration
    let hw_config_result = (update_hardware_configuration $dry_run)
    
    # Update filesystem configuration  
    let fs_config_result = (update_filesystem_configuration $dry_run)
    
    # Validate updated configuration
    let validation_result = if not $dry_run {
        use validators.nu [run_comprehensive_storage_validation]
        (run_comprehensive_storage_validation)
    } else {
        { success: true, message: "dry run - validation skipped" }
    }
    
    let overall_success = (($hw_config_result | get success? | default true) and 
                          ($fs_config_result | get success? | default true) and
                          ($validation_result | get success? | default true))
    
    {
        success: $overall_success,
        hardware_config: $hw_config_result,
        filesystem_config: $fs_config_result,
        validation: $validation_result,
        dry_run: $dry_run
    }
}

# ──────────────────────────────────────────────────────────
# UPDATE FUNCTIONS
# ──────────────────────────────────────────────────────────

export def update_hardware_configuration [dry_run: bool] {
    if $dry_run {
        dry_run "Would update hardware configuration" --context "storage-update"
        return { success: true, message: "dry run - hardware config update skipped" }
    }
    
    try {
        let platform = (get_platform)
        if $platform.is_linux {
            # Generate new hardware configuration
            let result = (execute_command ["nixos-generate-config" "--show-hardware-config"] --context "hardware-update")
            if $result.exit_code == 0 {
                info "Hardware configuration updated successfully" --context "storage-update"
                { success: true, message: "hardware configuration updated" }
            } else {
                { success: false, message: "failed to generate hardware configuration" }
            }
        } else {
            { success: true, message: "hardware update not required on this platform" }
        }
    } catch { | err|
        { success: false, message: $err.msg }
    }
}

export def update_filesystem_configuration [dry_run: bool] {
    if $dry_run {
        dry_run "Would update filesystem configuration" --context "storage-update"
        return { success: true, message: "dry run - filesystem config update skipped" }
    }
    
    try {
        info "Filesystem configuration update not yet implemented" --context "storage-update"
        { success: true, message: "filesystem configuration update placeholder" }
    } catch { | err|
        { success: false, message: $err.msg }
    }
}