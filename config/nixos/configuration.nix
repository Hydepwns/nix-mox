{ config, pkgs, lib, ... }:

{
  imports = [
    # Hardware configuration - REQUIRED
    # Generate with: nixos-generate-config --show-hardware-config
    ../hardware/hardware-configuration.nix
    
    # Hardware auto-detection
    ../../modules/hardware/auto-detect.nix
    
    # Storage module not needed - single SSD setup
    # ../../modules/storage/gaming-drives.nix
    
    # Secrets management (disabled for initial setup)
    # ../../modules/security/secrets.nix
    
    # Backup and recovery
    ../../modules/backup/restic.nix
    ../../modules/recovery/auto-rollback.nix
    
    # User configuration from personal
    ../personal/hydepwns.nix
    
    # Gaming is now handled by the subflake in flake.nix
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
      
      # Parallel building
      max-jobs = lib.mkDefault 8;
      cores = lib.mkDefault 4;
      
      # Trusted users for development
      trusted-users = [ "root" "@wheel" ];
    };
    
    # Garbage collection
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };
  
  # Allow unfree packages (required for Steam, NVIDIA drivers)
  nixpkgs.config.allowUnfree = true;

  # ============================================================================
  # QUICK WINS - IMMEDIATE IMPROVEMENTS
  # ============================================================================
  
  # Limit boot generations to prevent menu overflow
  boot.loader.systemd-boot.configurationLimit = 10;
  
  # Enable auto-rollback for safety
  boot.autoRollback = {
    enable = true;
    maxAttempts = 3;
    timeout = 300;  # 5 minutes
    displayManagerCheck = true;
    networkCheck = true;
  };
  
  # Enable earlyoom to prevent system freezes
  services.earlyoom = {
    enable = true;
    enableNotifications = true;
    freeMemThreshold = 5;
    freeSwapThreshold = 10;
    extraArgs = [
      "-g" # Kill entire process group
      "--avoid" "^(X|plasma|sddm|pipewire|wireplumber)$" # Don't kill display/audio
      "--prefer" "^(chrome|firefox|electron)$" # Prefer killing browsers first
    ];
  };
  
  # Enable zram for better memory management
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
    priority = 100;
  };
  
  # Optimize SSD performance
  services.fstrim = {
    enable = true;
    interval = "weekly";
  };

  # ============================================================================
  # BOOT & KERNEL - OPTIMIZED FOR INTEL i7-13700K
  # ============================================================================
  
  boot = {
    # Use latest kernel for best gaming performance
    kernelPackages = pkgs.linuxPackages_zen;
    
    # Kernel parameters optimized for Intel i7-13700K gaming
    kernelParams = [
      # NVIDIA settings
      "nvidia-drm.modeset=1"
      
      # Intel CPU optimizations
      "intel_idle.max_cstate=1"    # Limit Intel CPU C-states for performance
      "intel_pstate=performance"   # Force Intel P-state to performance mode
      "intel_iommu=on"             # Enable Intel IOMMU for better virtualization
      "i915.enable_guc=3"          # Enable Intel GPU firmware (if using iGPU)
      "i915.enable_fbc=1"          # Enable frame buffer compression
      "i915.fastboot=1"            # Fast boot for Intel graphics
      
      # Performance optimizations
      "mitigations=off"            # Disable CPU mitigations for performance
      "nowatchdog"                 # Disable watchdog
      "quiet"                      # Reduce boot messages
      "splash"                     # Enable splash screen
      
      # Memory management
      "transparent_hugepage=always"
      "vm.swappiness=10"
      
      # Power management for Intel
      "processor.max_cstate=1"     # Limit CPU C-states
      "idle=poll"                  # Polling idle for minimal latency
      
      # Intel specific performance
      "tsc=reliable"               # Trust TSC for Intel CPUs
      "clocksource=tsc"            # Use TSC as clocksource
    ];
    
    # Blacklist conflicting drivers
    blacklistedKernelModules = [ "nouveau" ];
    
    # Kernel modules to load
    kernelModules = [ "kvm-intel" "kvm-amd" "v4l2loopback" ];
    
    # Sysctl settings optimized for Intel i7-13700K
    kernel.sysctl = {
      # Network optimizations
      "net.core.rmem_max" = 134217728;
      "net.core.wmem_max" = 134217728;
      "net.ipv4.tcp_rmem" = "4096 87380 134217728";
      "net.ipv4.tcp_wmem" = "4096 65536 134217728";
      "net.ipv4.tcp_congestion_control" = "bbr";
      "net.ipv4.tcp_fastopen" = 3;
      
      # Memory management optimized for Intel
      "vm.swappiness" = 10;
      "vm.vfs_cache_pressure" = 50;
      "vm.dirty_background_ratio" = 1;
      "vm.dirty_ratio" = 3;
      "vm.nr_hugepages" = 1024;  # Enable huge pages for Intel
      
      # File handles
      "fs.file-max" = 2097152;
      "fs.inotify.max_user_watches" = 524288;
      
      # Intel CPU specific optimizations
      "dev.cpu.dma_latency" = 0;  # Reduce DMA latency
      "kernel.sched_rt_runtime_us" = -1;  # Allow real-time scheduling
      "kernel.sched_rt_period_us" = 1000000;
    };
  };

  # ============================================================================
  # HARDWARE
  # ============================================================================
  
  # Enable hardware auto-detection
  hardware.autoDetect = {
    enable = true;
    gpu.autoConfig = true;
    cpu.autoConfig = true;
    memory.autoConfig = true;
    storage.autoConfig = true;
  };
  
  # NVIDIA configuration
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;  # Use closed source drivers
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    forceFullCompositionPipeline = false;  # Disable this to prevent black screen
    # Add more conservative settings
    prime = {
      offload.enable = false;  # Disable prime offload for now
    };
  };
  
  hardware = {
    # Enable all firmware
    enableAllFirmware = true;
    enableRedistributableFirmware = true;
    
    # Graphics configuration (base, auto-detect adds vendor-specific)
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    
    # Controller support
    xone.enable = true;     # Xbox One controllers
    xpadneo.enable = true;  # Xbox controllers via Bluetooth
  };

  # ============================================================================
  # DISPLAY & DESKTOP
  # ============================================================================
  
  services.xserver = {
    enable = true;
    
    # Video drivers - be more conservative
    videoDrivers = [ "nvidia" ];
    
    # Keyboard and mouse
    xkb = {
      layout = "us";
      variant = "";
    };
    
    # High DPI settings
    dpi = 96;
    
    # Add screen configuration to prevent black screen
    screenSection = ''
      Option "RegistryDwords" "EnableBrightnessControl=1"
    '';
    
    # Add device configuration
    deviceSection = ''
      Option "TripleBuffer" "true"
      Option "AllowIndirectGLXProtocol" "off"
      Option "TripleBuffer" "true"
    '';
  };

  # Display manager configuration (updated for newer NixOS)
  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = false;  # Disable Wayland for now to prevent conflicts
      theme = "breeze";
    };
    
    # Session settings
    defaultSession = "plasma";
    
    # Auto-login configuration - DISABLED for security
    autoLogin = {
      enable = false;
      user = "nixos";
    };
  };
  
  # Desktop environment - use Plasma6 (latest stable)
  services.desktopManager.plasma6.enable = true;

  # ============================================================================
  # AUDIO
  # ============================================================================
  
  # Enable sound
  services.pulseaudio.enable = false;  # We use PipeWire instead
  
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
    
    # Low-latency configuration
    extraConfig.pipewire = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.quantum" = 512;
        "default.clock.min-quantum" = 32;
        "default.clock.max-quantum" = 2048;
      };
    };
    
    wireplumber = {
      enable = true;
      package = pkgs.wireplumber;
    };
  };

  # ============================================================================
  # NETWORKING
  # ============================================================================
  
  networking = {
    hostName = "nixos-gaming";
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
        25565  # Minecraft
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
  
  # Enable the gaming module with desired features
  services.gaming = {
    enable = true;
    
    platforms = {
      steam = true;
      lutris = true;
      heroic = true;
      bottles = false;
      itch = false;
    };
    
    performance = {
      enable = true;
      cpuGovernor = "performance";
      gameMode = true;
      niceness = -10;
    };
    
    graphics = {
      mangohud = true;
      vkbasalt = false;
      gamescope = true;
      shaderCache = {
        enable = true;
        maxSize = "10G";
      };
    };
    
    audio = {
      lowLatency = true;
      sampleRate = 48000;
      quantum = 512;
    };
    
    networking = {
      optimize = true;
      tcpCongestion = "bbr";
      openPorts = true;
    };
  };
  
  # ============================================================================
  # NOTE: Storage configuration not needed for single SSD setup
  # ============================================================================
  # The exec mount option issue only affects secondary drives.
  # Your root filesystem (/) already has exec enabled by default,
  # so Steam games installed in your home directory will work fine
  # with EasyAntiCheat and other anticheats.

  # ============================================================================
  # USERS
  # ============================================================================
  
  # Users are configured via ../personal/hydepwns.nix import above
  
  # Enable Zsh for the hydepwns user
  programs.zsh.enable = true;

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
    pkgs.kdePackages.dolphin
    pkgs.kdePackages.ark
    
    # Media players
    vlc
    mpv
    spotify
    
    # Communication
    discord
    vesktop  # Better Discord for Linux
    
    # Audio tools
    pavucontrol
    helvum
    easyeffects
    
    # Gaming packages are now provided by the gaming module
    
    # Graphics tools
    vulkan-tools
    glxinfo
    
    # Performance monitoring
    htop
    btop
  ];
  
  # Font packages - Monaspace collection for modern development and gaming
  fonts.packages = with pkgs; [
    # Monaspace font collection (GitHub's modern coding font)
    monaspace
    
    # Fallback fonts for compatibility
    liberation_ttf
    corefonts
    noto-fonts-emoji
    
    # Additional coding fonts
    jetbrains-mono
  ];
  
  # Font configuration for better rendering
  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      monospace = [ "Monaspace Neon" "Monaspace Argon" "Monaspace Xenon" "JetBrains Mono" ];
      sansSerif = [ "Monaspace Neon" "Monaspace Argon" "Monaspace Xenon" "Liberation Sans" ];
      serif = [ "Liberation Serif" ];
    };
    localConf = ''
      <!-- Monaspace font configuration -->
      <match target="font">
        <test name="family" compare="contains">
          <string>Monaspace</string>
        </test>
        <edit name="hinting" mode="assign">
          <bool>true</bool>
        </edit>
        <edit name="hintstyle" mode="assign">
          <const>hintslight</const>
        </edit>
        <edit name="antialias" mode="assign">
          <bool>true</bool>
        </edit>
        <edit name="rgba" mode="assign">
          <const>rgb</const>
        </edit>
      </match>
    '';
  };

  # ============================================================================
  # POWER MANAGEMENT - OPTIMIZED FOR INTEL i7-13700K
  # ============================================================================
  
  powerManagement = {
    enable = true;
    cpuFreqGovernor = "performance";  # Always maximum performance for Intel
    scsiLinkPolicy = "max_performance";  # Maximum SCSI performance
  };
  
  # Intel CPU specific power management
  services.thermald = {
    enable = true;  # Enable Intel thermal daemon for proper thermal management
    configFile = pkgs.writeText "thermal-conf.xml" ''
      <?xml version="1.0"?>
      <ThermalConfiguration>
        <Platform>
          <Name>Intel i7-13700K</Name>
          <ProductName>*</ProductName>
          <Preference>QUIET</Preference>
          <ThermalZones>
            <ThermalZone>
              <Type>cpu</Type>
              <TripPoints>
                <TripPoint>
                  <SensorType>x86_pkg_temp</SensorType>
                  <Temperature>85000</Temperature>
                  <type>passive</type>
                  <ControlType>SEQUENTIAL</ControlType>
                </TripPoint>
              </TripPoints>
            </ThermalZone>
          </ThermalZones>
        </Platform>
      </ThermalConfiguration>
    '';
  };
  
  # Disable conflicting power management services
  services.tlp.enable = false;
  services.auto-cpufreq.enable = false;

  # ============================================================================
  # SECURITY
  # ============================================================================
  
  # Secrets management disabled for initial setup
  
  security = {
    # Allow real-time priority for games
    pam.loginLimits = [
      {
        domain = "@users";
        type = "soft";
        item = "memlock";
        value = "unlimited";
      }
      {
        domain = "@users";
        type = "hard";
        item = "memlock";
        value = "unlimited";
      }
      {
        domain = "@users";
        type = "-";
        item = "nice";
        value = "-20";
      }
      {
        domain = "@users";
        type = "-";
        item = "rtprio";
        value = "99";
      }
    ];
    
    # Polkit rules for gamemode
    polkit.enable = true;
  };

  # ============================================================================
  # BACKUP & RECOVERY
  # ============================================================================
  
  # Automated backup configuration (disabled for now)
  services.backup = {
    enable = false;  # Disabled until backup password is configured
    repository = "/var/backup/restic";
    passwordFile = "/etc/nixos/secrets/backup-password";
    
    paths = [
      "/home"
      "/etc/nixos"
      "/var/lib"
    ];
    
    exclude = [
      "/home/*/.cache"
      "/home/*/.steam/steamapps"
      "/home/*/Downloads"
      "*.tmp"
      "node_modules"
    ];
    
    schedule = "daily";
    
    prune = {
      enable = true;
      keepDaily = 7;
      keepWeekly = 4;
      keepMonthly = 6;
      keepYearly = 2;
    };
    
    check = {
      enable = true;
      schedule = "weekly";
    };
  };
  
  # ============================================================================
  # ENVIRONMENT VARIABLES - OPTIMIZED FOR INTEL i7-13700K
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
    PROTON_EAC_RUNTIME = "1";      # Enable EasyAntiCheat runtime
    PROTON_BATTLEYE_RUNTIME = "1";  # Enable BattlEye runtime
    PROTON_FORCE_LARGE_ADDRESS_AWARE = "1";
    DXVK_HUD = "compiler";
    VKD3D_DEBUG = "none";
    VKD3D_CONFIG = "dxr,dxr11";
    
    # NVIDIA
    __GL_THREADED_OPTIMIZATIONS = "1";
    __GL_SHADER_DISK_CACHE_SKIP_CLEANUP = "1";
    __NV_PRIME_RENDER_OFFLOAD = "1";
    __VK_LAYER_NV_optimus = "NVIDIA_only";
    VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.x86_64.json";
    
    # Intel CPU optimizations
    INTEL_DEVICE_PLUGIN_XE = "1";  # Enable Intel Xe graphics support
    INTEL_OPENCL_ICD = "1";        # Enable Intel OpenCL
    INTEL_VAAPI_DRIVER = "i965";   # Intel VAAPI driver
    LIBVA_DRIVER_NAME = "iHD";     # Intel media driver
    
    # Gaming optimizations for Intel
    MANGOHUD = "1";
    ENABLE_VKBASALT = "1";
    GAMEMODE = "1";                # Enable Feral GameMode
    
    # SDL
    SDL_VIDEODRIVER = "wayland,x11";
    
    # Intel specific performance
    INTEL_PREFER_SSE4_1 = "1";     # Prefer SSE4.1 for Intel
  };
}