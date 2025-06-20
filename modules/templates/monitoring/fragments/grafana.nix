{ config, pkgs, inputs, ... }:
let
  # CI/CD specific configuration
  isCI = builtins.getEnv "CI" == "true";
  logLevel = if isCI then "debug" else "info";

  # Security configuration
  adminPassword = if isCI then "admin" else "$(cat /run/secrets/grafana-admin-password)";
in
{
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_port = 3000;
        domain = "localhost";
        root_url = "http://localhost:3000/";
        serve_from_sub_path = false;
      };
      security = {
        admin_user = "admin";
        admin_password = adminPassword;
        secret_key = "$(cat /run/secrets/grafana-secret-key)";
        disable_initial_admin_creation = false;
        cookie_secure = true;
        allow_embedding = false;
      };
      auth = {
        disable_login_form = false;
        disable_signout_menu = false;
        oauth_auto_login = false;
      };
      log = {
        mode = "console file";
        level = logLevel;
      };
      metrics = {
        enabled = true;
        interval_seconds = 10;
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
          editable = false;
          jsonData = {
            timeInterval = "15s";
            queryTimeout = "30s";
            httpMethod = "POST";
          };
        }
      ];
      dashboards.settings.providers = [
        {
          name = "default";
          orgId = 1;
          folder = "";
          type = "file";
          options.path = "/var/lib/grafana/dashboards";
          disableDeletion = true;
          updateIntervalSeconds = 60;
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

  # Enhanced systemd service configuration
  systemd.services.grafana = {
    serviceConfig = {
      Restart = "always";
      RestartSec = "10s";
      TimeoutStartSec = "300s";
      TimeoutStopSec = "300s";
      # Add environment variables for CI/CD
      Environment = [
        "GF_INSTALL_PLUGINS=grafana-piechart-panel,grafana-worldmap-panel"
        "GF_PATHS_DATA=/var/lib/grafana"
        "GF_PATHS_LOGS=/var/log/grafana"
        "GF_PATHS_PLUGINS=/var/lib/grafana/plugins"
      ];
    };
    # Add pre-start checks
    preStart = ''
      if [ ! -d /var/lib/grafana/dashboards ]; then
        mkdir -p /var/lib/grafana/dashboards
        chown grafana:grafana /var/lib/grafana/dashboards
      fi
      if [ ! -d /var/lib/grafana/plugins ]; then
        mkdir -p /var/lib/grafana/plugins
        chown grafana:grafana /var/lib/grafana/plugins
      fi
    '';
  };

  # Ensure required directories exist with proper permissions
  systemd.tmpfiles.rules = [
    "d /var/lib/grafana/dashboards 0755 grafana grafana -"
    "d /var/lib/grafana/plugins 0755 grafana grafana -"
    "d /var/log/grafana 0755 grafana grafana -"
  ];
}
