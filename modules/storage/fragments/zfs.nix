{ config, lib, pkgs, ... }:

let
  # Import error handling module
  errorHandling = import ../../error-handling.nix { inherit config lib pkgs; };

  # Storage configuration
  storageCfg = config.services.nix-mox.storage;
  zfsCfg = config.services.nix-mox.zfs-auto-snapshot;
in
{
  options.services.nix-mox.zfs-auto-snapshot = {
    enable = lib.mkEnableOption "Enable declarative ZFS auto-snapshots";

    pools = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule ({ ... }: {
        options = {
          enable = lib.mkEnableOption "snapshots for this pool/dataset" // {
            default = true;
          };
          frequency = lib.mkOption {
            type = lib.types.str;
            default = "daily";
            description = "Systemd calendar expression for snapshot frequency (e.g., 'hourly', 'daily', 'weekly').";
          };
          retention_days = lib.mkOption {
            type = lib.types.int;
            default = 7;
            description = "Number of days to retain snapshots for.";
          };
          compression = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable compression for snapshots";
          };
          recursive = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Create recursive snapshots of child datasets";
          };
        };
      }));
      default = { };
      description = "Configuration for ZFS pools/datasets to snapshot.";
      example = lib.literalExpression ''
        {
          "rpool" = {
            frequency = "hourly";
            retention_days = 14;
            compression = true;
            recursive = true;
          };
          "rpool/data" = {
            frequency = "daily";
            retention_days = 30;
            compression = true;
            recursive = false;
          };
        }
      '';
    };
  };

  config = lib.mkIf (storageCfg.enable && zfsCfg.enable) {
    # Add ZFS-specific packages
    environment.systemPackages = with pkgs; [
      zfs
      zfs-auto-snapshot
    ];

    # Create systemd services for ZFS snapshots
    systemd.services = lib.mapAttrs'
      (poolName: poolConfig:
        let
          poolName_escaped = lib.replaceStrings [ "/" ] [ "-" ] poolName;
        in
        lib.nameValuePair "zfs-snapshot-${poolName_escaped}" {
          description = "ZFS snapshot for ${poolName}";
          serviceConfig = {
            Type = "oneshot";
            User = "root";
            ExecStart = pkgs.writeScript "zfs-snapshot-${poolName_escaped}" ''
              #!${pkgs.bash}/bin/bash
              set -e

              # Source error handling
              . ${errorHandling}/bin/template-error-handler

              # Validate pool exists
              if ! zpool list "${poolName}" >/dev/null 2>&1; then
                ${errorHandling.logMessage} "ERROR" "ZFS pool ${poolName} does not exist"
                exit 1
              fi

              # Create snapshot
              ${pkgs.nix-mox.zfs-snapshot}/bin/zfs-snapshot \
                --pool "${poolName}" \
                --retention "${toString poolConfig.retention_days}" \
                ${lib.optionalString poolConfig.compression "--compression"} \
                ${lib.optionalString poolConfig.recursive "--recursive"}

              ${errorHandling.logMessage} "INFO" "Created ZFS snapshot for ${poolName}"
            '';
          };
        })
      (lib.filterAttrs (_: pool: pool.enable) zfsCfg.pools);

    # Create systemd timers for ZFS snapshots
    systemd.timers = lib.mapAttrs'
      (poolName: poolConfig:
        let
          poolName_escaped = lib.replaceStrings [ "/" ] [ "-" ] poolName;
        in
        lib.nameValuePair "zfs-snapshot-${poolName_escaped}" {
          description = "ZFS snapshot timer for ${poolName}";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = poolConfig.frequency;
            Persistent = true;
          };
        })
      (lib.filterAttrs (_: pool: pool.enable) zfsCfg.pools);

    # Add ZFS monitoring if enabled
    services.prometheus.exporters = lib.mkIf storageCfg.enableMonitoring {
      node = {
        enable = true;
        enabledCollectors = [ "zfs" ];
      };
    };
  };
}
