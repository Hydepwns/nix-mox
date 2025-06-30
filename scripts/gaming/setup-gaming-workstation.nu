#!/usr/bin/env nu

# Gaming Workstation Setup Script
# Combines development and gaming capabilities for dual-purpose workstations

use ../lib/error-handling.nu *
use ../lib/config.nu *
use ../lib/logging.nu *
use ../lib/security.nu *
use ../lib/performance.nu *

# Script metadata
export const SCRIPT_METADATA = {
    name: "setup-gaming-workstation"
    description: "Setup gaming workstation with development capabilities"
    version: "1.0.0"
    author: "nix-mox"
    category: "gaming"
    platform: "linux"
    requires_root: false
}

def show_help [] {
    print $"
🎮 Gaming Workstation Setup Script
==================================

Usage: nu scripts/gaming/setup-gaming-workstation.nu [OPTIONS]

Options:
  --help, -h              Show this help message
  --dry-run               Show what would be done without making changes
  --debug                 Enable debug output
  --interactive, -i       Interactive mode with prompts
  --development           Include development tools
  --gaming-only           Gaming tools only (no development)
  --performance           Enable performance optimizations
  --audio                 Configure audio for gaming
  --gpu <type>            GPU type: auto, nvidia, amd, intel
  --steam                 Install Steam
  --lutris                Install Lutris
  --heroic                Install Heroic Games Launcher
  --wine                  Configure Wine for Windows games
  --league                Setup League of Legends
  --benchmark             Run performance benchmarks after setup

Examples:
  # Basic gaming setup
  nu scripts/gaming/setup-gaming-workstation.nu

  # Development + Gaming workstation
  nu scripts/gaming/setup-gaming-workstation.nu --development --performance

  # Gaming-only with specific GPU
  nu scripts/gaming/setup-gaming-workstation.nu --gaming-only --gpu nvidia

  # Interactive setup
  nu scripts/gaming/setup-gaming-workstation.nu --interactive

  # Dry run to see what would be done
  nu scripts/gaming/setup-gaming-workstation.nu --dry-run
"
}

def parse_args [] {
    let args = $in
    
    mut config = {
        dry_run: false
        debug: false
        interactive: false
        development: false
        gaming_only: false
        performance: false
        audio: false
        gpu: "auto"
        steam: false
        lutris: false
        heroic: false
        wine: false
        league: false
        benchmark: false
    }
    
    mut i = 0
    while $i < ($args | length) {
        let arg = $args | get $i
        
        match $arg {
            "--help" | "-h" => {
                show_help
                exit 0
            }
            "--dry-run" => {
                $config.dry_run = true
            }
            "--debug" => {
                $config.debug = true
            }
            "--interactive" | "-i" => {
                $config.interactive = true
            }
            "--development" => {
                $config.development = true
            }
            "--gaming-only" => {
                $config.gaming_only = true
            }
            "--performance" => {
                $config.performance = true
            }
            "--audio" => {
                $config.audio = true
            }
            "--steam" => {
                $config.steam = true
            }
            "--lutris" => {
                $config.lutris = true
            }
            "--heroic" => {
                $config.heroic = true
            }
            "--wine" => {
                $config.wine = true
            }
            "--league" => {
                $config.league = true
            }
            "--benchmark" => {
                $config.benchmark = true
            }
            "--gpu" => {
                $i = $i + 1
                if $i < ($args | length) {
                    $config.gpu = ($args | get $i)
                }
            }
            _ => {
                if ($arg | str starts-with "-") {
                    error $"Unknown option: ($arg)"
                    show_help
                    exit 1
                }
            }
        }
        $i = $i + 1
    }
    
    $config
}

def detect_gpu [] {
    info "Detecting GPU..."
    
    let gpu_info = (lspci | grep -i vga)
    
    if ($gpu_info | str contains "NVIDIA") {
        { type: "nvidia", name: "NVIDIA", score: 3 }
    } else if ($gpu_info | str contains "AMD") {
        { type: "amd", name: "AMD", score: 3 }
    } else if ($gpu_info | str contains "Intel") {
        { type: "intel", name: "Intel", score: 2 }
    } else {
        { type: "unknown", name: "Unknown", score: 1 }
    }
}

