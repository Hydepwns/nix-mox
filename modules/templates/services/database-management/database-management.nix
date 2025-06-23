{ config, lib, pkgs, ... }:

let
  # Import error handling module
  errorHandling = import ../../modules/error-handling.nix { inherit config lib pkgs; };

  # Template configuration
  cfg = config.services.nix-mox.database-management;

  # Database types
  dbTypes = {
    postgresql = {
      package = pkgs.postgresql;
      service = "postgresql";
      port = 5432;
      dataDir = "/var/lib/postgresql";
    };
    mysql = {
      package = pkgs.mysql;
      service = "mysql";
      port = 3306;
      dataDir = "/var/lib/mysql";
    };
  };

  # Validation functions
  validateConfig = { dbType, ... }@config:
    let
      validDbTypes = builtins.attrNames dbTypes;
    in
    if !builtins.elem dbType validDbTypes then
      errorHandling.handleError 1 "Invalid database type: ${dbType}. Valid types: ${lib.concatStringsSep ", " validDbTypes}"
    else
      true;

  # Health check functions
  checkDatabaseHealth = dbType:
    let
      db = dbTypes.${dbType};
    in
    ''
      # Check if database service is running
      if ! systemctl is-active --quiet ${db.service}; then
        ${errorHandling.logMessage} "ERROR" "${db.service} service is not running"
        exit 1
      fi

      # Check database connection
      if ! ${db.package}/bin/psql -h localhost -p ${toString db.port} -U postgres -c "SELECT 1" > /dev/null 2>&1; then
        ${errorHandling.logMessage} "ERROR" "Cannot connect to ${db.service}"
        exit 1
      fi

      # Check disk space
      if ! df -h ${db.dataDir} | awk 'NR==2 {print $5}' | grep -q "^[0-9]*%$"; then
        ${errorHandling.logMessage} "ERROR" "Cannot check disk space for ${db.service}"
        exit 1
      fi

      ${errorHandling.logMessage} "INFO" "${db.service} health check passed"
    '';

  # Backup functions
  createBackup = dbType:
    let
      db = dbTypes.${dbType};
      backupDir = "/var/backups/${db.service}";
    in
    ''
      # Create backup directory if it doesn't exist
      mkdir -p ${backupDir}

      # Create backup
      if [ "${dbType}" = "postgresql" ]; then
        ${db.package}/bin/pg_dumpall > ${backupDir}/backup-$(date +%Y%m%d-%H%M%S).sql
      elif [ "${dbType}" = "mysql" ]; then
        ${db.package}/bin/mysqldump --all-databases > ${backupDir}/backup-$(date +%Y%m%d-%H%M%S).sql
      fi

      ${errorHandling.logMessage} "INFO" "Created backup for ${db.service}"
    '';

  # Monitoring functions
  setupMonitoring = dbType:
    let
      db = dbTypes.${dbType};
    in
    ''
      # Add Prometheus metrics
      if [ "${dbType}" = "postgresql" ]; then
        ${pkgs.prometheus-postgres-exporter}/bin/postgres_exporter \
          --extend.query-path=${pkgs.prometheus-postgres-exporter}/queries.yaml \
          --web.listen-address=:9187 &
      elif [ "${dbType}" = "mysql" ]; then
        ${pkgs.prometheus-mysqld-exporter}/bin/mysqld_exporter \
          --config.my-cnf=${pkgs.prometheus-mysqld-exporter}/my.cnf \
          --web.listen-address=:9104 &
      fi

      ${errorHandling.logMessage} "INFO" "Set up monitoring for ${db.service}"
    '';
in
{
  options.services.nix-mox.database-management = {
    enable = lib.mkEnableOption "Enable database management template";
    dbType = lib.mkOption {
      type = lib.types.enum (builtins.attrNames dbTypes);
      default = "postgresql";
      description = "Type of database to manage";
    };
    enableBackups = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable automatic backups";
    };
    backupInterval = lib.mkOption {
      type = lib.types.str;
      default = "daily";
      description = "Backup interval (daily, weekly, monthly)";
    };
    enableMonitoring = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable monitoring with Prometheus";
    };
    customConfig = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Custom database configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    # Validate configuration
    assertions = [
      {
        assertion = validateConfig cfg;
        message = "Invalid database management configuration";
      }
    ];

    # Add database package
    environment.systemPackages = with pkgs; [
      dbTypes.${cfg.dbType}.package
    ];

    # Create systemd service
    systemd.services."nix-mox-database-${cfg.dbType}" = {
      description = "nix-mox database management for ${cfg.dbType}";
      wantedBy = [ "multi-user.target" ];
      after = [ "${dbTypes.${cfg.dbType}.service}.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeScript "database-management" ''
          #!${pkgs.bash}/bin/bash
          set -e

          # Source error handling
          . ${errorHandling}/bin/template-error-handler

          # Run health check
          ${checkDatabaseHealth cfg.dbType}

          # Create backup if enabled
          ${lib.optionalString cfg.enableBackups (createBackup cfg.dbType)}

          # Set up monitoring if enabled
          ${lib.optionalString cfg.enableMonitoring (setupMonitoring cfg.dbType)}
        '';
      };
    };

    # Create systemd timer for backups
    systemd.timers."nix-mox-database-${cfg.dbType}-backup" = lib.mkIf cfg.enableBackups {
      description = "Timer for ${cfg.dbType} database backups";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.backupInterval;
        Persistent = true;
      };
    };

    # Add monitoring configuration
    services.prometheus.exporters = lib.mkIf cfg.enableMonitoring {
      ${cfg.dbType} = {
        enable = true;
        port = dbTypes.${cfg.dbType}.port + 10000;
      };
    };
  };
}
