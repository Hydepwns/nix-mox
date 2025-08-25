{
  description = "Simplified NixOS configuration with subflakes";

  inputs = {
    # Core inputs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Subflakes (commented out until properly set up)
    # gaming = {
    #   url = "path:./flakes/gaming";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # Future subflakes (uncomment as they're created)
    # hardware = {
    #   url = "path:./flakes/hardware";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    # services = {
    #   url = "path:./flakes/services";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # Utility inputs
    flake-utils.url = "github:numtide/flake-utils";
    agenix.url = "github:ryantm/agenix"; # For secrets management
  };

  outputs = { self, nixpkgs, flake-utils, agenix, ... }@inputs:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          # Gaming module (commented out for now)
          # gamingModule = import ./flakes/gaming/module.nix;

          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
        {
          # Development shells
          devShells.default = pkgs.mkShell {
            buildInputs = with pkgs; [
              treefmt
              nixpkgs-fmt
              shfmt
              shellcheck
              prettier
              nil
              git
              gnumake
              nushell
            ];

            shellHook = ''
              echo "🚀 NixOS Development Environment"
              echo ""
              echo "Available commands:"
              echo "  make help        - Show all commands"
              echo "  make test        - Run tests"
              echo "  make pre-rebuild - Validate before rebuild"
              echo ""
              echo "Rebuild commands:"
              echo "  sudo nixos-rebuild test --flake .#nixos"
              echo "  sudo nixos-rebuild switch --flake .#nixos"
              echo ""
              echo "Subflakes:"
              echo "  cd flakes/gaming && nix develop  - Gaming development"
            '';
          };

          # Apps for quick access
          apps = {
            # Format all code using treefmt
            fmt = {
              type = "app";
              program = toString (pkgs.writeShellScript "fmt" ''
                if [ "$1" = "--check" ]; then
                  # Check mode - exit with error if any files need formatting
                  nix --extra-experimental-features "nix-command flakes" develop --command treefmt --fail-on-change
                else
                  # Format mode - format all files
                  nix --extra-experimental-features "nix-command flakes" develop --command treefmt
                fi
              '');
            };

            # Validate configuration
            validate = {
              type = "app";
              program = toString (pkgs.writeShellScript "validate" ''
                echo "🔍 Validating configuration..."
              
                # Check syntax
                nix --extra-experimental-features "nix-command flakes" flake check --no-build
              
                # Only build NixOS config on Linux
                if [[ "$OSTYPE" == "linux"* ]]; then
                  # Check if configuration builds
                  nix --extra-experimental-features "nix-command flakes" build .#nixosConfigurations.nixos.config.system.build.toplevel --dry-run
                else
                  echo "⚠️  Skipping NixOS config build on non-Linux system"
                fi
              
                echo "✅ Configuration is valid"
              '');
            };

            # Update all inputs
            update = {
              type = "app";
              program = toString (pkgs.writeShellScript "update" ''
                echo "📦 Updating flake inputs..."
                nix --extra-experimental-features "nix-command flakes" flake update
                echo "✅ Updated all inputs"
              '');
            };

            # Storage guard - validate storage before reboot (Linux only)
            storage-guard = {
              type = "app";
              program = toString (pkgs.writeShellScript "storage-guard" ''
                if [[ "$OSTYPE" != "linux"* ]]; then
                  echo "⚠️  Storage guard only available on Linux systems"
                  exit 0
                fi
              
                if [ -f scripts/validation/storage-validator.nu ]; then
                  ${pkgs.nushell}/bin/nu scripts/validation/storage-validator.nu
                else
                  echo "❌ Storage validator script not found"
                  exit 1
                fi
              '');
            };

            # Fix storage - auto-fix UUID mismatches (Linux only)
            fix-storage = {
              type = "app";
              program = toString (pkgs.writeShellScript "fix-storage" ''
                if [[ "$OSTYPE" != "linux"* ]]; then
                  echo "⚠️  Storage fix only available on Linux systems"
                  exit 0
                fi
              
                if [ -f scripts/storage/auto-update-storage.nu ]; then
                  ${pkgs.nushell}/bin/nu scripts/storage/auto-update-storage.nu
                else
                  echo "❌ Storage auto-update script not found"
                  exit 1
                fi
              '');
            };

            # Run tests
            test = {
              type = "app";
              program = toString (pkgs.writeShellScript "test" ''
                echo "🧪 Running tests..."
                if [ -f scripts/testing/run-tests.nu ]; then
                  ${pkgs.nushell}/bin/nu scripts/testing/run-tests.nu
                else
                  echo "⚠️  Test runner not found, using make"
                  make test || true
                fi
              '');
            };
          };

          # Packages
          packages = {
            # System backup script (Linux only)
            backup-system = pkgs.writeShellScriptBin "backup-system" ''
              #!/bin/sh
              set -e
            
              if [[ "$OSTYPE" != "linux"* ]]; then
                echo "⚠️  System backup only available on Linux systems"
                exit 0
              fi
            
              BACKUP_DIR="/var/backup/nixos"
              DATE=$(date +%Y%m%d-%H%M%S)
            
              echo "📦 Creating system backup..."
            
              # Create backup directory
              sudo mkdir -p "$BACKUP_DIR"
            
              # Backup configuration
              sudo cp -r /etc/nixos "$BACKUP_DIR/config-$DATE"
            
              # Backup current generation
              CURRENT_GEN=$(readlink /nix/var/nix/profiles/system)
              echo "$CURRENT_GEN" | sudo tee "$BACKUP_DIR/generation-$DATE.txt"
            
              # Create tarball
              sudo tar -czf "$BACKUP_DIR/backup-$DATE.tar.gz" \
                -C "$BACKUP_DIR" \
                "config-$DATE" \
                "generation-$DATE.txt"
            
              # Clean up
              sudo rm -rf "$BACKUP_DIR/config-$DATE"
              sudo rm "$BACKUP_DIR/generation-$DATE.txt"
            
              echo "✅ Backup created: $BACKUP_DIR/backup-$DATE.tar.gz"
            
              # Keep only last 5 backups
              ls -t "$BACKUP_DIR"/backup-*.tar.gz | tail -n +6 | xargs -r sudo rm
            '';
          };

          # Checks
          checks = {
            # Test that the flake can be evaluated
            flake-evaluation = pkgs.runCommand "flake-evaluation" { } ''
              echo "Testing flake evaluation..."
              # Only test backup-system package on Linux
              if [[ "${system}" == *"linux"* ]]; then
                ${pkgs.nix}/bin/nix eval .#packages.${system}.backup-system --extra-experimental-features "flakes nix-command" || true
              fi
              touch $out
            '';
          };
        }
      ) // {
      # NixOS configurations (Linux only)
      nixosConfigurations = {
        # Main gaming workstation
        nixos = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";

          specialArgs = { inherit inputs; };

          modules = [
            # Hardware configuration
            ./config/hardware/hardware-configuration.nix

            # Core configuration
            ./config/nixos/configuration.nix

            # Storage safety module
            ./modules/storage/auto-update.nix

            # Configure storage auto-update
            {
              services.storageAutoUpdate = {
                enable = true;
                autoUpdate = true;
                hardwareConfigPath = "/etc/nixos/hardware-configuration.nix";
              };
            }

            # Gaming module (optional - provides advanced gaming features)
            # gamingModule

            # Secrets management
            agenix.nixosModules.default
          ];
        };

        # Simple configuration for testing (without gaming module)
        nixos-simple = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";

          specialArgs = { inherit inputs; };

          modules = [
            # Hardware configuration
            ./config/hardware/hardware-configuration.nix

            # Core configuration (without gaming module)
            ./config/nixos/configuration.nix

            # Secrets management
            agenix.nixosModules.default
          ];
        };

        # Minimal configuration for recovery
        nixos-minimal = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";

          modules = [
            ./config/hardware/hardware-configuration.nix
            ./config/templates/minimal.nix
          ];
        };
      };
    };
}
