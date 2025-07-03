# ============================================================================
# SERVER EXTRA MODULE
# ============================================================================
# Server-specific configurations for host2
# ============================================================================

{ config, lib, pkgs, inputs, mySecret, hostType, ... }:

{
  # Server-specific settings
  services = {
    # SSH server
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        PubkeyAuthentication = true;
      };
    };

    # Web server (optional)
    nginx = {
      enable = true;
      virtualHosts."localhost" = {
        default = true;
        root = "/var/www";
      };
    };

    # Database (optional)
    postgresql = {
      enable = true;
      package = pkgs.postgresql_15;
    };

    # Monitoring
    prometheus = {
      enable = true;
      exporters = {
        node = {
          enable = true;
          enabledCollectors = [ "systemd" "cpu" "diskstats" "filesystem" "loadavg" "meminfo" "netdev" "netstat" "textfile" "time" "vmstat" "logind" "interrupts" "tcpstat" ];
        };
      };
    };

    grafana = {
      enable = true;
      settings = {
        server = {
          http_port = 3000;
          domain = "localhost";
        };
      };
    };
  };

  # Server applications
  environment.systemPackages = with pkgs; [
    # Server tools
    htop
    iotop
    nethogs
    tcpdump
    nmap

    # Development tools
    git
    vim
    tmux

    # Monitoring tools
    prometheus
    grafana

    # Database tools
    postgresql_15
  ];

  # User-specific settings for server
  users.users.droo = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    shell = lib.mkForce pkgs.bash;
    openssh.authorizedKeys.keys = [
      # Add your SSH public key here
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC..."
    ];
  };

  # Security settings for server
  security = {
    sudo.wheelNeedsPassword = true;
    auditd.enable = lib.mkForce true;
  };

  # Networking for server
  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22 # SSH
        80 # HTTP
        443 # HTTPS
        3000 # Grafana
        9090 # Prometheus
        5432 # PostgreSQL
      ];
      allowedUDPPorts = [ 53 ]; # DNS
    };
  };

  # System settings
  system = {
    autoUpgrade = {
      enable = lib.mkForce true;
      channel = lib.mkForce "https://nixos.org/channels/nixos-23.11"; # More stable for servers
    };
  };

  # Performance tuning for servers
  boot = {
    kernel.sysctl = {
      "net.core.somaxconn" = 65535;
      "net.ipv4.tcp_max_syn_backlog" = 65535;
      "vm.swappiness" = 10;
    };
  };

  # Debug: Print host-specific arguments
  system.activationScripts.debug = ''
    echo "Server configuration loaded"
    echo "Host type: ${hostType}"
    echo "Secret: ${mySecret}"
  '';
}
