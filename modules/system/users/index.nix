{ pkgs, config, lib, ... }:

let
  # User management configuration (default)
  user-management = { config, lib, pkgs, ... }: {
    options.users = {
      default = {
        enable = lib.mkEnableOption "Enable default user creation";
        username = lib.mkOption {
          type = lib.types.str;
          default = "user";
          description = "Default username";
        };
        fullName = lib.mkOption {
          type = lib.types.str;
          default = "Default User";
          description = "User's full name";
        };
        email = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "User's email address";
        };
        shell = lib.mkOption {
          type = lib.types.package;
          default = pkgs.zsh;
          description = "User's default shell";
        };
        groups = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "wheel" "networkmanager" "video" "audio" ];
          description = "Groups to add user to";
        };
        extraGroups = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Additional groups for the user";
        };
        home = lib.mkOption {
          type = lib.types.str;
          default = "/home/user";
          description = "User's home directory";
        };
        uid = lib.mkOption {
          type = lib.types.int;
          default = 1000;
          description = "User ID";
        };
        isNormalUser = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether this is a normal user (not system user)";
        };
        createHome = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Create home directory";
        };
        initialPassword = lib.mkOption {
          type = lib.types.str;
          default = "changeme";
          description = "Initial password (should be changed on first login)";
        };
      };
      sudo = {
        enable = lib.mkEnableOption "Enable sudo configuration";
        wheelNeedsPassword = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Require password for sudo";
        };
        extraRules = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Additional sudo rules";
        };
        securePath = lib.mkOption {
          type = lib.types.str;
          default = "/run/wrappers/bin:/etc/profiles/per-user/root/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin";
          description = "Secure PATH for sudo";
        };
      };
      groups = {
        wheel = {
          enable = lib.mkEnableOption "Enable wheel group";
          members = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Members of wheel group";
          };
        };
        docker = {
          enable = lib.mkEnableOption "Enable docker group";
          members = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Members of docker group";
          };
        };
        libvirtd = {
          enable = lib.mkEnableOption "Enable libvirtd group";
          members = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Members of libvirtd group";
          };
        };
        input = {
          enable = lib.mkEnableOption "Enable input group";
          members = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Members of input group";
          };
        };
        uinput = {
          enable = lib.mkEnableOption "Enable uinput group";
          members = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Members of uinput group";
          };
        };
      };
      security = {
        enable = lib.mkEnableOption "Enable security features";
        passwordQuality = {
          enable = lib.mkEnableOption "Enable password quality checks";
          minLength = lib.mkOption {
            type = lib.types.int;
            default = 8;
            description = "Minimum password length";
          };
          complexity = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Require password complexity";
          };
        };
        loginDefs = {
          enable = lib.mkEnableOption "Enable login.defs configuration";
          passwordMaxDays = lib.mkOption {
            type = lib.types.int;
            default = 90;
            description = "Maximum password age in days";
          };
          passwordMinDays = lib.mkOption {
            type = lib.types.int;
            default = 1;
            description = "Minimum password age in days";
          };
          passwordWarnAge = lib.mkOption {
            type = lib.types.int;
            default = 7;
            description = "Password warning age in days";
          };
        };
        pam = {
          enable = lib.mkEnableOption "Enable PAM configuration";
          unlockDelay = lib.mkOption {
            type = lib.types.int;
            default = 3;
            description = "Delay before allowing unlock attempts";
          };
          maxRetries = lib.mkOption {
            type = lib.types.int;
            default = 3;
            description = "Maximum login attempts";
          };
        };
      };
    };

    config =
      let
        cfg = config.users;
      in
      {
        # Default user configuration
        users.users = lib.mkIf cfg.default.enable {
          ${cfg.default.username} = {
            isNormalUser = cfg.default.isNormalUser;
            description = cfg.default.fullName;
            extraGroups = cfg.default.groups ++ cfg.default.extraGroups;
            uid = cfg.default.uid;
            home = cfg.default.home;
            createHome = cfg.default.createHome;
            shell = cfg.default.shell;
            initialPassword = cfg.default.initialPassword;
          };
        };

        # Group configurations
        users.groups = {
          wheel = lib.mkIf cfg.groups.wheel.enable {
            members = cfg.groups.wheel.members;
          };
          docker = lib.mkIf cfg.groups.docker.enable {
            members = cfg.groups.docker.members;
          };
          libvirtd = lib.mkIf cfg.groups.libvirtd.enable {
            members = cfg.groups.libvirtd.members;
          };
          input = lib.mkIf cfg.groups.input.enable {
            members = cfg.groups.input.members;
          };
          uinput = lib.mkIf cfg.groups.uinput.enable {
            members = cfg.groups.uinput.members;
          };
        };

        # Security and sudo configuration
        security = lib.mkMerge [
          # Sudo configuration
          (lib.mkIf cfg.sudo.enable {
            sudo = {
              enable = true;
              wheelNeedsPassword = cfg.sudo.wheelNeedsPassword;
              extraRules = cfg.sudo.extraRules;
              securePath = cfg.sudo.securePath;
            };
          })
          # Security features
          (lib.mkIf cfg.security.enable {
            # Password quality and PAM configuration
            pam.services = lib.mkMerge [
              (lib.mkIf cfg.security.passwordQuality.enable {
                login.passwordAuth = {
                  enable = true;
                  settings = {
                    password = "requisite pam_pwquality.so retry=3 minlen=${toString cfg.security.passwordQuality.minLength}";
                  };
                };
                sudo.passwordAuth = {
                  enable = true;
                  settings = {
                    password = "requisite pam_pwquality.so retry=3 minlen=${toString cfg.security.passwordQuality.minLength}";
                  };
                };
              })
              (lib.mkIf cfg.security.pam.enable {
                login = {
                  enable = true;
                  settings = {
                    auth = [
                      "required pam_unix.so"
                      "required pam_faillock.so preauth audit silent deny=${toString cfg.security.pam.maxRetries} unlock_time=${toString cfg.security.pam.unlockDelay}"
                    ];
                  };
                };
              })
            ];

            # Login definitions
            loginDefs = lib.mkIf cfg.security.loginDefs.enable {
              passwordMaxDays = cfg.security.loginDefs.passwordMaxDays;
              passwordMinDays = cfg.security.loginDefs.passwordMinDays;
              passwordWarnAge = cfg.security.loginDefs.passwordWarnAge;
            };
          })
        ];

        # User environment
        environment = {
          # Set default editor
          variables = {
            EDITOR = "nano";
            VISUAL = "nano";
          };
        };

        # User services
        services = {
          # Enable user services
          dbus.enable = true;
          gvfs.enable = true;
        };
      };
  };

in
{
  # Export user management modules
  inherit user-management;

  # Default user management configuration
  default = user-management;
}
