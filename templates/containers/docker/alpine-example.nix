{ config, pkgs, ... }:
{
  virtualisation.oci-containers.containers.alpine = {
    image = "alpine:latest";
    autoStart = true;
    # Command to keep the container running (customize as needed)
    command = [ "sleep" "infinity" ];
    # Multiple bind-mounted volumes
    volumes = [
      "/tmp/alpine-data:/data"
      "/tmp/alpine-logs:/logs"
    ];
    # Advanced networking: attach to 'alpine-net' with a static IP
    networksAdvanced = {
      "alpine-net" = {
        ipv4_address = "172.28.1.10";
      };
    };
    # Health check: run 'echo ok' every 30s
    healthcheck = {
      test = ["CMD" "echo" "ok"];
      interval = "30s";
      timeout = "3s";
      retries = 3;
      start_period = "5s";
    };
    # Optionally, set environment variables or ports
    # environment = { FOO = "bar"; };
    # ports = [ "1234:1234" ];
  };

  # Note: Create the Docker network on the host with:
  #   docker network create --subnet=172.28.0.0/16 alpine-net
  # And ensure /tmp/alpine-data and /tmp/alpine-logs exist and are writable by Docker.
} 