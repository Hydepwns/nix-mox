#!/usr/bin/env nu
# Storage backup and restore functions
# Extracted from scripts/storage.nu for better organization

use ../lib/logging.nu *
use ../lib/platform.nu *

# ──────────────────────────────────────────────────────────
# BACKUP AND RESTORE FUNCTIONS
# ──────────────────────────────────────────────────────────

export def backup_storage_config [] {
    info "Starting backing up storage configuration" --context "storage-backup"
    
    let backup_dir = "tmp/storage-backups"
    let timestamp = (date now | format date '%Y%m%d-%H%M%S')
    let backup_name = $"storage-backup-($timestamp)"
    let full_backup_path = $"($backup_dir)/($backup_name)"
    
    # Create backup directory
    if not ($backup_dir | path exists) {
        mkdir $backup_dir
    }
    mkdir $full_backup_path
    
    # Files to backup
    let config_files = [
        "config/hardware/hardware-configuration.nix",
        "config/nixos/configuration.nix"
    ]
    
    let system_files = [
        "/etc/fstab"
    ]
    
    # Backup configuration files
    for file in $config_files {
        if ($file | path exists) {
            cp $file $"($full_backup_path)/(($file | path basename))"
            debug $"Backed up: ($file)" --context "storage-backup"
        }
    }
    
    # Backup system files (if accessible)
    for file in $system_files {
        try {
            cp $file $"($full_backup_path)/(($file | path basename))"
            debug $"Backed up: ($file)" --context "storage-backup"
        } catch {
            warn $"Could not backup system file: ($file)" --context "storage-backup"
        }
    }
    
    # Create backup metadata
    let metadata = {
        timestamp: (date now),
        platform: (get_platform | get normalized),
        files: ($config_files | append $system_files),
        backup_path: $full_backup_path
    }
    
    $metadata | to json | save $"($full_backup_path)/metadata.json"
    
    success $"Storage configuration backed up: ($full_backup_path)" --context "storage-backup"
    
    {
        success: true,
        backup_path: $full_backup_path,
        files_backed_up: ($config_files | length),
        metadata: $metadata
    }
}

export def restore_storage_config [] {
    info "Starting restoring storage configuration" --context "storage-restore"
    
    let backup_dir = "tmp/storage-backups"
    
    if not ($backup_dir | path exists) {
        error "No backup directory found" --context "storage-restore"
        return { success: false, message: "no backups available" }
    }
    
    # Find most recent backup
    let backups = (ls $backup_dir | where type == "dir" | sort-by modified | reverse)
    
    if ($backups | length) == 0 {
        error "No backups found" --context "storage-restore"
        return { success: false, message: "no backups found" }
    }
    
    let latest_backup = ($backups | first)
    let backup_path = $latest_backup.name
    
    info $"Restoring from backup: ($backup_path)" --context "storage-restore"
    
    # Restore files
    try {
        if ($"($backup_path)/hardware-configuration.nix" | path exists) {
            cp $"($backup_path)/hardware-configuration.nix" "config/hardware/hardware-configuration.nix"
        }
        
        if ($"($backup_path)/configuration.nix" | path exists) {
            cp $"($backup_path)/configuration.nix" "config/nixos/configuration.nix"
        }
        
        success "Storage configuration restored successfully" --context "storage-restore"
        
        {
            success: true,
            restored_from: $backup_path,
            timestamp: $latest_backup.modified
        }
    } catch { | err|
        error $"Failed to restore configuration: ($err.msg)" --context "storage-restore"
        { success: false, message: $err.msg }
    }
}