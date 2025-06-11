{ pkgs }:
pkgs.mkShell {
  buildInputs = [
    pkgs.nushell
    pkgs.git
    pkgs.nix
    pkgs.nixpkgs-fmt
    pkgs.shellcheck
    pkgs.coreutils
    pkgs.fd
    pkgs.ripgrep
  ];
  shellHook = ''
    echo "Welcome to the nix-mox dev shell!"
    echo "Available tools:"
    echo "  - nu (Nushell)"
    echo "  - git"
    echo "  - nix"
    echo "  - nixpkgs-fmt"
    echo "  - shellcheck"
    echo "  - coreutils"
    echo "  - fd"
    echo "  - ripgrep"
    echo ""
    echo "Run 'nu scripts/run-tests.nu' to run the test suite."
  '';
} 