#!/usr/bin/env nu

# nix-mox Health Check Script
# Comprehensive system health validation for nix-mox configurations

use lib/common.nu *

def show_banner [] {
    print $"\n(ansi blue_bold)🏥 nix-mox: Health Check(ansi reset)"
    print $"(ansi dark_gray)System health validation and configuration check(ansi reset)\n"
}

def check_command [cmd: string] {
    if (which $cmd | length) > 0 {
        log_success $"Command '$cmd' is available"
        true
    } else {
        log_error $"Command '$cmd' is not available"
        false
    }
}

def check_file [path: string] {
    if ($path | path exists) {
        log_success $"File '$path' exists"
        true
    } else {
        log_error $"File '$path' does not exist"
        false
    }
}

def check_directory [path: string] {
    if ($path | path exists) {
        log_success $"Directory '$path' exists"
        true
    } else {
        log_error $"Directory '$path' does not exist"
        false
    }
}

def check_nix_environment [] {
    log_info "Checking Nix environment..."
    mut checks_passed = 0
    mut total_checks = 0
    $total_checks = $total_checks + 1
    log_trace "Checking command: nix"
    try {
        if (check_command "nix") { $checks_passed = $checks_passed + 1 }
        log_trace "nix command: available"
    } catch { |err| log_error $"Failed to check 'nix' command. Error: ($err)"; log_trace $"nix command check failed: ($err)" }
    $total_checks = $total_checks + 1
    log_trace "Checking command: nixos-rebuild"
    try {
        if (check_command "nixos-rebuild") { $checks_passed = $checks_passed + 1 }
        log_trace "nixos-rebuild command: available"
    } catch { |err| log_error $"Failed to check 'nixos-rebuild' command. Error: ($err)"; log_trace $"nixos-rebuild command check failed: ($err)" }
    $total_checks = $total_checks + 1
    log_trace "Checking command: nix-env"
    try {
        if (check_command "nix-env") { $checks_passed = $checks_passed + 1 }
        log_trace "nix-env command: available"
    } catch { |err| log_error $"Failed to check 'nix-env' command. Error: ($err)"; log_trace $"nix-env command check failed: ($err)" }
    log_trace "Checking nix version"
    try {
        let nix_version = (nix --version | str trim)
        log_success $"Nix version: ($nix_version)"
        log_trace $"Nix version: ($nix_version)"
        $checks_passed = $checks_passed + 1
    } catch { |err| log_error $"Could not determine Nix version. Error: ($err)"; log_trace $"Nix version check failed: ($err)" }
    $total_checks = $total_checks + 1
    log_trace "Checking if flakes are enabled"
    try {
        let flake_check = (nix flake --help | str contains "flake")
        log_trace $"nix flake --help output: ($flake_check)"
        if $flake_check {
            log_success "Nix flakes are enabled"
            log_trace "Nix flakes: enabled"
            $checks_passed = $checks_passed + 1
        } else {
            log_warn "Nix flakes may not be enabled"
            log_trace "Nix flakes: not enabled"
        }
    } catch { |err| log_error $"Could not check Nix flakes status. Error: ($err)"; log_trace $"Nix flakes check failed: ($err)" }
    $total_checks = $total_checks + 1
    { passed: $checks_passed total: $total_checks }
}

