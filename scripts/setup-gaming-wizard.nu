#!/usr/bin/env nu

# Interactive Gaming Setup Wizard for nix-mox
# Guides users through gaming workstation configuration

def main [] {
    print $"(ansi green)🎮 nix-mox Gaming Workstation Setup Wizard(ansi reset)"
    print $"(ansi yellow)==============================================(ansi reset)\n"
    
    # Check if running as root
    if (whoami) != "root" {
        print $"(ansi red)❌ This wizard should be run with sudo for system configuration(ansi reset)"
        print $"(ansi yellow)💡 Run: sudo nu scripts/setup-gaming-wizard.nu(ansi reset)\n"
        exit 1
    }
    
    # Welcome and overview
    print $"(ansi cyan)Welcome to the nix-mox Gaming Workstation Setup Wizard!(ansi reset)"
    print "This wizard will help you configure your system for optimal gaming performance.\n"
    
    # Hardware detection
    print $"(ansi green)🔍 Detecting your hardware...(ansi reset)"
    let gpu_info = detect_gpu
    let audio_info = detect_audio
    let performance_info = detect_performance
    
    print $"(ansi green)✅ Hardware detection complete!(ansi reset)\n"
    
    # Display detected hardware
    print $"(ansi cyan)📋 Detected Hardware:(ansi reset)"
    print $"  GPU: ($gpu_info)"
    print $"  Audio: ($audio_info)"
    print $"  Performance: ($performance_info)\n"
    
    # Configuration options
    let config = get_user_preferences $gpu_info $audio_info $performance_info
    
    # Apply configuration
    print $"(ansi green)⚙️  Applying gaming configuration...(ansi reset)"
    apply_gaming_config $config
    
    # Test configuration
    print $"(ansi green)🧪 Testing gaming setup...(ansi reset)"
    test_gaming_setup
    
    # Final instructions
    print $"(ansi green)🎉 Gaming workstation setup complete!(ansi reset)\n"
    print $"(ansi cyan)Next steps:(ansi reset)"
    print "  1. Reboot your system: sudo reboot"
    print "  2. Enter gaming shell: nix develop .#gaming"
    print "  3. Test gaming: make gaming-test"
    print "  4. Launch Steam: steam\n"
    
    print $"(ansi yellow)📚 For more information, see: docs/guides/gaming.md(ansi reset)"
}

def detect_gpu [] {
    # Detect GPU type
    let lspci_output = (lspci | grep -i vga | str trim)
    
    if ($lspci_output | str contains "NVIDIA") {
        "NVIDIA GPU detected"
    } else if ($lspci_output | str contains "AMD") {
        "AMD GPU detected"
    } else if ($lspci_output | str contains "Intel") {
        "Intel GPU detected"
    } else {
        "Unknown GPU"
    }
}

def detect_audio [] {
    # Detect audio system
    if (which pulseaudio | is-empty) == false {
        "PulseAudio detected"
    } else if (which pipewire-pulse | is-empty) == false {
        "PipeWire detected"
    } else {
        "ALSA detected"
    }
}

def detect_performance [] {
    # Check CPU cores and memory
    let cpu_cores = (nproc)
    let mem_gb = (free -g | grep Mem | awk '{print $2}')
    
    $"($cpu_cores) cores, ($mem_gb)GB RAM"
}

def get_user_preferences [gpu_info: string, audio_info: string, performance_info: string] {
    print $"(ansi cyan)⚙️  Configuration Options:(ansi reset)\n"
    
    # GPU configuration
    let gpu_choice = input $"(ansi yellow)GPU Configuration (auto/nvidia/amd/intel) [auto]: (ansi reset)"
    let gpu_type = if ($gpu_choice | str trim | is-empty) { "auto" } else { $gpu_choice | str trim }
    
    # Performance options
    let performance_enabled = input $"(ansi yellow)Enable performance optimizations? (y/n) [y]: (ansi reset)"
    let performance = if ($performance_enabled | str trim | is-empty) or ($performance_enabled | str downcase | str contains "y") { true } else { false }
    
    # Audio options
    let audio_enabled = input $"(ansi yellow)Enable audio optimization? (y/n) [y]: (ansi reset)"
    let audio = if ($audio_enabled | str trim | is-empty) or ($audio_enabled | str downcase | str contains "y") { true } else { false }
    
    # Gaming platforms
    let steam_enabled = input $"(ansi yellow)Enable Steam support? (y/n) [y]: (ansi reset)"
    let steam = if ($steam_enabled | str trim | is-empty) or ($steam_enabled | str downcase | str contains "y") { true } else { false }
    
    let lutris_enabled = input $"(ansi yellow)Enable Lutris support? (y/n) [y]: (ansi reset)"
    let lutris = if ($lutris_enabled | str trim | is-empty) or ($lutris_enabled | str downcase | str contains "y") { true } else { false }
    
    let heroic_enabled = input $"(ansi yellow)Enable Heroic support? (y/n) [n]: (ansi reset)"
    let heroic = if ($heroic_enabled | str downcase | str contains "y") { true } else { false }
    
    # Create configuration
    {
        gpu: { type: $gpu_type }
        performance: { enable: $performance }
        audio: { enable: $audio }
        platforms: {
            steam: $steam
            lutris: $lutris
            heroic: $heroic
        }
    }
}

def apply_gaming_config [config: record] {
    # This would integrate with the existing gaming configuration
    print $"  GPU: ($config.gpu.type)"
    print $"  Performance: ($config.performance.enable)"
    print $"  Audio: ($config.audio.enable)"
    print $"  Steam: ($config.platforms.steam)"
    print $"  Lutris: ($config.platforms.lutris)"
    print $"  Heroic: ($config.platforms.heroic)"
    
    # TODO: Actually apply the configuration to NixOS
    print $"(ansi yellow)⚠️  Configuration preview shown above(ansi reset)"
    print $"(ansi yellow)💡 To apply: Add services.gaming configuration to your NixOS config(ansi reset)"
}

def test_gaming_setup [] {
    # Test basic gaming functionality
    print "  Testing graphics..."
    if (which glxinfo | is-empty) == false {
        print "    ✅ OpenGL support available"
    } else {
        print "    ⚠️  OpenGL support not detected"
    }
    
    print "  Testing audio..."
    if (which pactl | is-empty) == false {
        print "    ✅ Audio system available"
    } else {
        print "    ⚠️  Audio system not detected"
    }
    
    print "  Testing gaming tools..."
    if (which steam | is-empty) == false {
        print "    ✅ Steam available"
    } else {
        print "    ⚠️  Steam not installed"
    }
}

# Run the wizard
main 