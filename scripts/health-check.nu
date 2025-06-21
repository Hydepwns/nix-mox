#!/usr/bin/env nu

# nix-mox Health Check Script
# Comprehensive system health validation for nix-mox configurations

def show_banner [] {
    print $"\n(ansi green_bold)╔══════════════════════════════════════════════════════════════╗"
    print $"║                    (ansi yellow_bold)nix-mox Health Check(ansi green_bold)                    ║"
    print $"║                                                                    ║"
    print $"║  Checking system health and configuration validity...             ║"
    print $"╚══════════════════════════════════════════════════════════════════╝(ansi reset)\n"
}

def log_info [message: string] {
    print $"(ansi cyan)[INFO](ansi reset) ($message)"
}

def log_success [message: string] {
    print $"(ansi green)[✓](ansi reset) ($message)"
}

def log_warning [message: string] {
    print $"(ansi yellow)[⚠](ansi reset) ($message)"
}

def log_error [message: string] {
    print $"(ansi red)[✗](ansi reset) ($message)"
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
    if (check_command "nix") { $checks_passed = $checks_passed + 1 }

    $total_checks = $total_checks + 1
    if (check_command "nixos-rebuild") { $checks_passed = $checks_passed + 1 }

    $total_checks = $total_checks + 1
    if (check_command "nix-env") { $checks_passed = $checks_passed + 1 }

    # Check Nix version
    try {
        let nix_version = (nix --version | str trim)
        log_success $"Nix version: ($nix_version)"
        $checks_passed = $checks_passed + 1
    } catch {
        log_error "Could not determine Nix version"
    }
    $total_checks = $total_checks + 1

    # Check if flakes are enabled
    try {
        let flake_check = (nix flake --help | str contains "flake")
        if $flake_check {
            log_success "Nix flakes are enabled"
            $checks_passed = $checks_passed + 1
        } else {
            log_warning "Nix flakes may not be enabled"
        }
    } catch {
        log_error "Could not check Nix flakes status"
    }
    $total_checks = $total_checks + 1

    {
        passed: $checks_passed
        total: $total_checks
    }
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
        if (check_file $file) { $checks_passed = $checks_passed + 1 }
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
        if (check_directory $dir) { $checks_passed = $checks_passed + 1 }
    }

    {
        passed: $checks_passed
        total: $total_checks
    }
}

def check_flake_syntax [] {
    log_info "Checking flake.nix syntax..."

    try {
        let flake_check = (nix flake check --no-build | complete | get stderr | str trim)
        if ($flake_check | str contains "error") {
            log_error "Flake syntax errors detected"
            print $flake_check
            false
        } else {
            log_success "Flake syntax is valid"
            true
        }
    } catch {
        log_error "Could not validate flake syntax"
        false
    }
}

def check_nixos_configuration [] {
    log_info "Checking NixOS configuration..."

    try {
        let config_check = (nixos-rebuild build --dry-run | complete | get stderr | str trim)
        if ($config_check | str contains "error") {
            log_error "NixOS configuration errors detected"
            print $config_check
            false
        } else {
            log_success "NixOS configuration is valid"
            true
        }
    } catch {
        log_error "Could not validate NixOS configuration"
        false
    }
}

def check_system_services [] {
    log_info "Checking system services..."

    mut checks_passed = 0
    mut total_checks = 0

    # Check if we're on a NixOS system
    if ("/etc/nixos" | path exists) {
        log_success "Running on NixOS system"
        $checks_passed = $checks_passed + 1
    } else {
        log_warning "Not running on NixOS system"
    }
    $total_checks = $total_checks + 1

    # Check systemd services if available
    if (check_command "systemctl") {
        try {
            let services = (systemctl --failed --no-pager --no-legend | lines | length)
            if $services == 0 {
                log_success "No failed systemd services"
                $checks_passed = $checks_passed + 1
            } else {
                log_warning $"($services) failed systemd services detected"
            }
        } catch {
            log_warning "Could not check systemd services"
        }
        $total_checks = $total_checks + 1
    }

    {
        passed: $checks_passed
        total: $total_checks
    }
}

def check_disk_space [] {
    log_info "Checking disk space..."

    try {
        let disk_usage = (df -h / | lines | skip 1 | split column " " | get "Use%" | str replace "%" "" | into int)
        if $disk_usage < 80 {
            log_success $"Disk usage: ($disk_usage)% (healthy)"
            true
        } else if $disk_usage < 90 {
            log_warning $"Disk usage: ($disk_usage)% (getting full)"
            true
        } else {
            log_error $"Disk usage: ($disk_usage)% (critical)"
            false
        }
    } catch {
        log_error "Could not check disk space"
        false
    }
}

def check_memory_usage [] {
    log_info "Checking memory usage..."

    try {
        let mem_info = (free -h | lines | skip 1 | split column " " | get "Mem" | split row "G" | get 0 | into float)
        let mem_used = (free -h | lines | skip 1 | split column " " | get "Mem" | split row "G" | get 1 | str replace "G" "" | into float)
        let usage_percent = (($mem_used / $mem_info) * 100 | into int)

        if $usage_percent < 80 {
            log_success $"Memory usage: ($usage_percent)% (healthy)"
            true
        } else if $usage_percent < 90 {
            log_warning $"Memory usage: ($usage_percent)% (high)"
            true
        } else {
            log_error $"Memory usage: ($usage_percent)% (critical)"
            false
        }
    } catch {
        log_error "Could not check memory usage"
        false
    }
}

