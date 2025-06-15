{ config, lib, pkgs, ... }:

let
  # Import error handling module
  errorHandling = import ../../modules/error-handling.nix { inherit config lib pkgs; };

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

  # Validation functions
  validateConfig = { cacheType, ... }@config:
    let
      validCacheTypes = builtins.attrNames cacheTypes;
    in
    if !builtins.elem cacheType validCacheTypes then
      errorHandling.handleError 1 "Invalid cache server type: ${cacheType}. Valid types: ${lib.concatStringsSep ", " validCacheTypes}"
    else
      true;

  # Health check functions
  checkCacheServerHealth = cacheType:
    let
      cache = cacheTypes.${cacheType};
    in
    ''
      # Check if cache server is running
      if ! systemctl is-active --quiet ${cache.service}; then
        ${errorHandling.logMessage} "ERROR" "${cache.service} service is not running"
        exit 1
      fi

      # Check if cache server is listening on port
      if ! netstat -tuln | grep -q ":${toString cache.defaultPort} "; then
        ${errorHandling.logMessage} "ERROR" "${cache.service} is not listening on port ${toString cache.defaultPort}"
        exit 1
      fi

      # Check metrics port if monitoring is enabled
      if [ "${toString cfg.enableMonitoring}" = "true" ]; then
        if ! netstat -tuln | grep -q ":${toString cache.metricsPort} "; then
          ${errorHandling.logMessage} "ERROR" "${cache.service} metrics are not available on port ${toString cache.metricsPort}"
          exit 1
        fi
      fi

      # Check cache server health
      if [ "${cacheType}" = "redis" ]; then
        if ! ${pkgs.redis}/bin/redis-cli ping | grep -q "PONG"; then
          ${errorHandling.logMessage} "ERROR" "Redis server is not responding"
          exit 1
        fi
      elif [ "${cacheType}" = "memcached" ]; then
        if ! echo "stats" | nc localhost ${toString cache.defaultPort} | grep -q "STAT"; then
          ${errorHandling.logMessage} "ERROR" "Memcached server is not responding"
          exit 1
        fi
      fi

      ${errorHandling.logMessage} "INFO" "${cache.service} health check passed"
    '';

  # Configuration setup functions
  setupConfig = cacheType:
    let
      cache = cacheTypes.${cacheType};
    in
    ''
      # Set up cache server configuration
      if [ "${cacheType}" = "redis" ]; then
        cat > ${cache.configDir}/redis.conf <<EOF
        port ${toString cache.defaultPort}
        bind ${cfg.bindAddress}
        maxmemory ${toString cfg.maxMemory}mb
        maxmemory-policy ${cfg.evictionPolicy}
        appendonly ${if cfg.persistence then "yes" else "no"}
        ${lib.optionalString (cfg.password != null) "requirepass ${cfg.password}"}
        ${lib.optionalString cfg.enableMonitoring "enable-statistics yes"}
        EOF
      elif [ "${cacheType}" = "memcached" ]; then
        cat > ${cache.configDir}/memcached.conf <<EOF
        -p ${toString cache.defaultPort}
        -l ${cfg.bindAddress}
        -m ${toString cfg.maxMemory}
        -c ${toString cfg.maxConnections}
        ${lib.optionalString (cfg.password != null) "-S"}
        ${lib.optionalString cfg.enableMonitoring "-v"}
        EOF
      fi

      ${errorHandling.logMessage} "INFO" "Set up configuration for ${cache.service}"
    '';

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

  # Backup setup functions
  setupBackup = cacheType:
    let
      cache = cacheTypes.${cacheType};
    in
    ''
      # Set up backup script
      if [ "${cacheType}" = "redis" ]; then
        cat > ${cache.configDir}/backup.sh <<EOF
        #!${pkgs.bash}/bin/bash
        set -e

        # Source error handling
        . ${errorHandling}/bin/template-error-handler

        # Create backup directory
        mkdir -p ${cfg.backupDir}

        # Create backup
        ${pkgs.redis}/bin/redis-cli ${lib.optionalString (cfg.password != null) "-a ${cfg.password}"} SAVE
        cp ${cache.configDir}/dump.rdb ${cfg.backupDir}/redis-\$(date +%Y%m%d-%H%M%S).rdb

        # Clean up old backups
        find ${cfg.backupDir} -name "redis-*.rdb" -mtime +${toString cfg.backupRetention} -delete

        ${errorHandling.logMessage} "INFO" "Created Redis backup"
        EOF
        chmod +x ${cache.configDir}/backup.sh
      elif [ "${cacheType}" = "memcached" ]; then
        cat > ${cache.configDir}/backup.sh <<EOF
        #!${pkgs.bash}/bin/bash
        set -e

        # Source error handling
        . ${errorHandling}/bin/template-error-handler

        # Create backup directory
        mkdir -p ${cfg.backupDir}

        # Create backup
        echo "stats" | nc localhost ${toString cache.defaultPort} > ${cfg.backupDir}/memcached-\$(date +%Y%m%d-%H%M%S).stats

        # Clean up old backups
        find ${cfg.backupDir} -name "memcached-*.stats" -mtime +${toString cfg.backupRetention} -delete

        ${errorHandling.logMessage} "INFO" "Created Memcached backup"
        EOF
        chmod +x ${cache.configDir}/backup.sh
      fi

      ${errorHandling.logMessage} "INFO" "Set up backup script for ${cache.service}"
    '';
