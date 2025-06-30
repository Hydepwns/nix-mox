# Server Template Configuration
# Server configuration with monitoring and management tools
{ config, pkgs, ... }:
{
  imports = [
    ../profiles/base.nix
    ../profiles/security.nix
    ../profiles/server.nix
  ];

  # Server-specific configuration
  environment.systemPackages = with pkgs; [
    # Server management
    htop
    iotop
    nethogs
    iftop

    # Monitoring
    prometheus
    grafana
    node-exporter

    # Network tools
    nmap
    wireshark
    tcpdump

    # Backup tools
    rsync
    rclone
    restic

    # Container tools
    docker
    docker-compose
    podman

    # Web servers
    nginx
    apacheHttpd

    # Database tools
    postgresql
    redis

    # Log management
    logrotate
    journalctl
  ];

  # Server programs
  programs = {
    zsh.enable = true;
    git.enable = true;
    tmux.enable = true;
  };

  # Server services
  services = {
    # SSH for remote access
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
        X11Forwarding = false;
      };
    };

    # Monitoring
    prometheus = {
      enable = true;
      globalConfig = {
        scrape_interval = "15s";
      };
    };

    # Logging
    journald.extraConfig = ''
      SystemMaxUse=1G
      MaxRetentionSec=1month
    '';
  };

  # Security hardening
  security = {
    # Firewall
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 80 443 ]; # SSH, HTTP, HTTPS
      allowedUDPPorts = [ ];
    };

    # Audit
    auditd.enable = true;

    # AppArmor
    apparmor.enable = true;
  };

  # Performance tuning
  boot.kernelParams = [
    "elevator=deadline"
    "transparent_hugepage=never"
  ];

  # Server environment variables
  environment.variables = {
    EDITOR = "vim";
    PAGER = "less";
    TERM = "xterm-256color";
  };
}
