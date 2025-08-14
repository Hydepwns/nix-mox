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
    initialPassword = "changeme";
  };

  users.users.${personal.username} = {
    isNormalUser = true;
    description = "Hydepwns User";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "docker" "libvirtd" "kvm" "vboxusers" "lxd" "qemu-libvirtd" ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keyFiles = [ ./keys/hydepwns.pub ];
    initialPassword = "changeme";
  };

  # Temporary recovery account to avoid lockout when migrating users
  users.users.nixos = {
    isNormalUser = true;
    description = "Temporary recovery user";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.zsh;
    initialPassword = "changeme";
    uid = 1000;
    home = "/home/nixos";
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

    # Primary editor
    zed

    # 3D and graphics
    blender

    # Development environment tools
    direnv
    devenv

    # Additional tools from Hydepwns dotfiles
    bat
    eza
    fzf
    htop
    btop  # Better resource monitor
    tree
    curl
    wget
    nmap
    pciutils
    usbutils
    lshw
    gh

    # Proxmox and virtualization tools
    proxmox-backup-client
    proxmox-auto-install-assistant
    python312Packages.proxmoxer
    terraform-providers.proxmox
  ];

  # NOTE: services.xserver is already configured in config/nixos/configuration.nix
  # Avoid duplicate configuration to prevent conflicts

  # Display manager and desktop environment (consolidated configuration)
  services.displayManager.sddm = {
    enable = true;
    # Enable Wayland support for Plasma 6 (can cause screen lock issues if misconfigured)
    wayland.enable = true;
  };

  # Desktop Manager (Plasma 6)
  services.desktopManager = {
    plasma6.enable = true;
  };

  # SSH configuration - use Plasma 6's ksshaskpass
  programs.ssh.askPassword = lib.mkForce "${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass";

  # NOTE: networking.useDHCP is already set in hardware-configuration.nix
  # Remove duplicate to avoid conflicts

  # Home Manager configuration
  home-manager.users.${personal.username} = lib.mkForce {
    home.stateVersion = "24.05";
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
        export EDITOR=zed
        export VISUAL=zed

        # Initialize direnv
        eval "$(direnv hook zsh)"

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

        # Load Hydepwns dotfiles if available
        if [ -f "$HOME/.config/zsh/.zshrc" ]; then
          source "$HOME/.config/zsh/.zshrc"
        fi

        # Devenv integration
        if [ -n "$NIX_MOX_DEVENV_LOADED" ]; then
          echo "🚀 nix-mox devenv active"
        fi
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
        core.editor = "zed";
      };
    };

    # Development tools
    programs = {
      # Neovim as fallback
      neovim = {
        enable = true;
        viAlias = true;
        vimAlias = true;
      };

      # Terminal
      kitty = {
        enable = true;
        font = {
          name = "JetBrains Mono Nerd Font";
          size = 12;
        };
        settings = {
          background_opacity = "0.9";
          background = "#1e1e2e";
          foreground = "#cdd6f4";
          selection_background = "#585b70";
          cursor = "#f5e0dc";
          url_color = "#f5c2e7";
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

      # Primary editor
      zed

      # Utilities
      ripgrep
      fd
      fzf
      bat
      eza
      htop
    btop  # Better resource monitor
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
      blender

      # Office and productivity
      libreoffice
      calibre
      evince

      # Additional development tools
      vscode
      jetbrains.idea-community
      docker
      docker-compose

      # Development environment tools
      direnv
      devenv

      # Proxmox and virtualization tools
      proxmox-backup-client
      proxmox-auto-install-assistant
      python312Packages.proxmoxer
      terraform-providers.proxmox
    ];
  };
}
