# ============================================================================
# NIXOS CONFIGURATION
# ============================================================================
# Base NixOS configuration shared by all hosts
# ============================================================================

{ config, lib, pkgs, inputs, ... }:

{
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Nix settings
  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "root" "hydepwns" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # System packages
  environment.systemPackages = with pkgs; [
    # Essential tools
    vim
    wget
    curl
    git
    htop
    tree

    # Nix tools
    nix-index
    nix-tree

    # Network tools
    inetutils
    mtr
    iperf3
  ];

  # System settings
  system = {
    stateVersion = "23.11";
    autoUpgrade = {
      enable = false; # Disabled by default, enable per-host
      channel = "https://nixos.org/channels/nixos-unstable";
    };
  };

  # Security settings
  security = {
    sudo.wheelNeedsPassword = true;
    auditd.enable = false; # Enable per-host if needed
  };

  # Networking
  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ]; # SSH only by default
      allowedUDPPorts = [ ];
    };
  };

  # Services
  services = {
    # SSH (basic config, can be overridden per-host)
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        PubkeyAuthentication = true;
      };
    };

    # Timesync
    timesyncd.enable = true;

    # Cron
    cron.enable = true;
  };

  # Users - will be configured in personal config
  users.mutableUsers = true;

  # X11 and Display Manager (basic setup, can be overridden)
  services.xserver = {
    enable = true;
    displayManager.lightdm.enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  # Desktop Manager (updated for Plasma 6)
  services.desktopManager = {
    plasma6.enable = true;
  };

  # Boot
  boot = {
    # Kernel settings
    kernel.sysctl = {
      "kernel.sysrq" = 1;
      "net.ipv4.ip_forward" = 0;
    };

    # Loader (will be overridden by hardware configs)
    loader.grub.enable = false;
    loader.systemd-boot.enable = false;
  };

  # Hardware
  hardware = {
    # Basic hardware support
    enableRedistributableFirmware = true;
  };

  # Internationalization
  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [ "en_US.UTF-8/UTF-8" ];
  };

  # Console
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Time
  time.timeZone = "UTC"; # Will be overridden by hardware configs

  # Documentation
  documentation = {
    nixos.enable = true;
    man.enable = true;
    info.enable = true;
  };

  # Programs
  programs = {
    # Shell
    bash.completion.enable = true;

    # SSH
    ssh.startAgent = false;

    # Less
    less.enable = true;

    # Zsh
    zsh.enable = true;
  };

  # Environment
  environment = {
    # Variables
    variables = {
      EDITOR = "vim";
      PAGER = "less";
    };

    # Shell init
    shellInit = ''
      # Add any global shell initialization here
    '';
  };
}
