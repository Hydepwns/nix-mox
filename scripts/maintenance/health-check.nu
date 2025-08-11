#!/usr/bin/env nu

# nix-mox Health Check Script
# Comprehensive system health validation for nix-mox configurations

def show_banner [] {
    print $"\n(ansi blue_bold)🏥 nix-mox: Health Check(ansi reset)"
    print $"(ansi dark_gray)System health validation and configuration check(ansi reset)\n"
}

def check_command [cmd: string] {
    if (which $cmd | length) > 0 {
        print $"✓ Command '$cmd' is available"
        true
    } else {
        print $"✗ Command '$cmd' is not available"
        false
    }
}

def check_file [path: string] {
    if ($path | path exists) {
        print $"✓ File '$path' exists"
        true
    } else {
        print $"✗ File '$path' does not exist"
        false
    }
}

def check_directory [path: string] {
    if ($path | path exists) {
        print $"✓ Directory '$path' exists"
        true
    } else {
        print $"✗ Directory '$path' does not exist"
        false
    }
}

def check_nix_environment [] {
    print "Checking Nix environment..."
    mut checks_passed = 0
    mut total_checks = 0

    $total_checks = $total_checks + 1
    print "Checking command: nix"
    try {
        if (which nix | length) > 0 {
            $checks_passed = $checks_passed + 1
            print "✓ nix command: available"
        }
    } catch { |err|
        print $"✗ Failed to check 'nix' command. Error: ($err)"
    }

    $total_checks = $total_checks + 1
    print "Checking command: nixos-rebuild"
    try {
        if (which nixos-rebuild | length) > 0 {
            $checks_passed = $checks_passed + 1
            print "✓ nixos-rebuild command: available"
        }
    } catch { |err|
        print $"✗ Failed to check 'nixos-rebuild' command. Error: ($err)"
    }

    $total_checks = $total_checks + 1
    print "Checking command: nix-env"
    try {
        if (which nix-env | length) > 0 {
            $checks_passed = $checks_passed + 1
            print "✓ nix-env command: available"
        }
    } catch { |err|
        print $"✗ Failed to check 'nix-env' command. Error: ($err)"
    }

    print "Checking nix version"
    try {
        let nix_version = (nix --version | str trim)
        print $"✓ Nix version: ($nix_version)"
        $checks_passed = $checks_passed + 1
    } catch { |err|
        print $"✗ Could not determine Nix version. Error: ($err)"
    }

    $total_checks = $total_checks + 1
    print "Checking if flakes are enabled"
    try {
        let flake_check = (nix flake --help | str contains "flake")
        if $flake_check {
            print "✓ Nix flakes are enabled"
            $checks_passed = $checks_passed + 1
        } else {
            print "⚠️ Nix flakes may not be enabled"
        }
    } catch { |err|
        print $"✗ Could not check Nix flakes status. Error: ($err)"
    }

    {passed: $checks_passed, total: $total_checks}
}

def check_configuration_files [] {
    print "Checking configuration files..."
    mut checks_passed = 0
    mut total_checks = 0

    let required_files = ["flake.nix", "config/nixos/configuration.nix", "config/hardware/hardware-configuration.nix"]
    for file in $required_files {
        $total_checks = $total_checks + 1
        print $"Checking file: ($file)"
        try {
            if ($file | path exists) {
                $checks_passed = $checks_passed + 1
                print $"✓ File exists: ($file)"
            }
        } catch { |err|
            print $"✗ Failed to check file ($file). Error: ($err)"
        }
    }

    let required_dirs = ["config", "config/nixos", "config/hardware", "modules", "scripts"]
    for dir in $required_dirs {
        $total_checks = $total_checks + 1
        print $"Checking directory: ($dir)"
        try {
            if ($dir | path exists) {
                $checks_passed = $checks_passed + 1
                print $"✓ Directory exists: ($dir)"
            }
        } catch { |err|
            print $"✗ Failed to check directory ($dir). Error: ($err)"
        }
    }

    {passed: $checks_passed, total: $total_checks}
}

