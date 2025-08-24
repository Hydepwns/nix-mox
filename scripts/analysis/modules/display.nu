#!/usr/bin/env nu

# Import unified libraries
use ../../lib/unified-checks.nu
use ../../lib/enhanced-error-handling.nu


# Display module for dashboard
# Handles dashboard rendering, formatting, and UI components

# Helper function to repeat a string
def repeat_string [str: string, count: int] {
    if $count <= 0 {
        ""
    } else {
        1..$count | each { $str } | str join
    }
}

export def render_header [title: string, version: string] {
    let title_length = ($title | str length)
    let version_length = ($version | str length)
    let total_length = $title_length + $version_length + 3
    
    let header_line = (repeat_string "=" $total_length)
    
    print $"(ansi blue)($header_line)(ansi reset)"
    print $"(ansi blue)$title (ansi yellow)v$version(ansi reset)"
    print $"(ansi blue)($header_line)(ansi reset)"
    print ""
}

export def render_system_info [system_info: record] {
    print $"(ansi cyan)🖥️  System Information(ansi reset)"
    print $"(ansi cyan)===================(ansi reset)"
    print $"Hostname: (ansi green)($system_info.hostname)(ansi reset)"
    print $"Platform: (ansi green)($system_info.platform)(ansi reset)"
    print $"OS Version: (ansi green)($system_info.os_version)(ansi reset)"
    print $"Architecture: (ansi green)($system_info.architecture)(ansi reset)"
    print $"Uptime: (ansi green)($system_info.uptime | into string -d 0)s(ansi reset)"
    print ""
}

export def render_performance_metrics [system_info: record] {
    print $"(ansi cyan)📊 Performance Metrics(ansi reset)"
    print $"(ansi cyan)====================(ansi reset)"
    
    # CPU usage with color coding
    let cpu_color = if $system_info.cpu_usage > 80.0 { "red" } else if $system_info.cpu_usage > 60.0 { "yellow" } else { "green" }
    print $"CPU Usage: (ansi $cpu_color)($system_info.cpu_usage | into string -d 1)%(ansi reset)"
    
    # Memory usage with color coding
    let mem_color = if $system_info.memory_usage > 85.0 { "red" } else if $system_info.memory_usage > 70.0 { "yellow" } else { "green" }
    print $"Memory Usage: (ansi $mem_color)($system_info.memory_usage | into string -d 1)%(ansi reset)"
    
    # Load average
    let load_avg = $system_info.load_average
    if ($load_avg | length) >= 3 {
        let load_color = if ($load_avg | get 0) > 2.0 { "red" } else if ($load_avg | get 0) > 1.0 { "yellow" } else { "green" }
        print $"Load Average: (ansi $load_color)($load_avg | get 0 | into string -d 2), ($load_avg | get 1 | into string -d 2), ($load_avg | get 2 | into string -d 2)(ansi reset)"
    }
    
    print ""
}

export def render_health_status [health_status: record] {
    print $"(ansi cyan)🏥 System Health(ansi reset)"
    print $"(ansi cyan)===============(ansi reset)"
    
    let status_color = if $health_status.overall == "critical" { "red" } else if $health_status.overall == "warning" { "yellow" } else { "green" }
    print $"Overall Status: (ansi $status_color)($health_status.overall | str title-case)(ansi reset)"
    
    if ($health_status.issues | length) > 0 {
        print $"(ansi red)🚨 Issues:(ansi reset)"
        $health_status.issues | each { |issue|
            print $"  • $issue"
        }
    }
    
    if ($health_status.warnings | length) > 0 {
        print $"(ansi yellow)⚠️  Warnings:(ansi reset)"
        $health_status.warnings | each { |warning|
            print $"  • $warning"
        }
    }
    
    print ""
}

export def render_service_status [service_info: record] {
    print $"(ansi cyan)🔧 Services(ansi reset)"
    print $"(ansi cyan)==========(ansi reset)"
    print $"Active: (ansi green)($service_info.active_count)/($service_info.total_count)(ansi reset)"
    
    $service_info.services | each { |service|
        let status_color = if $service.active { "green" } else { "red" }
        let status_icon = if $service.active { "✅" } else { "❌" }
        print $"  $status_icon ($service.name): (ansi $status_color)($service.status)(ansi reset)"
    }
    
    print ""
}

export def render_process_info [process_info: record] {
    print $"(ansi cyan)⚙️  Top Processes(ansi reset)"
    print $"(ansi cyan)===============(ansi reset)"
    
    if ($process_info.top_processes | length) > 0 {
        $process_info.top_processes | take 5 | each { |process|
            let cpu_color = if $process.cpu > 50.0 { "red" } else if $process.cpu > 20.0 { "yellow" } else { "green" }
            let mem_color = if $process.mem > 10.0 { "red" } else if $process.mem > 5.0 { "yellow" } else { "green" }
            
            print $"  PID ($process.pid): (ansi $cpu_color)($process.cpu | into string -d 1)% CPU(ansi reset), (ansi $mem_color)($process.mem | into string -d 1)% MEM(ansi reset)"
            print $"    ($process.command | str substring 0..50)..."
        }
    }
    
    print $"Total Processes: (ansi blue)($process_info.total_processes)(ansi reset)"
    print ""
}

export def render_test_status [test_status: record] {
    print $"(ansi cyan)🧪 Test Status(ansi reset)"
    print $"(ansi cyan)=============(ansi reset)"
    
    let total_tests = $test_status.total_tests
    let passed_tests = $test_status.passed_tests
    let failed_tests = $test_status.failed_tests
    let coverage = $test_status.coverage_percent
    
    print $"Total Tests: (ansi blue)($total_tests)(ansi reset)"
    print $"Passed: (ansi green)($passed_tests)(ansi reset)"
    print $"Failed: (ansi red)($failed_tests)(ansi reset)"
    print $"Coverage: (ansi blue)($coverage | into string -d 1)%(ansi reset)"
    print $"Last Run: (ansi yellow)($test_status.last_run)(ansi reset)"
    print ""
}

export def render_footer [refresh_interval: int] {
    let footer_line = (repeat_string "=" 50)
    print $"(ansi blue)($footer_line)(ansi reset)"
    print $"(ansi blue)Auto-refresh every ($refresh_interval)s | Press Ctrl+C to exit(ansi reset)"
    print $"(ansi blue)($footer_line)(ansi reset)"
}

export def clear_screen [] {
    print $"(ansi cls)"
}

export def hide_cursor [] {
    print $"(ansi cursor_hide)"
}

export def show_cursor [] {
    print $"(ansi cursor_show)"
}

export def move_cursor_to_top [] {
    print $"(ansi home)"
} 