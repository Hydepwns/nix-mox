# Hydepwns User Configuration
# Custom configuration for hydepwns user
{ config, pkgs, ... }:
let
  lib = pkgs.lib;
  # Personal settings for hydepwns
  personal = {
    username = "hydepwns";
    email = "andrewtehsailor@gmail.com";
    timezone = "Europe/Madrid";
    hostname = "nixos";
    gitUsername = "hydepwns";
    gitEmail = "andrewtehsailor@gmail.com";
  };
in
{
    # System user configuration - keep droo user but add hydepwns
  users.users.droo = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
  };

  users.users.${personal.username} = {
    isNormalUser = true;
    description = "Hydepwns User";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "docker" "libvirtd" "kvm" "vboxusers" "lxd" ];
    shell = pkgs.zsh;
    initialPassword = "nixos";
  };

  # System configuration
  networking.hostName = lib.mkForce personal.hostname;
  time.timeZone = lib.mkForce personal.timezone;

  # Display manager configuration - use LightDM since it's currently running
  services.xserver = {
    enable = true;
    displayManager.lightdm.enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  # Network configuration - enable network interfaces
  networking.useDHCP = true;

  # Home Manager configuration
  home-manager.users.${personal.username} = lib.mkForce {
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
        update = "nix flake update && sudo nixos-rebuild switch --flake .#nixos";
        gc = "nix-collect-garbage -d";
        rebuild = "sudo nixos-rebuild switch --flake .#nixos";
      };

      initContent = ''
        export EDITOR=nvim
        export VISUAL=nvim

        # Nix flake aliases
        alias nrs="sudo nixos-rebuild switch --flake .#nixos"
        alias nfu="nix flake update"
        alias ngc="nix-collect-garbage -d"

        # Development aliases
        alias gst="git status"
        alias gco="git checkout"
        alias gcb="git checkout -b"
        alias gcm="git commit -m"
        alias gp="git push"
        alias gl="git pull"

        # System aliases
        alias ..="cd .."
        alias ...="cd ../.."
        alias ....="cd ../../.."

        # Custom prompt
        PROMPT='%F{green}%n@%m%f %F{blue}%~%f %F{red}%#%f '
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
        pull.rebase = true;
        core.editor = "nvim";
      };
    };

    # Development tools
    programs = {
      # Neovim for editing
      neovim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
      };

      # Terminal
      kitty = {
        enable = true;
        settings = {
          font_family = "JetBrains Mono Nerd Font";
          font_size = 12;
          background_opacity = 0.9;
          background = "#1e1e2e";
          foreground = "#cdd6f4";
          selection_background = "#585b70";
          cursor = "#f5e0dc";
          url_color = "#f5c2e7";
        };
      };

      # Browser
      firefox = {
        enable = true;
        profiles.default = {
          id = 0;
          name = "Default";
          isDefault = true;
          search = {
            default = "ddg";
            force = true;
          };
        };
      };
    };

    # Common packages for development
    home.packages = with pkgs; [
      # Development tools
      nodejs_20
      python3
      rustc
      cargo
      go

      # Utilities
      ripgrep
      fd
      fzf
      bat
      eza
      htop
      tree

      # Version control
      git
      gh

      # Networking
      curl
      wget
      nmap

      # System tools
      pciutils
      usbutils
      lshw
      virt-manager
      qemu
      podman
      podman-compose
    ];
  };
}