def check_network_connectivity [] {
    log_info "Checking network connectivity..."

    mut checks_passed = 0
    mut total_checks = 0

    # Check internet connectivity
    try {
        let ping_test = (ping -c 1 8.8.8.8 | str contains "1 packets transmitted, 1 received")
        if $ping_test {
            log_success "Internet connectivity: OK"
            $checks_passed = $checks_passed + 1
        } else {
            log_error "Internet connectivity: Failed"
        }
    } catch {
        log_error "Could not test internet connectivity"
    }
    $total_checks = $total_checks + 1

    # Check DNS resolution
    try {
        let dns_test = (nslookup google.com | str contains "Name:")
        if $dns_test {
            log_success "DNS resolution: OK"
            $checks_passed = $checks_passed + 1
        } else {
            log_error "DNS resolution: Failed"
        }
    } catch {
        log_error "Could not test DNS resolution"
    }
    $total_checks = $total_checks + 1

    {
        passed: $checks_passed
        total: $total_checks
    }
}

def check_nix_store [] {
    log_info "Checking Nix store..."

    try {
        # Use ls to get directory size instead of du
        let store_size = (ls -la /nix/store | get size | math sum | into filesize)
        log_success $"Nix store size: ($store_size)"

        # Check for broken packages
        let broken_packages = (nix-store --verify --check-contents | complete | get stderr | str contains "error" | length)
        if $broken_packages == 0 {
            log_success "No broken packages detected"
            true
        } else {
            log_warning "Some packages may be broken"
            true
        }
    } catch {
        log_error "Could not check Nix store"
        false
    }
}

def check_security [] {
    log_info "Checking security configuration..."

    mut checks_passed = 0
    mut total_checks = 0

    # Check if firewall is enabled (if on NixOS)
    if ("/etc/nixos" | path exists) {
        try {
            let firewall_status = (systemctl is-active firewall | complete | get stdout | str trim)
            if $firewall_status == "active" {
                log_success "Firewall is active"
                $checks_passed = $checks_passed + 1
            } else {
                log_warning "Firewall is not active"
            }
        } catch {
            log_warning "Could not check firewall status"
        }
        $total_checks = $total_checks + 1
    }

    # Check for open ports
    try {
        let open_ports = (ss -tuln | lines | length)
        if $open_ports < 10 {
            log_success "Reasonable number of open ports"
            $checks_passed = $checks_passed + 1
        } else {
            log_warning "Many open ports detected"
        }
    } catch {
        log_warning "Could not check open ports"
    }
    $total_checks = $total_checks + 1

    {
        passed: $checks_passed
        total: $total_checks
    }
}

def generate_report [results: record] {
    print $"\n(ansi green_bold)══════════════════════════════════════════════════════════════"
    print $"                    Health Check Report                    "
    print $"══════════════════════════════════════════════════════════════(ansi reset)\n"

    let total_passed = ($results.nix_env.passed + $results.config_files.passed + $results.system_services.passed + $results.network.passed + $results.security.passed)
    let total_checks = ($results.nix_env.total + $results.config_files.total + $results.system_services.total + $results.network.total + $results.security.total)
    let success_rate = (($total_passed / $total_checks) * 100 | into int)

    print $"Overall Health Score: (ansi yellow_bold)($success_rate)%(ansi reset)"
    print $"Passed: (ansi green)($total_passed)/(ansi reset)(ansi yellow)($total_checks)(ansi reset) checks\n"

    print $"(ansi cyan_bold)Detailed Results:(ansi reset)"
    print $"• Nix Environment: (ansi green)($results.nix_env.passed)/(ansi reset)(ansi yellow)($results.nix_env.total)(ansi reset)"
    print $"• Configuration Files: (ansi green)($results.config_files.passed)/(ansi reset)(ansi yellow)($results.config_files.total)(ansi reset)"
    print $"• System Services: (ansi green)($results.system_services.passed)/(ansi reset)(ansi yellow)($results.system_services.total)(ansi reset)"
    print $"• Network: (ansi green)($results.network.passed)/(ansi reset)(ansi yellow)($results.network.total)(ansi reset)"
    print $"• Security: (ansi green)($results.security.passed)/(ansi reset)(ansi yellow)($results.security.total)(ansi reset)"

    if $results.flake_syntax {
        print $"• Flake Syntax: (ansi green)✓ Valid(ansi reset)"
    } else {
        print $"• Flake Syntax: (ansi red)✗ Invalid(ansi reset)"
    }

    if $results.nixos_config {
        print $"• NixOS Config: (ansi green)✓ Valid(ansi reset)"
    } else {
        print $"• NixOS Config: (ansi red)✗ Invalid(ansi reset)"
    }

    if $results.disk_space {
        print $"• Disk Space: (ansi green)✓ Healthy(ansi reset)"
    } else {
        print $"• Disk Space: (ansi red)✗ Critical(ansi reset)"
    }

    if $results.memory_usage {
        print $"• Memory Usage: (ansi green)✓ Healthy(ansi reset)"
    } else {
        print $"• Memory Usage: (ansi red)✗ Critical(ansi reset)"
    }

    if $results.nix_store {
        print $"• Nix Store: (ansi green)✓ Healthy(ansi reset)"
    } else {
        print $"• Nix Store: (ansi red)✗ Issues Detected(ansi reset)"
    }

    print $"\n(ansi cyan_bold)Recommendations:(ansi reset)"
    if $success_rate < 80 {
        print $"(ansi yellow)⚠ System health needs attention. Review failed checks above.(ansi reset)"
    } else if $success_rate < 95 {
        print $"(ansi yellow)⚠ System is mostly healthy. Consider addressing warnings.(ansi reset)"
    } else {
        print $"(ansi green)✓ System is in excellent health!(ansi reset)"
    }
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
