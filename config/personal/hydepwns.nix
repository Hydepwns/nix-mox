# Hydepwns User Configuration
# Custom configuration for hydepwns user
{ config, pkgs, ... }:
let
  lib = pkgs.lib;
  # Personal settings for hydepwns
  personal = {
    username = "hydepwns";
    email = "andrewtehsailor@gmail.com";
    timezone = "Europe/Madrid";
    hostname = "nixos";
    gitUsername = "hydepwns";
    gitEmail = "andrewtehsailor@gmail.com";
  };
 in
{
  # System user configuration - keep droo user but add hydepwns
  users.users.droo = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
  };

  users.users.${personal.username} = {
    isNormalUser = true;
    description = "Hydepwns User";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "docker" "libvirtd" "kvm" "vboxusers" "lxd" "qemu-libvirtd" ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keyFiles = [ ./keys/hydepwns.pub ];
    # No password set here; use existing accounts or set hashedPassword via secrets.
  };

  # Temporary recovery account to avoid lockout when migrating users (disabled by default)
  users.users.nixos = lib.mkIf (builtins.getEnv "NIXMOX_ENABLE_TEMP_USER" == "1") {
    isNormalUser = true;
    description = "Temporary recovery user";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.zsh;
    uid = 1000;
    home = "/home/nixos";
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
    
  ];
}
