{ config, pkgs, inputs, ... }:
{
  imports = [
    ./common/networking.nix
    ./common/display.nix
    ./common/sound.nix
    ./common/graphics.nix
    ./common/packages.nix
    ./common/programs.nix
    ./common/services.nix
    ./common/nix-settings.nix
    ./common/system.nix
    ./common/messaging.nix
  ];

  # Boot loader
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    timeout = 3;
  };

  # Kernel (optional: use latest)
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Networking (hostName should be set in the importing config)
  networking = {
    networkmanager.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
    };
  };

  # Time zone and locale (should be set in the importing config)
  i18n.defaultLocale = "en_US.UTF-8";

  # Display configuration
  services.xserver = {
    enable = true;
    services.desktopManager.gnome.enable = true;
  };

  # Display manager (updated for newer NixOS)
  services.displayManager.sddm.enable = true;

  # Sound
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Graphics drivers (updated for newer NixOS)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Enable sudo
  security.sudo.enable = true;

  # System packages (add user/system-specific packages in the importing config)
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    htop
    firefox
    kitty
    alacritty
    inputs.nix-mox.packages.${pkgs.system}.proxmox-update
    inputs.nix-mox.packages.${pkgs.system}.vzdump-backup
    inputs.nix-mox.packages.${pkgs.system}.zfs-snapshot
    inputs.nix-mox.packages.${pkgs.system}.nixos-flake-update
    vscode
    docker
    docker-compose
  ];

  # Programs
  programs = {
    zsh.enable = true;
    git.enable = true;
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };
  };

  # Services
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };
  services.docker = {
    enable = true;
    enableOnBoot = true;
  };

  # Nix configuration
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
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
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # This value determines the NixOS release from which the default settings for stateful data, like file locations and database versions were taken.
  system.stateVersion = "23.11";
}
