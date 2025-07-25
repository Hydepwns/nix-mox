#!/usr/bin/env nu

# Interactive Setup Wizard for nix-mox
# Guides users through complete system configuration

use ../lib/platform.nu *
use ../lib/config.nu *
use ../lib/logging.nu *
use ../lib/common.nu *

# Setup wizard state
mut $SETUP_STATE = {
    step: 0,
    total_steps: 8,
    config: {},
    selected_features: [],
    platform: "",
    user_preferences: {}
}

# ASCII Art Banner
def show_banner [] {
    print "
╔═══════════════════════════════════════╗
║           🚀 nix-mox Setup            ║
║     Production-grade NixOS Config     ║
║            Setup Wizard               ║
╚═══════════════════════════════════════╝
"
}

# Progress indicator
def show_progress [] {
    let progress = ($SETUP_STATE.step * 100) / $SETUP_STATE.total_steps
    let filled = ($progress / 10) | math floor
    let empty = 10 - $filled
    
    let bar = (seq 1 $filled | each { "█" } | str join) + (seq 1 $empty | each { "░" } | str join)
    print $"Progress: [$bar] ($SETUP_STATE.step)/($SETUP_STATE.total_steps) - ($progress)%"
    print ""
}

# Interactive input with validation
def get_user_input [prompt: string, default: string = "", validator: closure = {|x| true}] {
    while true {
        let input = (input $"($prompt) [($default)]: ")
        let value = if ($input | is-empty) { $default } else { $input }
        
        if (do $validator $value) {
            return $value
        } else {
            print $"❌ Invalid input. Please try again."
        }
    }
}

# Multi-choice selection
def get_user_choice [prompt: string, choices: list] {
    print $"($prompt)"
    print ""
    
    for i in (seq 0 (($choices | length) - 1)) {
        print $"  ($i + 1). ($choices | get $i)"
    }
    print ""
    
    while true {
        let input = (input "Enter choice (1-$($choices | length)): ")
        let choice_num = try { $input | into int } catch { 0 }
        
        if $choice_num >= 1 and $choice_num <= ($choices | length) {
            return ($choices | get ($choice_num - 1))
        } else {
            print "❌ Please enter a valid choice number."
        }
    }
}

# Multi-select with checkboxes
def get_multi_select [prompt: string, options: list] {
    print $"($prompt)"
    print "Use space to toggle, enter to confirm:"
    print ""
    
    mut selected = ($options | each { false })
    mut current = 0
    
    while true {
        # Clear and redraw
        print "\n".repeat(($options | length) + 3)
        print "\033[A".repeat(($options | length) + 3)
        
        for i in (seq 0 (($options | length) - 1)) {
            let option = ($options | get $i)
            let is_selected = ($selected | get $i)
            let is_current = ($i == $current)
            
            let checkbox = if $is_selected { "☑" } else { "☐" }
            let cursor = if $is_current { "►" } else { " " }
            
            print $"($cursor) ($checkbox) ($option)"
        }
        
        print ""
        print "Controls: ↑/↓ navigate, space toggle, enter confirm, q quit"
        
        # This is a simplified version - in a real implementation you'd handle key input
        let action = (input "Action [space/enter/q]: ")
        
        match $action {
            "space" => {
                $selected = ($selected | update $current (not ($selected | get $current)))
            }
            "enter" => {
                let result = ($options | enumerate | where {|item| $selected | get $item.index} | get item)
                return $result
            }
            "q" => {
                return []
            }
            _ => {}
        }
    }
}

# Step 1: Platform Detection
def step_platform_detection [] {
    print "🔍 Step 1: Platform Detection"
    show_progress
    
    let detected_platform = detect_platform
    print $"Detected platform: ($detected_platform)"
    
    let platforms = ["linux", "darwin", "auto"]
    let platform_choice = get_user_choice "Select your platform:" $platforms
    
    $SETUP_STATE.platform = if ($platform_choice == "auto") { $detected_platform } else { $platform_choice }
    $SETUP_STATE.config = ($SETUP_STATE.config | insert platform $SETUP_STATE.platform)
    
    print $"✅ Platform set to: ($SETUP_STATE.platform)"
    $SETUP_STATE.step = $SETUP_STATE.step + 1
}

