#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Function to prompt for input with default value
prompt_with_default() {
  local prompt="$1"
  local default="$2"
  local var_name="$3"

  echo -n "$prompt [$default]: "
  read -r input
  if [ -z "$input" ]; then
    eval "$var_name='$default'"
  else
    eval "$var_name='$input'"
  fi
}

# Function to validate input
validate_input() {
  local value="$1"
  local pattern="$2"
  local error_msg="$3"

  if [[ ! $value =~ $pattern ]]; then
    print_error "$error_msg"
    return 1
  fi
  return 0
}

# Main setup function
main() {
  print_status "Setting up Safe NixOS Configuration with nix-mox fragment system"
  echo

  # Get configuration directory
  local config_dir
  prompt_with_default "Enter the directory for your NixOS configuration" "$HOME/nixos-config" config_dir

  # Validate directory
  if [ -d "$config_dir" ]; then
    print_warning "Directory $config_dir already exists"
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      print_status "Setup cancelled"
      exit 0
    fi
  fi

  # Create directory structure
  print_status "Creating configuration directory structure..."
  mkdir -p "$config_dir"/{nixos,home,hardware}
  cd "$config_dir"

  # Get system configuration
  local hostname
  prompt_with_default "Enter your desired hostname" "hydebox" hostname

  local username
  prompt_with_default "Enter your username" "hyde" username

  local timezone
  prompt_with_default "Enter your timezone" "America/New_York" timezone

  # Display manager selection
  echo
  print_status "Choose your display manager:"
  echo "1) LightDM (lightweight, recommended)"
  echo "2) SDDM (KDE's display manager)"
  echo "3) GDM (GNOME's display manager)"
  local display_manager_choice
  prompt_with_default "Enter your choice (1-3)" "1" display_manager_choice

  case $display_manager_choice in
  1) display_manager="lightdm" ;;
  2) display_manager="sddm" ;;
  3) display_manager="gdm" ;;
  *) display_manager="lightdm" ;;
  esac

  # Desktop environment selection
  echo
  print_status "Choose your desktop environment:"
  echo "1) GNOME (full-featured, recommended)"
  echo "2) KDE Plasma (feature-rich)"
  echo "3) XFCE (lightweight)"
  echo "4) i3 (tiling window manager)"
  echo "5) Awesome (tiling window manager)"
  local de_choice
  prompt_with_default "Enter your choice (1-5)" "1" de_choice

  case $de_choice in
  1) desktop_environment="gnome" ;;
  2) desktop_environment="plasma6" ;;
  3) desktop_environment="xfce" ;;
  4) desktop_environment="i3" ;;
  5) desktop_environment="awesome" ;;
  *) desktop_environment="gnome" ;;
  esac

  # Graphics driver selection
  echo
  print_status "Choose your graphics driver:"
  echo "1) Auto-detect (recommended)"
  echo "2) NVIDIA"
  echo "3) AMD"
  echo "4) Intel"
  local gpu_choice
  prompt_with_default "Enter your choice (1-4)" "1" gpu_choice

  case $gpu_choice in
  1) graphics_driver="auto" ;;
  2) graphics_driver="nvidia" ;;
  3) graphics_driver="amdgpu" ;;
  4) graphics_driver="intel" ;;
  *) graphics_driver="auto" ;;
  esac

  # Additional options
  echo
  local enable_steam
  prompt_with_default "Enable Steam for gaming? (y/N)" "y" enable_steam

  local enable_docker
  prompt_with_default "Enable Docker? (y/N)" "y" enable_docker

  local enable_ssh
  prompt_with_default "Enable SSH server? (y/N)" "y" enable_ssh

  # Messaging and communication options
  echo
  print_status "Messaging and Communication Applications:"
  local enable_messaging
  prompt_with_default "Enable messaging applications (Signal, Telegram, Discord, etc.)? (y/N)" "y" enable_messaging

  local enable_video_calling
  prompt_with_default "Enable video calling applications (Zoom, Teams, Skype)? (y/N)" "y" enable_video_calling

  local enable_email_clients
  prompt_with_default "Enable email clients (Thunderbird, Evolution)? (y/N)" "y" enable_email_clients

  # Git configuration
  echo
  local git_name
  prompt_with_default "Enter your Git name" "Your Name" git_name

  local git_email
  prompt_with_default "Enter your Git email" "your.email@example.com" git_email

  # Generate configuration files
  print_status "Generating configuration files..."

  # Generate flake.nix
  cat >flake.nix <<EOF
{
  description = "NixOS configuration using nix-mox fragment system";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix-mox = {
      url = "github:Hydepwns/nix-mox";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, nix-mox, home-manager, ... }@inputs:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
      let
        pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
      in {
        packages = import ./modules/packages { inherit pkgs inputs; };
        devShells = import ./devshells { inherit pkgs; };
        nixosConfigurations = import ./config { inherit inputs; };
      }
    );
}
EOF

  # Generate config/default.nix
  cat >config/default.nix <<EOF
{ inputs, ... }:
let
  userConfig = import ./nixos/configuration.nix;
  userHome = import ./home/home.nix;
  userHardware = import ./hardware/hardware-configuration.nix;
