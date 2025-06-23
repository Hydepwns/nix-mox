{ config, pkgs, inputs, ... }:
{
  imports = [
    ../fragments/grafana.nix
  ];

  networking.hostName = "grafana-only";
  time.timeZone = "UTC";

  # Grafana-only configuration (assumes external Prometheus)
  services.grafana.settings.security = {
    admin_user = "admin";
    admin_password = "admin"; # Change in production
    secret_key = "your-secret-key-here"; # Change in production
    cookie_secure = false; # Set to true in production with HTTPS
    allow_embedding = false;
    disable_initial_admin_creation = false;
  };

  # Add external Prometheus data source
  services.grafana.provision.datasources.settings.datasources = [
    {
      name = "External Prometheus";
      type = "prometheus";
      access = "proxy";
      url = "http://prometheus-server:9090"; # Change to your Prometheus URL
      isDefault = true;
      editable = false;
      jsonData = {
        timeInterval = "15s";
        queryTimeout = "30s";
        httpMethod = "POST";
      };
    }
  ];
}
