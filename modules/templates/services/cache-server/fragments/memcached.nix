{ config, lib, pkgs, ... }:

let
  # Import error handling module
  errorHandling = import ../../../error-handling.nix { inherit config lib pkgs; };

  # Template configuration
  cfg = config.services.nix-mox.cache-server;

  # Cache server types
  cacheTypes = {
    memcached = {
      package = pkgs.memcached;
      service = "memcached";
      configDir = "/etc/memcached";
      logDir = "/var/log/memcached";
      defaultPort = 11211;
      metricsPort = 9150;
    };
  };

  # Configuration setup functions
  setupConfig = ''
    # Set up Memcached configuration
    cat > ${cacheTypes.memcached.configDir}/memcached.conf <<EOF
    -p ${toString cacheTypes.memcached.defaultPort}
    -l ${cfg.bindAddress}
    -m ${toString cfg.maxMemory}
    -c ${toString cfg.maxConnections}
    ${lib.optionalString (cfg.password != null) "-S"}
    ${lib.optionalString cfg.enableMonitoring "-v"}
    EOF

    ${errorHandling.logMessage} "INFO" "Set up configuration for ${cacheTypes.memcached.service}"
  '';

  # Health check functions
  checkHealth = ''
    # Check if Memcached server is running
    if ! systemctl is-active --quiet ${cacheTypes.memcached.service}; then
      ${errorHandling.logMessage} "ERROR" "${cacheTypes.memcached.service} service is not running"
      exit 1
    fi

    # Check if Memcached server is listening on port
    if ! netstat -tuln | grep -q ":${toString cacheTypes.memcached.defaultPort} "; then
      ${errorHandling.logMessage} "ERROR" "${cacheTypes.memcached.service} is not listening on port ${toString cacheTypes.memcached.defaultPort}"
      exit 1
    fi

    # Check Memcached server health
    if ! echo "stats" | nc localhost ${toString cacheTypes.memcached.defaultPort} | grep -q "STAT"; then
      ${errorHandling.logMessage} "ERROR" "Memcached server is not responding"
      exit 1
    fi

    ${errorHandling.logMessage} "INFO" "${cacheTypes.memcached.service} health check passed"
  '';
in
{
  config = lib.mkIf (cfg.enable && cfg.cacheType == "memcached") {
    # Create systemd service for Memcached
    systemd.services."nix-mox-cache-server-memcached" = {
      description = "nix-mox cache server for Memcached";
      wantedBy = [ "multi-user.target" ];
      after = [ "memcached.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeScript "cache-server-memcached" ''
          #!${pkgs.bash}/bin/bash
          set -e

          # Source error handling
          . ${errorHandling}/bin/template-error-handler

          # Run health check
          ${checkHealth}

          # Set up configuration
          ${setupConfig}

          # Reload Memcached configuration
          systemctl reload ${cacheTypes.memcached.service}
        '';
      };
    };
  };
}
