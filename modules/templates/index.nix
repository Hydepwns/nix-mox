{
  # Template configurations organized by category
  templates = import ./templates.nix;

  # Service templates
  services = import ./services/index.nix;

  # Infrastructure templates
  infrastructure = import ./infrastructure/index.nix;

  # Platform-specific templates
  platforms = import ./platforms/index.nix;
}
