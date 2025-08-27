#!/usr/bin/env nu
# Dashboard display functions
# Modularized from the main dashboard.nu for better maintainability

use ../lib/logging.nu *
use ../lib/platform.nu *

# =============================================================================
# DASHBOARD DISPLAY FUNCTIONS
# =============================================================================

export def display_overview [data: record, format: string] {
    if $format == "json" {
        $data | to json
        return
    }

    section "nix-mox System Overview" --context "dashboard"
    
    # Basic system info
    if "basic_system" in $data {
        info $"Hostname: ($data.basic_system.hostname)" --context "system"
        info $"Platform: ($data.basic_system.platform)" --context "system"
        info $"Uptime: ($data.basic_system.uptime)" --context "system"
        info $"Architecture: ($data.basic_system.architecture)" --context "system"
    }
    
    # Performance overview
    if "performance" in $data {
        section "Performance Overview" --context "dashboard"
        
        if "memory" in $data.performance {
            let mem = $data.performance.memory.memory_usage
            info $"Memory: ($mem.used)MB/($mem.total)MB (($mem.usage_percent)%)" --context "performance"
        }
        
        if "disk" in $data.performance {
            if ($data.performance.disk.disk_usage | length) > 0 {
                let root_disk = ($data.performance.disk.disk_usage | where mount == "/" | get 0)
                info $"Root Disk: ($root_disk.usage_percent)% used" --context "performance"
            }
        }
        
        if "load" in $data.performance {
            let load = $data.performance.load.load_average
            info $"Load Average: ($load.one_minute) ($load.five_minute) ($load.fifteen_minute)" --context "performance"
        }
    }
}

export def display_system [data: record, format: string] {
    if $format == "json" {
        $data | to json
        return
    }

    section "System Information" --context "dashboard"
    
    # Display each system component
    if "basic_system" in $data {
        subsection "Basic System" --context "system"
        $data.basic_system | transpose key value | each { |row|
            info $"($row.key): ($row.value)" --context "system"
        } | ignore
    }
    
    if "hardware" in $data {
        subsection "Hardware Information" --context "hardware"
        info "Hardware info collection available" --context "hardware"
    }
    
    if "network" in $data {
        subsection "Network Information" --context "network"
        info "Network info collection available" --context "network"
    }
}

export def display_performance [data: record, format: string] {
    if $format == "json" {
        $data | to json
        return
    }

    section "Performance Metrics" --context "dashboard"
    
    # CPU metrics
    if "cpu" in $data {
        subsection "CPU Metrics" --context "performance"
        info "CPU metrics available" --context "performance"
    }
    
    # Memory metrics
    if "memory" in $data {
        subsection "Memory Usage" --context "performance"
        let mem = $data.memory.memory_usage
        info $"Total: ($mem.total)MB" --context "performance"
        info $"Used: ($mem.used)MB (($mem.usage_percent)%)" --context "performance"
        info $"Available: ($mem.free)MB" --context "performance"
    }
    
    # Disk metrics
    if "disk" in $data {
        subsection "Disk Usage" --context "performance"
        $data.disk.disk_usage | each { |disk|
            info $"($disk.mount): ($disk.usage_percent)% used (($disk.used)/($disk.size))" --context "performance"
        } | ignore
    }
    
    # Load average
    if "load" in $data {
        subsection "Load Average" --context "performance"
        let load = $data.load.load_average
        info $"1 min: ($load.one_minute)" --context "performance"
        info $"5 min: ($load.five_minute)" --context "performance"
        info $"15 min: ($load.fifteen_minute)" --context "performance"
    }
}

export def display_testing [data: record, format: string] {
    if $format == "json" {
        $data | to json
        return
    }

    section "Testing Information" --context "dashboard"
    
    if "test_results" in $data {
        info "Test results available" --context "testing"
    } else {
        info "No test results available" --context "testing"
    }
}

