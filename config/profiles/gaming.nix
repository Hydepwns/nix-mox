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

  # Default display driver; switch to NVIDIA in hosts with RTX
  services.xserver.videoDrivers = lib.mkDefault [ "modesetting" ];

  # NVIDIA (enable on RTX systems)
  # services.xserver.videoDrivers = [ "nvidia" "modesetting" ];
  # hardware.nvidia = {
  #   modesetting.enable = true;
  #   open = false;
  #   nvidiaSettings = true;
  #   package = config.boot.kernelPackages.nvidiaPackages.stable;
  #   prime = {
  #     intelBusId = "PCI:0:2:0";   # 0000:00:02.0 (Intel UHD 770)
  #     nvidiaBusId = "PCI:1:0:0";  # 0000:01:00.0 (RTX 4070)
  #     sync.enable = true;          # or offload.enable = true;
  #   };
  # };

  # When NVIDIA is enabled, prevent conflicts
  boot.blacklistedKernelModules = lib.mkIf (lib.elem "nvidia" config.services.xserver.videoDrivers) [ "nouveau" ];

  # Performance optimizations
  boot.kernelParams = [
    "nvidia-drm.modeset=1"
  ];

  # Gaming environment variables
  environment.variables = {
    # Wine
    WINEDEBUG = "-all";
    WINEPREFIX = "$HOME/.wine";

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
