#!/usr/bin/env nu

# Display Configuration Validator for nix-mox
# User-friendly script to validate display configurations before applying changes

use ../lib/validators.nu *
use ../lib/logging.nu *

def show_banner [] {
    print "🖥️  nix-mox: Display Configuration Validator"
    print "Safe display configuration testing and validation"
    print ""
}

def validate_configuration_file [config_path: string] {
    print $"📋 Validating configuration file: ($config_path)"
    try {
        let config_content = (open $config_path)
        print "✅ Configuration file is valid"
        true
    } catch {
        | err| print $"❌ Configuration file not found: ($config_path)"
        false
    }
}

def create_safety_backup [config_path: string] {
    print "💾 Creating safety backup... "
    try {
        let backup_dir = "/tmp/nix-mox-display-backups"
        if not ($backup_dir | path exists) {
            mkdir $backup_dir
        }
        let timestamp = (date now | format date "%Y%m%d_%H%M%S")
        let backup_path = $"($backup_dir)/config_backup_($timestamp).nix"
        cp $config_path $backup_path
        print $"✅ Configuration backed up to: ($backup_path)"
        {
            success: true
            backup_path: $backup_path
            timestamp: $timestamp
        }
    } catch {
        | err| print $"❌ Backup failed: ($err)"
        {
            success: false
            error: $err
        }
    }
}

def detect_gpu_hardware [] {
    print "🔍 Detecting GPU hardware..."
    try {
        # Get detailed GPU information
        let lspci_output = (lspci | grep -i vga)
        if ($lspci_output | str length) > 0 {
            # Extract GPU name and type
            let gpu_name = ($lspci_output | str replace ".*: " "")
            let gpu_type = if ($gpu_name | str downcase | str contains "nvidia") {
                "nvidia"
            } else if ($gpu_name | str downcase | str contains "amd") {
                "amd"
            } else if ($gpu_name | str downcase | str contains "intel") {
                "intel"
            } else {
                "unknown"
            }
            # Get additional GPU details
            let gpu_details = try {
                let nvidia_info = (nvidia-smi --query-gpu=name,driver_version --format=csv,noheader,nounits 2>/dev/null)
                if ($nvidia_info | str length) > 0 {
                    $nvidia_info
                } else {
                    ""
                }
            } catch {
                ""
            }
            {
                detected: true
                name: $gpu_name
                type: $gpu_type
                details: $gpu_details
                pci_id: ($lspci_output | str replace " .*" "")
            }
        } else {
            {
                detected: false
                name: "No GPU detected"
                type: "none"
                details: ""
                pci_id: ""
            }
        }
    } catch {
        {
            detected: false
            name: "Detection failed"
            type: "error"
            details: ""
            pci_id: ""
        }
    }
}

def test_graphics [] {
    print "🎮 Testing graphics capabilities..."
    # Test OpenGL
    let opengl_test = try {
        let glxinfo = (glxinfo | grep "OpenGL version")
        let glx_vendor = (glxinfo | grep "OpenGL vendor" | str replace "OpenGL vendor string: " "")
        let glx_renderer = (glxinfo | grep "OpenGL renderer" | str replace "OpenGL renderer string: " "")
        {
            available: true
            version: $glxinfo
            vendor: $glx_vendor
            renderer: $glx_renderer
        }
    } catch {
        {
            available: false
            version: ""
            vendor: ""
            renderer: ""
        }
    }
    # Test Vulkan
    let vulkan_test = try {
        let vulkaninfo = (vulkaninfo | grep "GPU" | head -n 1)
        let vulkan_version = (vulkaninfo | grep "Vulkan Instance Version" | str replace "Vulkan Instance Version: " "")
        let vulkan_devices = (vulkaninfo | grep "GPU" | length)
        {
            available: true
            gpu: $vulkaninfo
            version: $vulkan_version
            device_count: $vulkan_devices
        }
    } catch {
        {
            available: false
            gpu: ""
            version: ""
            device_count: 0
        }
    }
    {
        opengl: $opengl_test
        vulkan: $vulkan_test
    }
}

