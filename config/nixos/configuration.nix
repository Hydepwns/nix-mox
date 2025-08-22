{ config, pkgs, lib, ... }:

{
  imports = [
    # Hardware configuration - REQUIRED
    ../hardware/hardware-configuration.nix
    
    # User configuration from personal
    ../personal/hydepwns.nix
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
  # HARDWARE - NVIDIA RTX 4070
  # ============================================================================
  
  # NVIDIA configuration for RTX 4070
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;  # Use closed source drivers
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    forceFullCompositionPipeline = false;
    prime = {
      offload.enable = false;
    };
  };
  
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
    
    # Display manager - SDDM
    displayManager = {
      sddm = {
        enable = true;
        wayland.enable = false;
      };
      
      # Session settings
      defaultSession = "plasma";
      
      # Auto-login configuration - DISABLED for security
      autoLogin = {
        enable = false;
        user = "hydepwns";
      };
    };
    
    # Desktop environment - Plasma for gaming
    desktopManager.plasma5.enable = true;
    
    # X11 configuration
    layout = "us";
    xkbVariant = "";
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
        27015  # Source games
        25565  # Minecraft
        7777   # Terraria
        8080   # Web servers
      ];
      allowedUDPPorts = [
        27015  # Source games
        7777   # Terraria
        5353   # mDNS
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
  # ENVIRONMENT VARIABLES - OPTIMIZED FOR NVIDIA RTX 4070
  # ============================================================================
  
  environment.variables = {
    # Proton/Wine
    WINEDEBUG = "-all";
    WINEESYNC = "1";
    WINEFSYNC = "1";
    WINE_LARGE_ADDRESS_AWARE = "1";
    
    # Proton GE and Anticheat Support
    PROTON_ENABLE_NVAPI = "1";
    PROTON_HIDE_NVIDIA_GPU = "0";
    PROTON_NO_ESYNC = "0";
    PROTON_NO_FSYNC = "0";
    PROTON_EAC_RUNTIME = "1";
    PROTON_BATTLEYE_RUNTIME = "1";
    PROTON_FORCE_LARGE_ADDRESS_AWARE = "1";
    DXVK_HUD = "compiler";
    VKD3D_DEBUG = "none";
    VKD3D_CONFIG = "dxr,dxr11";
    
    # NVIDIA (X11 optimized)
    __GL_THREADED_OPTIMIZATIONS = "1";
    __GL_SHADER_DISK_CACHE_SKIP_CLEANUP = "1";
    __NV_PRIME_RENDER_OFFLOAD = "1";
    __VK_LAYER_NV_optimus = "NVIDIA_only";
    
    # Gaming optimizations
    MANGOHUD = "1";
    GAMEMODE = "1";
    
    # SDL
    SDL_VIDEODRIVER = "x11";
    
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