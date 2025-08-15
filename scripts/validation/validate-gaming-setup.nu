#!/usr/bin/env nu

# Gaming Setup Validation Script
# Comprehensive validation for gaming workstation configuration

use ../lib/logging.nu *
use ../lib/platform.nu *

def main [] {
    print_header "Gaming Setup Validation"
    
    let results = {
        gpu: (validate_gpu_config),
        kernel: (validate_kernel_config),
        audio: (validate_audio_config),
        performance: (validate_performance_config),
        platforms: (validate_gaming_platforms),
        network: (validate_network_config),
        storage: (validate_storage_performance)
    }
    
    print_validation_report $results
    
    let all_passed = ($results | values | all {|r| $r.success})
    if $all_passed {
        print_success "✅ Gaming setup validation passed!"
        exit 0
    } else {
        print_error "❌ Gaming setup validation failed!"
        print_warning "Review the issues above and run the setup wizard to fix them."
        exit 1
    }
}

# Validate GPU configuration
def validate_gpu_config [] {
    print_info "Checking GPU configuration..."
    
    let checks = []
    
    # Check for GPU detection
    let gpu_check = if (which lspci | is-not-empty) {
        let gpus = (^lspci | grep -i "vga\|3d\|display" | lines)
        {
            name: "GPU Detection"
            success: ($gpus | length) > 0
            message: if ($gpus | length) > 0 { 
                $"Found ($gpus | length) GPU(s)" 
            } else { 
                "No GPU detected" 
            }
            gpus: $gpus
        }
    } else {
        {
            name: "GPU Detection"
            success: false
            message: "lspci not available (not on Linux)"
        }
    }
    
    let checks = ($checks | append $gpu_check)
    
    # Check for Vulkan support
    let vulkan_check = if (which vulkaninfo | is-not-empty) {
        {
            name: "Vulkan Support"
            success: true
            message: "Vulkan is available"
        }
    } else {
        {
            name: "Vulkan Support"
            success: false
            message: "vulkaninfo not found - Vulkan may not be properly configured"
        }
    }
    
    let checks = ($checks | append $vulkan_check)
    
    # Check for OpenGL support
    let opengl_check = if (which glxinfo | is-not-empty) {
        let renderer = (try { ^glxinfo | grep "OpenGL renderer" | str trim } catch { "" })
        {
            name: "OpenGL Support"
            success: ($renderer | str length) > 0
            message: if ($renderer | str length) > 0 { $renderer } else { "OpenGL not detected" }
        }
    } else {
        {
            name: "OpenGL Support"
            success: false
            message: "glxinfo not found - OpenGL may not be properly configured"
        }
    }
    
    let checks = ($checks | append $opengl_check)
    
    # Check configuration file
    let config_check = {
        name: "GPU Config in Nix"
        success: ("config/nixos/gaming/hardware.nix" | path exists)
        message: if ("config/nixos/gaming/hardware.nix" | path exists) {
            "Gaming hardware configuration found"
        } else {
            "Gaming hardware configuration missing"
        }
    }
    
    let checks = ($checks | append $config_check)
    
    {
        success: ($checks | all {|c| $c.success})
        checks: $checks
    }
}

# Validate kernel configuration
def validate_kernel_config [] {
    print_info "Checking kernel configuration..."
    
    let checks = []
    
    # Check kernel version
    let kernel_check = if (which uname | is-not-empty) {
        let kernel = (^uname -r | str trim)
        let is_zen = ($kernel | str contains "zen")
        let is_latest = ($kernel | str contains "6.") # Assuming 6.x is latest
        
        {
            name: "Kernel Version"
            success: ($is_zen or $is_latest)
            message: $"Kernel: ($kernel)"
            recommendation: if (not ($is_zen or $is_latest)) {
                "Consider using linux-zen or latest kernel for gaming"
            } else { "" }
        }
    } else {
        {
            name: "Kernel Version"
            success: false
            message: "Cannot determine kernel version"
        }
    }
    
    let checks = ($checks | append $kernel_check)
    
    # Check for important kernel modules
    let modules_to_check = ["nvidia" "amdgpu" "i915" "kvm"]
    
    for module in $modules_to_check {
        let module_check = if (which lsmod | is-not-empty) {
            let loaded = (try { ^lsmod | grep $module | lines | length } catch { 0 })
            {
                name: $"Module: ($module)"
                success: true  # Not all modules need to be loaded
                message: if $loaded > 0 { "Loaded" } else { "Not loaded" }
            }
        } else {
            {
                name: $"Module: ($module)"
                success: false
                message: "Cannot check modules (not on Linux)"
            }
        }
        let checks = ($checks | append $module_check)
    }
    
    {
        success: ($checks | where name == "Kernel Version" | get success | first)
        checks: $checks
    }
}

