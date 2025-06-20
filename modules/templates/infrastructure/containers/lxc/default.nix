{ config, pkgs, lib, ... }:
let
  # CI/CD specific configuration
  isCI = builtins.getEnv "CI" == "true";
  logLevel = if isCI then "debug" else "info";
  
  # Container configuration
  cfg = {
    hostname = "nixos-lxc";
    timezone = "UTC";
    locale = "en_US.UTF-8";
  };
in
{
  imports = [
    ./first-boot-setup.nix
    ./cloud-init-example.nix
  ];

  # Basic system configuration
  system.stateVersion = "23.11";
  time.timeZone = cfg.timezone;
  i18n.defaultLocale = cfg.locale;

  # Enhanced networking
  networking = {
    hostName = cfg.hostname;
    useDHCP = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
      allowedUDPPorts = [ ];
    };
  };

  # Security configuration
  security = {
    auditd.enable = true;
    audit.enable = true;
    sudo.wheelNeedsPassword = true;
  };

  # Enhanced user setup
  users.users.root = {
    initialPassword = if isCI then "nixos" else "!";
    openssh.authorizedKeys.keys = [
      # Add your SSH keys here
    ];
  };

  # SSH configuration
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # Monitoring and logging
  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [
      "systemd"
      "filesystem"
      "meminfo"
      "netdev"
    ];
  };

  # Systemd configuration
  systemd = {
    services = {
      # Add custom services here
    };
    tmpfiles.rules = [
      "d /var/log/audit 0750 root root -"
      "d /var/lib/prometheus 0755 prometheus prometheus -"
    ];
  };

  # CI/CD specific settings
  environment.variables = {
    CI_MODE = toString isCI;
    LOG_LEVEL = logLevel;
  };

  # Automatic updates
  system.autoUpgrade = {
    enable = true;
    dates = "weekly";
    allowReboot = false;
  };

  # System monitoring
  services.prometheus.scrapeConfigs = [
    {
      job_name = "node";
      static_configs = [{
        targets = [ "localhost:9100" ];
      }];
    }
  ];
} 