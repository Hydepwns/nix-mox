{ inputs, self, ... }:
let
  # Import the user's NixOS configuration
  userConfig = import ./nixos/configuration.nix;
  userHome = import ./home/home.nix;
  userHardware = import ./hardware/hardware-configuration.nix;
in
{
  # Default NixOS configuration using user's configs
  nixos = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs self; };
    modules = [
      userConfig
      userHardware
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.droo = userHome;
      }
    ];
  };
}
