#!/usr/bin/env nu
# Simplified dashboard system for nix-mox
# Basic dashboard functionality without complex module dependencies

use ./lib/command-wrapper.nu

# Simple logging functions
def info [msg: string, --context: string = "dashboard"] {
    print $"[INFO] (ansi green)($msg)(ansi reset)"
}

def success [msg: string, --context: string = "dashboard"] {
    print $"[SUCCESS] (ansi green)✓ ($msg)(ansi reset)"
}

def error [msg: string, --context: string = "dashboard"] {
    print $"[ERROR] (ansi red)✗ ($msg)(ansi reset)"
}

def warn [msg: string, --context: string = "dashboard"] {
    print $"[WARN] (ansi yellow)⚠ ($msg)(ansi reset)"
}

def banner [title: string, context: string = "dashboard"] {
    print ""
    print $"(ansi cyan)═══════════════════════════════════════════════(ansi reset)"
    print $"(ansi cyan)  ($title)(ansi reset)"
    print $"(ansi cyan)═══════════════════════════════════════════════(ansi reset)"
    print ""
}

# Platform detection
def get_platform [] {
    let os = $env.OS?
    let uname = (safe_command_with_fallback "uname -s" "unknown" --context "platform-detection" | str downcase)
    
    if $os == "Windows_NT" {
        "windows"
    } else if $uname == "darwin" {
        "macos"  
    } else if $uname == "linux" {
        "linux"
    } else {
        "unknown"
    }
}

# Main dashboard dispatcher  
def main [
    view: string = "overview",
    --refresh: int = 5,
    --watch,
    --output: string = "",
    --format: string = "table",
    --help
] {
    if $help {
        show_dashboard_help
        return
    }

    banner "nix-mox Dashboard System"
    
    # Route to appropriate dashboard based on view
    match $view {
        "overview" => (overview_dashboard $refresh $watch $output $format),
        "system" => (system_dashboard $refresh $watch $output $format),
        "performance" => (performance_dashboard $refresh $watch $output $format),
        "testing" => (testing_dashboard $refresh $watch $output $format),
        "coverage" => (coverage_dashboard $refresh $watch $output $format),
        "security" => (security_dashboard $refresh $watch $output $format),
        "gaming" => (gaming_dashboard $refresh $watch $output $format),
        "analysis" => (analysis_dashboard $refresh $watch $output $format),
        "quick" => (quick_status_dashboard),
        _ => {
            error $"Unknown dashboard view: ($view). Use '--help' to see available views."
            show_dashboard_help
            return
        }
    }
}

# Overview dashboard - high-level system status
def overview_dashboard [refresh: int, watch: bool, output: string, format: string] {
    let data = (collect_basic_data)
    display_basic_info $data $format
    
    if not ($output | is-empty) {
        save_data $data $output
    }
}

# System dashboard - system information
def system_dashboard [refresh: int, watch: bool, output: string, format: string] {
    let data = (collect_system_data)
    display_system_info $data $format
    
    if not ($output | is-empty) {
        save_data $data $output
    }
}

# Simplified data collectors
def collect_basic_data [] {
    let platform = (get_platform)
    let timestamp = (date now)
    
    {
        platform: $platform,
        timestamp: $timestamp,
        hostname: (safe_command_with_fallback "hostname" "unknown" --context "system-info" ),
        uptime: (safe_command_with_fallback "uptime" "unknown" --context "system-info"  | str trim)
    }
}

def collect_system_data [] {
    let basic = (collect_basic_data)
    let disk = (try {
        let df_result = (^df -h | from ssv -a)
        ($df_result | where filesystem =~ "/" | get 0)
    } catch { { use%: "unknown", avail: "unknown" } })
    
    let memory = (try {
        let mem = (sys mem)
        {
            total: ($mem.total | into string),
            used: ($mem.used | into string),
            usage_percent: (($mem.used / $mem.total) * 100 | math round)
        }
    } catch { { total: "unknown", used: "unknown", usage_percent: 0 } })
    
    let hardware = (try {
        let emi_status = (^nu scripts/testing/hardware/emi-detection.nu | complete)
        let usb_errors = (^journalctl --since "1 hour ago" --no-pager | grep -E "error.*USB|can.*t set config" | wc -l | str trim | into int)
        let i2c_errors = (^journalctl --since "1 hour ago" --no-pager | grep -E "i2c.*Invalid|0xffff" | wc -l | str trim | into int)
        
        {
            emi_healthy: (($emi_status.exit_code == 0) and not ($emi_status.stdout | str contains "errors detected")),
            usb_errors: $usb_errors,
            i2c_errors: $i2c_errors,
            overall_health: (if ($usb_errors == 0 and $i2c_errors == 0) { "healthy" } else { "issues_detected" })
        }
    } catch { 
        { 
            emi_healthy: true, 
            usb_errors: 0, 
            i2c_errors: 0, 
            overall_health: "unknown" 
        } 
    })
    
    $basic | merge { disk: $disk, memory: $memory, hardware: $hardware }
}

# Display functions
def display_basic_info [data: record, format: string] {
    info $"Platform: ($data.platform)"
    info $"Hostname: ($data.hostname)"  
    info $"Uptime: ($data.uptime)"
    info $"Timestamp: ($data.timestamp)"
}

