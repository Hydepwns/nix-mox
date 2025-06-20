{ config, pkgs, inputs, ... }:
{
  imports = [
    ../fragments/base.nix
  ];

  networking.hostName = "basic-vm";
}
