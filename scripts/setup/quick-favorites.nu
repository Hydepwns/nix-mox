#!/usr/bin/env nu

# Quick Favorites Setup for nix-mox
# Quick setup for common favorite configurations
# Usage: nu quick-favorites.nu [PRESET] [--dry-run]

use ../lib/common.nu

# --- Quick Favorites Presets ---
const QUICK_PRESETS = {
    "dev-gaming": {
        name: "Developer Gaming Rig"
        description: "Perfect for developers who also game - includes development tools, gaming platforms, and performance optimizations"
        icon: "🎮💻"
        components: {
            development: ["editors", "languages", "tools"]
            gaming: ["platforms", "performance", "communication"]
            system: ["monitoring"]
        }
        features: [
            "Full development environment with IDEs and compilers"
            "Gaming platforms (Steam, Lutris, Heroic)"
            "Performance monitoring and optimization tools"
            "Gaming communication (Discord, Teamspeak)"
            "System monitoring and utilities"
        ]
    }
    "productivity": {
        name: "Productivity Workstation"
        description: "Focused on productivity, communication, and office work"
        icon: "📊💼"
        components: {
            productivity: ["communication", "office", "utilities"]
            system: ["monitoring", "security"]
        }
        features: [
            "Communication tools (Discord, Signal, Telegram, Thunderbird)"
            "Office suite (LibreOffice)"
            "Note-taking and task management"
            "System monitoring and security tools"
            "File management utilities"
        ]
    }
    "gaming-only": {
        name: "Pure Gaming Machine"
        description: "Dedicated gaming setup with all gaming platforms and optimizations"
        icon: "🎮⚡"
        components: {
            gaming: ["platforms", "performance", "media", "communication"]
            system: ["monitoring"]
        }
        features: [
            "All gaming platforms (Steam, Lutris, Heroic)"
            "Performance optimization tools (Gamemode, MangoHud)"
            "Media players and streaming tools"
            "Gaming communication platforms"
            "System monitoring for performance"
        ]
    }
    "dev-server": {
        name: "Development Server"
        description: "Server-focused development environment with remote access"
        icon: "🖥️🔧"
        components: {
            development: ["languages", "tools"]
            system: ["monitoring", "security", "networking"]
        }
        features: [
            "Programming languages and build tools"
            "SSH server for remote development"
            "System monitoring and security"
            "VPN and networking tools"
            "Docker for containerization"
        ]
    }
    "minimal-dev": {
        name: "Minimal Development"
        description: "Lightweight development environment with essential tools only"
        icon: "⚡💻"
        components: {
            development: ["editors", "languages"]
            system: ["monitoring"]
        }
        features: [
            "Essential code editors (Vim, VSCode)"
            "Core programming languages"
            "Basic system monitoring"
            "Minimal resource usage"
        ]
    }
    "media-center": {
        name: "Media Center"
        description: "Home entertainment and media playback system"
        icon: "🎬🎵"
        components: {
            gaming: ["media"]
            productivity: ["utilities"]
            system: ["monitoring"]
        }
        features: [
            "Media players (VLC, mpv)"
            "Streaming services"
            "Audio optimization"
            "System monitoring"
            "File management utilities"
        ]
    }
}

def main [
    preset?: string
    --dry-run
    --help
] {
    if $help {
        usage
    }
    
    let preset = ($preset | default "")
    let dry_run = $dry_run
    
    if $dry_run {
        print "🔍 Dry-run mode enabled. No files will be changed."
    }
    
    if $preset == "" {
        show_preset_menu
    } else {
        apply_preset $preset $dry_run
    }
}

def show_preset_menu [] {
    print $"\n($GREEN)⚡ Quick Favorites Setup($NC)"
    print "============================="
    print ""
    print "Choose a preset configuration:"
    print ""
    
    for preset in ($QUICK_PRESETS | transpose name config | get name) {
        let config = ($QUICK_PRESETS | get $preset)
        
        print $"($config.icon) ($YELLOW)($preset)($NC) - ($config.name)"
        print $"   ($config.description)"
        print ""
        print "   Features:"
        for feature in $config.features {
            print $"   • ($feature)"
        }
        print ""
    }
    
    print "Usage:"
    print "  nu quick-favorites.nu PRESET"
    print "  nu quick-favorites.nu PRESET --dry-run"
    print ""
    print "Examples:"
    print "  nu quick-favorites.nu dev-gaming"
    print "  nu quick-favorites.nu productivity --dry-run"
    print ""
}

