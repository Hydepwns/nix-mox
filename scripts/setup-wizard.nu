#!/usr/bin/env nu

# nix-mox Configuration Wizard
# Interactive setup script for nix-mox configuration

use lib/common.nu *

def show_banner [] {
    print $"\n(ansi green_bold)╔══════════════════════════════════════════════════════════════╗"
    print $"║                    (ansi yellow_bold)nix-mox Configuration Wizard(ansi green_bold)                    ║"
    print $"║                                                                    ║"
    print $"║  Welcome to nix-mox! This wizard will help you configure         ║"
    print $"║  your system with the right settings for your needs.             ║"
    print $"╚══════════════════════════════════════════════════════════════════╝(ansi reset)\n"
}

def ask_question [question: string, options: list, default: string = ""] {
    print $"\n(ansi cyan_bold)($question)(ansi reset)"

    for i in 0..($options | length) {
        let option = $options | get $i
        let marker = if $option == $default { "(ansi green)✓" } else { " " }
        print $"  ($marker) [($i)] ($option)"
    }

    let answer = (input | str trim)
    if $answer == "" and $default != "" {
        $default
    } else {
        let index = ($answer | into int)
        if $index >= 0 and $index < ($options | length) {
            $options | get $index
        } else {
            print $"(ansi red)Invalid selection. Please try again.(ansi reset)"
            ask_question $question $options $default
        }
    }
}

def ask_yes_no [question: string, default: bool = true] {
    let default_text = if $default { "Y/n" } else { "y/N" }
    print $"\n(ansi cyan_bold)($question) [($default_text)](ansi reset)"

    let answer = (input | str trim | str downcase)
    if $answer == "" {
        $default
    } else if $answer in ["y", "yes", "true"] {
        true
    } else if $answer in ["n", "no", "false"] {
        false
    } else {
        print $"(ansi red)Invalid answer. Please use y/n.(ansi reset)"
        ask_yes_no $question $default
    }
}

def ask_text [question: string, default: string = ""] {
    let prompt = if $default != "" { $"($question) [($default)]" } else { $question }
    print $"\n(ansi cyan_bold)($prompt)(ansi reset)"

    let answer = (input | str trim)
    if $answer == "" and $default != "" {
        $default
    } else {
        $answer
    }
}

def detect_platform [] {
    let platform = (sys | get host.name)
    print $"\n(ansi green)✓ Detected platform: (ansi yellow)($platform)(ansi reset)"
    $platform
}

def select_use_case [] {
    let use_cases = [
        "Desktop - Personal computer with GUI"
        "Server - Headless server for services"
        "Development - Development workstation"
        "Gaming - Gaming-focused setup"
        "Minimal - Minimal system with basic tools"
        "Custom - Custom configuration"
    ]

    ask_question "What type of system are you setting up?" $use_cases "Desktop - Personal computer with GUI"
}

def select_features [] {
    print $"\n(ansi cyan_bold)Select features to enable:(ansi reset)"

    let features = [
        { name: "messaging", description: "Messaging & Communication (Signal, Telegram, Discord)", default: true }
        { name: "gaming", description: "Gaming Support (Wine, Steam, DXVK)", default: false }
        { name: "development", description: "Development Tools (IDEs, compilers, debuggers)", default: false }
        { name: "monitoring", description: "Monitoring & Observability (Prometheus, Grafana)", default: false }
        { name: "security", description: "Security Features (firewall, fail2ban, SSL)", default: true }
        { name: "storage", description: "Storage Management (ZFS, RAID, backups)", default: false }
    ]

    mut selected_features = []

    for feature in $features {
        let enabled = (ask_yes_no $feature.description $feature.default)
        if $enabled {
            $selected_features = ($selected_features | append $feature.name)
        }
    }

    $selected_features
}

def configure_basic_settings [] {
    print $"\n(ansi cyan_bold)Basic System Configuration:(ansi reset)"

    # Hostname
    let hostname = (ask_text "Enter hostname" "nixos-system")

    # Timezone
    let timezone = (ask_text "Enter timezone (e.g., America/New_York, Europe/London)" "UTC")

    # Username
    let username = (ask_text "Enter username for the main user" "user")

    {
        hostname: $hostname
        timezone: $timezone
        username: $username
    }
}