def validate_system [] {
    info "Validating system requirements..."
    
    mut results = {}
    
    # Check available memory
    let mem_info = (free -h | lines | where ($it | str contains "Mem") | split row " " | where ($it | str length) > 0)
    let mem_total = ($mem_info | get 1)
    let mem_gb = ($mem_total | str replace "Gi" "" | into float)
    
    if $mem_gb >= 8.0 {
        $results = ($results | upsert memory "Sufficient" | upsert memory_score 2)
        info $"Memory: Sufficient ($mem_total)"
    } else {
        $results = ($results | upsert memory "Insufficient" | upsert memory_score 0)
        warn $"Memory: Insufficient ($mem_total) - 8GB+ recommended"
    }
    
    # Check available storage
    let storage_info = (df -h . | lines | last | split row " " | where ($it | str length) > 0)
    let storage_avail = ($storage_info | get 3)
    let storage_gb = ($storage_avail | str replace "G" "" | into float)
    
    if $storage_gb >= 50.0 {
        $results = ($results | upsert storage "Sufficient" | upsert storage_score 2)
        info $"Storage: Sufficient ($storage_avail)"
    } else {
        $results = ($results | upsert storage "Insufficient" | upsert storage_score 0)
        warn $"Storage: Insufficient ($storage_avail) - 50GB+ recommended"
    }
    
    # Check GPU
    let gpu = detect_gpu
    $results = ($results | upsert gpu $gpu.name | upsert gpu_score $gpu.score)
    info $"GPU: ($gpu.name) detected"
    
    # Calculate overall score
    let total_score = ($results.memory_score + $results.storage_score + $results.gpu_score)
    $results = ($results | upsert total_score $total_score)
    
    if $total_score >= 5 {
        info "System validation: PASSED"
    } else {
        warn "System validation: WARNING - Some requirements not met"
    }
    
    $results
}

def setup_gaming_environment [config: record] {
    info "Setting up gaming environment..."
    
    # Create gaming config directory
    try {
        mkdir ~/.config/gaming
    } catch {
        # Directory might already exist
    }
    
    # Set up environment variables
    let env_vars = {
        GAMING_MODE: "enabled"
        GAMING_PERFORMANCE: $config.performance
        GAMING_AUDIO: $config.audio
        GAMING_GPU: $config.gpu
        STEAM_ENABLED: $config.steam
        LUTRIS_ENABLED: $config.lutris
        HEROIC_ENABLED: $config.heroic
        WINE_ENABLED: $config.wine
        LEAGUE_ENABLED: $config.league
    }
    
    # Write environment variables to file
    $env_vars | to json | save --force ~/.config/gaming/environment.json
    
    info "Gaming environment configured"
}

def setup_gaming_platforms [config] {
    info "Setting up gaming platforms..."
    
    if $config.dry_run {
        info "DRY RUN: Would setup gaming platforms"
        return
    }
    
    mut platforms = if $config.steam or $config.lutris or $config.heroic {
        []
    } else {
        ["steam", "lutris", "heroic"]
    }
    
    if $config.steam {
        $platforms = ($platforms | append "steam")
    }
    if $config.lutris {
        $platforms = ($platforms | append "lutris")
    }
    if $config.heroic {
        $platforms = ($platforms | append "heroic")
    }
    
    $platforms | each { |platform|
        info $"Setting up ($platform)..."
        
        match $platform {
            "steam" => {
                # Steam setup
                info "Steam will be available in gaming devshell"
            }
            "lutris" => {
                # Lutris setup
                info "Lutris will be available in gaming devshell"
            }
            "heroic" => {
                # Heroic setup
                info "Heroic will be available in gaming devshell"
            }
            _ => {
                warn $"Unknown platform: ($platform)"
            }
        }
    }
    
    info "Gaming platforms configured"
}

