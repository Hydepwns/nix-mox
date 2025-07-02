# ============================================================================
# HOST1 HOME CONFIGURATION
# ============================================================================
# Desktop home configuration for host1
# ============================================================================

{ config, lib, pkgs, ... }:

{
  # Home Manager configuration
  home.username = "droo";
  home.homeDirectory = "/home/droo";
  home.stateVersion = "23.11";

  # Programs
  programs = {
    # Shell
    zsh = {
      autosuggestion.enable = true;
      enableCompletion = true;
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
      profiles.default = {
        settings = {
          "browser.startup.homepage" = "https://nixos.org";
          "browser.search.defaultenginename" = "DuckDuckGo";
        };
      };
    };

    # SSH
    ssh = {
    };
  };

  # Services
  services = {
    # SSH agent
    ssh-agent = {
    };

    # GPG agent
    gpg-agent = {
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
    userDirs = {
      createDirectories = true;
    };
  };

  # Qt
  qt = {
    platformTheme = "gtk";
  };
}
