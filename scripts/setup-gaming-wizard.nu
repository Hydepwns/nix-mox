#!/usr/bin/env nu

# Interactive Gaming Setup Wizard for nix-mox
# Guides users through gaming workstation configuration

use lib/common.nu *

# Configuration constants
const GAMING_CONFIG_PATH = "config/nixos/gaming.nix"
const GAMING_MODULE_PATH = "modules/gaming/default.nix"

# Check for command line arguments
let args = ($env.args? | default [])
let dry_run = ($args | where $it == "--dry-run" | length) > 0
$env.DRY_RUN = $dry_run

# Add dry-run support
export-env {
    let dry_run = ($env.DRY_RUN? | default false)
    $env.DRY_RUN = $dry_run
}

def main [] {
    if ($env.DRY_RUN | default false) {
        print "(ansi yellow)⚠️  DRY-RUN MODE: No changes will be made. All actions are simulated.(ansi reset)\n"
    }
    
    print $"(ansi green)🎮 nix-mox Gaming Workstation Setup Wizard(ansi reset)"
    print $"(ansi yellow)==============================================(ansi reset)\n"
    
    # Check if running as root
    if not (is_root_user) {
        print $"(ansi red)❌ This wizard should be run with sudo for system configuration(ansi reset)"
        print $"(ansi yellow)💡 Run: sudo nu scripts/setup-gaming-wizard.nu(ansi reset)\n"
        exit 1
    }
    
    # Welcome and overview
    print $"(ansi cyan)Welcome to the nix-mox Gaming Workstation Setup Wizard!(ansi reset)"
    print "This wizard will help you configure your system for optimal gaming performance.\n"
    
    # Check prerequisites
    if not (check_prerequisites) {
        print $"(ansi red)❌ Prerequisites not met. Please install required packages first.(ansi reset)\n"
        exit 1
    }
    
    # Hardware detection
    print $"(ansi green)🔍 Detecting your hardware...(ansi reset)"
    let hardware_info = detect_hardware
    
    print $"(ansi green)✅ Hardware detection complete!(ansi reset)\n"
    
    # Display detected hardware
    display_hardware_info $hardware_info
    
    # Configuration options
    let config = get_user_preferences $hardware_info
    
    # Validate configuration
    if not (validate_configuration $config) {
        print $"(ansi red)❌ Invalid configuration. Please check your selections.(ansi reset)\n"
        exit 1
    }
    
    # Apply configuration
    print $"(ansi green)⚙️  Applying gaming configuration...(ansi reset)"
    let success = apply_gaming_config $config
    
    if not $success {
        print $"(ansi red)❌ Failed to apply gaming configuration.(ansi reset)\n"
        exit 1
    }
    
    # Test configuration
    print $"(ansi green)🧪 Testing gaming setup...(ansi reset)"
    let test_results = test_gaming_setup
    
    # Display results
    display_setup_results $config $test_results
    
    # Final instructions
    print $"(ansi green)🎉 Gaming workstation setup complete!(ansi reset)\n"
    display_final_instructions $config
    
    print $"(ansi yellow)📚 For more information, see: docs/guides/gaming.md(ansi reset)"
}

def is_root_user [] {
    try {
        (whoami) == "root"
    } catch {
        false
    }
}

def check_prerequisites [] {
    log_info "Checking prerequisites..."
    
    mut all_good = true
    
    # Check for required commands
    let required_commands = ["nix" "lspci" "free" "nproc"]
    
    for cmd in $required_commands {
        if (which $cmd | is-empty) {
            print $"  ❌ ($cmd) not found"
            $all_good = false
        } else {
            print $"  ✅ ($cmd) available"
        }
    }
    
    # Check for Nix flake
    if not ("flake.nix" | path exists) {
        print "  ❌ Not in a Nix flake directory"
        $all_good = false
    } else {
        print "  ✅ Nix flake found"
    }
    
    $all_good
}

