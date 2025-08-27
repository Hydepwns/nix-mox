# Display fixes for KDE Plasma 6 + NVIDIA compatibility issues on NixOS 25.11
# This configuration addresses known issues with KDE Plasma 6 and NVIDIA drivers

{ config, pkgs, lib, ... }:

{
  # ============================================================================
  # NVIDIA DRIVER FIXES FOR PLASMA 6
  # ============================================================================

  # Use latest NVIDIA driver for better Plasma 6 compatibility
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false; # Proprietary driver works better with Plasma 6
    nvidiaSettings = true;

    # Use beta driver for better Plasma 6 support
    package = config.boot.kernelPackages.nvidiaPackages.beta;

    # Disable composition pipeline (causes issues with Plasma 6)
    forceFullCompositionPipeline = false;
  };

  # ============================================================================
  # DISPLAY MANAGER CONFIGURATION - CRITICAL FIXES
  # ============================================================================

  services.displayManager = {
    sddm = {
      enable = true;
      # Force X11 - Wayland causes the lock screen issue you're experiencing
      wayland.enable = false;

      # Additional SDDM settings for NVIDIA compatibility
      settings = {
        General = {
          DisplayServer = "x11";
          GreeterEnvironment = "QT_SCREEN_SCALE_FACTORS=1,QT_AUTO_SCREEN_SCALE_FACTOR=0";
        };

        # Fix for NVIDIA + SDDM black screen issues
        X11 = {
          ServerPath = "/run/current-system/sw/bin/X";
          ServerArguments = "-nolisten tcp -dpi 96";
        };
      };
    };

    # Force X11 session - this is critical for your setup
    defaultSession = lib.mkForce "plasmax11";

    # Disable auto-login to prevent session issues
    autoLogin.enable = false;
  };

  # ============================================================================
  # KDE PLASMA 6 SPECIFIC FIXES
  # ============================================================================

  services.desktopManager.plasma6 = {
    enable = true;

    # Enable additional components that help with NVIDIA
    enableQt5Integration = true;
  };

  # ============================================================================
  # X11 CONFIGURATION - NVIDIA SPECIFIC
  # ============================================================================

  services.xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ];

    # X11 configuration for NVIDIA
    xkb = {
      layout = "us";
      variant = "";
    };

    # Additional X11 config for NVIDIA stability
    config = ''
      Section "Device"
        Identifier "nvidia"
        Driver "nvidia"
        VendorName "NVIDIA Corporation"
        Option "NoLogo" "true"
        Option "UseEDID" "false"
        Option "ConnectedMonitor" "DFP"
        Option "CustomEDID" "DFP-0:/etc/X11/edid.bin"
        Option "IgnoreEDIDChecksum" "true"
        Option "UseDisplayDevice" "none"
      EndSection
    '';

    # Screen configuration
    screenSection = ''
      Option         "metamodes" "nvidia-auto-select +0+0 { ForceFullCompositionPipeline = Off }"
      Option         "AllowIndirectGLXProtocol" "off"
      Option         "TripleBuffer" "on"
    '';
  };

  # ============================================================================
  # KERNEL PARAMETERS - UPDATED FOR PLASMA 6 + NVIDIA
  # ============================================================================

  boot.kernelParams = [
    # NVIDIA settings - critical for Plasma 6
    "nvidia-drm.modeset=1"
    "nvidia-drm.fbdev=1"

    # Disable problematic features that conflict with Plasma 6
    "nvidia.NVreg_PreserveVideoMemoryAllocations=0"
    "nvidia.NVreg_UsePageAttributeTable=1"

    # Intel CPU optimizations (your current settings)
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

    # Additional fixes for display stability
    "acpi_backlight=vendor"
    "pci=nommconf"
  ];

  # ============================================================================
  # ENVIRONMENT VARIABLES - PLASMA 6 + NVIDIA FIXES
  # ============================================================================

  environment.variables = {
    # Force X11 session type
    XDG_SESSION_TYPE = "x11";

    # NVIDIA specific for Plasma 6
    __GL_THREADED_OPTIMIZATIONS = "1";
    __GL_SHADER_DISK_CACHE_SKIP_CLEANUP = "1";
    __GL_SYNC_TO_VBLANK = "1";
    __GL_YIELD = "USLEEP";

    # KDE/Qt specific fixes
    QT_XCB_GL_INTEGRATION = "none";
    QT_QUICK_BACKEND = "software";
    KWIN_COMPOSE = "O2"; # Force OpenGL 2.0 for compatibility
    KWIN_DRM_USE_EGL_STREAMS = "1";

    # Disable Wayland for Qt applications
    QT_QPA_PLATFORM = "xcb";
    GDK_BACKEND = "x11";

    # SDL should use X11
    SDL_VIDEODRIVER = "x11";

    # Plasma 6 specific environment fixes
    PLASMA_USE_QT_SCALING = "1";
    QT_AUTO_SCREEN_SCALE_FACTOR = "0";
    QT_SCREEN_SCALE_FACTORS = "1";

    # Gaming optimizations (your current settings)
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

    # Gaming optimizations
    MANGOHUD = "1";
    GAMEMODE = "1";

    # Git configuration
    GIT_EDITOR = "nvim";

    # Development tool aliases
    FZF_DEFAULT_COMMAND = "fd --type f";
    FZF_CTRL_T_COMMAND = "fd --type f";
    FZF_ALT_C_COMMAND = "fd --type d";
  };

  # ============================================================================
  # ADDITIONAL PACKAGES FOR DISPLAY STABILITY
  # ============================================================================

  environment.systemPackages = with pkgs; [
    # Display troubleshooting tools
    xorg.xrandr
    xorg.xdpyinfo
    xorg.xwininfo
    xorg.xprop
    mesa-demos # for glxinfo

    # NVIDIA tools
    nvidia-system-monitor-qt
    nvtopPackages.full

    # KDE debugging tools
    kdePackages.qttools
    kdePackages.qtbase
  ];

  # ============================================================================
  # SYSTEMD SERVICES - DISPLAY RECOVERY
  # ============================================================================

  systemd.services.nvidia-resume = {
    description = "NVIDIA Resume Actions";
    after = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl restart display-manager";
    };
  };

  # Service to fix display after resume
  systemd.services.display-fix = {
    description = "Display Fix Service";
    wantedBy = [ "graphical-session.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "display-fix" ''
        # Wait for display manager to start
        sleep 5
        
        # Ensure NVIDIA modules are loaded
        ${pkgs.kmod}/bin/modprobe nvidia_drm
        ${pkgs.kmod}/bin/modprobe nvidia_uvm
        
        # Fix potential X11 issues
        if [ -z "$DISPLAY" ]; then
          export DISPLAY=:0
        fi
        
        # Restart compositor if needed
        ${pkgs.procps}/bin/pgrep kwin_x11 || {
          export DISPLAY=:0
          ${pkgs.kdePackages.kwin}/bin/kwin_x11 --replace &
        }
      '';
    };
  };

  # ============================================================================
  # SECURITY AND PERMISSIONS
  # ============================================================================

  # Ensure proper permissions for NVIDIA devices
  services.udev.extraRules = ''
    # NVIDIA device permissions
    KERNEL=="nvidia", GROUP="video", MODE="0664"
    KERNEL=="nvidia_uvm", GROUP="video", MODE="0664"
    KERNEL=="nvidia_modeset", GROUP="video", MODE="0664"
    KERNEL=="nvidiactl", GROUP="video", MODE="0664"
  '';

  # Add user to video group for NVIDIA access
  users.users.hydepwns.extraGroups = [ "video" ];
}
