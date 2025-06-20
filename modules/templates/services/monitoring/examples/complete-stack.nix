{ config, pkgs, inputs, ... }:
{
  imports = [
    ../fragments/prometheus.nix
    ../fragments/grafana.nix
    ../fragments/node-exporter.nix
    ../fragments/alertmanager.nix
  ];

  networking.hostName = "monitoring-stack";
  time.timeZone = "UTC";

  # Production-ready settings
  services.prometheus.extraFlags = [
    "--storage.tsdb.retention.time=30d"
    "--web.enable-lifecycle"
    "--web.enable-admin-api"
  ];

  # Enhanced Grafana security
  services.grafana.settings.security = {
    admin_user = "admin";
    admin_password = "$(cat /run/secrets/grafana-admin-password)";
    secret_key = "$(cat /run/secrets/grafana-secret-key)";
    cookie_secure = true;
    allow_embedding = false;
    disable_initial_admin_creation = false;
  };

  # Add custom alert rules
  services.prometheus.rules = [
    {
      alert = "HighCPUUsage";
      expr = "100 - (avg by (instance) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100) > 80";
      for = "5m";
      labels = {
        severity = "warning";
      };
      annotations = {
        summary = "High CPU usage on {{ $labels.instance }}";
        description = "CPU usage is above 80% for more than 5 minutes";
      };
    }
    {
      alert = "HighMemoryUsage";
      expr = "(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 90";
      for = "5m";
      labels = {
        severity = "warning";
      };
      annotations = {
        summary = "High memory usage on {{ $labels.instance }}";
        description = "Memory usage is above 90% for more than 5 minutes";
      };
    }
    {
      alert = "DiskSpaceLow";
      expr = "(node_filesystem_avail_bytes{mountpoint=\"/\"} / node_filesystem_size_bytes{mountpoint=\"/\"}) * 100 < 10";
      for = "5m";
      labels = {
        severity = "critical";
      };
      annotations = {
        summary = "Low disk space on {{ $labels.instance }}";
        description = "Disk space is below 10%";
      };
    }
  ];
}
