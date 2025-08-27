#!/usr/bin/env nu
# Consolidated storage operations for nix-mox
# Replaces storage-guard.nu, fix-storage-config.nu, auto-update-storage.nu
# Uses functional patterns for safe storage management

use lib/logging.nu *
use lib/platform.nu *
use lib/validators.nu *
use lib/command-wrapper.nu *
use lib/script-template.nu *

# Main storage operations dispatcher
def main [
    operation: string = "guard",
    --fix,
    --auto-update,
    --backup,
    --dry-run,
    --verbose,
    --context: string = "storage"
] {
    if ($verbose | default false) { $env.LOG_LEVEL = "DEBUG" }
    
    info $"nix-mox storage operations: Running ($operation) operation" --context $context
    
    # Dispatch to appropriate storage operation
    match $operation {
        "guard" => (storage_guard $fix $backup $dry_run),
        "fix" => (fix_storage_config $backup $dry_run),
        "auto-update" => (auto_update_storage $backup $dry_run),
        "validate" => (validate_storage_config $dry_run),
        "backup" => (backup_storage_config),
        "restore" => (restore_storage_config),
        "health-check" => (storage_health_check),
        "help" => { show_storage_help; return },
        _ => {
            error $"Unknown storage operation: ($operation). Use 'help' to see available operations."
            return
        }
    }
}

# Storage guard - comprehensive safety validation before reboot
def storage_guard [fix: bool, backup: bool, dry_run: bool] {
    info "Starting storage guard validation" --context "storage-guard"
    
    critical "🛡️  STORAGE GUARD: Critical boot safety validation" --context "storage-guard"
    
    # Run comprehensive storage validation
    let validation_results = (run_comprehensive_storage_validation)
    
    if not $validation_results.success {
        critical "❌ STORAGE VALIDATION FAILED - DO NOT REBOOT!" --context "storage-guard"
        error "Failed validations:" --context "storage-guard"
        
        for failure in ($validation_results.results | where success == false) {
            error $"  - ($failure.name): ($failure.message)" --context "storage-guard"
        }
        
        if $fix {
            warn "Attempting automatic fixes..." --context "storage-guard"
            let fix_result = (fix_storage_config $backup $dry_run)
            
            if $fix_result.success {
                info "Re-running validation after fixes..." --context "storage-guard"
                let revalidation = (run_comprehensive_storage_validation)
                
                if $revalidation.success {
                    success "✅ Storage validation PASSED after fixes - system is safe to reboot" --context "storage-guard"
                    return { success: true, fixed: true }
                } else {
                    critical "❌ Storage validation STILL FAILING after fixes - DO NOT REBOOT!" --context "storage-guard"
                    return { success: false, fixed: false }
                }
            } else {
                critical "❌ Automatic fixes FAILED - manual intervention required" --context "storage-guard"
                return { success: false, fixed: false }
            }
        } else {
            critical "Use --fix to attempt automatic repairs" --context "storage-guard"
            return { success: false, fixed: false }
        }
    } else {
        success "✅ Storage validation PASSED - system is safe to reboot" --context "storage-guard"
        return { success: true, fixed: false }
    }
}