def apply_preset [preset: string, dry_run: bool] {
    if ($QUICK_PRESETS | get $preset | is-empty) {
        print $"\n($RED)❌ Preset '($preset)' not found.($NC)"
        print ""
        print "Available presets:"
        for p in ($QUICK_PRESETS | transpose name config | get name) {
            print $"  • ($p)"
        }
        print ""
        exit 1
    }
    
    let config = ($QUICK_PRESETS | get $preset)
    
    print $"\n($GREEN)🚀 Setting up ($config.name)($NC)"
    print "=" * (($config.name | str length) + 20)
    print ""
            print $"($config.description)"
    print ""
    
    # Collect basic information
    let user_info = collect_basic_info
    
    # Apply the preset
    apply_preset_config $preset $config $user_info $dry_run
    
    # Show next steps
    show_next_steps $preset $config
}

def collect_basic_info [] {
    print $"\n($BLUE)👤 Basic Information($NC)"
    print "====================="
    print "Please provide basic system information:"
    print ""
    
    let username = (input "Username [nixos]: " | str trim)
    let hostname = (input "Hostname [nixos]: " | str trim)
    let timezone = (input "Timezone [UTC]: " | str trim)
    
    {
        username: (if $username == "" { "nixos" } else { $username })
        hostname: (if $hostname == "" { "nixos" } else { $hostname })
        timezone: (if $timezone == "" { "UTC" } else { $timezone })
    }
}

def apply_preset_config [preset: string, config: record, user_info: record, dry_run: bool] {
    print $"\n($BLUE)📝 Applying Configuration($NC)"
    print "============================="
    
    # Create directories
    let dirs = ["config/personal", "config/nixos"]
    for dir in $dirs {
        if not (dir_exists $dir) {
            if not $dry_run {
                mkdir $dir
                print "ℹ️" $"Created directory: ($dir)"
            } else {
                print "🔍" $"Would create directory: ($dir)"
            }
        }
    }
    
    # Generate package list based on preset
    let packages = generate_preset_packages $preset $config
    let services = generate_preset_services $preset $config
    
    # Create personal configuration
    create_personal_config $user_info $dry_run
    
    # Create main configuration
    create_main_config $user_info $packages $services $dry_run
    
    # Create environment file
    create_env_file $preset $user_info $dry_run
    
    print "✅" "Configuration applied successfully!"
}

def generate_preset_packages [preset: string, config: record] {
    mut packages = [
        "vim"
        "wget"
        "curl"
        "git"
        "htop"
        "btop"
        "tree"
        "ripgrep"
        "fd"
        "bat"
        "eza"
        "fzf"
        "kitty"
    ]
    
    # Add packages based on selected components
    for category in ($config.components | transpose cat comps | get cat) {
        let components = ($config.components | get $category)
        
        for component in $components {
            let component_packages = get_component_packages $category $component
            $packages = ($packages | append $component_packages)
        }
    }
    
    # Remove duplicates and sort
    $packages | uniq | sort
}

def get_component_packages [category: string, component: string] {
    # This would ideally reference the component database
    # For now, return common packages for each component
    match $category {
        "development" => {
            match $component {
                "editors" => ["vscode", "vim", "neovim"]
                "languages" => ["rustc", "cargo", "python3", "nodejs", "go", "jdk", "gcc", "clang"]
                "tools" => ["docker", "cmake", "ninja", "gdb", "lldb"]
                _ => []
            }
        }
        "gaming" => {
            match $component {
                "platforms" => ["steam", "lutris", "heroic"]
                "performance" => ["gamemode", "mangohud", "radeontop"]
                "media" => ["vlc", "mpv", "spotify", "obs-studio"]
                "communication" => ["discord", "teamspeak_client", "mumble"]
                _ => []
            }
        }
        "productivity" => {
            match $component {
                "communication" => ["discord", "signal-desktop", "telegram-desktop", "thunderbird"]
                "office" => ["libreoffice", "obsidian", "joplin"]
                "utilities" => ["ranger", "timeshift"]
                _ => []
            }
        }
        "system" => {
            match $component {
                "monitoring" => ["neofetch", "inxi"]
                "security" => ["ufw", "gpg", "pass"]
                "networking" => ["tailscale", "openvpn", "wireshark"]
                _ => []
            }
        }
        _ => []
    }
}