def configure_hardware [] {
    print $"\n(ansi cyan_bold)Hardware Configuration:(ansi reset)"

    let has_hardware_config = (ask_yes_no "Do you have an existing hardware configuration file?" false)

    if $has_hardware_config {
        print $"\n(ansi yellow)Please place your hardware configuration in:"
        print $"  config/hardware/hardware-configuration-actual.nix(ansi reset)"
    } else {
        print $"\n(ansi yellow)After setup, generate hardware configuration with:"
        print $"  sudo nixos-generate-config --show-hardware-config > config/hardware/hardware-configuration-actual.nix(ansi reset)"
    }

    $has_hardware_config
}

def generate_configuration [config: record] {
    print $"\n(ansi cyan_bold)Generating Configuration Files...(ansi reset)"

    # Create configuration directory structure
    mkdir config/nixos
    mkdir config/home
    mkdir config/hardware

    # Generate main configuration
    let config_content = generate_main_config $config
    $config_content | save config/nixos/configuration.nix

    # Generate hardware configuration template if needed
    if not $config.hardware_config {
        let hw_template = generate_hardware_template
        $hw_template | save config/hardware/hardware-configuration.nix
    }

    # Generate flake.nix if it doesn't exist
    if not ("flake.nix" | path exists) {
        let flake_content = generate_flake_config $config
        $flake_content | save flake.nix
    }

    print $"\n(ansi green)✓ Configuration files generated successfully!(ansi reset)"
}

def generate_main_config [config: record] {
    mut imports = [
        "../../modules/templates/base/common.nix"
        "../hardware/hardware-configuration.nix"
    ]

    # Add feature-specific imports
    if $config.messaging {
        $imports = ($imports | append "../../modules/templates/base/common/messaging.nix")
    }

    if $config.gaming {
        $imports = ($imports | append "../../modules/templates/base/common/gaming.nix")
    }

    if $config.development {
        $imports = ($imports | append "../../modules/templates/base/common/development.nix")
    }

    if $config.monitoring {
        $imports = ($imports | append "../../modules/templates/base/common/monitoring.nix")
    }

    if $config.security {
        $imports = ($imports | append "../../modules/security/all")
    }

    let imports_str = ($imports | each { |imp| $"    ($imp)" } | str join "\n")
    let hostname = $config.basic.hostname
    let timezone = $config.basic.timezone
    let username = $config.basic.username

    $"# Generated by nix-mox Configuration Wizard
# Generated on: ((date now | format date '%Y-%m-%d %H:%M:%S'))

{{ config, pkgs, inputs, ... }}:

{{
  imports = [
($imports_str)
  ];

  # Basic system configuration
  networking.hostName = \"($hostname)\";
  time.timeZone = \"($timezone)\";

  # Enable sudo
  security.sudo.enable = true;

  # Create main user
  users.users.($username) = {{
    isNormalUser = true;
    extraGroups = [ \"wheel\" \"networkmanager\" \"video\" \"audio\" ];
    shell = pkgs.zsh;
  }};

  # Enable SSH
  services.openssh = {{
    enable = true;
    settings = {{
      PermitRootLogin = \"no\";
      PasswordAuthentication = false;
    }};
  }};

  # Enable firewall
  networking.firewall = {{
    enable = true;
    allowedTCPPorts = [ 22 80 443 ];
  }};

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    htop
    git
    # Include nix-mox packages
    inputs.nix-mox.packages.${{pkgs.system}}.proxmox-update
    inputs.nix-mox.packages.${{pkgs.system}}.vzdump-backup
    inputs.nix-mox.packages.${{pkgs.system}}.zfs-snapshot
    inputs.nix-mox.packages.${{pkgs.system}}.nixos-flake-update
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken.
  system.stateVersion = \"23.11\";
}}"
}

def generate_hardware_template [] {
    "# Hardware Configuration Template
# This file serves as a template for hardware configuration.
# The actual hardware configuration should be generated using:
# sudo nixos-generate-config --show-hardware-config > config/hardware/hardware-configuration-actual.nix

{{ config, lib, pkgs, modulesPath, ... }}:

let
  # Import the actual hardware configuration
  # This should be generated for your specific hardware
  actualHardware = import ./hardware-configuration-actual.nix {{ inherit config lib pkgs modulesPath; }};
in

# Use the actual hardware configuration if it exists, otherwise use a basic template
if builtins.pathExists ./hardware-configuration-actual.nix then
  actualHardware
else {{
  imports = [
    (modulesPath + \"/installer/scan/not-detected.nix\")
  ];

  # Basic hardware configuration template
  # Replace this with your actual hardware configuration

  boot.initrd.availableKernelModules = [ \"xhci_pci\" \"ahci\" \"nvme\" \"usb_storage\" \"usbhid\" \"sd_mod\" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # File systems - replace with your actual file system configuration
  fileSystems.\"/\" = {{
    device = \"/dev/disk/by-uuid/YOUR-ROOT-UUID\";
    fsType = \"ext4\";
  }};

  fileSystems.\"/boot\" = {{
    device = \"/dev/disk/by-uuid/YOUR-BOOT-UUID\";
    fsType = \"vfat\";
    options = [ \"fmask=0077\" \"dmask=0077\" ];
  }};

  swapDevices = [ ];

  # Networking
  networking.useDHCP = lib.mkDefault true;

  # Platform
  nixpkgs.hostPlatform = lib.mkDefault \"x86_64-linux\";

  # CPU microcode updates
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}}"
}

