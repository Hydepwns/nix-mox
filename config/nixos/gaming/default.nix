{ config, lib, pkgs, ... }:

with lib;

# Main gaming module entry point
# Imports all gaming-related sub-modules

let
  isX86_64 = pkgs.stdenv.hostPlatform.isx86_64;
  cfg = config.services.gaming;
in
{
  imports = [
    ./options.nix
    ./hardware.nix
    ./audio.nix
    ./performance.nix
    ./platforms.nix
    ./networking.nix
    ./security.nix
  ];

  # Only enable gaming configuration on x86_64 systems
  config = mkIf (cfg.enable && isX86_64) {
    # This file serves as the main entry point
    # All actual configuration is handled by the imported modules
  };
} 