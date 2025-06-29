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
    pkgs.ripgrep # File search
    pkgs.neovim # Editor
    pkgs.tmux # Terminal multiplexer
    pkgs.tmuxinator # Tmuxinator
    pkgs.code-cursor # Cursor AI IDE

    # Python development
    pkgs.python3
    pkgs.python3Packages.pip
    pkgs.python3Packages.pytest
    pkgs.python3Packages.black

    # Development tools
    pkgs.just # Command runner
    pkgs.pre-commit # Git hooks
    pkgs.direnv # Directory environment manager
    pkgs.gh # GitHub CLI
    pkgs.bat # Better cat
    pkgs.eza # Modern ls
    pkgs.jq # JSON processor
  ];

  shellHook = ''
    # Function to show help menu
    show_help() {
      echo "Welcome to the nix-mox development shell!"
      echo ""
      echo "🔍 File Search & Navigation"
      echo "-------------------------"
      echo "ripgrep: (v${pkgs.ripgrep.version})"
      echo "    Commands:"
      echo "    - rg 'pattern'                 # Search for pattern in files"
      echo "    - rg -i 'pattern'              # Case-insensitive search"
      echo "    - rg -t py 'pattern'           # Search only Python files"
      echo "    - rg --type-list               # Show supported file types"
      echo ""
      echo "fd: (v${pkgs.fd.version})"
      echo "    Commands:"
      echo "    - fd 'pattern'                 # Find files by name"
      echo "    - fd -e py                     # Find files by extension"
      echo "    - fd -H 'pattern'              # Include hidden files"
      echo ""
      echo "📝 Editing & Development"
      echo "----------------------"
      echo "neovim: (v${pkgs.neovim.version})"
      echo "    Commands:"
      echo "    - nvim file                    # Open file in Neovim"
      echo "    - nvim .                       # Open current directory"
      echo "    - nvim -c 'set number' file    # Open with line numbers"
      echo ""
      echo "code-cursor: (v${pkgs.code-cursor.version})"
      echo "    Commands:"
      echo "    - cursor file                  # Open file in Cursor"
      echo "    - cursor .                     # Open current directory"
      echo "    - cursor --help                # Show Cursor options"
      echo ""
      echo "🖥️  Terminal Management"
      echo "---------------------"
      echo "tmux: (v${pkgs.tmux.version})"
      echo "    Commands:"
      echo "    - tmux                         # Start new session"
      echo "    - tmux new-session -s dev      # Create named session"
      echo "    - tmux attach -t dev           # Attach to session"
      echo "    - tmux list-sessions           # List all sessions"
      echo "    - tmux kill-session -t dev     # Kill session"
      echo ""
      echo "tmuxinator: (v${pkgs.tmuxinator.version})"
      echo "    Commands:"
      echo "    - tmuxinator start project     # Start project session"
      echo "    - tmuxinator list              # List available projects"
      echo "    - tmuxinator new project       # Create new project config"
      echo "    - tmuxinator edit project      # Edit project config"
      echo ""
      echo "🐍 Python Development"
      echo "-------------------"
      echo "python3: (v${pkgs.python3.version})"
      echo "    Commands:"
      echo "    - python3 --version              # Check Python version"
      echo "    - python3 -m pip --version       # Check pip version"
      echo "    - python3 -m venv venv           # Create virtual environment"
      echo "    - source venv/bin/activate       # Activate virtual environment"
      echo ""
      echo "pytest: (v${pkgs.python3Packages.pytest.version})"
      echo "    Commands:"
      echo "    - pytest                         # Run all tests"
      echo "    - pytest -v                      # Verbose output"
      echo "    - pytest -k 'test_name'          # Run specific test"
      echo ""
      echo "black: (v${pkgs.python3Packages.black.version})"
      echo "    Commands:"
      echo "    - black .                        # Format all Python files"
      echo "    - black --check .                # Check formatting"
      echo ""
      echo "🔧 Development Tools"
      echo "------------------"
      echo "just: (v${pkgs.just.version})"
      echo "    Commands:"
      echo "    - just --list                    # List available commands"
      echo "    - just build                     # Run build command"
      echo ""
      echo "pre-commit: (v${pkgs.pre-commit.version})"
      echo "    Commands:"
      echo "    - pre-commit install            # Install git hooks"
      echo "    - pre-commit run --all-files   # Run all hooks"
      echo ""
      echo "direnv: (v${pkgs.direnv.version})"
      echo "    Commands:"
      echo "    - direnv allow                  # Enable directory"
      echo "    - direnv edit .                 # Edit .envrc"
      echo ""
      echo "gh: (v${pkgs.gh.version})"
      echo "    Commands:"
      echo "    - gh pr create                 # Create pull request"
      echo "    - gh issue list                # List issues"
      echo ""
      echo "bat: (v${pkgs.bat.version})"
      echo "    Commands:"
      echo "    - bat file                     # View file with syntax highlighting"
      echo "    - bat --style=numbers file     # Show line numbers"
      echo ""
      echo "eza: (v${pkgs.eza.version})"
      echo "    Commands:"
      echo "    - eza -l                       # List with details"
      echo "    - eza -T                       # Tree view"
      echo ""
      echo "jq: (v${pkgs.jq.version})"
      echo "    Commands:"
      echo "    - jq '.' file.json            # Pretty print JSON"
      echo "    - jq '.key' file.json         # Extract value"
      echo ""
      echo "📝 Quick Start"
      echo "------------"
      echo "1. Setup development environment:"
      echo "   just --list                    # View available commands"
      echo "   pre-commit install            # Install git hooks"
      echo "   direnv allow                  # Enable directory environment"
      echo ""
      echo "2. Python development:"
      echo "   python3 -m venv venv          # Create virtual environment"
      echo "   source venv/bin/activate      # Activate environment"
      echo "   pip install -r requirements.txt # Install dependencies"
      echo "   pytest                        # Run tests"
      echo "   black .                       # Format code"
      echo ""
      echo "3. Development workflow:"
      echo "   gh pr create                  # Create pull request"
      echo "   just test                     # Run tests"
      echo ""
      echo "4. Code quality:"
      echo "   pre-commit run               # Run all hooks"
      echo "   nixpkgs-fmt .                # Format Nix files"
      echo "   shellcheck scripts/          # Lint shell scripts"
      echo ""
      echo "5. Terminal workflow:"
      echo "   tmuxinator start dev          # Start development session"
      echo "   nvim .                        # Open editor"
      echo "   rg 'TODO'                     # Search for TODOs"
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
    alias which-shell='echo "You are in the nix-mox development shell"'
  '';
}
