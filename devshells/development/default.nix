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

    # Python development
    pkgs.python3
    pkgs.python3Packages.pip
    pkgs.python3Packages.setuptools
    pkgs.python3Packages.wheel
    pkgs.python3Packages.virtualenv
    pkgs.python3Packages.pytest
    pkgs.python3Packages.black
    pkgs.python3Packages.flake8
    pkgs.python3Packages.mypy

    # Development tools
    pkgs.just           # Command runner
    pkgs.pre-commit     # Git hooks
    pkgs.direnv        # Directory environment manager
    pkgs.act           # Run GitHub Actions locally
    pkgs.gh            # GitHub CLI
    pkgs.sd            # Intuitive find & replace
    pkgs.bat           # Better cat
    pkgs.eza           # Modern ls
    pkgs.tree          # Directory tree
    pkgs.duf           # Disk usage
    pkgs.htop          # Process viewer
    pkgs.jq            # JSON processor
    pkgs.code-cursor   # Add code-cursor editor
  ];

  shellHook = ''
    # Function to show help menu
    show_help() {
      echo "Welcome to the nix-mox development shell!"
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
      echo "pip: (v${pkgs.python3Packages.pip.version})"
      echo "    Commands:"
      echo "    - pip install package            # Install package"
      echo "    - pip install -r requirements.txt # Install from requirements"
      echo "    - pip list                       # List installed packages"
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
      echo "    - black --diff file.py           # Show formatting changes"
      echo ""
      echo "flake8: (v${pkgs.python3Packages.flake8.version})"
      echo "    Commands:"
      echo "    - flake8 .                       # Lint Python code"
      echo "    - flake8 --max-line-length=88 .  # Custom line length"
      echo ""
      echo "mypy: (v${pkgs.python3Packages.mypy.version})"
      echo "    Commands:"
      echo "    - mypy .                         # Type check Python code"
      echo "    - mypy --strict .                # Strict type checking"
      echo ""
      echo "🔧 Development Tools"
      echo "------------------"
      echo "just: (v${pkgs.just.version})"
      echo "    Commands:"
      echo "    - just --list                    # List available commands"
      echo "    - just build                     # Run build command"
      echo "    Dependencies:"
      echo "    - Requires: git, nix"
      echo ""
      echo "pre-commit: (v${pkgs.pre-commit.version})"
      echo "    Commands:"
      echo "    - pre-commit install            # Install git hooks"
      echo "    - pre-commit run --all-files   # Run all hooks"
      echo "    Dependencies:"
      echo "    - Requires: git"
      echo ""
      echo "direnv: (v${pkgs.direnv.version})"
      echo "    Commands:"
      echo "    - direnv allow                  # Enable directory"
      echo "    - direnv edit .                 # Edit .envrc"
      echo "    Configuration:"
      echo "    - ~/.config/direnv/direnv.toml"
      echo ""
      echo "act: (v${pkgs.act.version})"
      echo "    Commands:"
      echo "    - act -l                       # List workflows"
      echo "    - act -W .github/workflows/test.yml"
      echo "    Dependencies:"
      echo "    - Requires: docker"
      echo ""
      echo "gh: (v${pkgs.gh.version})"
      echo "    Commands:"
      echo "    - gh pr create                 # Create pull request"
      echo "    - gh issue list                # List issues"
      echo "    Configuration:"
      echo "    - ~/.config/gh/config.yml"
      echo ""
      echo "sd: (v${pkgs.sd.version})"
      echo "    Commands:"
      echo "    - sd 'old' 'new' file          # Replace text"
      echo "    - sd -f 'old' 'new' file       # Replace first occurrence"
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
      echo "tree: (v${pkgs.tree.version})"
      echo "    Commands:"
      echo "    - tree -L 2                    # Show 2 levels deep"
      echo "    - tree -I 'node_modules'       # Exclude patterns"
      echo ""
      echo "duf: (v${pkgs.duf.version})"
      echo "    Commands:"
      echo "    - duf                         # Show disk usage"
      echo "    - duf --all                   # Show all filesystems"
      echo ""
      echo "htop: (v${pkgs.htop.version})"
      echo "    Commands:"
      echo "    - htop                        # Interactive process viewer"
      echo "    - htop -p PID                 # Monitor specific process"
      echo ""
      echo "jq: (v${pkgs.jq.version})"
      echo "    Commands:"
      echo "    - jq '.' file.json            # Pretty print JSON"
      echo "    - jq '.key' file.json         # Extract value"
      echo ""
      echo "code-cursor: (v${pkgs.code-cursor.version})"
      echo "    Commands:"
      echo "    - code-cursor .                 # Launch code-cursor editor"
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
      echo "   flake8 .                      # Lint code"
      echo "   mypy .                        # Type check"
      echo ""
      echo "3. Development workflow:"
      echo "   gh pr create                  # Create pull request"
      echo "   act -l                        # List GitHub Actions"
      echo "   just test                     # Run tests"
      echo ""
      echo "4. Code quality:"
      echo "   pre-commit run               # Run all hooks"
      echo "   nixpkgs-fmt .                # Format Nix files"
      echo "   shellcheck scripts/          # Lint shell scripts"
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
