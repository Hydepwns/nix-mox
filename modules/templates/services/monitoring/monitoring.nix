{ config, pkgs, inputs, ... }:
{
  imports = [
    ./fragments/prometheus.nix
    ./fragments/grafana.nix
    ./fragments/node-exporter.nix
    ./fragments/alertmanager.nix
  ];

  # Common monitoring configuration
  networking.firewall = {
    allowedTCPPorts = [ 9090 3000 9100 9093 ];
    allowedTCPPortRanges = [
      { from = 9100; to = 9100; } # node_exporter default port
    ];
  };

  # Create monitoring user and group
  users.users.monitoring = {
    isSystemUser = true;
    group = "monitoring";
    description = "Monitoring services user";
  };

  users.groups.monitoring = { };

  # Ensure required directories exist
  systemd.tmpfiles.rules = [
    "d /var/lib/prometheus 0755 prometheus prometheus -"
    "d /var/lib/grafana 0755 grafana grafana -"
    "d /var/lib/alertmanager 0755 alertmanager alertmanager -"
    "d /var/log/monitoring 0755 monitoring monitoring -"
  ];
}
