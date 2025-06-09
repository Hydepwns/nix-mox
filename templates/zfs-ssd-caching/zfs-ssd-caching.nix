{ config, pkgs, lib, ... }:
let
  # CI/CD specific configuration
  isCI = builtins.getEnv "CI" == "true";
  logLevel = if isCI then "debug" else "info";
  
  # Configuration options
  cfg = {
    poolName = "rpool";
    devicePattern = "/dev/nvme*n1";
    useSpecialVdevs = false;
    enableLogging = true;
  };

  # Helper functions
  logMessage = message: ''
    if [ "${toString cfg.enableLogging}" = "true" ]; then
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message"
    fi
  '';

  checkDevice = dev: ''
    if [ ! -b "${dev}" ]; then
      ${logMessage "Device ${dev} not found"}
      return 1
    fi
    return 0
  '';

  checkPool = ''
    if ! zpool list ${cfg.poolName} >/dev/null 2>&1; then
      ${logMessage "Pool ${cfg.poolName} not found"}
      return 1
    fi
    return 0
  '';
in
{
  # Ensure the rpool is imported before running this service
  boot.zfs.extraPools = [ cfg.poolName ];

  systemd.services.zfs-ssd-caching = {
    description = "Auto-configure ZFS SSD caching (L2ARC)";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      Restart = "on-failure";
      RestartSec = "10s";
      TimeoutStartSec = "300s";
      TimeoutStopSec = "300s";
      # Only run if rpool is imported
      Requires = [ "zfs-import-${cfg.poolName}.service" ];
      After = [ "zfs-import-${cfg.poolName}.service" ];
    };

    script = ''
      #!/bin/sh
      set -e

      ${logMessage "Starting ZFS SSD caching configuration"}
      ${logMessage "CI Mode: ${toString isCI}"}
      ${logMessage "Log Level: ${logLevel}"}

      # Check if pool exists
      ${checkPool} || exit 1

      # Detect all NVMe SSDs
      for dev in ${cfg.devicePattern}; do
        # Check if device exists
        ${checkDevice "$dev"} || continue

        # Only add if not already present in the pool
        if ! zpool status ${cfg.poolName} | grep -q "$dev"; then
          ${logMessage "Adding $dev as ${if cfg.useSpecialVdevs then "special vdev" else "L2ARC cache"} to ${cfg.poolName}"}
          
          if ${toString cfg.useSpecialVdevs}; then
            zpool add ${cfg.poolName} special mirror "$dev" || {
              ${logMessage "Failed to add $dev as special vdev"}
              continue
            }
          else
            zpool add ${cfg.poolName} cache "$dev" || {
              ${logMessage "Failed to add $dev as L2ARC cache"}
              continue
            }
          fi
          
          ${logMessage "Successfully added $dev"}
        else
          ${logMessage "Device $dev already in use"}
        fi
      done

      ${logMessage "ZFS SSD caching configuration completed"}
    '';
  };

  # Add monitoring for ZFS
  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [
      "zfs"
      "filesystem"
      "diskstats"
    ];
  };

  # Add ZFS monitoring to Prometheus
  services.prometheus.scrapeConfigs = [
    {
      job_name = "zfs";
      static_configs = [{
        targets = [ "localhost:9100" ];
      }];
    }
  ];
} 