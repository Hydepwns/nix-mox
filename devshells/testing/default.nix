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

    # Testing tools (essential only)
    pkgs.bats           # Bash Automated Testing System
    pkgs.shellspec      # Shell script testing framework
    pkgs.bash           # Bash shell for testing
    pkgs.python3        # Python for testing
    pkgs.python3Packages.pytest  # Python testing framework
    pkgs.python3Packages.coverage # Python code coverage

    # Code quality tools
    pkgs.shellcheck     # Shell script analysis

    # Test reporting
    pkgs.jq             # JSON processor
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
      echo ""
      echo "shellspec: (v${pkgs.shellspec.version})"
      echo "    Commands:"
      echo "    - shellspec                     # Run all specs"
      echo "    - shellspec --format documentation"
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
      echo "shellcheck: (v${pkgs.shellcheck.version})"
      echo "    Commands:"
      echo "    - shellcheck scripts/*.sh       # Check shell scripts"
      echo "    - shellcheck -x scripts/*.sh    # Check with shell specified"
      echo ""
      echo "jq: (v${pkgs.jq.version})"
      echo "    Commands:"
      echo "    - jq '.' file.json            # Pretty print JSON"
      echo "    - jq '.key' file.json         # Extract value"
      echo ""
      echo "📝 Quick Start"
      echo "------------"
      echo "1. Run shell tests:"
      echo "   bats tests/                     # Run BATS tests"
      echo "   shellspec                       # Run ShellSpec tests"
      echo ""
      echo "2. Run Python tests:"
      echo "   pytest                          # Run all tests"
      echo "   coverage run -m pytest          # With coverage"
      echo ""
      echo "3. Code quality:"
      echo "   shellcheck scripts/             # Lint shell scripts"
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
