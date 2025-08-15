{
  description = "Simplified NixOS configuration with subflakes";

  inputs = {
    # Core inputs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
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
    agenix.url = "github:ryantm/agenix";  # For secrets management
  };

  outputs = { self, nixpkgs, home-manager, flake-utils, agenix, ... }@inputs:
    let
      system = "x86_64-linux";
      
      # Import gaming module directly for now
      gamingModule = import ./flakes/gaming/module.nix;
      
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          # Gaming overlay will be added when subflake is ready
        ];
      };
    in
    {
      # NixOS configurations
      nixosConfigurations = {
        # Main gaming workstation
        nixos = nixpkgs.lib.nixosSystem {
          inherit system;
          
          specialArgs = { inherit inputs; };
          
          modules = [
            # Hardware configuration
            ./config/hardware/hardware-configuration.nix
            
            # Core configuration
            ./config/nixos/configuration.nix
            
            # Gaming module imported directly
            gamingModule
            
            # Secrets management
            agenix.nixosModules.default
            
            # Home-manager
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                
                users.hydepwns = { ... }: {
                  imports = [
                    ./config/home/hydepwns.nix
                    ./flakes/gaming/home-manager/gaming.nix
                  ];
                  
                  home.stateVersion = "24.05";
                };
              };
            }
          ];
        };
        
        # Minimal configuration for recovery
        nixos-minimal = nixpkgs.lib.nixosSystem {
          inherit system;
          
          modules = [
            ./config/hardware/hardware-configuration.nix
            ./config/templates/minimal.nix
          ];
        };
      };
      
      # Development shells
      devShells.${system} = {
        default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nixpkgs-fmt
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
      };
      
      # Apps for quick access
      apps.${system} = {
        # Format all code
        fmt = {
          type = "app";
          program = toString (pkgs.writeShellScript "fmt" ''
            ${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt **/*.nix
            echo "✅ Formatted all Nix files"
          '');
        };
        
        # Validate configuration
        validate = {
          type = "app";
          program = toString (pkgs.writeShellScript "validate" ''
            echo "🔍 Validating configuration..."
            
            # Check syntax
            nix flake check
            
            # Check if configuration builds
            nix build .#nixosConfigurations.nixos.config.system.build.toplevel --dry-run
            
            echo "✅ Configuration is valid"
          '');
        };
        
        # Update all inputs
        update = {
          type = "app";
          program = toString (pkgs.writeShellScript "update" ''
            echo "📦 Updating flake inputs..."
            nix flake update
            echo "✅ Updated all inputs"
          '');
        };
      };
      
      # Packages
      packages.${system} = {
        # Gaming packages will be added when subflake is ready
        
        # System backup script
        backup-system = pkgs.writeShellScriptBin "backup-system" ''
          #!/usr/bin/env bash
          set -e
          
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
      checks.${system} = {
        # Test the configuration builds
        config-builds = pkgs.runCommand "config-builds" { } ''
          echo "Testing configuration build..."
          ${pkgs.nix}/bin/nix build ${self}#nixosConfigurations.nixos.config.system.build.toplevel --dry-run
          touch $out
        '';
      };
    };
}