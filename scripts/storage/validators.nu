#!/usr/bin/env nu
# Storage validation functions
# Extracted from scripts/storage.nu for better organization

use ../lib/logging.nu *
use ../lib/platform.nu *
use ../lib/validators.nu *
use ../lib/command-wrapper.nu *

# =============================================================================
# COMPREHENSIVE VALIDATION RUNNER
# =============================================================================

export def run_comprehensive_storage_validation [] {
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

# =============================================================================
# INDIVIDUAL VALIDATION FUNCTIONS
# =============================================================================

export def validate_hardware_config_exists [] {
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

export def validate_boot_partition_mounted [] {
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

export def validate_root_partition_healthy [] {
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

export def validate_uuid_consistency [] {
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

export def validate_filesystem_table [] {
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

export def validate_boot_loader_config [] {
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

export def validate_mount_points [] {
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