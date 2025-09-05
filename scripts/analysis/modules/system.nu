#!/usr/bin/env nu

# System monitoring module for dashboard
# Handles system overview, performance metrics, and status information



export def get_system_overview_module [] {
    let platform_info = get_platform_info
    let performance = try { get_system_performance } catch { {} }
    
    {
        hostname: (hostname),
        platform: $platform_info.platform,
        os_version: $platform_info.os_version,
        architecture: $platform_info.architecture,
        uptime: ($performance.uptime? | default 0),
        cpu_usage: ($performance.cpu_usage? | default 0.0),
        memory_usage: ($performance.memory_usage? | default 0.0),
        load_average: ($performance.load_average? | default [0.0, 0.0, 0.0])
    }
}

export def get_detailed_system_info_module [] {
    let system_info = get_system_overview_module
    
    # Get additional system details
    let disk_info = try {
        let disk_usage = (df -h / | tail -n 1 | split row " " | get 4 | str replace "%" "")
        {
            disk_usage: ($disk_usage | into float)
        }
    } catch {
        {
            disk_usage: 0.0
        }
    }
    
    let network_info = try {
        let network_interfaces = (ip addr show | grep "inet " | split row " " | get 2 | split row "/" | first)
        {
            ip_addresses: $network_interfaces
        }
    } catch {
        {
            ip_addresses: []
        }
    }
    
    $system_info | merge $disk_info | merge $network_info
}

export def get_system_health_module [] {
    let system_info = get_detailed_system_info_module
    
    let health_status = {
        overall: "healthy"
        issues: []
        warnings: []
    }
    
    # Check CPU usage
    if $system_info.cpu_usage > 80.0 {
        $health_status | upsert overall "warning"
        $health_status | upsert warnings ($health_status.warnings | append "High CPU usage")
    }
    
    # Check memory usage
    if $system_info.memory_usage > 85.0 {
        $health_status | upsert overall "warning"
        $health_status | upsert warnings ($health_status.warnings | append "High memory usage")
    }
    
    # Check disk usage
    if $system_info.disk_usage > 90.0 {
        $health_status | upsert overall "critical"
        $health_status | upsert issues ($health_status.issues | append "Critical disk usage")
    } else if $system_info.disk_usage > 80.0 {
        $health_status | upsert overall "warning"
        $health_status | upsert warnings ($health_status.warnings | append "High disk usage")
    }
    
    # Check load average
    let load_avg = $system_info.load_average
    if ($load_avg | length) >= 3 {
        let current_load = ($load_avg | first)
        let cpu_count = (sys | get cpu | length)
        if $current_load > ($cpu_count * 2) {
            $health_status | upsert overall "warning"
            $health_status | upsert warnings ($health_status.warnings | append "High system load")
        }
    }
    
    $health_status
}

export def get_process_info_module [] {
    try {
        let processes = (ps | skip 1 | each { | line|
            let parts = ($line | split row " " | where $it != "")
            {
                user: ($parts | first),
                pid: ($parts | get 1 | into int),
                cpu: ($parts | get 2 | into float),
                mem: ($parts | get 3 | into float),
                command: ($parts | skip 10 | str join " ")
            }
        } | sort-by cpu --reverse | take 10)
        
        {
            top_processes: $processes,
            total_processes: (ps | skip 1 | length)
        }
    } catch {
        {
            top_processes: [],
            total_processes: 0
        }
    }
}

export def get_service_status_module [] {
    try {
        let services = [
            "nix-daemon"
            "systemd-resolved"
            "NetworkManager"
            "sshd"
        ]
        
        let service_status = ($services | each { | service|
            let status = try {
                systemctl is-active $service
            } catch {
                "unknown"
            }
            
            {
                name: $service,
                status: $status,
                active: ($status == "active")
            }
        })
        
        {
            services: $service_status,
            active_count: ($service_status | where active == true | length),
            total_count: ($service_status | length)
        }
    } catch {
        {
            services: [],
            active_count: 0,
            total_count: 0
        }
    }
}
