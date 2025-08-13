#!/usr/bin/env nu

# Enhanced nix-mox Setup Script
# Allows granular selection of favorite configuration parts
# Usage: nu enhanced-setup.nu [--dry-run] [--help]

use ../lib/common.nu

# --- Global Variables ---
const CONFIG_DIR = "config"
const TEMPLATES_DIR = $CONFIG_DIR + "/templates"
const PERSONAL_DIR = $CONFIG_DIR + "/personal"
const NIXOS_DIR = $CONFIG_DIR + "/nixos"

# --- Configuration Categories ---
const CATEGORIES = {
    development: {
        name: "Development Tools"
        description: "IDEs, compilers, debuggers, and development utilities"
        components: {
            editors: {
                name: "Code Editors & IDEs"
                description: "Visual Studio Code, JetBrains IDEs, Vim, Neovim"
                packages: ["vscode", "vim", "neovim", "jetbrains.idea-community", "jetbrains.pycharm-community"]
            }
            languages: {
                name: "Programming Languages"
                description: "Rust, Python, Node.js, Go, Java, C/C++"
                packages: ["rustc", "cargo", "python3", "nodejs", "go", "jdk", "gcc", "clang"]
            }
            tools: {
                name: "Development Tools"
                description: "Git, Docker, build tools, debuggers"
                packages: ["git", "docker", "cmake", "ninja", "gdb", "lldb"]
            }
        }
    }
    gaming: {
        name: "Gaming & Entertainment"
        description: "Gaming platforms, performance tools, and media"
        components: {
            platforms: {
                name: "Gaming Platforms"
                description: "Steam, Lutris, Heroic, Epic Games"
                packages: ["steam", "lutris", "heroic"]
            }
            performance: {
                name: "Performance Tools"
                description: "Gamemode, MangoHud, monitoring tools"
                packages: ["gamemode", "mangohud", "htop", "radeontop"]
            }
            media: {
                name: "Media & Entertainment"
                description: "Video players, music, streaming"
                packages: ["vlc", "mpv", "spotify", "obs-studio"]
            }
            communication: {
                name: "Gaming Communication"
                description: "Discord, Teamspeak, voice chat"
                packages: ["discord", "teamspeak_client", "mumble"]
            }
        }
    }
    productivity: {
        name: "Productivity & Communication"
        description: "Communication tools, office apps, utilities"
        components: {
            communication: {
                name: "Communication"
                description: "Discord, Signal, Telegram, email clients"
                packages: ["discord", "signal-desktop", "telegram-desktop", "thunderbird"]
            }
            office: {
                name: "Office & Productivity"
                description: "LibreOffice, note-taking, task management"
                packages: ["libreoffice", "obsidian", "joplin"]
            }
            utilities: {
                name: "Utilities"
                description: "File managers, system monitors, backup tools"
                packages: ["ranger", "btop", "timeshift"]
            }
        }
    }
    system: {
        name: "System & Security"
        description: "System utilities, security, monitoring"
        components: {
            monitoring: {
                name: "System Monitoring"
                description: "Resource monitors, system information"
                packages: ["htop", "btop", "neofetch", "inxi"]
            }
            security: {
                name: "Security Tools"
                description: "Firewall, encryption, security utilities"
                packages: ["ufw", "gpg", "pass"]
            }
            networking: {
                name: "Networking"
                description: "VPN, network tools, remote access"
                packages: ["tailscale", "openvpn", "wireshark"]
            }
        }
    }
}

def main [] {
    $env.STATE = {
        dry_run: false
        username: ""
        email: ""
        timezone: ""
        hostname: ""
        git_username: ""
        git_email: ""
        selected_components: {}
        created_files: []
    }

    # --- Argument Parsing ---
    let args = $env._args
    for arg in $args {
        match $arg {
            "--dry-run" => {
                $env.STATE = ($env.STATE | upsert dry_run true)
            }
            "--help" | "-h" => {
                usage
            }
            _ => {
                log_error $"Unknown option: ($arg)"
                usage
            }
        }
    }

    if $env.STATE.dry_run {
        log_dryrun "Dry-run mode enabled. No files will be changed."
    }

    # --- Welcome and Setup ---
    print_welcome
    collect_personal_info
    collect_system_info
    
    # --- Component Selection ---
    let selected_components = select_components
    $env.STATE = ($env.STATE | upsert selected_components $selected_components)
    
    # --- Preview and Confirm ---
    preview_configuration
    let confirmed = confirm_configuration
    
    if $confirmed {
        # --- File Creation ---
        create_configuration_files
        print_final_steps
    } else {
        print "Setup cancelled."
        exit 0
    }

    return $env.STATE
}

