#!/usr/bin/env nu
# Modular dashboard system for nix-mox
# Refactored from monolithic 1255-line file into focused modules
# Uses functional patterns for data collection and presentation

use lib/logging.nu *
use lib/platform.nu *
use lib/validators.nu *
use lib/command-wrapper.nu *
use lib/script-template.nu *
use lib/testing.nu *
use lib/constants.nu *

# Import dashboard modules
use dashboard/core.nu *
use dashboard/data-collectors.nu *
use dashboard/displays.nu *

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

    banner "nix-mox Dashboard System" $CONTEXTS.dashboard
    
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
        "size-analysis" => (size_analysis_dashboard $refresh $watch $output $format),
        "project-status" => (project_status_dashboard $refresh $watch $output $format),
        "quick" => (quick_status_dashboard),
        _ => {
            error $"Unknown dashboard view: ($view)" --context "dashboard"
            info "Available views: overview, system, performance, testing, coverage, security, gaming, analysis, size-analysis, project-status, quick" --context "dashboard"
        }
    }
}

# Show dashboard help information
def show_dashboard_help [] {
    print "nix-mox Dashboard System"
    print "========================"
    print ""
    print "Usage: nu dashboard.nu [view] [options]"
    print ""
    print "Available views:"
    print "  overview        - System overview (default)"
    print "  system          - Detailed system information"  
    print "  performance     - Performance metrics"
    print "  testing         - Test results and coverage"
    print "  coverage        - Code coverage analysis"
    print "  security        - Security status"
    print "  gaming          - Gaming system status"
    print "  analysis        - Package and dependency analysis"
    print "  size-analysis   - Size analysis dashboard"
    print "  project-status  - Project status dashboard"
    print "  quick           - Quick non-interactive status"
    print ""
    print "Options:"
    print "  --refresh N     - Refresh interval in seconds (default: 5)"
    print "  --watch         - Enable watch mode (continuous updates)"
    print "  --output PATH   - Save output to file"
    print "  --format FORMAT - Output format: table, json (default: table)"
    print "  --help          - Show this help message"
    print ""
    print "Examples:"
    print "  nu dashboard.nu                           # Overview dashboard"
    print "  nu dashboard.nu system --watch            # Watch system dashboard"
    print "  nu dashboard.nu performance --refresh 2   # Performance with 2s refresh"
    print "  nu dashboard.nu overview --format json    # JSON output format"
    print "  nu dashboard.nu quick                     # Quick status check"
}

# Legacy compatibility functions for Makefile
export def overview [] { main "overview" }
export def system [] { main "system" }
export def performance [] { main "performance" } 
export def testing [] { main "testing" }
export def coverage [] { main "coverage" }
export def security [] { main "security" }
export def gaming [] { main "gaming" }
export def analysis [] { main "analysis" }