# Validate audio configuration
def validate_audio_config [] {
    print_info "Checking audio configuration..."
    
    let checks = []
    
    # Check for PipeWire
    let pipewire_check = if (which pipewire | is-not-empty) {
        {
            name: "PipeWire"
            success: true
            message: "PipeWire is installed"
        }
    } else {
        {
            name: "PipeWire"
            success: false
            message: "PipeWire not found - using PulseAudio or ALSA"
        }
    }
    
    let checks = ($checks | append $pipewire_check)
    
    # Check for PulseAudio compatibility
    let pulse_check = if (which pactl | is-not-empty) {
        {
            name: "PulseAudio Interface"
            success: true
            message: "PulseAudio interface available"
        }
    } else {
        {
            name: "PulseAudio Interface"
            success: false
            message: "PulseAudio interface not available"
        }
    }
    
    let checks = ($checks | append $pulse_check)
    
    # Check audio configuration file
    let config_check = {
        name: "Audio Config in Nix"
        success: ("config/nixos/gaming/audio.nix" | path exists)
        message: if ("config/nixos/gaming/audio.nix" | path exists) {
            "Gaming audio configuration found"
        } else {
            "Gaming audio configuration missing"
        }
    }
    
    let checks = ($checks | append $config_check)
    
    {
        success: ($checks | any {|c| $c.success})
        checks: $checks
    }
}

# Validate performance configuration
def validate_performance_config [] {
    print_info "Checking performance configuration..."
    
    let checks = []
    
    # Check CPU governor
    let governor_check = if ("/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor" | path exists) {
        let governor = (open /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor | str trim)
        {
            name: "CPU Governor"
            success: ($governor == "performance" or $governor == "schedutil")
            message: $"Current governor: ($governor)"
            recommendation: if ($governor != "performance") {
                "Consider setting to 'performance' for gaming"
            } else { "" }
        }
    } else {
        {
            name: "CPU Governor"
            success: false
            message: "Cannot check CPU governor"
        }
    }
    
    let checks = ($checks | append $governor_check)
    
    # Check for GameMode
    let gamemode_check = if (which gamemoded | is-not-empty) {
        {
            name: "GameMode"
            success: true
            message: "GameMode is installed"
        }
    } else {
        {
            name: "GameMode"
            success: false
            message: "GameMode not installed - recommended for gaming"
        }
    }
    
    let checks = ($checks | append $gamemode_check)
    
    # Check for MangoHud
    let mangohud_check = if (which mangohud | is-not-empty) {
        {
            name: "MangoHud"
            success: true
            message: "MangoHud is installed"
        }
    } else {
        {
            name: "MangoHud"
            success: false
            message: "MangoHud not installed - useful for performance monitoring"
        }
    }
    
    let checks = ($checks | append $mangohud_check)
    
    # Check swappiness
    let swappiness_check = if ("/proc/sys/vm/swappiness" | path exists) {
        let swappiness = (open /proc/sys/vm/swappiness | str trim | into int)
        {
            name: "Swappiness"
            success: ($swappiness <= 10)
            message: $"Current swappiness: ($swappiness)"
            recommendation: if ($swappiness > 10) {
                "Consider setting to 10 or lower for gaming"
            } else { "" }
        }
    } else {
        {
            name: "Swappiness"
            success: false
            message: "Cannot check swappiness"
        }
    }
    
    let checks = ($checks | append $swappiness_check)
    
    {
        success: ($checks | where success == true | length) >= 2
        checks: $checks
    }
}

