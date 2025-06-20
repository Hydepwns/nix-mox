{ config, lib, pkgs, ... }:

let
  # Import error handling module
  errorHandling = import ../../error-handling.nix { inherit config lib pkgs; };
in
{
  options.services.nix-mox.storage = {
    enable = lib.mkEnableOption "Enable storage management modules";

    # Common storage options
    defaultBackupDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/storage/backups";
      description = "Default directory for storage backups";
    };

    enableMonitoring = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable storage monitoring and health checks";
    };

    enableLogging = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable detailed storage operation logging";
    };
  };

  config = lib.mkIf config.services.nix-mox.storage.enable {
    # Add common storage packages
    environment.systemPackages = with pkgs; [
      # Basic storage tools
      smartmontools
      hdparm
      fio
      iostat
    ];
  };
}
