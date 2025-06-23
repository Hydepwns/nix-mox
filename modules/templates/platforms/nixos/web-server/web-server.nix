{ config, lib, pkgs, ... }:

let
  # Import error handling module
  errorHandling = import ../../modules/error-handling.nix { inherit config lib pkgs; };

  # Template configuration
  cfg = config.services.nix-mox.web-server;

  # Web server types
  serverTypes = {
    nginx = {
      package = pkgs.nginx;
      service = "nginx";
      configDir = "/etc/nginx";
      logDir = "/var/log/nginx";
      defaultPort = 80;
      sslPort = 443;
    };
    apache = {
      package = pkgs.apacheHttpd;
      service = "httpd";
      configDir = "/etc/apache2";
      logDir = "/var/log/apache2";
      defaultPort = 80;
      sslPort = 443;
    };
  };

  # Validation functions
  validateConfig = { serverType, ... }@config:
    let
      validServerTypes = builtins.attrNames serverTypes;
    in
    if !builtins.elem serverType validServerTypes then
      errorHandling.handleError 1 "Invalid server type: ${serverType}. Valid types: ${lib.concatStringsSep ", " validServerTypes}"
    else
      true;

  # Health check functions
  checkServerHealth = serverType:
    let
      server = serverTypes.${serverType};
    in
    ''
      # Check if server is running
      if ! systemctl is-active --quiet ${server.service}; then
        ${errorHandling.logMessage} "ERROR" "${server.service} service is not running"
        exit 1
      fi

      # Check if server is listening on ports
      if ! netstat -tuln | grep -q ":${toString server.defaultPort} "; then
        ${errorHandling.logMessage} "ERROR" "${server.service} is not listening on port ${toString server.defaultPort}"
        exit 1
      fi

      # Check SSL if enabled
      if [ "${toString cfg.enableSSL}" = "true" ]; then
        if ! netstat -tuln | grep -q ":${toString server.sslPort} "; then
          ${errorHandling.logMessage} "ERROR" "${server.service} is not listening on SSL port ${toString server.sslPort}"
          exit 1
        fi
      fi

      # Check log directory
      if [ ! -d "${server.logDir}" ]; then
        ${errorHandling.logMessage} "ERROR" "Log directory ${server.logDir} does not exist"
        exit 1
      fi

      ${errorHandling.logMessage} "INFO" "${server.service} health check passed"
    '';

  # SSL setup functions
  setupSSL = serverType:
    let
      server = serverTypes.${serverType};
    in
    ''
      # Create SSL directory if it doesn't exist
      mkdir -p ${server.configDir}/ssl

      # Generate self-signed certificate if not provided
      if [ ! -f "${server.configDir}/ssl/server.crt" ]; then
        ${pkgs.openssl}/bin/openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
          -keyout ${server.configDir}/ssl/server.key \
          -out ${server.configDir}/ssl/server.crt \
          -subj "/CN=localhost"
      fi

      ${errorHandling.logMessage} "INFO" "SSL setup completed for ${server.service}"
    '';

  # Monitoring setup functions
  setupMonitoring = serverType:
    let
      server = serverTypes.${serverType};
    in
    ''
      # Add Prometheus metrics
      if [ "${serverType}" = "nginx" ]; then
        ${pkgs.prometheus-nginx-exporter}/bin/nginx-prometheus-exporter \
          -nginx.scrape-uri=http://localhost:${toString server.defaultPort}/metrics &
      elif [ "${serverType}" = "apache" ]; then
        ${pkgs.prometheus-apache-exporter}/bin/apache_exporter \
          --insecure \
          --scrape-uri=http://localhost:${toString server.defaultPort}/server-status &
      fi

      ${errorHandling.logMessage} "INFO" "Set up monitoring for ${server.service}"
    '';

  # Virtual host setup functions
  setupVirtualHost = serverType: hostConfig:
    let
      server = serverTypes.${serverType};
    in
    ''
      # Create virtual host configuration
      if [ "${serverType}" = "nginx" ]; then
        cat > ${server.configDir}/conf.d/${hostConfig.name}.conf <<EOF
        server {
            listen ${toString server.defaultPort};
            ${lib.optionalString cfg.enableSSL "listen ${toString server.sslPort} ssl;"}
            server_name ${hostConfig.domain};

            ${lib.optionalString cfg.enableSSL ''
            ssl_certificate ${server.configDir}/ssl/server.crt;
            ssl_certificate_key ${server.configDir}/ssl/server.key;
            ''}

            root ${hostConfig.root};
            index ${lib.concatStringsSep " " hostConfig.indexFiles};

            location / {
                try_files \$uri \$uri/ =404;
            }

            ${lib.optionalString (hostConfig.proxyPass != null) ''
            location /api {
                proxy_pass ${hostConfig.proxyPass};
                proxy_set_header Host \$host;
                proxy_set_header X-Real-IP \$remote_addr;
            }
            ''}
        }
        EOF
      elif [ "${serverType}" = "apache" ]; then
        cat > ${server.configDir}/sites-available/${hostConfig.name}.conf <<EOF
        <VirtualHost *:${toString server.defaultPort}>
            ${lib.optionalString cfg.enableSSL "<VirtualHost *:${toString server.sslPort}>"}
            ServerName ${hostConfig.domain}
            DocumentRoot ${hostConfig.root}

            ${lib.optionalString cfg.enableSSL ''
            SSLEngine on
            SSLCertificateFile ${server.configDir}/ssl/server.crt
            SSLCertificateKeyFile ${server.configDir}/ssl/server.key
            ''}

            <Directory ${hostConfig.root}>
                Options Indexes FollowSymLinks
                AllowOverride All
                Require all granted
            </Directory>

            ${lib.optionalString (hostConfig.proxyPass != null) ''
            ProxyPass /api ${hostConfig.proxyPass}
            ProxyPassReverse /api ${hostConfig.proxyPass}
            ''}
        </VirtualHost>
        EOF

        # Enable the site
        ln -sf ${server.configDir}/sites-available/${hostConfig.name}.conf \
               ${server.configDir}/sites-enabled/${hostConfig.name}.conf
      fi

      ${errorHandling.logMessage} "INFO" "Set up virtual host ${hostConfig.name} for ${server.service}"
    '';
