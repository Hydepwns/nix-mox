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
    pkgs.bats          # Bash Automated Testing System
    pkgs.shellspec     # Shell testing framework
    pkgs.shunit2       # Shell unit testing framework
    pkgs.bashcov       # Bash code coverage
    pkgs.shellcheck    # Shell script analysis
    pkgs.bashate       # Bash script style checker
    pkgs.bashdb        # Bash debugger
    pkgs.bash-completion # Bash completion
    pkgs.bash-preexec  # Bash preexec hook
    pkgs.bash-it       # Bash framework
    pkgs.bash_unit     # Bash unit testing
    pkgs.bashcov       # Bash code coverage
    pkgs.bashate       # Bash script style checker
    pkgs.bashdb        # Bash debugger
    pkgs.bash-completion # Bash completion
    pkgs.bash-preexec  # Bash preexec hook
    pkgs.bash-it       # Bash framework
    pkgs.bash_unit     # Bash unit testing

    # Test data generation
    pkgs.fakeroot      # Fake root privileges
    pkgs.fakeroot-ng   # Next generation fakeroot
    pkgs.fakechroot    # Fake chroot
    pkgs.fakeroot-ng   # Next generation fakeroot
    pkgs.fakechroot    # Fake chroot

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
    echo "  - Testing frameworks:"
    echo "    - bats (Bash Automated Testing System)"
    echo "    - shellspec (Shell testing framework)"
    echo "    - shunit2 (Shell unit testing framework)"
    echo "    - bash_unit (Bash unit testing)"
    echo "  - Code quality tools:"
    echo "    - shellcheck (Shell script analysis)"
    echo "    - bashate (Bash script style checker)"
    echo "    - bashcov (Bash code coverage)"
    echo "  - Debugging tools:"
    echo "    - bashdb (Bash debugger)"
    echo "  - Test data generation:"
    echo "    - fakeroot (Fake root privileges)"
    echo "    - fakechroot (Fake chroot)"
    echo "  - Test reporting:"
    echo "    - jq (JSON processor)"
    echo "    - yq (YAML processor)"
    echo "    - xmlstarlet (XML processor)"
    echo ""
    echo "Run 'bats tests/' to run the test suite."
  '';
}