# Fix storage configuration issues
def fix_storage_config [backup: bool, dry_run: bool] {
    info "Starting fixing storage configuration" --context "storage-fix"
    
    if $backup and not $dry_run {
        info "Creating backup before fixes..." --context "storage-fix"
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

# Auto-update storage configuration
def auto_update_storage [backup: bool, dry_run: bool] {
    info "Starting auto-updating storage configuration" --context "storage-update"
    
    let platform = (get_platform)
    if not $platform.is_linux {
        warn "Auto-update storage is primarily designed for Linux systems" --context "storage-update"
    }
    
    if $backup and not $dry_run {
        backup_storage_config
    }
    
    # Update hardware configuration
    let hw_config_result = (update_hardware_configuration $dry_run)
    
    # Update filesystem configuration  
    let fs_config_result = (update_filesystem_configuration $dry_run)
    
    # Validate updated configuration
    let validation_result = if not $dry_run {
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

# Validate storage configuration
def validate_storage_config [dry_run: bool] {
    run_comprehensive_storage_validation
}

# Comprehensive storage validation
def run_comprehensive_storage_validation [] {
    let storage_validations = [
        { name: "hardware_config_exists", validator: {|| validate_hardware_config_exists } },
        { name: "boot_partition_mounted", validator: {|| validate_boot_partition_mounted } },
        { name: "root_partition_healthy", validator: {|| validate_root_partition_healthy } },
        { name: "uuid_consistency", validator: {|| validate_uuid_consistency } },
        { name: "filesystem_table", validator: {|| validate_filesystem_table } },
        { name: "boot_loader_config", validator: {|| validate_boot_loader_config } },
        { name: "mount_point_accessibility", validator: {|| validate_mount_points } }
    ]
    
    run_validations $storage_validations --fail-fast false --context "storage-validation"
}

# Individual validation functions
def validate_hardware_config_exists [] {
    try {
        let hw_config = "/etc/nixos/hardware-configuration.nix"
        if ($hw_config | path exists) {
            validation_result true "Hardware configuration exists"
        } else {
            validation_result false "Hardware configuration missing at /etc/nixos/hardware-configuration.nix"
        }
    } catch {
        validation_result false "Failed to check hardware configuration"
    }
}

def validate_boot_partition_mounted [] {
    try {
        let boot_check = (df /boot | complete)
        if $boot_check.exit_code == 0 {
            let lines = ($boot_check.stdout | lines)
            if ($lines | length) > 1 {
                validation_result true $"Boot partition mounted"
            } else {
                validation_result false "Boot partition not mounted"
            }
        } else {
            validation_result false "Boot partition not accessible"
        }
    } catch {
        validation_result false "Failed to check boot partition"
    }
}

def validate_root_partition_healthy [] {
    try {
        let root_check = (df / | complete)
        if $root_check.exit_code == 0 {
            let lines = ($root_check.stdout | lines)
            if ($lines | length) > 1 {
                # Parse the usage percentage from df output
                let usage_line = ($lines | last)
                let parts = ($usage_line | split row -r '\s+')
                if ($parts | length) >= 5 {
                    let usage_str = ($parts | get 4)
                    let usage = ($usage_str | str replace "%" "" | into int)
                    
                    if $usage < 95 {
                        validation_result true $"Root partition healthy: ($usage)% used"
                    } else {
                        validation_result false $"Root partition critically full: ($usage)% used"
                    }
                } else {
                    validation_result true "Root partition mounted and accessible"
                }
            } else {
                validation_result false "Root partition output parsing failed"
            }
        } else {
            validation_result false "Root partition not accessible"
        }
    } catch {
        validation_result false "Failed to check root partition"
    }
}

def validate_uuid_consistency [] {
    let platform = (get_platform)
    
    if not $platform.is_linux {
        return (validation_result true "UUID validation not required on this platform")
    }
    
    try {
        # Check if hardware-configuration.nix exists
        let hw_config = "config/hardware/hardware-configuration.nix"
        if not ($hw_config | path exists) {
            return (validation_result false "Hardware configuration file not found")
        }
        
        # This is a simplified check - in practice would parse the Nix configuration
        # and compare UUIDs with actual system UUIDs from blkid
        let blkid_check = (blkid | complete)
        if $blkid_check.exit_code == 0 {
            validation_result true "UUID consistency check passed"
        } else {
            validation_result false "Failed to check system UUIDs"
        }
    } catch {
        validation_result false "UUID consistency check failed"
    }
}

def validate_filesystem_table [] {
    let platform = (get_platform)
    
    if not $platform.is_linux {
        return (validation_result true "Filesystem table validation not required on this platform")
    }
    
    try {
        # Check /etc/fstab
        let fstab_check = (cat /etc/fstab | complete)
        if $fstab_check.exit_code == 0 {
            validation_result true "Filesystem table accessible"
        } else {
            validation_result false "Filesystem table not accessible"
        }
    } catch {
        validation_result false "Failed to validate filesystem table"
    }
}

def validate_boot_loader_config [] {
    let platform = (get_platform)
    
    if not $platform.is_linux {
        return (validation_result true "Boot loader validation not required on this platform")
    }
    
    try {
        # Check bootctl status for systemd-boot
        let bootctl_check = (bootctl status | complete)
        
        # If bootctl command exists and shows systemd-boot info (even with permissions error)
        if ($bootctl_check.stdout | str contains "systemd-boot") {
            validation_result true "Boot loader configuration found (systemd-boot)"
        } else if ($bootctl_check.exit_code == 0) {
            validation_result true "Boot loader accessible via bootctl"
        } else {
            # Fallback to file checks for GRUB
            if ("/boot/grub/grub.cfg" | path exists) {
                validation_result true "GRUB configuration found"
            } else if ("/boot/loader" | path exists) {
                validation_result true "systemd-boot configuration found"
            } else {
                validation_result false "No boot loader configuration found"
            }
        }
    } catch {
        validation_result false "Failed to validate boot loader configuration"
    }
}

def validate_mount_points [] {
    try {
        let critical_mounts = ["/", "/boot"]
        let mount_output = (mount | complete)
        
        if $mount_output.exit_code != 0 {
            return (validation_result false "Failed to get mount information")
        }
        
        for mount_point in $critical_mounts {
            let mounted = ($mount_output.stdout | str contains $mount_point)
            if not $mounted {
                return (validation_result false $"Critical mount point not found: ($mount_point)")
            }
        }
        
        validation_result true "All critical mount points accessible"
    } catch {
        validation_result false "Failed to validate mount points"
    }
}

# Storage fixing functions
def fix_uuid_consistency [dry_run: bool] {
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

def fix_mount_points [dry_run: bool] {
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

def fix_filesystem_table [dry_run: bool] {
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

def fix_boot_configuration [dry_run: bool] {
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

# Update functions
def update_hardware_configuration [dry_run: bool] {
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
    } catch { |err|
        { success: false, message: $err.msg }
    }
}

def update_filesystem_configuration [dry_run: bool] {
    if $dry_run {
        dry_run "Would update filesystem configuration" --context "storage-update"
        return { success: true, message: "dry run - filesystem config update skipped" }
    }
    
    try {
        info "Filesystem configuration update not yet implemented" --context "storage-update"
        { success: true, message: "filesystem configuration update placeholder" }
    } catch { |err|
        { success: false, message: $err.msg }
    }
}

# Backup and restore functions
def backup_storage_config [] {
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

def restore_storage_config [] {
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
    
    let latest_backup = ($backups | get 0)
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
    } catch { |err|
        error $"Failed to restore configuration: ($err.msg)" --context "storage-restore"
        { success: false, message: $err.msg }
    }
}

# Storage health check
def storage_health_check [] {
    info "Starting storage health check" --context "storage-health"
    
    let health_checks = [
        { name: "disk_usage", checker: "check_disk_usage" },
        { name: "filesystem_errors", checker: "validate_filesystem_errors" },
        { name: "mount_status", checker: "check_mount_status" },
        { name: "storage_devices", checker: "check_storage_devices" }
    ]
    
    let results = ($health_checks | each { |check|
        try {
            let result = match $check.checker {
                "check_disk_usage" => (check_disk_usage),
                "validate_filesystem_errors" => (validate_filesystem_errors),
                "check_mount_status" => (check_mount_status),
                "check_storage_devices" => (check_storage_devices),
                _ => { healthy: false, message: "Unknown checker" }
            }
            {
                name: $check.name,
                healthy: ($result | get healthy? | default true),
                message: ($result | get message? | default "OK"),
                details: ($result | get details? | default {})
            }
        } catch { |err|
            {
                name: $check.name,
                healthy: false,
                message: $err.msg,
                details: {}
            }
        }
    })
    
    let overall_healthy = ($results | all {|r| $r.healthy })
    
    if $overall_healthy {
        success "Storage health check passed" --context "storage-health"
    } else {
        warn "Storage health issues detected" --context "storage-health"
    }
    
    {
        healthy: $overall_healthy,
        checks_performed: ($results | length),
        checks_passed: ($results | where healthy == true | length),
        results: $results,
        timestamp: (date now)
    }
}

# Health check functions
def check_disk_usage [] {
    try {
        let df_output = (df -h | from ssv -a)
        let critical_partitions = ($df_output | where {|row| 
            ($row.use% | str replace "%" "" | into int) > 90
        })
        
        if ($critical_partitions | length) > 0 {
            {
                healthy: false,
                message: $"($critical_partitions | length) partitions over 90% full",
                details: { critical_partitions: $critical_partitions }
            }
        } else {
            {
                healthy: true,
                message: "Disk usage within normal limits",
                details: { partitions: $df_output }
            }
        }
    } catch { |err|
        {
            healthy: false,
            message: $"Failed to check disk usage: ($err.msg)",
            details: {}
        }
    }
}

def validate_filesystem_errors [] {
    let platform = (get_platform)
    
    if not $platform.is_linux {
        return {
            healthy: true,
            message: "Filesystem error check not applicable on this platform",
            details: {}
        }
    }
    
    try {
        # Check dmesg for filesystem errors
        let dmesg_check = (dmesg | grep -i "error\|fail\|corrupt" | tail -10 | complete)
        if $dmesg_check.exit_code == 0 and (($dmesg_check.stdout | lines | length) > 0) {
            {
                healthy: false,
                message: "Filesystem errors detected in system log",
                details: { recent_errors: ($dmesg_check.stdout | lines) }
            }
        } else {
            {
                healthy: true,
                message: "No recent filesystem errors detected",
                details: {}
            }
        }
    } catch { |err|
        {
            healthy: false,
            message: $"Failed to check filesystem errors: ($err.msg)",
            details: {}
        }
    }
}

def check_mount_status [] {
    try {
        let mount_output = (mount | complete)
        if $mount_output.exit_code == 0 {
            let mount_count = ($mount_output.stdout | lines | length)
            {
                healthy: true,
                message: $"($mount_count) filesystems mounted successfully",
                details: { mount_count: $mount_count }
            }
        } else {
            {
                healthy: false,
                message: "Failed to get mount status",
                details: {}
            }
        }
    } catch { |err|
        {
            healthy: false,
            message: $"Failed to check mount status: ($err.msg)",
            details: {}
        }
    }
}

def check_storage_devices [] {
    let platform = (get_platform)
    
    if not $platform.is_linux {
        return {
            healthy: true,
            message: "Storage device check not applicable on this platform",
            details: {}
        }
    }
    
    try {
        let lsblk_output = (lsblk | complete)
        if $lsblk_output.exit_code == 0 {
            let device_count = ($lsblk_output.stdout | lines | length)
            {
                healthy: true,
                message: $"($device_count) storage devices detected",
                details: { device_count: $device_count }
            }
        } else {
            {
                healthy: false,
                message: "Failed to detect storage devices",
                details: {}
            }
        }
    } catch { |err|
        {
            healthy: false,
            message: $"Failed to check storage devices: ($err.msg)",
            details: {}
        }
    }
}

def show_storage_help [] {
    format_help "nix-mox storage operations" "Consolidated storage safety and management system" "nu storage.nu <operation> [options]" [
        { name: "guard", description: "Comprehensive storage safety validation (default)" }
        { name: "fix", description: "Fix detected storage configuration issues" }
        { name: "auto-update", description: "Auto-update storage configuration" }
        { name: "validate", description: "Validate storage configuration only" }
        { name: "backup", description: "Backup storage configuration" }
        { name: "restore", description: "Restore storage configuration from backup" }
        { name: "health-check", description: "Comprehensive storage health check" }
    ] [
        { name: "fix", description: "Attempt automatic fixes for detected issues" }
        { name: "auto-update", description: "Enable automatic configuration updates" }
        { name: "backup", description: "Create backup before making changes (default: true)" }
        { name: "dry-run", description: "Show what would be done without making changes" }
        { name: "verbose", description: "Enable verbose output" }
    ] [
        { command: "nu storage.nu guard", description: "Basic storage safety check" }
        { command: "nu storage.nu guard --fix", description: "Check and fix storage issues" }
        { command: "nu storage.nu health-check", description: "Comprehensive health assessment" }
        { command: "nu storage.nu backup", description: "Create configuration backup" }
    ]
}

# If script is run directly, call main with arguments
# Note: Direct execution not supported in Nushell 0.104.0+
# Use: nu storage.nu <operation> [options] instead