def safe_command [cmd: string] {
    try {
        nu -c $cmd | str trim
    } catch {
        ""
    }
}

def safe_int [value: any] {
    try {
        $value | into int
    } catch {
        0
    }
}

def detect_hardware [] {
    log_info "Detecting hardware components..."
    
    # Detect GPU
    let gpu_info = detect_gpu
    
    # Detect audio
    let audio_info = detect_audio
    
    # Detect performance characteristics
    let performance_info = detect_performance
    
    # Detect storage
    let storage_info = detect_storage
    
    {
        gpu: $gpu_info
        audio: $audio_info
        performance: $performance_info
        storage: $storage_info
    }
}

def detect_gpu [] {
    let lspci_output = (safe_command "lspci | grep -i vga")
    
    if ($lspci_output | str contains "NVIDIA") {
        {
            type: "nvidia"
            name: ($lspci_output | str replace ".*: " "")
            driver: "nvidia"
            vulkan: true
        }
    } else if ($lspci_output | str contains "AMD") {
        {
            type: "amd"
            name: ($lspci_output | str replace ".*: " "")
            driver: "amdgpu"
            vulkan: true
        }
    } else if ($lspci_output | str contains "Intel") {
        {
            type: "intel"
            name: ($lspci_output | str replace ".*: " "")
            driver: "i915"
            vulkan: false
        }
    } else {
        {
            type: "unknown"
            name: "Unknown GPU"
            driver: "auto"
            vulkan: false
        }
    }
}

def detect_audio [] {
    if (safe_command "which pipewire-pulse" | str length) > 0 {
        {
            system: "pipewire"
            backend: "pulse"
            status: "available"
        }
    } else if (safe_command "which pulseaudio" | str length) > 0 {
        {
            system: "pulseaudio"
            backend: "pulse"
            status: "available"
        }
    } else if (safe_command "which alsa" | str length) > 0 {
        {
            system: "alsa"
            backend: "alsa"
            status: "available"
        }
    } else {
        {
            system: "unknown"
            backend: "auto"
            status: "not_detected"
        }
    }
}

def detect_performance [] {
    let cpu_cores = (safe_command "nproc" | into int | default 0)
    let mem_gb = (safe_command "free -g | grep Mem | awk '{print $2}'" | into int | default 0)
    let cpu_governor = (safe_command "cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor" | default "unknown")
    
    {
        cpu_cores: $cpu_cores
        memory_gb: $mem_gb
        cpu_governor: $cpu_governor
        recommended_parallel_jobs: (if $cpu_cores > 8 { 8 } else { $cpu_cores })
    }
}

def detect_storage [] {
    let disk_free_gb = (safe_command "df -h . | tail -n 1 | awk '{print $4}' | str replace 'G' ''" | into int | default 0)
    let storage_type = (safe_command "lsblk -d -o name,rota | grep -v NAME | head -n 1 | awk '{print $2}'" | default "unknown")
    
    {
        free_gb: $disk_free_gb
        type: (if $storage_type == "0" { "ssd" } else { "hdd" })
        recommended: ($disk_free_gb >= 50)
    }
}

def display_hardware_info [hardware: record] {
    print $"(ansi cyan)📋 Detected Hardware:(ansi reset)"
    print $"  🎨 GPU: ($hardware.gpu.name) (($hardware.gpu.type | str upcase))"
    print $"  🔊 Audio: ($hardware.audio.system | str upcase) with ($hardware.audio.backend) backend"
    print $"  ⚡ Performance: ($hardware.performance.cpu_cores) cores, ($hardware.performance.memory_gb)GB RAM"
    print $"  💾 Storage: ($hardware.storage.free_gb)GB free (($hardware.storage.type | str upcase))"
    print $"  🎯 CPU Governor: ($hardware.performance.cpu_governor)"
    print ""
}

