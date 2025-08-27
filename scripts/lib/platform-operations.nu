#!/usr/bin/env nu
# Platform operations library for nix-mox
# Consolidates platform-specific operations with functional patterns
# Replaces duplicated install/uninstall/maintenance scripts across platforms

use logging.nu *
use platform.nu *
use validators.nu *
use command-wrapper.nu *

# Platform-aware operation dispatcher
def execute_platform_operation [
    operations: record,
    operation_name: string,
    --context: string = "platform-ops"
] {
    let platform = (get_platform)
    
    info $"Starting ($operation_name) on ($platform.normalized)" --context $context
    
    # Get platform-specific operation
    let operation = ($operations | get $platform.normalized -o)
    if ($operation | is-not-empty) {
        debug $"Executing ($operation_name) for ($platform.normalized)" --context $context
        do $operation
    } else {
        # Try default operation
        let default_op = ($operations | get "default" -o)
        if ($default_op | is-not-empty) {
            warn $"Using default operation for unsupported platform: ($platform.normalized)" --context $context
            do $default_op
        } else {
            error $"No ($operation_name) operation defined for platform: ($platform.normalized)" --context $context
            return { success: false, message: "unsupported platform" }
        }
    }
}

# Installation pipeline with platform-specific steps
export def install_pipeline [
    package_name: string,
    --pre-install: closure,
    --post-install: closure,
    --context: string = "install"
] {
    info $"Starting installation of ($package_name)" --context $context
    
    # Pre-installation checks and setup
    if ($pre_install | is-not-empty) {
        do $pre_install
    }
    
    # Platform-specific installation
    let operations = {
        linux: {|| install_on_linux $package_name },
        macos: {|| install_on_macos $package_name },
        windows: {|| install_on_windows $package_name },
        default: {|| error make { msg: $"Installation not supported for ($package_name)" } }
    }
    let result = (execute_platform_operation $operations "install")
    
    if ($result | get success -o | default true) {
        # Post-onstallation verification
        if ($post_install | is-not-empty) {
            do $post_install
        }
        success $"Successfully installed ($package_name)" --context $context
    } else {
        error $"Failed to install ($package_name)" --context $context
    }
    
    $result
}

# Uninstallation pipeline
export def uninstall_pipeline [
    package_name: string,
    --pre-uninstall: closure,
    --post-uninstall: closure,
    --context: string = "uninstall"
] {
    info $"Starting uninstallation of ($package_name)" --context $context
    
    # Pre-uninstallation checks
    if ($pre_uninstall | is-not-empty) {
        do $pre_uninstall
    }
    
    # Platform-specific uninstallation
    let operations = {
        linux: {|| uninstall_on_linux $package_name },
        macos: {|| uninstall_on_macos $package_name },
        windows: {|| uninstall_on_windows $package_name },
        default: {|| warn $"Manual uninstallation required for ($package_name)"; { success: true } }
    }
    let result = (execute_platform_operation $operations "uninstall")
    
    if ($result | get success -o | default true) {
        # Post-uninstallation cleanup
        if ($post_uninstall | is-not-empty) {
            do $post_uninstall
        }
        success $"Successfully uninstalled ($package_name)" --context $context
    } else {
        error $"Failed to uninstall ($package_name)" --context $context
    }
    
    $result
}

# Maintenance pipeline for platform-specific maintenance tasks
export def maintenance_pipeline [
    --context: string = "maintenance"
] {
    info "Starting system maintenance" --context $context
    
    let operations = {
        linux: {|| linux_maintenance },
        macos: {|| macos_maintenance },
        windows: {|| windows_maintenance },
        default: {|| basic_maintenance }
    }
    let results = (execute_platform_operation $operations "maintenance")
    
    $results
}

# Platform-specific installation functions
def install_on_linux [package: string] {
    let package_manager = (detect_package_manager)
    
    match $package_manager {
        "nix" => {
            nix_command "profile" --extra-args ["install" $package]
        },
        "apt" => {
            execute_command ["sudo" "apt" "install" "-y" $package] --context "apt-onstall"
        },
        "yum" => {
            execute_command ["sudo" "yum" "install" "-y" $package] --context "yum-onstall"
        },
        "pacman" => {
            execute_command ["sudo" "pacman" "-S" "--noconfirm" $package] --context "pacman-onstall"
        },
        _ => {
            error make { msg: $"No supported package manager found for ($package)" }
        }
    }
}