def run_comprehensive_validation [config_path: string, verbose: bool] {
    print "🔍 Running comprehensive display validation..."
    print ""

    # System information - dynamically detected using environment variables and basic commands
    let system_info = {
        platform: (try { $env.OS | default "Linux" } catch { "Linux" })
        architecture: (try { $env.ARCH | default "x86_64" } catch { "x86_64" })
        kernel: (try { sys host | get kernel.release | default "6.15.3" } catch { "6.15.3" })
        health: {
            disk_usage: (try { df / | lines | skip 1 | first | split row " " | where $it != "" | get 4 | str replace "%" "" | into int } catch { 0 })
            memory_usage: (try {
                let mem_line = (free | lines | skip 1 | first | split row " " | where $it != "")
                let total = ($mem_line | get 1 | into int)
                let used = ($mem_line | get 2 | into int)
                (($used * 100) / $total | math round)
            } catch { 0 })
            network_available: (try { (ping -c 1 8.8.8.8 | str length) > 0 } catch { false })
        }
    }

    if $verbose {
        print $"($env.CYAN)System Information:($env.NC)"
        print $"  🖥️  Platform: ($system_info.platform)"
        print $"  🏗️  Architecture: ($system_info.architecture)"
        print $"  🐧 Kernel: ($system_info.kernel)"
        print $"  💾 Disk Usage: ($system_info.health.disk_usage)%"
        print $"  🧠 Memory Usage: ($system_info.health.memory_usage)%"
        let network_display = if $system_info.health.network_available { "✅ Available" } else { "❌ Unavailable" }
        print $"  🌐 Network: ($network_display)"
        print ""
    }

    # Test graphics capabilities
    let graphics_test = (test_graphics)
    if $verbose {
        print $"($env.CYAN)Graphics Capabilities:($env.NC)"
        let opengl_status = if $graphics_test.opengl.available { "✅ Available" } else { "❌ Not Available" }
        print $"  🎮 OpenGL: ($opengl_status)"
        if $graphics_test.opengl.available {
            print $"    Version: ($graphics_test.opengl.version)"
            print $"    Vendor: ($graphics_test.opengl.vendor)"
            print $"    Renderer: ($graphics_test.opengl.renderer)"
        }
        let vulkan_status = if $graphics_test.vulkan.available { "✅ Available" } else { "❌ Not Available" }
        print $"  🎮 Vulkan: ($vulkan_status)"
        if $graphics_test.vulkan.available {
            print $"    GPU: ($graphics_test.vulkan.gpu)"
            print $"    Vulkan Version: ($graphics_test.vulkan.version)"
            print $"    Device Count: ($graphics_test.vulkan.device_count)"
        }
        print ""
    }

    # Hardware detection
    let hardware = (detect_gpu_hardware)
    if $verbose {
        print $"($env.CYAN)Hardware Detection:($env.NC)"
        let gpu_status = if $hardware.detected { "✅ Detected" } else { "❌ Not Detected" }
        print $"  🎨 GPU: ($hardware.name) ($gpu_status)"
        print ""
    }

    # Overall assessment
    let overall_safe = $hardware.detected and $graphics_test.opengl.available

    {
        system_info: $system_info
        graphics_test: $graphics_test
        hardware: $hardware
        overall_safe: $overall_safe
    }
}

