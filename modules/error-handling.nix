{ config, lib, pkgs, ... }:

let
  errorHandler = pkgs.nix-mox.error-handling;
in {
  options = {
    services.nix-mox.error-handling = {
      enable = lib.mkEnableOption "Enable nix-mox error handling";
    };
  };

  config = lib.mkIf config.services.nix-mox.error-handling.enable {
    environment.systemPackages = [ errorHandler ];
  };

  # Export functions that wrap the shell script
  handleError = code: message: ''
    ${errorHandler}/bin/template-error-handler error ${toString code} "${message}"
  '';

  logMessage = level: message: ''
    ${errorHandler}/bin/template-error-handler ${level} "${message}"
  '';
} 