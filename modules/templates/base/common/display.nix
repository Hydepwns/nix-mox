{ config, pkgs, inputs, ... }:
{
  services.xserver = {
    enable = true;
    services.desktopManager.gnome.enable = true;
  };

  # Display manager (updated for newer NixOS)
  services.displayManager.sddm.enable = true;
}
