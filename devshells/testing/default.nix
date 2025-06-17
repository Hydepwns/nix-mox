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

    # Testing tools
    pkgs.bats           # Bash Automated Testing System
    pkgs.shellspec      # Shell script testing framework
    pkgs.shunit2        # Shell unit testing framework
    pkgs.bash           # Bash shell for testing
    pkgs.zsh            # Zsh shell for testing
    pkgs.fish           # Fish shell for testing
    pkgs.nushell        # Nushell for testing
    pkgs.python3        # Python for testing
    pkgs.python3Packages.pytest  # Python testing framework
    pkgs.python3Packages.coverage # Python code coverage
    pkgs.mypy           # Python type checking
    pkgs.black          # Python code formatter
    pkgs.python3Packages.flake8  # Python linter
    pkgs.nodejs         # Node.js for testing
    pkgs.nodePackages.mocha # JavaScript testing framework
    pkgs.typescript     # TypeScript for testing
    pkgs.eslint         # JavaScript linter
    pkgs.prettier       # JavaScript formatter

    # Testing frameworks
    pkgs.elixir         # Elixir for testing
    pkgs.erlang         # Erlang runtime
    pkgs.rebar3         # Erlang build tool
    pkgs.hex            # Elixir package manager
    pkgs.ex_doc         # Documentation generator

    # Code quality tools
    pkgs.shellcheck     # Shell script analysis
    pkgs.bashate        # Bash script style checker

    # Debugging tools
    # Only include bashdb on Linux
    # pkgs.bashdb        # Bash debugger (Linux only)
    pkgs.bash-completion # Bash completion
    pkgs.bash-preexec   # Bash preexec hook

    # Test data generation
    pkgs.fakeroot       # Fake root privileges
    # pkgs.fakechroot    # Fake chroot (Linux only)

    # Test reporting
    pkgs.jq             # JSON processor
    pkgs.yq             # YAML processor
    pkgs.xmlstarlet     # XML processor
    pkgs.html-xml-utils # HTML/XML utilities
  ];

  shellHook = ''
    # Function to show help menu
    show_help() {
      echo "Welcome to the nix-mox testing shell!"
      echo ""
      echo "🔧 Testing Tools"
      echo "----------------"
      echo "bats: (v${pkgs.bats.version})"
      echo "    Commands:"
      echo "    - bats tests/                   # Run all tests"
      echo "    - bats -t test.bats            # Run specific test"
      echo "    Dependencies:"
      echo "    - Requires: bash"
      echo ""
      echo "shellspec: (v${pkgs.shellspec.version})"
      echo "    Commands:"
      echo "    - shellspec                     # Run all specs"
      echo "    - shellspec --format documentation"
      echo "    Configuration:"
      echo "    - .shellspec"
      echo ""
      echo "shunit2: (v${pkgs.shunit2.version})"
      echo "    Commands:"
      echo "    - ./test.sh                     # Run shell unit tests"
      echo "    - shunit2 test.sh              # Run with shunit2"
      echo ""
      echo "Python Testing:"
      echo "pytest: (v${pkgs.python3Packages.pytest.version})"
      echo "    Commands:"
      echo "    - pytest                        # Run all tests"
      echo "    - pytest -v                     # Verbose output"
      echo "    - pytest --cov                  # With coverage"
      echo ""
      echo "coverage: (v${pkgs.python3Packages.coverage.version})"
      echo "    Commands:"
      echo "    - coverage run -m pytest        # Run tests with coverage"
      echo "    - coverage report               # Show coverage report"
      echo ""
      echo "mypy: (v${pkgs.mypy.version})"
      echo "    Commands:"
      echo "    - mypy .                        # Type check"
      echo "    - mypy --strict .              # Strict type checking"
      echo ""
      echo "black: (v${pkgs.black.version})"
      echo "    Commands:"
      echo "    - black .                       # Format Python code"
      echo "    - black --check .              # Check formatting"
      echo ""
      echo "flake8: (v${pkgs.python3Packages.flake8.version})"
      echo "    Commands:"
      echo "    - flake8 .                      # Lint Python code"
      echo "    - flake8 --max-line-length=100"
      echo ""
      echo "JavaScript Testing:"
      echo "jest: (v${pkgs.nodePackages.mocha.version})"
      echo "    Commands:"
      echo "    - jest                          # Run all tests"
      echo "    - jest --watch                  # Watch mode"
      echo "    - jest --coverage               # With coverage"
      echo ""
      echo "typescript: (v${pkgs.typescript.version})"
      echo "    Commands:"
      echo "    - tsc --noEmit                  # Type check"
      echo "    - tsc --watch                   # Watch mode"
      echo ""
      echo "eslint: (v${pkgs.eslint.version})"
      echo "    Commands:"
      echo "    - eslint .                      # Lint JavaScript"
      echo "    - eslint --fix .               # Fix issues"
      echo ""
      echo "prettier: (v${pkgs.prettier.version})"
      echo "    Commands:"
      echo "    - prettier --write .            # Format code"
      echo "    - prettier --check .           # Check formatting"
      echo ""
      echo "📝 Quick Start"
      echo "------------"
      echo "1. Run shell tests:"
      echo "   bats tests/                     # Run BATS tests"
      echo "   shellspec                       # Run ShellSpec tests"
      echo "   ./test.sh                       # Run shunit2 tests"
      echo ""
      echo "2. Run Python tests:"
      echo "   pytest                          # Run all tests"
      echo "   coverage run -m pytest          # With coverage"
      echo "   mypy .                          # Type check"
      echo ""
      echo "3. Run JavaScript tests:"
      echo "   jest                            # Run all tests"
      echo "   tsc --noEmit                    # Type check"
      echo "   eslint .                        # Lint code"
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
    alias which-shell='echo "You are in the nix-mox testing shell"'
  '';
}
