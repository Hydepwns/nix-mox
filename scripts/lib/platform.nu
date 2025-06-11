# Platform detection module for nix-mox
# This replaces the bash platform.sh with a more robust Nushell implementation

def detect_platform [] {
    let os = (sys).host.name
    match $os {
        "Linux" => "linux"
        "Windows" => "windows"
        "Darwin" => "darwin"
        _ => "unknown"
    }
}

def validate_platform [platform: string] {
    let valid_platforms = ["linux", "windows", "darwin", "auto"]
    $valid_platforms | where $it == $platform | length > 0
}

def get_platform_script [platform: string, script: string] {
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
                $"scripts/linux/($linux_scripts | get $script)"
            } else {
                null
            }
        }
        "windows" => {
            if ($windows_scripts | get -i $script) != null {
                $"scripts/windows/($windows_scripts | get $script)"
            } else {
                null
            }
        }
        _ => null
    }
}

def script_exists_for_platform [platform: string, script: string] {
    let script_file = get_platform_script $platform $script
    if $script_file != null {
        ($script_file | path exists)
    } else {
        false
    }
}

def get_platform_info [] {
    {
        os: (sys).host.name
        arch: (sys).host.arch
        version: (sys).host.version
        kernel: (sys).host.kernel_version
        memory: (sys).mem
        cpu: (sys).cpu
    }
}

def check_platform_requirements [platform: string] {
    let info = get_platform_info
    match $platform {
        "linux" => {
            if $info.os != "Linux" {
                return false
            }
            # Add more Linux-specific checks
            true
        }
        "windows" => {
            if $info.os != "Windows" {
                return false
            }
            # Add more Windows-specific checks
            true
        }
        "darwin" => {
            if $info.os != "Darwin" {
                return false
            }
            # Add more macOS-specific checks
            true
        }
        _ => false
    }
}

def get_available_scripts [platform: string] {
    match $platform {
        "linux" => {
            ls scripts/linux/*.sh | each { |f| $f | path basename }
        }
        "windows" => {
            ls scripts/windows/*.{nu,bat} | each { |f| $f | path basename }
        }
        _ => []
    }
}

def get_script_dependencies [script_path: string] {
    let content = open $script_path
    let mut deps = []
    
    # Look for common dependency patterns
    if ($content | find "#!/usr/bin/env" | length) > 0 {
        $deps = ($deps | append ($content | find "#!/usr/bin/env" | each { |l| $l | split row " " | get 1 }))
    }
    
    if ($content | find "require" | length) > 0 {
        $deps = ($deps | append ($content | find "require" | each { |l| $l | split row " " | get 1 }))
    }
    
    $deps | uniq
}

# Export the functions
export-env {
    $env.PLATFORM = detect_platform
    $env.PLATFORM_INFO = get_platform_info
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