def check_flake_syntax [] {
    print "Checking flake.nix syntax..."
    print "Running: nix flake check --no-build"
    try {
        let flake_check = (nix flake check --no-build | complete)
        if ($flake_check.stderr | str contains "error") {
            print "✗ Flake syntax errors detected"
            print $flake_check.stderr
            false
        } else {
            print "✓ Flake syntax is valid"
            true
        }
    } catch { |err|
        print $"✗ Could not validate flake syntax. Error: ($err)"
        false
    }
}

def check_nixos_configuration [] {
    print "Checking NixOS configuration..."
    print "Running: nixos-rebuild dry-build"
    try {
        let config_check = (nixos-rebuild dry-build | complete)
        if ($config_check.stderr | str contains "error") {
            print "✗ NixOS configuration errors detected"
            print $config_check.stderr
            false
        } else {
            print "✓ NixOS configuration is valid"
            true
        }
    } catch { |err|
        print $"✗ Could not validate NixOS configuration. Error: ($err)"
        false
    }
}

def check_system_services [] {
    print "Checking system services..."
    mut checks_passed = 0
    mut total_checks = 0

    print "Checking if /etc/nixos exists"
    if ("/etc/nixos" | path exists) {
        print "✓ Running on NixOS system"
        $checks_passed = $checks_passed + 1
    } else {
        print "⚠️ Not running on NixOS system"
    }
    $total_checks = $total_checks + 1

    print "Checking command: systemctl"
    if (which systemctl | length) > 0 {
        print "✓ systemctl command: available"
        try {
            print "Running: systemctl --failed --no-pager --no-legend"
            let services = (systemctl --failed --no-pager --no-legend | lines | length)
            print $"Failed systemd services count: ($services)"
            if $services == 0 {
                print "✓ No failed systemd services"
                $checks_passed = $checks_passed + 1
            } else {
                print $"⚠️ ($services) failed systemd services detected"
            }
        } catch { |err|
            print $"⚠️ Could not check systemd services. Error: ($err)"
        }
        $total_checks = $total_checks + 1
    }

    {passed: $checks_passed, total: $total_checks}
}

def check_disk_space [] {
    print "Checking disk space..."
    print "Running: df -h /"
    try {
        let df_output = (df -h / | complete)
        let usage_line = ($df_output.stdout | lines | skip 1 | get 0)
        let usage_percent = ($usage_line | str replace -r '.*\s+(\d+)%\s+.*' '$1' | into int)
        print $"Parsed disk usage: ($usage_percent)%"
        if $usage_percent < 80 {
            print "✓ Disk space usage is healthy"
            true
        } else {
            print "⚠️ Disk space usage is high: ($usage_percent)% used"
            false
        }
    } catch { |err|
        print $"✗ Could not check disk space. Error: ($err)"
        false
    }
}

def check_memory_usage [] {
    print "Checking memory usage..."
    print "Running: free -m"
    try {
        let free_output = (free -m | complete)
        # Parse the memory line (second line, first is header)
        let mem_line = ($free_output.stdout | lines | get 1)
        # Split by whitespace and get total and used
        let mem_parts = ($mem_line | split row " " | where ($it | str length) > 0)
        let total = ($mem_parts | get 1 | into int)
        let used = ($mem_parts | get 2 | into int)
        let percent = (($used / $total) * 100 | into int)
        print $"Memory usage percent: ($percent)%"
        if $percent < 80 {
            print "✓ Memory usage is healthy"
            true
        } else {
            print $"⚠️ Memory usage is high: ($percent)% used"
            false
        }
    } catch { |err|
        print $"✗ Could not check memory usage. Error: ($err)"
        false
    }
}

