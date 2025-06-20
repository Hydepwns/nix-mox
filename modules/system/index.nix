{
  # System-level configurations
  networking = import ./networking/index.nix;
  hardware = import ./hardware/index.nix;
  boot = import ./boot/index.nix;
  users = import ./users/index.nix;
}
