{ config, pkgs, lib, ... }:
{
  # Keep your existing users/passwords
  system.stateVersion = "24.05";
  users.mutableUsers = true;

  # Enable flakes and unfree for NVIDIA/Steam
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  # Basic networking
  networking.networkmanager.enable = true;

  # Graphics and 32-bit support for Steam/Proton
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Start a desktop session
  services.xserver = {
    enable = true;
    displayManager.sddm.enable = true;
    desktopManager.plasma6.enable = true;
    videoDrivers = [ "nvidia" ];
  };

  # NVIDIA driver; avoid nouveau conflicts
  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  boot.blacklistedKernelModules = [ "nouveau" ];

  # Audio via PipeWire
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = lib.mkDefault true;
  };

  # Recommended for NVIDIA modesetting
  boot.kernelParams = [ "nvidia-drm.modeset=1" ];

  # Optional gaming programs/tools (safe to trim further)
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  environment.systemPackages = with pkgs; [
    steam
    lutris
    gamemode
    mangohud
    vulkan-tools
    pciutils
  ];
}