def generate_preset_services [preset: string, config: record] {
    mut services = []
    
    # Add services based on selected components
    for category in ($config.components | transpose cat comps | get cat) {
        let components = ($config.components | get $category)
        
        for component in $components {
            let component_services = get_component_services $category $component
            $services = ($services | append $component_services)
        }
    }
    
    $services
}

def get_component_services [category: string, component: string] {
    match $category {
        "development" => {
            match $component {
                "tools" => [
                    "virtualisation.docker = { enable = true; enableOnBoot = true; };"
                    "services.openssh = { enable = true; settings = { PasswordAuthentication = false; PermitRootLogin = \"no\"; }; };"
                ]
                _ => []
            }
        }
        "gaming" => {
            match $component {
                "platforms" => [
                    "programs.steam = { enable = true; remotePlay.openFirewall = true; dedicatedServer.openFirewall = true; };"
                ]
                "communication" => [
                    "security.rtkit.enable = true;"
                    "services.pipewire = { enable = true; alsa.enable = true; alsa.support32Bit = true; pulse.enable = true; jack.enable = true; };"
                ]
                _ => []
            }
        }
        "system" => {
            match $component {
                "networking" => [
                    "services.tailscale.enable = true;"
                ]
                _ => []
            }
        }
        _ => []
    }
}

