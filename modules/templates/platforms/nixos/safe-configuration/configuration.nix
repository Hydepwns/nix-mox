{ config, pkgs, inputs, ... }:

{
  imports = [
    # Import the base common configuration
    ../../base/common.nix

    # Import hardware configuration (will use template if actual doesn't exist)
    ../../../config/hardware/hardware-configuration.nix
  ];

  # Basic system configuration
  networking.hostName = "nixos-safe";
  time.timeZone = "UTC";

  # Enable sudo
  security.sudo.enable = true;

  # Create a default user
  users.users.default = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
  };

  # Enable SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # Enable firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 80 443 ];
  };

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    htop
    git
    # Include nix-mox packages
    inputs.nix-mox.packages.${pkgs.system}.proxmox-update
    inputs.nix-mox.packages.${pkgs.system}.vzdump-backup
    inputs.nix-mox.packages.${pkgs.system}.zfs-snapshot
    inputs.nix-mox.packages.${pkgs.system}.nixos-flake-update
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}
