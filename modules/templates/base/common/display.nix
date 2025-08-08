{ config, pkgs, inputs, ... }:
{
  # Display configuration module - SDDM configuration moved to common.nix to avoid conflicts
  services.xserver = {
    enable = true;
    desktopManager.gnome.enable = true;
  };
}
