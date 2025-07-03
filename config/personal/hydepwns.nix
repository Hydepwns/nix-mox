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
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "docker" "libvirtd" "kvm" "vboxusers" "lxd" "qemu-libvirtd" ];
    shell = pkgs.zsh;
    initialPassword = "nixos";
  };

  # System configuration
  networking.hostName = lib.mkForce personal.hostname;
  time.timeZone = lib.mkForce personal.timezone;

  # Virtualization services
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true;
      };
    };
    spiceUSBRedirection.enable = true;
  };

  # Additional system packages
  environment.systemPackages = with pkgs; [
    # Essential tools (in addition to base config)
    firefox
    vlc
    mpv
    ffmpeg
    imagemagick
    gimp
    inkscape
    libreoffice
    calibre
    evince
    vscode
    jetbrains.idea-community
    docker
    docker-compose

    # Proxmox and virtualization tools
    proxmox-backup-client
    proxmox-auto-install-assistant
    python312Packages.proxmoxer
    terraform-providers.proxmox
  ];

  # Display manager configuration - use LightDM since it's currently running
  # Note: This will be merged with gaming configuration
  services.xserver = {
    enable = true;
    displayManager.lightdm.enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  # Desktop Manager (updated for Plasma 6)
  services.desktopManager = {
    plasma6.enable = true;
  };

  # SSH configuration - use Plasma 6's ksshaskpass
  programs.ssh.askPassword = lib.mkForce "${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass";

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
          # KDE Plasma integration
          wayland_titlebar_color = "system";
          macos_titlebar_color = "system";
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
          # KDE Plasma integration
          settings = {
            "widget.use-xdg-desktop-portal.file-picker" = 1;
            "widget.use-xdg-desktop-portal.mime-handler" = 1;
          };
        };
      };
    };

    # Common packages for development and gaming
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

      # Virtualization and management
      virt-viewer
      spice-gtk
      spice-protocol
      libvirt
      libguestfs

      # Additional essential tools
      vim
      wget
      curl
      git
      htop
      tree
      nix-index
      nix-tree
      inetutils
      mtr
      iperf3

      # Graphics and multimedia
      vlc
      mpv
      ffmpeg
      imagemagick
      gimp
      inkscape

      # Office and productivity
      libreoffice
      calibre
      evince

      # Additional development tools
      vscode
      jetbrains.idea-community
      docker
      docker-compose

      # Proxmox and virtualization tools
      proxmox-backup-client
      proxmox-auto-install-assistant
      python312Packages.proxmoxer
      terraform-providers.proxmox
    ];
  };
}
