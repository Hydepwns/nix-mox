{
  # Service-specific modules organized by functionality
  services = import ./services.nix;

  # Legacy service modules (for backward compatibility)
  infisical = import ./infisical.nix;
  tailscale = import ./tailscale.nix;
  # Future service modules can be added here
  # monitoring = import ./monitoring;
}
