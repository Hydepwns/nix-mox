# Base Profile
# Common system configuration shared across all templates
{ config, pkgs, ... }:
{
  # Basic system configuration
  system.stateVersion = "23.11";

  # Essential system packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    git
    htop
    tree
    ripgrep
    fd
    bat
    exa
    fzf

    # Terminal emulator
    kitty
  ];

  # Basic programs
  programs = {
    zsh.enable = true;
    git.enable = true;
    vim.defaultEditor = true;
  };

  # Enable sudo
  security.sudo.enable = true;

  # Nix configuration
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;

      # Binary cache configuration
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

  # Basic networking
  networking = {
    networkmanager.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
    };
  };

  # Basic locale and time
  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Basic environment variables
  environment.variables = {
    EDITOR = "vim";
    PAGER = "less";
    TERM = "xterm-256color";
  };

  # Desktop environment
  services.desktopManager.plasma6.enable = true;
  # Optional: Enable GNOME instead of Plasma
  # services.desktopManager.gnome.enable = true;
  # Enable Wayland support for SDDM (Plasma 6)
  services.displayManager.sddm.wayland.enable = true;
}
