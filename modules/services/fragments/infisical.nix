{ config, lib, pkgs, self, system, ... }:

let
  # Import error handling module
  errorHandling = import ../../error-handling.nix { inherit config lib pkgs; };

  # Service configuration
  servicesCfg = config.services.nix-mox.services;
  infisicalCfg = config.services.nix-mox.infisical;

  # Helper function to create a secret-fetching service for a given secrets set.
  createSecretService = name: secretsConfig: {
    name = "infisical-fetch-${name}";
    value = {
      description = "Fetch secrets for ${name} from Infisical";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = servicesCfg.defaultUser;
        Group = servicesCfg.defaultGroup;
        Environment = "INFISICAL_TOKEN_FILE=${infisicalCfg.tokenFile}";
        ExecStart = pkgs.writeScript "infisical-fetch-${name}" ''
          #!${pkgs.bash}/bin/bash
          set -e

          # Source error handling
          . ${errorHandling}/bin/template-error-handler

          # Validate token file exists
          if [ ! -f "${infisicalCfg.tokenFile}" ]; then
            ${errorHandling.logMessage} "ERROR" "Infisical token file ${infisicalCfg.tokenFile} does not exist"
            exit 1
          fi

          # Create destination directory
          mkdir -p "$(dirname ${secretsConfig.path})"

          # Fetch secrets from Infisical
          ${self.packages.${system}.infisical-cli}/bin/infisical export \
            --project-id=${secretsConfig.project} \
            --env=${secretsConfig.environment} \
            --format=dotenv \
            -o ${secretsConfig.path}

          # Validate secrets file was created
          if [ ! -f "${secretsConfig.path}" ]; then
            ${errorHandling.logMessage} "ERROR" "Failed to create secrets file ${secretsConfig.path}"
            exit 1
          fi

          ${errorHandling.logMessage} "INFO" "Successfully fetched secrets for ${name} to ${secretsConfig.path}"
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
    enable = lib.mkEnableOption "Enable declarative secret management with Infisical";

    tokenFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to a file containing the Infisical authentication token.";
      example = "/run/secrets/infisical-token";
    };

    secrets = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule ({ ... }: {
        options = {
          project = lib.mkOption {
            type = lib.types.str;
            description = "The Infisical Project ID to fetch secrets from.";
            example = "a1b2c3d4-e5f6-7890-a1b2-c3d4e5f67890";
          };
          environment = lib.mkOption {
            type = lib.types.str;
            description = "The environment (slug) within the Infisical project.";
            default = "prod";
            example = "staging";
          };
          path = lib.mkOption {
            type = lib.types.path;
            description = "The destination path for the fetched secrets file (in .env format).";
            example = "/run/secrets/my-app.env";
          };
          update_timer = {
            enable = lib.mkEnableOption "Enable a recurring timer to refresh the secrets";
            frequency = lib.mkOption {
              type = lib.types.str;
              description = "How often to refresh the secrets (e.g., 'hourly', 'daily').";
              default = "daily";
            };
          };
        };
      }));
      default = { };
      description = "Attribute set defining the secrets to fetch from Infisical.";
      example = lib.literalExpression ''
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

  config = lib.mkIf (servicesCfg.enable && infisicalCfg.enable) {
    # Create a systemd service for each configured secrets set.
    systemd.services = builtins.listToAttrs (
      map (name: createSecretService name infisicalCfg.secrets.${name}) (builtins.attrNames infisicalCfg.secrets)
    );

    # Create systemd timers for secrets sets with update_timer enabled.
    systemd.timers = builtins.listToAttrs (
      let
        setsWithTimers = lib.filter (name: infisicalCfg.secrets.${name}.update_timer.enable) (builtins.attrNames infisicalCfg.secrets);
      in
      map (name: createSecretTimer name infisicalCfg.secrets.${name}) setsWithTimers
    );
  };
}