def print_welcome [] {
    print $"\n($GREEN)🚀 Enhanced nix-mox Setup($NC)"
    print "================================"
    print ""
    print "Welcome to the enhanced nix-mox setup wizard!"
    print "This script allows you to select your favorite parts of the configuration."
    print ""
    print "What this setup will do:"
    print "• Collect your personal information"
    print "• Let you choose specific components you want"
    print "• Create a custom configuration based on your selections"
    print "• Set up your development environment"
    print ""
}

def collect_personal_info [] {
    print $"\n($BLUE)👤 Personal Information($NC)"
    print "======================="
    print "Please provide your personal information:"
    print ""

    let username = (input "Username (for system account): " | str trim)
    let email = (input "Email address: " | str trim)
    let git_username = (input "Git username: " | str trim)
    let git_email = (input "Git email: " | str trim)

    $env.STATE = ($env.STATE | merge {
        username: $username
        email: $email
        git_username: $git_username
        git_email: $git_email
    })
}

def collect_system_info [] {
    print $"\n($BLUE)🖥️  System Information($NC)"
    print "====================="
    print "Please provide system configuration:"
    print ""

    let hostname = (input "Hostname: " | str trim)
    let timezone = (input "Timezone (e.g., America/New_York): " | str trim)

    $env.STATE = ($env.STATE | merge {
        hostname: $hostname
        timezone: $timezone
    })
}

def select_components [] {
    print $"\n($BLUE)🎯 Select Your Favorite Components($NC)"
    print "====================================="
    print "Choose the components you want in your configuration:"
    print ""

    mut selected_components = {}

    # Iterate through categories
    for category in ($CATEGORIES | transpose category config | get category) {
        let config = ($CATEGORIES | get $category)
        
        print $"\n($YELLOW)📁 ($config.name)($NC)"
        print $($config.description)
        print ""
        
        let category_selection = select_category_components $category $config
        if ($category_selection | length) > 0 {
            $selected_components = ($selected_components | upsert $category $category_selection)
        }
    }

    $selected_components
}

def select_category_components [category: string, config: record] {
    mut selected = []
    
    # Show components in this category
    for component in ($config.components | transpose name details | get name) {
        let details = ($config.components | get $component)
        
        print $"  ($CYAN)• ($details.name)($NC)"
        print $"    ($details.description)"
        
        let response = (input $"Include ($details.name)? (Y/n): " | str trim)
        if $response == "" or $response == "y" or $response == "Y" {
            $selected = ($selected | append $component)
            print $"    ($GREEN)✓ Selected($NC)"
        } else {
            print $"    ($RED)✗ Skipped($NC)"
        }
        print ""
    }
    
    $selected
}

def preview_configuration [] {
    print $"\n($BLUE)📋 Configuration Preview($NC)"
    print "========================="
    print ""
    print $"Username: ($env.STATE.username)"
    print $"Hostname: ($env.STATE.hostname)"
    print $"Timezone: ($env.STATE.timezone)"
    print ""
    
    print "Selected components:"
    for category in ($env.STATE.selected_components | transpose category components | get category) {
        let components = ($env.STATE.selected_components | get $category)
        let category_name = ($CATEGORIES | get $category | get name)
        
        print $"  ($YELLOW)($category_name)($NC):"
        for component in $components {
            let component_name = ($CATEGORIES | get $category | get components | get $component | get name)
            print $"    • ($component_name)"
        }
        print ""
    }
}

def confirm_configuration [] {
    let response = (input "Proceed with this configuration? (Y/n): " | str trim)
    $response == "" or $response == "y" or $response == "Y"
}