in
{
  $hostname = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      userConfig
      userHardware
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.$username = userHome;
      }
    ];
  };
}
EOF

  # Generate nixos/configuration.nix using fragment system
  cat >nixos/configuration.nix <<EOF
{ config, pkgs, inputs, ... }:

{
  imports = [
    ../../modules/templates/base/common.nix
    ../hardware/hardware-configuration.nix
  ];

  networking.hostName = "$hostname";
  time.timeZone = "$timezone";

  users.users.$username = {
    isNormalUser = true;
    description = "$username";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    shell = pkgs.zsh;
  };
EOF

  # Add display manager override if not lightdm
  if [ "$display_manager" != "lightdm" ]; then
    cat >>nixos/configuration.nix <<EOF

  # Override display manager
  services.xserver.displayManager = {
    lightdm.enable = false;
EOF
    case $display_manager in
    "sddm")
      echo "    sddm.enable = true;" >>nixos/configuration.nix
      ;;
    "gdm")
      echo "    gdm.enable = true;" >>nixos/configuration.nix
      ;;
    esac
    echo "  };" >>nixos/configuration.nix
  fi

  # Add desktop environment override if not gnome
  if [ "$desktop_environment" != "gnome" ]; then
    cat >>nixos/configuration.nix <<EOF

  # Override desktop environment
  services.xserver.desktopManager = {
    gnome.enable = false;
EOF
    case $desktop_environment in
    "plasma6")
      echo "    plasma6.enable = true;" >>nixos/configuration.nix
      ;;
    "xfce")
      echo "    xfce.enable = true;" >>nixos/configuration.nix
      ;;
    esac
    echo "  };" >>nixos/configuration.nix

    # Add window manager if selected
    if [ "$desktop_environment" = "i3" ] || [ "$desktop_environment" = "awesome" ]; then
      cat >>nixos/configuration.nix <<EOF

  # Window manager
  services.xserver.windowManager = {
EOF
      case $desktop_environment in
      "i3")
        echo "    i3.enable = true;" >>nixos/configuration.nix
        ;;
      "awesome")
        echo "    awesome.enable = true;" >>nixos/configuration.nix
        ;;
      esac
      echo "  };" >>nixos/configuration.nix
    fi
  fi

  # Add graphics driver configuration
  if [ "$graphics_driver" != "auto" ]; then
    cat >>nixos/configuration.nix <<EOF

  # Graphics driver
EOF
    case $graphics_driver in
    "nvidia")
      cat >>nixos/configuration.nix <<EOF
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
EOF
      ;;
    "amdgpu")
      echo '  services.xserver.videoDrivers = [ "amdgpu" ];' >>nixos/configuration.nix
      ;;
    "intel")
      echo '  services.xserver.videoDrivers = [ "intel" ];' >>nixos/configuration.nix
      ;;
    esac
  fi

  # Add optional services
  if [[ $enable_steam =~ ^[Yy]$ ]]; then
    cat >>nixos/configuration.nix <<EOF

  # Steam gaming
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };
EOF
  fi

  if [[ $enable_ssh =~ ^[Yy]$ ]]; then
    cat >>nixos/configuration.nix <<EOF

  # SSH server
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };
EOF
  fi

  if [[ $enable_docker =~ ^[Yy]$ ]]; then
    cat >>nixos/configuration.nix <<EOF

  # Docker
  services.docker = {
    enable = true;
    enableOnBoot = true;
  };
EOF
  fi

  # Add messaging and communication configuration
  if [[ $enable_messaging =~ ^[Yy]$ ]] || [[ $enable_video_calling =~ ^[Yy]$ ]] || [[ $enable_email_clients =~ ^[Yy]$ ]]; then
    cat >>nixos/configuration.nix <<EOF

  # Messaging and communication services
  services.dbus.enable = true;
  services.gvfs.enable = true;

  # Configure dbus packages for messaging apps
  services.dbus.packages = with pkgs; [
EOF
    if [[ $enable_messaging =~ ^[Yy]$ ]]; then
      cat >>nixos/configuration.nix <<EOF
    signal-desktop
    telegram-desktop
    discord
    slack
    element-desktop
    whatsapp-for-linux
EOF
    fi
    if [[ $enable_video_calling =~ ^[Yy]$ ]]; then
      cat >>nixos/configuration.nix <<EOF
    zoom-us
    teams
    skypeforlinux
EOF
    fi
    cat >>nixos/configuration.nix <<EOF
  ];

  # Firewall ports for messaging and communication
  networking.firewall.allowedTCPPorts = [
    80 443  # HTTP/HTTPS for web-based messaging
    3478 3479  # STUN/TURN for WebRTC (Signal, Telegram calls)
    5349 5350  # STUN/TURN over TLS
    8080 8081  # Alternative ports for some messaging services
  ];
  networking.firewall.allowedUDPPorts = [
    3478 3479  # STUN/TURN for WebRTC
    5349 5350  # STUN/TURN over TLS
    16384 16387  # WebRTC media ports
  ];