def check_configuration_files [] {
    log_info "Checking configuration files..."
    mut checks_passed = 0
    mut total_checks = 0
    let required_files = [
        "flake.nix"
        "config/nixos/configuration.nix"
        "config/hardware/hardware-configuration.nix"
    ]
    for file in $required_files {
        $total_checks = $total_checks + 1
        log_trace $"Checking file: ($file)"
        try {
            if (check_file $file) { $checks_passed = $checks_passed + 1 }
            log_trace $"File exists: ($file)"
        } catch { |err| log_error $"Failed to check file ($file). Error: ($err)"; log_trace $"File check failed for ($file): ($err)" }
    }
    let required_dirs = [
        "config"
        "config/nixos"
        "config/hardware"
        "modules"
        "scripts"
    ]
    for dir in $required_dirs {
        $total_checks = $total_checks + 1
        log_trace $"Checking directory: ($dir)"
        try {
            if (check_directory $dir) { $checks_passed = $checks_passed + 1 }
            log_trace $"Directory exists: ($dir)"
        } catch { |err| log_error $"Failed to check directory ($dir). Error: ($err)"; log_trace $"Directory check failed for ($dir): ($err)" }
    }
    { passed: $checks_passed total: $total_checks }
}

def check_flake_syntax [] {
    log_info "Checking flake.nix syntax..."
    log_trace "Running: nix flake check --no-build"
    try {
        let flake_check = (nix flake check --no-build | complete)
        log_trace $"nix flake check output: ($flake_check.stderr)"
        if ($flake_check.stderr | str contains "error") {
            log_error "Flake syntax errors detected"
            log_trace "Flake syntax: invalid"
            print $flake_check.stderr
            false
        } else {
            log_success "Flake syntax is valid"
            log_trace "Flake syntax: valid"
            true
        }
    } catch { |err| log_error $"Could not validate flake syntax. Error: ($err)"; log_trace $"Flake syntax check failed: ($err)"; false }
}

def check_nixos_configuration [] {
    log_info "Checking NixOS configuration..."
    log_trace "Running: nixos-rebuild dry-build"
    try {
        let config_check = (nixos-rebuild dry-build | complete)
        log_trace $"nixos-rebuild output: ($config_check.stderr)"
        if ($config_check.stderr | str contains "error") {
            log_error "NixOS configuration errors detected"
            log_trace "NixOS config: invalid"
            print $config_check.stderr
            false
        } else {
            log_success "NixOS configuration is valid"
            log_trace "NixOS config: valid"
            true
        }
    } catch { |err| log_error $"Could not validate NixOS configuration. Error: ($err)"; log_trace $"NixOS config check failed: ($err)"; false }
}

def check_system_services [] {
    log_info "Checking system services..."
    mut checks_passed = 0
    mut total_checks = 0
    log_trace "Checking if /etc/nixos exists"
    if ("/etc/nixos" | path exists) {
        log_success "Running on NixOS system"
        log_trace "NixOS system detected"
        $checks_passed = $checks_passed + 1
    } else {
        log_warn "Not running on NixOS system"
        log_trace "Not a NixOS system"
    }
    $total_checks = $total_checks + 1
    log_trace "Checking command: systemctl"
    if (check_command "systemctl") {
        log_trace "systemctl command: available"
        try {
            log_trace "Running: systemctl --failed --no-pager --no-legend"
            let services = (systemctl --failed --no-pager --no-legend | lines | length)
            log_trace $"Failed systemd services count: ($services)"
            if $services == 0 {
                log_success "No failed systemd services"
                log_trace "Systemd services: all running"
                $checks_passed = $checks_passed + 1
            } else {
                log_warn $"($services) failed systemd services detected"
                log_trace $"Systemd services: ($services) failed"
            }
        } catch { |err| log_warn $"Could not check systemd services. Error: ($err)"; log_trace $"Systemd services check failed: ($err)" }
        $total_checks = $total_checks + 1
    }
    { passed: $checks_passed total: $total_checks }
}

def check_disk_space [] {
    log_info "Checking disk space..."
    log_trace "Running: df -h /"
    try {
        let df_output = (df -h / | complete)
        log_trace $"df output: ($df_output.stdout)"
        let usage_line = ($df_output.stdout | lines | skip 1 | get 0)
        log_trace $"Usage line: ($usage_line)"
        let usage_percent = ($usage_line | str replace -r '.*\s+(\d+)%\s+.*' '$1' | into int)
        log_trace $"Parsed disk usage: ($usage_percent)%"
        if $usage_percent < 80 {
            log_success "Disk space usage is healthy"
            log_trace "Disk space check: healthy"
            true
        } else {
            log_warn "Disk space usage is high: ($usage_percent)% used"
            log_trace "Disk space check: high usage"
            false
        }
    } catch { |err| 
        log_error $"Could not check disk space. Error: ($err)"
        log_trace $"Disk space check failed with error: ($err)"
        false
    }
}

