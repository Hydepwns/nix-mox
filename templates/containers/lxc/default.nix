{ config, pkgs, ... }:
{
  imports = [];

  # Basic container settings
  networking.hostName = "nixos-lxc";
  networking.useDHCP = true;

  # Minimal user setup
  users.users.root = {
    initialPassword = "nixos"; # Change after first login
  };

  # Optionally enable SSH for remote access
  # services.openssh.enable = true;

  # Add more services or customizations as needed
} 