{ config, pkgs, inputs, self, ... }:

{
  imports = [
    ../hardware/hardware-configuration.nix
  ];

  # Boot loader
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    timeout = 3;
  };

  # Kernel (optional: use latest)
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Networking
  networking = {
    hostName = "nixos"; # Change this to your hostname
    networkmanager.enable = true;

    # Optional: enable firewall
    firewall = {
      enable = true;
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
    };
  };

  # Time zone and locale
  time.timeZone = "America/New_York"; # Change to your timezone
  i18n.defaultLocale = "en_US.UTF-8";

  # IMPORTANT: Display configuration to prevent CLI lock
  services.xserver = {
    enable = true;

    # Display manager - choose one:
    displayManager = {
      lightdm.enable = true;
      # sddm.enable = true;  # Alternative: KDE's display manager
      # gdm.enable = true;   # Alternative: GNOME's display manager
    };

    # Or use a window manager instead:
    # windowManager.i3.enable = true;
    # windowManager.awesome.enable = true;
  };

  # Desktop environment - choose one:
  services.desktopManager = {
    gnome.enable = true;
    # plasma5.enable = true;  # Alternative: KDE Plasma
    # xfce.enable = true;     # Alternative: XFCE (lightweight)
  };

  # Enable sound
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Graphics drivers
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # NVIDIA drivers (uncomment if you have NVIDIA GPU)
  # services.xserver.videoDrivers = [ "nvidia" ];
  # hardware.nvidia = {
  #   modesetting.enable = true;
  #   powerManagement.enable = true;
  #   open = false;
  #   nvidiaSettings = true;
  #   package = config.boot.kernelPackages.nvidiaPackages.stable;
  # };

  # AMD drivers (usually work out of the box, but you can be explicit)
  # services.xserver.videoDrivers = [ "amdgpu" ];

  # Users
  users.users.droo = {  # Change "droo" to your username
    isNormalUser = true;
    description = "Droo";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    shell = pkgs.zsh;  # or pkgs.bash
  };

  # Enable sudo
  security.sudo.enable = true;

  # System packages
  environment.systemPackages = with pkgs; [
    # Essential tools
    vim
    wget
    git
    htop
    firefox

    # Terminal emulators
    kitty
    alacritty

    # From nix-mox (access the packages)
    self.packages.${pkgs.system}.proxmox-update
    self.packages.${pkgs.system}.vzdump-backup
    self.packages.${pkgs.system}.zfs-snapshot
    self.packages.${pkgs.system}.nixos-flake-update

    # Development tools
    vscode
    docker
    docker-compose
  ];

  # Programs
  programs = {
    zsh.enable = true;
    git.enable = true;

    # Steam for gaming (since nix-mox has gaming focus)
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };
  };

  # Services
  services = {
    # SSH (optional)
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };
  };

  # Docker (optional)
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  # Nix configuration
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;

      # Use nix-mox's binary caches
      substituters = [
        "https://cache.nixos.org"
        "https://hydepwns.cachix.org"
        "https://nix-mox.cachix.org"
      ];

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "hydepwns.cachix.org-1:xg8huKdwzBkLdkq5eCKenadhCROHIICGI9H6y3simJU="
        "nix-mox.cachix.org-1:MVJZxC7ZyRFAxVsxDuq0nmMRxlTIt5nFFm4Ur10ZCI4="
      ];
    };

    # Garbage collection
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # were taken. Don't change this unless you know what you're doing.
  system.stateVersion = "23.11"; # Did you read the comment?
}
