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
  };

  config = lib.mkIf (cfg.enable && cfg.enableBackup) {
    # Add backup timer
    systemd.timers."nix-mox-cache-server-backup-${cfg.cacheType}" = {
      description = "nix-mox cache server backup timer for ${cfg.cacheType}";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
    };

    systemd.services."nix-mox-cache-server-backup-${cfg.cacheType}" = {
      description = "nix-mox cache server backup for ${cfg.cacheType}";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${cacheTypes.${cfg.cacheType}.configDir}/backup.sh";
      };
    };

    # Add backup setup to cache server services
    systemd.services."nix-mox-cache-server-${cfg.cacheType}".serviceConfig.ExecStart =
      lib.mkIf (cfg.enable && cfg.cacheType == "redis" || cfg.cacheType == "memcached")
        pkgs.writeScript "cache-server-with-backup" ''
        #!${pkgs.bash}/bin/bash
        set -e

        # Source error handling
        . ${errorHandling}/bin/template-error-handler

        # Set up backup
        ${setupBackup cfg.cacheType}
      '';
  };
}
