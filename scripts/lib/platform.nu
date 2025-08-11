# platform.nu - Platform detection module for nix-mox
# This replaces the bash platform.sh with a more robust Nushell implementation

# Export the main platform detection function
export def detect_platform [] {
    let os = (sys host | get name)
    match $os {
        "Linux" => "linux"
        "NixOS" => "linux"
        "Windows" => "windows"
        "Darwin" => "darwin"
        _ => "unknown"
    }
}

export def validate_platform [platform: string] {
    let valid_platforms = ["linux", "windows", "darwin", "auto"]
    $valid_platforms | any { |p| $p == $platform }
}

export def get_platform_script [platform: string, script: string] {
    let linux_scripts = {
        install: "install.sh"
        uninstall: "uninstall.sh"
        update: "nixos-flake-update.sh"
        zfs-snapshot: "zfs-snapshot.sh"
        vzdump-backup: "vzdump-backup.sh"
        proxmox-update: "proxmox-update.sh"
    }

    let windows_scripts = {
        install: "install-steam-rust.nu"
        run: "run-steam-rust.bat"
    }

    match $platform {
        "linux" => {
            if ($linux_scripts | get -i $script) != null {
                $"scripts/platforms/linux/($linux_scripts | get $script)"
            } else {
                null
            }
        }
        "windows" => {
            if ($windows_scripts | get -i $script) != null {
                $"scripts/platforms/windows/($windows_scripts | get $script)"
            } else {
                null
            }
        }
        _ => null
    }
}

export def script_exists_for_platform [platform: string, script: string] {
    let script_file = (get_platform_script $platform $script)
    if $script_file != null {
        ($script_file | path exists)
    } else {
        false
    }
}

export def get_platform_info [] {
    {
        os: (sys host | get name)
        version: (sys host | get os_version)
        long_version: (sys host | get long_os_version)
        kernel: (sys host | get kernel_version)
        hostname: (sys host | get hostname)
    }
}

export def check_platform_requirements [platform: string] {
    let info = (get_platform_info)

    match $platform {
        "linux" => {
            if $info.os != "Linux" {
                return false
            }
            # Check for essential Linux tools
            let required_tools = ["nix", "curl", "git"]
            let missing_tools = ($required_tools | where { |tool| not (which $tool | is-empty) })
            if ($missing_tools | length) > 0 {
                print $"Missing required tools: ($missing_tools | str join ', ')"
                return false
            }
            # Check for sufficient memory (at least 2GB)
            let mem_gb = ($info.memory.total | into int) / 1024 / 1024 / 1024
            if $mem_gb < 2 {
                print "Insufficient memory: at least 2GB required"
                return false
            }
            true
        }
        "windows" => {
            if $info.os != "Windows" {
                return false
            }
            # Check for PowerShell 5.1+ or PowerShell Core
            let ps_version = (powershell -Command "$PSVersionTable.PSVersion.Major" | into int)
            if $ps_version < 5 {
                print "PowerShell 5.1 or higher required"
                return false
            }
            # Check for Windows 10/11 (build 10.0.17763 or higher)
            let build = (sys host | get os_version | str replace "Windows " "" | str replace "." "" | into int)
            if $build < 10017763 {
                print "Windows 10 (build 17763) or higher required"
                return false
            }
            true
        }
        "darwin" => {
            if $info.os != "Darwin" {
                return false
            }
            # Check for macOS 10.15+ (Catalina)
            let version = ($info.version | str replace "macOS " "" | str replace "." "" | into int)
            if $version < 1015 {
                print "macOS 10.15 (Catalina) or higher required"
                return false
            }
            # Check for Homebrew (recommended for macOS)
            if (which brew | is-empty) {
                print "Warning: Homebrew not found. Consider installing it for better package management."
            }
            true
        }
        _ => false
    }
}

export def get_available_scripts [platform: string] {
    match $platform {
        "linux" => {
            ls scripts/platforms/linux/*.sh | get name | each { |f| $f | path basename }
        }
        "windows" => {
            ls scripts/platforms/windows/*.{nu,bat} | get name | each { |f| $f | path basename }
        }
        _ => []
    }
}

export def get_script_dependencies [script_path: string] {
    let content = (open $script_path)
    mut deps = []

    # Look for common dependency patterns
    if ($content | find "#!/usr/bin/env" | length) > 0 {
        $deps = ($deps | append ($content | find "#!/usr/bin/env" | each { |l| $l | split row " " | get 1 }))
    }

    if ($content | find "require" | length) > 0 {
        $deps = ($deps | append ($content | find "require" | each { |l| $l | split row " " | get 1 }))
    }

    $deps | uniq
}

# Set environment variables
export-env {
    $env.PLATFORM = (detect_platform)
    $env.PLATFORM_INFO = (get_platform_info)
}

# Main function to handle platform operations
def main [] {
    let args = $in
    match $args.0 {
        "detect" => { detect_platform }
        "validate" => { validate_platform $args.1 }
        "info" => { get_platform_info }
        "scripts" => { get_available_scripts $args.1 }
        "deps" => { get_script_dependencies $args.1 }
        _ => { print "Unknown platform operation" }
    }
}
