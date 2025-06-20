{ config, lib, pkgs, ... }:

let
  # Import error handling module
  errorHandling = import ../../error-handling.nix { inherit config lib pkgs; };

  # Storage configuration
  storageCfg = config.services.nix-mox.storage;
  monitoringCfg = config.services.nix-mox.storage-monitoring;
in
{
  options.services.nix-mox.storage-monitoring = {
    enable = lib.mkEnableOption "Enable storage monitoring and health checks";

    # Enhanced monitoring options
    enablePrometheus = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Prometheus metrics collection";
    };

    enableGrafana = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Grafana dashboard provisioning";
    };

    disks = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule ({ ... }: {
        options = {
          enable = lib.mkEnableOption "monitoring for this disk" // {
            default = true;
          };
          device = lib.mkOption {
            type = lib.types.str;
            description = "Device path (e.g., /dev/sda)";
          };
          check_smart = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable SMART health checks";
          };
          check_temperature = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable temperature monitoring";
          };
          max_temperature = lib.mkOption {
            type = lib.types.int;
            default = 50;
            description = "Maximum temperature threshold in Celsius";
          };
        };
      }));
      default = {};
      description = "Configuration for disk monitoring";
      example = lib.literalExpression ''
        {
          "sda" = {
            device = "/dev/sda";
            check_smart = true;
            check_temperature = true;
            max_temperature = 45;
          };
        }
      '';
    };

    pools = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule ({ ... }: {
        options = {
          enable = lib.mkEnableOption "monitoring for this pool" // {
            default = true;
          };
          name = lib.mkOption {
            type = lib.types.str;
            description = "Pool name";
          };
          check_health = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable pool health checks";
          };
          check_space = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable space usage monitoring";
          };
          space_threshold = lib.mkOption {
            type = lib.types.int;
            default = 80;
            description = "Space usage threshold percentage";
          };
        };
      }));
      default = {};
      description = "Configuration for storage pool monitoring";
    };
  };

  config = lib.mkIf (storageCfg.enable && storageCfg.enableMonitoring && monitoringCfg.enable) {
    # Add monitoring tools
    environment.systemPackages = with pkgs; [
      smartmontools
      hdparm
      hddtemp
      iostat
    ];

    # Enhanced Prometheus monitoring
    services.prometheus.exporters = lib.mkIf monitoringCfg.enablePrometheus {
      node = {
        enable = true;
        enabledCollectors = [
          "diskstats"
          "filesystem"
          "uname"
          "vmstat"
          "zfs"
          "smartmon"
        ];
      };
    };

    # Enhanced Prometheus configuration
    services.prometheus.scrapeConfigs = lib.mkIf monitoringCfg.enablePrometheus [
      {
        job_name = "storage";
        static_configs = [{
          targets = [ "localhost:9100" ];
        }];
      }
    ];

    # Add ZFS monitoring to Grafana if enabled
    services.grafana.provision.datasources = lib.mkIf (monitoringCfg.enableGrafana && monitoringCfg.enablePrometheus) [
      {
        name = "Storage Metrics";
        type = "prometheus";
        url = "http://localhost:9090";
        access = "proxy";
        isDefault = true;
      }
    ];

    # Create systemd services for disk and pool monitoring
    systemd.services = lib.mkMerge [
      # Disk monitoring services
      (lib.mapAttrs'
        (diskName: diskConfig:
          lib.nameValuePair "storage-monitor-disk-${diskName}" {
            description = "Storage monitoring for disk ${diskName}";
            serviceConfig = {
              Type = "oneshot";
              User = "root";
              ExecStart = pkgs.writeScript "storage-monitor-disk-${diskName}" ''
                #!${pkgs.bash}/bin/bash
                set -e

                # Source error handling
                . ${errorHandling}/bin/template-error-handler

                # Check if device exists
                if [ ! -e "${diskConfig.device}" ]; then
                  ${errorHandling.logMessage} "ERROR" "Device ${diskConfig.device} does not exist"
                  exit 1
                fi

                # SMART health check
                if [ "${toString diskConfig.check_smart}" = "true" ]; then
                  if ! ${pkgs.smartmontools}/bin/smartctl -H "${diskConfig.device}" | grep -q "SMART overall-health self-assessment test result: PASSED"; then
                    ${errorHandling.logMessage} "ERROR" "SMART health check failed for ${diskConfig.device}"
                    exit 1
                  fi
                  ${errorHandling.logMessage} "INFO" "SMART health check passed for ${diskConfig.device}"
                fi

                # Temperature check
                if [ "${toString diskConfig.check_temperature}" = "true" ]; then
                  temp=$(${pkgs.smartmontools}/bin/smartctl -A "${diskConfig.device}" | grep "Temperature_Celsius" | awk '{print $10}')
                  if [ "$temp" -gt ${toString diskConfig.max_temperature} ]; then
                    ${errorHandling.logMessage} "WARNING" "Temperature ${temp}°C exceeds threshold ${toString diskConfig.max_temperature}°C for ${diskConfig.device}"
                  else
                    ${errorHandling.logMessage} "INFO" "Temperature ${temp}°C is within normal range for ${diskConfig.device}"
                  fi
                fi
              '';
            };
          })
        (lib.filterAttrs (_: disk: disk.enable) monitoringCfg.disks))

      # Pool monitoring services
      (lib.mapAttrs'
        (poolName: poolConfig:
          lib.nameValuePair "storage-monitor-pool-${poolName}" {
            description = "Storage monitoring for pool ${poolName}";
            serviceConfig = {
              Type = "oneshot";
              User = "root";
              ExecStart = pkgs.writeScript "storage-monitor-pool-${poolName}" ''
                #!${pkgs.bash}/bin/bash
                set -e

                # Source error handling
                . ${errorHandling}/bin/template-error-handler

                # Check if pool exists
                if ! zpool list "${poolConfig.name}" >/dev/null 2>&1; then
                  ${errorHandling.logMessage} "ERROR" "ZFS pool ${poolConfig.name} does not exist"
                  exit 1
                fi

                # Pool health check
                if [ "${toString poolConfig.check_health}" = "true" ]; then
                  health=$(zpool status "${poolConfig.name}" | grep "state:" | awk '{print $2}')
                  if [ "$health" != "ONLINE" ]; then
                    ${errorHandling.logMessage} "ERROR" "ZFS pool ${poolConfig.name} health is $health"
                    exit 1
                  fi
                  ${errorHandling.logMessage} "INFO" "ZFS pool ${poolConfig.name} health is $health"
                fi

                # Space usage check
                if [ "${toString poolConfig.check_space}" = "true" ]; then
                  usage=$(zpool list -H -o capacity "${poolConfig.name}" | sed 's/%//')
                  if [ "$usage" -gt ${toString poolConfig.space_threshold} ]; then
                    ${errorHandling.logMessage} "WARNING" "ZFS pool ${poolConfig.name} usage ${usage}% exceeds threshold ${toString poolConfig.space_threshold}%"
                  else
                    ${errorHandling.logMessage} "INFO" "ZFS pool ${poolConfig.name} usage ${usage}% is within normal range"
                  fi
                fi
              '';
            };
          })
        (lib.filterAttrs (_: pool: pool.enable) monitoringCfg.pools))
    ];

    # Create monitoring timers
    systemd.timers = lib.mkMerge [
      # Disk monitoring timers
      (lib.mapAttrs'
        (diskName: _:
          lib.nameValuePair "storage-monitor-disk-${diskName}" {
            description = "Storage monitoring timer for disk ${diskName}";
            wantedBy = [ "timers.target" ];
            timerConfig = {
              OnCalendar = "hourly";
              Persistent = true;
            };
          })
        (lib.filterAttrs (_: disk: disk.enable) monitoringCfg.disks))

      # Pool monitoring timers
      (lib.mapAttrs'
        (poolName: _:
          lib.nameValuePair "storage-monitor-pool-${poolName}" {
            description = "Storage monitoring timer for pool ${poolName}";
            wantedBy = [ "timers.target" ];
            timerConfig = {
              OnCalendar = "hourly";
              Persistent = true;
            };
          })
        (lib.filterAttrs (_: pool: pool.enable) monitoringCfg.pools))
    ];
  };
}
