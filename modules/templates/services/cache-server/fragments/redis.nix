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
  };

  # Configuration setup functions
  setupConfig = ''
    # Set up Redis configuration
    cat > ${cacheTypes.redis.configDir}/redis.conf <<EOF
    port ${toString cacheTypes.redis.defaultPort}
    bind ${cfg.bindAddress}
    maxmemory ${toString cfg.maxMemory}mb
    maxmemory-policy ${cfg.evictionPolicy}
    appendonly ${if cfg.persistence then "yes" else "no"}
    ${lib.optionalString (cfg.password != null) "requirepass ${cfg.password}"}
    ${lib.optionalString cfg.enableMonitoring "enable-statistics yes"}
    EOF

    ${errorHandling.logMessage} "INFO" "Set up configuration for ${cacheTypes.redis.service}"
  '';

  # Health check functions
  checkHealth = ''
    # Check if Redis server is running
    if ! systemctl is-active --quiet ${cacheTypes.redis.service}; then
      ${errorHandling.logMessage} "ERROR" "${cacheTypes.redis.service} service is not running"
      exit 1
    fi

    # Check if Redis server is listening on port
    if ! netstat -tuln | grep -q ":${toString cacheTypes.redis.defaultPort} "; then
      ${errorHandling.logMessage} "ERROR" "${cacheTypes.redis.service} is not listening on port ${toString cacheTypes.redis.defaultPort}"
      exit 1
    fi

    # Check Redis server health
    if ! ${pkgs.redis}/bin/redis-cli ping | grep -q "PONG"; then
      ${errorHandling.logMessage} "ERROR" "Redis server is not responding"
      exit 1
    fi

    ${errorHandling.logMessage} "INFO" "${cacheTypes.redis.service} health check passed"
  '';
in
{
  options.services.nix-mox.cache-server = {
    evictionPolicy = lib.mkOption {
      type = lib.types.enum [ "noeviction" "allkeys-lru" "volatile-lru" "allkeys-random" "volatile-random" "volatile-ttl" ];
      default = "noeviction";
      description = "Memory eviction policy (Redis only)";
    };
    persistence = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable persistence (Redis only)";
    };
  };

  config = lib.mkIf (cfg.enable && cfg.cacheType == "redis") {
    # Create systemd service for Redis
    systemd.services."nix-mox-cache-server-redis" = {
      description = "nix-mox cache server for Redis";
      wantedBy = [ "multi-user.target" ];
      after = [ "redis.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeScript "cache-server-redis" ''
          #!${pkgs.bash}/bin/bash
          set -e

          # Source error handling
          . ${errorHandling}/bin/template-error-handler

          # Run health check
          ${checkHealth}

          # Set up configuration
          ${setupConfig}

          # Reload Redis configuration
          systemctl reload ${cacheTypes.redis.service}
        '';
      };
    };
  };
}