def generate_flake_config [config: record] {
    let hostname = $config.basic.hostname
    let username = $config.basic.username

    $"# Generated by nix-mox Configuration Wizard
# Generated on: ((date now | format date '%Y-%m-%d %H:%M:%S'))

{{
  description = \"NixOS configuration generated by nix-mox wizard\";

  inputs = {{
    nixpkgs.url = \"github:NixOS/nixpkgs/nixos-unstable\";
    nix-mox = {{
      url = \"github:Hydepwns/nix-mox\";
      inputs.nixpkgs.follows = \"nixpkgs\";
    }};
    home-manager = {{
      url = \"github:nix-community/home-manager\";
      inputs.nixpkgs.follows = \"nixpkgs\";
    }};
  }};

  outputs = {{ self, nixpkgs, nix-mox, home-manager, ... }}: {{
    nixosConfigurations.($hostname) = nixpkgs.lib.nixosSystem {{
      system = \"x86_64-linux\";
      modules = [
        ./config/nixos/configuration.nix
        home-manager.nixosModules.home-manager
        {{
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.($username) = import ./config/home/home.nix;
        }}
      ];
    }};
  }};
}}"
}

def show_next_steps [config: record] {
    let hostname = $config.basic.hostname

    print $"\n(ansi green_bold)══════════════════════════════════════════════════════════════"
    print $"                    Setup Complete!                    "
    print $"══════════════════════════════════════════════════════════════(ansi reset)\n"

    print $"(ansi yellow_bold)Next Steps:(ansi reset)"
    print $"1. Review the generated configuration files"
    print $"2. Generate hardware configuration:"
    print $"   sudo nixos-generate-config --show-hardware-config > config/hardware/hardware-configuration-actual.nix"
    print $"3. Test the configuration:"
    print $"   nixos-rebuild build --flake .#($hostname)"
    print $"4. Apply the configuration:"
    print $"   sudo nixos-rebuild switch --flake .#($hostname)"
    print $"\n(ansi cyan)For more information, see the documentation at docs/USAGE.md(ansi reset)\n"
}

def main [] {
    # Show banner
    show_banner

    # Run configuration steps
    let platform = (detect_platform)
    let use_case = (select_use_case)
    let features = (select_features)
    let basic = (configure_basic_settings)
    let hardware_config = (configure_hardware)

    # Build configuration object
    let config = {
        platform: $platform
        use_case: $use_case
        features: $features
        basic: $basic
        hardware_config: $hardware_config
        messaging: ($features | any { |f| $f == "messaging" })
        gaming: ($features | any { |f| $f == "gaming" })
        development: ($features | any { |f| $f == "development" })
        monitoring: ($features | any { |f| $f == "monitoring" })
        security: ($features | any { |f| $f == "security" })
        storage: ($features | any { |f| $f == "storage" })
    }

    # Generate configuration
    generate_configuration $config

    # Show next steps
    show_next_steps $config
}

# Run the wizard
main