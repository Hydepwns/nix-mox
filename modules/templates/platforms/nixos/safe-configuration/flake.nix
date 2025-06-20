{
  description = "Default NixOS configuration using nix-mox tools";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Import your nix-mox repository
    nix-mox = {
      url = "github:Hydepwns/nix-mox";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Optional: home-manager for user configuration
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix-mox, home-manager, ... }@inputs: {
    nixosConfigurations = {
      # Replace "hydebox" with your desired hostname
      hydebox = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        # Pass inputs to modules
        specialArgs = { inherit inputs; };

        modules = [
          ./configuration.nix
          ./hardware-configuration.nix

          # Optional: Include home-manager
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.hyde = import ./home.nix;
          }
        ];
      };
    };
  };
}
