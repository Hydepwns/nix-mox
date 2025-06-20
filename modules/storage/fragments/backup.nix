{ config, lib, pkgs, ... }:

let
  # Import error handling module
  errorHandling = import ../../error-handling.nix { inherit config lib pkgs; };

  # Storage configuration
  storageCfg = config.services.nix-mox.storage;
  backupCfg = config.services.nix-mox.storage-backup;
in
{
  options.services.nix-mox.storage-backup = {
    enable = lib.mkEnableOption "Enable storage backup functionality";

    targets = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule ({ ... }: {
        options = {
          enable = lib.mkEnableOption "backup for this target" // {
            default = true;
          };
          source = lib.mkOption {
            type = lib.types.str;
            description = "Source path to backup";
          };
          destination = lib.mkOption {
            type = lib.types.str;
            description = "Destination path for backup";
          };
          frequency = lib.mkOption {
            type = lib.types.str;
            default = "daily";
            description = "Systemd calendar expression for backup frequency";
          };
          retention_days = lib.mkOption {
            type = lib.types.int;
            default = 7;
            description = "Number of days to retain backups";
          };
          compression = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable compression for backups";
          };
          exclude = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "Patterns to exclude from backup";
          };
        };
      }));
      default = {};
      description = "Configuration for storage backup targets";
      example = lib.literalExpression ''
        {
          "home-backup" = {
            source = "/home";
            destination = "/backup/home";
            frequency = "daily";
            retention_days = 30;
            compression = true;
            exclude = [ "*.tmp" "*.log" ];
          };
        }
      '';
    };
  };

  config = lib.mkIf (storageCfg.enable && backupCfg.enable) {
    # Add backup tools
    environment.systemPackages = with pkgs; [
      rsync
      tar
      gzip
      borgbackup
    ];

    # Create systemd services for backups
    systemd.services = lib.mapAttrs'
      (targetName: targetConfig:
        let
          targetName_escaped = lib.replaceStrings [ "/" "-" ] [ "_" "_" ] targetName;
        in
        lib.nameValuePair "storage-backup-${targetName_escaped}" {
          description = "Storage backup for ${targetName}";
          serviceConfig = {
            Type = "oneshot";
            User = "root";
            ExecStart = pkgs.writeScript "storage-backup-${targetName_escaped}" ''
              #!${pkgs.bash}/bin/bash
              set -e

              # Source error handling
              . ${errorHandling}/bin/template-error-handler

              # Validate source exists
              if [ ! -e "${targetConfig.source}" ]; then
                ${errorHandling.logMessage} "ERROR" "Backup source ${targetConfig.source} does not exist"
                exit 1
              fi

              # Create destination directory
              mkdir -p "${targetConfig.destination}"

              # Build rsync exclude options
              exclude_opts=""
              for pattern in ${lib.escapeShellArgs targetConfig.exclude}; do
                exclude_opts="$exclude_opts --exclude='$pattern'"
              done

              # Create backup with timestamp
              timestamp=$(date +%Y%m%d-%H%M%S)
              backup_dir="${targetConfig.destination}/${targetName_escaped}-$timestamp"

              # Use rsync for backup
              ${pkgs.rsync}/bin/rsync -av --delete $exclude_opts \
                "${targetConfig.source}/" "$backup_dir/"

              # Compress if enabled
              if [ "${toString targetConfig.compression}" = "true" ]; then
                ${pkgs.tar}/bin/tar -czf "$backup_dir.tar.gz" -C "${targetConfig.destination}" "$(basename $backup_dir)"
                rm -rf "$backup_dir"
                ${errorHandling.logMessage} "INFO" "Created compressed backup: $backup_dir.tar.gz"
              else
                ${errorHandling.logMessage} "INFO" "Created backup: $backup_dir"
              fi

              # Clean up old backups
              find "${targetConfig.destination}" -name "${targetName_escaped}-*" -mtime +${toString targetConfig.retention_days} -delete
            '';
          };
        })
      (lib.filterAttrs (_: target: target.enable) backupCfg.targets);

    # Create systemd timers for backups
    systemd.timers = lib.mapAttrs'
      (targetName: targetConfig:
        let
          targetName_escaped = lib.replaceStrings [ "/" "-" ] [ "_" "_" ] targetName;
        in
        lib.nameValuePair "storage-backup-${targetName_escaped}" {
          description = "Storage backup timer for ${targetName}";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = targetConfig.frequency;
            Persistent = true;
          };
        })
      (lib.filterAttrs (_: target: target.enable) backupCfg.targets);
  };
}