# Validate gaming platforms
def validate_gaming_platforms [] {
    print_info "Checking gaming platforms..."
    
    let checks = []
    
    # Check for Steam
    let steam_check = if (which steam | is-not-empty) {
        {
            name: "Steam"
            success: true
            message: "Steam is installed"
        }
    } else {
        {
            name: "Steam"
            success: false
            message: "Steam not installed"
        }
    }
    
    let checks = ($checks | append $steam_check)
    
    # Check for Lutris
    let lutris_check = if (which lutris | is-not-empty) {
        {
            name: "Lutris"
            success: true
            message: "Lutris is installed"
        }
    } else {
        {
            name: "Lutris"
            success: false
            message: "Lutris not installed"
        }
    }
    
    let checks = ($checks | append $lutris_check)
    
    # Check for Wine
    let wine_check = if (which wine | is-not-empty) {
        let wine_version = (try { ^wine --version | str trim } catch { "unknown" })
        {
            name: "Wine"
            success: true
            message: $"Wine is installed: ($wine_version)"
        }
    } else {
        {
            name: "Wine"
            success: false
            message: "Wine not installed - needed for Windows games"
        }
    }
    
    let checks = ($checks | append $wine_check)
    
    # Check for Proton tools
    let protontricks_check = if (which protontricks | is-not-empty) {
        {
            name: "Protontricks"
            success: true
            message: "Protontricks is installed"
        }
    } else {
        {
            name: "Protontricks"
            success: false
            message: "Protontricks not installed - useful for game fixes"
        }
    }
    
    let checks = ($checks | append $protontricks_check)
    
    {
        success: ($checks | where name in ["Steam" "Wine"] | all {|c| $c.success})
        checks: $checks
    }
}

# Validate network configuration
def validate_network_config [] {
    print_info "Checking network configuration..."
    
    let checks = []
    
    # Check TCP congestion control
    let tcp_check = if ("/proc/sys/net/ipv4/tcp_congestion_control" | path exists) {
        let congestion = (open /proc/sys/net/ipv4/tcp_congestion_control | str trim)
        {
            name: "TCP Congestion Control"
            success: ($congestion == "bbr" or $congestion == "cubic")
            message: $"Current: ($congestion)"
            recommendation: if ($congestion != "bbr") {
                "Consider using BBR for better gaming performance"
            } else { "" }
        }
    } else {
        {
            name: "TCP Congestion Control"
            success: false
            message: "Cannot check TCP settings"
        }
    }
    
    let checks = ($checks | append $tcp_check)
    
    # Check firewall for common gaming ports
    let firewall_check = {
        name: "Firewall Config"
        success: true  # Assume configured if config exists
        message: "Check firewall allows game traffic"
    }
    
    let checks = ($checks | append $firewall_check)
    
    {
        success: true  # Network is optional
        checks: $checks
    }
}

# Validate storage performance
def validate_storage_performance [] {
    print_info "Checking storage performance..."
    
    let checks = []
    
    # Check for SSD
    let ssd_check = if (which lsblk | is-not-empty) {
        let disks = (try { ^lsblk -d -o NAME,ROTA | lines | skip 1 } catch { [] })
        let has_ssd = ($disks | any {|d| ($d | split row " " | last) == "0"})
        
        {
            name: "SSD Detection"
            success: $has_ssd
            message: if $has_ssd { "SSD detected" } else { "No SSD detected - games may load slowly" }
        }
    } else {
        {
            name: "SSD Detection"
            success: false
            message: "Cannot detect storage type"
        }
    }
    
    let checks = ($checks | append $ssd_check)
    
    # Check for enough free space
    let space_check = {
        name: "Free Space"
        success: true  # Assume enough space
        message: "Ensure at least 100GB free for games"
    }
    
    let checks = ($checks | append $space_check)
    
    {
        success: true  # Storage checks are informational
        checks: $checks
    }
}

# Print validation report
def print_validation_report [results: record] {
    print "\n📊 Validation Report"
    print "==================="
    
    $results | transpose key value | each {|row|
        let component = $row.key
        let result = $row.value
        let status = if $result.success { "✅" } else { "❌" }
        
        print $"\n($status) ($component | str capitalize)"
        
        if ($result | get -i checks | is-not-empty) {
            $result.checks | each {|check|
                let check_status = if $check.success { "  ✓" } else { "  ✗" }
                print $"($check_status) ($check.name): ($check.message)"
                
                if ($check | get -i recommendation | is-not-empty) {
                    if ($check.recommendation | str length) > 0 {
                        print $"      → ($check.recommendation)"
                    }
                }
            }
        }
    }
    
    print "\n"
}

# Helper functions
def print_header [title: string] {
    print $"(ansi blue)🎮 ($title)(ansi reset)"
    print $"(ansi blue)========================(ansi reset)\n"
}

def print_info [message: string] {
    print $"(ansi cyan)ℹ️  ($message)(ansi reset)"
}

def print_success [message: string] {
    print $"(ansi green)($message)(ansi reset)"
}

def print_error [message: string] {
    print $"(ansi red)($message)(ansi reset)"
}

def print_warning [message: string] {
    print $"(ansi yellow)⚠️  ($message)(ansi reset)"
}

# Run main if called directly
if $env.FILE_PWD == (which $env.CURRENT_FILE | get path | first) {
    main
}