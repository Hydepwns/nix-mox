# Basic Gaming Configuration Example
# This example demonstrates the simplest way to enable gaming support in nix-mox

{ config, pkgs, ... }:

{
  # Import the gaming configuration
  imports = [ ./gaming.nix ];

  # Enable basic gaming support with auto-detection
  services.gaming = {
    enable = true;

    # Auto-detect GPU (NVIDIA/AMD/Intel)
    gpu.type = "auto";

    # Enable basic performance optimizations
    performance.enable = true;

    # Enable audio support
    audio.enable = true;
  };

  # Optional: Enable additional gaming platforms
  # services.gaming.platforms = {
  #   steam = true;
  #   lutris = true;
  #   heroic = true;
  # };
}
