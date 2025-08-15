{
  description = "Gaming subsystem for NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    {
      # NixOS modules for gaming
      nixosModules = {
        default = self.nixosModules.gaming;
        
        gaming = import ./module.nix;
        
        # All functionality consolidated in main module
        # Individual features controlled via options
      };

      # Overlay with gaming packages
      overlays.default = final: prev: {
        gaming = {
          # Custom gaming packages
          proton-ge = final.callPackage ./packages/proton-ge.nix { };
          gamemode-plus = final.callPackage ./packages/gamemode-plus.nix { };
          mangohud-extended = final.callPackage ./packages/mangohud-extended.nix { };
          
          # Gaming scripts
          game-launcher = final.callPackage ./packages/game-launcher.nix { };
          shader-cache-manager = final.callPackage ./packages/shader-cache-manager.nix { };
          performance-monitor = final.callPackage ./packages/performance-monitor.nix { };
        };
      };

      # Home-manager modules for user gaming config
      homeManagerModules = {
        default = self.homeManagerModules.gaming;
        
        gaming = { config, lib, pkgs, ... }: {
          imports = [ ./home-manager/gaming.nix ];
        };
      };
    } // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        # Gaming utilities
        packages = {
          default = self.packages.${system}.gaming-utils;
          
          gaming-utils = pkgs.stdenv.mkDerivation {
            pname = "gaming-utils";
            version = "1.0.0";
            
            src = ./scripts;
            
            installPhase = ''
              mkdir -p $out/bin
              cp -r * $out/bin/
              chmod +x $out/bin/*
            '';
            
            meta = with pkgs.lib; {
              description = "Gaming utility scripts";
              license = licenses.mit;
              platforms = platforms.linux;
            };
          };
          
          # Testing tools
          gaming-benchmark = pkgs.callPackage ./packages/gaming-benchmark.nix { };
        };
        
        # Development shell for gaming module development
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nixpkgs-fmt
            nil
            nix-tree
            steam-run
            mangohud
            gamemode
          ];
          
          shellHook = ''
            echo "🎮 Gaming subflake development environment"
            echo "Available commands:"
            echo "  nix build .#gaming-utils"
            echo "  nix develop"
          '';
        };
        
        # Tests for gaming configuration
        checks = {
          gaming-module = pkgs.nixosTest {
            name = "gaming-module-test";
            
            nodes.machine = { config, pkgs, ... }: {
              imports = [ self.nixosModules.gaming ];
              
              services.gaming = {
                enable = true;
                platforms.steam = true;
              };
            };
            
            testScript = ''
              machine.wait_for_unit("multi-user.target")
              machine.succeed("which steam")
              machine.succeed("which gamemode")
            '';
          };
        };
      });
}