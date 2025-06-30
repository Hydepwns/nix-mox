# User-specific Configuration
# Customize this file with your personal settings
{ config, pkgs, ... }:
let
  # Get personal settings from environment or use defaults
  personal = config.personal or {
    username = "user";
    email = "user@example.com";
    timezone = "UTC";
    hostname = "nixos";
    gitUsername = "user";
    gitEmail = "user@example.com";
  };
in
{
  # System user configuration
  users.users.${personal.username} = {
    isNormalUser = true;
    description = personal.username;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    shell = pkgs.zsh;
    initialPassword = builtins.getEnv "INITIAL_PASSWORD" or "changeme";
  };

  # System configuration
  networking.hostName = personal.hostname;
  time.timeZone = personal.timezone;

  # Home Manager configuration
  home-manager.users.${personal.username} = {
    home.stateVersion = "23.11";
    home.username = personal.username;
    home.homeDirectory = "/home/${personal.username}";

    # Shell configuration
    programs.zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      shellAliases = {
        ll = "ls -l";
        la = "ls -la";
        nrs = "sudo nixos-rebuild switch --flake .#nixos";
        nfu = "nix flake update";
        ngc = "nix-collect-garbage -d";
      };

      initContent = ''
        export EDITOR=vim
      '';
    };

    # Git configuration
    programs.git = {
      enable = true;
      userName = personal.gitUsername;
      userEmail = personal.gitEmail;
      extraConfig = {
        init.defaultBranch = "main";
        push.autoSetupRemote = true;
      };
    };

    # Common programs
    programs.firefox.enable = true;
    programs.vscode.enable = true;
  };
}
