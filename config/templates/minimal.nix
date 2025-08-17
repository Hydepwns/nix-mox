# Minimal Template Configuration
# Basic system with essential tools only
{ config, pkgs, ... }:
{
  imports = [
    # Profiles removed - they don't exist
  ];

  # Minimal system configuration
  boot.loader.systemd-boot.enable = true;
  networking.networkmanager.enable = true;
  time.timeZone = "UTC";

  # Essential system packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    htop
    curl
    neovim

    # Terminal emulator
    kitty
  ];

  # Basic programs
  programs = {
    zsh.enable = true;
    git.enable = true;
  };

  # Enable sudo
  security.sudo.enable = true;

  # Nix configuration
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
}
