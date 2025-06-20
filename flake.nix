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
    nix-mox = {
      url = "github:Hydepwns/nix-mox";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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

  outputs = { self, nixpkgs, flake-utils, nix-mox, home-manager, ... }@inputs:
    let
      supportedSystems = [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" "aarch64-linux" ];
    in
      flake-utils.lib.eachSystem supportedSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
            config.darwinConfig = if pkgs.stdenv.isDarwin then {
              system = system;
            } else {};
          };
          devShell = import ./devshells/default.nix { inherit pkgs; };
          helpers = import ./modules/packages/error-handling/helpers.nix {
            inherit pkgs;
          } // {
            readScript = path: builtins.readFile (self + "/${path}");
          };
          linuxPackages = if pkgs.stdenv.isLinux then
            import ./modules/packages/linux/default.nix {
              inherit pkgs;
              config = import ./config/default.nix { inherit inputs; };
              helpers = helpers;
            }
          else {};
        in
        {
          devShells = {
            default = devShell.default;
            development = devShell.development;
            testing = devShell.testing;
            services = devShell.services;
            monitoring = devShell.monitoring;
          } // (if pkgs.stdenv.isLinux && pkgs.system == "x86_64-linux" then {
            gaming = devShell.gaming;
            zfs = devShell.zfs;
          } else if pkgs.stdenv.isLinux then {
            zfs = devShell.zfs;
          } else if pkgs.stdenv.isDarwin then {
            macos = devShell.macos;
          } else {});
          formatter = pkgs.nixpkgs-fmt;
          packages = if pkgs.stdenv.isLinux then {
            proxmox-update = linuxPackages.proxmox-update;
            vzdump-backup = linuxPackages.vzdump-backup;
            zfs-snapshot = linuxPackages.zfs-snapshot;
            nixos-flake-update = linuxPackages.nixos-flake-update;
            install = linuxPackages.install;
            uninstall = linuxPackages.uninstall;
            default = linuxPackages.proxmox-update;
          } else {};
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
              nu -c "source scripts/tests/unit/unit-tests.nu"
              touch $out
            '';

            # Integration tests only
            integration = pkgs.runCommand "nix-mox-integration-tests" {
              buildInputs = [ pkgs.nushell ];
            } ''
              cp -r ${src} $TMPDIR/src
              cd $TMPDIR/src
              export TEST_TEMP_DIR=$TMPDIR/nix-mox-integration
              nu -c "source scripts/tests/integration/integration-tests.nu"
              touch $out
            '';

            # Full suite
            test-suite = pkgs.runCommand "nix-mox-tests" {
              buildInputs = [ pkgs.nushell ];
            } ''
              cp -r ${src} $TMPDIR/src
              cd $TMPDIR/src
              export TEST_TEMP_DIR=$TMPDIR/nix-mox-tests
              nu -c "source scripts/tests/run-tests.nu; run []"
              touch $out
            '';
          };
        }
      ) // {
        # NixOS configurations - now imported from config directory
        nixosConfigurations = import ./config { inherit inputs; };
      };
}
