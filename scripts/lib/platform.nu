#!/usr/bin/env nu
# Platform detection and management library for nix-mox
# Eliminates platform detection duplication across scripts
# Uses functional patterns for platform-specific operations

use logging.nu *

# Platform information structure
export def platform_info [] {
    let host_info = (sys host)
    let platform_name = ($host_info.name | str downcase)
    
    let normalized_platform = match $platform_name {
        "linux" => "linux",
        "nixos" => "linux",
        "ubuntu" => "linux",
        "debian" => "linux",
        "fedora" => "linux",
        "centos" => "linux",
        "rhel" => "linux",
        "arch" => "linux",
        "darwin" => "macos", 
        "windows" => "windows",
        _ => $platform_name
    }
    
    # Additional check for Linux variants
    let final_platform = if ($normalized_platform not-in ["linux", "macos", "windows"]) and ($platform_name | str contains "linux") {
        "linux"
    } else {
        $normalized_platform
    }
    
    {
        raw_name: $host_info.name,
        normalized: $final_platform,
        arch: (uname | get machine),
        kernel: ($host_info | get -i kernel_version | default "unknown"),
        hostname: ($host_info | get -i hostname | default "unknown"),
        uptime: ($host_info | get -i uptime | default "unknown"),
        os_version: ($host_info | get -i os_version | default "unknown"),
        is_linux: ($final_platform == "linux"),
        is_macos: ($final_platform == "macos"),
        is_windows: ($final_platform == "windows"),
        is_unix: ($final_platform in ["linux", "macos"])
    }
}

# Get current platform (cached)
export def get_platform [] {
    platform_info
}

# Platform-specific command execution
export def run_on_platform [platforms: list<string>] {
    |command: closure|
    
    let current = (get_platform)
    if $current.normalized in $platforms {
        debug $"Running command on platform: ($current.normalized)" --context "platform"
        do $command
    } else {
        debug $"Skipping command - platform ($current.normalized) not in ($platforms)" --context "platform"
        null
    }
}

# Functional platform branching
export def platform_switch [platform_map: record] {
    let current = (get_platform)
    let handler = ($platform_map | get -i $current.normalized)
    
    if ($handler | is-not-empty) {
        debug $"Executing platform-specific handler for: ($current.normalized)" --context "platform"
        do $handler
    } else {
        let default_handler = ($platform_map | get -i "default")
        if ($default_handler | is-not-empty) {
            debug $"Executing default handler for unsupported platform: ($current.normalized)" --context "platform"
            do $default_handler
        } else {
            warn $"No handler found for platform: ($current.normalized)" --context "platform"
            null
        }
    }
}

# Check if current platform is supported
export def is_platform_supported [supported_platforms: list<string>] {
    let current = (get_platform)
    $current.normalized in $supported_platforms
}

# Require specific platform
export def require_platform [required_platforms: list<string>, error_message: string = ""] {
    let current = (get_platform)
    
    if not ($current.normalized in $required_platforms) {
        let msg = if ($error_message | is-empty) {
            $"Platform ($current.normalized) not supported. Required: ($required_platforms | str join ', ')"
        } else {
            $error_message
        }
        error make { msg: $msg }
    }
}

# Platform-specific file paths
export def get_platform_paths [] {
    let current = (get_platform)
    
    match $current.normalized {
        "linux" => {
            config_home: ($env | get -i XDG_CONFIG_HOME | default $"($env.HOME)/.config"),
            data_home: ($env | get -i XDG_DATA_HOME | default $"($env.HOME)/.local/share"),
            cache_home: ($env | get -i XDG_CACHE_HOME | default $"($env.HOME)/.cache"),
            temp_dir: "/tmp",
            path_separator: ":",
            line_ending: "\n"
        },
        "macos" => {
            config_home: $"($env.HOME)/Library/Application Support",
            data_home: $"($env.HOME)/Library/Application Support", 
            cache_home: $"($env.HOME)/Library/Caches",
            temp_dir: "/tmp",
            path_separator: ":",
            line_ending: "\n"
        },
        "windows" => {
            config_home: ($env | get -i APPDATA | default $"($env.USERPROFILE)\\AppData\\Roaming"),
            data_home: ($env | get -i APPDATA | default $"($env.USERPROFILE)\\AppData\\Roaming"),
            cache_home: ($env | get -i TEMP | default $"($env.USERPROFILE)\\AppData\\Local\\Temp"),
            temp_dir: ($env | get -i TEMP | default "C:\\Windows\\Temp"),
            path_separator: ";",
            line_ending: "\r\n"
        },
        _ => {
            config_home: ($env | get -i HOME | default "."),
            data_home: ($env | get -i HOME | default "."),
            cache_home: ($env | get -i HOME | default "."),
            temp_dir: "/tmp",
            path_separator: ":",
            line_ending: "\n"
        }
    }
}

# Platform-specific package managers
export def get_platform_package_managers [] {
    let current = (get_platform)
    
    match $current.normalized {
        "linux" => ["nix", "apt", "yum", "pacman", "zypper", "portage"],
        "macos" => ["nix", "brew", "macports"],
        "windows" => ["nix", "chocolatey", "scoop", "winget"],
        _ => ["nix"]
    }
}

