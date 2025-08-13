#!/usr/bin/env nu

# nix-mox Interactive Dashboard
# Real-time system status and monitoring dashboard

use ../lib/platform.nu *
use ../lib/logging.nu *
use ../lib/error-handling.nu *
use ../lib/performance.nu *
use ../lib/common.nu *

# Import modular components
use ./modules/system.nu *
use ./modules/display.nu *

# Global dashboard state
let DASHBOARD_VERSION = "1.0.0"
let REFRESH_INTERVAL = 5  # seconds
let DASHBOARD_TITLE = "nix-mox System Dashboard"

# Dashboard configuration
let DASHBOARD_CONFIG = {
    show_header: true,
    show_system_info: true,
    show_test_status: true,
    show_metrics: true,
    show_services: true,
    show_recent_logs: true,
    auto_refresh: true,
    max_log_lines: 10
}

# Initialize dashboard
def init_dashboard [] {
    clear_screen
    hide_cursor
}

# Cleanup dashboard
def cleanup_dashboard [] {
    show_cursor
}

# Get test status
def get_test_status [] {
    let test_coverage_file = "/tmp/nix-mox-test-coverage.json"
    
    if ($test_coverage_file | path exists) {
        try {
            let coverage_data = (open $test_coverage_file | from json)
            {
                total_tests: ($coverage_data.total_tests? | default 0),
                passed_tests: ($coverage_data.passed_tests? | default 0),
                failed_tests: ($coverage_data.failed_tests? | default 0),
                skipped_tests: ($coverage_data.skipped_tests? | default 0),
                coverage_percent: ($coverage_data.coverage_percent? | default 0.0),
                last_run: ($coverage_data.last_run? | default "Never")
            }
        } catch {
            create_default_test_status
        }
    } else {
        create_default_test_status
    }
}

def create_default_test_status [] {
    {
        total_tests: 0,
        passed_tests: 0,
        failed_tests: 0,
        skipped_tests: 0,
        coverage_percent: 0.0,
        last_run: "Never"
    }
}

# Main dashboard update function
def update_dashboard [] {
    move_cursor_to_top
    
    # Render header
    if $DASHBOARD_CONFIG.show_header {
        render_header $DASHBOARD_TITLE $DASHBOARD_VERSION
    }
    
    # Get system information
    let system_info = get_system_overview
    let health_status = get_system_health
    let service_info = get_service_status
    let process_info = get_process_info
    let test_status = get_test_status
    
    # Render system information
    if $DASHBOARD_CONFIG.show_system_info {
        render_system_info $system_info
    }
    
    # Render performance metrics
    if $DASHBOARD_CONFIG.show_metrics {
        render_performance_metrics $system_info
        render_health_status $health_status
    }
    
    # Render service status
    if $DASHBOARD_CONFIG.show_services {
        render_service_status $service_info
        render_process_info $process_info
    }
    
    # Render test status
    if $DASHBOARD_CONFIG.show_test_status {
        render_test_status $test_status
    }
    
    # Render footer
    render_footer $REFRESH_INTERVAL
}

# Main dashboard loop
def run_dashboard [] {
    init_dashboard
    
    # Set up signal handling for cleanup
    def cleanup [] {
        cleanup_dashboard
        print "\n(ansi green)Dashboard stopped.(ansi reset)"
        exit 0
    }
    
    # Main loop
    loop {
        try {
            update_dashboard
            sleep $REFRESH_INTERVAL
        } catch { |err|
            print $"(ansi red)Error updating dashboard: ($err)(ansi reset)"
            sleep 2
        }
    }
}

# Quick status check (non-interactive)
export def quick_status [] {
    let system_info = get_system_overview
    let health_status = get_system_health
    
    print $"(ansi blue)=== Quick System Status ===(ansi reset)"
    print $"Hostname: ($system_info.hostname)"
    print $"Platform: ($system_info.platform)"
    print $"CPU Usage: ($system_info.cpu_usage | into string -d 1)%"
    print $"Memory Usage: ($system_info.memory_usage | into string -d 1)%"
    print $"Health Status: ($health_status.overall)"
    
    if ($health_status.issues | length) > 0 {
        print $"(ansi red)Issues: ($health_status.issues | str join ', ')(ansi reset)"
    }
    
    if ($health_status.warnings | length) > 0 {
        print $"(ansi yellow)Warnings: ($health_status.warnings | str join ', ')(ansi reset)"
    }
}

# Export main functions
export def main [] {
    if ($env | get -i QUICK | default "false") == "true" {
        quick_status
    } else {
        run_dashboard
    }
}

# Run if called directly
if ($env | get -i NU_DASHBOARD | default "false") == "true" {
    main
}