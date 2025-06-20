{ config, lib, pkgs, ... }:

let
  # Import error handling module
  errorHandling = import ../../modules/error-handling.nix { inherit config lib pkgs; };

  # Template configuration
  cfg = config.services.nix-mox.load-balancer;

  # Load balancer types
  lbTypes = {
    haproxy = {
      package = pkgs.haproxy;
      service = "haproxy";
      configDir = "/etc/haproxy";
      logDir = "/var/log/haproxy";
      defaultPort = 80;
      statsPort = 8404;
    };
    nginx = {
      package = pkgs.nginx;
      service = "nginx";
      configDir = "/etc/nginx";
      logDir = "/var/log/nginx";
      defaultPort = 80;
      statusPort = 8080;
    };
  };

  # Validation functions
  validateConfig = { lbType, ... }@config:
    let
      validLbTypes = builtins.attrNames lbTypes;
    in
    if !builtins.elem lbType validLbTypes then
      errorHandling.handleError 1 "Invalid load balancer type: ${lbType}. Valid types: ${lib.concatStringsSep ", " validLbTypes}"
    else
      true;

  # Health check functions
  checkLoadBalancerHealth = lbType:
    let
      lb = lbTypes.${lbType};
    in
    ''
      # Check if load balancer is running
      if ! systemctl is-active --quiet ${lb.service}; then
        ${errorHandling.logMessage} "ERROR" "${lb.service} service is not running"
        exit 1
      fi

      # Check if load balancer is listening on ports
      if ! netstat -tuln | grep -q ":${toString lb.defaultPort} "; then
        ${errorHandling.logMessage} "ERROR" "${lb.service} is not listening on port ${toString lb.defaultPort}"
        exit 1
      fi

      # Check stats port if enabled
      if [ "${toString cfg.enableStats}" = "true" ]; then
        if ! netstat -tuln | grep -q ":${toString lb.statsPort} "; then
          ${errorHandling.logMessage} "ERROR" "${lb.service} is not listening on stats port ${toString lb.statsPort}"
          exit 1
        fi
      fi

      # Check backend servers
      for backend in ${lib.concatStringsSep " " (map (b: b.name) cfg.backends)}; do
        if ! curl -s "http://localhost:${toString lb.defaultPort}/health" > /dev/null; then
          ${errorHandling.logMessage} "ERROR" "Backend ${backend} is not responding"
          exit 1
        fi
      done

      ${errorHandling.logMessage} "INFO" "${lb.service} health check passed"
    '';

  # Stats setup functions
  setupStats = lbType:
    let
      lb = lbTypes.${lbType};
    in
    ''
      # Set up stats page
      if [ "${lbType}" = "haproxy" ]; then
        cat > ${lb.configDir}/stats.cfg <<EOF
        listen stats
            bind *:${toString lb.statsPort}
            stats enable
            stats uri /stats
            stats refresh 10s
            stats auth ${cfg.statsUser}:${cfg.statsPassword}
        EOF
      elif [ "${lbType}" = "nginx" ]; then
        cat > ${lb.configDir}/conf.d/stats.conf <<EOF
        server {
            listen ${toString lb.statsPort};
            location /status {
                stub_status on;
                access_log off;
                allow 127.0.0.1;
                deny all;
            }
        }
        EOF
      fi

      ${errorHandling.logMessage} "INFO" "Set up stats page for ${lb.service}"
    '';

  # Backend setup functions
  setupBackend = lbType: backend:
    let
      lb = lbTypes.${lbType};
    in
    ''
      # Set up backend configuration
      if [ "${lbType}" = "haproxy" ]; then
        cat > ${lb.configDir}/backends/${backend.name}.cfg <<EOF
        backend ${backend.name}
            balance ${backend.algorithm}
            ${lib.concatStringsSep "\n    " (map (server: "server ${server.name} ${server.address}:${toString server.port} check") backend.servers)}
            ${lib.optionalString (backend.healthCheck != null) "option httpchk ${backend.healthCheck}"}
            ${lib.optionalString (backend.sticky != null) "cookie SERVERID insert indirect nocache"}
        EOF
      elif [ "${lbType}" = "nginx" ]; then
        cat > ${lb.configDir}/conf.d/${backend.name}.conf <<EOF
        upstream ${backend.name} {
            ${lib.concatStringsSep "\n    " (map (server: "server ${server.address}:${toString server.port};") backend.servers)}
            ${lib.optionalString (backend.sticky != null) "ip_hash;"}
        }

        server {
            listen ${toString lb.defaultPort};
            server_name ${backend.domain};

            location / {
                proxy_pass http://${backend.name};
                proxy_set_header Host \$host;
                proxy_set_header X-Real-IP \$remote_addr;
            }
        }
        EOF
      fi

      ${errorHandling.logMessage} "INFO" "Set up backend ${backend.name} for ${lb.service}"
    '';

  # Monitoring setup functions
  setupMonitoring = lbType:
    let
      lb = lbTypes.${lbType};
    in
    ''
      # Add Prometheus metrics
      if [ "${lbType}" = "haproxy" ]; then
        ${pkgs.prometheus-haproxy-exporter}/bin/haproxy_exporter \
          --web.listen-address=:9101 \
          --haproxy.scrape-uri=http://localhost:${toString lb.statsPort}/stats &
      elif [ "${lbType}" = "nginx" ]; then
        ${pkgs.prometheus-nginx-exporter}/bin/nginx-prometheus-exporter \
          -nginx.scrape-uri=http://localhost:${toString lb.statusPort}/status &
      fi

      ${errorHandling.logMessage} "INFO" "Set up monitoring for ${lb.service}"
    '';