# Detect available package manager
export def detect_package_manager [] {
    let managers = (get_platform_package_managers)
    
    for manager in $managers {
        if (which $manager | is-not-empty) {
            debug $"Found package manager: ($manager)" --context "platform"
            return $manager
        }
    }
    
    warn "No package manager detected" --context "platform"
    null
}

# Platform-specific service management
export def get_service_manager [] {
    let current = (get_platform)
    
    match $current.normalized {
        "linux" => {
            if (which systemctl | is-not-empty) { "systemd" }
            else if (which service | is-not-empty) { "sysvinit" }
            else { "unknown" }
        },
        "macos" => {
            if (which launchctl | is-not-empty) { "launchd" }
            else { "unknown" }
        },
        "windows" => {
            if (which sc | is-not-empty) { "windows-services" }
            else { "unknown" }
        },
        _ => "unknown"
    }
}

# Check if running in specific environments
export def is_wsl [] {
    let current = (get_platform)
    if $current.is_linux {
        try {
            let wsl_check = (cat /proc/version | str contains "microsoft" | default false)
            $wsl_check
        } catch {
            false
        }
    } else {
        false
    }
}

export def is_docker [] {
    try {
        let docker_check = (".dockerenv" | path exists) or (cat /proc/1/cgroup | str contains "docker" | default false)
        $docker_check
    } catch {
        false
    }
}

export def is_ci [] {
    let ci = (($env | get -i CI | default "false") == "true")
    let github = (($env | get -i GITHUB_ACTIONS | default "false") == "true")
    let gitlab = (($env | get -i GITLAB_CI | default "false") == "true")
    let jenkins = (($env | get -i JENKINS_URL | is-not-empty))
    let buildkite = (($env | get -i BUILDKITE | default "false") == "true")
    
    $ci or $github or $gitlab or $jenkins or $buildkite
}

# Platform-specific shell detection
export def get_shell_info [] {
    let current_shell = ($env | get -i SHELL | default "unknown" | path basename)
    let shells = ["bash", "zsh", "fish", "nu", "cmd", "powershell"]
    
    {
        current: $current_shell,
        available: ($shells | where {|shell| which $shell | is-not-empty }),
        is_nushell: ($current_shell == "nu"),
        is_posix: ($current_shell in ["bash", "zsh", "fish"])
    }
}

# Generate platform report
export def platform_report [] {
    let current = (get_platform)
    let paths = (get_platform_paths)
    let package_manager = (detect_package_manager)
    let service_manager = (get_service_manager)
    let shell_info = (get_shell_info)
    
    {
        platform: $current,
        paths: $paths,
        package_manager: $package_manager,
        service_manager: $service_manager,
        shell: $shell_info,
        environment: {
            is_wsl: (is_wsl),
            is_docker: (is_docker),
            is_ci: (is_ci)
        },
        capabilities: {
            has_systemd: (which systemctl | is-not-empty),
            has_docker: (which docker | is-not-empty),
            has_git: (which git | is-not-empty),
            has_nix: (which nix | is-not-empty)
        }
    }
}

# Platform-specific file operations
export def platform_path_join [...parts: string] {
    let paths = (get_platform_paths)
    let separator = if (get_platform).is_windows { "\\" } else { "/" }
    $parts | str join $separator
}

export def platform_executable_name [base_name: string] {
    let current = (get_platform)
    if $current.is_windows {
        $"($base_name).exe"
    } else {
        $base_name
    }
}

# Platform-aware command wrapper
export def platform_command [command_map: record] {
    let current = (get_platform)
    let command = ($command_map | get -i $current.normalized)
    
    if ($command | is-not-empty) {
        $command
    } else {
        let default_command = ($command_map | get -i "default")
        if ($default_command | is-not-empty) {
            $default_command
        } else {
            error make { msg: $"No command defined for platform: ($current.normalized)" }
        }
    }
}

# Functional platform testing
export def test_platform_compatibility [requirements: record] {
    let current = (get_platform)
    let report = (platform_report)
    
    mut compatibility_issues = []
    
    # Check platform requirements
    if "platforms" in $requirements {
        if not ($current.normalized in $requirements.platforms) {
            $compatibility_issues = ($compatibility_issues | append {
                type: "platform",
                issue: $"Platform ($current.normalized) not in required list: ($requirements.platforms)"
            })
        }
    }
    
    # Check architecture requirements  
    if "architectures" in $requirements {
        if not ($current.arch in $requirements.architectures) {
            $compatibility_issues = ($compatibility_issues | append {
                type: "architecture", 
                issue: $"Architecture ($current.arch) not in required list: ($requirements.architectures)"
            })
        }
    }
    
    # Check command requirements
    if "commands" in $requirements {
        for command in $requirements.commands {
            if not (which $command | is-not-empty) {
                $compatibility_issues = ($compatibility_issues | append {
                    type: "command",
                    issue: $"Required command not found: ($command)"
                })
            }
        }
    }
    
    {
        compatible: (($compatibility_issues | length) == 0),
        platform: $current,
        issues: $compatibility_issues,
        report: $report
    }
}