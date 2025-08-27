#!/usr/bin/env nu

# Common functions for nix-mox Linux scripts (Modern Nushell Implementation)
# Replaces: _common.sh with modern consolidated patterns

use ../../lib/logging.nu *
use ../../lib/validators.nu *
use ../../lib/platform.nu *

# Platform-specific utilities for Linux
export const LINUX_METADATA = {
    name: "linux-common"
    description: "Common utilities for Linux platform scripts"
    platform: "linux"
    requires_root: false
    category: "platform"
}

# Check if running as root (using modern validation)
export def check_root [] {
    let validation = (validate_root_access)
    if not $validation.success {
        error "This script must be run as root" --context "linux-common"
        exit 1
    }
    success "Running with root privileges" --context "linux-common"
}

# File and directory utilities using modern patterns
export def ensure_dir [path: path] {
    let validation = (validate_directory $path)
    if not $validation.success {
        info $"Creating directory: ($path)" --context "linux-common"
        try {
            mkdir $path
            success $"Created directory: ($path)" --context "linux-common"
        } catch { |err|
            error $"Failed to create directory ($path): ($err)" --context "linux-common"
        }
    }
}

export def file_exists [path: path] {
    $path | path exists
}

export def dir_exists [path: path] {
    ($path | path exists) and (($path | path type) == "dir")
}

# CI detection using environment validation
export def is_ci_mode [] {
    let ci_env = ($env | get CI? | default "false")
    $ci_env == "true" or $ci_env == "1"
}

# System information gathering
export def get_linux_distro [] {
    let platform_info = (detect_platform)
    {
        os: $platform_info.os
        distro: $platform_info.distro
        version: $platform_info.version
        arch: $platform_info.arch
    }
}

# Package manager detection
export def detect_package_manager [] {
    if (which apt | length) > 0 {
        "apt"
    } else if (which yum | length) > 0 {
        "yum"
    } else if (which dnf | length) > 0 {
        "dnf"
    } else if (which pacman | length) > 0 {
        "pacman"
    } else if (which zypper | length) > 0 {
        "zypper"
    } else {
        "unknown"
    }
}

# Service management with modern patterns
export def manage_service [action: string, service: string] {
    let context = "linux-service"
    
    match $action {
        "enable" => {
            info $"Enabling service: ($service)" --context $context
            systemctl enable $service
        },
        "disable" => {
            info $"Disabling service: ($service)" --context $context
            systemctl disable $service
        },
        "start" => {
            info $"Starting service: ($service)" --context $context
            systemctl start $service
        },
        "stop" => {
            info $"Stopping service: ($service)" --context $context
            systemctl stop $service
        },
        "restart" => {
            info $"Restarting service: ($service)" --context $context
            systemctl restart $service
        },
        "status" => {
            info $"Checking service status: ($service)" --context $context
            systemctl status $service
        },
        _ => {
            error $"Unknown service action: ($action)" --context $context
        }
    }
}

# Modern process management
export def check_process_running [process_name: string] {
    let processes = (ps | where name == $process_name)
    ($processes | length) > 0
}

export def get_process_info [process_name: string] {
    ps | where name == $process_name
}

# Network utilities
export def check_port_open [port: int, --host: string = "localhost"] {
    try {
        let result = (netstat -tuln | where ($it.address | str contains $":($port)"))
        ($result | length) > 0
    } catch {
        false
    }
}

# Disk space utilities
export def check_disk_space [path: path = "/"] {
    let df_output = (df $path | first)
    {
        filesystem: $df_output.filesystem
        size: $df_output.size
        used: $df_output.used
        available: $df_output.available
        use_percentage: $df_output.use%
        mounted_on: $df_output.mounted_on
    }
}

# Memory information
export def get_memory_info [] {
    let mem_info = (cat /proc/meminfo | lines | parse "{key}: {value} {unit?}" | where key != null)
    let total_mem = ($mem_info | where key == "MemTotal" | get value.0 | into int)
    let free_mem = ($mem_info | where key == "MemFree" | get value.0 | into int)
    let available_mem = ($mem_info | where key == "MemAvailable" | get value.0 | into int)
    
    {
        total_kb: $total_mem
        free_kb: $free_mem
        available_kb: $available_mem
        used_kb: ($total_mem - $free_mem)
        usage_percent: (($total_mem - $available_mem) * 100 / $total_mem)
    }
}

# Backup utilities with modern error handling
export def create_backup [source: path, destination: path] {
    let context = "linux-backup"
    
    if not ($source | path exists) {
        error $"Source path does not exist: ($source)" --context $context
        return {success: false, error: "Source not found"}
    }
    
    info $"Creating backup: ($source) -> ($destination)" --context $context
    
    try {
        cp -r $source $destination
        success $"Backup created successfully: ($destination)" --context $context
        {success: true, backup_path: $destination}
    } catch { |err|
        error $"Backup failed: ($err)" --context $context
        {success: false, error: $"Backup failed: ($err)"}
    }
}

# Configuration file management
export def backup_config [config_file: path] {
    let timestamp = (date now | format date "%Y%m%d-%H%M%S")
    let backup_path = $"($config_file).backup.($timestamp)"
    create_backup $config_file $backup_path
}

# Log analysis utilities
export def analyze_logs [log_file: path, --lines: int = 100] {
    if not ($log_file | path exists) {
        error $"Log file not found: ($log_file)" --context "linux-logs"
        return
    }
    
    let recent_logs = (tail -n $lines $log_file | lines)
    let error_lines = ($recent_logs | where ($it | str contains "ERROR" or $it | str contains "error"))
    let warning_lines = ($recent_logs | where ($it | str contains "WARN" or $it | str contains "warning"))
    
    {
        total_lines: ($recent_logs | length)
        error_count: ($error_lines | length)
        warning_count: ($warning_lines | length)
        errors: $error_lines
        warnings: $warning_lines
    }
}

# Export all functions for use in other scripts
export def show_common_functions [] {
    print "Available Linux common functions:"
    print "- check_root: Verify root privileges"
    print "- ensure_dir: Create directory if it doesn't exist"  
    print "- file_exists: Check if file exists"
    print "- dir_exists: Check if directory exists"
    print "- is_ci_mode: Detect CI environment"
    print "- get_linux_distro: Get distribution information"
    print "- detect_package_manager: Find available package manager"
    print "- manage_service: Control systemd services"
    print "- check_process_running: Check if process is running"
    print "- get_process_info: Get process information"
    print "- check_port_open: Check if port is listening"
    print "- check_disk_space: Get disk usage information"
    print "- get_memory_info: Get memory usage information"
    print "- create_backup: Create file/directory backups"
    print "- backup_config: Backup configuration files with timestamp"
    print "- analyze_logs: Analyze log files for errors and warnings"
}