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

    if [[ ! "$value" =~ $pattern ]]; then
        print_error "$error_msg"
        return 1
    fi
    return 0
}

# Main setup function
main() {
    print_status "Setting up Safe NixOS Configuration with nix-mox integration"
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

    # Create directory
    print_status "Creating configuration directory..."
    mkdir -p "$config_dir"
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
        2) desktop_environment="plasma5" ;;
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

    # Git configuration
    echo
    local git_name
    prompt_with_default "Enter your Git name" "Your Name" git_name

    local git_email
    prompt_with_default "Enter your Git email" "your.email@example.com" git_email

    # Generate configuration files
    print_status "Generating configuration files..."

    # Generate flake.nix
    cat > flake.nix << EOF
{
  description = "Default NixOS configuration using nix-mox tools";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Import repository
    nix-mox = {
      url = "github:Hydepwns/nix-mox";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Optional: home-manager for user configuration
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix-mox, home-manager, ... }@inputs: {
    nixosConfigurations = {
      # Replace "hydebox" with your desired hostname
      $hostname = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        # Pass inputs to modules
        specialArgs = { inherit inputs; };

        modules = [
          ./configuration.nix
          ./hardware-configuration.nix

          # Optional: Include home-manager
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.$username = import ./home.nix;
          }
        ];
      };
    };
  };
}
EOF

    # Generate configuration.nix with proper display settings
    cat > configuration.nix << EOF
{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Boot loader
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    timeout = 3;
  };

  # Kernel (optional: use latest)
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Networking
  networking = {
    hostName = "$hostname";
    networkmanager.enable = true;

    # Optional: enable firewall
    firewall = {
      enable = true;
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
    };
  };

  # Time zone and locale
  time.timeZone = "$timezone";
  i18n.defaultLocale = "en_US.UTF-8";

  # IMPORTANT: Display configuration to prevent CLI lock
  services.xserver = {
    enable = true;

    # Display manager
    displayManager = {
EOF

    # Add display manager configuration
    case $display_manager in
        "lightdm")
            echo "      lightdm.enable = true;" >> configuration.nix
            ;;
        "sddm")
            echo "      sddm.enable = true;" >> configuration.nix
            ;;
        "gdm")
            echo "      gdm.enable = true;" >> configuration.nix
            ;;
    esac

    cat >> configuration.nix << EOF
    };

    # Desktop environment
EOF

    # Add desktop environment configuration
    case $desktop_environment in
        "gnome")
            echo "    desktopManager.gnome.enable = true;" >> configuration.nix
            ;;
        "plasma5")
            echo "    desktopManager.plasma5.enable = true;" >> configuration.nix
            ;;
        "xfce")
            echo "    desktopManager.xfce.enable = true;" >> configuration.nix
            ;;
        "i3")
            echo "    windowManager.i3.enable = true;" >> configuration.nix
            ;;
        "awesome")
            echo "    windowManager.awesome.enable = true;" >> configuration.nix
            ;;
    esac

    cat >> configuration.nix << EOF
  };

  # Enable sound
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Graphics drivers
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

EOF

    # Add graphics driver configuration
    case $graphics_driver in
        "nvidia")
            cat >> configuration.nix << EOF
  # NVIDIA drivers
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
            cat >> configuration.nix << EOF
  # AMD drivers
  services.xserver.videoDrivers = [ "amdgpu" ];

EOF
            ;;
        "intel")
            cat >> configuration.nix << EOF
  # Intel drivers
  services.xserver.videoDrivers = [ "intel" ];