in
{
  options.services.nix-mox.web-server = {
    enable = lib.mkEnableOption "Enable web server template";
    serverType = lib.mkOption {
      type = lib.types.enum (builtins.attrNames serverTypes);
      default = "nginx";
      description = "Type of web server to use";
    };
    enableSSL = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable SSL support";
    };
    enableMonitoring = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable monitoring with Prometheus";
    };
    virtualHosts = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            description = "Name of the virtual host";
          };
          domain = lib.mkOption {
            type = lib.types.str;
            description = "Domain name for the virtual host";
          };
          root = lib.mkOption {
            type = lib.types.path;
            description = "Root directory for the virtual host";
          };
          indexFiles = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ "index.html" "index.php" ];
            description = "List of index files to try";
          };
          proxyPass = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Proxy pass URL for API requests";
          };
        };
      });
      default = [ ];
      description = "List of virtual hosts to configure";
    };
    customConfig = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Custom server configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    # Validate configuration
    assertions = [
      {
        assertion = validateConfig cfg;
        message = "Invalid web server configuration";
      }
    ];

    # Add web server package
    environment.systemPackages = with pkgs; [
      serverTypes.${cfg.serverType}.package
    ];

    # Create systemd service
    systemd.services."nix-mox-web-${cfg.serverType}" = {
      description = "nix-mox web server for ${cfg.serverType}";
      wantedBy = [ "multi-user.target" ];
      after = [ "${serverTypes.${cfg.serverType}.service}.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeScript "web-server" ''
          #!${pkgs.bash}/bin/bash
          set -e

          # Source error handling
          . ${errorHandling}/bin/template-error-handler

          # Run health check
          ${checkServerHealth cfg.serverType}

          # Set up SSL if enabled
          ${lib.optionalString cfg.enableSSL (setupSSL cfg.serverType)}

          # Set up monitoring if enabled
          ${lib.optionalString cfg.enableMonitoring (setupMonitoring cfg.serverType)}

          # Set up virtual hosts
          ${lib.concatStringsSep "\n" (map (host: setupVirtualHost cfg.serverType host) cfg.virtualHosts)}

          # Reload server configuration
          systemctl reload ${serverTypes.${cfg.serverType}.service}
        '';
      };
    };

    # Add monitoring configuration
    services.prometheus.exporters = lib.mkIf cfg.enableMonitoring {
      ${cfg.serverType} = {
        enable = true;
        port = serverTypes.${cfg.serverType}.defaultPort + 10000;
      };
    };
  };
}
