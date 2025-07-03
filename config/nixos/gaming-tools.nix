# Gaming Validation Tools Configuration
# Add this to your NixOS configuration.nix or import it

{ config, lib, pkgs, ... }:

{
  # Add gaming validation tools to system packages
  environment.systemPackages = with pkgs; [
    # Hardware detection
    pciutils # lspci - for GPU detection
    mesa-demos # glxinfo - for OpenGL information

    # Audio system
    pulseaudio # pactl - for audio system detection

    # Security
    # ufw # firewall status (removed, not in nixpkgs)

    # Additional useful gaming tools
    vulkan-tools # vulkaninfo (already available)
    gamemode # gamemoded (already available)
    mangohud # performance monitoring (already available)

    # Gaming platforms
    steam # Steam (already available)
    lutris # Lutris (already available)
    wine # Wine (already available)
  ];

  # Note: Firewall and audio are configured through the gaming.nix module
  # This file only provides additional tools and packages

  # Note: GameMode is configured through the gaming.nix module
  # This file only provides additional tools and packages
}
