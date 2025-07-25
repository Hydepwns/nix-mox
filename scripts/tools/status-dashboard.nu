#!/usr/bin/env nu

# nix-mox Status Dashboard
# Simple system status display

use ../lib/platform.nu *

# Show the dashboard
print "╔══════════════════════════════════════════════════════════════════════════════╗"
print "║                           nix-mox System Status                              ║"
print "╠══════════════════════════════════════════════════════════════════════════════╣"

# System Information
print "║ 🖥️  System Information                                                       ║"
let hostname = try { hostname } catch { "unknown" }
let platform = try { detect_platform } catch { "unknown" }
let os_info = try { sys host } catch { {} }

print $"║   Hostname:     ($hostname)                                              ║"
print $"║   Platform:     ($platform)                                             ║"
print $"║   OS:           ($os_info.name? | default 'Unknown OS')                  ║"
print "║                                                                              ║"

# Quick Status Checks
print "║ ⚡ Quick Status                                                               ║"
let nix_available = try { (which nix | length) > 0 } catch { false }
let nu_available = try { (which nu | length) > 0 } catch { false }
let git_available = try { (which git | length) > 0 } catch { false }

let nix_symbol = if $nix_available { "✅" } else { "❌" }
let nu_symbol = if $nu_available { "✅" } else { "❌" }
let git_symbol = if $git_available { "✅" } else { "❌" }

print $"║   Nix:          ($nix_symbol) Available                                      ║"
print $"║   Nushell:      ($nu_symbol) Available                                      ║"
print $"║   Git:          ($git_symbol) Available                                      ║"
print "║                                                                              ║"

# Test Status  
print "║ 🧪 Test Information                                                          ║"
let test_coverage_file = "/tmp/nix-mox-tests/coverage.json"
if ($test_coverage_file | path exists) {
    try {
        let data = (open $test_coverage_file | from json)
        let total = ($data.total_tests? | default 0)
        let passed = ($data.passed_tests? | default 0)
        let pass_rate = if $total > 0 { ($passed * 100 / $total) } else { 0 }
        print $"║   Total Tests:  ($total)                                                ║"
        print $"║   Passed:       ($passed)                                               ║"
        print $"║   Pass Rate:    ($pass_rate | math round)%                                        ║"
    } catch {
        print "║   No test data available                                                 ║"
    }
} else {
    print "║   No test coverage file found                                            ║"
    print "║   Run: nu scripts/tests/run-tests.nu                                    ║"
}
print "║                                                                              ║"

# Available Commands
print "║ 🛠️  Available Commands                                                       ║"
print "║   Health Check:     nu scripts/core/health-check.nu                         ║"
print "║   Run Tests:        nu scripts/tests/run-tests.nu                           ║"
print "║   Interactive Setup: nu scripts/core/interactive-setup.nu                   ║"
print "║   Project Cleanup:  nu scripts/tools/cleanup.nu                            ║"

print "╠══════════════════════════════════════════════════════════════════════════════╣"
print $"║ Generated: (date now | format date '%Y-%m-%d %H:%M:%S')                                        ║"
print "╚══════════════════════════════════════════════════════════════════════════════╝"