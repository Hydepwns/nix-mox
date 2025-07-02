# Main Configuration Aggregator
# This file manages the overall configuration structure

{ inputs, self, ... }:
let
  # Check if personal config exists
  hasPersonalConfig = builtins.pathExists ./personal/default.nix;

  # Import appropriate configuration
  baseConfig = ./nixos/configuration.nix;
  personalConfig = if hasPersonalConfig then import ./personal/default.nix else { };
  userHome = import ./home/home.nix;
  userHardware = import ./hardware/hardware-configuration.nix;
in
{
  # Default NixOS configuration using user's configs
  nixos = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs self; };
    modules = [
      baseConfig
      personalConfig
      userHardware
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        # Use personal configuration if available, otherwise fallback to droo
        home-manager.users = if hasPersonalConfig then { } else {
          droo = userHome;
        };
      }
    ];
  };
}
