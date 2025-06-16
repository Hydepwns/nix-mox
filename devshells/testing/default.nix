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

    # Elixir and Erlang
    pkgs.elixir
    pkgs.erlang

    # Testing frameworks
    pkgs.bats          # Bash Automated Testing System
    pkgs.shellspec     # Shell testing framework
    pkgs.shunit2       # Shell unit testing framework
    pkgs.bash_unit     # Bash unit testing

    # Code quality tools
    pkgs.shellcheck    # Shell script analysis
    pkgs.bashate       # Bash script style checker

    # Debugging tools
    # Only include bashdb on Linux
    # pkgs.bashdb        # Bash debugger (Linux only)
    pkgs.bash-completion # Bash completion
    pkgs.bash-preexec  # Bash preexec hook

    # Test data generation
    pkgs.fakeroot      # Fake root privileges
    # pkgs.fakechroot    # Fake chroot (Linux only)

    # Test reporting
    pkgs.jq            # JSON processor
    pkgs.yq            # YAML processor
    pkgs.xmlstarlet    # XML processor
    pkgs.html-xml-utils # HTML/XML utilities
  ];

  shellHook = ''
    echo "Welcome to the nix-mox testing shell!"
    echo "Available tools:"
    echo "  - Base tools (from default shell)"
    echo "  - Elixir and Erlang"
    echo ""
    echo "🔧 Testing Tools"
    echo "--------------"
    echo "1. Run Tests with Summarization:"
    echo "   # Run tests with summarize-tests.sh"
    echo "   ./tests/summarize-tests.sh"
    echo ""
    echo "2. BATS (Bash Automated Testing):"
    echo "   # Run all tests"
    echo "   bats tests/"
    echo ""
    echo "   # Run specific test"
    echo "   bats tests/my_test.bats"
    echo ""
    echo "3. ShellSpec:"
    echo "   # Run all specs"
    echo "   shellspec"
    echo ""
    echo "   # Run specific spec"
    echo "   shellspec spec/my_spec.sh"
    echo ""
    echo "4. Code Quality:"
    echo "   # Run shellcheck"
    echo "   shellcheck scripts/*.sh"
    echo ""
    echo "   # Run bashate"
    echo "   bashate scripts/*.sh"
    echo ""
    echo "📝 Testing Patterns"
    echo "-----------------"
    echo "1. Test Development:"
    echo "   [Write] -> [Run] -> [Debug] -> [Refine]"
    echo "   [Test] -> [Execute] -> [Analyze] -> [Improve]"
    echo ""
    echo "2. Test Execution:"
    echo "   [Unit] -> [Integration] -> [System] -> [Acceptance]"
    echo "   [Component] -> [Interface] -> [End-to-end] -> [User]"
    echo ""
    echo "3. Test Reporting:"
    echo "   [Results] -> [Analysis] -> [Documentation] -> [Action]"
    echo "   [Data] -> [Metrics] -> [Reports] -> [Improvements]"
    echo ""
    echo "🔍 Testing Architecture"
    echo "---------------------"
    echo "                    [Test Suite]"
    echo "                        ↑"
    echo "                        |"
    echo "        +---------------+---------------+"
    echo "        ↓               ↓               ↓"
    echo "  [Unit Tests]    [Integration]    [System Tests]"
    echo "        ↑               ↑               ↑"
    echo "        |               |               |"
    echo "  [Components]    [Interfaces]     [End-to-End]"
    echo "        ↑               ↑               ↑"
    echo "        |               |               |"
    echo "  [Functions]     [Services]       [Workflows]"
    echo ""
    echo "📚 Configuration Examples"
    echo "----------------------"
    echo "1. Running Tests with Summarization:"
    echo "   # Make sure the script is executable"
    echo "   chmod +x tests/summarize-tests.sh"
    echo ""
    echo "   # Run tests with summarization"
    echo "   ./tests/summarize-tests.sh"
    echo ""
    echo "2. BATS Test Example (test_example.bats):"
    echo "   #!/usr/bin/env bats"
    echo ""
    echo "   @test 'addition using bc' {"
    echo "     result='$(echo 2+2 | bc)'"
    echo "     [ '$result' -eq 4 ]"
    echo "   }"
    echo ""
    echo "   @test 'addition using dc' {"
    echo "     result='$(echo 2 2+p | dc)'"
    echo "     [ '$result' -eq 4 ]"
    echo "   }"
    echo ""
    echo "3. Test Data Generation:"
    echo "   # Create test environment"
    echo "   fakeroot bash -c '"
    echo "     mkdir -p /test/dir"
    echo "     chown nobody:nogroup /test/dir"
    echo "   '"
    echo ""
    echo "4. Test Reporting:"
    echo "   # Generate JUnit XML"
    echo "   bats --formatter junit tests/ > test-results.xml"
    echo ""
    echo "   # Generate HTML report"
    echo "   bats --formatter tap tests/ | tap2junit > test-results.xml"
    echo "   junit2html test-results.xml test-report.html"
    echo ""
    echo "5. Continuous Integration:"
    echo "   # GitHub Actions workflow"
    echo "   name: Tests"
    echo "   on: [push, pull_request]"
    echo "   jobs:"
    echo "     test:"
    echo "       runs-on: ubuntu-latest"
    echo "       steps:"
    echo "         - uses: actions/checkout@v3"
    echo "         - uses: DeterminateSystems/nix-installer-action@main"
    echo "         - uses: DeterminateSystems/magic-nix-cache-action@main"
    echo "         - run: ./tests/summarize-tests.sh"
    echo "         - run: bats tests/"
    echo "         - run: shellspec"
    echo "         - run: shellcheck scripts/*.sh"
    echo ""
    echo "For more information, see the testing documentation."
  '';
}
