# modules/tailscale.nix
{ config, lib, pkgs, ... }:

let
  cfg = config.services.nix-mox.tailscale;
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
  };

  config = lib.mkIf cfg.enable {
    services.tailscale.enable = true;

    # If an auth key file is provided, set up the one-shot service to authenticate.
    systemd.services.tailscale-auth = lib.mkIf (cfg.authKeyFile != null) {
      description = "Tailscale Authentication";
      wantedBy = [ "multi-user.target" ];
      after = [ "tailscaled.service" ];
      requires = [ "tailscaled.service" ];
      script = ''
        ${pkgs.tailscale}/bin/tailscale up --authkey-file=${cfg.authKeyFile}
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        # This service should only run once if the node is not yet authenticated.
        # We check for the presence of the tailscale state file.
        ConditionPathExists = "!/var/lib/tailscale/tailscaled.state";
      };
    };
  };
}
