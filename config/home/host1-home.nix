# ============================================================================
# HOST1 HOME CONFIGURATION
# ============================================================================
# Desktop home configuration for host1
# ============================================================================

{ config, lib, pkgs, ... }:

{
  # Home Manager configuration
  home = {
    username = "droo";
    homeDirectory = "/home/droo";
    stateVersion = "23.11";
  };

  # Programs
  programs = {
    # Shell
    zsh = {
      enable = true;
      enableAutosuggestions = true;
      enableCompletion = true;
      syntaxHighlighting.enable = true;
      shellAliases = {
        ll = "ls -la";
        la = "ls -A";
        l = "ls -CF";
        ".." = "cd ..";
        "..." = "cd ../..";
        g = "git";
        ga = "git add";
        gc = "git commit";
        gp = "git push";
        gl = "git log --oneline";
        gs = "git status";
      };
    };

    # Git
    git = {
      enable = true;
      userName = "Your Name";
      userEmail = "your.email@example.com";
      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
      };
    };

    # Neovim
    neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      extraConfig = ''
        set number
        set relativenumber
        set expandtab
        set shiftwidth=2
        set tabstop=2
      '';
    };

    # Terminal
    alacritty = {
      enable = true;
      settings = {
        window = {
          opacity = 0.9;
          decorations = "buttonless";
        };
        font = {
          size = 12;
          family = "JetBrains Mono";
        };
        colors = {
          primary = {
            background = "#282c34";
            foreground = "#abb2bf";
          };
        };
      };
    };

    # Browser
    firefox = {
      enable = true;
      profiles.default = {
        settings = {
          "browser.startup.homepage" = "https://nixos.org";
          "browser.search.defaultenginename" = "DuckDuckGo";
        };
      };
    };
  };

  # Services
  services = {
    # SSH agent
    ssh-agent = {
      enable = true;
    };

    # GPG agent
    gpg-agent = {
      enable = true;
      enableSshSupport = true;
    };
  };

  # Packages
  home.packages = with pkgs; [
    # Development tools
    git
    vim
    tmux
    htop
    ripgrep
    fd
    fzf

    # Utilities
    tree
    wget
    curl
    jq
    yq

    # Media
    mpv
    feh

    # System tools
    xclip
    xsel
    pavucontrol
  ];

  # XDG
  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };

  # GTK
  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome.gnome-themes-extra;
    };
  };

  # Qt
  qt = {
    enable = true;
    platformTheme = "gtk";
  };
}