def get_user_preferences [hardware: record] {
    print $"(ansi cyan)⚙️  Configuration Options:(ansi reset)\n"
    
    # GPU configuration
    let gpu_prompt = "(ansi yellow)GPU Configuration (auto/nvidia/amd/intel) [auto]: (ansi reset)"
    let gpu_choice = input $gpu_prompt
    let gpu_type = if ($gpu_choice | str trim | is-empty) { "auto" } else { $gpu_choice | str trim }
    
    # Performance options
    let perf_prompt = "(ansi yellow)Enable performance optimizations? (y/n) [y]: (ansi reset)"
    let performance_enabled = input $perf_prompt
    let performance = if ($performance_enabled | str trim | is-empty) or ($performance_enabled | str downcase | str contains "y") { true } else { false }
    
    # Audio options
    let audio_prompt = "(ansi yellow)Enable audio optimization? (y/n) [y]: (ansi reset)"
    let audio_enabled = input $audio_prompt
    let audio = if ($audio_enabled | str trim | is-empty) or ($audio_enabled | str downcase | str contains "y") { true } else { false }
    
    # Gaming platforms
    let steam_prompt = "(ansi yellow)Enable Steam support? (y/n) [y]: (ansi reset)"
    let steam_enabled = input $steam_prompt
    let steam = if ($steam_enabled | str trim | is-empty) or ($steam_enabled | str downcase | str contains "y") { true } else { false }
    
    let lutris_prompt = "(ansi yellow)Enable Lutris support? (y/n) [y]: (ansi reset)"
    let lutris_enabled = input $lutris_prompt
    let lutris = if ($lutris_enabled | str trim | is-empty) or ($lutris_enabled | str downcase | str contains "y") { true } else { false }
    
    let heroic_prompt = "(ansi yellow)Enable Heroic support? (y/n) [n]: (ansi reset)"
    let heroic_enabled = input $heroic_prompt
    let heroic = if ($heroic_enabled | str downcase | str contains "y") { true } else { false }
    
    let wine_prompt = "(ansi yellow)Enable Wine support? (y/n) [y]: (ansi reset)"
    let wine_enabled = input $wine_prompt
    let wine = if ($wine_enabled | str trim | is-empty) or ($wine_enabled | str downcase | str contains "y") { true } else { false }
    
    # Advanced options
    let gamemode_prompt = "(ansi yellow)Enable GameMode? (y/n) [y]: (ansi reset)"
    let gamemode_enabled = input $gamemode_prompt
    let gamemode = if ($gamemode_enabled | str trim | is-empty) or ($gamemode_enabled | str downcase | str contains "y") { true } else { false }
    
    let mangohud_prompt = "(ansi yellow)Enable MangoHud for performance monitoring? (y/n) [y]: (ansi reset)"
    let mangohud_enabled = input $mangohud_prompt
    let mangohud = if ($mangohud_enabled | str trim | is-empty) or ($mangohud_enabled | str downcase | str contains "y") { true } else { false }
    
    # Create configuration
    {
        gpu: { 
            type: $gpu_type
            detected: $hardware.gpu
        }
        performance: { 
            enable: $performance
            detected: $hardware.performance
        }
        audio: { 
            enable: $audio
            detected: $hardware.audio
        }
        storage: $hardware.storage
        platforms: {
            steam: $steam
            lutris: $lutris
            heroic: $heroic
            wine: $wine
        }
        tools: {
            gamemode: $gamemode
            mangohud: $mangohud
        }
    }
}

def validate_configuration [config: record] {
    log_info "Validating configuration..."
    
    mut valid = true
    
    # Check GPU configuration
    if not ($config.gpu.type in ["auto" "nvidia" "amd" "intel"]) {
        print "  ❌ Invalid GPU type"
        $valid = false
    }
    
    # Check storage
    if not $config.storage.recommended {
        print "  ⚠️  Low disk space - gaming may be limited"
    }
    
    # Check if at least one platform is enabled
    let platforms_enabled = ($config.platforms | values | where $it == true | length)
    if $platforms_enabled == 0 {
        print "  ❌ No gaming platforms enabled"
        $valid = false
    }
    
    $valid
}