def install_on_macos [package: string] {
    let package_manager = (detect_package_manager)
    
    match $package_manager {
        "nix" => {
            nix_command "profile" --extra-args ["install" $package]
        },
        "brew" => {
            execute_command ["brew" "install" $package] --context "brew-onstall"
        },
        "macports" => {
            execute_command ["sudo" "port" "install" $package] --context "macports-onstall"
        },
        _ => {
            error make { msg: $"No supported package manager found for ($package)" }
        }
    }
}

def install_on_windows [package: string] {
    let package_manager = (detect_package_manager)
    
    match $package_manager {
        "nix" => {
            nix_command "profile" --extra-args ["install" $package]
        },
        "chocolatey" => {
            execute_command ["choco" "install" "-y" $package] --context "choco-onstall"
        },
        "scoop" => {
            execute_command ["scoop" "install" $package] --context "scoop-onstall"
        },
        "winget" => {
            execute_command ["winget" "install" $package] --context "winget-onstall"
        },
        _ => {
            error make { msg: $"No supported package manager found for ($package)" }
        }
    }
}

# Platform-specific uninstallation functions
def uninstall_on_linux [package: string] {
    let package_manager = (detect_package_manager)
    
    match $package_manager {
        "nix" => {
            nix_command "profile" --extra-args ["remove" $package]
        },
        "apt" => {
            execute_command ["sudo" "apt" "remove" "-y" $package] --context "apt-remove"
        },
        "yum" => {
            execute_command ["sudo" "yum" "remove" "-y" $package] --context "yum-remove"
        },
        "pacman" => {
            execute_command ["sudo" "pacman" "-R" "--noconfirm" $package] --context "pacman-remove"
        },
        _ => {
            warn $"Unknown package manager, manual removal required for ($package)"
            { success: false, message: "manual removal required" }
        }
    }
}

def uninstall_on_macos [package: string] {
    let package_manager = (detect_package_manager)
    
    match $package_manager {
        "nix" => {
            nix_command "profile" --extra-args ["remove" $package]
        },
        "brew" => {
            execute_command ["brew" "uninstall" $package] --context "brew-uninstall"
        },
        "macports" => {
            execute_command ["sudo" "port" "uninstall" $package] --context "macports-uninstall"
        },
        _ => {
            warn $"Unknown package manager, manual removal required for ($package)"
            { success: false, message: "manual removal required" }
        }
    }
}

def uninstall_on_windows [package: string] {
    let package_manager = (detect_package_manager)
    
    match $package_manager {
        "nix" => {
            nix_command "profile" --extra-args ["remove" $package]
        },
        "chocolatey" => {
            execute_command ["choco" "uninstall" "-y" $package] --context "choco-uninstall"
        },
        "scoop" => {
            execute_command ["scoop" "uninstall" $package] --context "scoop-uninstall"
        },
        "winget" => {
            execute_command ["winget" "uninstall" $package] --context "winget-uninstall"
        },
        _ => {
            warn $"Unknown package manager, manual removal required for ($package)"
            { success: false, message: "manual removal required" }
        }
    }
}

# Platform-specific maintenance functions
def linux_maintenance [] {
    let tasks = []
    mut results = []
    
    # Update package databases
    let package_manager = (detect_package_manager)
    match $package_manager {
        "apt" => {
            let update_result = (execute_command ["sudo" "apt" "update"] --context "linux-maintenance")
            $results = ($results | append { task: "apt-update", result: $update_result })
        },
        "yum" => {
            let update_result = (execute_command ["sudo" "yum" "check-update"] --context "linux-maintenance") 
            $results = ($results | append { task: "yum-update", result: $update_result })
        },
        "pacman" => {
            let update_result = (execute_command ["sudo" "pacman" "-Sy"] --context "linux-maintenance")
            $results = ($results | append { task: "pacman-sync", result: $update_result })
        }
    }
    
    # Clean up temporary files
    let cleanup_result = (cleanup_temp_files)
    $results = ($results | append { task: "cleanup", result: $cleanup_result })
    
    # Check system services if systemd is available
    if (which systemctl | is-not-empty) {
        let service_check = (execute_command ["systemctl" "--failed" "--no-pager"] --context "linux-maintenance")
        $results = ($results | append { task: "service-check", result: $service_check })
    }
    
    {
        platform: "linux",
        completed_tasks: ($results | length),
        results: $results
    }
}

