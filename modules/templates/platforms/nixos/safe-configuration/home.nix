{ config, pkgs, inputs, ... }:

{
  home.stateVersion = "23.11";
  home.username = "droo";
  home.homeDirectory = "/home/droo";

  # Shell configuration
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ll = "ls -l";
      la = "ls -la";

      # Nix aliases
      nrs = "sudo nixos-rebuild switch --flake .#hydebox";
      nfu = "nix flake update";
      ngc = "nix-collect-garbage -d";

      # Quick access to nix-mox dev shells
      dev-default = "nix develop ${inputs.nix-mox}#default";
      dev-development = "nix develop ${inputs.nix-mox}#development";
      dev-testing = "nix develop ${inputs.nix-mox}#testing";
      dev-services = "nix develop ${inputs.nix-mox}#services";
      dev-monitoring = "nix develop ${inputs.nix-mox}#monitoring";
      dev-gaming = "nix develop ${inputs.nix-mox}#gaming";
      dev-zfs = "nix develop ${inputs.nix-mox}#zfs";
      dev-macos = "nix develop ${inputs.nix-mox}#macos";
      dev-storage = "nix develop ${inputs.nix-mox}#storage";

      # nix-mox package commands
      nixos-update = "nixos-flake-update";
    };

    initExtra = ''
      # Any additional shell configuration
      export EDITOR=vim
    '';
  };

  # Git configuration
  programs.git = {
    enable = true;
    userName = "hydepwns";
    userEmail = "andrewtehsailor@gmail.com";
    extraConfig = {
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
    };
  };

  # Other programs
  programs.firefox.enable = true;
  programs.vscode.enable = true;

  # Messaging and communication programs
  programs = {
    # Enable desktop notifications for messaging apps
    dconf.enable = true;

    # Configure file associations for messaging apps
    xdg = {
      enable = true;
      mimeApps = {
        enable = true;
        defaultApplications = {
          "x-scheme-handler/signal" = "signal-desktop.desktop";
          "x-scheme-handler/telegram" = "telegram-desktop.desktop";
          "x-scheme-handler/discord" = "discord.desktop";
          "x-scheme-handler/slack" = "slack.desktop";
        };
      };
    };
  };

  # Desktop notifications for messaging apps
  services.dunst.enable = true;
}
