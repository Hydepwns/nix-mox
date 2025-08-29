{ config, pkgs, lib, ... }:

{
  imports = [
    # Hardware configuration - REQUIRED
    ../hardware/hardware-configuration.nix

    # User configuration from personal
    ../personal/hydepwns.nix

    # Display fixes for KDE Plasma 6 + NVIDIA on NixOS 25.11
    ./display-fixes.nix

    # Session management module - prevents reboot issues after rebuilds
    ../../modules/session-management.nix
  ];

  # ============================================================================
  # CORE SYSTEM
  # ============================================================================

  system.stateVersion = "24.05";

  # Nix configuration
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      trusted-users = [ "root" "@wheel" ];
    };
  };

  # Allow unfree packages (required for Steam, NVIDIA drivers)
  nixpkgs.config.allowUnfree = true;

  # ============================================================================
  # SESSION MANAGEMENT - PREVENT REBOOT ISSUES AFTER REBUILDS
  # ============================================================================

  # Enable session management with safety features
  services.sessionManagement = {
    enable = true;
    ensureRebootCapability = true;
    preventServiceRestartIssues = true;
  };

  # ============================================================================
  # BOOT & KERNEL - OPTIMIZED FOR INTEL i7-13700K + NVIDIA RTX 4070
  # ============================================================================

  boot = {
    # Use latest kernel for best gaming performance
    kernelPackages = pkgs.linuxPackages_zen;

    # Kernel parameters optimized for Intel i7-13700K + NVIDIA RTX 4070
    kernelParams = [
      # NVIDIA settings
      "nvidia-drm.modeset=1"

      # Intel CPU optimizations
      "intel_idle.max_cstate=1"
      "intel_pstate=performance"
      "intel_iommu=on"

      # Performance optimizations
      "mitigations=off"
      "nowatchdog"
      "quiet"
      "splash"

      # Memory management
      "transparent_hugepage=always"
      "vm.swappiness=10"

      # Power management for Intel
      "processor.max_cstate=1"
      "idle=poll"

      # Intel specific performance
      "tsc=reliable"
      "clocksource=tsc"
    ];

    # Blacklist conflicting drivers
    blacklistedKernelModules = [ "nouveau" ];

    # Kernel modules to load
    kernelModules = [ "kvm-intel" "nvidia" "nvidia-drm" "nvidia-uvm" ];
  };

  # ============================================================================
  # HARDWARE - NVIDIA RTX 4070 (configured in display-fixes.nix)
  # ============================================================================

  hardware = {
    # Enable all firmware
    enableAllFirmware = true;
    enableRedistributableFirmware = true;

    # Graphics configuration
    graphics = {
      enable = true;
      enable32Bit = true;
    };

    # Controller support
    xone.enable = true;
    xpadneo.enable = true;
  };

  # ============================================================================
  # DISPLAY & DESKTOP - X11 for NVIDIA RTX 4070
  # ============================================================================

  # X11 configuration for better NVIDIA compatibility
  services.xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ];

    # X11 configuration
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  # Desktop environment - Using Plasma 6 (modern KDE)
  services.desktopManager.plasma6.enable = true;

  # Display manager configuration
  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = false; # Use X11 for NVIDIA compatibility
    };

    defaultSession = "plasmax11";

    # Auto-login configuration - DISABLED for security
    autoLogin = {
      enable = false;
      user = "hydepwns";
    };
  };

  # Enable XDG portal
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    wlr.enable = false;
  };

  # ============================================================================
  # AUDIO
  # ============================================================================

  # PipeWire for low-latency audio
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
    jack.enable = true;
  };

  # ============================================================================
  # NETWORKING
  # ============================================================================

  networking = {
    networkmanager.enable = true;

    # Firewall with gaming ports
    firewall = {
      enable = true;
      allowedTCPPorts = [
        27015 # Source games
        25565 # Minecraft
        7777 # Terraria
        8080 # Web servers
      ];
      allowedUDPPorts = [
        27015 # Source games
        7777 # Terraria
        5353 # mDNS
      ];
    };

    # Use CloudFlare DNS for gaming
    nameservers = [ "1.1.1.1" "1.0.0.1" ];
  };

  # ============================================================================
  # GAMING
  # ============================================================================

  # Enable Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  # ============================================================================
  # USERS
  # ============================================================================

  # Enable Zsh
  programs.zsh.enable = true;

  # Additional shell improvements
  programs.bash.completion.enable = true;
  programs.zsh.enableCompletion = true;
  programs.zsh.autosuggestions.enable = true;
  programs.zsh.syntaxHighlighting.enable = true;

  # ============================================================================
  # PACKAGES
  # ============================================================================

  environment.systemPackages = with pkgs; [
    # Core system utilities
    git
    neovim
    pciutils

    # Terminal emulators
    kitty
    alacritty

    # Browsers
    firefox

    # File management
    xfce.thunar
    pcmanfm

    # Archive tools
    unzip
    unrar
    p7zip
    zip
    gzip
    xz
    zstd

    # Media players
    vlc
    mpv

    # Communication
    discord

    # Audio tools
    pavucontrol
    helvum

    # Gaming packages
    vulkan-tools
    mangohud
    gamemode
    gamescope

    # Performance monitoring
    btop

    # Development tools
    nodejs_20
    ripgrep
    fd
    bat
    eza
    fzf
    jq
    tree
  ];

  # ============================================================================
  # POWER MANAGEMENT - OPTIMIZED FOR INTEL i7-13700K
  # ============================================================================

  powerManagement = {
    enable = true;
    cpuFreqGovernor = "performance";
    scsiLinkPolicy = "max_performance";
  };

  # ============================================================================
  # ENVIRONMENT VARIABLES (gaming/NVIDIA vars in display-fixes.nix)
  # ============================================================================

  environment.variables = {
    # Git configuration
    GIT_EDITOR = "nvim";

    # Development tool aliases
    FZF_DEFAULT_COMMAND = "fd --type f";
    FZF_CTRL_T_COMMAND = "fd --type f";
    FZF_ALT_C_COMMAND = "fd --type d";
  };


  # ============================================================================
  # LOCALE CONFIGURATION
  # ============================================================================

  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "es_ES.UTF-8/UTF-8"
      "C.UTF-8/UTF-8"
    ];
    extraLocaleSettings = {
      LC_ADDRESS = "es_ES.UTF-8";
      LC_IDENTIFICATION = "es_ES.UTF-8";
      LC_MEASUREMENT = "es_ES.UTF-8";
      LC_MONETARY = "es_ES.UTF-8";
      LC_NAME = "es_ES.UTF-8";
      LC_NUMERIC = "es_ES.UTF-8";
      LC_PAPER = "es_ES.UTF-8";
      LC_TELEPHONE = "es_ES.UTF-8";
      LC_TIME = "es_ES.UTF-8";
    };
  };
}