EOF
            ;;
        *)
            # Auto-detect, no specific driver configuration
            ;;
    esac

    cat >> configuration.nix << EOF
  # Users
  users.users.$username = {
    isNormalUser = true;
    description = "$username";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    shell = pkgs.zsh;
  };

  # Enable sudo
  security.sudo.enable = true;

  # System packages
  environment.systemPackages = with pkgs; [
    # Essential tools
    vim
    wget
    git
    htop
    firefox

    # Terminal emulators
    kitty
    alacritty

    # From nix-mox (access the packages)
    inputs.nix-mox.packages.\${pkgs.system}.proxmox-update
    inputs.nix-mox.packages.\${pkgs.system}.vzdump-backup
    inputs.nix-mox.packages.\${pkgs.system}.zfs-snapshot
    inputs.nix-mox.packages.\${pkgs.system}.nixos-flake-update

    # Development tools
    vscode
    docker
    docker-compose
  ];

  # Programs
  programs = {
    zsh.enable = true;
    git.enable = true;
EOF

    # Add Steam configuration if enabled
    if [[ $enable_steam =~ ^[Yy]$ ]]; then
        cat >> configuration.nix << EOF

    # Steam for gaming (since nix-mox has gaming focus)
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };
EOF
    fi

    cat >> configuration.nix << EOF
  };

  # Services
  services = {
EOF

    # Add SSH configuration if enabled
    if [[ $enable_ssh =~ ^[Yy]$ ]]; then
        cat >> configuration.nix << EOF
    # SSH
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };
EOF
    fi

    # Add Docker configuration if enabled
    if [[ $enable_docker =~ ^[Yy]$ ]]; then
        cat >> configuration.nix << EOF

    # Docker
    docker = {
      enable = true;
      enableOnBoot = true;
    };
EOF
    fi

    cat >> configuration.nix << EOF
  };

  # Nix configuration
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;

      # Use nix-mox's binary caches
      substituters = [
        "https://cache.nixos.org"
        "https://hydepwns.cachix.org"
        "https://nix-mox.cachix.org"
      ];

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "hydepwns.cachix.org-1:xg8huKdwzBkLdkq5eCKenadhCROHIICGI9H6y3simJU="
        "nix-mox.cachix.org-1:MVJZxC7ZyRFAxVsxDuq0nmMRxlTIt5nFFm4Ur10ZCI4="
      ];
    };

    # Garbage collection
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # were taken. Don't change this unless you know what you're doing.
  system.stateVersion = "23.11";
}
EOF

    # Generate home.nix
    cat > home.nix << EOF
{ config, pkgs, inputs, ... }:

{
  home.stateVersion = "23.11";
  home.username = "$username";
  home.homeDirectory = "/home/$username";

  # Shell configuration
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ll = "ls -l";
      la = "ls -la";

      # Nix aliases
      nrs = "sudo nixos-rebuild switch --flake .#$hostname";
      nfu = "nix flake update";
      ngc = "nix-collect-garbage -d";

      # Quick access to nix-mox dev shells
      dev-default = "nix develop \${inputs.nix-mox}#default";
      dev-development = "nix develop \${inputs.nix-mox}#development";
      dev-testing = "nix develop \${inputs.nix-mox}#testing";
      dev-services = "nix develop \${inputs.nix-mox}#services";
      dev-monitoring = "nix develop \${inputs.nix-mox}#monitoring";
      dev-gaming = "nix develop \${inputs.nix-mox}#gaming";
      dev-zfs = "nix develop \${inputs.nix-mox}#zfs";

      # nix-mox package commands
      nixos-update = "nixos-flake-update";
    };

    initExtra = ''
      # Any additional shell configuration
      export EDITOR=vim
    '';
  };

  # Git configuration
  programs.git = {
    enable = true;
    userName = "$git_name";
    userEmail = "$git_email";
    extraConfig = {
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
    };
  };

  # Other programs
  programs.firefox.enable = true;
  programs.vscode.enable = true;
}
EOF

    # Generate hardware configuration
    print_status "Generating hardware configuration..."
    if command -v nixos-generate-config >/dev/null 2>&1; then
        sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix
        print_success "Hardware configuration generated"
    else
        print_warning "nixos-generate-config not found. Please run this script on a NixOS system or manually create hardware-configuration.nix"
        cat > hardware-configuration.nix << EOF
# This file was not automatically generated.
# Please run 'sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix'
# on your target NixOS system to generate the proper hardware configuration.

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ ];

  # Add your hardware-specific configuration here
  # This is a minimal example - replace with your actual hardware config

  boot.initrd.availableKernelModules = [ "ata_piix" "ohci_pci" "ehci_pci" "ahci" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-label/boot";
      fsType = "vfat";
    };

  swapDevices = [ ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with networking.interfaces.<interface>.useDHCP = true.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.ens33.useDHCP = lib.mkDefault true;

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
