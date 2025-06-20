{ config, lib, pkgs, ... }:

let
  # Import error handling module
  errorHandling = import ../../error-handling.nix { inherit config lib pkgs; };
in
{
  options.services.nix-mox.services = {
    enable = lib.mkEnableOption "Enable service management modules";

    # Common service options
    enableLogging = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable detailed service operation logging";
    };

    enableHealthChecks = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable service health checks and validation";
    };

    defaultUser = lib.mkOption {
      type = lib.types.str;
      default = "root";
      description = "Default user for service operations";
    };

    defaultGroup = lib.mkOption {
      type = lib.types.str;
      default = "root";
      description = "Default group for service operations";
    };
  };

  config = lib.mkIf config.services.nix-mox.services.enable {
    # Add common service tools
    environment.systemPackages = with pkgs; [
      # Service management tools
      systemd
      jq
      curl
      wget
    ];
  };
}
