{ config, pkgs, inputs, ... }:
{
  # Display configuration module - lightweight, specific display settings only
  # Main desktop and display manager configuration is in common.nix
  services.xserver = {
    enable = true;
    # Desktop manager configured in common.nix to avoid conflicts
  };
}
