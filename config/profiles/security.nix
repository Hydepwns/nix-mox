# Security Profile
# Security hardening configuration shared across templates
{ config, pkgs, ... }:
{
  # Security configuration
  security = {
    # Sudo configuration
    sudo = {
      enable = true;
      wheelNeedsPassword = true;
    };

    # Password quality (using proper PAM configuration)
    # Note: PAM configuration requires more specific module setup
    # Commented out for now to avoid conflicts
    # pam.services = {
    #   login.passwordAuth = {
    #     password = "requisite pam_pwquality.so retry=3 minlen=8";
    #   };
    #   sudo.passwordAuth = {
    #     password = "requisite pam_pwquality.so retry=3 minlen=8";
    #   };
    # };

    # Password policy settings (commented out - need correct module)
    # loginDefs = {
    #   passwordMaxDays = 90;
    #   passwordMinDays = 1;
    #   passwordWarnAge = 7;
    # };

    # AppArmor
    apparmor = {
      enable = true;
      killUnconfinedConfinables = true;
    };

    # Audit
    audit = {
      enable = true;
      rules = [
        "-w /etc/passwd -p wa -k identity"
        "-w /etc/group -p wa -k identity"
        "-w /etc/shadow -p wa -k identity"
        "-w /etc/sudoers -p wa -k scope"
        "-w /var/log/auth.log -p wa -k authentication"
      ];
    };

    # Kernel security
    protectKernelImage = true;
    lockKernelModules = true;
  };

  # Firewall configuration
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ ];
    allowedUDPPorts = [ ];
    logRefusedConnections = true;
  };

  # SSH security
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      PubkeyAuthentication = true;
      AuthorizedKeysFile = ".ssh/authorized_keys";
      # Protocol = 2; # Deprecated in newer SSH versions
      # HostKeyAlgorithms = "ssh-rsa,ssh-ed25519"; # Commented out - causes type conflicts
      # KexAlgorithms = "curve25519-sha256,curve25519-sha256@libssh.org"; # Commented out - causes type conflicts
      # Ciphers = "chacha20-poly1305@openssh.com,aes256-gcm@openssh.com"; # Commented out - causes type conflicts
      # MACs = "hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com"; # Commented out - causes type conflicts
      X11Forwarding = false;
      AllowTcpForwarding = false;
      AllowAgentForwarding = false;
      MaxAuthTries = 3;
      MaxSessions = 2;
      ClientAliveInterval = 300;
      ClientAliveCountMax = 2;
    };
  };

  # System hardening
  boot.kernelParams = [
    "slab_nomerge"
    "slub_debug=FZP"
    "pti=on"
    "vsyscall=none"
    "debugfs=off"
    "oops=panic"
    "module.sig_unenforce=1"
    "lockdown=confidentiality"
  ];

  # Environment security
  environment.variables = {
    # Disable core dumps
    NOCOREDUMP = "1";

    # Secure umask
    UMASK = "077";
  };

  # Systemd security and user restrictions
  systemd = {
    services = {
      # Disable core dumps
      "systemd-coredump".enable = false;
    };
    
    # Global systemd security defaults (adjusted for GUI compatibility)
    extraConfig = ''
      DefaultLimitCORE=0
      DefaultLimitNOFILE=2048
      DefaultLimitNPROC=1024
    '';
    
    # User session restrictions (adjusted for GUI compatibility)
    user.extraConfig = ''
      DefaultLimitCORE=0
      DefaultLimitNOFILE=2048
      DefaultLimitNPROC=512
    '';
  };

  # User and group security (allow mutable users for desktop compatibility)
  users.mutableUsers = true;
  
  # Additional security limits (adjusted for desktop environments)
  security.pam.loginLimits = [
    { domain = "*"; type = "hard"; item = "core"; value = "0"; }
    { domain = "*"; type = "hard"; item = "nproc"; value = "1024"; }
    { domain = "*"; type = "hard"; item = "nofile"; value = "2048"; }
    { domain = "wheel"; type = "hard"; item = "nproc"; value = "2048"; }
    { domain = "wheel"; type = "hard"; item = "nofile"; value = "8192"; }
  ];

  # Kernel module security
  boot.blacklistedKernelModules = [
    "dccp"
    "sctp"
    "rds"
    "tipc"
  ];
}
