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
      nixosModules = {
        nix-mox = import ./modules/nix-mox.nix;
        # zfs-auto-snapshot = import ./modules/zfs-auto-snapshot.nix;
        # infisical = import ./modules/infisical.nix;
        # tailscale = import ./modules/tailscale.nix;
      };

      # Overlay to easily add nix-mox packages to nixpkgs
      overlay = final: prev: {
        nix-mox = self.packages.${prev.system};
      };
    in
      flake-utils.lib.eachDefaultSystem (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          # Flag to control Infisical inclusion
          enableInfisical = builtins.getEnv "ENABLE_INFISICAL" == "0";

          # Infisical CLI version and hashes
          infisicalVersion = "0.22.0";
          infisicalHashes = {
            "x86_64-linux" = "sha256:0j906p5j3q5qxqxzv8z2w3f8g1zsqwyq5j5d1d6h7yq1cc6y7352";
            "aarch64-linux" = "sha256:1nwv9i5ahq6z09aqgq0z7pf2z3i9zylwgy9wjjdf2bmz7r5k1sga";
            "x86_64-darwin" = "sha256:12wwn9f38vif8g4xsmb3is99gq7i9c5k8a3m3z6v9v395q8c5211";
            "aarch64-darwin" = "sha256:0q4r8kw7flg19q3nalb7cfc8g7k4g1v8cwv39b2a7p2q5k4w51c7";
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

          isLinux = builtins.elem system [ "x86_64-linux" "aarch64-linux" ];

          install-steam-rust-pkg = pkgs.writeTextFile {
            name = "install-steam-rust.nu";
            destination = "/bin/install-steam-rust.nu";
            text = ''
              #!${pkgs.nushell}/bin/nu
              ${builtins.readFile ./scripts/windows/install-steam-rust.nu}
            '';
            executable = true;
          };

          allPackages = {
            "error-handling" = pkgs.callPackage ./packages/error-handling { };
            vzdump-backup = if isLinux then pkgs.writeShellApplication {
              name = "vzdump-backup";
              runtimeInputs = [ pkgs.proxmox-backup-client pkgs.qemu pkgs.lxc pkgs.bash pkgs.coreutils pkgs.gawk ];
              text = builtins.readFile ./scripts/linux/vzdump-backup.nu;
              meta = {
                description = "Backup all Proxmox VMs and containers to specified storage.";
                platforms = [ "x86_64-linux" "aarch64-linux" ];
              };
            } else null;
            zfs-snapshot = if isLinux then pkgs.writeShellApplication {
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
              text = builtins.readFile ./scripts/linux/zfs-snapshot.nu;
              meta = {
                description = "Create and prune ZFS snapshots for the specified pool.";
                platforms = [ "x86_64-linux" "aarch64-linux" ];
              };
            } else null;
            nixos-flake-update = if isLinux then pkgs.writeShellApplication {
              name = "nixos-flake-update";
              runtimeInputs = [ pkgs.nix pkgs.bash pkgs.coreutils ];
              text = builtins.readFile ./scripts/linux/nixos-flake-update.nu;
              meta = {
                description = "Update flake inputs and rebuild NixOS system.";
                platforms = [ "x86_64-linux" "aarch64-linux" ];
              };
            } else null;
            install = if isLinux then pkgs.writeScriptBin "nix-mox-install" ''
              #!${pkgs.bash}/bin/bash
              ${builtins.readFile ./scripts/linux/install.nu}
            '' else null;
            uninstall = if isLinux then let
              commonSh = builtins.readFile ./scripts/linux/_common.nu;
              uninstallSh = builtins.readFile ./scripts/linux/uninstall.nu;
            in pkgs.writeShellApplication {
              name = "nix-mox-uninstall";
              runtimeInputs = [ pkgs.bash pkgs.coreutils ];
              text = ''
                #!${pkgs.bash}/bin/bash
                set -euo pipefail

                # Write _common.nu to a temp file
                common_sh=$(mktemp)
                cat > "$common_sh" <<'EOF'
${commonSh}
EOF

                # Source common functions
                source "$common_sh"

                # Main uninstall logic
${uninstallSh}
              '';
              meta = {
                description = "Legacy/compat uninstall logic for nix-mox scripts.";
                platforms = [ "x86_64-linux" "aarch64-linux" ];
              };
            } else null;
            install-steam-rust = install-steam-rust-pkg;
            windows-automation-assets-sources = pkgs.stdenv.mkDerivation {
              name = "windows-automation-assets-sources";
              src = ./scripts/windows;
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
          } // (if enableInfisical then { infisical-cli = infisical-cli; } else {});
          proxmoxUpdate = if isLinux then {
            proxmox-update = pkgs.writeShellApplication {
              name = "proxmox-update";
              runtimeInputs = [ pkgs.apt pkgs.bash pkgs.coreutils ];
              text = builtins.readFile ./scripts/linux/proxmox-update.nu;
              meta = {
                description = "Update and upgrade Proxmox host packages safely.";
                platforms = [ "x86_64-linux" "aarch64-linux" ];
              };
            };
          } else {};

          apps =
            if isLinux then {
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
            } else {};

          # Development shell with all required tools
          devShells.default = pkgs.mkShell {
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
              echo "Run 'nu tests/run-tests.nu' to run the test suite."
            '';
          };
        in
        {
          inherit overlay;
          inherit nixosModules;
          inherit devShells;
          inherit apps;
          packages = allPackages // proxmoxUpdate;
          formatter = pkgs.nixpkgs-fmt;
          checks = {
            # Run the ZFS SSD caching tests
            zfs-ssd-caching = pkgs.callPackage ./tests/zfs-ssd-caching { };
            test-windows-gaming-template = pkgs.stdenv.mkDerivation {
              name = "test-windows-gaming-template";
              src = self;
              nativeBuildInputs = [ pkgs.nushell ];
              buildPhase = ''
                # Test that the script exists and is executable
                test -f ${install-steam-rust-pkg}/bin/install-steam-rust.nu
                test -x ${install-steam-rust-pkg}/bin/install-steam-rust.nu
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
        overlays.default = overlay;
      };
}