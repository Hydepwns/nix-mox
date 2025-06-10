{
  description = "Test configuration for nix-mox module";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-mox.url = "path:..";
  };

  outputs = { self, nixpkgs, nix-mox }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { 
        inherit system;
        overlays = [ nix-mox.overlays.default ];
      };
    in
    {
      nixosConfigurations.test-vm = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          nix-mox.nixosModules.nix-mox
          {
            # Basic system configuration
            system.stateVersion = "24.05";
            networking.hostName = "test-vm";
            
            # Enable the nix-mox module
            nix-mox = {
              enable = true;
              # Add any required configuration here
            };
          }
        ];
      };
    };
} 