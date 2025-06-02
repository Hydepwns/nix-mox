{
  description = "Example NixOS VM Template Flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        nixosConfigurations.example-vm = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./base.nix
          ];
        };
        nixosConfigurations.web-vm = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./base.nix
            ./web-server.nix
            # Optionally enable first-boot or cloud-init modules:
            # ./first-boot-setup.nix
            # ./cloud-init-example.nix
          ];
        };
      });
} 