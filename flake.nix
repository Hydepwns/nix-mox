{
  # Flake outputs:
  # - devShells.default: Development shell with common tools for working on this repo
  # - formatter: Nix code formatter (nixpkgs-fmt)
  # - packages.<system>.proxmox-update: Proxmox update script as a Nix package
  # - packages.<system>.vzdump-backup: Proxmox vzdump backup script as a Nix package
  # - packages.<system>.zfs-snapshot: ZFS snapshot/prune script as a Nix package
  # - packages.<system>.nixos-flake-update: NixOS flake update script as a Nix package
  # - packages.<system>.install: nix-mox installation script as a Nix package
  # - packages.<system>.uninstall: nix-mox uninstallation script as a Nix package

  description = "A comprehensive NixOS configuration framework with development tools, monitoring, and system management utilities";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    extra-substituters = [
      "https://hydepwns.cachix.org"
      "https://nix-mox.cachix.org"
      "https://cache.nixos.org"
    ];
    extra-trusted-public-keys = [
      "hydepwns.cachix.org-1:xg8huKdwzBkLdkq5eCKenadhCROHIICGI9H6y3simJU="
      "nix-mox.cachix.org-1:MVJZxC7ZyRFAxVsxDuq0nmMRxlTIt5nFFm4Ur10ZCI4="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };

  outputs = { self, nixpkgs, flake-utils, home-manager, ... }@inputs:
    let
      # Supported systems with clear documentation
      supportedSystems = [
        "aarch64-darwin"   # Apple Silicon Macs
        "x86_64-darwin"    # Intel Macs
        "x86_64-linux"     # Intel/AMD Linux
        "aarch64-linux"    # ARM Linux (Raspberry Pi, etc.)
      ];

      # Helper function to check if system is supported
      isSupported = system: builtins.elem system supportedSystems;

      # Helper function to get system-specific packages
      getSystemPackages = system: pkgs:
        if pkgs.stdenv.isLinux then
          import ./modules/packages/linux/default.nix {
            inherit pkgs;
            config = import ./config/default.nix { inherit inputs; };
            helpers = {
              readScript = path: builtins.readFile (self + "/${path}");
              isLinux = system: builtins.elem system [ "x86_64-linux" "aarch64-linux" ];
            };
          }
        else {};
    in
      flake-utils.lib.eachSystem supportedSystems (system:
        let
          # Import nixpkgs with proper configuration
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
            config.darwinConfig = if system == "aarch64-darwin" || system == "x86_64-darwin" then {
              system = system;
            } else {};
          };

          # Import development shell
          devShell = import ./devshells/default.nix { inherit pkgs; };

          # Get system-specific packages
          systemPackages = getSystemPackages system pkgs;

          # Helper functions
          helpers = {
            readScript = path: builtins.readFile (self + "/${path}");
            isLinux = system: builtins.elem system [ "x86_64-linux" "aarch64-linux" ];
          };
        in
        {
          # Development shells with platform-specific availability
          devShells = {
            default = devShell.default;
            development = devShell.development;
            testing = devShell.testing;
            services = devShell.services;
            monitoring = devShell.monitoring;
          } // (
            # Platform-specific shells
            if pkgs.stdenv.isLinux && system == "x86_64-linux" then {
              gaming = devShell.gaming;  # Gaming shell (Linux x86_64 only)
              zfs = devShell.zfs;        # ZFS tools (Linux only)
            } else if pkgs.stdenv.isLinux then {
              zfs = devShell.zfs;        # ZFS tools (Linux only)
            } else if pkgs.stdenv.isDarwin then {
              macos = devShell.macos;    # macOS development (macOS only)
            } else {}
          );

          # Code formatter
          formatter = pkgs.nixpkgs-fmt;

          # Packages (Linux only for system management tools)
          packages = if pkgs.stdenv.isLinux then {
            proxmox-update = systemPackages.proxmox-update;
            vzdump-backup = systemPackages.vzdump-backup;
            zfs-snapshot = systemPackages.zfs-snapshot;
            nixos-flake-update = systemPackages.nixos-flake-update;
            install = systemPackages.install;
            uninstall = systemPackages.uninstall;
            default = systemPackages.proxmox-update;
          } else {};

          # Test suite with proper error handling
          checks = let
            src = ./.;
          in {
            # Unit tests only
            unit = pkgs.runCommand "nix-mox-unit-tests" {
              buildInputs = [ pkgs.nushell ];
            } ''
              cp -r ${src} $TMPDIR/src
              cd $TMPDIR/src
              export TEST_TEMP_DIR=$TMPDIR/nix-mox-unit
              nu -c "source scripts/tests/unit/unit-tests.nu" || exit 1
              touch $out
            '';

            # Integration tests only
            integration = pkgs.runCommand "nix-mox-integration-tests" {
              buildInputs = [ pkgs.nushell ];
            } ''
              cp -r ${src} $TMPDIR/src
              cd $TMPDIR/src
              export TEST_TEMP_DIR=$TMPDIR/nix-mox-integration
              nu -c "source scripts/tests/integration/integration-tests.nu" || exit 1
              touch $out
            '';

            # Full test suite
            test-suite = pkgs.runCommand "nix-mox-tests" {
              buildInputs = [ pkgs.nushell ];
            } ''
              cp -r ${src} $TMPDIR/src
              cd $TMPDIR/src
              export TEST_TEMP_DIR=$TMPDIR/nix-mox-tests
              nu -c "source scripts/tests/run-tests.nu; run []" || exit 1
              touch $out
            '';
          };
        }
      ) // {
        # NixOS configurations - imported from config directory
        nixosConfigurations = import ./config { inherit inputs; };
      };
}
