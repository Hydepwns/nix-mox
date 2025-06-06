{
  # Flake outputs:
  # - devShells.default: Development shell with common tools for working on this repo
  # - formatter: Nix code formatter (nixpkgs-fmt)
  # - packages.<system>.proxmox-update: Proxmox update script as a Nix package
  # - packages.<system>.vzdump-backup: Proxmox vzdump backup script as a Nix package
  # - packages.<system>.zfs-snapshot: ZFS snapshot/prune script as a Nix package

  description = "Proxmox + NixOS + Windows automation flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    let
      nixosModules = {
        nix-mox = import ./modules/nix-mox.nix;
        zfs-auto-snapshot = import ./modules/zfs-auto-snapshot.nix;
        infisical = import ./modules/infisical.nix;
        tailscale = import ./modules/tailscale.nix;
      };

      # Overlay to easily add nix-mox packages to nixpkgs
      overlay = final: prev: {
        nix-mox = self.packages.${prev.system};
      };
    in
      flake-utils.lib.eachDefaultSystem (system:
        let
          pkgs = import nixpkgs { inherit system; };

          # Infisical CLI version and hashes
          infisicalVersion = "0.22.0";
          infisicalHashes = {
            "x86_64-linux" = "sha256-0j906p5j3q5qxqxzv8z2w3f8g1zsqwyq5j5d1d6h7yq1cc6y7352";
            "aarch64-linux" = "sha256-1nwv9i5ahq6z09aqgq0z7pf2z3i9zylwgy9wjjdf2bmz7r5k1sga";
            "x86_64-darwin" = "sha256-12wwn9f38vif8g4xsmb3is99gq7i9c5k8a3m3z6v9v395q8c5211";
            "aarch64-darwin" = "sha256-0q4r8kw7flg19q3nalb7cfc8g7k4g1v8cwv39b2a7p2q5k4w51c7";
          };
          infisicalPlatform = {
            "x86_64-linux" = "linux_amd64";
            "aarch64-linux" = "linux_arm64";
            "x86_64-darwin" = "darwin_amd64";
            "aarch64-darwin" = "darwin_arm64";
          };

          # Infisical CLI package
          infisical-cli = pkgs.stdenv.mkDerivation {
            pname = "infisical-cli";
            version = infisicalVersion;
            src = pkgs.fetchurl {
              url = "https://cli.infisical.com/infisical_${infisicalVersion}_${infisicalPlatform.${system}}.tar.gz";
              hash = infisicalHashes.${system};
            };
            sourceRoot = ".";
            installPhase = ''
              mkdir -p $out/bin
              install -m 755 infisical $out/bin/infisical
            '';
            meta = {
              description = "Infisical CLI for secret management";
              homepage = "https://infisical.com/";
              license = pkgs.lib.licenses.mit;
              platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
            };
          };
        in {
          # Development shell with common tools for working on this repository
          # Usage: nix develop
          # Provides a shell with git, nix, bash, shellcheck, nushell, coreutils, nixpkgs-fmt, fd, and ripgrep for development and testing.
          devShells.default = pkgs.mkShell {
            buildInputs = [
              pkgs.git            # Version control
              pkgs.nix            # Nix package manager
              pkgs.bashInteractive # Interactive Bash shell
              pkgs.shellcheck     # Shell script linter
              pkgs.nushell        # NuShell for Windows automation
              pkgs.coreutils      # GNU core utilities
              pkgs.nixpkgs-fmt    # Nix code formatter
              pkgs.fd             # Fast file search
              pkgs.ripgrep        # Fast text search
            ];
          };
          # Nix code formatter (nixpkgs-fmt)
          # Usage: nix fmt
          # Formats all Nix files in the repository for consistent style.
          formatter = pkgs.nixpkgs-fmt;
          packages = {
            # Infisical CLI for secret management
            infisical-cli = infisical-cli;
            # Proxmox update script: updates and upgrades Proxmox host packages
            proxmox-update = pkgs.writeShellApplication {
              name = "proxmox-update";
              runtimeInputs = [ pkgs.apt pkgs.pve-manager pkgs.bash pkgs.coreutils ];
              text = builtins.readFile ./scripts/linux/proxmox-update.sh;
              meta = {
                description = "Update and upgrade Proxmox host packages safely.";
              };
            };
            # Proxmox vzdump backup script: backs up all VMs and containers to specified storage
            vzdump-backup = pkgs.writeShellApplication {
              name = "vzdump-backup";
              runtimeInputs = [ pkgs.proxmox-backup-client pkgs.qemu pkgs.lxc pkgs.bash pkgs.coreutils pkgs.gawk ];
              text = builtins.readFile ./scripts/linux/vzdump-backup.sh;
              meta = {
                description = "Backup all Proxmox VMs and containers to specified storage.";
              };
            };
            # ZFS snapshot/prune script: creates and prunes ZFS snapshots for the specified pool
            zfs-snapshot = pkgs.writeShellApplication {
              name = "zfs-snapshot";
              runtimeInputs = [
                pkgs.zfs
                pkgs.bash
                pkgs.coreutils
                pkgs.gnugrep
                pkgs.gawk
                pkgs.gnused
                pkgs.gnutar
              ];
              text = builtins.readFile ./scripts/linux/zfs-snapshot.sh;
              meta = {
                description = "Create and prune ZFS snapshots for the specified pool.";
              };
            };
            # NixOS flake update script: updates flake inputs and rebuilds
            nixos-flake-update = pkgs.writeShellApplication {
              name = "nixos-flake-update";
              runtimeInputs = [ pkgs.nix pkgs.bash pkgs.coreutils ];
              text = builtins.readFile ./scripts/linux/nixos-flake-update.sh;
              meta = {
                description = "Update flake inputs and rebuild NixOS system.";
              };
            };
            # Install script: legacy/compat install logic
            install = pkgs.writeShellApplication {
              name = "nix-mox-install";
              runtimeInputs = [ pkgs.bash pkgs.coreutils ];
              text = builtins.readFile ./scripts/linux/install.sh;
              meta = {
                description = "Legacy/compat install logic for nix-mox scripts.";
              };
            };
            # Uninstall script: legacy/compat uninstall logic
            uninstall = pkgs.writeShellApplication {
              name = "nix-mox-uninstall";
              runtimeInputs = [ pkgs.bash pkgs.coreutils ];
              text = builtins.readFile ./scripts/linux/uninstall.sh;
              meta = {
                description = "Legacy/compat uninstall logic for nix-mox scripts.";
              };
            };
            # Nushell script for Steam+Rust installation on Windows
            install-steam-rust = pkgs.writeShellApplication {
              name = "install-steam-rust";
              runtimeInputs = [ pkgs.nushell ]; # Requires nushell in PATH
              text = builtins.readFile ./scripts/windows/install-steam-rust.nu;
              meta = {
                description = "Automate Steam installation and prompt for Rust on Windows.";
                platforms = pkgs.lib.platforms.windows; # Indicate it's for Windows
              };
            };
            # Package bundling all Windows automation assets (source files)
            windows-automation-assets-sources = pkgs.stdenv.mkDerivation {
              name = "windows-automation-assets-sources";
              src = ./scripts/windows; # Source directory
              installPhase = ''
                mkdir -p $out
                cp $src/install-steam-rust.nu $out/
                cp $src/run-steam-rust.bat $out/
                cp $src/InstallSteamRust.xml $out/
              '';
              meta = {
                description = "Source files for Windows automation (Steam, Rust NuShell script, .bat, .xml). Requires Nushell on the Windows host.";
              };
            };
          };
          apps = {
            proxmox-update = {
              type = "app";
              program = "${self.packages.${system}.proxmox-update}/bin/proxmox-update";
              description = "Update and upgrade Proxmox host packages safely.";
            };
            vzdump-backup = {
              type = "app";
              program = "${self.packages.${system}.vzdump-backup}/bin/vzdump-backup";
              description = "Backup all Proxmox VMs and containers to specified storage.";
            };
            zfs-snapshot = {
              type = "app";
              program = "${self.packages.${system}.zfs-snapshot}/bin/zfs-snapshot";
              description = "Create and prune ZFS snapshots for the specified pool.";
            };
            nixos-flake-update = {
              type = "app";
              program = "${self.packages.${system}.nixos-flake-update}/bin/nixos-flake-update";
              description = "Update flake inputs and rebuild NixOS system.";
            };
            install = {
              type = "app";
              program = "${self.packages.${system}.install}/bin/nix-mox-install";
              description = "Legacy/compat install logic for nix-mox scripts.";
            };
            uninstall = {
              type = "app";
              program = "${self.packages.${system}.uninstall}/bin/nix-mox-uninstall";
              description = "Legacy/compat uninstall logic for nix-mox scripts.";
            };
            # Note: install-steam-rust is not added as an app here as it's Windows-specific
            # and `nix run` is typically used on the host (Linux/macOS).
            # Users should build .#windows-automation-assets and copy to Windows.
          };
        }
      ) // {
        nixosModules = nixosModules;
        overlays.default = overlay;
      };
}