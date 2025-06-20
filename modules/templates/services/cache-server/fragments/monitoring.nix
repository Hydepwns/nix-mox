{ config, lib, pkgs, ... }:

let
  # Import error handling module
  errorHandling = import ../../../error-handling.nix { inherit config lib pkgs; };

  # Template configuration
  cfg = config.services.nix-mox.cache-server;

  # Cache server types
  cacheTypes = {
    redis = {
      package = pkgs.redis;
      service = "redis";
      configDir = "/etc/redis";
      logDir = "/var/log/redis";
      defaultPort = 6379;
      metricsPort = 9121;
    };
    memcached = {
      package = pkgs.memcached;
      service = "memcached";
      configDir = "/etc/memcached";
      logDir = "/var/log/memcached";
      defaultPort = 11211;
      metricsPort = 9150;
    };
  };

  # Monitoring setup functions
  setupMonitoring = cacheType:
    let
      cache = cacheTypes.${cacheType};
    in
    ''
      # Add Prometheus metrics
      if [ "${cacheType}" = "redis" ]; then
        ${pkgs.prometheus-redis-exporter}/bin/redis_exporter \
          --redis.addr=localhost:${toString cache.defaultPort} \
          --web.listen-address=:${toString cache.metricsPort} \
          ${lib.optionalString (cfg.password != null) "--redis.password=${cfg.password}"} &
      elif [ "${cacheType}" = "memcached" ]; then
        ${pkgs.prometheus-memcached-exporter}/bin/memcached_exporter \
          --memcached.address=localhost:${toString cache.defaultPort} \
          --web.listen-address=:${toString cache.metricsPort} &
      fi

      ${errorHandling.logMessage} "INFO" "Set up monitoring for ${cache.service}"
    '';

  # Health check for monitoring
  checkMonitoring = cacheType:
    let
      cache = cacheTypes.${cacheType};
    in
    ''
      # Check metrics port if monitoring is enabled
      if [ "${toString cfg.enableMonitoring}" = "true" ]; then
        if ! netstat -tuln | grep -q ":${toString cache.metricsPort} "; then
          ${errorHandling.logMessage} "ERROR" "${cache.service} metrics are not available on port ${toString cache.metricsPort}"
          exit 1
        fi
      fi
    '';
in
{
  options.services.nix-mox.cache-server = {
    enableMonitoring = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable monitoring with Prometheus";
    };
  };

  config = lib.mkIf (cfg.enable && cfg.enableMonitoring) {
    # Add monitoring configuration
    services.prometheus.exporters = {
      ${cfg.cacheType} = {
        enable = true;
        port = cacheTypes.${cfg.cacheType}.metricsPort;
      };
    };

    # Add monitoring setup to cache server services
    systemd.services."nix-mox-cache-server-${cfg.cacheType}".serviceConfig.ExecStart =
      lib.mkIf (cfg.enable && cfg.cacheType == "redis" || cfg.cacheType == "memcached")
        pkgs.writeScript "cache-server-with-monitoring" ''
          #!${pkgs.bash}/bin/bash
          set -e

          # Source error handling
          . ${errorHandling}/bin/template-error-handler

          # Set up monitoring
          ${setupMonitoring cfg.cacheType}

          # Check monitoring health
          ${checkMonitoring cfg.cacheType}
        '';
  };
}