def macos_maintenance [] {
    mut results = []
    
    # Update Homebrew if available
    if (which brew | is-not-empty) {
        let brew_update = (execute_command ["brew" "update"] --context "macos-maintenance")
        $results = ($results | append { task: "brew-update", result: $brew_update })
        
        let brew_cleanup = (execute_command ["brew" "cleanup"] --context "macos-maintenance")
        $results = ($results | append { task: "brew-cleanup", result: $brew_cleanup })
    }
    
    # Clean up temporary files
    let cleanup_result = (cleanup_temp_files)
    $results = ($results | append { task: "cleanup", result: $cleanup_result })
    
    # Check launchd services
    if (which launchctl | is-not-empty) {
        let service_check = (execute_command ["launchctl" "list"] --context "macos-maintenance")
        $results = ($results | append { task: "service-check", result: $service_check })
    }
    
    {
        platform: "macos",
        completed_tasks: ($results | length),
        results: $results
    }
}

def windows_maintenance [] {
    mut results = []
    
    # Update Chocolatey if available
    if (which choco | is-not-empty) {
        let choco_upgrade = (execute_command ["choco" "upgrade" "all" "-y"] --context "windows-maintenance")
        $results = ($results | append { task: "choco-upgrade", result: $choco_upgrade })
    }
    
    # Update Scoop if available
    if (which scoop | is-not-empty) {
        let scoop_update = (execute_command ["scoop" "update"] --context "windows-maintenance")
        $results = ($results | append { task: "scoop-update", result: $scoop_update })
    }
    
    # Clean up temporary files
    let cleanup_result = (cleanup_temp_files)
    $results = ($results | append { task: "cleanup", result: $cleanup_result })
    
    {
        platform: "windows",
        completed_tasks: ($results | length),
        results: $results
    }
}

def basic_maintenance [] {
    mut results = []
    
    # Basic cleanup that works on all platforms
    let cleanup_result = (cleanup_temp_files)
    $results = ($results | append { task: "cleanup", result: $cleanup_result })
    
    # Nix-specific maintenance if available
    if (which nix | is-not-empty) {
        let nix_gc = (execute_command ["nix-collect-garbage"] --context "basic-maintenance")
        $results = ($results | append { task: "nix-gc", result: $nix_gc })
    }
    
    {
        platform: "basic",
        completed_tasks: ($results | length),
        results: $results
    }
}

# Helper functions
def cleanup_temp_files [] {
    let temp_patterns = ["tmp/*", "coverage-tmp/*", "*.tmp", "*.log"]
    mut cleaned = []
    
    for pattern in $temp_patterns {
        try {
            let files = (glob $pattern)
            for file in $files {
                if ($file | path exists) {
                    try {
                        if ($file | path type) == "dir" {
                            rm -rf $file
                        } else {
                            rm -f $file
                        }
                        $cleaned = ($cleaned | append $file)
                    } catch {
                        # Ignore errors for individual file cleanup
                    }
                }
            }
        } catch {
            # Ignore errors for temp cleanup
        }
    }
    
    {
        success: true,
        cleaned_files: ($cleaned | length),
        files: $cleaned
    }
}

# Service management pipeline
export def service_pipeline [
    action: string,
    service_name: string,
    --context: string = "service"
] {
    let operations = {
        linux: {|| linux_service_action $action $service_name },
        macos: {|| macos_service_action $action $service_name },
        windows: {|| windows_service_action $action $service_name },
        default: {|| error make { msg: $"Service management not supported on this platform" } }
    }
    execute_platform_operation $operations $"service ($action)" --context $context
}

def linux_service_action [action: string, service: string] {
    if (which systemctl | is-not-empty) {
        execute_command ["sudo" "systemctl" $action $service] --context "systemd-service"
    } else {
        execute_command ["sudo" "service" $service $action] --context "sysv-service"
    }
}

def macos_service_action [action: string, service: string] {
    match $action {
        "start" => {
            execute_command ["sudo" "launchctl" "load" $service] --context "launchd-service"
        },
        "stop" => {
            execute_command ["sudo" "launchctl" "unload" $service] --context "launchd-service"
        },
        "restart" => {
            execute_command ["sudo" "launchctl" "unload" $service] --context "launchd-service"
            execute_command ["sudo" "launchctl" "load" $service] --context "launchd-service"
        },
        _ => {
            error make { msg: $"Unknown service action: ($action)" }
        }
    }
}

def windows_service_action [action: string, service: string] {
    match $action {
        "start" => {
            execute_command ["sc" "start" $service] --context "windows-service"
        },
        "stop" => {
            execute_command ["sc" "stop" $service] --context "windows-service"
        },
        "restart" => {
            execute_command ["sc" "stop" $service] --context "windows-service"
            sleep 2sec
            execute_command ["sc" "start" $service] --context "windows-service"
        },
        _ => {
            error make { msg: $"Unknown service action: ($action)" }
        }
    }
}