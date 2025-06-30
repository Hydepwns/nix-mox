#!/usr/bin/env nu
# Display Testing Module for nix-mox
# This module provides comprehensive display configuration testing and validation

export-env {
    use ../lib/test-utils.nu *
    use ../lib/test-common.nu *
}

# --- Display Testing Configuration ---
def setup_display_test_config [] {
    {
        enable_hardware_detection: true
        enable_config_analysis: true
        enable_risk_assessment: true
        enable_safety_backups: true
        enable_interactive_mode: true
        backup_config_dir: "/tmp/nix-mox-display-backups"
        max_risk_score: 7
        timeout: 60
        verbose: false
    }
}

# --- Hardware Detection Functions ---
def detect_gpu_hardware [] {
    print $"($env.CYAN)🔍 Detecting GPU hardware...($env.NC)"
    
    try {
        let lspci_output = (safe_command "lspci | grep -i vga")
        
        if ($lspci_output | str contains "NVIDIA") {
            {
                type: "nvidia"
                name: ($lspci_output | str replace ".*: " "")
                driver: "nvidia"
                vulkan: true
                risk_level: "medium"
                detected: true
            }
        } else if ($lspci_output | str contains "AMD") {
            {
                type: "amd"
                name: ($lspci_output | str replace ".*: " "")
                driver: "amdgpu"
                vulkan: true
                risk_level: "low"
                detected: true
            }
        } else if ($lspci_output | str contains "Intel") {
            {
                type: "intel"
                name: ($lspci_output | str replace ".*: " "")
                driver: "i915"
                vulkan: false
                risk_level: "low"
                detected: true
            }
        } else {
            {
                type: "unknown"
                name: "Unknown GPU"
                driver: "auto"
                vulkan: false
                risk_level: "high"
                detected: false
            }
        }
    } catch { |err|
        {
            type: "error"
            name: "Detection failed"
            driver: "unknown"
            vulkan: false
            risk_level: "high"
            detected: false
            error: $err
        }
    }
}

def detect_display_environment [] {
    print $"($env.CYAN)🖥️  Detecting display environment...($env.NC)"
    
    # Detect X11/Wayland
    let display_info = try {
        let x11_check = (safe_command "echo $env.DISPLAY")
        if ($x11_check | str length) > 0 {
            {
                display_server: "X11"
                display_var: $x11_check
            }
        } else {
            let wayland_check = (safe_command "echo $env.WAYLAND_DISPLAY")
            if ($wayland_check | str length) > 0 {
                {
                    display_server: "Wayland"
                    display_var: $wayland_check
                }
            } else {
                {
                    display_server: "None"
                    display_var: ""
                }
            }
        }
    } catch {
        {
            display_server: "Unknown"
            display_var: ""
        }
    }
    
    # Detect desktop environment
    let desktop_environment = try {
        let de_check = (safe_command "echo $env.XDG_CURRENT_DESKTOP")
        if ($de_check | str length) > 0 {
            $de_check
        } else {
            "Unknown"
        }
    } catch {
        "Unknown"
    }
    
    # Detect display manager
    let session_type = try {
        let dm_check = (safe_command "systemctl --user show-environment | grep XDG_SESSION_TYPE")
        if ($dm_check | str length) > 0 {
            ($dm_check | str replace "XDG_SESSION_TYPE=" "")
        } else {
            "Unknown"
        }
    } catch {
        "Unknown"
    }
    
    ($display_info | merge {
        desktop_environment: $desktop_environment
        session_type: $session_type
    })
}

