{ config, pkgs, lib, ... }:
let
  # CI/CD specific configuration
  isCI = builtins.getEnv "CI" == "true";
  logLevel = if isCI then "debug" else "info";
in
{
  services.prometheus = {
    enable = true;
    configFile = ./prometheus.yml;
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
    ];
  };

  # Enhanced firewall configuration
  networking.firewall = {
    allowedTCPPorts = [ 9090 ];
    # Allow Prometheus to scrape metrics from other hosts
    allowedTCPPortRanges = [
      { from = 9100; to = 9100; }  # node_exporter default port
    ];
  };

  # Add systemd service configuration for better error handling
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

  # Add monitoring for the Prometheus service itself
  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [
      "systemd"
      "textfile"
      "filesystem"
      "diskstats"
      "meminfo"
      "netdev"
    ];
  };
} 