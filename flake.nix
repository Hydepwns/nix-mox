{
  # Flake outputs:
  # - devShells.default: Development shell with common tools for working on this repo
  # - formatter: Nix code formatter (nixpkgs-fmt)
  # - packages.<system>.proxmox-update: Proxmox update script as a Nix package
  # - packages.<system>.vzdump-backup: Proxmox vzdump backup script as a Nix package
  # - packages.<system>.zfs-snapshot: ZFS snapshot/prune script as a Nix package

  description = "Proxmox templates + NixOS workstation + Windows gaming automation";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  nixConfig = {
    extra-substituters = [
      "https://hydepwns.cachix.org"
      "https://nix-mox.cachix.org"
    ];
    extra-trusted-public-keys = [
      "hydepwns.cachix.org-1:xg8huKdwzBkLdkq5eCKenadhCROHIICGI9H6y3simJU="
      "nix-mox.cachix.org-1:MVJZxC7ZyRFAxVsxDuq0nmMRxlTIt5nFFm4Ur10ZCI4="
    ];
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    let
      config = import ./config/default.nix;
      helpers = import ./lib/helpers.nix { inherit nixpkgs; };

      nixosModules = {
        nix-mox = import ./modules/core/nix-mox.nix;
        templates = import ./modules/core/templates.nix;
        infisical = import ./modules/services/infisical.nix;
        tailscale = import ./modules/services/tailscale.nix;
        zfs-auto-snapshot = import ./modules/storage/zfs-auto-snapshot.nix;
        error-handling = import ./modules/storage/error-handling.nix;
      };

      overlays = {
        default = final: prev: {
          nix-mox = self.packages.${prev.system};
        };
      };
    in
      flake-utils.lib.eachDefaultSystem (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          linuxPackages = import ./packages/linux { inherit pkgs helpers config; };
          windowsPackages = import ./packages/windows { inherit pkgs helpers config; };
          devShell = import ./shells/default.nix { inherit pkgs; };
          allPackages = linuxPackages // windowsPackages;
        in
        {
          inherit overlays;
          inherit nixosModules;
          devShells = {
            default = devShell;
          };
          packages = allPackages // {
            all = pkgs.symlinkJoin {
              name = "all";
              paths = builtins.attrValues allPackages;
            };
          };
          formatter = pkgs.nixpkgs-fmt;
          checks = {
            zfs-ssd-caching = pkgs.callPackage ./tests/storage/zfs-ssd-caching { };
            test-windows-gaming-template = pkgs.stdenv.mkDerivation {
              name = "test-windows-gaming-template";
              src = self;
              nativeBuildInputs = [ pkgs.nushell ];
              buildPhase = ''
                # Test that the script exists and is executable
                test -f ${windowsPackages.install-steam-rust}/bin/install-steam-rust.nu
                test -x ${windowsPackages.install-steam-rust}/bin/install-steam-rust.nu
              '';
              installPhase = ''
                mkdir -p $out
                touch $out/success
              '';
            };
          };
        }
      ) // {
        nixosModules = nixosModules;
        overlays.default = overlays.default;
      };
}
