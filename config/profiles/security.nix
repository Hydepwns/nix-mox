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

    # Password quality configuration (properly implemented)
    pam.services = {
      login.enableGnomeKeyring = true;
      sudo.enableGnomeKeyring = true;
    };

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
    # Advanced network security
    extraCommands = ''
      # Drop packets with invalid TCP flags
      iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL NONE -j DROP
      iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL ALL -j DROP
      
      # Rate limiting for SSH
      iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --set --name ssh --rsource
      iptables -A INPUT -p tcp --dport 22 -m recent --rcheck --seconds 60 --hitcount 4 --name ssh --rsource -j DROP
      
      # Block common attack patterns
      iptables -A INPUT -p tcp --tcp-flags ACK,FIN FIN -j DROP
      iptables -A INPUT -p tcp --tcp-flags ACK,PSH PSH -j DROP
      iptables -A INPUT -p tcp --tcp-flags ACK,URG URG -j DROP
    '';
  };

  # Additional network security settings
  boot.kernel.sysctl = {
    # Network security
    "net.ipv4.ip_forward" = false;
    "net.ipv4.conf.all.send_redirects" = false;
    "net.ipv4.conf.default.send_redirects" = false;
    "net.ipv4.conf.all.accept_redirects" = false;
    "net.ipv4.conf.default.accept_redirects" = false;
    "net.ipv4.conf.all.secure_redirects" = false;
    "net.ipv4.conf.default.secure_redirects" = false;
    "net.ipv4.icmp_echo_ignore_broadcasts" = true;
    "net.ipv4.icmp_ignore_bogus_error_responses" = true;
    "net.ipv4.conf.all.log_martians" = true;
    "net.ipv4.conf.default.log_martians" = true;
    "net.ipv4.tcp_syncookies" = true;
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
    # IPv6 security
    "net.ipv6.conf.all.accept_redirects" = false;
    "net.ipv6.conf.default.accept_redirects" = false;
    "net.ipv6.conf.all.accept_ra" = false;
    "net.ipv6.conf.default.accept_ra" = false;
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
    "lockdown=integrity"
    # Additional hardening
    "kptr_restrict=2"
    "kernel.dmesg_restrict=1"
    "kernel.unprivileged_bpf_disabled=1"
    "kernel.kexec_load_disabled=1"
    "net.core.bpf_jit_harden=2"
    "kernel.perf_event_paranoid=2"
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
