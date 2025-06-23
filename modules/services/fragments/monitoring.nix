{ config, lib, pkgs, ... }:

let
  # Import error handling module
  errorHandling = import ../../error-handling.nix { inherit config lib pkgs; };

  # Service configuration
  servicesCfg = config.services.nix-mox.services;
  monitoringCfg = config.services.nix-mox.service-monitoring;
in
{
  options.services.nix-mox.service-monitoring = {
    enable = lib.mkEnableOption "Enable service monitoring and health checks";

    services = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule ({ ... }: {
        options = {
          enable = lib.mkEnableOption "monitoring for this service" // {
            default = true;
          };
          name = lib.mkOption {
            type = lib.types.str;
            description = "Systemd service name to monitor";
          };
          check_status = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Check if the service is running";
          };
          check_port = lib.mkOption {
            type = lib.types.nullOr lib.types.int;
            default = null;
            description = "Port to check if the service is listening";
          };
          check_url = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "URL to check for HTTP/HTTPS health endpoint";
          };
          frequency = lib.mkOption {
            type = lib.types.str;
            default = "*/2:00"; # Every 2 minutes
            description = "How often to check the service";
          };
        };
      }));
      default = { };
      description = "Configuration for service monitoring";
      example = lib.literalExpression ''
        {
          "nginx" = {
            name = "nginx";
            check_status = true;
            check_port = 80;
            check_url = "http://localhost/health";
            frequency = "*/1:00";
          };
          "postgresql" = {
            name = "postgresql";
            check_status = true;
            check_port = 5432;
            frequency = "*/5:00";
          };
        }
      '';
    };
  };

  config = lib.mkIf (servicesCfg.enable && servicesCfg.enableHealthChecks && monitoringCfg.enable) {
    # Add monitoring tools
    environment.systemPackages = with pkgs; [
      netcat
      curl
      jq
    ];

    # Create systemd services for service monitoring
    systemd.services = lib.mapAttrs'
      (serviceName: serviceConfig:
        lib.nameValuePair "service-monitor-${serviceName}" {
          description = "Service monitoring for ${serviceName}";
          serviceConfig = {
            Type = "oneshot";
            User = servicesCfg.defaultUser;
            Group = servicesCfg.defaultGroup;
            ExecStart = pkgs.writeScript "service-monitor-${serviceName}" ''
              #!${pkgs.bash}/bin/bash
              set -e

              # Source error handling
              . ${errorHandling}/bin/template-error-handler

              # Check service status
              if [ "${toString serviceConfig.check_status}" = "true" ]; then
                if ! systemctl is-active --quiet ${serviceConfig.name}; then
                  ${errorHandling.logMessage} "ERROR" "Service ${serviceConfig.name} is not running"
                  exit 1
                fi
                ${errorHandling.logMessage} "INFO" "Service ${serviceConfig.name} is running"
              fi

              # Check port if specified
              if [ "${toString serviceConfig.check_port}" != "null" ]; then
                if ! netstat -tuln | grep -q ":${toString serviceConfig.check_port} "; then
                  ${errorHandling.logMessage} "ERROR" "Service ${serviceConfig.name} is not listening on port ${toString serviceConfig.check_port}"
                  exit 1
                fi
                ${errorHandling.logMessage} "INFO" "Service ${serviceConfig.name} is listening on port ${toString serviceConfig.check_port}"
              fi

              # Check URL if specified
              if [ "${toString serviceConfig.check_url}" != "null" ]; then
                if ! ${pkgs.curl}/bin/curl -f -s "${serviceConfig.check_url}" >/dev/null; then
                  ${errorHandling.logMessage} "ERROR" "Service ${serviceConfig.name} health check failed at ${serviceConfig.check_url}"
                  exit 1
                fi
                ${errorHandling.logMessage} "INFO" "Service ${serviceConfig.name} health check passed at ${serviceConfig.check_url}"
              fi

              ${errorHandling.logMessage} "INFO" "All health checks passed for ${serviceConfig.name}"
            '';
          };
        })
      (lib.filterAttrs (_: service: service.enable) monitoringCfg.services);

    # Create monitoring timers
    systemd.timers = lib.mapAttrs'
      (serviceName: serviceConfig:
        lib.nameValuePair "service-monitor-${serviceName}" {
          description = "Service monitoring timer for ${serviceName}";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = serviceConfig.frequency;
            Persistent = true;
          };
        })
      (lib.filterAttrs (_: service: service.enable) monitoringCfg.services);

    # Add Prometheus monitoring
    services.prometheus.exporters = {
      node = {
        enable = true;
        enabledCollectors = [ "systemd" "uname" "vmstat" ];
      };
    };
  };
}