def create_configuration_files [] {
    print $"\n($BLUE)📝 Creating Configuration Files($NC)"
    print "================================"

    # Create directories if they don't exist
    for dir in [$PERSONAL_DIR, $NIXOS_DIR] {
        if not (dir_exists $dir) {
            if not $env.STATE.dry_run {
                mkdir $dir
                $env.STATE = ($env.STATE | upsert created_files ($env.STATE.created_files | append $dir))
            } else {
                log_dryrun $"Would create directory: ($dir)"
            }
        }
    }

    # Create personal configuration
    create_personal_config

    # Create main configuration
    create_main_config

    # Create environment configuration
    create_env_config

    log_success "Configuration files created successfully!"
}

def create_personal_config [] {
    let user_config = $"# Personal User Configuration
# Generated by enhanced-setup.nu
# Customize this file with your personal settings

{{ config, pkgs, ... }}:
let
  # Personal settings
  personal = {{
    username = \"$env.STATE.username\";
    email = \"$env.STATE.email\";
    timezone = \"$env.STATE.timezone\";
    hostname = \"$env.STATE.hostname\";
    gitUsername = \"$env.STATE.git_username\";
    gitEmail = \"$env.STATE.git_email\";
  }};
in
{{
  # System user configuration
  users.users.${{personal.username}} = {{
    isNormalUser = true;
    description = personal.username;
    extraGroups = [ \"wheel\" \"networkmanager\" \"video\" \"audio\" ];
    shell = pkgs.zsh;
  }};

  # System configuration
  networking.hostName = personal.hostname;
  time.timeZone = personal.timezone;

  # Git configuration
  programs.git = {{
    enable = true;
    userName = personal.gitUsername;
    userEmail = personal.gitEmail;
    extraConfig = {{
      init.defaultBranch = \"main\";
      push.autoSetupRemote = true;
    }};
  }};
}}"

    let config_path = $PERSONAL_DIR + "/user.nix"
    if not $env.STATE.dry_run {
        $user_config | save $config_path
        $env.STATE = ($env.STATE | upsert created_files ($env.STATE.created_files | append $config_path))
        log_info $"Created personal configuration: ($config_path)"
    } else {
        log_dryrun $"Would create personal configuration: ($config_path)"
    }
}

def create_main_config [] {
    let selected_packages = generate_package_list
    let selected_services = generate_service_config
    
    let main_config = $"# Main Configuration
# Generated by enhanced-setup.nu
# Based on your selected components

{{ config, pkgs, ... }}:

{{
  imports = [
    ../profiles/base.nix
    ../profiles/security.nix
    ./personal/user.nix
  ];

  # Selected packages based on your choices
  environment.systemPackages = with pkgs; [
    ($selected_packages | str join "\n    ")
  ];

  # Selected services
  ($selected_services)

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
  time.timeZone = \"$env.STATE.timezone\";
  i18n.defaultLocale = \"en_US.UTF-8\";
}}"

    let config_path = $NIXOS_DIR + "/configuration.nix"
    if not $env.STATE.dry_run {
        $main_config | save $config_path
        $env.STATE = ($env.STATE | upsert created_files ($env.STATE.created_files | append $config_path))
        log_info $"Created main configuration: ($config_path)"
    } else {
        log_dryrun $"Would create main configuration: ($config_path)"
    }
}

def generate_package_list [] {
    mut packages = []
    
    # Add base packages
    $packages = ($packages | append [
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
    ])
    
    # Add selected component packages
    for category in ($env.STATE.selected_components | transpose category components | get category) {
        let components = ($env.STATE.selected_components | get $category)
        
        for component in $components {
            let component_packages = ($CATEGORIES | get $category | get components | get $component | get packages)
            $packages = ($packages | append $component_packages)
        }
    }
    
    # Remove duplicates and sort
    $packages | uniq | sort
}

def generate_service_config [] {
    mut services = []
    
    # Add services based on selected components
    if ($env.STATE.selected_components | get development | default [] | length) > 0 {
        $services = ($services | append [
            "  # Development services"
            "  virtualisation.docker = {"
            "    enable = true;"
            "    enableOnBoot = true;"
            "  };"
            ""
            "  services.openssh = {"
            "    enable = true;"
            "    settings = {"
            "      PasswordAuthentication = false;"
            "      PermitRootLogin = \"no\";"
            "    };"
            "  };"
        ])
    }
    
    if ($env.STATE.selected_components | get gaming | default [] | length) > 0 {
        $services = ($services | append [
            "  # Gaming services"
            "  programs.steam = {"
            "    enable = true;"
            "    remotePlay.openFirewall = true;"
            "    dedicatedServer.openFirewall = true;"
            "  };"
            ""
            "  security.rtkit.enable = true;"
            "  services.pipewire = {"
            "    enable = true;"
            "    alsa.enable = true;"
            "    alsa.support32Bit = true;"
            "    pulse.enable = true;"
            "    jack.enable = true;"
            "  };"
        ])
    }
    
    if ($env.STATE.selected_components | get system | default [] | length) > 0 {
        $services = ($services | append [
            "  # System services"
            "  services.tailscale.enable = true;"
        ])
    }
    
    $services | str join "\n"
}

def create_env_config [] {
    let env_content = $"# nix-mox Environment Configuration
# Generated by enhanced-setup.nu

# User configuration
NIXMOX_USERNAME=$env.STATE.username
NIXMOX_HOSTNAME=$env.STATE.hostname
NIXMOX_TIMEZONE=$env.STATE.timezone
NIXMOX_EMAIL=$env.STATE.email
NIXMOX_GIT_USERNAME=$env.STATE.git_username
NIXMOX_GIT_EMAIL=$env.STATE.git_email

# Selected components
NIXMOX_COMPONENTS=($env.STATE.selected_components | to json | str replace '"' '\\"')"
    
    if not $env.STATE.dry_run {
        $env_content | save .env
        $env.STATE = ($env.STATE | upsert created_files ($env.STATE.created_files | append ".env"))
        log_info "Created environment configuration: .env"
    } else {
        log_dryrun "Would create environment configuration: .env"
    }
}

def print_final_steps [] {
    print $"\n($GREEN)✅ Setup Complete!($NC)"
    print "=================="
    print ""
    print "Your custom nix-mox configuration has been created!"
    print ""
    print $"\n($YELLOW)📋 Next Steps:($NC)"
    print "1. Review your configuration files:"
    print $"   • Personal config: ($PERSONAL_DIR)/user.nix"
    print $"   • Main config: ($NIXOS_DIR)/configuration.nix"
    print "   • Environment: .env"
    print ""
    print "2. Build and switch to your configuration:"
    print "   sudo nixos-rebuild switch --flake .#nixos"
    print ""
    print "3. Enter development environment:"
    print "   nix develop"
    print ""
    print "4. Test your setup:"
    print "   nix flake check"
    print ""

    # Show component-specific notes
    if ($env.STATE.selected_components | get development | default [] | length) > 0 {
        print $"\n($BLUE)💻 Development Setup Notes:($NC)"
        print "• Enter development shell: nix develop .#development"
        print "• Open IDE: vscode or cursor"
        print "• Docker is enabled and ready to use"
    }

    if ($env.STATE.selected_components | get gaming | default [] | length) > 0 {
        print $"\n($BLUE)🎮 Gaming Setup Notes:($NC)"
        print "• Enter gaming shell: nix develop .#gaming"
        print "• Launch gaming platforms: steam, lutris, heroic"
        print "• Audio is configured for gaming with PipeWire"
    }

    if ($env.STATE.selected_components | get system | default [] | length) > 0 {
        print $"\n($BLUE)🛡️  System Setup Notes:($NC)"
        print "• Tailscale VPN is enabled"
        print "• System monitoring tools are available"
        print "• Security features are active"
    }

    print $"\n($GREEN)🎉 Enjoy your customized nix-mox environment!($NC)"
}

def usage [] {
    print "Usage: nu enhanced-setup.nu [OPTIONS]"
    print ""
    print "Enhanced interactive setup wizard for nix-mox configuration."
    print "Allows granular selection of favorite configuration components."
    print ""
    print "Options:"
    print "  --dry-run    Show what would be done, but make no changes"
    print "  --help, -h   Show this help message"
    print ""
    print "This script guides you through:"
    print "• Personal information collection"
    print "• Component selection (development, gaming, productivity, system)"
    print "• Configuration preview and confirmation"
    print "• Custom configuration file creation"
    exit 0
}

# --- Execution ---
try {
    main
} catch {
    log_error $"Setup failed: ($env.LAST_ERROR)"
    exit 1
} 