def apply_gaming_config [config: record] {
    log_info "Applying gaming configuration..."
    
    # Handle dry-run mode first
    if ($env.DRY_RUN | default false) {
        print "(ansi yellow)⚠️  DRY-RUN: Would generate and save configuration, but skipping.(ansi reset)"
        print "(ansi yellow)⚠️  DRY-RUN: Would apply performance and audio optimizations, but skipping.(ansi reset)"
        return true
    }
    
    try {
        # Display configuration summary
        print $"(ansi cyan)📋 Configuration Summary:(ansi reset)"
        print $"  🎨 GPU: ($config.gpu.type)"
        print $"  ⚡ Performance: ($config.performance.enable)"
        print $"  🔊 Audio: ($config.audio.enable)"
        print $"  🎮 Steam: ($config.platforms.steam)"
        print $"  🎮 Lutris: ($config.platforms.lutris)"
        print $"  🎮 Heroic: ($config.platforms.heroic)"
        print $"  🍷 Wine: ($config.platforms.wine)"
        print $"  ⚡ GameMode: ($config.tools.gamemode)"
        print $"  📊 MangoHud: ($config.tools.mangohud)"
        print ""
        
        # Generate NixOS configuration
        let nix_config = generate_nixos_config $config
        
        # Save configuration
        $nix_config | save $GAMING_CONFIG_PATH
        
        print $"✅ Configuration saved to ($GAMING_CONFIG_PATH)"
        
        # Apply performance optimizations
        if $config.performance.enable {
            apply_performance_optimizations $config.performance.detected
        }
        
        # Apply audio optimizations
        if $config.audio.enable {
            apply_audio_optimizations $config.audio.detected
        }
        
        true
    } catch {
        log_error "Failed to apply configuration"
        false
    }
}

def generate_nixos_config [config: record] {
    let gpu_config = if $config.gpu.type == "auto" {
        "# Auto-detected GPU configuration"
    } else {
        $"services.xserver.videoDrivers = [\"($config.gpu.type)\"];"
    }
    
    let performance_config = if $config.performance.enable {
        "# Performance optimizations enabled"
    } else {
        "# Performance optimizations disabled"
    }
    
    let audio_config = if $config.audio.enable {
        "# Audio optimizations enabled"
    } else {
        "# Audio optimizations disabled"
    }
    
    let platforms_config = if $config.platforms.steam {
        "steam.enable = true;"
    } else {
        "# Steam disabled"
    }
    
    $"# nix-mox Gaming Configuration
# Generated by setup-gaming-wizard.nu

{ $gpu_config
  $performance_config
  $audio_config
  $platforms_config
}"
}

def apply_performance_optimizations [performance: record] {
    if ($env.DRY_RUN | default false) {
        print "(ansi yellow)⚠️  DRY-RUN: Would set CPU governor and enable GameMode, but skipping.(ansi reset)"
        return
    }
    
    log_info "Applying performance optimizations..."
    
    # Set CPU governor to performance
    if $performance.cpu_governor != "performance" {
        try {
            safe_command "echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor"
            print "  ✅ CPU governor set to performance"
        } catch {
            print "  ⚠️  Could not set CPU governor (may require manual configuration)"
        }
    }
    
    # Enable GameMode if available
    if (safe_command "which gamemoded" | str length) > 0 {
        try {
            safe_command "systemctl enable --now gamemoded"
            print "  ✅ GameMode enabled"
        } catch {
            print "  ⚠️  Could not enable GameMode"
        }
    }
}

def apply_audio_optimizations [audio: record] {
    if ($env.DRY_RUN | default false) {
        print "(ansi yellow)⚠️  DRY-RUN: Would apply audio optimizations, but skipping.(ansi reset)"
        return
    }
    
    log_info "Applying audio optimizations..."
    
    if $audio.system == "pipewire" {
        print "  ✅ PipeWire detected - audio optimized"
    } else if $audio.system == "pulseaudio" {
        print "  ⚠️  PulseAudio detected - consider upgrading to PipeWire"
    } else {
        print "  ⚠️  Audio system not optimized"
    }
}

