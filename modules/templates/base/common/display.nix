{ config, pkgs, inputs, ... }:
{
  services.xserver = {
    enable = true;
    displayManager.sddm.enable = true;
    services.desktopManager.gnome.enable = true;
  };
}
