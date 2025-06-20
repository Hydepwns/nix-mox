{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
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
    hostName = "hydebox"; # Change this to your hostname
    networkmanager.enable = true;

    # Optional: enable firewall
    firewall = {
      enable = true;
      allowedTCPPorts = [
        80 443  # HTTP/HTTPS for web-based messaging
        3478 3479  # STUN/TURN for WebRTC (Signal, Telegram calls)
        5349 5350  # STUN/TURN over TLS
        8080 8081  # Alternative ports for some messaging services
      ];
      allowedUDPPorts = [
        3478 3479  # STUN/TURN for WebRTC
        5349 5350  # STUN/TURN over TLS
        16384 16387  # WebRTC media ports
      ];
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

    # Desktop environment - choose one:
    desktopManager = {
      gnome.enable = true;
      # plasma5.enable = true;  # Alternative: KDE Plasma
      # xfce.enable = true;     # Alternative: XFCE (lightweight)
    };

    # Or use a window manager instead:
    # windowManager.i3.enable = true;
    # windowManager.awesome.enable = true;
  };

  # Enable sound (PipeWire is the modern default; PulseAudio is legacy)
  # Uncomment and adjust only if you know your hardware needs it
  # hardware.pulseaudio.enable = false;
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
    # driSupport = true; # Deprecated, no longer needed in recent NixOS
  };

  # Additional graphics support for gaming
  hardware.graphics.extraPackages = with pkgs; [
    vaapiVdpau
    libvdpau-va-gl
  ];

  # Enable 32-bit support for Wine
  hardware.graphics.extraPackages32 = with pkgs.pkgsi686Linux; [
    vaapiVdpau
    libvdpau-va-gl
  ];

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
  users.users.hyde = {  # Change "hyde" to your username
    isNormalUser = true;
    description = "Hyde";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    shell = pkgs.zsh;  # or pkgs.bash
  };

  # Add back the droo user for system access
  users.users.droo = {
    isNormalUser = true;
    description = "Droo";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    shell = pkgs.zsh;
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

    # Messaging and communication (primary focus: Signal and Telegram)
    signal-desktop
    telegram-desktop
    discord
    slack
    element-desktop
    whatsapp-for-linux

    # Video calling and conferencing
    zoom-us

    # Email clients
    thunderbird
    evolution

    # Wine and gaming support (64-bit enabled)
    wineWowPackages.stable
    winetricks
    dxvk
    vkd3d

    # Gaming performance tools
    gamemode
    mangohud
    vulkan-tools
    vulkan-validation-layers
    vulkan-headers
    vulkan-loader
    vulkan-extension-layer
    vulkan-utility-libraries

    # Additional gaming platforms
    lutris
    heroic

    # From nix-mox (access the packages)
    inputs.nix-mox.packages.${pkgs.system}.proxmox-update
    inputs.nix-mox.packages.${pkgs.system}.vzdump-backup
    inputs.nix-mox.packages.${pkgs.system}.zfs-snapshot
    inputs.nix-mox.packages.${pkgs.system}.nixos-flake-update

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

  # Docker (optional)
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
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

    # Messaging and communication services
    dbus.enable = true;
    gvfs.enable = true;

    # Configure dbus packages for messaging apps
    dbus.packages = with pkgs; [
      signal-desktop
      telegram-desktop
      discord
      slack
    ];
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
