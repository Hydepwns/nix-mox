{ config, pkgs, inputs, ... }:
let
  # Get the pre-packaged script from the root nix-mox flake
  nixMoxUpdateScriptPkg = inputs.nix-mox.packages.${pkgs.system}.nixos-flake-update;
in
{
  # Automatic Updates
  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = false; # Set to true if you want automatic reboots

  # Place the nixos-flake-update script from the root flake into /etc/nixos/
  environment.etc."nixos/nixos-flake-update.sh" = {
    source = nixMoxUpdateScriptPkg;
    mode = "0555"; # r-xr-xr-x, executable for all
  };

  # Enable the systemd service and timer for automatic updates
  systemd.services.nixos-flake-update = {
    enable = true;
  };

  systemd.timers.nixos-flake-update = {
    enable = true;
    wantedBy = [ "timers.target" ]; # Ensures the timer is started on boot
  };
}
