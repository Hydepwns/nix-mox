# Home configuration for hydepwns
{ config, pkgs, ... }:

{
  # Basic home-manager configuration
  home.username = "hydepwns";
  home.homeDirectory = "/home/hydepwns";
  
  # User packages (in addition to system packages)
  home.packages = with pkgs; [
    # Development tools
    vscode
    
    # Utilities
    neofetch
    tree
    
    # Gaming utilities installed at user level
    protonup-qt
  ];
  
  # Git configuration
  programs.git = {
    enable = true;
    userName = "hydepwns";
    userEmail = "drew@axol.io";
  };
  
  # Shell configuration
  programs.bash = {
    enable = true;
    shellAliases = {
      ll = "ls -la";
      gs = "git status";
      nrs = "sudo nixos-rebuild switch --flake .#nixos";
      nrt = "sudo nixos-rebuild test --flake .#nixos";
    };
  };
  
  # Enable direnv for development
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
  
  home.stateVersion = "24.05";
}