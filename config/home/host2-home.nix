# ============================================================================
# HOST2 HOME CONFIGURATION
# ============================================================================
# Server home configuration for host2
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
    bash = {
      enable = true;
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
        # Server-specific aliases
        logs = "journalctl -f";
        status = "systemctl status";
        restart = "sudo systemctl restart";
        stop = "sudo systemctl stop";
        start = "sudo systemctl start";
      };
    };

    # Git
    git = {
      enable = true;
      userName = "Server Admin";
      userEmail = "admin@example.com";
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
        set background=dark
      '';
    };

    # Tmux
    tmux = {
      enable = true;
      shortcut = "Space";
      baseIndex = 1;
      escapeTime = 0;
      extraConfig = ''
        set -g default-terminal "screen-256color"
        set -g status-style bg=black,fg=white
        set -g window-status-current-style bg=white,fg=black
        bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "xclip -selection clipboard"
      '';
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
    # Server tools
    htop
    iotop
    nethogs
    tcpdump
    nmap
    netcat
    socat

    # Development tools
    git
    vim
    tmux
    ripgrep
    fd
    fzf

    # Monitoring tools
    htop
    glances
    ncdu
    tree

    # Network tools
    curl
    wget
    jq
    yq

    # System tools
    rsync
    screen
    unzip
    zip

    # Log analysis
    # logwatch
    # multitail
  ];

  # XDG
  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
      # Server-specific directories
      documents = "$HOME/docs";
      download = "$HOME/downloads";
      music = "$HOME/music";
      pictures = "$HOME/pics";
      videos = "$HOME/videos";
    };
  };

  # Environment variables
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    PAGER = "less";
    LESS = "-R";
    # Server-specific variables
    HISTSIZE = "10000";
    HISTFILESIZE = "20000";
    HISTCONTROL = "ignoreboth";
  };

  # Shell init
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/bin"
  ];
}