def display_system_info [data: record, format: string] {
    display_basic_info $data $format
    
    if "disk" in $data {
        info $"Disk Usage: ($data.disk.use% // 'unknown')"
        info $"Disk Available: ($data.disk.avail // 'unknown')"
    }
    
    if "memory" in $data {
        info $"Memory Usage: ($data.memory.usage_percent)%"
        info $"Memory Total: ($data.memory.total)"
    }
    
    if "hardware" in $data {
        let status_icon = if ($data.hardware.overall_health == "healthy") { "✅" } else if ($data.hardware.overall_health == "issues_detected") { "⚠️ " } else { "❓" }
        info $"Hardware Health: ($status_icon) ($data.hardware.overall_health)"
        if ($data.hardware.usb_errors > 0) {
            info $"USB Errors (1h): ($data.hardware.usb_errors)"
        }
        if ($data.hardware.i2c_errors > 0) {
            info $"I2C Errors (1h): ($data.hardware.i2c_errors)"  
        }
        if not $data.hardware.emi_healthy {
            info "EMI Interference: Detected"
        }
    }
}

# Placeholder dashboard functions
def performance_dashboard [refresh: int, watch: bool, output: string, format: string] {
    info "Performance dashboard - collecting performance metrics..."
    let data = (collect_basic_data)
    display_basic_info $data $format
}

def testing_dashboard [refresh: int, watch: bool, output: string, format: string] {
    info "Testing dashboard - collecting test results..."
    let data = (collect_basic_data)
    display_basic_info $data $format
}

def coverage_dashboard [refresh: int, watch: bool, output: string, format: string] {
    info "Coverage dashboard - collecting coverage data..."
    let data = (collect_basic_data)
    display_basic_info $data $format
}

def security_dashboard [refresh: int, watch: bool, output: string, format: string] {
    info "Security dashboard - collecting security status..."
    let data = (collect_security_data)
    
    if $format == "json" or not ($output | is-empty) {
        display_security_json $data $format
    } else {
        display_security_info $data $format
    }
    
    if not ($output | is-empty) {
        save_data $data $output
    }
}

def gaming_dashboard [refresh: int, watch: bool, output: string, format: string] {
    info "Gaming dashboard - collecting gaming system status..."
    let data = (collect_basic_data)
    display_basic_info $data $format
}

def analysis_dashboard [refresh: int, watch: bool, output: string, format: string] {
    info "Analysis dashboard - collecting system analysis..."
    let data = (collect_basic_data)
    display_basic_info $data $format
}

def quick_status_dashboard [] {
    banner "Quick Status"
    let data = (collect_basic_data)
    display_basic_info $data "table"
}

# Security-specific data collection
def collect_security_data [] {
    let basic = (collect_basic_data)
    
    # Check for common security indicators
    let nix_store_permissions = (try {
        let store_info = (^ls -la /nix/store | head -5 | complete)
        if $store_info.exit_code == 0 { "accessible" } else { "restricted" }
    } catch { "unknown" })
    
    let firewall_status = (try {
        # Check if iptables binary exists (indicates firewall capability)
        if (which iptables | is-not-empty) { "available" } else { "not_available" }
    } catch { "unknown" })
    
    let ssh_status = (try {
        # Check if ssh/sshd binaries exist
        if (which ssh | is-not-empty) { "ssh_client_available" } else { "not_available" }
    } catch { "unknown" })
    
    # Security scan results
    let security_analysis = {
        nix_store_permissions: $nix_store_permissions,
        firewall_status: $firewall_status,  
        ssh_service: $ssh_status,
        scan_timestamp: (date now),
        security_level: "basic_scan"
    }
    
    $basic | merge { security: $security_analysis }
}

# Security display functions
def display_security_info [data: record, format: string] {
    display_basic_info $data $format
    
    if "security" in $data {
        info $"Nix Store: ($data.security.nix_store_permissions)"
        info $"Firewall: ($data.security.firewall_status)"  
        info $"SSH Service: ($data.security.ssh_service)"
        info $"Security Level: ($data.security.security_level)"
    }
}

def display_security_json [data: record, format: string] {
    # For JSON format, just return the data structure
    $data | to json | print
}

# Data saving function
def save_data [data: record, output: string] {
    try {
        $data | to json | save $output
        success $"Dashboard data saved to: ($output)"
    } catch { |err|
        warn $"Failed to save dashboard data: ($err.msg)"
    }
}

# Help function
def show_dashboard_help [] {
    print "nix-mox Dashboard System"
    print "======================="
    print ""
    print "Usage: nu dashboard.nu [view] [options]"
    print ""
    print "Available views:"
    print "  overview     - System overview (default)"
    print "  system       - Detailed system information"
    print "  performance  - Performance metrics"
    print "  testing      - Test results and status"
    print "  coverage     - Test coverage information"
    print "  security     - Security status"
    print "  gaming       - Gaming system status"
    print "  analysis     - System analysis"
    print "  quick        - Quick status overview"
    print ""
    print "Options:"
    print "  --refresh N    - Refresh interval in seconds (default: 5)"
    print "  --watch        - Continuous monitoring mode"
    print "  --output PATH  - Save data to file"
    print "  --format TYPE  - Output format (table, json)"
    print "  --help         - Show this help"
}