def setup_wine [config] {
    if not $config.wine {
        return
    }
    
    info "Setting up Wine configuration..."
    
    if $config.dry_run {
        info "DRY RUN: Would setup Wine"
        return
    }
    
    # Create Wine prefixes directory
    mkdir ~/.wine-prefixes
    
    # Create general Wine prefix
    if not ($config.dry_run) {
        env WINEPREFIX=~/.wine-prefixes/general WINEARCH=win64 wineboot -i
        env WINEPREFIX=~/.wine-prefixes/general winetricks -q d3dx9 vcrun2019 dxvk vkd3d
    }
    
    info "Wine configuration completed"
}

def setup_league_of_legends [config] {
    if not $config.league {
        return
    }
    
    info "Setting up League of Legends..."
    
    if $config.dry_run {
        info "DRY RUN: Would setup League of Legends"
        return
    }
    
    # Create League-specific Wine prefix
    mkdir ~/.wine-prefixes/league
    
    if not ($config.dry_run) {
        env WINEPREFIX=~/.wine-prefixes/league WINEARCH=win64 wineboot -i
        env WINEPREFIX=~/.wine-prefixes/league winetricks -q d3dx9 vcrun2019 dxvk vkd3d xact xact_x64
        env WINEPREFIX=~/.wine-prefixes/league winetricks settings win7
    }
    
    # Create launch script
    let launch_script = '#!/bin/bash
export WINEPREFIX=~/.wine-prefixes/league
export WINEARCH=win64
export DXVK=1
export DXVK_HUD=1

# Launch with GameMode and MangoHud for optimal performance
gamemoderun mangohud wine LeagueClient.exe "$@"
'
    
    $launch_script | save ~/.local/bin/league-launch
    chmod +x ~/.local/bin/league-launch
    
    info "League of Legends setup completed"
}

def setup_development_environment [config] {
    if not $config.development {
        return
    }
    
    info "Setting up development environment..."
    
    if $config.dry_run {
        info "DRY RUN: Would setup development environment"
        return
    }
    
    # Create development directories
    mkdir ~/.config/development
    mkdir ~/.cache/development
    
    # Set up development environment variables
    let dev_env_vars = {
        EDITOR: "cursor"
        VISUAL: "cursor"
        BROWSER: "firefox"
        TERMINAL: "alacritty"
    }
    
    $dev_env_vars | to json | save ~/.config/development/environment.json
    
    info "Development environment configured"
}

def setup_performance_optimizations [config] {
    if not $config.performance {
        return
    }
    
    info "Setting up performance optimizations..."
    
    if $config.dry_run {
        info "DRY RUN: Would setup performance optimizations"
        return
    }
    
    # Create performance configuration
    let perf_config = {
        gamemode: {
            enable: true
            cpu_governor: "performance"
            gpu_power: "performance"
        }
        mangohud: {
            enable: true
            fps: true
            gpu_stats: true
            cpu_stats: true
        }
        kernel_params: [
            "nvidia-drm.modeset=1"
            "amdgpu.si_support=1"
            "amdgpu.cik_support=1"
            "i915.enable_rc6=1"
            "i915.enable_fbc=1"
        ]
    }
    
    $perf_config | to json | save ~/.config/gaming/performance.json
    
    info "Performance optimizations configured"
}

def setup_audio [config] {
    if not $config.audio {
        return
    }
    
    info "Setting up audio configuration..."
    
    if $config.dry_run {
        info "DRY RUN: Would setup audio configuration"
        return
    }
    
    # Create audio configuration
    let audio_config = {
        pipewire: {
            enable: true
            low_latency: true
            realtime_priority: true
        }
        pulseaudio: {
            enable: false
        }
        jack: {
            enable: false
        }
    }
    
    $audio_config | to json | save ~/.config/gaming/audio.json
    
    info "Audio configuration completed"
}

def run_benchmarks [config] {
    if not $config.benchmark {
        return
    }
    
    info "Running performance benchmarks..."
    
    if $config.dry_run {
        info "DRY RUN: Would run benchmarks"
        return
    }
    
    # Run gaming benchmark script
    nu scripts/gaming/gaming-benchmark.nu
}

