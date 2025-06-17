{
  # Default configuration for nix-mox
  config = {
    # Enable unfree packages
    allowUnfree = true;

    # Default paths
    paths = {
      templates = ../modules/templates;
      scripts = ../modules/scripts;
      tests = ../modules/scripts/testing;
    };

    # Default settings
    settings = {
      # Enable experimental features
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      # Default substituters
      substituters = [
        "https://hydepwns.cachix.org"
        "https://nix-mox.cachix.org"
      ];

      # Trusted public keys
      trusted-public-keys = [
        "hydepwns.cachix.org-1:xg8huKdwzBkLdkq5eCKenadhCROHIICGI9H6y3simJU="
        "nix-mox.cachix.org-1:MVJZxC7ZyRFAxVsxDuq0nmMRxlTIt5nFFm4Ur10ZCI4="
      ];
    };

    # Platform-specific settings
    meta = {
      platforms = {
        linux = [
          "aarch64-linux"
          "x86_64-linux"
        ];
        darwin = [
          "aarch64-darwin"
          "x86_64-darwin"
        ];
      };
    };
  };
}