def detect_graphics_drivers [] {
    print $"($env.CYAN)🎨 Detecting graphics drivers...($env.NC)"
    
    # Check for NVIDIA drivers
    let nvidia_info = try {
        let nvidia_check = (safe_command "nvidia-smi --version")
        if ($nvidia_check | str length) > 0 {
            {
                nvidia: true
                nvidia_version: ($nvidia_check | lines | first)
            }
        } else {
            {
                nvidia: false
                nvidia_version: ""
            }
        }
    } catch {
        {
            nvidia: false
            nvidia_version: ""
        }
    }
    
    # Check for AMD drivers
    let amd_info = try {
        let amd_check = (safe_command "lspci | grep -i amd")
        {
            amd: ( ($amd_check | str length) > 0 )
        }
    } catch {
        {
            amd: false
        }
    }
    
    # Check for Intel drivers
    let intel_info = try {
        let intel_check = (safe_command "lspci | grep -i intel")
        {
            intel: ( ($intel_check | str length) > 0 )
        }
    } catch {
        {
            intel: false
        }
    }
    
    # Check OpenGL support
    let opengl_info = try {
        let opengl_check = (safe_command "glxinfo | grep 'OpenGL version'")
        if ($opengl_check | str length) > 0 {
            {
                opengl: true
                opengl_version: $opengl_check
            }
        } else {
            {
                opengl: false
                opengl_version: ""
            }
        }
    } catch {
        {
            opengl: false
            opengl_version: ""
        }
    }
    
    # Check Vulkan support
    let vulkan_info = try {
        let vulkan_check = (safe_command "vulkaninfo | grep 'GPU' | head -n 1")
        if ($vulkan_check | str length) > 0 {
            {
                vulkan: true
                vulkan_gpu: $vulkan_check
            }
        } else {
            {
                vulkan: false
                vulkan_gpu: ""
            }
        }
    } catch {
        {
            vulkan: false
            vulkan_gpu: ""
        }
    }
    
    ($nvidia_info | merge $amd_info | merge $intel_info | merge $opengl_info | merge $vulkan_info)
}

# --- Configuration Analysis Functions ---
def analyze_nixos_config [] {
    print $"($env.CYAN)📋 Analyzing NixOS configuration...($env.NC)"
    
    # Check if we're in a NixOS system
    let nixos_check = try {
        let nixos_test = (safe_command "test -f /etc/nixos/configuration.nix")
        {
            is_nixos: ( ($nixos_test | str length) >= 0 )
        }
    } catch {
        {
            is_nixos: false
        }
    }
    
    # Analyze flake.nix
    let config_analysis = try {
        let config_content = (safe_command "cat flake.nix")
        let display_services = ($config_content | str contains "services.xserver")
        let graphics_drivers = ($config_content | str contains "hardware.opengl")
        let nvidia_drivers = ($config_content | str contains "hardware.nvidia")
        
        {
            valid: true
            error: ""
            has_display_services: $display_services
            has_graphics_drivers: $graphics_drivers
            has_nvidia_drivers: $nvidia_drivers
            config_size: ($config_content | str length)
        }
    } catch { |err|
        {
            valid: false
            error: $err
            has_display_services: false
            has_graphics_drivers: false
            has_nvidia_drivers: false
            config_size: 0
        }
    }
    
    # Check for flake.nix
    let flake_analysis = try {
        let flake_content = (safe_command "cat flake.nix")
        let has_display_modules = ($flake_content | str contains "display")
        let has_gaming_modules = ($flake_content | str contains "gaming")
        
        {
            has_flake: true
            has_display_modules: $has_display_modules
            has_gaming_modules: $has_gaming_modules
            flake_size: ($flake_content | str length)
        }
    } catch {
        {
            has_flake: false
            has_display_modules: false
            has_gaming_modules: false
            flake_size: 0
        }
    }
    
    ($nixos_check | merge $config_analysis | merge $flake_analysis)
}

