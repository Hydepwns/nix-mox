{ config, pkgs, inputs, ... }:
let
  # CI/CD specific configuration
  isCI = builtins.getEnv "CI" == "true";
  logLevel = if isCI then "debug" else "info";
in
{
  # Alertmanager for alert routing and silencing
  services.prometheus.alertmanager = {
    enable = true;
    port = 9093;
    listenAddress = "0.0.0.0";

    # Basic configuration
    configuration = {
      global = {
        smtp_smarthost = "localhost:587";
        smtp_from = "alertmanager@localhost";
      };

      route = {
        group_by = [ "alertname" ];
        group_wait = "30s";
        group_interval = "5m";
        repeat_interval = "4h";
        receiver = "web.hook";
      };

      receivers = [
        {
          name = "web.hook";
          webhook_configs = [
            {
              url = "http://127.0.0.1:5001/";
            }
          ];
        }
      ];
    };

    # Enhanced configuration for CI/CD and production
    extraFlags = [
      "--log.level=${logLevel}"
      "--storage.path=/var/lib/alertmanager"
      "--data.retention=120h"
    ];
  };

  # Enhanced systemd service configuration
  systemd.services.alertmanager = {
    serviceConfig = {
      Restart = "always";
      RestartSec = "10s";
      TimeoutStartSec = "60s";
      TimeoutStopSec = "60s";
    };
    # Add pre-start check
    preStart = ''
      if [ ! -d /var/lib/alertmanager ]; then
        mkdir -p /var/lib/alertmanager
        chown alertmanager:alertmanager /var/lib/alertmanager
      fi
    '';
  };

  # Ensure required directories exist with proper permissions
  systemd.tmpfiles.rules = [
    "d /var/lib/alertmanager 0755 alertmanager alertmanager -"
  ];
}