def check_network_connectivity [] {
    print "Checking network connectivity..."
    mut checks_passed = 0
    mut total_checks = 0

    # Check internet connectivity
    print "Running: ping -c 1 8.8.8.8"
    let internet_ok = try {
        let ping_output = (ping -c 1 8.8.8.8 | complete)
        if ($ping_output.exit_code == 0) {
            print "✓ Internet connectivity: OK"
            true
        } else {
            print "✗ Internet connectivity: Failed"
            false
        }
    } catch { |err|
        print $"✗ Could not test internet connectivity. Error: ($err)"
        false
    }

    if $internet_ok {
        $checks_passed = $checks_passed + 1
    }
    $total_checks = $total_checks + 1

    # Check DNS resolution
    print "Running: nslookup google.com"
    let dns_ok = try {
        let nslookup_output = (nslookup google.com | complete)
        let dns_test = ($nslookup_output.stdout | str contains "Name:")
        if $dns_test {
            print "✓ DNS resolution: OK"
            true
        } else {
            print "✗ DNS resolution: Failed"
            false
        }
    } catch { |err|
        print $"nslookup failed, trying alternative DNS check: ($err)"
        # Fallback: try using ping to test DNS resolution
        let ping_dns_output = (ping -c 1 google.com | complete)
        if ($ping_dns_output.exit_code == 0) {
            print "✓ DNS resolution: OK (via ping)"
            true
        } else {
            print "✗ DNS resolution: Failed"
            false
        }
    }

    if $dns_ok {
        $checks_passed = $checks_passed + 1
    }
    $total_checks = $total_checks + 1

    {passed: $checks_passed, total: $total_checks}
}

def check_nix_store [] {
    print "Checking Nix store..."
    print "Running: ls -la /nix/store"
    try {
        let ls_output = (ls -la /nix/store)
        print $"($ls_output | length) items found"
        let store_size = ($ls_output | get size | math sum | into filesize)
        print $"Parsed Nix store size: ($store_size)"
        print "✓ Nix store size: ($store_size)"

        print "Running: nix-store --verify --check-contents"
        let verify_output = (nix-store --verify --check-contents | complete)
        let broken_packages = ($verify_output.stderr | str contains "error" | length)
        print $"Broken packages count: ($broken_packages)"
        if $broken_packages == 0 {
            print "✓ No broken packages detected"
            true
        } else {
            print "⚠️ Some packages may be broken"
            true
        }
    } catch { |err|
        print $"✗ Could not check Nix store. Error: ($err)"
        false
    }
}

def check_security [] {
    print "Checking security configuration..."
    mut checks_passed = 0
    mut total_checks = 0

    print "Checking if /etc/nixos exists for firewall check"
    if ("/etc/nixos" | path exists) {
        try {
            print "Running: systemctl is-active firewall"
            let firewall_status = (systemctl is-active firewall | complete)
            let status = ($firewall_status.stdout | str trim)
            if $status == "active" {
                print "✓ Firewall is active"
                $checks_passed = $checks_passed + 1
            } else {
                print "⚠️ Firewall is not active"
            }
        } catch { |err|
            print $"⚠️ Could not check firewall status. Error: ($err)"
        }
        $total_checks = $total_checks + 1
    }

    print "Running: ss -tuln for open ports"
    try {
        let ss_output = (ss -tuln | complete)
        let open_ports = ($ss_output.stdout | lines | length)
        print $"Open ports count: ($open_ports)"
        if $open_ports < 10 {
            print "✓ Reasonable number of open ports"
            $checks_passed = $checks_passed + 1
        } else {
            print "⚠️ Many open ports detected"
        }
    } catch { |err|
        print $"⚠️ Could not check open ports. Error: ($err)"
    }
    $total_checks = $total_checks + 1

    {passed: $checks_passed, total: $total_checks}
}

