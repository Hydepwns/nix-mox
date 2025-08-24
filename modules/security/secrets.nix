# Secrets management module using agenix
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.security.secrets;
in
{
  options.security.secrets = {
    enable = mkEnableOption "secrets management with agenix";

    keyFile = mkOption {
      type = types.path;
      default = "/etc/ssh/ssh_host_ed25519_key";
      description = "Path to the age identity file";
    };

    secretsDir = mkOption {
      type = types.path;
      default = "/run/agenix";
      description = "Directory where decrypted secrets are stored";
    };

    wifi = {
      enable = mkEnableOption "WiFi password management";

      networks = mkOption {
        type = types.listOf types.str;
        default = [ "home" "work" ];
        description = "WiFi networks to configure";
      };
    };

    ssh = {
      enable = mkEnableOption "SSH key management";

      keys = mkOption {
        type = types.listOf types.str;
        default = [ "github" "gitlab" ];
        description = "SSH keys to manage";
      };
    };

    services = {
      enable = mkEnableOption "service password management";

      passwords = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Service passwords to manage";
      };
    };
  };

  config = mkIf cfg.enable {
    # Configure agenix
    age = {
      identityPaths = [ cfg.keyFile ];

      secrets = mkMerge [
        # WiFi passwords
        (mkIf cfg.wifi.enable (
          listToAttrs (map
            (network: {
              name = "wifi-${network}";
              value = {
                file = ../../secrets/wifi-${network}.age;
                mode = "0400";
                owner = "root";
                group = "root";
              };
            })
            cfg.wifi.networks)
        ))

        # SSH keys
        (mkIf cfg.ssh.enable (
          listToAttrs (map
            (key: {
              name = "ssh-${key}";
              value = {
                file = ../../secrets/ssh-${key}.age;
                mode = "0600";
                owner = "gamer";
                group = "users";
                path = "/home/gamer/.ssh/id_${key}";
              };
            })
            cfg.ssh.keys)
        ))

        # User password
        {
          "gamer-password" = {
            file = ../../secrets/gamer-password.age;
            mode = "0400";
            owner = "root";
            group = "root";
          };
        }

        # Service passwords
        (mkIf cfg.services.enable (
          listToAttrs (map
            (service: {
              name = "${service}-password";
              value = {
                file = ../../secrets/${service}-password.age;
                mode = "0400";
                owner = "root";
                group = "root";
              };
            })
            cfg.services.passwords)
        ))
      ];
    };

    # Configure NetworkManager to use WiFi secrets
    networking.networkmanager = mkIf cfg.wifi.enable {
      enable = true;

      # WiFi configurations will be added after secrets are decrypted
      dispatcherScripts = [{
        type = "pre-up";
        source = pkgs.writeScript "load-wifi-passwords" ''
          #!/bin/sh
          ${concatMapStrings (network: ''
            if [ -f ${cfg.secretsDir}/wifi-${network} ]; then
              nmcli connection modify "${network}" wifi-sec.psk "$(cat ${cfg.secretsDir}/wifi-${network})"
            fi
          '') cfg.wifi.networks}
        '';
      }];
    };

    # Configure user password from secret
    users.users.gamer = mkIf (builtins.pathExists "${cfg.secretsDir}/gamer-password") {
      hashedPasswordFile = "${cfg.secretsDir}/gamer-password";
    };

    # Ensure SSH directory exists for managed keys
    systemd.tmpfiles.rules = mkIf cfg.ssh.enable [
      "d /home/gamer/.ssh 0700 gamer users -"
    ];

    # Helper script to initialize secrets
    environment.systemPackages = with pkgs; [
      agenix
      (writeScriptBin "secrets-init" ''
        #!/usr/bin/env bash
        set -e
        
        echo "🔐 Initializing secrets management..."
        
        # Check if age key exists
        if [ ! -f "${cfg.keyFile}" ]; then
          echo "⚠️  Age identity not found at ${cfg.keyFile}"
          echo "   Generating from SSH host key..."
          
          if [ -f /etc/ssh/ssh_host_ed25519_key ]; then
            sudo ssh-to-age -private-key < /etc/ssh/ssh_host_ed25519_key > /tmp/age-key.txt
            echo "✅ Age key generated. Public key:"
            ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub
          else
            echo "❌ No SSH host key found. Please run: sudo ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key"
            exit 1
          fi
        fi
        
        echo ""
        echo "📝 To encrypt a new secret:"
        echo "   agenix -e secrets/my-secret.age"
        echo ""
        echo "🔄 To rekey all secrets:"
        echo "   agenix -r"
      '')

      (writeScriptBin "secrets-edit" ''
        #!/usr/bin/env bash
        SECRET="$1"
        
        if [ -z "$SECRET" ]; then
          echo "Usage: secrets-edit <secret-name>"
          echo ""
          echo "Available secrets:"
          ls -1 ${../../secrets}/*.age 2>/dev/null | xargs -n1 basename | sed 's/\.age$//'
          exit 1
        fi
        
        agenix -e "${../../secrets}/$SECRET.age"
      '')

      (writeScriptBin "secrets-show" ''
        #!/usr/bin/env bash
        SECRET="$1"
        
        if [ -z "$SECRET" ]; then
          echo "Usage: secrets-show <secret-name>"
          echo ""
          echo "Available secrets:"
          ls -1 ${cfg.secretsDir}/* 2>/dev/null | xargs -n1 basename
          exit 1
        fi
        
        if [ -f "${cfg.secretsDir}/$SECRET" ]; then
          sudo cat "${cfg.secretsDir}/$SECRET"
        else
          echo "Secret not found: $SECRET"
          exit 1
        fi
      '')
    ];

    # Documentation
    environment.etc."secrets-readme.md".text = ''
      # Secrets Management with Agenix
      
      ## Quick Start
      
      1. Initialize secrets:
         ```
         secrets-init
         ```
      
      2. Edit a secret:
         ```
         secrets-edit wifi-home
         ```
      
      3. Show a decrypted secret:
         ```
         secrets-show wifi-home
         ```
      
      ## Adding New Secrets
      
      1. Add the secret definition to `/etc/nixos/secrets/secrets.nix`
      2. Create the encrypted file:
         ```
         agenix -e secrets/my-secret.age
         ```
      3. Reference it in your configuration:
         ```nix
         age.secrets.my-secret.file = ./secrets/my-secret.age;
         ```
      
      ## Rotating Secrets
      
      To rotate all secrets with new keys:
      ```
      cd /etc/nixos
      agenix -r
      ```
      
      ## Troubleshooting
      
      - Ensure your public key is in `secrets/secrets.nix`
      - Check that the age identity file exists at `${cfg.keyFile}`
      - Verify permissions on decrypted secrets in `${cfg.secretsDir}`
    '';
  };
}