def compare_configurations [old_config: string, new_config: string] {
    print $"($env.CYAN)🔄 Comparing configurations...($env.NC)"
    
    # Compare configurations
    let comparison_result = try {
        let old_content = (open $old_config)
        let new_content = (open $new_config)
        
        # Check for display-related changes
        let xserver_changed = ( ($old_content | str contains "services.xserver") != ($new_content | str contains "services.xserver") )
        let nvidia_changed = ( ($old_content | str contains "hardware.nvidia") != ($new_content | str contains "hardware.nvidia") )
        let opengl_changed = ( ($old_content | str contains "hardware.opengl") != ($new_content | str contains "hardware.opengl") )
        let gaming_changed = ( ($old_content | str contains "services.gaming") != ($new_content | str contains "services.gaming") )
        let video_drivers_changed = ( ($old_content | str contains "videoDrivers") != ($new_content | str contains "videoDrivers") )
        
        # Check for driver-specific changes
        let nvidia_driver_changed = ( ($old_content | str contains "nvidia") != ($new_content | str contains "nvidia") )
        let amd_driver_changed = ( ($old_content | str contains "amdgpu") != ($new_content | str contains "amdgpu") )
        let intel_driver_changed = ( ($old_content | str contains "intel") != ($new_content | str contains "intel") )
        
        # Check for audio system changes
        let pulseaudio_changed = ( ($old_content | str contains "services.pulseaudio") != ($new_content | str contains "services.pulseaudio") )
        let pipewire_changed = ( ($old_content | str contains "services.pipewire") != ($new_content | str contains "services.pipewire") )
        
        {
            valid: true
            error: ""
            xserver_changed: $xserver_changed
            nvidia_changed: $nvidia_changed
            opengl_changed: $opengl_changed
            gaming_changed: $gaming_changed
            video_drivers_changed: $video_drivers_changed
            nvidia_driver_changed: $nvidia_driver_changed
            amd_driver_changed: $amd_driver_changed
            intel_driver_changed: $intel_driver_changed
            pulseaudio_changed: $pulseaudio_changed
            pipewire_changed: $pipewire_changed
        }
    } catch { |err|
        {
            valid: false
            error: $err
            xserver_changed: false
            nvidia_changed: false
            opengl_changed: false
            gaming_changed: false
            video_drivers_changed: false
            nvidia_driver_changed: false
            amd_driver_changed: false
            intel_driver_changed: false
            pulseaudio_changed: false
            pipewire_changed: false
        }
    }
    
    $comparison_result
}

# --- Risk Assessment Functions ---
def calculate_risk_score [hardware: record, config: record, changes: record] {
    print $"($env.CYAN)⚠️  Calculating risk score...($env.NC)"
    
    mut risk_score = 0
    mut risk_factors = []
    
    # Hardware-based risks
    if ($hardware.type == "nvidia") {
        $risk_score = ($risk_score + 2)
        $risk_factors = ($risk_factors | append "NVIDIA GPU detected (higher risk)")
    }
    
    if not $hardware.detected {
        $risk_score = ($risk_score + 3)
        $risk_factors = ($risk_factors | append "GPU not detected")
    }
    
    # Configuration-based risks
    if ($config.has_graphics_drivers | default false) {
        $risk_score = ($risk_score + 1)
        $risk_factors = ($risk_factors | append "Graphics drivers configuration detected")
    }
    
    if ($config.has_nvidia_drivers | default false) {
        $risk_score = ($risk_score + 1)
        $risk_factors = ($risk_factors | append "NVIDIA drivers configuration detected")
    }
    
    # Change-based risks
    if ($changes.nvidia_driver_changed | default false) {
        $risk_score = ($risk_score + 2)
        $risk_factors = ($risk_factors | append "NVIDIA driver configuration changed")
    }
    
    if ($changes.video_drivers_changed | default false) {
        $risk_score = ($risk_score + 2)
        $risk_factors = ($risk_factors | append "Video drivers configuration changed")
    }
    
    if ($changes.xserver_changed | default false) {
        $risk_score = ($risk_score + 1)
        $risk_factors = ($risk_factors | append "X server configuration changed")
    }
    
    # Determine risk level
    let risk_level = if $risk_score >= 5 {
        "high"
    } else if $risk_score >= 3 {
        "medium"
    } else {
        "low"
    }
    
    {
        score: $risk_score
        level: $risk_level
        factors: $risk_factors
        max_score: 10
    }
}

def generate_safety_recommendations [risk_assessment: record, hardware: record, config: record] {
    print $"($env.CYAN)💡 Generating safety recommendations...($env.NC)"
    
    mut recommendations = []
    
    # High risk recommendations
    if $risk_assessment.level == "high" {
        $recommendations = ($recommendations | append "⚠️  HIGH RISK: Create system backup before proceeding")
        $recommendations = ($recommendations | append "💾 Backup current configuration to safe location")
        $recommendations = ($recommendations | append "🔧 Ensure console access is available")
        $recommendations = ($recommendations | append "📱 Have recovery media ready")
    }
    
    # NVIDIA-specific recommendations
    if ($hardware.type == "nvidia") {
        $recommendations = ($recommendations | append "🎨 NVIDIA GPU: Ensure proper driver configuration")
        $recommendations = ($recommendations | append "⚡ Check for conflicting nouveau driver")
    }
    
    # Configuration recommendations
    if ($config.has_graphics_drivers | default false) {
        $recommendations = ($recommendations | append "🔄 Update graphics drivers configuration")
    }
    
    if ($config.has_nvidia_drivers | default false) {
        $recommendations = ($recommendations | append "🔄 Update NVIDIA drivers configuration")
    }
    
    # General recommendations
    $recommendations = ($recommendations | append "✅ Test configuration with nixos-rebuild dry-activate")
    $recommendations = ($recommendations | append "📋 Review generated configuration before applying")
    
    $recommendations
}

