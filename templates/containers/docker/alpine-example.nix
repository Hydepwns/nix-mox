{ config, pkgs, lib, ... }:
let
  # CI/CD specific configuration
  isCI = builtins.getEnv "CI" == "true";
  logLevel = if isCI then "debug" else "info";
  
  # Container configuration
  cfg = {
    name = "alpine";
    image = "alpine:latest";
    dataDir = "/var/lib/docker/alpine";
    logDir = "/var/log/docker/alpine";
    network = "alpine-net";
    ipv4Address = "172.28.1.10";
  };

  # Helper function to create directories
  createDir = path: ''
    if [ ! -d "${path}" ]; then
      mkdir -p "${path}"
      chown -R root:root "${path}"
      chmod 755 "${path}"
    fi
  '';
in
{
  # Enable Docker
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  # Container configuration
  virtualisation.oci-containers.containers.${cfg.name} = {
    image = cfg.image;
    autoStart = true;
    
    # Enhanced command with logging
    command = [ 
      "sh" 
      "-c" 
      "echo 'Container started at $(date)' > /logs/startup.log && sleep infinity"
    ];

    # Structured volume mounts
    volumes = [
      "${cfg.dataDir}:/data"
      "${cfg.logDir}:/logs"
      "/etc/localtime:/etc/localtime:ro"
    ];

    # Enhanced networking
    networksAdvanced = {
      ${cfg.network} = {
        ipv4_address = cfg.ipv4Address;
      };
    };

    # Improved health check
    healthcheck = {
      test = ["CMD" "sh" "-c" "echo ok > /logs/health.log && echo ok"];
      interval = "30s";
      timeout = "3s";
      retries = 3;
      start_period = "5s";
    };

    # Environment variables
    environment = {
      TZ = "UTC";
      LOG_LEVEL = logLevel;
      CI_MODE = toString isCI;
    };

    # Resource limits
    extraOptions = [
      "--memory=512m"
      "--cpus=0.5"
      "--restart=unless-stopped"
    ];
  };

  # Systemd service for container management
  systemd.services."docker-${cfg.name}" = {
    description = "Docker container ${cfg.name}";
    wantedBy = [ "multi-user.target" ];
    after = [ "docker.service" "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = createDir cfg.dataDir + createDir cfg.logDir;
    };
  };

  # Monitoring configuration
  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [
      "docker"
      "filesystem"
      "meminfo"
      "netdev"
    ];
  };

  # Add Docker monitoring to Prometheus
  services.prometheus.scrapeConfigs = [
    {
      job_name = "docker";
      static_configs = [{
        targets = [ "localhost:9100" ];
      }];
    }
  ];

  # Ensure required directories exist
  systemd.tmpfiles.rules = [
    "d ${cfg.dataDir} 0755 root root -"
    "d ${cfg.logDir} 0755 root root -"
  ];

  # Note: Create the Docker network on the host with:
  #   docker network create --subnet=172.28.0.0/16 alpine-net
  # And ensure /tmp/alpine-data and /tmp/alpine-logs exist and are writable by Docker.
} 