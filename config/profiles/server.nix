# Server Profile
# Server management and monitoring tools shared across server templates
{ config, pkgs, ... }:
{
  # Server packages
  environment.systemPackages = with pkgs; [
    # Server management
    htop
    btop
    iotop
    nethogs
    iftop
    atop
    glances

    # Monitoring
    prometheus
    grafana
    node-exporter
    alertmanager
    blackbox-exporter

    # Network tools
    nmap
    wireshark
    tcpdump
    netcat
    socat
    curl
    wget

    # Backup tools
    rsync
    rclone
    restic
    duplicity
    borgbackup

    # Container tools
    docker
    docker-compose
    podman
    buildah
    skopeo
    kubernetes

    # Web servers
    nginx
    apacheHttpd
    caddy

    # Database tools
    postgresql
    redis
    mongodb
    mariadb

    # Log management
    logrotate
    journalctl
    logwatch
    fail2ban

    # Security tools
    openssl
    certbot
    ufw
    iptables
  ];

  # Server programs
  programs = {
    tmux.enable = true;
    git.enable = true;
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
        AllowTcpForwarding = false;
        AllowAgentForwarding = false;
        MaxAuthTries = 3;
        MaxSessions = 2;
        ClientAliveInterval = 300;
        ClientAliveCountMax = 2;
      };
    };

    # Monitoring
    prometheus = {
      enable = true;
      globalConfig = {
        scrape_interval = "15s";
        evaluation_interval = "15s";
      };
    };

    # Logging
    journald.extraConfig = ''
      SystemMaxUse=1G
      MaxRetentionSec=1month
      MaxLevelStore=info
      MaxLevelSyslog=info
    '';
  };

  # Security hardening
  security = {
    # Firewall
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 80 443 ]; # SSH, HTTP, HTTPS
      allowedUDPPorts = [ ];
      logRefusedConnections = true;
    };

    # Audit
    auditd = {
      enable = true;
      rules = [
        "-w /etc/passwd -p wa -k identity"
        "-w /etc/group -p wa -k identity"
        "-w /etc/shadow -p wa -k identity"
        "-w /etc/sudoers -p wa -k scope"
        "-w /var/log/auth.log -p wa -k authentication"
        "-w /etc/ssh/sshd_config -p wa -k sshd"
        "-w /etc/nginx/nginx.conf -p wa -k nginx"
        "-w /etc/postgresql -p wa -k postgresql"
      ];
    };

    # AppArmor
    apparmor.enable = true;
  };

  # Performance tuning
  boot.kernelParams = [
    "elevator=deadline"
    "transparent_hugepage=never"
    "vm.swappiness=10"
    "vm.dirty_ratio=15"
    "vm.dirty_background_ratio=5"
  ];

  # Server environment variables
  environment.variables = {
    EDITOR = "vim";
    PAGER = "less";
    TERM = "xterm-256color";

    # Performance
    GOGC = "50";
    GOMEMLIMIT = "512MiB";
  };

  # Server shell configuration
  programs.zsh.interactiveShellInit = ''
    # Server aliases
    alias status="systemctl status"
    alias logs="journalctl -f"
    alias services="systemctl list-units --type=service"
    alias ports="netstat -tulpn"
    alias connections="ss -tulpn"
    
    # Monitoring
    alias cpu="htop"
    alias monitor="btop"
    alias mem="free -h"
    alias disk="df -h"
    alias load="uptime"
    
    # Network
    alias ip="ip addr show"
    alias route="ip route show"
    alias ping="ping -c 4"
    
    # Docker
    alias dps="docker ps"
    alias di="docker images"
    alias dex="docker exec -it"
    alias dlogs="docker logs -f"
    
    # Quick access
    alias etc="cd /etc"
    alias var="cd /var"
    alias log="cd /var/log"
  '';

  # Systemd optimizations
  systemd = {
    # Reduce memory usage
    extraConfig = ''
      DefaultMemoryPressureLimit=50%
      DefaultMemoryPressureLimitSec=30s
    '';

    # Optimize services
    services = {
      # Reduce journal size
      systemd-journald.serviceConfig = {
        SystemMaxUse = "1G";
        MaxRetentionSec = "1month";
      };

      # Optimize network
      systemd-networkd.serviceConfig = {
        Restart = "always";
        RestartSec = "5s";
      };
    };
  };
}