# --- Safety Functions ---
def create_configuration_backup [config_path: string, backup_dir: string] {
    print $"($env.CYAN)💾 Creating configuration backup...($env.NC)"
    
    try {
        # Ensure backup directory exists
        if not ($backup_dir | path exists) {
            mkdir $backup_dir
        }
        
        let timestamp = (date now | format date "%Y%m%d_%H%M%S")
        let backup_path = $"($backup_dir)/config_backup_($timestamp).nix"
        
        # Copy configuration
        cp $config_path $backup_path
        
        print $"($env.GREEN)✅ Configuration backed up to: ($backup_path)($env.NC)"
        
        {
            success: true
            backup_path: $backup_path
            timestamp: $timestamp
        }
    } catch { |err|
        print $"($env.RED)❌ Backup failed: ($err)($env.NC)"
        {
            success: false
            error: $err
        }
    }
}

def perform_safety_checks [] {
    print $"($env.CYAN)🔒 Performing safety checks...($env.NC)"
    
    # Check NixOS configuration syntax
    let syntax_check = try {
        let syntax_test = (safe_command "nixos-rebuild dry-activate")
        {
            syntax_valid: ( ($syntax_test | str length) > 0 )
        }
    } catch {
        {
            syntax_valid: false
        }
    }
    
    # Check for backup availability
    let backup_check = try {
        let backup_test = (safe_command "ls -la /etc/nixos/backup/")
        {
            backup_available: ( ($backup_test | str length) > 0 )
        }
    } catch {
        {
            backup_available: false
        }
    }
    
    # Check system resources
    let resource_check = try {
        let disk_space = (safe_command "df / | tail -n 1 | awk '{print $4}'")
        let memory_available = (safe_command "free | grep Mem | awk '{print $7}'")
        
        {
            disk_space_available: ( ($disk_space | into int) > 1000000 )
            memory_available: ( ($memory_available | into int) > 1000000 )
        }
    } catch {
        {
            disk_space_available: false
            memory_available: false
        }
    }
    
    # Check network connectivity
    let network_check = try {
        let network_test = (safe_command "ping -c 1 8.8.8.8")
        {
            network_available: ( ($network_test | str length) > 0 )
        }
    } catch {
        {
            network_available: false
        }
    }
    
    ($syntax_check | merge $backup_check | merge $resource_check | merge $network_check)
}

