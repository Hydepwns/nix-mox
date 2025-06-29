#!/usr/bin/env nu

# Gaming Workstation Setup Script for nix-mox
# This script sets up a comprehensive gaming environment on NixOS

use lib/common.nu *

def show_banner [] {
    print $"\n(ansi blue_bold)🎮 nix-mox: Gaming Workstation Setup(ansi reset)"
    print $"(ansi dark_gray)Comprehensive gaming environment configuration(ansi reset)\n"
}

def detect_gpu [] {
    log_info "Detecting GPU hardware..."
    
    try {
        # Check for NVIDIA GPU
        let nvidia_check = (lspci | str contains "NVIDIA" | length)
        if $nvidia_check > 0 {
            log_success "NVIDIA GPU detected"
            return "nvidia"
        }
        
        # Check for AMD GPU
        let amd_check = (lspci | str contains "AMD" | length)
        if $amd_check > 0 {
            log_success "AMD GPU detected"
            return "amd"
        }
        
        # Check for Intel GPU
        let intel_check = (lspci | str contains "Intel" | length)
        if $intel_check > 0 {
            log_success "Intel GPU detected"
            return "intel"
        }
        
        log_warn "No specific GPU detected, using auto configuration"
        return "auto"
    } catch { |err|
        log_error $"Could not detect GPU: ($err)"
        return "auto"
    }
}

def check_system_requirements [] {
    log_info "Checking system requirements..."
    
    mut requirements_met = true
    
    # Check CPU cores
    try {
        let cpu_cores = (nproc | into int)
        if $cpu_cores >= 4 {
            log_success $"CPU cores: ($cpu_cores) (sufficient)"
        } else {
            log_warn $"CPU cores: ($cpu_cores) (minimum 4 recommended)"
            $requirements_met = false
        }
    } catch { |err|
        log_error $"Could not check CPU cores: ($err)"
        $requirements_met = false
    }
    
    # Check RAM
    try {
        let total_ram = (free -m | lines | get 1 | split row " " | where ($it | str length) > 0 | get 1 | into int)
        if $total_ram >= 8192 {
            log_success $"RAM: ($total_ram) MB (sufficient)"
        } else {
            log_warn $"RAM: ($total_ram) MB (minimum 8GB recommended)"
            $requirements_met = false
        }
    } catch { |err|
        log_error $"Could not check RAM: ($err)"
        $requirements_met = false
    }
    
    # Check disk space
    try {
        let disk_usage = (df -h / | lines | skip 1 | get 0 | str replace -r '.*\s+(\d+)%\s+.*' '$1' | into int)
        if $disk_usage < 90 {
            log_success $"Disk usage: ($disk_usage)% (sufficient space)"
        } else {
            log_warn $"Disk usage: ($disk_usage)% (low space)"
            $requirements_met = false
        }
    } catch { |err|
        log_error $"Could not check disk space: ($err)"
        $requirements_met = false
    }
    
    $requirements_met
}

def configure_gaming_profile [] {
    log_info "Configuring gaming profile..."
    
    let gpu_type = (detect_gpu)
    
    # Create gaming profile configuration
    let gaming_config = {
        gpu_type: $gpu_type
        performance_enabled: true
        audio_enabled: true
        platforms: {
            steam: true
            lutris: true
            heroic: true
        }
    }
    
    # Save configuration
    try {
        $gaming_config | to json | save ~/.config/nix-mox/gaming-profile.json
        log_success "Gaming profile saved"
    } catch { |err|
        log_error $"Could not save gaming profile: ($err)"
    }
    
    $gaming_config
}

def setup_environment_variables [] {
    log_info "Setting up gaming environment variables..."
    
    # Create environment file
    let env_content = $"
# Gaming Environment Variables
export DXVK_HUD=1
export DXVK_STATE_CACHE=1
export DXVK_STATE_CACHE_PATH=~/.cache/dxvk
export __GL_SHADER_DISK_CACHE=1
export __GL_SHADER_DISK_CACHE_PATH=~/.cache/gl-shaders
export __GL_SYNC_TO_VBLANK=0
export __GL_THREADED_OPTIMIZATIONS=1
export MESA_GL_VERSION_OVERRIDE=4.5
export MESA_GLSL_VERSION_OVERRIDE=450

# Performance optimizations
export GAMEMODE_RUN=1
export MANGOHUD=1

# Audio optimizations
export PULSE_LATENCY_MSEC=60
export JACK_LATENCY=256
"
    
    try {
        $env_content | save ~/.config/nix-mox/gaming-env.sh
        log_success "Environment variables configured"
    } catch { |err|
        log_error $"Could not save environment variables: ($err)"
    }
}

def create_cache_directories [] {
    log_info "Creating cache directories..."
    
    let cache_dirs = [
        "~/.cache/dxvk"
        "~/.cache/gl-shaders"
        "~/.cache/mangohud"
        "~/.cache/gamemode"
        "~/.local/share/lutris"
        "~/.local/share/heroic"
    ]
    
    for dir in $cache_dirs {
        try {
            mkdir -p $dir
            log_success $"Created: ($dir)"
        } catch { |err|
            log_warn $"Could not create ($dir): ($err)"
        }
    }
}

