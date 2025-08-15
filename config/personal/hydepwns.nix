# Hydepwns User Configuration
# Custom configuration for hydepwns user
{ config, pkgs, ... }:
let
  lib = pkgs.lib;
  # Personal settings for hydepwns
  personal = {
    username = "hydepwns";
    email = "drew@axol.io";
    timezone = "Europe/Madrid";
    hostname = "nixos";
    gitUsername = "hydepwns";
    gitEmail = "drew@axol.io";
  };
 in
{
  # System user configuration for hydepwns (commented out to avoid conflicts)
  # users.users.${personal.username} = {
  #   isNormalUser = true;
  #   description = "Hydepwns User";
  #   extraGroups = [ "wheel" "networkmanager" "video" "audio" "docker" "libvirtd" "kvm" "vboxusers" "lxd" "qemu-libvirtd" ];
  #   shell = pkgs.zsh;
  #   openssh.authorizedKeys.keyFiles = [ ./keys/hydepwns.pub ];
  #   # No password set here; use existing accounts or set hashedPassword via secrets.
  # };

  # Preserve the current nixos user to avoid lockout
  # IMPORTANT: This prevents password changes on rebuild
  users.users.nixos = {
    isNormalUser = true;
    description = "NixOS User";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "docker" "libvirtd" "kvm" "vboxusers" "lxd" "qemu-libvirtd" ];
    shell = pkgs.zsh;
    uid = 1000;
    home = "/home/nixos";
    openssh.authorizedKeys.keyFiles = [ ./keys/hydepwns.pub ];
    # CRITICAL: Don't set password here - let the existing password persist
    # This prevents NixOS from generating a new random password
  };

  # System configuration
  networking.hostName = lib.mkForce personal.hostname;
  time.timeZone = lib.mkForce personal.timezone;

  # Virtualization services
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true;
      };
    };
    spiceUSBRedirection.enable = true;
  };

  # Additional system packages
  environment.systemPackages = with pkgs; [
    # Add any packages you want to install here
  ];
}