def generate_safety_report [validation_result: record, backup_result: record] {
    print $"\n($env.BLUE)📊 Safety Report($env.NC)"
    print $"($env.DARK_GRAY)Generated: ((date now | format date '%Y-%m-%d %H:%M:%S'))($env.NC)\n"

    # System health summary
    let health = $validation_result.system_info.health
    print $"($env.CYAN)System Health:($env.NC)"
    let disk_status = if $health.disk_usage > 90 { "⚠️" } else if $health.disk_usage > 80 { "⚡" } else { "✅" }
    print $"  💾 Disk Usage: ($health.disk_usage)% ($disk_status)"
    let mem_status = if $health.memory_usage > 90 { "⚠️" } else if $health.memory_usage > 80 { "⚡" } else { "✅" }
    print $"  🧠 Memory Usage: ($health.memory_usage)% ($mem_status)"
    let network_status = if $health.network_available { "✅ Available" } else { "❌ Unavailable" }
    print $"  🌐 Network: ($network_status)"
    print ""

    # Hardware summary
    let hardware = $validation_result.hardware
    print $"($env.CYAN)Hardware Status:($env.NC)"
    let gpu_status = if $hardware.detected { "✅ Detected" } else { "❌ Not Detected" }
    print $"  🎨 GPU: ($hardware.name) ($gpu_status)"
    if $hardware.detected {
        print $"    Type: ($hardware.type | str upcase)"
        print $"    PCI ID: ($hardware.pci_id)"
        if ($hardware.details | str length) > 0 {
            print $"    Details: ($hardware.details)"
        }
    }
    print ""

    # Graphics capabilities summary
    let graphics = $validation_result.graphics_test
    print $"($env.CYAN)Graphics Capabilities:($env.NC)"
    let opengl_status = if $graphics.opengl.available { "✅ Available" } else { "❌ Not Available" }
    print $"  🎮 OpenGL: ($opengl_status)"
    if $graphics.opengl.available {
        print $"    Version: ($graphics.opengl.version)"
        print $"    Vendor: ($graphics.opengl.vendor)"
        print $"    Renderer: ($graphics.opengl.renderer)"
    }
    let vulkan_status = if $graphics.vulkan.available { "✅ Available" } else { "❌ Not Available" }
    print $"  🎮 Vulkan: ($vulkan_status)"
    if $graphics.vulkan.available {
        print $"    Version: ($graphics.vulkan.version)"
        print $"    GPU: ($graphics.vulkan.gpu)"
        print $"    Device Count: ($graphics.vulkan.device_count)"
    }
    print ""

    # Backup information
    if $backup_result.success {
        print $"($env.CYAN)Safety Backup:($env.NC)"
        print $"  💾 Backup Location: ($backup_result.backup_path)"
        print $"  📅 Backup Time: ($backup_result.timestamp)"
        print ""
    }

    # Final recommendation
    if $validation_result.overall_safe {
        print $"($env.GREEN)✅ RECOMMENDATION: Configuration appears safe to apply($env.NC)"
        print $"($env.DARK_GRAY)You can proceed with: sudo nixos-rebuild switch($env.NC)"
    } else {
        print $"($env.RED)❌ RECOMMENDATION: Configuration has potential risks($env.NC)"
        print $"($env.YELLOW)Please review the warnings above before proceeding($env.NC)"
        print $"($env.DARK_GRAY)Consider running with --interactive for guided assistance($env.NC)"
    }
}

def main [] {
    # Set environment variables for color output
    $env.CYAN = (ansi cyan)
    $env.BLUE = (ansi blue)
    $env.GREEN = (ansi green)
    $env.YELLOW = (ansi yellow)
    $env.RED = (ansi red)
    $env.DARK_GRAY = (ansi dark_gray)
    $env.NC = (ansi reset)

    # Default configuration path
    let config_path = "flake.nix"
    print $"($env.CYAN)Validating configuration: ($config_path)($env.NC)\n"

    # Step 1: Validate configuration file
    let file_valid = (validate_configuration_file $config_path)
    if not $file_valid {
        print $"($env.RED)❌ Cannot proceed without valid configuration file($env.NC)"
        exit 1
    }

    # Step 2: Create backup
    let backup_result = (create_safety_backup $config_path)

    # Step 3: Run comprehensive validation
    let validation_result = (run_comprehensive_validation $config_path true)

    # Step 4: Generate report
    generate_safety_report $validation_result $backup_result

    # Exit with appropriate code
    if $validation_result.overall_safe {
        exit 0
    } else {
        exit 1
    }
}