in
{
  options.services.nix-mox.load-balancer = {
    enable = lib.mkEnableOption "Enable load balancer template";
    lbType = lib.mkOption {
      type = lib.types.enum (builtins.attrNames lbTypes);
      default = "haproxy";
      description = "Type of load balancer to use";
    };
    enableStats = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable statistics page";
    };
    statsUser = lib.mkOption {
      type = lib.types.str;
      default = "admin";
      description = "Username for statistics page";
    };
    statsPassword = lib.mkOption {
      type = lib.types.str;
      description = "Password for statistics page";
    };
    enableMonitoring = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable monitoring with Prometheus";
    };
    backends = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            description = "Name of the backend";
          };
          domain = lib.mkOption {
            type = lib.types.str;
            description = "Domain name for the backend";
          };
          algorithm = lib.mkOption {
            type = lib.types.enum [ "roundrobin" "leastconn" "first" "source" "uri" "url_param" "hdr" "rdp-cookie" ];
            default = "roundrobin";
            description = "Load balancing algorithm";
          };
          servers = lib.mkOption {
            type = lib.types.listOf (lib.types.submodule {
              options = {
                name = lib.mkOption {
                  type = lib.types.str;
                  description = "Name of the server";
                };
                address = lib.mkOption {
                  type = lib.types.str;
                  description = "Address of the server";
                };
                port = lib.mkOption {
                  type = lib.types.port;
                  description = "Port of the server";
                };
              };
            });
            description = "List of backend servers";
          };
          healthCheck = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Health check configuration";
          };
          sticky = lib.mkOption {
            type = lib.types.nullOr lib.types.bool;
            default = null;
            description = "Enable sticky sessions";
          };
        };
      });
      default = [];
      description = "List of backends to configure";
    };
    customConfig = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Custom load balancer configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    # Validate configuration
    assertions = [
      {
        assertion = validateConfig cfg;
        message = "Invalid load balancer configuration";
      }
    ];

    # Add load balancer package
    environment.systemPackages = with pkgs; [
      lbTypes.${cfg.lbType}.package
    ];

    # Create systemd service
    systemd.services."nix-mox-load-balancer-${cfg.lbType}" = {
      description = "nix-mox load balancer for ${cfg.lbType}";
      wantedBy = [ "multi-user.target" ];
      after = [ "${lbTypes.${cfg.lbType}.service}.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeScript "load-balancer" ''
          #!${pkgs.bash}/bin/bash
          set -e

          # Source error handling
          . ${errorHandling}/bin/template-error-handler

          # Run health check
          ${checkLoadBalancerHealth cfg.lbType}

          # Set up stats if enabled
          ${lib.optionalString cfg.enableStats (setupStats cfg.lbType)}

          # Set up backends
          ${lib.concatStringsSep "\n" (map (backend: setupBackend cfg.lbType backend) cfg.backends)}

          # Set up monitoring if enabled
          ${lib.optionalString cfg.enableMonitoring (setupMonitoring cfg.lbType)}

          # Reload load balancer configuration
          systemctl reload ${lbTypes.${cfg.lbType}.service}
        '';
      };
    };

    # Add monitoring configuration
    services.prometheus.exporters = lib.mkIf cfg.enableMonitoring {
      ${cfg.lbType} = {
        enable = true;
        port = lbTypes.${cfg.lbType}.defaultPort + 10000;
      };
    };
  };
} 