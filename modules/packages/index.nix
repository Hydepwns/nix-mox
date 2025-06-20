{
  # Package-specific modules organized by functionality
  development = import ./development/index.nix;
  multimedia = import ./multimedia/index.nix;
  productivity = import ./productivity/index.nix;
  system = import ./system/index.nix;

  # Platform-specific packages
  linux = import ./linux/default.nix;
  windows = import ./windows/default.nix;
}