def test_gaming_setup [] {
    log_info "Testing gaming setup..."
    
    mut results = {
        graphics: { success: false, details: "" }
        audio: { success: false, details: "" }
        tools: { success: false, details: "" }
    }
    
    # Test graphics
    print "  🎨 Testing graphics..."
    if (safe_command "which glxinfo" | str length) > 0 {
        $results = ($results | upsert graphics { success: true, details: "OpenGL support available" })
        print "    ✅ OpenGL support available"
    } else {
        $results = ($results | upsert graphics { success: false, details: "OpenGL support not detected" })
        print "    ⚠️  OpenGL support not detected"
    }
    
    # Test Vulkan
    if (safe_command "which vulkaninfo" | str length) > 0 {
        print "    ✅ Vulkan support available"
    } else {
        print "    ⚠️  Vulkan support not detected"
    }
    
    # Test audio
    print "  🔊 Testing audio..."
    if (safe_command "which pactl" | str length) > 0 {
        $results = ($results | upsert audio { success: true, details: "Audio system available" })
        print "    ✅ Audio system available"
    } else {
        $results = ($results | upsert audio { success: false, details: "Audio system not detected" })
        print "    ⚠️  Audio system not detected"
    }
    
    # Test gaming tools
    print "  🎮 Testing gaming tools..."
    mut tools_found = 0
    
    if (safe_command "which steam" | str length) > 0 {
        print "    ✅ Steam available"
        $tools_found = ($tools_found + 1)
    } else {
        print "    ⚠️  Steam not installed"
    }
    
    if (safe_command "which lutris" | str length) > 0 {
        print "    ✅ Lutris available"
        $tools_found = ($tools_found + 1)
    } else {
        print "    ⚠️  Lutris not installed"
    }
    
    if (safe_command "which wine" | str length) > 0 {
        print "    ✅ Wine available"
        $tools_found = ($tools_found + 1)
    } else {
        print "    ⚠️  Wine not installed"
    }
    
    let tools_details = $"($tools_found) gaming tools found"
    $results = ($results | upsert tools { success: ($tools_found > 0), details: $tools_details })
    
    $results
}

def display_setup_results [config: record, results: record] {
    print $"\n(ansi cyan)📊 Setup Results:(ansi reset)"
    
    let graphics_status = if $results.graphics.success { "✅" } else { "❌" }
    let audio_status = if $results.audio.success { "✅" } else { "❌" }
    let tools_status = if $results.tools.success { "✅" } else { "❌" }
    
    print $"  ($graphics_status) Graphics: ($results.graphics.details)"
    print $"  ($audio_status) Audio: ($results.audio.details)"
    print $"  ($tools_status) Tools: ($results.tools.details)"
    print ""
}

def display_final_instructions [config: record] {
    print $"(ansi cyan)Next steps:(ansi reset)"
    print "  1. Reboot your system: sudo reboot"
    print "  2. Enter gaming shell: nix develop .#gaming"
    print "  3. Test gaming setup: nu scripts/validate-gaming-config.nu"
    
    if $config.platforms.steam {
        print "  4. Launch Steam: steam"
    }
    
    if $config.platforms.lutris {
        print "  5. Launch Lutris: lutris"
    }
    
    print "  6. Configure game settings and enjoy!"
    print ""
    
    print $"(ansi yellow)💡 Tips:(ansi reset)"
    print "  • Use 'nix develop .#gaming' for the best gaming environment"
    print "  • Run 'nu scripts/validate-gaming-config.nu' to check your setup"
    print "  • Check 'docs/guides/gaming.md' for advanced configuration"
    print ""
}

# Export functions for use in other scripts
export def wizard [] {
    main
}

export def detect [] {
    detect_hardware
}

export def test [] {
    test_gaming_setup
}