{ config, lib, pkgs, ... }:

# Monitoring template definition
{
  name = "monitoring";
  description = "Monitoring template with Prometheus and Grafana";
  scripts = [
    "prometheus.nix"
    "grafana.nix"
  ];
  dependencies = [
    "prometheus"
    "grafana"
  ];
} 