def check_memory_usage [] {
    log_info "Checking memory usage..."
    log_trace "Running: free -m"
    try {
        let free_output = (free -m | complete)
        log_trace $"free output: ($free_output.stdout)"
        # Parse the memory line (second line, first is header)
        let mem_line = ($free_output.stdout | lines | get 1)
        log_trace $"Memory line: ($mem_line)"
        # Split by whitespace and get total and used
        let mem_parts = ($mem_line | split row " " | where ($it | str length) > 0)
        log_trace $"Memory parts: ($mem_parts)"
        let total = ($mem_parts | get 1 | into int)
        let used = ($mem_parts | get 2 | into int)
        let percent = ($used / $total * 100 | into int)
        log_trace $"Memory usage percent: ($percent)%"
        if $percent < 80 {
            log_success "Memory usage is healthy"
            log_trace "Memory usage check: healthy"
            true
        } else {
            log_warn $"Memory usage is high: ($percent)% used"
            log_trace "Memory usage check: high usage"
            false
        }
    } catch { |err| 
        log_error $"Could not check memory usage. Error: ($err)"
        log_trace $"Memory usage check failed with error: ($err)"
        false
    }
}

def check_network_connectivity [] {
    log_info "Checking network connectivity..."
    mut checks_passed = 0
    mut total_checks = 0
    log_trace "Running: ping -c 1 8.8.8.8"
    try {
        let ping_output = (ping -c 1 8.8.8.8 | complete)
        log_trace $"ping output: ($ping_output.stdout)"
        if ($ping_output.exit_code == 0) {
            log_success "Internet connectivity: OK"
            log_trace "Internet connectivity: OK"
            $checks_passed = $checks_passed + 1
        } else {
            log_error "Internet connectivity: Failed"
            log_trace "Internet connectivity: Failed"
        }
    } catch { |err| log_error $"Could not test internet connectivity. Error: ($err)"; log_trace $"Internet connectivity check failed: ($err)" }
    $total_checks = $total_checks + 1
    log_trace "Running: nslookup google.com"
    try {
        let nslookup_output = (nslookup google.com | complete)
        log_trace $"nslookup output: ($nslookup_output.stdout)"
        let dns_test = ($nslookup_output.stdout | str contains "Name:")
        if $dns_test {
            log_success "DNS resolution: OK"
            log_trace "DNS resolution: OK"
            $checks_passed = $checks_passed + 1
        } else {
            log_error "DNS resolution: Failed"
            log_trace "DNS resolution: Failed"
        }
    } catch { |err| 
        log_trace $"nslookup failed, trying alternative DNS check: ($err)"
        # Fallback: try using ping to test DNS resolution
        try {
            let ping_dns_output = (ping -c 1 google.com | complete)
            log_trace $"ping google.com output: ($ping_dns_output.stdout)"
            if ($ping_dns_output.exit_code == 0) {
                log_success "DNS resolution: OK (via ping)"
                log_trace "DNS resolution: OK (via ping)"
                $checks_passed = $checks_passed + 1
            } else {
                log_error "DNS resolution: Failed"
                log_trace "DNS resolution: Failed"
            }
        } catch { |err2| 
            log_error $"Could not test DNS resolution. Error: ($err2)"
            log_trace $"DNS resolution check failed: ($err2)"
        }
    }
    $total_checks = $total_checks + 1
    { passed: $checks_passed total: $total_checks }
}

