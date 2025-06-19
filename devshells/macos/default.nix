{ pkgs }:

pkgs.mkShell {
  buildInputs = [
    # Core development tools
    pkgs.git
    pkgs.nix
    pkgs.nixpkgs-fmt
    pkgs.shellcheck
    pkgs.coreutils
    pkgs.fd
    pkgs.ripgrep

    # macOS specific tools
    pkgs.darwin.apple_sdk.frameworks.CoreServices
    pkgs.darwin.apple_sdk.frameworks.Foundation

    # Development tools
    pkgs.vscode
    pkgs.jq
    pkgs.yq
    pkgs.curl
    pkgs.wget
    pkgs.htop
    pkgs.tmux
    pkgs.zsh
    pkgs.oh-my-zsh
    pkgs.code-cursor
  ];

  # Add macOS-specific environment variables
  shellHook = ''
    # Set up macOS environment
    export MACOSX_DEPLOYMENT_TARGET=11.0
    export SDKROOT=${pkgs.darwin.apple_sdk.MacOSX-SDK}/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk

    # Function to show help menu
    show_help() {
      echo "Welcome to the nix-mox macOS development shell!"
      echo ""
      echo "🔧 Base Tools"
      echo "-----------"
      echo "git: (v${pkgs.git.version})"
      echo "    Commands:"
      echo "    - git status                       # Check repository status"
      echo "    - git log --oneline               # View commit history"
      echo ""
      echo "nix: (v${pkgs.nix.version})"
      echo "    Commands:"
      echo "    - nix develop                     # Enter development shell"
      echo "    - nix build                       # Build packages"
      echo ""
      echo "Development Tools"
      echo "----------------"
      echo "vscode: (v${pkgs.vscode.version})"
      echo "    Commands:"
      echo "    - code .                          # Open current directory"
      echo ""
      echo "jq: (v${pkgs.jq.version})"
      echo "    Commands:"
      echo "    - jq '.' file.json               # Pretty print JSON"
      echo ""
      echo "yq: (v${pkgs.yq.version})"
      echo "    Commands:"
      echo "    - yq eval '.' file.yaml          # Pretty print YAML"
      echo ""
      echo "curl: (v${pkgs.curl.version})"
      echo "    Commands:"
      echo "    - curl -O url                    # Download file"
      echo "    - curl -I url                    # Check headers"
      echo ""
      echo "wget: (v${pkgs.wget.version})"
      echo "    Commands:"
      echo "    - wget url                       # Download file"
      echo ""
      echo "htop: (v${pkgs.htop.version})"
      echo "    Commands:"
      echo "    - htop                           # System monitor"
      echo ""
      echo "tmux: (v${pkgs.tmux.version})"
      echo "    Commands:"
      echo "    - tmux new -s session           # New session"
      echo "    - tmux attach -t session        # Attach to session"
      echo ""
      echo "zsh: (v${pkgs.zsh.version})"
      echo "    Commands:"
      echo "    - zsh                           # Start ZSH shell"
      echo ""
      echo "code-cursor: (v${pkgs.code-cursor.version})"
      echo "    Commands:"
      echo "    - code-cursor .                 # Launch code-cursor editor"
      echo ""
      echo "📝 Quick Start"
      echo "------------"
      echo "1. Enter specialized shells:"
      echo "   nix develop .#development         # Development tools"
      echo "   nix develop .#testing            # Testing tools"
      echo "   nix develop .#services           # Service tools"
      echo "   nix develop .#monitoring         # Monitoring tools"
      echo ""
      echo "2. Format Nix code:"
      echo "   nix fmt"
      echo ""
      echo "For more information, see docs/."
    }

    # Show initial help menu
    show_help

    # Add help command to shell
    echo ""
    echo "💡 Tip: Type 'help' to show this menu again"
    echo "💡 Tip: Type 'which-shell' to see which shell you're in"
    echo ""
    alias help='show_help'
    alias which-shell='echo "You are in the nix-mox macOS development shell"'
  '';
}
