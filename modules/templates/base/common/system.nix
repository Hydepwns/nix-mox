{ config, pkgs, inputs, ... }:
{
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "24.05";
}
