{ config, lib, pkgs, ... }:
{
  options.services.nix-mox.common = {
    enable = lib.mkEnableOption "Enable nix-mox common scripts and timers";
  };
  config = lib.mkIf config.services.nix-mox.common.enable {
    environment.systemPackages = [
      pkgs.nix-mox.proxmox-update
      pkgs.nix-mox.vzdump-backup
      pkgs.nix-mox.zfs-snapshot
      pkgs.nix-mox.nixos-flake-update
      pkgs.nix-mox.install
      pkgs.nix-mox.uninstall
    ];
    # Example: systemd timer for flake update
    systemd.timers.nixos-flake-update = {
      wantedBy = [ "timers.target" ];
      timerConfig.OnCalendar = "daily";
    };
    systemd.services.nixos-flake-update = {
      script = "${pkgs.nix-mox.nixos-flake-update}/bin/nixos-flake-update";
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
    };
  };
} 