# Gaming Profile
# Gaming support and performance optimizations shared across gaming templates
{ config, pkgs, lib, ... }:
{
  # Gaming packages
  environment.systemPackages = with pkgs; [
    # Gaming platforms
    steam
    lutris
    #heroic
    itch
    # gog-galaxy

    # Gaming tools
    gamemode
    mangohud
    goverlay
    vkbasalt
    dxvk
    vkd3d

    # Performance monitoring
    # htop
    # nvtop # GPU monitoring - may not be available on all systems
    radeontop
    mesa-demos

    # Media players
    vlc
    mpv
    spotify

    # Voice chat
    discord
    teamspeak_client  # TeamSpeak voice chat client
    mumble

    # Game launchers
    steam-run
    wine
    winetricks

    # Emulation
    retroarch
    dolphin-emu
    pcsx2
    rpcs3
  ];

  # Gaming programs
  programs = {
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };
  };

  # Gaming services
  services = {
    # Gaming support
    gaming = {
      enable = true;
      gpu.type = "auto";
      performance.enable = true;
      audio.enable = true;
      audio.pipewire = true;
      platforms.steam = true;
      platforms.lutris = true;
      platforms.heroic = true;
    };
  };

  # Audio configuration for gaming
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = lib.mkDefault true;
  };

  # Graphics configuration
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # NVIDIA drivers (uncomment if you have NVIDIA GPU)
  # services.xserver.videoDrivers = [ "nvidia" ];
  # hardware.nvidia = {
  #   modesetting.enable = true;
  #   powerManagement.enable = true;
  #   open = false;
  #   nvidiaSettings = true;
  #   package = config.boot.kernelPackages.nvidiaPackages.stable;
  # };

  # AMD drivers (uncomment if you have AMD GPU)
  # services.xserver.videoDrivers = [ "amdgpu" ];

  # Performance optimizations
  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "amdgpu.si_support=1"
    "amdgpu.cik_support=1"
    "radeon.si_support=0"
    "radeon.cik_support=0"
    "i915.enable_rc6=1"
    "i915.enable_fbc=1"
    "i915.lvds_downclock=1"
  ];

  # Gaming environment variables
  environment.variables = {
    # Vulkan
    VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json:/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json";

    # Wine
    WINEDEBUG = "-all";
    WINEPREFIX = "$HOME/.wine";

    # Performance
    __GL_SYNC_TO_VBLANK = "0";
    __GL_THREADED_OPTIMIZATIONS = "1";
    __GL_YIELD = "NOTHING";

    # Steam
    STEAM_RUNTIME = "1";
    STEAM_FORCE_DESKTOPUI_SCALING = "1";

    # GameMode
    LD_PRELOAD = "libgamemode.so.0";
  };

  # Gaming shell configuration
  programs.zsh.interactiveShellInit = ''
    # Gaming aliases
    alias steam="steam -silent"
    alias lutris="lutris --no-browser"
    alias heroic="heroic --no-sandbox"

    # Performance monitoring
    alias gpu="nvidia-smi || radeontop || intel_gpu_top"
    alias fps="mangohud"

    # Wine shortcuts
    alias wine32="WINEARCH=win32 WINEPREFIX=~/.wine32 wine"
    alias wine64="WINEARCH=win64 WINEPREFIX=~/.wine64 wine"
  '';

  # Gaming file associations
  xdg.mime.defaultApplications = {
    "application/x-ms-dos-executable" = "wine.desktop";
    "application/x-msi" = "wine.desktop";
    "application/vnd.ms-cab-compressed" = "wine.desktop";
  };
}
