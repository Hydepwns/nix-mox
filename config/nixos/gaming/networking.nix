{ config, lib, pkgs, ... }:

with lib;

# Gaming networking configuration
# Handles firewall rules and network optimizations for gaming

let
  cfg = config.services.gaming;
in
{
  config = mkIf (cfg.enable && pkgs.stdenv.hostPlatform.isx86_64) {
    # Networking for gaming
    networking = {
      # Open ports for gaming
      firewall = {
        allowedTCPPorts = [
          27015 # Steam
          27016 # Steam
          27017 # Steam
          27018 # Steam
          27019 # Steam
          27020 # Steam
          4380 # Steam
          4381 # Steam
        ];
        allowedUDPPorts = [
          27015 # Steam
          27016 # Steam
          27017 # Steam
          27018 # Steam
          27019 # Steam
          27020 # Steam
          4380 # Steam
          4381 # Steam
        ];
      };
    };
  };
} 