def generate_report [results: record] {
    print $"\n(ansi blue_bold)📊 Health Check Report(ansi reset)"
    print $"(ansi dark_gray)══════════════════════════════════════════════════════════════(ansi reset)\n"

    let total_passed = ($results.nix_env.passed + $results.config_files.passed + $results.system_services.passed + $results.network.passed + $results.security.passed)
    let total_checks = ($results.nix_env.total + $results.config_files.total + $results.system_services.total + $results.network.total + $results.security.total)
    let success_rate = (($total_passed / $total_checks) * 100 | into int)

    # Health score with color coding
    let score_color = if $success_rate >= 90 {
        "green_bold"
    } else if $success_rate >= 80 {
        "yellow_bold"
    } else {
        "red_bold"
    }

    let score_icon = if $success_rate >= 90 {
        "✅"
    } else if $success_rate >= 80 {
        "⚠️"
    } else {
        "❌"
    }

    print $"($score_icon) Overall Health: (ansi $score_color)($success_rate)%(ansi reset) ($total_passed)/($total_checks) checks passed\n"

    print $"(ansi cyan_bold)📋 Detailed Results:(ansi reset)"
    print $"  • Nix Environment:     (ansi green)($results.nix_env.passed)/(ansi reset)(ansi dark_gray)($results.nix_env.total)(ansi reset)"
    print $"  • Configuration Files: (ansi green)($results.config_files.passed)/(ansi reset)(ansi dark_gray)($results.config_files.total)(ansi reset)"
    print $"  • System Services:     (ansi green)($results.system_services.passed)/(ansi reset)(ansi dark_gray)($results.system_services.total)(ansi reset)"
    print $"  • Network:             (ansi green)($results.network.passed)/(ansi reset)(ansi dark_gray)($results.network.total)(ansi reset)"
    print $"  • Security:            (ansi green)($results.security.passed)/(ansi reset)(ansi dark_gray)($results.security.total)(ansi reset)"

    print $"\n(ansi cyan_bold)🔧 System Status:(ansi reset)"
    if $results.flake_syntax {
        print $"  • Flake Syntax:       (ansi green)✓ Valid(ansi reset)"
    } else {
        print $"  • Flake Syntax:       (ansi red)✗ Invalid(ansi reset)"
    }

    if $results.nixos_config {
        print $"  • NixOS Config:       (ansi green)✓ Valid(ansi reset)"
    } else {
        print $"  • NixOS Config:       (ansi red)✗ Invalid(ansi reset)"
    }

    if $results.disk_space {
        print $"  • Disk Space:         (ansi green)✓ Healthy(ansi reset)"
    } else {
        print $"  • Disk Space:         (ansi red)✗ Critical(ansi reset)"
    }

    if $results.memory_usage {
        print $"  • Memory Usage:       (ansi green)✓ Healthy(ansi reset)"
    } else {
        print $"  • Memory Usage:       (ansi red)✗ Critical(ansi reset)"
    }

    if $results.nix_store {
        print $"  • Nix Store:          (ansi green)✓ Healthy(ansi reset)"
    } else {
        print $"  • Nix Store:          (ansi red)✗ Issues Detected(ansi reset)"
    }

    print $"\n(ansi cyan_bold)💡 Recommendations:(ansi reset)"
    if $success_rate < 80 {
        print $"(ansi red)❌ System health needs attention. Review failed checks above.(ansi reset)"
    } else if $success_rate < 95 {
        print $"(ansi yellow)⚠️  System is mostly healthy. Consider addressing warnings.(ansi reset)"
    } else {
        print $"(ansi green)✅ System is in excellent health!(ansi reset)"
    }
    print ""
}

def main [] {
    show_banner

    # Run all health checks
    let nix_env = (check_nix_environment)
    let config_files = (check_configuration_files)
    let flake_syntax = (check_flake_syntax)
    let nixos_config = (check_nixos_configuration)
    let system_services = (check_system_services)
    let disk_space = (check_disk_space)
    let memory_usage = (check_memory_usage)
    let network = (check_network_connectivity)
    let nix_store = (check_nix_store)
    let security = (check_security)

    # Compile results
    let results = {
        nix_env: $nix_env,
        config_files: $config_files,
        flake_syntax: $flake_syntax,
        nixos_config: $nixos_config,
        system_services: $system_services,
        disk_space: $disk_space,
        memory_usage: $memory_usage,
        network: $network,
        nix_store: $nix_store,
        security: $security
    }

    # Generate report
    generate_report $results

    # Exit with appropriate code
    let total_passed = ($results.nix_env.passed + $results.config_files.passed + $results.system_services.passed + $results.network.passed + $results.security.passed)
    let total_checks = ($results.nix_env.total + $results.config_files.total + $results.system_services.total + $results.network.total + $results.security.total)
    let success_rate = (($total_passed / $total_checks) * 100 | into int)

    if $success_rate < 80 {
        exit 1
    } else {
        exit 0
    }
}

# Run the health check
main
