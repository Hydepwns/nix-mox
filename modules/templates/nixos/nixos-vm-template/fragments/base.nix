{ config, pkgs, inputs, ... }:
{
  imports = [
    ./networking.nix
    ./users.nix
    ./ssh.nix
    ./firewall.nix
    ./updates.nix
    ./hardware.nix
    ./graphics.nix
  ];

  networking.hostName = "example-vm";
  time.timeZone = "UTC";
  system.stateVersion = "24.05";
}
