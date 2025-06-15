{ pkgs }:
pkgs.mkShell {
  buildInputs = [
    # Base tools from default shell
    pkgs.nushell
    pkgs.git
    pkgs.nix
    pkgs.nixpkgs-fmt
    pkgs.shellcheck
    pkgs.coreutils
    pkgs.fd
    pkgs.ripgrep

    # Additional development tools
    pkgs.just           # Command runner
    pkgs.pre-commit     # Git hooks
    pkgs.direnv        # Directory environment manager
    pkgs.act           # Run GitHub Actions locally
    pkgs.gh            # GitHub CLI
    pkgs.sd            # Intuitive find & replace
    pkgs.bat           # Better cat
    pkgs.exa           # Modern ls
    pkgs.tree          # Directory tree
    pkgs.duf           # Disk usage
    pkgs.htop          # Process viewer
    pkgs.jq            # JSON processor
  ];

  shellHook = ''
    echo "Welcome to the nix-mox enhanced development shell!"
    echo "Available tools:"
    echo "  - Base tools (from default shell)"
    echo "  - just (Command runner)"
    echo "  - pre-commit (Git hooks)"
    echo "  - direnv (Directory environment manager)"
    echo "  - act (Run GitHub Actions locally)"
    echo "  - gh (GitHub CLI)"
    echo "  - sd (Intuitive find & replace)"
    echo "  - bat (Better cat)"
    echo "  - exa (Modern ls)"
    echo "  - tree (Directory tree)"
    echo "  - duf (Disk usage)"
    echo "  - htop (Process viewer)"
    echo "  - jq (JSON processor)"
    echo ""
    echo "Run 'just' to see available commands."
  '';
}