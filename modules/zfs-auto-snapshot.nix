{ config, lib, pkgs, ... }:

let
  cfg = config.services.nix-mox.zfs-auto-snapshot;
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
        };
      }));
      default = {};
      description = "Configuration for ZFS pools/datasets to snapshot.";
      example = lib.literalExpression ''
        {
          "rpool" = {
            frequency = "hourly";
            retention_days = 14;
          };
          "rpool/data" = {
            frequency = "daily";
            retention_days = 30;
          };
        }
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services = lib.mapAttrs'
      (poolName: poolConfig:
        let poolName_escaped = lib.replaceStrings [ "/" ] [ "-" ] poolName;
        in lib.nameValuePair "zfs-snapshot-${poolName_escaped}" {
          description = "ZFS snapshot for ${poolName}";
          serviceConfig = {
            Type = "oneshot";
            User = "root";
          };
          script = ''
            ${pkgs.nix-mox.zfs-snapshot}/bin/zfs-snapshot --pool "${poolName}" --retention "${toString poolConfig.retention_days}"
          '';
        })
      (lib.filterAttrs (_: pool: pool.enable) cfg.pools);

    systemd.timers = lib.mapAttrs'
      (poolName: poolConfig:
        let poolName_escaped = lib.replaceStrings [ "/" ] [ "-" ] poolName;
        in lib.nameValuePair "zfs-snapshot-${poolName_escaped}" {
          description = "ZFS snapshot timer for ${poolName}";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = poolConfig.frequency;
            Persistent = true;
          };
        })
      (lib.filterAttrs (_: pool: pool.enable) cfg.pools);
  };
} 