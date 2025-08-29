#!/usr/bin/env nu
# Dashboard data collection functions
# Modularized from the main dashboard.nu for better maintainability

use ../lib/logging.nu *
use ../lib/platform.nu *
use ../lib/validators.nu *
use ../lib/command-wrapper.nu *

# ──────────────────────────────────────────────────────────
# HIGH-LEVEL DATA COLLECTORS
# ──────────────────────────────────────────────────────────

export def collect_overview_data [] {
    {
        overview: (collect_basic_system_info),
        performance: (collect_basic_performance_data)
    }
}

export def collect_system_data [] {
    (collect_comprehensive_system_info)
}

export def collect_performance_data [] {
    {
        cpu: (collect_cpu_metrics),
        memory: (collect_memory_metrics),
        disk: (collect_disk_metrics),
        network: (collect_network_metrics),
        load: (collect_load_average)
    }
}

export def collect_testing_data [] {
    (collect_test_results)
}

export def collect_security_data [] {
    {
        status: (collect_security_status),
        vulnerabilities: (collect_vulnerability_scan),
        audit: (collect_audit_logs)
    }
}

export def collect_gaming_data [] {
    {
        gpu: (collect_gpu_info),
        services: (collect_gaming_services),
        audio: (collect_audio_status),
        controllers: (collect_controller_status)
    }
}

export def collect_analysis_data [] {
    {
        packages: (collect_package_analysis),
        sizes: (collect_size_analysis),
        dependencies: (collect_dependency_analysis),
        performance: (collect_performance_analysis)
    }
}

# ──────────────────────────────────────────────────────────
# SYSTEM INFORMATION COLLECTORS
# ──────────────────────────────────────────────────────────

export def collect_comprehensive_system_info [] {
    {
        basic_system: (collect_basic_system_info),
        hardware: (collect_detailed_hardware_info),
        network: (collect_network_info),
        processes: (collect_process_info),
        environment: (collect_environment_info),
        services: (collect_service_status),
        recent_activity: (collect_recent_activity)
    }
}

export def collect_basic_system_info [] {
    let platform = (get_platform)
    
    try {
        {
            hostname: (hostname | str trim),
            platform: $platform,
            uptime: (if $platform == "linux" { 
                uptime | str trim 
            } else { 
                "N/A" 
            }),
            kernel: (uname | get kernel-release),
            architecture: (uname | get machine),
            timestamp: (date now | format date '%Y-%m-%d %H:%M:%S')
        }
    } catch {
        {
            hostname: "unknown",
            platform: $platform,
            uptime: "unknown",
            kernel: "unknown",
            architecture: "unknown",
            timestamp: (date now | format date '%Y-%m-%d %H:%M:%S'),
            error: "Failed to collect basic system info"
        }
    }
}

export def collect_basic_performance_data [] {
    {
        cpu: (collect_cpu_metrics),
        memory: (collect_memory_usage),
        disk: (collect_disk_usage),
        load: (collect_load_average)
    }
}

# ──────────────────────────────────────────────────────────
# DETAILED COLLECTORS
# ──────────────────────────────────────────────────────────

export def collect_nix_status [] {
    try {
        let generations = (nix-env --list-generations | lines | length)
        let profile_version = (try { 
            nix-env --version | parse "nix-env (Nix) {version}" | get version | get 0
        } catch { 
            "unknown" 
        })
        
        {
            nix_status: {
                generations: $generations,
                version: $profile_version,
                store_path: "/nix/store",
                profiles: (try { ls ~/.nix-profile/ | length } catch { 0 })
            }
        }
    } catch {
        {
            nix_status: {
                generations: 0,
                version: "unknown",
                store_path: "/nix/store",
                profiles: 0,
                error: "Failed to collect Nix status"
            }
        }
    }
}

