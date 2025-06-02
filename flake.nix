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
      };
    in
      flake-utils.lib.eachDefaultSystem (system:
        let
          pkgs = import nixpkgs { inherit system; };
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
            # Proxmox update script: updates and upgrades Proxmox host packages
            proxmox-update = pkgs.writeShellApplication {
              name = "proxmox-update";
              runtimeInputs = [ pkgs.apt pkgs.pve-manager pkgs.bash pkgs.coreutils ];
              text = builtins.readFile ./scripts/linux/proxmox-update.sh;
            };
            # Proxmox vzdump backup script: backs up all VMs and containers to specified storage
            vzdump-backup = pkgs.writeShellApplication {
              name = "vzdump-backup";
              runtimeInputs = [ pkgs.proxmox-backup-client pkgs.qemu pkgs.lxc pkgs.bash pkgs.coreutils pkgs.gawk ];
              text = builtins.readFile ./scripts/linux/vzdump-backup.sh;
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
            };
            # NixOS flake update script: updates flake inputs and rebuilds
            nixos-flake-update = pkgs.writeShellApplication {
              name = "nixos-flake-update";
              runtimeInputs = [ pkgs.nix pkgs.bash pkgs.coreutils ];
              text = builtins.readFile ./scripts/linux/nixos-flake-update.sh;
            };
            # Install script: legacy/compat install logic
            install = pkgs.writeShellApplication {
              name = "nix-mox-install";
              runtimeInputs = [ pkgs.bash pkgs.coreutils ];
              text = builtins.readFile ./scripts/linux/install.sh;
            };
            # Uninstall script: legacy/compat uninstall logic
            uninstall = pkgs.writeShellApplication {
              name = "nix-mox-uninstall";
              runtimeInputs = [ pkgs.bash pkgs.coreutils ];
              text = builtins.readFile ./scripts/linux/uninstall.sh;
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
          };
        }
      ) // { nixosModules = nixosModules; };
}