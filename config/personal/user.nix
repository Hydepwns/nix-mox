# User-specific Configuration
# Customize this file with your personal settings
{ config, pkgs, ... }:
let
  lib = pkgs.lib;
  # Get personal settings from environment or use defaults
  personal = {
    username = let val = builtins.getEnv "NIXMOX_USERNAME"; in if val == "" then "user" else val;
    email = let val = builtins.getEnv "NIXMOX_EMAIL"; in if val == "" then "user@example.com" else val;
    timezone = let val = builtins.getEnv "NIXMOX_TIMEZONE"; in if val == "" then "UTC" else val;
    hostname = let val = builtins.getEnv "NIXMOX_HOSTNAME"; in if val == "" then "nixos" else val;
    gitUsername = let val = builtins.getEnv "NIXMOX_GIT_USERNAME"; in if val == "" then "user" else val;
    gitEmail = let val = builtins.getEnv "NIXMOX_GIT_EMAIL"; in if val == "" then "user@example.com" else val;
  };
in
{
  # System user configuration
  users.users.${personal.username} = {
    isNormalUser = true;
    description = personal.username;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    shell = pkgs.zsh;
    initialPassword = let val = builtins.getEnv "INITIAL_PASSWORD"; in if val == "" then "changeme" else val;
  };

  # System configuration
  networking.hostName = personal.hostname;
  time.timeZone = lib.mkDefault personal.timezone;

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
