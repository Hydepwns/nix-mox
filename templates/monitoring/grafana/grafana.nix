{ config, pkgs, ... }:
{
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_port = 3000;
        domain = "localhost";
      };
      security = {
        admin_user = "admin";
        admin_password = "admin"; # Change in production!
      };
    };
    provision = {
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          access = "proxy";
          url = "http://localhost:9090";
          isDefault = true;
        }
      ];
      dashboards.settings.providers = [
        {
          name = "default";
          orgId = 1;
          folder = "";
          type = "file";
          options.path = "/var/lib/grafana/dashboards";
        }
      ];
    };
    # Example dashboard provisioning
    extraOptions = {
      "dashboards.json" = builtins.toJSON [
        {
          title = "Sample Node Exporter Dashboard";
          uid = "node-exporter-sample";
          panels = [];
        }
      ];
    };
  };

  # Ensure the dashboards directory exists
  systemd.tmpfiles.rules = [
    "d /var/lib/grafana/dashboards 0755 grafana grafana -"
  ];
} 