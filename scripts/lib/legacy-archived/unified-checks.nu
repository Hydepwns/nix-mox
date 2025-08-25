# ⚠️  DEPRECATED: unified-checks.nu is deprecated!
# Use lib/validators.nu instead - this legacy library will be removed

export def check_command [cmd: string] {
    """Check if a command is available in PATH"""
    try {
        let result = (which $cmd | length)
        $result > 0
    } catch {
        false
    }
}

export def check_file [path: string] {
    """Check if a file exists and is readable"""
    try {
        ($path | path exists) and (($path | path type) == "file")
    } catch {
        false
    }
}

export def check_directory [path: string] {
    """Check if a directory exists and is accessible"""
    try {
        ($path | path exists) and (($path | path type) == "dir")
    } catch {
        false
    }
}

export def check_permissions [path: string, required: string] {
    """Check if a path has the required permissions"""
    try {
        let perms = (ls -la $path | get mode | get 0)
        match $required {
            "read" => ($perms | str contains "r"),
            "write" => ($perms | str contains "w"),
            "execute" => ($perms | str contains "x"),
            _ => false
        }
    } catch {
        false
    }
}

export def check_flake_syntax [flake_path: string = "."] {
    """Check if a flake.nix file has valid syntax"""
    try {
        let result = (nix flake check --no-build --extra-experimental-features flakes nix-command --flake $flake_path | complete)
        $result.exit_code == 0
    } catch {
        false
    }
}

export def check_nixos_configuration [config_path: string = "."] {
    """Check if NixOS configuration is valid"""
    try {
        let result = (nixos-rebuild dry-build --flake $config_path | complete)
        $result.exit_code == 0
    } catch {
        false
    }
}

export def check_prerequisites [requirements: list] {
    """Check if all prerequisites are met"""
    mut all_met = true
    mut results = {}
    
    for req in $requirements {
        let met = match $req.type {
            "command" => (check_command $req.value),
            "file" => (check_file $req.value),
            "directory" => (check_directory $req.value),
            "permission" => (check_permissions $req.path $req.value),
            _ => false
        }
        
        $results = ($results | upsert $req.name $met)
        if not $met {
            $all_met = false
        }
    }
    
    {
        all_met: $all_met,
        results: $results
    }
}

export def check_system_services [] {
    """Check system services status"""
    try {
        let failed_services = (systemctl --failed --no-pager --no-legend | lines | length)
        {
            failed_count: $failed_services,
            healthy: ($failed_services == 0)
        }
    } catch {
        {
            failed_count: -1,
            healthy: false
        }
    }
}

export def check_disk_space [threshold: int = 80] {
    """Check disk space usage"""
    try {
        let df_output = (df -h / | complete)
        let usage_line = ($df_output.stdout | lines | skip 1 | get 0)
        let usage_percent = ($usage_line | str replace -r '.*\s+(\d+)%\s+.*' '$1' | into int)
        
        {
            usage_percent: $usage_percent,
            healthy: ($usage_percent < $threshold)
        }
    } catch {
        {
            usage_percent: -1,
            healthy: false
        }
    }
}

export def check_memory_usage [threshold: int = 80] {
    """Check memory usage"""
    try {
        let free_output = (free -m | complete)
        let mem_line = ($free_output.stdout | lines | skip 1 | get 0)
        let parts = ($mem_line | split row " " | where ($it | str length) > 0)
        let total = ($parts | get 1 | into int)
        let used = ($parts | get 2 | into int)
        let usage_percent = (($used / $total) * 100 | into int)
        
        {
            usage_percent: $usage_percent,
            healthy: ($usage_percent < $threshold)
        }
    } catch {
        {
            usage_percent: -1,
            healthy: false
        }
    }
}

export def check_network_connectivity [host: string = "8.8.8.8"] {
    """Check network connectivity"""
    try {
        let ping_result = (ping -c 1 $host | complete)
        $ping_result.exit_code == 0
    } catch {
        false
    }
}

export def check_dns_resolution [domain: string = "google.com"] {
    """Check DNS resolution with multiple fallbacks"""
    try {
        # Try dig first
        let dig_result = (dig +short $domain | complete)
        if ($dig_result.exit_code == 0) and ($dig_result.stdout | str length) > 0 {
            true
        } else {
            # Try nslookup
            let nslookup_result = (nslookup $domain | complete)
            if ($nslookup_result.exit_code == 0) {
                true
            } else {
                # Try ping as final fallback
                let ping_result = (ping -c 1 $domain | complete)
                $ping_result.exit_code == 0
            }
        }
    } catch {
        false
    }
}

export def check_nix_store [timeout_seconds: int = 30] {
    """Check Nix store health with timeout"""
    try {
        let verify_result = (timeout $timeout_seconds nix-store --verify --check-contents | complete)
        
        if $verify_result.exit_code == 124 {
            # Timeout - store is likely healthy but large
            {
                healthy: true,
                timed_out: true,
                message: "Store verification timed out (normal for large stores)"
            }
        } else if $verify_result.exit_code == 0 {
            {
                healthy: true,
                timed_out: false,
                message: "Store verification completed successfully"
            }
        } else {
            {
                healthy: false,
                timed_out: false,
                message: "Store verification failed"
            }
        }
    } catch {
        {
            healthy: false,
            timed_out: false,
            message: "Store verification error"
        }
    }
}

export def check_platform [] {
    """Detect current platform"""
    try {
        let os = (sys | get host.name | str downcase)
        let arch = (sys | get host.arch | str downcase)
        
        {
            os: $os,
            arch: $arch,
            is_linux: ($os == "linux"),
            is_macos: ($os == "darwin"),
            is_windows: ($os | str contains "windows"),
            is_x86_64: ($arch == "x86_64"),
            is_arm64: ($arch == "aarch64" or $arch == "arm64")
        }
    } catch {
        {
            os: "unknown",
            arch: "unknown",
            is_linux: false,
            is_macos: false,
            is_windows: false,
            is_x86_64: false,
            is_arm64: false
        }
    }
}

export def check_nix_environment [] {
    """Check Nix environment status"""
    try {
        let nix_version = (nix --version | complete)
        let flakes_enabled = (nix flake --help | complete)
        
        {
            nix_available: ($nix_version.exit_code == 0),
            flakes_enabled: ($flakes_enabled.exit_code == 0),
            version: ($nix_version.stdout | str trim)
        }
    } catch {
        {
            nix_available: false,
            flakes_enabled: false,
            version: "unknown"
        }
    }
} 