export def collect_disk_usage [] {
    try {
        # Simplified disk usage collection for now
        {
            disk_usage: [
                {
                    filesystem: "/dev/root",
                    size: "unknown",
                    used: "unknown", 
                    available: "unknown",
                    usage_percent: 0,
                    mount: "/"
                }
            ]
        }
    } catch {
        {
            disk_usage: [],
            error: "Failed to collect disk usage"
        }
    }
}

export def collect_memory_usage [] {
    try {
        let mem_info = (free -m | from ssv -a | where "Mem:" != null | get 0)
        
        {
            memory_usage: {
                total: $mem_info.total,
                used: $mem_info.used,
                free: $mem_info.available,
                usage_percent: (($mem_info.used / $mem_info.total) * 100 | math round)
            }
        }
    } catch {
        {
            memory_usage: {
                total: 0,
                used: 0,
                free: 0,
                usage_percent: 0,
                error: "Failed to collect memory usage"
            }
        }
    }
}

# ──────────────────────────────────────────────────────────
# PLACEHOLDER COLLECTORS (to be implemented)
# ──────────────────────────────────────────────────────────

export def collect_service_status [] {
    { services: { status: "service collection not implemented" } }
}

export def collect_recent_activity [] {
    { activity: { status: "activity collection not implemented" } }
}

export def collect_detailed_hardware_info [] {
    { hardware: { status: "hardware collection not implemented" } }
}

export def collect_network_info [] {
    { network: { status: "network collection not implemented" } }
}

export def collect_network_interfaces [] {
    { interfaces: { status: "interface collection not implemented" } }
}

export def collect_process_info [] {
    { processes: { status: "process collection not implemented" } }
}

export def collect_environment_info [] {
    { environment: { status: "environment collection not implemented" } }
}

export def collect_cpu_metrics [] {
    { cpu: { status: "CPU metrics not implemented" } }
}

export def collect_load_average [] {
    try {
        let load = (uptime | parse "{uptime} load average: {one}, {five}, {fifteen}" | get 0)
        {
            load_average: {
                one_minute: ($load.one | into float),
                five_minute: ($load.five | into float),
                fifteen_minute: ($load.fifteen | into float)
            }
        }
    } catch {
        { load_average: { error: "Failed to collect load average" } }
    }
}

export def collect_memory_metrics [] {
    (collect_memory_usage)
}

export def collect_disk_metrics [] {
    (collect_disk_usage)
}

export def collect_network_metrics [] {
    { network_metrics: { status: "network metrics not implemented" } }
}

export def collect_nix_performance [] {
    { nix_performance: { status: "Nix performance not implemented" } }
}

export def collect_test_results [] {
    { test_results: { status: "test results collection not implemented" } }
}

export def collect_quality_metrics [] {
    { quality: { status: "quality metrics collection not implemented" } }
}

export def collect_security_status [] {
    { security_status: { status: "security status not implemented" } }
}

export def collect_vulnerability_scan [] {
    { vulnerabilities: { status: "vulnerability scan not implemented" } }
}

export def collect_audit_logs [] {
    { audit_logs: { status: "audit logs not implemented" } }
}

export def collect_gpu_info [] {
    { gpu: { status: "GPU info not implemented" } }
}

export def collect_gaming_services [] {
    { gaming_services: { status: "gaming services not implemented" } }
}

export def collect_audio_status [] {
    { audio: { status: "audio status not implemented" } }
}

export def collect_controller_status [] {
    { controllers: { status: "controller status not implemented" } }
}

export def collect_package_analysis [] {
    { packages: { status: "package analysis not implemented" } }
}

export def collect_size_analysis [] {
    { sizes: { status: "size analysis not implemented" } }
}

export def collect_dependency_analysis [] {
    { dependencies: { status: "dependency analysis not implemented" } }
}

export def collect_performance_analysis [] {
    { performance_analysis: { status: "performance analysis not implemented" } }
}

export def collect_size_analysis_data [] {
    { size_analysis: { status: "size analysis data not implemented" } }
}

export def collect_project_status_data [] {
    { project_status: { status: "project status data not implemented" } }
}