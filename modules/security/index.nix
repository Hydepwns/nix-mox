{ pkgs, config, lib, ... }:

let
  # Fail2ban configuration
  fail2ban = { config, lib, pkgs, ... }: {
    options.services.fail2ban = {
      enable = lib.mkEnableOption "Enable fail2ban intrusion prevention";
      maxretry = lib.mkOption {
        type = lib.types.int;
        default = 3;
        description = "Maximum number of failed attempts before banning";
      };
      bantime = lib.mkOption {
        type = lib.types.int;
        default = 3600;
        description = "Ban time in seconds";
      };
      findtime = lib.mkOption {
        type = lib.types.int;
        default = 600;
        description = "Time window for counting failed attempts";
      };
      jails = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "sshd" "nginx-http-auth" ];
        description = "Jails to enable";
      };
    };

    config = let
      cfg = config.services.fail2ban;
    in lib.mkIf cfg.enable {
      services.fail2ban = {
        enable = true;
        maxretry = cfg.maxretry;
        bantime = cfg.bantime;
        findtime = cfg.findtime;
        jails = cfg.jails;
      };
    };
  };

  # UFW firewall configuration
  ufw = { config, lib, pkgs, ... }: {
    options.services.ufw = {
      enable = lib.mkEnableOption "Enable UFW firewall";
      defaultIncomingPolicy = lib.mkOption {
        type = lib.types.enum [ "deny" "allow" "reject" ];
        default = "deny";
        description = "Default policy for incoming connections";
      };
      defaultOutgoingPolicy = lib.mkOption {
        type = lib.types.enum [ "deny" "allow" "reject" ];
        default = "allow";
        description = "Default policy for outgoing connections";
      };
      rules = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "UFW rules to add";
      };
      allowedPorts = lib.mkOption {
        type = lib.types.listOf lib.types.int;
        default = [ 22 80 443 ];
        description = "Ports to allow incoming connections";
      };
    };

    config = let
      cfg = config.services.ufw;
    in lib.mkIf cfg.enable {
      services.ufw = {
        enable = true;
        defaultIncomingPolicy = cfg.defaultIncomingPolicy;
        defaultOutgoingPolicy = cfg.defaultOutgoingPolicy;
        rules = cfg.rules;
      };

      # Add allowed ports
      services.ufw.rules = lib.mkAfter (lib.forEach cfg.allowedPorts (port: "allow ${toString port}"));
    };
  };

  # SSL/TLS configuration
  ssl = { config, lib, pkgs, ... }: {
    options.security.ssl = {
      enable = lib.mkEnableOption "Enable SSL/TLS security";
      certificates = lib.mkOption {
        type = lib.types.listOf lib.types.path;
        default = [];
        description = "SSL certificates to install";
      };
      privateKeys = lib.mkOption {
        type = lib.types.listOf lib.types.path;
        default = [];
        description = "SSL private keys to install";
      };
      dhparam = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "DH parameters file";
      };
      ocspStapling = lib.mkDefault true;
      hsts = lib.mkDefault true;
      modernCiphers = lib.mkDefault true;
    };

    config = let
      cfg = config.security.ssl;
    in lib.mkIf cfg.enable {
      # Install certificates
      security.pki.certificateFiles = cfg.certificates;

      # Configure SSL settings for nginx
      services.nginx = lib.mkIf config.services.nginx.enable {
        recommendedTlsSettings = cfg.modernCiphers;
        recommendedGzipSettings = true;
        recommendedOptimisation = true;
        recommendedProxySettings = true;
      };
    };
  };

  # AppArmor configuration
  apparmor = { config, lib, pkgs, ... }: {
    options.security.apparmor = {
      enable = lib.mkEnableOption "Enable AppArmor mandatory access control";
      enableCache = lib.mkDefault true;
      killUnconfined = lib.mkDefault false;
      packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [];
        description = "Packages to enable AppArmor for";
      };
    };

    config = let
      cfg = config.security.apparmor;
    in lib.mkIf cfg.enable {
      security.apparmor = {
        enable = true;
        enableCache = cfg.enableCache;
        killUnconfined = cfg.killUnconfined;
        packages = cfg.packages;
      };
    };
  };

  # Audit configuration
  audit = { config, lib, pkgs, ... }: {
    options.security.audit = {
      enable = lib.mkEnableOption "Enable system auditing";
      rules = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Audit rules to add";
      };
      logFile = lib.mkOption {
        type = lib.types.str;
        default = "/var/log/audit/audit.log";
        description = "Audit log file location";
      };
    };

    config = let
      cfg = config.security.audit;
    in lib.mkIf cfg.enable {
      services.auditd = {
        enable = true;
        rules = cfg.rules;
        logFile = cfg.logFile;
      };
    };
  };

  # SELinux configuration
  selinux = { config, lib, pkgs, ... }: {
    options.security.selinux = {
      enable = lib.mkEnableOption "Enable SELinux mandatory access control";
      state = lib.mkOption {
        type = lib.types.enum [ "enforcing" "permissive" "disabled" ];
        default = "enforcing";
        description = "SELinux state";
      };
      type = lib.mkOption {
        type = lib.types.enum [ "targeted" "minimum" "mls" ];
        default = "targeted";
        description = "SELinux policy type";
      };
    };

    config = let
      cfg = config.security.selinux;
    in lib.mkIf cfg.enable {
      security.selinux = {
        enable = true;
        state = cfg.state;
        type = cfg.type;
      };
    };
  };

  # Kernel security configuration
  kernel = { config, lib, pkgs, ... }: {
    options.security.kernel = {
      enable = lib.mkEnableOption "Enable kernel security features";
      lockdown = lib.mkOption {
        type = lib.types.enum [ "none" "integrity" "confidentiality" ];
        default = "integrity";
        description = "Kernel lockdown mode";
      };
      yama = lib.mkDefault true;
      seccomp = lib.mkDefault true;
      stackProtector = lib.mkDefault true;
      aslr = lib.mkDefault true;
    };

    config = let
      cfg = config.security.kernel;
    in lib.mkIf cfg.enable {
      boot.kernelParams = lib.mkIf (cfg.lockdown != "none") [ "lockdown=${cfg.lockdown}" ];

      security.yama = lib.mkIf cfg.yama {
        enable = true;
      };

      security.seccomp = lib.mkIf cfg.seccomp {
        enable = true;
      };
    };
  };

  # Network security configuration
  network = { config, lib, pkgs, ... }: {
    options.security.network = {
      enable = lib.mkEnableOption "Enable network security features";
      ipv6Privacy = lib.mkDefault true;
      tcpHardening = lib.mkDefault true;
      icmpRateLimit = lib.mkDefault true;
      synCookies = lib.mkDefault true;
      rpFilter = lib.mkDefault true;
    };

    config = let
      cfg = config.security.network;
    in lib.mkIf cfg.enable {
      # IPv6 privacy extensions
      networking.tempAddresses = lib.mkIf cfg.ipv6Privacy "enabled";

      # TCP hardening
      boot.kernelParams = lib.mkIf cfg.tcpHardening [
        "net.ipv4.tcp_syncookies=1"
        "net.ipv4.tcp_timestamps=0"
        "net.ipv4.tcp_max_syn_backlog=2048"
      ];

      # ICMP rate limiting
      boot.kernelParams = lib.mkIf cfg.icmpRateLimit [
        "net.ipv4.icmp_ratelimit=100"
        "net.ipv4.icmp_ratemask=88089"
      ];

      # Reverse path filtering
      boot.kernelParams = lib.mkIf cfg.rpFilter [
        "net.ipv4.conf.all.rp_filter=1"
        "net.ipv4.conf.default.rp_filter=1"
      ];
    };
  };

  # File system security
  filesystem = { config, lib, pkgs, ... }: {
    options.security.filesystem = {
      enable = lib.mkEnableOption "Enable file system security features";
      noexec = lib.mkDefault true;
      nosuid = lib.mkDefault true;
      nodev = lib.mkDefault false;
      readOnly = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Directories to mount read-only";
      };
    };

    config = let
      cfg = config.security.filesystem;
    in lib.mkIf cfg.enable {
      # Add security options to file systems
      fileSystems = lib.mapAttrs' (name: value: lib.nameValuePair name (value // {
        options = (value.options or []) ++
          (lib.optionals cfg.noexec [ "noexec" ]) ++
          (lib.optionals cfg.nosuid [ "nosuid" ]) ++
          (lib.optionals cfg.nodev [ "nodev" ]);
      })) config.fileSystems;

      # Read-only mounts
      fileSystems = lib.mkIf (cfg.readOnly != []) (lib.listToAttrs (lib.forEach cfg.readOnly (dir: lib.nameValuePair dir {
        device = "tmpfs";
        fsType = "tmpfs";
        options = [ "ro" "noexec" "nosuid" "nodev" "size=1M" ];
      })));
    };
  };

  # User security configuration
  users = { config, lib, pkgs, ... }: {
    options.security.users = {
      enable = lib.mkEnableOption "Enable user security features";
      passwordMinLength = lib.mkOption {
        type = lib.types.int;
        default = 12;
        description = "Minimum password length";
      };
      passwordComplexity = lib.mkDefault true;
      lockoutAttempts = lib.mkOption {
        type = lib.types.int;
        default = 5;
        description = "Number of failed attempts before account lockout";
      };
      lockoutTime = lib.mkOption {
        type = lib.types.int;
        default = 900;
        description = "Account lockout time in seconds";
      };
    };

    config = let
      cfg = config.security.users;
    in lib.mkIf cfg.enable {
      security.pam.services = lib.mkIf cfg.passwordComplexity {
        login.pamAuth = [ "pam_pwquality.so" ];
        sudo.pamAuth = [ "pam_pwquality.so" ];
        passwd.pamAuth = [ "pam_pwquality.so" ];
      };

      security.pam.pwquality = {
        enable = cfg.passwordComplexity;
        settings = {
          minlen = cfg.passwordMinLength;
          minclass = 3;
          maxrepeat = 3;
          geoscheck = 1;
        };
      };
    };
  };

in {
  # Export all security modules
  inherit fail2ban ufw ssl apparmor audit selinux kernel network filesystem users;

  # Combined security configuration
  all = { config, lib, pkgs, ... }: {
    imports = [
      (fail2ban { inherit config lib pkgs; })
      (ufw { inherit config lib pkgs; })
      (ssl { inherit config lib pkgs; })
      (apparmor { inherit config lib pkgs; })
      (audit { inherit config lib pkgs; })
      (selinux { inherit config lib pkgs; })
      (kernel { inherit config lib pkgs; })
      (network { inherit config lib pkgs; })
      (filesystem { inherit config lib pkgs; })
      (users { inherit config lib pkgs; })
    ];
  };
}
