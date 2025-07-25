# Gaming Template Configuration
# Gaming-focused configuration with performance optimizations
{ config, pkgs, ... }:
{
  imports = [
    ../profiles/base.nix
    ../profiles/security.nix
    ../profiles/gaming.nix
  ];

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
    nvtop
    radeontop

    # Media players
    vlc
    mpv

    # Voice chat
    discord
    teamspeak

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

  # Audio configuration for gaming
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Performance optimizations
  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "amdgpu.si_support=1"
    "amdgpu.cik_support=1"
  ];

  # Gaming environment variables
  environment.variables = {
    # Vulkan
    VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json:/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json";

    # Wine
    WINEDEBUG = "-all";

    # Performance
    __GL_SYNC_TO_VBLANK = "0";
    __GL_THREADED_OPTIMIZATIONS = "1";
  };
}
