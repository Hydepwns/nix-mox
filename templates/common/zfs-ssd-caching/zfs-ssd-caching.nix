{ config, pkgs, lib, ... }:
let
  # Import error handling module
  errorHandling = pkgs.nix-mox.error-handling;

  # CI/CD specific configuration
  isCI = builtins.getEnv "CI" == "true";
  isTest = builtins.getEnv "TEST" == "true";
  
  # Configuration options
  cfg = {
    poolName = "rpool";
    devicePattern = "/dev/nvme*n1";
    useSpecialVdevs = false;
    enableLogging = true;
    maxRetries = 3;
    retryDelay = 5;
    # New configuration options
    enableMonitoring = true;
    enableMetrics = true;
    cacheType = "l2arc"; # or "special"
    cacheMode = "mirror"; # or "stripe"
    cacheSize = "auto"; # or specific size like "100G"
    enableAutoScrub = true;
    scrubInterval = "weekly";
    enableAutoTrim = true;
    trimInterval = "weekly";
  };

  # Use standardized error handling functions
  inherit (errorHandling) logMessage handleError retryOperation validateConfig checkHealth cleanup withTimeout withLock recoverFromError;

  # Validation functions
  validateZFSConfig = ''
    ${validateConfig ''
      [ -n "${cfg.poolName}" ] || ${handleError "1" "Pool name is not configured"}
      [ -n "${cfg.devicePattern}" ] || ${handleError "1" "Device pattern is not configured"}
      [ "${cfg.cacheType}" = "l2arc" ] || [ "${cfg.cacheType}" = "special" ] || ${handleError "1" "Invalid cache type: ${cfg.cacheType}"}
      [ "${cfg.cacheMode}" = "mirror" ] || [ "${cfg.cacheMode}" = "stripe" ] || ${handleError "1" "Invalid cache mode: ${cfg.cacheMode}"}
    ''}
  '';

  # Enhanced device checking with health checks
  checkDevice = dev: ''
    ${checkHealth "test -b ${dev}" "Device ${dev} not found"} || return 1
    ${checkHealth "smartctl -H ${dev} 2>/dev/null | grep -q 'PASSED'" "Device ${dev} health check failed"} || return 1
    ${logMessage "INFO" "Device ${dev} found and healthy"}
    return 0
  '';

  # Enhanced pool checking with health status
  checkPool = ''
    ${checkHealth "zpool list ${cfg.poolName} >/dev/null 2>&1" "Pool ${cfg.poolName} not found"} || return 1
    ${checkHealth "zpool status ${cfg.poolName} | grep -q 'state: ONLINE'" "Pool ${cfg.poolName} not healthy"} || return 1
    ${logMessage "INFO" "Pool ${cfg.poolName} found and healthy"}
    return 0
  '';

  # New function for cache size calculation
  calculateCacheSize = dev: ''
    if [ "${cfg.cacheSize}" = "auto" ]; then
      # Use 80% of device size for cache
      size=$(blockdev --getsize64 "${dev}")
      cache_size=$((size * 80 / 100))
      echo "$cache_size"
    else
      echo "${cfg.cacheSize}"
    fi
  '';

  # Cleanup function
  cleanupZFS = ''
    ${logMessage "INFO" "Running ZFS cleanup operations"}
    zpool scrub -s ${cfg.poolName} 2>/dev/null || true
    zpool trim ${cfg.poolName} 2>/dev/null || true
  '';