# Step 2: System Configuration
def step_system_config [] {
    print "⚙️  Step 2: System Configuration"
    show_progress
    
    let hostname = get_user_input "Enter hostname" (sys host | get hostname) {|h| ($h | str length) > 0}
    let timezone = get_user_input "Enter timezone" "UTC" {|tz| ($tz | str length) > 0}
    let locale = get_user_input "Enter locale" "en_US.UTF-8" {|l| ($l | str length) > 0}
    
    $SETUP_STATE.config = ($SETUP_STATE.config 
        | insert hostname $hostname
        | insert timezone $timezone  
        | insert locale $locale)
    
    print "✅ System configuration saved"
    $SETUP_STATE.step = $SETUP_STATE.step + 1
}

# Step 3: User Configuration
def step_user_config [] {
    print "👤 Step 3: User Configuration" 
    show_progress
    
    let username = get_user_input "Enter username" ($env.USER | default "nixos") {|u| ($u | str length) > 0}
    let shell = get_user_choice "Select default shell:" ["bash", "zsh", "fish", "nu"]
    
    let enable_sudo = (get_user_choice "Enable sudo access?" ["yes", "no"]) == "yes"
    
    $SETUP_STATE.config = ($SETUP_STATE.config 
        | insert user {
            name: $username,
            shell: $shell,
            sudo: $enable_sudo
        })
    
    print "✅ User configuration saved"
    $SETUP_STATE.step = $SETUP_STATE.step + 1
}

# Step 4: Feature Selection
def step_feature_selection [] {
    print "🎯 Step 4: Feature Selection"
    show_progress
    
    let available_features = [
        "Desktop Environment (GNOME/KDE)",
        "Development Tools",
        "Gaming Support",
        "Multimedia Workstation", 
        "Security Hardening",
        "Monitoring & Observability",
        "Remote Builder Setup",
        "ZFS Storage",
        "Docker/Containers",
        "VPN Configuration"
    ]
    
    print "Select features to enable (simplified multi-select):"
    for i in (seq 0 (($available_features | length) - 1)) {
        print $"  ($i + 1). ($available_features | get $i)"
    }
    
    let selections = get_user_input "Enter feature numbers (comma-separated)" "" {|s| true}
    
    let selected_indices = if ($selections | is-empty) { 
        [] 
    } else { 
        $selections | split row "," | each {|s| ($s | str trim | into int) - 1} | where {|i| $i >= 0 and $i < ($available_features | length)}
    }
    
    $SETUP_STATE.selected_features = ($selected_indices | each {|i| $available_features | get $i})
    
    print $"✅ Selected features: ($SETUP_STATE.selected_features | str join ', ')"
    $SETUP_STATE.step = $SETUP_STATE.step + 1
}

# Step 5: Storage Configuration
def step_storage_config [] {
    print "💾 Step 5: Storage Configuration"
    show_progress
    
    let use_zfs = if ("ZFS Storage" in $SETUP_STATE.selected_features) {
        print "ZFS storage is enabled."
        true
    } else {
        (get_user_choice "Enable ZFS storage?" ["yes", "no"]) == "yes"
    }
    
    if $use_zfs {
        let pool_name = get_user_input "Enter ZFS pool name" "rpool" {|p| ($p | str length) > 0}
        let compression = get_user_choice "Select compression:" ["lz4", "zstd", "gzip", "none"]
        
        $SETUP_STATE.config = ($SETUP_STATE.config 
            | insert storage {
                type: "zfs",
                pool: $pool_name,
                compression: $compression
            })
    } else {
        $SETUP_STATE.config = ($SETUP_STATE.config 
            | insert storage {
                type: "ext4",
                encryption: ((get_user_choice "Enable disk encryption?" ["yes", "no"]) == "yes")
            })
    }
    
    print "✅ Storage configuration saved"
    $SETUP_STATE.step = $SETUP_STATE.step + 1
}

# Step 6: Network Configuration
def step_network_config [] {
    print "🌐 Step 6: Network Configuration"
    show_progress
    
    let network_manager = get_user_choice "Select network management:" ["NetworkManager", "systemd-networkd", "manual"]
    let enable_firewall = (get_user_choice "Enable firewall?" ["yes", "no"]) == "yes"
    let enable_ssh = (get_user_choice "Enable SSH server?" ["yes", "no"]) == "yes"
    
    mut network_config = {
        manager: $network_manager,
        firewall: $enable_firewall,
        ssh: $enable_ssh
    }
    
    if $enable_ssh {
        let ssh_port = get_user_input "SSH port" "22" {|p| ($p | into int) > 0 and ($p | into int) < 65536}
        $network_config = ($network_config | insert ssh_port ($ssh_port | into int))
    }
    
    $SETUP_STATE.config = ($SETUP_STATE.config | insert network $network_config)
    
    print "✅ Network configuration saved"
    $SETUP_STATE.step = $SETUP_STATE.step + 1
}

