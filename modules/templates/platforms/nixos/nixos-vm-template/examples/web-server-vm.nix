{ config, pkgs, inputs, ... }:
{
  imports = [
    ../fragments/base.nix
    ../fragments/web-server.nix
  ];

  networking.hostName = "web-server-vm";
}
