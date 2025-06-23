{ config, lib, pkgs, ... }:

let
  # Import error handling module
  errorHandling = import ../../error-handling.nix { inherit config lib pkgs; };

  # Service configuration
  servicesCfg = config.services.nix-mox.services;
  tailscaleCfg = config.services.nix-mox.tailscale;
in
{
  options.services.nix-mox.tailscale = {
    enable = lib.mkEnableOption "Enable Tailscale service management via nix-mox";

    authKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to a file containing the Tailscale auth key.
        Using this option will enable Tailscale and configure the auth key for you.
        This is useful for headless servers that need to be pre-authorized.
      '';
    };

    enableHealthChecks = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Tailscale health checks and status monitoring";
    };

    enableLogging = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable detailed Tailscale operation logging";
    };
  };

  config = lib.mkIf (servicesCfg.enable && tailscaleCfg.enable) {
    services.tailscale.enable = true;

    # If an auth key file is provided, set up the one-shot service to authenticate.
    systemd.services.tailscale-auth = lib.mkIf (tailscaleCfg.authKeyFile != null) {
      description = "Tailscale Authentication";
      wantedBy = [ "multi-user.target" ];
      after = [ "tailscaled.service" ];
      requires = [ "tailscaled.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = servicesCfg.defaultUser;
        Group = servicesCfg.defaultGroup;
        ExecStart = pkgs.writeScript "tailscale-auth" ''
          #!${pkgs.bash}/bin/bash
          set -e

          # Source error handling
          . ${errorHandling}/bin/template-error-handler

          # Validate auth key file exists
          if [ ! -f "${tailscaleCfg.authKeyFile}" ]; then
            ${errorHandling.logMessage} "ERROR" "Tailscale auth key file ${tailscaleCfg.authKeyFile} does not exist"
            exit 1
          fi

          # Check if already authenticated
          if [ -f "/var/lib/tailscale/tailscaled.state" ]; then
            ${errorHandling.logMessage} "INFO" "Tailscale already authenticated, skipping auth key setup"
            exit 0
          fi

          # Authenticate with Tailscale
          ${pkgs.tailscale}/bin/tailscale up --authkey-file=${tailscaleCfg.authKeyFile}

          # Validate authentication
          if ! ${pkgs.tailscale}/bin/tailscale status >/dev/null 2>&1; then
            ${errorHandling.logMessage} "ERROR" "Tailscale authentication failed"
            exit 1
          fi

          ${errorHandling.logMessage} "INFO" "Tailscale authentication successful"
        '';
        # This service should only run once if the node is not yet authenticated.
        # We check for the presence of the tailscale state file.
        ConditionPathExists = "!/var/lib/tailscale/tailscaled.state";
      };
    };

    # Add health check service if enabled
    systemd.services.tailscale-health = lib.mkIf tailscaleCfg.enableHealthChecks {
      description = "Tailscale Health Check";
      serviceConfig = {
        Type = "oneshot";
        User = servicesCfg.defaultUser;
        Group = servicesCfg.defaultGroup;
        ExecStart = pkgs.writeScript "tailscale-health" ''
          #!${pkgs.bash}/bin/bash
          set -e

          # Source error handling
          . ${errorHandling}/bin/template-error-handler

          # Check if Tailscale is running
          if ! systemctl is-active --quiet tailscaled; then
            ${errorHandling.logMessage} "ERROR" "Tailscale daemon is not running"
            exit 1
          fi

          # Check Tailscale status
          if ! ${pkgs.tailscale}/bin/tailscale status >/dev/null 2>&1; then
            ${errorHandling.logMessage} "ERROR" "Tailscale is not connected"
            exit 1
          fi

          # Get connection status
          status=$(${pkgs.tailscale}/bin/tailscale status --json | ${pkgs.jq}/bin/jq -r '.BackendState')
          if [ "$status" != "Running" ]; then
            ${errorHandling.logMessage} "WARNING" "Tailscale backend state is $status"
          else
            ${errorHandling.logMessage} "INFO" "Tailscale is running and connected"
          fi
        '';
      };
    };

    # Add health check timer
    systemd.timers.tailscale-health = lib.mkIf tailscaleCfg.enableHealthChecks {
      description = "Tailscale Health Check Timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*/5:00"; # Every 5 minutes
        Persistent = true;
      };
    };
  };
}
