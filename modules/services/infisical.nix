{ config, lib, pkgs, self, system, ... }:

with lib;

let
  cfg = config.services.nix-mox.infisical;

  # Helper function to create a secret-fetching service for a given secrets set.
  createSecretService = name: secretsConfig: {
    name = "infisical-fetch-${name}";
    value = {
      description = "Fetch secrets for ${name} from Infisical";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        Group = "root";
        Environment = "INFISICAL_TOKEN_FILE=${cfg.tokenFile}";
        ExecStart = ''
          ${self.packages.${system}.infisical-cli}/bin/infisical export --project-id=${secretsConfig.project} --env=${secretsConfig.environment} --format=dotenv -o ${secretsConfig.path}
        '';
        PermissionsStartOnly = true;
      };
      path = [ pkgs.bash self.packages.${system}.infisical-cli ];
    };
  };

  # Helper function to create a systemd timer for a given secrets set.
  createSecretTimer = name: secretsConfig: {
    name = "infisical-fetch-${name}";
    value = {
      description = "Timer to periodically fetch secrets for ${name}";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = secretsConfig.update_timer.frequency;
        Unit = "infisical-fetch-${name}.service";
        Persistent = true;
      };
    };
  };

in
{
  options.services.nix-mox.infisical = {
    enable = mkEnableOption "Enable declarative secret management with Infisical";

    tokenFile = mkOption {
      type = types.path;
      description = "Path to a file containing the Infisical authentication token.";
      example = "/run/secrets/infisical-token";
    };

    secrets = mkOption {
      type = types.attrsOf (types.submodule ({ ... }: {
        options = {
          project = mkOption {
            type = types.str;
            description = "The Infisical Project ID to fetch secrets from.";
            example = "a1b2c3d4-e5f6-7890-a1b2-c3d4e5f67890";
          };
          environment = mkOption {
            type = types.str;
            description = "The environment (slug) within the Infisical project.";
            default = "prod";
            example = "staging";
          };
          path = mkOption {
            type = types.path;
            description = "The destination path for the fetched secrets file (in .env format).";
            example = "/run/secrets/my-app.env";
          };
          update_timer = {
            enable = mkEnableOption "Enable a recurring timer to refresh the secrets";
            frequency = mkOption {
              type = types.str;
              description = "How often to refresh the secrets (e.g., 'hourly', 'daily').";
              default = "daily";
            };
          };
        };
      }));
      default = {};
      description = "Attribute set defining the secrets to fetch from Infisical.";
      example = ''
        "my-app" = {
          project = "a1b2c3d4-e5f6-7890-a1b2-c3d4e5f67890";
          environment = "prod";
          path = "/run/secrets/my-app.env";
        };
        "grafana" = {
          project = "b2c3d4e5-f6a1-b2c3-d4e5-f6a1b2c3d4e5";
          environment = "staging";
          path = "/run/secrets/grafana.env";
          update_timer = {
            enable = true;
            frequency = "hourly";
          };
        };
      '';
    };
  };

  config = mkIf cfg.enable {
    # Create a systemd service for each configured secrets set.
    systemd.services = builtins.listToAttrs (
      map (name: createSecretService name cfg.secrets.${name}) (builtins.attrNames cfg.secrets)
    );

    # Create systemd timers for secrets sets with update_timer enabled.
    systemd.timers = builtins.listToAttrs (
      let
        setsWithTimers = filter (name: cfg.secrets.${name}.update_timer.enable) (builtins.attrNames cfg.secrets);
      in
        map (name: createSecretTimer name cfg.secrets.${name}) setsWithTimers
    );
  };
} 