def check_nix_store [] {
    log_info "Checking Nix store..."
    log_trace "Running: ls -la /nix/store"
    try {
        let ls_output = (ls -la /nix/store)
        log_trace $"ls output: ($ls_output | length) items found"
        let store_size = ($ls_output | get size | math sum | into filesize)
        log_trace $"Parsed Nix store size: ($store_size)"
        log_success $"Nix store size: ($store_size)"
        log_trace "Running: nix-store --verify --check-contents"
        let verify_output = (nix-store --verify --check-contents | complete)
        log_trace $"nix-store verify output: ($verify_output.stderr)"
        let broken_packages = ($verify_output.stderr | str contains "error" | length)
        log_trace $"Broken packages count: ($broken_packages)"
        if $broken_packages == 0 {
            log_success "No broken packages detected"
            log_trace "Nix store: healthy"
            true
        } else {
            log_warn "Some packages may be broken"
            log_trace "Nix store: some packages broken"
            true
        }
    } catch { |err| log_error $"Could not check Nix store. Error: ($err)"; log_trace $"Nix store check failed: ($err)"; false }
}

def check_security [] {
    log_info "Checking security configuration..."
    mut checks_passed = 0
    mut total_checks = 0
    log_trace "Checking if /etc/nixos exists for firewall check"
    if ("/etc/nixos" | path exists) {
        try {
            log_trace "Running: systemctl is-active firewall"
            let firewall_status = (systemctl is-active firewall | complete)
            log_trace $"firewall status output: ($firewall_status.stdout)"
            let status = ($firewall_status.stdout | str trim)
            if $status == "active" {
                log_success "Firewall is active"
                log_trace "Firewall: active"
                $checks_passed = $checks_passed + 1
            } else {
                log_warn "Firewall is not active"
                log_trace "Firewall: not active"
            }
        } catch { |err| log_warn $"Could not check firewall status. Error: ($err)"; log_trace $"Firewall status check failed: ($err)" }
        $total_checks = $total_checks + 1
    }
    log_trace "Running: ss -tuln for open ports"
    try {
        let ss_output = (ss -tuln | complete)
        log_trace $"ss output: ($ss_output.stdout)"
        let open_ports = ($ss_output.stdout | lines | length)
        log_trace $"Open ports count: ($open_ports)"
        if $open_ports < 10 {
            log_success "Reasonable number of open ports"
            log_trace "Open ports: reasonable"
            $checks_passed = $checks_passed + 1
        } else {
            log_warn "Many open ports detected"
            log_trace "Open ports: many detected"
        }
    } catch { |err| log_warn $"Could not check open ports. Error: ($err)"; log_trace $"Open ports check failed: ($err)" }
    $total_checks = $total_checks + 1
    { passed: $checks_passed total: $total_checks }
}

def generate_report [results: record] {
    print $"\n(ansi blue_bold)📊 Health Check Report(ansi reset)"
    print $"(ansi dark_gray)══════════════════════════════════════════════════════════════(ansi reset)\n"

    let total_passed = ($results.nix_env.passed + $results.config_files.passed + $results.system_services.passed + $results.network.passed + $results.security.passed)
    let total_checks = ($results.nix_env.total + $results.config_files.total + $results.system_services.total + $results.network.total + $results.security.total)
    let success_rate = (($total_passed / $total_checks) * 100 | into int)

    # Health score with color coding
    let score_color = if $success_rate >= 90 { "green_bold" } else if $success_rate >= 80 { "yellow_bold" } else { "red_bold" }
    let score_icon = if $success_rate >= 90 { "✅" } else if $success_rate >= 80 { "⚠️" } else { "❌" }
    
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
        nix_env: $nix_env
        config_files: $config_files
        flake_syntax: $flake_syntax
        nixos_config: $nixos_config
        system_services: $system_services
        disk_space: $disk_space
        memory_usage: $memory_usage
        network: $network
        nix_store: $nix_store
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
