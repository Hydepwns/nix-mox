{ config, pkgs, inputs, ... }:
{
  services.xserver = {
    enable = true;
    displayManager.lightdm.enable = true;
    services.desktopManager.gnome.enable = true;
  };
}
