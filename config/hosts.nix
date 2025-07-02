# ============================================================================
# HOST CONFIGURATIONS
# ============================================================================
# This file defines all NixOS hosts in your infrastructure.
# Each host can have its own hardware config, home config, extra modules,
# and special arguments.
# ============================================================================

{
  # Desktop/Laptop host
  host1 = {
    system = "x86_64-linux";
    hardware = ./hardware/host1-hardware-configuration.nix;
    home = ./home/host1-home.nix;
    extraModules = [
      ./modules/host1-extra.nix
      # Add more host-specific modules here
    ];
    specialArgs = {
      mySecret = "host1-secret";
      hostType = "desktop";
      # Add more host-specific arguments here
    };
  };

  # Server/VM host
  host2 = {
    system = "x86_64-linux";
    hardware = ./hardware/host2-hardware-configuration.nix;
    home = ./home/host2-home.nix;
    extraModules = [
      # Add server-specific modules here
      ./modules/server-extra.nix
    ];
    specialArgs = {
      mySecret = "host2-secret";
      hostType = "server";
      # Add more host-specific arguments here
    };
  };

  # Optional: Add more hosts as needed
  # host3 = {
  #   system = "aarch64-linux";  # For ARM-based hosts
  #   hardware = ./hardware/host3-hardware-configuration.nix;
  #   home = ./home/host3-home.nix;
  #   extraModules = [];
  #   specialArgs = {
  #     mySecret = "host3-secret";
  #     hostType = "embedded";
  #   };
  # };
}