# --- Main Display Testing Function ---
def run_display_tests [config_path: string = "/etc/nixos/configuration.nix"] {
    print $"($env.BLUE)🎮 Starting Display Configuration Tests($env.NC)"
    print $"($env.DARK_GRAY)Testing configuration: ($config_path)($env.NC)\n"
    
    let config = setup_display_test_config
    
    # Phase 1: Hardware Detection
    print $"($env.YELLOW)=== Phase 1: Hardware Detection ===($env.NC)"
    let hardware = detect_gpu_hardware
    let display_env = detect_display_environment
    let drivers = detect_graphics_drivers
    
    print $"  🎨 GPU: ($hardware.name) (($hardware.type | str upcase))"
    print $"  🖥️  Display: ($display_env.display_server)"
    print $"  🖥️  Desktop: ($display_env.desktop_environment)"
    print $"  🎮 OpenGL: ($drivers.opengl | if $in { "✅" } else { "❌" })"
    print $"  🎮 Vulkan: ($drivers.vulkan | if $in { "✅" } else { "❌" })"
    print ""
    
    # Phase 2: Configuration Analysis
    print $"($env.YELLOW)=== Phase 2: Configuration Analysis ===($env.NC)"
    let config_analysis = analyze_nixos_config
    
    if $config_analysis.valid {
        print $"  📋 X Server: ($config_analysis.has_display_services | if $in { "✅" } else { "❌" })"
        print $"  🎨 NVIDIA: ($config_analysis.has_nvidia_drivers | if $in { "✅" } else { "❌" })"
        print $"  🎮 Gaming: ($config_analysis.has_gaming_modules | if $in { "✅" } else { "❌" })"
        print $"  🔄 Deprecated OpenGL: ($config_analysis.has_graphics_drivers | if $in { "⚠️" } else { "✅" })"
        print $"  🔄 Deprecated PulseAudio: ($config_analysis.has_pulseaudio_drivers | if $in { "⚠️" } else { "✅" })"
    } else {
        print $"  ❌ Configuration analysis failed: ($config_analysis.error)"
    }
    print ""
    
    # Phase 3: Risk Assessment
    print $"($env.YELLOW)=== Phase 3: Risk Assessment ===($env.NC)"
    let risk_assessment = calculate_risk_score $hardware $config_analysis {}
    let recommendations = generate_safety_recommendations $risk_assessment $hardware $config_analysis
    
    print $"  ⚠️  Risk Score: ($risk_assessment.score)/(($risk_assessment.max_score))"
    print $"  🚨 Risk Level: ($risk_assessment.level | str upcase)"
    
    if ($risk_assessment.factors | length) > 0 {
        print $"  📋 Risk Factors:"
        for factor in $risk_assessment.factors {
            print $"    • ($factor)"
        }
    }
    print ""
    
    # Phase 4: Safety Validation
    print $"($env.YELLOW)=== Phase 4: Safety Validation ===($env.NC)"
    let safety_checks = perform_safety_checks
    
    print $"  🔒 Syntax Valid: ($safety_checks.syntax_valid | if $in { "✅" } else { "❌" })"
    print $"  🔒 Backup Available: ($safety_checks.backup_available | if $in { "✅" } else { "❌" })"
    print $"  🔒 Disk Space: ($safety_checks.disk_space_available | if $in { "✅" } else { "❌" })"
    print $"  🔒 Memory: ($safety_checks.memory_available | if $in { "✅" } else { "❌" })"
    print $"  🔒 Network Access: ($safety_checks.network_available | if $in { "✅" } else { "❌" })"
    print ""
    
    # Phase 5: Recommendations
    print $"($env.YELLOW)=== Phase 5: Safety Recommendations ===($env.NC)"
    for recommendation in $recommendations {
        print $"  ($recommendation)"
    }
    print ""
    
    # Final Assessment
    let overall_safe = ($risk_assessment.level == "low") and $safety_checks.syntax_valid and $safety_checks.backup_available
    
    if $overall_safe {
        print $"($env.GREEN)✅ Display configuration appears safe to apply($env.NC)"
        true
    } else {
        print $"($env.RED)❌ Display configuration has potential risks($env.NC)"
        if $config.enable_interactive_mode {
            let proceed = input "(ansi yellow)Do you want to proceed anyway? (y/N): (ansi reset)"
            if ($proceed | str downcase | str contains "y") {
                print $"($env.YELLOW)⚠️  Proceeding with user confirmation...($env.NC)"
                true
            } else {
                print $"($env.YELLOW)🛑 Operation cancelled by user($env.NC)"
                false
            }
        } else {
            false
        }
    }
}

# --- Export Functions ---
export def test_display_configuration [config_path: string = "/etc/nixos/configuration.nix"] {
    run_display_tests $config_path
}

export def validate_display_safety [config_path: string = "/etc/nixos/configuration.nix"] {
    let hardware = detect_gpu_hardware
    let config_analysis = analyze_nixos_config
    let risk_assessment = calculate_risk_score $hardware $config_analysis {}
    
    {
        hardware: $hardware
        config: $config_analysis
        risk: $risk_assessment
        safe: ($risk_assessment.level == "low")
    }
}

export def backup_display_config [config_path: string = "/etc/nixos/configuration.nix"] {
    let backup_dir = "/tmp/nix-mox-display-backups"
    create_configuration_backup $config_path $backup_dir
}

# --- Main Test Runner ---
def main [] {
    if ($env.NU_TEST == "true") {
        print "Running display tests in test mode..."
        test_display_configuration
    } else {
        print "Display testing module loaded. Use test_display_configuration() to run tests."
    }
} 