# Step 7: Security & Monitoring
def step_security_monitoring [] {
    print "🔐 Step 7: Security & Monitoring"
    show_progress
    
    let security_level = get_user_choice "Select security level:" ["basic", "hardened", "paranoid"]
    let enable_monitoring = ("Monitoring & Observability" in $SETUP_STATE.selected_features) or 
                           ((get_user_choice "Enable monitoring (Prometheus/Grafana)?" ["yes", "no"]) == "yes")
    
    let fail2ban = (get_user_choice "Enable fail2ban?" ["yes", "no"]) == "yes"
    let auto_updates = (get_user_choice "Enable automatic security updates?" ["yes", "no"]) == "yes"
    
    $SETUP_STATE.config = ($SETUP_STATE.config 
        | insert security {
            level: $security_level,
            fail2ban: $fail2ban,
            auto_updates: $auto_updates
        }
        | insert monitoring {
            enabled: $enable_monitoring,
            prometheus: $enable_monitoring,
            grafana: $enable_monitoring
        })
    
    print "✅ Security and monitoring configuration saved"
    $SETUP_STATE.step = $SETUP_STATE.step + 1
}

# Step 8: Final Review and Generation
def step_final_review [] {
    print "📋 Step 8: Final Review"
    show_progress
    
    print "Configuration Summary:"
    print "=" * 50
    print $"Platform: ($SETUP_STATE.config.platform)"
    print $"Hostname: ($SETUP_STATE.config.hostname)"
    print $"User: ($SETUP_STATE.config.user.name) (shell: ($SETUP_STATE.config.user.shell))"
    print $"Features: ($SETUP_STATE.selected_features | str join ', ')"
    print $"Storage: ($SETUP_STATE.config.storage.type)"
    print $"Network: ($SETUP_STATE.config.network.manager)"
    print $"Security: ($SETUP_STATE.config.security.level)"
    print $"Monitoring: ($SETUP_STATE.config.monitoring.enabled)"
    print "=" * 50
    
    let confirm = get_user_choice "Proceed with this configuration?" ["yes", "no", "edit"]
    
    match $confirm {
        "yes" => {
            generate_configuration
            $SETUP_STATE.step = $SETUP_STATE.step + 1
        }
        "no" => {
            print "❌ Setup cancelled."
            exit 0
        }
        "edit" => {
            print "🔄 Returning to feature selection..."
            $SETUP_STATE.step = 3  # Go back to feature selection
        }
    }
}

# Generate final configuration
def generate_configuration [] {
    print "🎉 Generating nix-mox configuration..."
    
    let config_dir = "./generated-config"
    mkdir $config_dir
    
    # Generate main configuration.nix
    let config_content = generate_nixos_config
    $config_content | save $"($config_dir)/configuration.nix"
    
    # Generate flake.nix if needed
    if ($SETUP_STATE.selected_features | any {|f| $f | str contains "Development"}) {
        let flake_content = generate_flake_config
        $flake_content | save $"($config_dir)/flake.nix"
    }
    
    # Generate setup scripts
    let setup_script = generate_setup_script
    $setup_script | save $"($config_dir)/setup.sh"
    chmod +x $"($config_dir)/setup.sh"
    
    # Save configuration summary
    $SETUP_STATE.config | to json | save $"($config_dir)/config-summary.json"
    
    print $"✅ Configuration generated in: ($config_dir)"
    print ""
    print "Next steps:"
    print $"  1. Review generated files in ($config_dir)"
    print $"  2. Run: cd ($config_dir) && ./setup.sh"
    print "  3. Reboot when installation completes"
    print ""
    print "🎊 Setup wizard completed successfully!"
}