in
{
  # Import error handling module
  imports = [ ../../modules/error-handling.nix ];

  # Configure error handling
  template.errorHandling = {
    enable = true;
    logLevel = if isCI || isTest then "debug" else "info";
    maxRetries = cfg.maxRetries;
    retryDelay = cfg.retryDelay;
    logFile = "/var/log/zfs-ssd-caching.log";
  };

  # Ensure the rpool is imported before running this service
  boot.zfs.extraPools = [ cfg.poolName ];

  systemd.services.zfs-ssd-caching = {
    description = "Auto-configure ZFS SSD caching (L2ARC/Special)";
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

      # Source error handling functions
      . template-error-handler

      ${logMessage "INFO" "Starting ZFS SSD caching configuration"}
      ${logMessage "DEBUG" "CI Mode: ${toString isCI}"}
      ${logMessage "DEBUG" "Test Mode: ${toString isTest}"}

      # Validate configuration
      ${validateZFSConfig}

      # Check if pool exists and is healthy
      ${checkPool} || ${handleError "2" "Pool ${cfg.poolName} not found or unhealthy"}

      # Detect all NVMe SSDs
      for dev in ${cfg.devicePattern}; do
        # Check if device exists and is healthy
        ${checkDevice "$dev"} || continue

        # Only add if not already present in the pool
        if ! zpool status ${cfg.poolName} | grep -q "$dev"; then
          cache_size=$(${calculateCacheSize "$dev"})
          ${logMessage "INFO" "Adding $dev as ${cfg.cacheType} (${cfg.cacheMode}) to ${cfg.poolName} with size $cache_size"}
          
          # Use resource locking for pool operations
          ${withLock "/var/lock/zfs-${cfg.poolName}.lock" ''
            if [ "${cfg.cacheType}" = "special" ]; then
              if [ "${cfg.cacheMode}" = "mirror" ]; then
                ${retryOperation "zpool add ${cfg.poolName} special mirror \"$dev\"" "Failed to add $dev as special vdev" ${toString cfg.maxRetries} ${toString cfg.retryDelay}} || continue
              else
                ${retryOperation "zpool add ${cfg.poolName} special \"$dev\"" "Failed to add $dev as special vdev" ${toString cfg.maxRetries} ${toString cfg.retryDelay}} || continue
              fi
            else
              if [ "${cfg.cacheMode}" = "mirror" ]; then
                ${retryOperation "zpool add ${cfg.poolName} cache mirror \"$dev\"" "Failed to add $dev as L2ARC cache" ${toString cfg.maxRetries} ${toString cfg.retryDelay}} || continue
              else
                ${retryOperation "zpool add ${cfg.poolName} cache \"$dev\"" "Failed to add $dev as L2ARC cache" ${toString cfg.maxRetries} ${toString cfg.retryDelay}} || continue
              fi
            fi
          ''}
          
          ${logMessage "INFO" "Successfully added $dev"}
        else
          ${logMessage "INFO" "Device $dev already in use"}
        fi
      done

      # Configure auto-scrub if enabled
      if ${toString cfg.enableAutoScrub}; then
        ${logMessage "INFO" "Configuring auto-scrub with interval: ${cfg.scrubInterval}"}
        ${withTimeout 30 "zpool set autoscrub=on ${cfg.poolName}"} || ${handleError "4" "Failed to configure auto-scrub"}
        ${withTimeout 30 "zpool set autoscrub_interval=${cfg.scrubInterval} ${cfg.poolName}"} || ${handleError "4" "Failed to set scrub interval"}
      fi

      # Configure auto-trim if enabled
      if ${toString cfg.enableAutoTrim}; then
        ${logMessage "INFO" "Configuring auto-trim with interval: ${cfg.trimInterval}"}
        ${withTimeout 30 "zpool set autotrim=on ${cfg.poolName}"} || ${handleError "4" "Failed to configure auto-trim"}
        ${withTimeout 30 "zpool set autotrim_interval=${cfg.trimInterval} ${cfg.poolName}"} || ${handleError "4" "Failed to set trim interval"}
      fi

      # Run cleanup operations
      ${cleanupZFS}

      ${logMessage "INFO" "ZFS SSD caching configuration completed"}
    '';
  };

  # Enhanced monitoring configuration
  services.prometheus.exporters.node = lib.mkIf cfg.enableMonitoring {
    enable = true;
    enabledCollectors = [
      "zfs"
      "filesystem"
      "diskstats"
      "smartmon"
    ];
  };

  # Enhanced Prometheus configuration
  services.prometheus.scrapeConfigs = lib.mkIf cfg.enableMetrics [
    {
      job_name = "zfs";
      static_configs = [{
        targets = [ "localhost:9100" ];
      }];
    }
  ];

  # Add ZFS monitoring to Grafana if enabled
  services.grafana.provision.datasources = lib.mkIf cfg.enableMonitoring [
    {
      name = "ZFS Metrics";
      type = "prometheus";
      url = "http://localhost:9090";
      access = "proxy";
      isDefault = true;
    }
  ];
} 