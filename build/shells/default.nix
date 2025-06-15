{ pkgs }:
let
  # Import all shell configurations
  development = import ./development/default.nix { inherit pkgs; };
  testing = import ./testing/default.nix { inherit pkgs; };
  zfs = import ./storage/zfs.nix { inherit pkgs; };
  services = import ./services/default.nix { inherit pkgs; };
  monitoring = import ./monitoring/default.nix { inherit pkgs; };

  # Base development shell (current default)
  base = pkgs.mkShell {
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
      echo "Specialized shells available:"
      echo "  - development: Enhanced development environment"
      echo "  - testing: Testing and debugging environment"
      echo "  - zfs: ZFS development and testing environment"
      echo "  - services: Service development and management"
      echo "  - monitoring: Monitoring and observability tools"
      echo ""
      echo "Run 'nix develop .#<shell-name>' to use a specialized shell."
    '';
  };
in {
  # Expose all shells
  inherit base development testing zfs services monitoring;
  # Default shell
  default = base;
}