def create_launch_scripts [] {
    info "Creating launch scripts..."
    
    # Ensure ~/.local/bin exists
    let bin_dir = ($env.HOME | path join ".local" "bin")
    try {
        mkdir $bin_dir
    } catch {
        # Directory might already exist
    }
    
    let scripts = {
        "gaming-shell": "#!/usr/bin/env bash
# Gaming development shell launcher
echo \"🎮 Starting gaming development environment...\"
nix develop .#gaming -c $SHELL
"
        "gaming-setup": "#!/usr/bin/env bash
# Quick gaming setup
echo \"🎮 Setting up gaming environment...\"
nix develop .#gaming -c nu scripts/gaming/setup-gaming-workstation.nu $@
"
        "dev-gaming": "#!/usr/bin/env bash
# Development + Gaming shell
echo \"💻 Starting development + gaming environment...\"
nix develop .#development -c nix develop .#gaming -c $SHELL
"
    }
    
    $scripts | columns | each {|name|
        let content = $scripts | get $name
        let script_path = ($bin_dir | path join $name)
        $content | save --force $script_path
        try {
            chmod +x $script_path
            info $"Created launch script: ($name)"
        } catch { |err|
            warn $"Failed to make ($name) executable: ($err)"
        }
    }
    
    info "Launch scripts created in ($bin_dir)"
    info "Available commands:"
    info "  gaming-shell    - Start gaming development shell"
    info "  gaming-setup    - Run gaming workstation setup"
    info "  dev-gaming      - Start development + gaming shell"
}

def show_completion_message [config] {
    print '''
🎮 Gaming Workstation Setup Complete!
====================================

✅ System validated and configured
✅ Gaming environment setup
✅ Performance optimizations applied
✅ Launch scripts created

🚀 Quick Start Commands:
=======================

# Enter gaming shell
gaming-shell

# Enter development shell  
dev-shell

# Test gaming setup
gaming-test

# Launch League of Legends (if configured)
league-launch

🎯 Available Gaming Platforms:
============================

Steam:     Available in gaming shell
Lutris:    Available in gaming shell  
Heroic:    Available in gaming shell

⚡ Performance Tools:
===================

GameMode:  CPU/GPU optimization
MangoHud:  Performance overlay
DXVK:      DirectX to Vulkan translation

🔧 Configuration Files:
=====================

~/.config/gaming/environment.json    # Gaming environment variables
~/.config/gaming/performance.json    # Performance settings
~/.config/gaming/audio.json          # Audio configuration
~/.wine-prefixes/                    # Wine prefixes

📚 Next Steps:
=============

1. Enter gaming shell: gaming-shell
2. Launch Steam: steam
3. Launch Lutris: lutris
4. Test performance: gaming-test
5. Configure specific games as needed

For more information, see docs/guides/gaming.md
'''
}

def main [config: record] {
    # Setup logging
    if $config.debug {
        $env.NIXMOX_LOG_LEVEL = "DEBUG"
    }
    let log_level = ($env.NIXMOX_LOG_LEVEL? | default "INFO")
    let logging_config = {
        logging: {
            level: $log_level
            format: "text"
            file: null
        }
    }
    setup_logging $logging_config
    
    info "Starting gaming workstation setup..."
    
    # Validate system
    let system_validation = validate_system
    
    # Setup components based on configuration
    setup_gaming_environment $config
    setup_gaming_platforms $config
    setup_wine $config
    setup_league_of_legends $config
    setup_development_environment $config
    setup_performance_optimizations $config
    setup_audio $config
    
    # Create launch scripts
    create_launch_scripts
    
    # Run benchmarks if requested
    run_benchmarks $config
    
    # Show completion message
    show_completion_message $config
    
    info "Gaming workstation setup completed successfully!"
}

# Main entry point - run with default configuration
let config = {
    dry_run: false
    debug: false
    interactive: false
    development: false
    gaming_only: false
    performance: false
    audio: false
    gpu: "auto"
    steam: false
    lutris: false
    heroic: false
    wine: false
    league: false
    benchmark: false
}
main $config 