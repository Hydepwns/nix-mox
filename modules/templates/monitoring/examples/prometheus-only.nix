{ config, pkgs, inputs, ... }:
{
  imports = [
    ../fragments/prometheus.nix
    ../fragments/node-exporter.nix
  ];

  networking.hostName = "prometheus-only";
  time.timeZone = "UTC";

  # Minimal Prometheus configuration
  services.prometheus.extraFlags = [
    "--storage.tsdb.retention.time=7d"
    "--web.enable-lifecycle"
  ];

  # Add basic alert rules
  services.prometheus.rules = [
    {
      alert = "PrometheusDown";
      expr = "up{job=\"prometheus\"} == 0";
      for = "1m";
      labels = {
        severity = "critical";
      };
      annotations = {
        summary = "Prometheus is down";
        description = "Prometheus has been down for more than 1 minute";
      };
    }
  ];
}
