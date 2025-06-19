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
      dev-gaming = "nix develop ${inputs.nix-mox}#gaming";
      dev-test = "nix develop ${inputs.nix-mox}#testing";
    };

    initExtra = ""
      # Any additional shell configuration
      export EDITOR=vim
    "";
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
}
