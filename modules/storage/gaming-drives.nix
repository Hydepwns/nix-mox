{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.storage.gamingDrives;
in
{
  options.storage.gamingDrives = {
    enable = mkEnableOption "optimized storage configuration for gaming drives";

    drives = mkOption {
      type = types.listOf (types.submodule {
        options = {
          mountPoint = mkOption {
            type = types.str;
            example = "/mnt/games";
            description = "Mount point for the gaming drive";
          };

          device = mkOption {
            type = types.str;
            example = "/dev/disk/by-uuid/12345678-1234-1234-1234-123456789012";
            description = "Device path or UUID for the drive";
          };

          fsType = mkOption {
            type = types.str;
            default = "ext4";
            description = "Filesystem type";
          };

          label = mkOption {
            type = types.str;
            default = "";
            example = "GameDrive";
            description = "Optional label for the drive";
          };
        };
      });
      default = [ ];
      description = "List of gaming storage drives to configure";
    };

    autoDetect = mkOption {
      type = types.bool;
      default = true;
      description = "Automatically detect and configure additional drives for gaming";
    };
  };

  config = mkIf cfg.enable {
    # Configure each gaming drive with proper mount options
    fileSystems = listToAttrs (map
      (drive: {
        name = drive.mountPoint;
        value = {
          device = drive.device;
          fsType = drive.fsType;
          options = [
            "defaults"
            "users" # Allow normal users to mount
            "exec" # CRITICAL: Allow execution (required for EasyAntiCheat)
            "nofail" # Don't fail boot if drive is missing
            "x-systemd.device-timeout=5" # Reduce timeout for missing drives
            "noatime" # Improve performance by not updating access times
            "nodiratime" # Don't update directory access times
          ] ++ (optionals (drive.fsType == "ntfs" || drive.fsType == "ntfs-3g") [
            "big_writes" # Improve NTFS write performance
            "windows_names" # Support Windows naming conventions
          ]);
        };
      })
      cfg.drives);

    # Create mount points
    systemd.tmpfiles.rules = map
      (drive:
        "d ${drive.mountPoint} 0755 root root -"
      )
      cfg.drives;

    # Add udev rules for better game drive handling
    services.udev.extraRules = ''
      # Optimize I/O scheduler for gaming drives
      ACTION=="add|change", KERNEL=="sd[a-z]", SUBSYSTEM=="block", ENV{ID_FS_LABEL}=="Game*", ATTR{queue/scheduler}="mq-deadline"
      ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", SUBSYSTEM=="block", ENV{ID_FS_LABEL}=="Game*", ATTR{queue/scheduler}="none"
      
      # Set read-ahead for gaming drives
      ACTION=="add|change", KERNEL=="sd[a-z]", SUBSYSTEM=="block", ENV{ID_FS_LABEL}=="Game*", ATTR{queue/read_ahead_kb}="2048"
      ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", SUBSYSTEM=="block", ENV{ID_FS_LABEL}=="Game*", ATTR{queue/read_ahead_kb}="2048"
    '';

    # Add helpful aliases for managing game drives
    environment.shellAliases = {
      "game-drives" = "df -h | grep -E '${concatMapStringsSep "|" (d: d.mountPoint) cfg.drives}'";
      "game-space" = "du -sh ${concatMapStringsSep " " (d: d.mountPoint) cfg.drives} 2>/dev/null";
    };

    # Ensure Steam and other game launchers can access the drives
    environment.systemPackages = with pkgs; [
      ntfs3g # NTFS support for Windows drives
      exfat # exFAT support
      gnome.gvfs # Better drive management
    ];
  };
}