# Generate NixOS configuration
def generate_nixos_config [] {
    let features_imports = ($SETUP_STATE.selected_features | each {|f|
        match $f {
            "Desktop Environment (GNOME/KDE)" => "  ./profiles/desktop.nix"
            "Development Tools" => "  ./profiles/development.nix"
            "Gaming Support" => "  ./profiles/gaming.nix" 
            "Security Hardening" => "  ./profiles/security.nix"
            "Monitoring & Observability" => "  ./templates/services/monitoring/monitoring.nix"
            _ => $"  # ($f)"
        }
    } | str join "\n")
    
    $"# Generated by nix-mox interactive setup wizard
# Configuration for ($SETUP_STATE.config.hostname)

{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
($features_imports)
  ];

  # System configuration
  networking.hostName = \"($SETUP_STATE.config.hostname)\";
  time.timeZone = \"($SETUP_STATE.config.timezone)\";
  i18n.defaultLocale = \"($SETUP_STATE.config.locale)\";

  # User configuration
  users.users.($SETUP_STATE.config.user.name) = {
    isNormalUser = true;
    shell = pkgs.($SETUP_STATE.config.user.shell);
    extraGroups = [ \"wheel\" \"networkmanager\" \"audio\" \"video\" ];
  };

  # Network configuration
  networking.networkmanager.enable = ($SETUP_STATE.config.network.manager == \"NetworkManager\");
  networking.firewall.enable = ($SETUP_STATE.config.network.firewall);
  services.openssh.enable = ($SETUP_STATE.config.network.ssh);
  (if ($SETUP_STATE.config.network | get -i ssh_port) != null { $\"services.openssh.ports = [ ($SETUP_STATE.config.network.ssh_port) ];\" } else { \"\" })

  # Storage configuration
  (if ($SETUP_STATE.config.storage.type == \"zfs\") { 
    $\"boot.supportedFilesystems = [ \\\"zfs\\\" ];
  services.zfs.autoScrub.enable = true;\"
  } else { \"\" })

  # Security configuration  
  (if ($SETUP_STATE.config.security.fail2ban) { \"services.fail2ban.enable = true;\" } else { \"\" })
  (if ($SETUP_STATE.config.security.auto_updates) { \"system.autoUpgrade.enable = true;\" } else { \"\" })

  # System packages
  environment.systemPackages = with pkgs; [
    wget curl git vim htop
    # Additional packages based on features
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken.
  system.stateVersion = \"24.05\";
}"
}

# Generate setup script
def generate_setup_script [] {
    $"#!/usr/bin/env bash
# nix-mox automated setup script
# Generated by interactive setup wizard

set -euo pipefail

echo \"🚀 Starting nix-mox installation...\"

# Copy configuration to system location
sudo mkdir -p /etc/nixos/nix-mox
sudo cp -r . /etc/nixos/nix-mox/

# Backup existing configuration
if [ -f /etc/nixos/configuration.nix ]; then
    sudo cp /etc/nixos/configuration.nix /etc/nixos/configuration.nix.backup
fi

# Link new configuration
sudo ln -sf /etc/nixos/nix-mox/configuration.nix /etc/nixos/configuration.nix

# Build and switch
echo \"🔨 Building NixOS configuration...\"
sudo nixos-rebuild switch

echo \"✅ nix-mox installation completed!\"
echo \"🎉 Reboot to enjoy your new system!\"
"
}

# Generate flake configuration
def generate_flake_config [] {
    $"{
  description = \"nix-mox configuration for ($SETUP_STATE.config.hostname)\";

  inputs = {
    nixpkgs.url = \"github:NixOS/nixpkgs/nixos-unstable\"; 
    home-manager = {
      url = \"github:nix-community/home-manager\";
      inputs.nixpkgs.follows = \"nixpkgs\";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }: {
    nixosConfigurations.($SETUP_STATE.config.hostname) = nixpkgs.lib.nixosSystem {
      system = \"x86_64-linux\";
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
      ];
    };
  };
}"
}

# Main wizard flow
def main [] {
    show_banner
    
    print "Welcome to the nix-mox interactive setup wizard!"
    print "This wizard will guide you through configuring your NixOS system."
    print ""
    
    let start = get_user_choice "Ready to begin?" ["yes", "no"]
    if $start == "no" {
        print "👋 Setup cancelled. Run again when ready!"
        exit 0
    }
    
    # Initialize setup state
    $SETUP_STATE.step = 0
    
    # Run setup steps
    while $SETUP_STATE.step < $SETUP_STATE.total_steps {
        print ""
        match $SETUP_STATE.step {
            0 => step_platform_detection
            1 => step_system_config
            2 => step_user_config
            3 => step_feature_selection
            4 => step_storage_config
            5 => step_network_config
            6 => step_security_monitoring
            7 => step_final_review
            _ => break
        }
    }
}

# Auto-run if executed directly
if ($env.PWD? != null) {
    main
}