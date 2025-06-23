{ config, pkgs, inputs, ... }:
let
  # CI/CD specific configuration
  isCI = builtins.getEnv "CI" == "true";
  logLevel = if isCI then "debug" else "info";
in
{
  services.prometheus = {
    enable = true;
    configFile = ../prometheus.yml;
    listenAddress = "0.0.0.0";
    port = 9090;

    # Enhanced configuration for CI/CD and production
    extraFlags = [
      "--log.level=${logLevel}"
      "--storage.tsdb.retention.time=15d"
      "--storage.tsdb.path=/var/lib/prometheus"
      "--web.enable-lifecycle"
    ];

    # Add scrape configs for monitoring the monitoring stack
    scrapeConfigs = [
      {
        job_name = "prometheus";
        static_configs = [{
          targets = [ "localhost:9090" ];
        }];
      }
      {
        job_name = "node-exporter";
        static_configs = [{
          targets = [ "localhost:9100" ];
        }];
      }
    ];
  };

  # Enhanced systemd service configuration for better error handling
  systemd.services.prometheus = {
    serviceConfig = {
      Restart = "always";
      RestartSec = "10s";
      TimeoutStartSec = "300s";
      TimeoutStopSec = "300s";
    };
    # Add pre-start check
    preStart = ''
      if [ ! -d /var/lib/prometheus ]; then
        mkdir -p /var/lib/prometheus
        chown prometheus:prometheus /var/lib/prometheus
      fi
    '';
  };
}
