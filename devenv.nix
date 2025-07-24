{ pkgs, ... }:

{
  # Core development tools
  packages = with pkgs; [
    # Essential tools
    git
    nix
    nixpkgs-fmt
    shellcheck
    coreutils
    eza
    btop

    # Editors
    zed
    code-cursor
    kitty

    # Formatters
    nodePackages.prettier
    shfmt
    python3Packages.black
    rustfmt
    go
    nufmt
    treefmt
    nodejs

    # Development tools
    direnv
    devenv

    # Additional tools from Hydepwns dotfiles
    bat
    fzf
    tree-sitter
    lshw
    pciutils
    usbutils
    nmap
    curl
    wget

    # Blender
    blender

    # Additional development languages and tools
    python3
    rustc
    cargo
    elixir
    elixir-ls
    nodejs_20
    gh
  ];

  # Environment variables
  env = {
    EDITOR = "zed";
    VISUAL = "zed";
    TERMINAL = "kitty";
    TERM = "xterm-kitty";
    NIX_MOX_DEVENV = "true";
  };

  # Shell hook
  enterShell = ''
    echo "🚀 Welcome to nix-mox devenv!"
    echo "📝 Editor: zed"
    echo "🖥️  Terminal: kitty"
    echo "🎨 Blender: $(which blender)"
    echo "🔧 Core tools: git, nix, direnv, devenv"
    echo ""
    echo "Available commands:"
    echo "  nix run .#fmt     - Format code"
    echo "  nix run .#test    - Run tests"
    echo "  nix run .#update  - Update flake inputs"
    echo "  nix run .#dev     - Show development help"
    echo ""
    echo "💡 Tip: Use 'direnv allow' to automatically load this environment"
    echo ""
  '';

  # Scripts
  scripts = {
    # Development helpers
    dev-help.exec = "nix run .#dev";
    fmt.exec = "nix run .#fmt";
    test.exec = "nix run .#test";
    update.exec = "nix run .#update";

    # Quick access to tools
    zed.exec = "zed";
    blender.exec = "blender";
    kitty.exec = "kitty";
  };
}
