#!/usr/bin/env nu

# Import unified libraries
use ../lib/unified-checks.nu
use ../lib/unified-error-handling.nu


# Simple nix-mox Dashboard
# Shows system status without complex formatting

use ../lib/unified-logging.nu *
use ../lib/unified-error-handling.nu *

def show_simple_dashboard [] {
    print "╔══════════════════════════════════════════════════════════════════════════════╗"
    print "║                           nix-mox System Dashboard                           ║"
    print "╠══════════════════════════════════════════════════════════════════════════════╣"
    
    # System Information
    print "║ 🖥️  System Information                                                       ║"
    let hostname = try { hostname } catch { "unknown" }
    let platform = try { detect_platform } catch { "unknown" }
    let os_info = try { sys host } catch { {} }
    
    print $"║   Hostname:    ($hostname)                                                    ║"
    print $"║   Platform:    ($platform)                                                   ║"
    print $"║   OS Info:     ($os_info.name? | default 'Unknown OS')                       ║"
    print "║                                                                              ║"
    
    # Test Status
    print "║ 🧪 Test Status                                                               ║"
    let test_status = get_test_summary
    print $"║   Total Tests: ($test_status.total)                                          ║"
    print $"║   Passed:      ($test_status.passed)                                         ║"
    print $"║   Failed:      ($test_status.failed)                                         ║"
    print $"║   Pass Rate:   ($test_status.pass_rate)%                                     ║"
    print "║                                                                              ║"
    
    # Services Status
    print "║ ⚙️  Services                                                                 ║"
    let services = check_services
    for service in $services {
        let status_symbol = if $service.status == "active" { "●" } else { "○" }
        print $"║   ($status_symbol) ($service.name): ($service.status)                        ║"
    }
    print "║                                                                              ║"
    
    # Recent Activity
    print "║ 📋 Recent Activity                                                           ║"
    let logs = get_recent_activity
    for log in $logs {
        let truncated = if ($log | str length) > 70 { ($log | str substring 0..67) + "..." } else { $log }
        print $"║   ($truncated)                                                              ║"
    }
    
    print "╠══════════════════════════════════════════════════════════════════════════════╣"
    print $"║ Last Updated: (date now | format date '%Y-%m-%d %H:%M:%S')                  ║"
    print "║ Commands: [r]efresh, [t]est, [h]ealth, [q]uit                               ║"
    print "╚══════════════════════════════════════════════════════════════════════════════╝"
}

def get_test_summary [] {
    let coverage_file = "/tmp/nix-mox-test-coverage.json"
    
    if ($coverage_file | path exists) {
        try {
            let data = (open $coverage_file | from json)
            let total = ($data.total_tests? | default 0)
            let passed = ($data.passed_tests? | default 0)
            let failed = ($data.failed_tests? | default 0)
            let pass_rate = if $total > 0 { ($passed * 100 / $total) } else { 0 }
            
            {
                total: $total,
                passed: $passed,
                failed: $failed,
                pass_rate: ($pass_rate | math round)
            }
        } catch {
            { total: 0, passed: 0, failed: 0, pass_rate: 0 }
        }
    } else {
        { total: 0, passed: 0, failed: 0, pass_rate: 0 }
    }
}

def check_services [] {
    let service_names = ["ssh", "systemd-resolved", "NetworkManager"]
    mut services = []
    
    for service in $service_names {
        let status = try {
            let result = (systemctl is-active $service | complete)
            if $result.exit_code == 0 { "active" } else { "inactive" }
        } catch {
            "unknown"
        }
        
        $services = ($services | append { name: $service, status: $status })
    }
    
    $services
}

def get_recent_activity [] {
    let log_file = "/tmp/nix-mox.log"
    
    if ($log_file | path exists) {
        try {
            open $log_file | lines | last 5
        } catch {
            ["No recent activity"]
        }
    } else {
        ["Log file not found", "Run some nix-mox commands to see activity"]
    }
}

def run_interactive [] {
    print "Starting interactive dashboard..."
    print "Use Ctrl+C to exit"
    
    while true {
        print $"(ansi cls)"
        show_simple_dashboard
        
        print "\nPress any key + Enter (or q to quit):"
        let input = (input "")
        
        match ($input | str trim) {
            "q" | "quit" => break
            "r" | "refresh" => continue
            "t" | "test" => {
                print "Running tests..."
                nu scripts/testing/run-tests.nu
                input "Press Enter to continue..."
            }
            "h" | "health" => {
                print "Running health check..."
                nu scripts/maintenance/health-check.nu
                input "Press Enter to continue..."
            }
            _ => continue
        }
    }
}

def main [mode?: string] {
    match $mode {
        "interactive" | "i" => run_interactive
        "help" | "h" => {
            print "nix-mox Simple Dashboard"
            print "Usage: nu scripts/analysis/simple-dashboard.nu [mode]"
            print ""
            print "Modes:"
            print "  (none)        - Show dashboard once"
            print "  interactive   - Interactive mode with refresh"
            print "  help          - Show this help"
        }
        _ => show_simple_dashboard
    }
}

# Run main function
main