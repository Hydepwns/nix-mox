# Development Profile
# Development tools and environments shared across development templates
{ config, pkgs, ... }:
{
  # Development packages
  environment.systemPackages = with pkgs; [
    # Programming languages
    nodejs
    python3
    rustc
    cargo
    gcc
    clang
    go
    jdk
    dotnet-sdk

    # Build tools
    cmake
    ninja
    meson
    make
    autoconf
    automake
    libtool
    pkg-config

    # Version control
    git
    git-lfs
    git-crypt
    hub
    gh

    # Development tools
    vscode
    jetbrains.idea-community
    jetbrains.pycharm-community
    jetbrains.clion
    jetbrains.goland

    # Debugging
    gdb
    lldb
    valgrind
    strace
    ltrace

    # Testing
    jq
    yq
    httpie
    postman

    # Container tools
    docker
    docker-compose
    podman
    buildah
    skopeo

    # Cloud tools
    awscli2
    azure-cli
    gcloud

    # Terminal tools
    kitty
    alacritty
    tmux
    screen

    # Code quality
    shellcheck
    hadolint
    eslint
    prettier
    black
    rustfmt
    clang-format
  ];

  # Development programs
  programs = {
    vscode.enable = true;
    tmux.enable = true;
  };

  # Development services
  services = {
    # Docker
    docker = {
      enable = true;
      enableOnBoot = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
      };
    };
  };

  # Development environment variables
  environment.variables = {
    # Editor
    EDITOR = "vim";
    VISUAL = "vim";

    # Language-specific
    PYTHONPATH = ".:$PYTHONPATH";
    GOPATH = "$HOME/go";
    CARGO_HOME = "$HOME/.cargo";
    RUSTUP_HOME = "$HOME/.rustup";

    # Development tools
    DOCKER_BUILDKIT = "1";
    COMPOSE_DOCKER_CLI_BUILD = "1";

    # Terminal
    TERM = "xterm-256color";
    COLORTERM = "truecolor";
  };

  # Development shell configuration
  programs.zsh.interactiveShellInit = ''
    # Development aliases
    alias gst="git status"
    alias ga="git add"
    alias gc="git commit"
    alias gp="git push"
    alias gl="git log --oneline"
    alias gco="git checkout"
    alias gcb="git checkout -b"
    
    # Docker aliases
    alias d="docker"
    alias dc="docker-compose"
    alias dps="docker ps"
    alias di="docker images"
    
    # Development shortcuts
    alias py="python3"
    alias pip="pip3"
    alias node="nodejs"
    
    # Quick directory navigation
    alias dev="cd ~/development"
    alias proj="cd ~/projects"
  '';

  # Development file associations
  xdg.mime.defaultApplications = {
    "text/x-python" = "code.desktop";
    "text/x-javascript" = "code.desktop";
    "text/x-typescript" = "code.desktop";
    "text/x-rust" = "code.desktop";
    "text/x-go" = "code.desktop";
    "text/x-java" = "code.desktop";
  };
}
