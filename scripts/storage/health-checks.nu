#!/usr/bin/env nu
# Storage health check functions
# Extracted from scripts/storage.nu for better organization

use ../lib/logging.nu *
use ../lib/platform.nu *

# =============================================================================
# MAIN HEALTH CHECK COORDINATOR
# =============================================================================

export def storage_health_check [] {
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

# =============================================================================
# INDIVIDUAL HEALTH CHECK FUNCTIONS
# =============================================================================

export def check_disk_usage [] {
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

export def validate_filesystem_errors [] {
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

export def check_mount_status [] {
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

export def check_storage_devices [] {
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