def test_gaming_setup [] {
    log_info "Testing gaming setup..."
    
    mut tests_passed = 0
    mut total_tests = 0
    
    # Test OpenGL
    $total_tests = $total_tests + 1
    try {
        let opengl_version = (glxinfo | str contains "OpenGL version" | length)
        if $opengl_version > 0 {
            log_success "OpenGL support: OK"
            $tests_passed = $tests_passed + 1
        } else {
            log_error "OpenGL support: Failed"
        }
    } catch { |err|
        log_error $"OpenGL test failed: ($err)"
    }
    
    # Test Vulkan
    $total_tests = $total_tests + 1
    try {
        let vulkan_check = (vulkaninfo | str contains "Vulkan" | length)
        if $vulkan_check > 0 {
            log_success "Vulkan support: OK"
            $tests_passed = $tests_passed + 1
        } else {
            log_warn "Vulkan support: Limited"
        }
    } catch { |err|
        log_warn $"Vulkan test failed: ($err)"
    }
    
    # Test audio
    $total_tests = $total_tests + 1
    try {
        let audio_check = (pactl list sinks | str contains "State: RUNNING" | length)
        if $audio_check > 0 {
            log_success "Audio system: OK"
            $tests_passed = $tests_passed + 1
        } else {
            log_warn "Audio system: Not running"
        }
    } catch { |err|
        log_warn $"Audio test failed: ($err)"
    }
    
    # Test Wine
    $total_tests = $total_tests + 1
    try {
        let wine_version = (wine --version | str trim)
        log_success $"Wine version: ($wine_version)"
        $tests_passed = $tests_passed + 1
    } catch { |err|
        log_error $"Wine test failed: ($err)"
    }
    
    {
        passed: $tests_passed
        total: $total_tests
        success_rate: (($tests_passed / $total_tests) * 100 | into int)
    }
}

def show_next_steps [] {
    print $"\n(ansi green_bold)✅ Gaming Workstation Setup Complete!(ansi reset)"
    print $"(ansi dark_gray)══════════════════════════════════════════════════════════════(ansi reset)\n"
    
    print $"(ansi cyan_bold)🎮 Next Steps:(ansi reset)"
    print $"  1. Reboot your system to apply all changes"
    print $"  2. Enter gaming shell: nix develop .#gaming"
    print $"  3. Test your setup: ./devshells/gaming/scripts/test-gaming.sh"
    print $"  4. Configure Wine: wine-setup"
    print $"  5. Install games through Steam, Lutris, or Heroic"
    print $"\n(ansi cyan_bold)🔧 Quick Commands:(ansi reset)"
    print $"  • nix develop .#gaming                    # Enter gaming shell"
    print $"  • source ~/.config/nix-mox/gaming-env.sh  # Load gaming environment"
    print $"  • steam                                   # Launch Steam"
    print $"  • lutris                                  # Launch Lutris"
    print $"  • heroic                                  # Launch Heroic"
    print $"\n(ansi cyan_bold)📊 Performance Monitoring:(ansi reset)"
    print $"  • mangohud <command>                      # Monitor FPS"
    print $"  • gamemoderun <command>                   # Optimize performance"
    print $"  • htop                                    # Monitor system resources"
    print $"\n(ansi cyan_bold)🎯 Gaming Profiles:(ansi reset)"
    print $"  • Development: nix develop .#development  # Full development tools"
    print $"  • Gaming: nix develop .#gaming            # Gaming-optimized environment"
    print $"  • Both: Use both shells simultaneously    # Shared resources"
    print $"\n(ansi yellow)💡 Tip: Your system is now configured for both development and gaming!(ansi reset)"
    print $"   You can switch between environments or use them simultaneously."
    print $"\n"
}

def main [] {
    show_banner
    
    # Check if running as root
    if (whoami | str trim) == "root" {
        log_error "This script should not be run as root"
        exit 1
    }
    
    # Check system requirements
    let requirements_ok = (check_system_requirements)
    if not $requirements_ok {
        log_warn "Some system requirements are not met, but setup will continue"
    }
    
    # Configure gaming profile
    let gaming_config = (configure_gaming_profile)
    
    # Setup environment
    setup_environment_variables
    create_cache_directories
    
    # Test setup
    let test_results = (test_gaming_setup)
    
    # Show results
    print $"\n(ansi blue_bold)📊 Setup Results(ansi reset)"
    print $"(ansi dark_gray)══════════════════════════════════════════════════════════════(ansi reset)"
    print $"GPU Type: ($gaming_config.gpu_type)"
    print $"Tests Passed: ($test_results.passed)/($test_results.total) (($test_results.success_rate)%)"
    
    if $test_results.success_rate >= 80 {
        log_success "Gaming setup is ready!"
    } else if $test_results.success_rate >= 60 {
        log_warn "Gaming setup is mostly ready, some features may need configuration"
    } else {
        log_error "Gaming setup needs attention, check the errors above"
    }
    
    show_next_steps
}

# Run the setup
main 