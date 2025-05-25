{
  description = "Proxmox + NixOS + Windows automation flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.git
            pkgs.nix
            pkgs.bashInteractive
            pkgs.shellcheck
          ];
        };
        formatter = pkgs.nixpkgs-fmt;
      }
    ) // {
      nixosConfigurations.example = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ({ pkgs, ... }: {
            environment.systemPackages = with pkgs; [ git nix bashInteractive ];
            system.stateVersion = "24.05";
          })
        ];
      };
    };
} 