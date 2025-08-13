# Gaming Template Configuration
# Gaming-focused configuration with performance optimizations
{ config, pkgs, lib, ... }:
{
  imports = [
    ../profiles/base.nix
    ../profiles/security.nix
    ../profiles/gaming.nix
    ./gaming/default.nix
  ];

  # Enable flakes CLI globally
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Locale configuration
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.supportedLocales = [
    "en_US.UTF-8/UTF-8"
    "es_ES.UTF-8/UTF-8"
  ];
  i18n.extraLocaleSettings = {
    LC_TIME = lib.mkForce "es_ES.UTF-8";
    LC_NUMERIC = lib.mkForce "es_ES.UTF-8";
    LC_MONETARY = lib.mkForce "es_ES.UTF-8";
    LC_ADDRESS = lib.mkForce "es_ES.UTF-8";
    LC_IDENTIFICATION = lib.mkForce "es_ES.UTF-8";
    LC_MEASUREMENT = lib.mkForce "es_ES.UTF-8";
    LC_PAPER = lib.mkForce "es_ES.UTF-8";
    LC_TELEPHONE = lib.mkForce "es_ES.UTF-8";
    LC_NAME = lib.mkForce "es_ES.UTF-8";
  };

  # Gaming-specific configuration
  environment.systemPackages = with pkgs; [
    # Gaming platforms
    steam
    lutris
    heroic

    # Gaming tools
    gamemode
    mangohud
    goverlay

    # Performance monitoring
    htop
    btop
    # nvtop  # GPU monitoring - not available in current nixpkgs
    radeontop

    # Media players
    vlc
    mpv

    # Voice chat
    discord
    teamspeak_client

    # Terminal emulator
    kitty
  ];

  # Gaming programs
  programs = {
    zsh.enable = true;
    git.enable = true;

    # Steam configuration
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

  # Default to modesetting; enable NVIDIA on RTX hosts
  services.xserver.videoDrivers = lib.mkDefault [ "modesetting" ];

  # When NVIDIA is enabled, avoid nouveau conflicts
  boot.blacklistedKernelModules = lib.mkIf (lib.elem "nvidia" config.services.xserver.videoDrivers) [ "nouveau" ];

  # Audio configuration for gaming
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = lib.mkDefault true;
  };

  # Performance optimizations
  boot.kernelParams = [
    "nvidia-drm.modeset=1"
  ];

  # Gaming environment variables
  environment.variables = {
    # Wine
    WINEDEBUG = "-all";
  };
}