export def display_coverage [data: record, format: string] {
    if $format == "json" {
        $data | to json
        return
    }

    section "Coverage Information" --context "dashboard"
    
    # Check for coverage data
    if "coverage" in $data {
        if "summary" in $data.coverage {
            let summary = $data.coverage.summary
            info $"Coverage: ($summary.coverage_percentage)%" --context "coverage"
            info $"Files analyzed: ($summary.files_analyzed)" --context "coverage"
        }
        
        if "metrics" in $data.coverage {
            let metrics = $data.coverage.metrics
            info $"Test files: ($metrics.test_files)" --context "coverage"
            info $"Library files: ($metrics.lib_files)" --context "coverage"
            info $"Coverage ratio: ($metrics.coverage_ratio)" --context "coverage"
        }
    }
    
    # Show file coverage details if available
    if "files" in $data.coverage {
        section "File Coverage Details" --context "coverage"
        
        let low_coverage = ($data.coverage.files | where { |file|
            ("error" not-in $file) and ($file.lines.coverage_percentage < 60)
        })
        
        if ($low_coverage | length) > 0 {
            warn "Files with low coverage (<60%):" --context "coverage"
            for file in $low_coverage {
                warn $"  ($file.file): ($file.lines.coverage_percentage)%" --context "coverage"
            }
        }
        
        let good_coverage = ($data.coverage.files | where { |file|
            ("error" not-in $file) and ($file.lines.coverage_percentage >= 80)
        })
        
        if ($good_coverage | length) > 0 {
            success $"Files with good coverage (≥80%): ($good_coverage | length)" --context "coverage"
        }
    }
}

export def display_security [data: record, format: string] {
    if $format == "json" {
        $data | to json
        return
    }

    section "Security Information" --context "dashboard"
    
    if "status" in $data {
        info "Security status available" --context "security"
    }
    
    if "vulnerabilities" in $data {
        info "Vulnerability scan available" --context "security"
    }
    
    if "audit" in $data {
        info "Audit logs available" --context "security"
    }
}

export def display_gaming [data: record, format: string] {
    if $format == "json" {
        $data | to json
        return
    }

    section "Gaming Information" --context "dashboard"
    
    if "gpu" in $data {
        info "GPU information available" --context "gaming"
    }
    
    if "services" in $data {
        info "Gaming services available" --context "gaming"
    }
    
    if "audio" in $data {
        info "Audio status available" --context "gaming"
    }
    
    if "controllers" in $data {
        info "Controller status available" --context "gaming"
    }
}

export def display_analysis [data: record, format: string] {
    if $format == "json" {
        $data | to json
        return
    }

    section "Analysis Information" --context "dashboard"
    
    if "packages" in $data {
        info "Package analysis available" --context "analysis"
    }
    
    if "sizes" in $data {
        info "Size analysis available" --context "analysis"
    }
    
    if "dependencies" in $data {
        info "Dependency analysis available" --context "analysis"
    }
    
    if "performance" in $data {
        info "Performance analysis available" --context "analysis"
    }
}

export def display_size_analysis [data: record, format: string] {
    if $format == "json" {
        $data | to json
        return
    }

    section "Size Analysis" --context "dashboard"
    info "Size analysis display not fully implemented" --context "analysis"
}

export def display_project_status [data: record, format: string] {
    if $format == "json" {
        $data | to json
        return
    }

    section "Project Status" --context "dashboard"
    info "Project status display not fully implemented" --context "project"
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

export def save_dashboard_data [data: record, output_path: string] {
    try {
        $data | to json | save $output_path
        info $"Dashboard data saved: ($output_path)" --context "dashboard"
    } catch { |err|
        error $"Failed to save dashboard data: ($err.msg)" --context "dashboard"
    }
}

# Quick status dashboard - minimal non-interactive status check
export def quick_status_dashboard [] {
    use data-collectors.nu *
    let system_info = (collect_basic_system_info)
    let nix_status = (collect_nix_status)
    let disk_usage = (collect_disk_usage)
    
    print "🚀 nix-mox Quick Status"
    print "======================="
    print $"System: ($system_info.hostname)"
    print $"Uptime: ($system_info.uptime)"
    print $"Nix Generations: ($nix_status.nix_status.generations)"
    let disk_info = if ($disk_usage.disk_usage | length) > 0 {
        ($disk_usage.disk_usage | each { |d| $"($d.mount): ($d.usage_percent)%" } | str join ', ')
    } else {
        'unknown'
    }
    print $"Disk Usage: ($disk_info)"
    print ""
}