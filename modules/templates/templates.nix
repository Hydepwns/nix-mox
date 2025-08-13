{ config, lib, pkgs, ... }:

let
  # Template configuration
  cfg = config.services.nix-mox.templates;

  # Import template definitions
  monitoring = import ./definitions/monitoring.nix { inherit config lib pkgs; };
  windows-gaming = import ./definitions/windows-gaming.nix { inherit config lib pkgs; };

  # Template definitions
  templates = {
    inherit monitoring;
    inherit windows-gaming;
    
    safe-configuration = {
      name = "safe-configuration";
      description = "Default NixOS configuration template that prevents display issues, integrates with nix-mox tools using the fragment system, and includes comprehensive messaging and communication support.";
      scripts = [
        "flake.nix"
        "configuration.nix"
        "home.nix"
        "README.md"
        "setup.sh"
      ];
      dependencies = [
        "nix"
        "git"
        "vim"
      ];
      customOptions = {
        hostname = {
          type = "string";
          default = "hydebox";
          description = "Hostname for the NixOS system";
        };
        username = {
          type = "string";
          default = "hyde";
          description = "Username for the NixOS system";
        };
        sshKey = {
          type = "string";
          default = "";
          description = "SSH public key for the user";
        };
      };
    };
  };

in
{
  options.services.nix-mox.templates = {
    enable = lib.mkEnableOption "Enable nix-mox templates";

    available = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = templates;
      description = "Available templates";
    };

    selected = lib.mkOption {
      type = lib.types.str;
      default = "safe-configuration";
      description = "Selected template to use";
    };

    customOptions = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Custom options for the selected template";
    };
  };

  config = lib.mkIf cfg.enable {
    # Template service configuration
    services.nix-mox.template-service = {
      enable = true;
      templates = cfg.available;
      selectedTemplate = cfg.selected;
      options = cfg.customOptions;
    };

    # System packages for template management
    environment.systemPackages = with pkgs; [
      # Template management tools
      (pkgs.writeScriptBin "nix-mox-template" ''
        #!${pkgs.bash}/bin/bash
        echo "nix-mox Template Manager"
        echo "======================="
        echo ""
        echo "Available templates:"
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: template: 
          "echo \"  - ${name}: ${template.description}\""
        ) templates)}
        echo ""
        echo "Selected template: ${cfg.selected}"
        echo "Custom options: ${lib.concatStringsSep ", " (lib.attrNames cfg.customOptions)}"
      '')
    ];
  };
}