in
{
  options.services.nix-mox.cache-server = {
    enable = lib.mkEnableOption "Enable cache server template";
    cacheType = lib.mkOption {
      type = lib.types.enum (builtins.attrNames cacheTypes);
      default = "redis";
      description = "Type of cache server to use";
    };
    bindAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address to bind the cache server to";
    };
    maxMemory = lib.mkOption {
      type = lib.types.int;
      default = 1024;
      description = "Maximum memory usage in MB";
    };
    maxConnections = lib.mkOption {
      type = lib.types.int;
      default = 1024;
      description = "Maximum number of connections";
    };
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
    password = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Password for authentication";
    };
    enableMonitoring = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable monitoring with Prometheus";
    };
    enableBackup = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable automated backups";
    };
    backupDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/cache-server/backups";
      description = "Directory for backups";
    };
    backupRetention = lib.mkOption {
      type = lib.types.int;
      default = 7;
      description = "Number of days to retain backups";
    };
    customConfig = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Custom cache server configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    # Validate configuration
    assertions = [
      {
        assertion = validateConfig cfg;
        message = "Invalid cache server configuration";
      }
    ];

    # Add cache server package
    environment.systemPackages = with pkgs; [
      cacheTypes.${cfg.cacheType}.package
    ];

    # Create systemd service
    systemd.services."nix-mox-cache-server-${cfg.cacheType}" = {
      description = "nix-mox cache server for ${cfg.cacheType}";
      wantedBy = [ "multi-user.target" ];
      after = [ "${cacheTypes.${cfg.cacheType}.service}.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeScript "cache-server" ''
          #!${pkgs.bash}/bin/bash
          set -e

          # Source error handling
          . ${errorHandling}/bin/template-error-handler

          # Run health check
          ${checkCacheServerHealth cfg.cacheType}

          # Set up configuration
          ${setupConfig cfg.cacheType}

          # Set up monitoring if enabled
          ${lib.optionalString cfg.enableMonitoring (setupMonitoring cfg.cacheType)}

          # Set up backup if enabled
          ${lib.optionalString cfg.enableBackup (setupBackup cfg.cacheType)}

          # Reload cache server configuration
          systemctl reload ${cacheTypes.${cfg.cacheType}.service}
        '';
      };
    };

    # Add monitoring configuration
    services.prometheus.exporters = lib.mkIf cfg.enableMonitoring {
      ${cfg.cacheType} = {
        enable = true;
        port = cacheTypes.${cfg.cacheType}.metricsPort;
      };
    };

    # Add backup timer if enabled
    systemd.timers."nix-mox-cache-server-backup-${cfg.cacheType}" = lib.mkIf cfg.enableBackup {
      description = "nix-mox cache server backup timer for ${cfg.cacheType}";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
    };

    systemd.services."nix-mox-cache-server-backup-${cfg.cacheType}" = lib.mkIf cfg.enableBackup {
      description = "nix-mox cache server backup for ${cfg.cacheType}";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${cacheTypes.${cfg.cacheType}.configDir}/backup.sh";
      };
    };
  };
} 