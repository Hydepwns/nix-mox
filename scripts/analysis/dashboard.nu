#!/usr/bin/env nu

# nix-mox Interactive Dashboard
# Real-time system status and monitoring dashboard

use ../lib/platform.nu *
use ../lib/logging.nu *
use ../lib/error-handling.nu *
use ../lib/performance.nu *
use ../lib/common.nu *
# use ../lib/metrics.nu *  # Disabled due to syntax issues

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

# Helper function to repeat a string
def repeat_string [str: string, count: int] {
    if $count <= 0 {
        ""
    } else {
        1..$count | each { $str } | str join
    }
}

# Initialize dashboard
def init_dashboard [] {
    # Initialize metrics if available
    # try {
    #     init_core_metrics
    # } catch {
    #     log_debug "Metrics system not available"
    # }
    
    # Clear screen and hide cursor
    print $"(ansi cls)(ansi cursor_hide)"
}

# Cleanup dashboard
def cleanup_dashboard [] {
    print $"(ansi cursor_show)"
}

# Get system overview
def get_system_overview [] {
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

# Get service status
def get_service_status [] {
    let services = ["prometheus", "grafana", "nginx", "ssh"]
    mut service_status = []
    
    for service in $services {
        let status = try {
            let result = (systemctl is-active $service | complete)
            if $result.exit_code == 0 {
                "active"
            } else {
                "inactive"
            }
        } catch {
            "unknown"
        }
        
        $service_status = ($service_status | append {
            name: $service,
            status: $status
        })
    }
    
    $service_status
}

# Get metrics summary
def get_metrics_summary [] {
    let metrics_file = "/tmp/nix-mox-metrics.prom"
    
    if ($metrics_file | path exists) {
        try {
            let metrics_content = (open $metrics_file)
            let lines = ($metrics_content | lines)
            
            {
                total_metrics: ($lines | length),
                script_executions: (extract_metric_value $metrics_content "nix_mox_script_executions_total"),
                script_failures: (extract_metric_value $metrics_content "nix_mox_script_failures_total"),
                avg_duration: (extract_metric_value $metrics_content "nix_mox_script_duration_seconds"),
                last_updated: (date now | format date "%Y-%m-%d %H:%M:%S")
            }
        } catch {
            create_default_metrics_summary
        }
    } else {
        create_default_metrics_summary
    }
}

def create_default_metrics_summary [] {
    {
        total_metrics: 0,
        script_executions: 0,
        script_failures: 0,
        avg_duration: 0.0,
        last_updated: "Never"
    }
}

# Extract metric value from Prometheus format
def extract_metric_value [content: string, metric_name: string] {
    let lines = ($content | lines | where { |line| $line | str starts-with $metric_name })
    if ($lines | length) > 0 {
        let first_line = ($lines | first)
        let value = ($first_line | split row " " | last)
        try {
            $value | into float
        } catch {
            0.0
        }
    } else {
        0.0
    }
}

# Get recent logs
def get_recent_logs [] {
    let log_file = "/tmp/nix-mox.log"
    
    if ($log_file | path exists) {
        try {
            open $log_file | lines | last $DASHBOARD_CONFIG.max_log_lines
        } catch {
            ["No logs available"]
        }
    } else {
        ["Log file not found"]
    }
}

# Format uptime in human readable format
def format_uptime [seconds: int] {
    let days = ($seconds / 86400)
    let hours = (($seconds mod 86400) / 3600)
    let minutes = (($seconds mod 3600) / 60)
    
    if $days > 0 {
        $"($days)d ($hours)h ($minutes)m"
    } else if $hours > 0 {
        $"($hours)h ($minutes)m"
    } else {
        $"($minutes)m"
    }
}

# Format percentage with color
def format_percentage [value: float, warning_threshold: float = 75.0, critical_threshold: float = 90.0] {
    if $value >= $critical_threshold {
        $"(ansi red_bold)($value | math round --precision 1)%(ansi reset)"
    } else if $value >= $warning_threshold {
        $"(ansi yellow_bold)($value | math round --precision 1)%(ansi reset)"
    } else {
        $"(ansi green_bold)($value | math round --precision 1)%(ansi reset)"
    }
}

# Format service status with color
def format_service_status [status: string] {
    match $status {
        "active" => $"(ansi green_bold)●(ansi reset) active"
        "inactive" => $"(ansi red_bold)●(ansi reset) inactive"
        _ => $"(ansi yellow_bold)●(ansi reset) unknown"
    }
}

# Draw dashboard header
def draw_header [] {
    let width = 80
    let title_len = ($DASHBOARD_TITLE | str length)
    let padding = (($width - $title_len - 4) / 2)
    let left_border = (0..$padding | each { "═" } | str join)
    let right_border = (0..($width - $title_len - 4 - $padding) | each { "═" } | str join)
    
    print $"(ansi blue_bold)╔═($left_border)═ ($DASHBOARD_TITLE) ═($right_border)═╗(ansi reset)"
    print $"(ansi blue_bold)║(ansi reset)" + (" " | str repeat ($width - 2)) + $"(ansi blue_bold)║(ansi reset)"
}

# Draw dashboard footer
def draw_footer [] {
    let width = 80
    let timestamp = (date now | format date "%Y-%m-%d %H:%M:%S")
    let version_text = $"v($DASHBOARD_VERSION)"
    let status_text = $"Last updated: ($timestamp)"
    let left_padding = ($width - ($version_text | str length) - ($status_text | str length) - 4)
    
    print $"(ansi blue_bold)║(ansi reset)" + (" " | str repeat ($width - 2)) + $"(ansi blue_bold)║(ansi reset)"
    print $"(ansi blue_bold)║(ansi reset) (ansi dim)($version_text)(ansi reset)" + (" " | str repeat $left_padding) + $"(ansi dim)($status_text)(ansi reset) (ansi blue_bold)║(ansi reset)"
    print $"(ansi blue_bold)╚═(" + ("═" | str repeat ($width - 4)) + ")═╝(ansi reset)"
}

# Draw system information section
def draw_system_info [system: record] {
    print $"(ansi blue_bold)║(ansi reset) (ansi cyan_bold)🖥️  System Information(ansi reset)" + (" " | str repeat 54) + $"(ansi blue_bold)║(ansi reset)"
    print $"(ansi blue_bold)║(ansi reset)   Hostname:     ($system.hostname)" + (" " | str repeat (65 - ($system.hostname | str length))) + $"(ansi blue_bold)║(ansi reset)"
    print $"(ansi blue_bold)║(ansi reset)   Platform:     ($system.platform) ($system.architecture)" + (" " | str repeat (58 - (($system.platform + " " + $system.architecture) | str length))) + $"(ansi blue_bold)║(ansi reset)"
    print $"(ansi blue_bold)║(ansi reset)   OS Version:   ($system.os_version)" + (" " | str repeat (65 - ($system.os_version | str length))) + $"(ansi blue_bold)║(ansi reset)"
    print $"(ansi blue_bold)║(ansi reset)   Uptime:       (format_uptime $system.uptime)" + (" " | str repeat (65 - ((format_uptime $system.uptime) | str length))) + $"(ansi blue_bold)║(ansi reset)"
    print $"(ansi blue_bold)║(ansi reset)   CPU Usage:    (format_percentage $system.cpu_usage)" + (" " | str repeat (58 - ((format_percentage $system.cpu_usage) | str length))) + $"(ansi blue_bold)║(ansi reset)"  
    print $"(ansi blue_bold)║(ansi reset)   Memory:       (format_percentage $system.memory_usage)" + (" " | str repeat (58 - ((format_percentage $system.memory_usage) | str length))) + $"(ansi blue_bold)║(ansi reset)"
    print $"(ansi blue_bold)║(ansi reset)" + (" " | str repeat 78) + $"(ansi blue_bold)║(ansi reset)"
}

# Draw test status section
def draw_test_status [tests: record] {
    let pass_rate = if $tests.total_tests > 0 { 
        ($tests.passed_tests * 100.0 / $tests.total_tests) 
    } else { 
        0.0 
    }
    
    print $"(ansi blue_bold)║(ansi reset) (ansi green_bold)🧪 Test Status(ansi reset)" + (" " | str repeat 61) + $"(ansi blue_bold)║(ansi reset)"
    print $"(ansi blue_bold)║(ansi reset)   Total Tests:  ($tests.total_tests)" + (" " | str repeat (65 - (($tests.total_tests | into string) | str length))) + $"(ansi blue_bold)║(ansi reset)"
    print $"(ansi blue_bold)║(ansi reset)   Passed:       (ansi green)($tests.passed_tests)(ansi reset)    Failed: (ansi red)($tests.failed_tests)(ansi reset)    Skipped: (ansi yellow)($tests.skipped_tests)(ansi reset)" + (" " | str repeat (30 - (($tests.passed_tests | into string) | str length) - (($tests.failed_tests | into string) | str length) - (($tests.skipped_tests | into string) | str length))) + $"(ansi blue_bold)║(ansi reset)"
    print $"(ansi blue_bold)║(ansi reset)   Pass Rate:    (format_percentage $pass_rate)" + (" " | str repeat (58 - ((format_percentage $pass_rate) | str length))) + $"(ansi blue_bold)║(ansi reset)"
    print $"(ansi blue_bold)║(ansi reset)   Last Run:     ($tests.last_run)" + (" " | str repeat (65 - ($tests.last_run | str length))) + $"(ansi blue_bold)║(ansi reset)"
    print $"(ansi blue_bold)║(ansi reset)" + (" " | str repeat 78) + $"(ansi blue_bold)║(ansi reset)"
}

# Draw metrics section
def draw_metrics [metrics: record] {
    let failure_rate = if $metrics.script_executions > 0 {
        ($metrics.script_failures * 100.0 / $metrics.script_executions)
    } else {
        0.0
    }
    
    print $"(ansi blue_bold)║(ansi reset) (ansi magenta_bold)📊 Metrics Summary(ansi reset)" + (" " | str repeat 56) + $"(ansi blue_bold)║(ansi reset)"
    print $"(ansi blue_bold)║(ansi reset)   Script Runs:  ($metrics.script_executions)" + (" " | str repeat (65 - (($metrics.script_executions | into string) | str length))) + $"(ansi blue_bold)║(ansi reset)"
    print $"(ansi blue_bold)║(ansi reset)   Failures:     ($metrics.script_failures) ((format_percentage $failure_rate))" + (" " | str repeat (52 - (($metrics.script_failures | into string) | str length) - ((format_percentage $failure_rate) | str length))) + $"(ansi blue_bold)║(ansi reset)"
    print $"(ansi blue_bold)║(ansi reset)   Avg Duration: ($metrics.avg_duration | math round --precision 2)s" + (" " | str repeat (61 - ((($metrics.avg_duration | math round --precision 2) | into string) | str length))) + $"(ansi blue_bold)║(ansi reset)"
    print $"(ansi blue_bold)║(ansi reset)   Updated:      ($metrics.last_updated)" + (" " | str repeat (65 - ($metrics.last_updated | str length))) + $"(ansi blue_bold)║(ansi reset)"
    print $"(ansi blue_bold)║(ansi reset)" + (" " | str repeat 78) + $"(ansi blue_bold)║(ansi reset)"
}

# Draw services section
def draw_services [services: list] {
    print $"(ansi blue_bold)║(ansi reset) (ansi yellow_bold)⚙️  Services(ansi reset)" + (" " | str repeat 63) + $"(ansi blue_bold)║(ansi reset)"
    
    let services_per_row = 4
    let rows = ($services | group $services_per_row)
    
    for row in $rows {
        mut line = "   "
        for service in $row {
            let status_text = $"($service.name): (format_service_status $service.status)"
            $line = $line + $status_text + "  "
        }
        let padding = (75 - ($line | str length))
        print $"(ansi blue_bold)║(ansi reset) ($line)" + (" " | str repeat $padding) + $"(ansi blue_bold)║(ansi reset)"
    }
    print $"(ansi blue_bold)║(ansi reset)" + (" " | str repeat 78) + $"(ansi blue_bold)║(ansi reset)"
}

# Draw recent logs section
def draw_recent_logs [logs: list] {
    print $"(ansi blue_bold)║(ansi reset) (ansi white_bold)📋 Recent Logs(ansi reset)" + (" " | str repeat 59) + $"(ansi blue_bold)║(ansi reset)"
    
    for log in $logs {
        let log_line = if ($log | str length) > 74 {
            ($log | str substring 0..71) + "..."
        } else {
            $log
        }
        let padding = (76 - ($log_line | str length))
        print $"(ansi blue_bold)║(ansi reset)  (ansi dim)($log_line)(ansi reset)" + (" " | str repeat $padding) + $"(ansi blue_bold)║(ansi reset)"
    }
    print $"(ansi blue_bold)║(ansi reset)" + (" " | str repeat 78) + $"(ansi blue_bold)║(ansi reset)"
}

# Draw help section
def draw_help [] {
    print $"(ansi blue_bold)║(ansi reset) (ansi cyan_bold)⌨️  Controls(ansi reset)" + (" " | str repeat 62) + $"(ansi blue_bold)║(ansi reset)"
    print $"(ansi blue_bold)║(ansi reset)   (ansi green)r(ansi reset) - Refresh    (ansi green)t(ansi reset) - Run Tests    (ansi green)m(ansi reset) - Show Metrics    (ansi green)q(ansi reset) - Quit" + (" " | str repeat 17) + $"(ansi blue_bold)║(ansi reset)"
    print $"(ansi blue_bold)║(ansi reset)   (ansi green)h(ansi reset) - Health Check    (ansi green)s(ansi reset) - Services    (ansi green)l(ansi reset) - Logs    (ansi green)c(ansi reset) - Clear" + (" " | str repeat 21) + $"(ansi blue_bold)║(ansi reset)"
}

# Main dashboard display
def display_dashboard [] {
    print $"(ansi cls)"
    
    let system = get_system_overview
    let tests = get_test_status  
    let metrics = get_metrics_summary
    let services = get_service_status
    let logs = get_recent_logs
    
    # Draw the dashboard
    draw_header
    
    if $DASHBOARD_CONFIG.show_system_info {
        draw_system_info $system
    }
    
    if $DASHBOARD_CONFIG.show_test_status {
        draw_test_status $tests
    }
    
    if $DASHBOARD_CONFIG.show_metrics {
        draw_metrics $metrics
    }
    
    if $DASHBOARD_CONFIG.show_services {
        draw_services $services
    }
    
    if $DASHBOARD_CONFIG.show_recent_logs {
        draw_recent_logs $logs
    }
    
    draw_help
    draw_footer
    
    print "\nPress any key for menu..."
}

# Handle user input
def handle_input [key: string] {
    match $key {
        "r" => {
            print "🔄 Refreshing dashboard..."
            sleep 1sec
        }
        "t" => {
            print "🧪 Running tests..."
            try {
                nu scripts/testing/run-tests.nu
                input "Tests completed. Press Enter to continue..."
            } catch {
                input "Test execution failed. Press Enter to continue..."
            }
        }
        "m" => {
            print "📊 Showing detailed metrics..."
            try {
                if ("/tmp/nix-mox-metrics.prom" | path exists) {
                    open "/tmp/nix-mox-metrics.prom"
                } else {
                    print "No metrics file found"
                }
                input "Press Enter to continue..."
            } catch {
                input "Error reading metrics. Press Enter to continue..."
            }
        }
        "h" => {
            print "🏥 Running health check..."
            try {
                nu scripts/maintenance/health-check.nu
                input "Health check completed. Press Enter to continue..."
            } catch {
                input "Health check failed. Press Enter to continue..."
            }
        }
        "s" => {
            print "⚙️ Service status details..."
            try {
                systemctl list-units --state=active --type=service | head -20
                input "Press Enter to continue..."
            } catch {
                input "Unable to get service status. Press Enter to continue..."
            }
        }
        "l" => {
            print "📋 Recent logs..."
            try {
                if ("/tmp/nix-mox.log" | path exists) {
                    tail -20 "/tmp/nix-mox.log"
                } else {
                    print "No log file found"
                }
                input "Press Enter to continue..."
            } catch {
                input "Error reading logs. Press Enter to continue..."
            }
        }
        "c" => {
            print $"(ansi cls)"
            sleep 100ms
        }
        "q" => {
            return "quit"
        }
        _ => {
            print $"Unknown command: ($key)"
            sleep 1sec
        }
    }
    ""
}

# Interactive dashboard loop
def run_interactive_dashboard [] {
    init_dashboard
    
    try {
        while true {
            display_dashboard
            
            # Get user input (simplified - in real implementation would use proper input handling)
            let key = (input "")
            let result = handle_input $key
            
            if $result == "quit" {
                break
            }
        }
    } catch {|e|
        log_error $"Dashboard error: ($e)"
    } finally {
        cleanup_dashboard
    }
}

# Simple one-time dashboard display
def show_dashboard [] {
    display_dashboard
}

# Auto-refresh dashboard (runs continuously)
def run_auto_dashboard [] {
    init_dashboard
    
    try {
        while true {
            display_dashboard
            print $"(ansi dim)Auto-refreshing in ($REFRESH_INTERVAL) seconds... (Press Ctrl+C to stop)(ansi reset)"
            sleep ($REFRESH_INTERVAL * 1sec)
        }
    } catch {|e|
        log_error $"Auto-dashboard error: ($e)"
    } finally {
        cleanup_dashboard
    }
}

# Main function - determine mode based on arguments
def main [mode?: string] {
    match $mode {
        "interactive" | "i" => run_interactive_dashboard
        "auto" | "a" => run_auto_dashboard
        "show" | "s" | null => show_dashboard
        "help" | "h" => {
            print "nix-mox Dashboard Usage:"
            print "  nu scripts/analysis/dashboard.nu [mode]"
            print ""
            print "Modes:"
            print "  show (default) - Display dashboard once"
            print "  interactive    - Interactive dashboard with controls"
            print "  auto          - Auto-refreshing dashboard"
            print "  help          - Show this help"
        }
        _ => {
            print $"Unknown mode: ($mode)"
            print "Use 'help' for available modes"
        }
    }
}

# Auto-run if executed directly
if ($env.PWD? != null) {
    main ...$argv
}