EOF
  fi

  echo "}" >>nixos/configuration.nix

  # Generate home/home.nix
  cat >home/home.nix <<EOF
{ config, pkgs, inputs, ... }:

{
  home.stateVersion = "23.11";
  home.username = "$username";
  home.homeDirectory = "/home/$username";

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ll = "ls -l";
      la = "ls -la";
      nrs = "sudo nixos-rebuild switch --flake .#$hostname";
      nfu = "nix flake update";
      ngc = "nix-collect-garbage -d";
      dev-default = "nix develop \${inputs.nix-mox}#default";
      dev-development = "nix develop \${inputs.nix-mox}#development";
      dev-testing = "nix develop \${inputs.nix-mox}#testing";
      dev-services = "nix develop \${inputs.nix-mox}#services";
      dev-monitoring = "nix develop \${inputs.nix-mox}#monitoring";
      dev-gaming = "nix develop \${inputs.nix-mox}#gaming";
      dev-zfs = "nix develop \${inputs.nix-mox}#zfs";
      nixos-update = "nixos-flake-update";
    };

    initExtra = ''
      export EDITOR=vim
    '';
  };

  programs.git = {
    enable = true;
    userName = "$git_name";
    userEmail = "$git_email";
    extraConfig = {
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
    };
  };

  programs.firefox.enable = true;
  programs.vscode.enable = true;

  # Add messaging configuration to home.nix if enabled
  if [[ $enable_messaging =~ ^[Yy]$ ]] || [[ $enable_video_calling =~ ^[Yy]$ ]] || [[ $enable_email_clients =~ ^[Yy]$ ]]; then
      cat >> home/home.nix << EOF

  # Messaging and communication programs
  programs = {
    # Enable desktop notifications for messaging apps
    dconf.enable = true;

    # Configure file associations for messaging apps
    xdg = {
      enable = true;
      mimeApps = {
        enable = true;
        defaultApplications = {
EOF
  if [[ $enable_messaging =~ ^[Yy]$ ]]; then
    cat >>home/home.nix <<EOF
          "x-scheme-handler/signal" = "signal-desktop.desktop";
          "x-scheme-handler/telegram" = "telegram-desktop.desktop";
          "x-scheme-handler/discord" = "discord.desktop";
          "x-scheme-handler/slack" = "slack.desktop";
EOF
  fi
  cat >>home/home.nix <<EOF
        };
      };
    };
  };

  # Desktop notifications for messaging apps
  services.dunst.enable = true;
}
EOF

  # Generate hardware configuration
  print_status "Generating hardware configuration..."
  if command -v nixos-generate-config >/dev/null 2>&1; then
    sudo nixos-generate-config --show-hardware-config | sudo tee hardware/hardware-configuration.nix >/dev/null
    print_success "Hardware configuration generated"
  else
    print_warning "nixos-generate-config not found. Creating minimal hardware config..."
    cat >hardware/hardware-configuration.nix <<EOF
# Minimal hardware configuration
# Run 'sudo nixos-generate-config --show-hardware-config > hardware/hardware-configuration.nix' on your target system

{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [ ];
  boot.initrd.availableKernelModules = [ "ata_piix" "ohci_pci" "ehci_pci" "ahci" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  swapDevices = [ ];
  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
EOF
  fi

  print_success "Configuration files generated successfully!"
  echo
  print_status "Next steps:"
  echo "1. Review the generated configuration files in $config_dir"
  echo "2. Make any necessary adjustments to match your hardware"
  echo "3. Build and switch to the new configuration:"
  echo "   cd $config_dir"
  echo "   sudo nixos-rebuild switch --flake .#$hostname"
  echo
  print_status "After switching, you can access nix-mox tools:"
  echo "- System packages: proxmox-update, vzdump-backup, zfs-snapshot, nixos-flake-update"
  echo "- Development shells: dev-default, dev-development, dev-testing, dev-services, dev-monitoring, dev-gaming, dev-zfs"
  echo "- Or directly: nix develop github:Hydepwns/nix-mox#default"
  echo
  print_warning "If you encounter display issues, check the troubleshooting section in the README.md file"
}

main "$@"