def create_personal_config [user_info: record, dry_run: bool] {
    let config = $"# Personal User Configuration
# Generated by quick-favorites.nu

{{ config, pkgs, ... }}:

{{
  # System user configuration
  users.users.($user_info.username) = {{
    isNormalUser = true;
    description = \"($user_info.username)\";
    extraGroups = [ \"wheel\" \"networkmanager\" \"video\" \"audio\" ];
    shell = pkgs.zsh;
  }};

  # System configuration
  networking.hostName = \"($user_info.hostname)\";
  time.timeZone = \"($user_info.timezone)\";

  # Git configuration
  programs.git = {{
    enable = true;
    config = {{
      init.defaultBranch = \"main\";
      push.autoSetupRemote = true;
    }};
  }};
}}"

    if not $dry_run {
        $config | save config/personal/user.nix
        print "ℹ️" "Created personal configuration: config/personal/user.nix"
    } else {
        print "🔍" "Would create personal configuration: config/personal/user.nix"
    }
}

def create_main_config [user_info: record, packages: list, services: list, dry_run: bool] {
    let packages_str = ($packages | str join "\n    ")
    let services_str = ($services | str join "\n  ")
    
    let config = $"# Main Configuration
# Generated by quick-favorites.nu

{{ config, pkgs, ... }}:

{{
  imports = [
    ../profiles/base.nix
    ../profiles/security.nix
    ./personal/user.nix
  ];

  # Selected packages
  environment.systemPackages = with pkgs; [
    ($packages_str)
  ];

  # Selected services
  ($services_str)

  # Basic system configuration
  system.stateVersion = \"24.05\";
  
  # Enable sudo
  security.sudo.enable = true;

  # Nix configuration
  nix = {{
    settings = {{
      experimental-features = [ \"nix-command\" \"flakes\" ];
      auto-optimise-store = true;
      substituters = [
        \"https://cache.nixos.org\"
        \"https://hydepwns.cachix.org\"
      ];
      trusted-public-keys = [
        \"cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=\"
        \"hydepwns.cachix.org-1:xg8huKdwzBkLdkq5eCKenadhCROHIICGI9H6y3simJU=\"
      ];
    }};
    gc = {{
      automatic = true;
      dates = \"weekly\";
      options = \"--delete-older-than 30d\";
    }};
  }};

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Basic networking
  networking = {{
    networkmanager.enable = true;
    firewall = {{
      enable = true;
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
    }};
  }};

  # Basic locale and time
  time.timeZone = \"($user_info.timezone)\";
  i18n.defaultLocale = \"en_US.UTF-8\";
}}"

    if not $dry_run {
        $config | save config/nixos/configuration.nix
        print "ℹ️" "Created main configuration: config/nixos/configuration.nix"
    } else {
        print "🔍" "Would create main configuration: config/nixos/configuration.nix"
    }
}

def create_env_file [preset: string, user_info: record, dry_run: bool] {
    let env_content = $"# nix-mox Environment Configuration
# Generated by quick-favorites.nu

# User configuration
NIXMOX_USERNAME=($user_info.username)
NIXMOX_HOSTNAME=($user_info.hostname)
NIXMOX_TIMEZONE=($user_info.timezone)

# Preset configuration
NIXMOX_PRESET=($preset)
NIXMOX_PRESET_NAME=($QUICK_PRESETS | get $preset | get name)"
    
    if not $dry_run {
        $env_content | save .env
        print "ℹ️" "Created environment configuration: .env"
    } else {
        print "🔍" "Would create environment configuration: .env"
    }
}

def show_next_steps [preset: string, config: record] {
    print $"\n($GREEN)✅ Setup Complete!($NC)"
    print "=================="
    print ""
    print $"Your ($config.name) configuration has been created!"
    print ""
    
    print $"\n($YELLOW)📋 Next Steps:($NC)"
    print "1. Review your configuration files:"
    print "   • config/personal/user.nix"
    print "   • config/nixos/configuration.nix"
    print "   • .env"
    print ""
    print "2. Build and switch to your configuration:"
    print "   sudo nixos-rebuild switch --flake .#nixos"
    print ""
    print "3. Test your setup:"
    print "   nix flake check"
    print ""
    
    # Show preset-specific notes
    match $preset {
        "dev-gaming" => {
            print $"\n($BLUE)🎮💻 Dev-Gaming Notes:($NC)"
            print "• Enter development shell: nix develop .#development"
            print "• Enter gaming shell: nix develop .#gaming"
            print "• Launch Steam: steam"
            print "• Open IDE: vscode or cursor"
        }
        "productivity" => {
            print $"\n($BLUE)📊💼 Productivity Notes:($NC)"
            print "• Open LibreOffice: libreoffice"
            print "• Launch communication apps from application menu"
            print "• Access notes: obsidian or joplin"
        }
        "gaming-only" => {
            print $"\n($BLUE)🎮⚡ Gaming Notes:($NC)"
            print "• Launch Steam: steam"
            print "• Open Lutris: lutris"
            print "• Launch Heroic: heroic"
            print "• Join Discord: discord"
        }
        "dev-server" => {
            print $"\n($BLUE)🖥️🔧 Server Notes:($NC)"
            print "• SSH server is enabled"
            print "• Docker is ready to use"
            print "• Tailscale VPN is enabled"
            print "• Access remotely via SSH"
        }
        "minimal-dev" => {
            print $"\n($BLUE)⚡💻 Minimal Dev Notes:($NC)"
            print "• Open VSCode: vscode"
            print "• Use Vim: vim"
            print "• Lightweight development environment"
        }
        "media-center" => {
            print $"\n($BLUE)🎬🎵 Media Center Notes:($NC)"
            print "• Launch VLC: vlc"
            print "• Open Spotify: spotify"
            print "• Use mpv for video: mpv"
            print "• Stream with OBS: obs-studio"
        }
        _ => {}
    }
    
    print $"\n($GREEN)🎉 Enjoy your ($config.name)!($NC)"
}

def usage [] {
    print "Usage: nu quick-favorites.nu [PRESET] [OPTIONS]"
    print ""
    print "Quick setup for common favorite configurations."
    print ""
    print "Presets:"
    for preset in ($QUICK_PRESETS | transpose name config | get name) {
        let config = ($QUICK_PRESETS | get $preset)
        print $"  ($preset) - ($config.name)"
    }
    print ""
    print "Options:"
    print "  --dry-run    Show what would be done, but make no changes"
    print "  --help, -h   Show this help message"
    print ""
    print "Examples:"
    print "  nu quick-favorites.nu dev-gaming"
    print "  nu quick-favorites.nu productivity --dry-run"
    exit 0
}

# --- Execution ---
try {
    main
} catch { |err|
    print $"❌ Quick favorites setup failed: ($err)"
    exit 1
} 