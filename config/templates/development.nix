# Development Template Configuration
# Development environment with IDEs and tools
{ config, pkgs, ... }:
{
  imports = [
    ../profiles/base.nix
    ../profiles/security.nix
    ../profiles/development.nix
  ];

  # Development-specific configuration
  environment.systemPackages = with pkgs; [
    # Development tools
    vscode
    docker
    docker-compose
    nodejs
    python3
    rustc
    cargo
    gcc
    clang

    # Version control
    git
    git-lfs

    # Build tools
    cmake
    ninja
    meson

    # Debugging
    gdb
    lldb

    # Terminal tools
    kitty
    alacritty
    tmux
  ];

  # Development programs
  programs = {
    zsh.enable = true;
    git.enable = true;
    vscode.enable = true;
  };

  # Docker support
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  # Development services
  services = {
    # SSH for remote development
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };
  };

  # Development environment variables
  environment.variables = {
    EDITOR = "vim";
    VISUAL = "vim";
    PAGER = "less";
  };
}
