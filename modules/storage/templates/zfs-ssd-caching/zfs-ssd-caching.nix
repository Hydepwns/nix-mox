{ config, pkgs, lib, ... }:

# ZFS SSD Caching Template - Fragment-based Architecture
# This template provides automated configuration for ZFS SSD caching using either L2ARC or Special VDEVs.
# It includes comprehensive monitoring, health checks, and automated maintenance features.

{
  # Import all fragments
  imports = [
    ./fragments/base.nix
  ];

  # Template metadata
  _module.args = {
    templateInfo = {
      name = "zfs-ssd-caching";
      description = "Auto-configure ZFS SSD caching (L2ARC/Special)";
      category = "storage";
      version = "2.0.0";
      fragments = [
        "base"
      ];
    };
  };
}
