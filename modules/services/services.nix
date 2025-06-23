{ config, lib, pkgs, ... }:

{
  # Import all service fragments
  imports = [
    ./fragments/base.nix
    ./fragments/infisical.nix
    ./fragments/tailscale.nix
    ./fragments/monitoring.nix
  ];
}
