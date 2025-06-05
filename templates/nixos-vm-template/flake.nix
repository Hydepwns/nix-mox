{
  description = "Example NixOS VM Template Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
    nix-mox = {
      url = "path:../.."; # Path to the root nix-mox flake
      # To ensure consistent nixpkgs, you might consider:
      # inputs.nixpkgs.follows = "nix-mox/nixpkgs";
      # inputs.flake-utils.follows = "nix-mox/flake-utils";
    };
  };

  outputs = { self, nixpkgs, flake-utils, nix-mox, ... }: # Added nix-mox
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        nixosConfigurations.example-vm = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./base.nix
          ];
          specialArgs = { inherit nix-mox pkgs; }; # Pass nix-mox and pkgs to modules
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
          specialArgs = { inherit nix-mox pkgs; }; # Pass nix-mox and pkgs to modules
        };
      });
} 