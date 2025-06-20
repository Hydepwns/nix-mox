{
  description = "Example NixOS VM Template Flake with Fragment System";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
    nix-mox = {
      url = "path:../../../.."; # Path to the root nix-mox flake
      # To ensure consistent nixpkgs, you might consider:
      # inputs.nixpkgs.follows = "nix-mox/nixpkgs";
      # inputs.flake-utils.follows = "nix-mox/flake-utils";
    };
  };

  outputs = { self, nixpkgs, flake-utils, nix-mox, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ nix-mox.overlays.default ];
        };
      in {
        nixosConfigurations = {
          # Basic VM with minimal configuration
          basic-vm = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              ./examples/basic-vm.nix
            ];
            specialArgs = { inherit nix-mox inputs; };
          };

          # Web server VM
          web-server-vm = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              ./examples/web-server-vm.nix
            ];
            specialArgs = { inherit nix-mox inputs; };
          };

          # Database VM
          database-vm = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              ./examples/database-vm.nix
            ];
            specialArgs = { inherit nix-mox inputs; };
          };

          # CI Runner VM
          ci-runner-vm = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              ./examples/ci-runner-vm.nix
            ];
            specialArgs = { inherit nix-mox inputs; };
          };

          # Legacy configurations for backward compatibility
          example-vm = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              ./base.nix
            ];
            specialArgs = { inherit nix-mox inputs; };
          };

          web-vm = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              ./base.nix
              ./web-server.nix
            ];
            specialArgs = { inherit nix-mox inputs; };
          };
        };
      });
}
