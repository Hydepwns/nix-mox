{
  # Flake outputs:
  # - devShells.default: Development shell with common tools for working on this repo
  # - formatter: Nix code formatter (nixpkgs-fmt)
  # - packages.<system>.proxmox-update: Proxmox update script as a Nix package (Linux only)
  # - packages.<system>.vzdump-backup: Proxmox vzdump backup script as a Nix package (Linux only)
  # - packages.<system>.zfs-snapshot: ZFS snapshot/prune script as a Nix package (Linux only)
  # - packages.<system>.nixos-flake-update: NixOS flake update script as a Nix package (Linux only)
  # - packages.<system>.install: nix-mox installation script as a Nix package (Platform-specific)
  # - packages.<system>.uninstall: nix-mox uninstallation script as a Nix package (Platform-specific)
  # - packages.<system>.homebrew-setup: Homebrew setup script (macOS only)
  # - packages.<system>.macos-maintenance: macOS maintenance script (macOS only)
  # - packages.<system>.xcode-setup: Xcode setup script (macOS only)
  # - packages.<system>.security-audit: Security audit script (macOS only)

  description = "A comprehensive NixOS configuration framework with development tools, monitoring, and system management utilities";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    trusted-substituters = [
      "https://hydepwns.cachix.org"
      "https://nix-mox.cachix.org"
      "https://cache.nixos.org"
    ];
    trusted-public-keys = [
      "hydepwns.cachix.org-1:xg8huKdwzBkLdkq5eCKenadhCROHIICGI9H6y3simJU="
      "nix-mox.cachix.org-1:MVJZxC7ZyRFAxVsxDuq0nmMRxlTIt5nFFm4Ur10ZCI4="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };

  outputs = { self, nixpkgs, flake-utils, home-manager, ... }@inputs:
    let
      # Supported systems with clear documentation
      supportedSystems = [
        "aarch64-darwin" # Apple Silicon Macs
        "x86_64-darwin" # Intel Macs
        "x86_64-linux" # Intel/AMD Linux
        "aarch64-linux" # ARM Linux (Raspberry Pi, etc.)
      ];

      # Helper function to check if system is supported
      isSupported = system: builtins.elem system supportedSystems;

      # Simplified helper function to get system-specific packages with better error handling
      getSystemPackages = system: pkgs:
        let
          tryImport = path: builtins.tryEval (import path {
            inherit pkgs;
            config = import ./config/default.nix { inherit inputs; };
            helpers = {
              readScript = path: builtins.readFile (self + "/${path}");
              isLinux = system: builtins.elem system [ "x86_64-linux" "aarch64-linux" ];
            };
          });
        in
        if pkgs.stdenv.isLinux then
          tryImport ./modules/packages/linux/default.nix
        else if pkgs.stdenv.isDarwin then
          tryImport ./modules/packages/macos/default.nix
        else { success = true; value = { }; };

      # Simplified helper function to create packages with minimal evaluation
      createPackages = system: pkgs: systemPackages:
        let
          # Common packages available on all platforms
          commonPackages = {
            install = systemPackages.install or null;
            uninstall = systemPackages.uninstall or null;
            default = systemPackages.install or null;
          };
        in
        if pkgs.stdenv.isLinux then
        # Linux packages - only include essential ones
          commonPackages // {
            proxmox-update = systemPackages.proxmox-update or null;
            vzdump-backup = systemPackages.vzdump-backup or null;
            zfs-snapshot = systemPackages.zfs-snapshot or null;
            nixos-flake-update = systemPackages.nixos-flake-update or null;
          }
        else if pkgs.stdenv.isDarwin then
        # macOS packages - only include essential ones
          commonPackages // {
            homebrew-setup = systemPackages.homebrew-setup or null;
            macos-maintenance = systemPackages.macos-maintenance or null;
            xcode-setup = systemPackages.xcode-setup or null;
            security-audit = systemPackages.security-audit or null;
          }
        else
        # Other platforms - only common packages
          commonPackages;

      # Simplified helper function to create platform-specific devShells
      createDevShells = system: pkgs: devShell:
        let
          # Common shells available on all platforms
          commonShells = {
            default = devShell.default;
            development = devShell.development;
            testing = devShell.testing;
          };
        in
        if pkgs.stdenv.isLinux then
        # Linux - add essential shells only
          commonShells // {
            services = devShell.services;
            monitoring = devShell.monitoring;
          }
        else if pkgs.stdenv.isDarwin then
        # macOS - add macOS-specific shell
          commonShells // {
            macos = devShell.macos;
          }
        else
        # Other platforms - only common shells
          commonShells;

      # Simplified helper function to create platform-specific checks
      createChecks = system: pkgs:
        let
          src = ./.;
          baseChecks = {
            # Unit tests only
            unit = pkgs.runCommand "nix-mox-unit-tests"
              {
                buildInputs = [ pkgs.nushell ];
              } ''
              cp -r ${src} $TMPDIR/src
              cd $TMPDIR/src
              export TEST_TEMP_DIR=$TMPDIR/nix-mox-unit
              nu -c "source scripts/tests/unit/unit-tests.nu" || exit 1
              touch $out
            '';

            # Integration tests only
            integration = pkgs.runCommand "nix-mox-integration-tests"
              {
                buildInputs = [ pkgs.nushell ];
              } ''
              cp -r ${src} $TMPDIR/src
              cd $TMPDIR/src
              export TEST_TEMP_DIR=$TMPDIR/nix-mox-integration
              nu -c "source scripts/tests/integration/integration-tests.nu" || exit 1
              touch $out
            '';

            # Full test suite
            test-suite = pkgs.runCommand "nix-mox-tests"
              {
                buildInputs = [ pkgs.nushell ];
              } ''
              cp -r ${src} $TMPDIR/src
              cd $TMPDIR/src
              export TEST_TEMP_DIR=$TMPDIR/nix-mox-tests
              nu -c "source scripts/tests/run-tests.nu; run []" || exit 1
              touch $out
            '';
          };
        in
        if pkgs.stdenv.isLinux then
        # Linux-specific checks
          baseChecks // {
            # Linux-specific tests
            linux-specific = pkgs.runCommand "nix-mox-linux-tests"
              {
                buildInputs = [ pkgs.nushell ];
              } ''
              cp -r ${src} $TMPDIR/src
              cd $TMPDIR/src
              export TEST_TEMP_DIR=$TMPDIR/nix-mox-linux
              nu -c "source scripts/tests/linux/linux-tests.nu" || exit 1
              touch $out
            '';
          }
        else if pkgs.stdenv.isDarwin then
        # macOS-specific checks
          baseChecks // {
            # macOS-specific tests
            macos-specific = pkgs.runCommand "nix-mox-macos-tests"
              {
                buildInputs = [ pkgs.nushell ];
              } ''
              cp -r ${src} $TMPDIR/src
              cd $TMPDIR/src
              export TEST_TEMP_DIR=$TMPDIR/nix-mox-macos
              nu -c "source scripts/tests/macos/macos-tests.nu" || exit 1
              touch $out
            '';
          }
        else
        # Other platforms - only base checks
          baseChecks;
    in
    flake-utils.lib.eachSystem supportedSystems
      (system:
        let
          # Import nixpkgs with proper configuration
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
            config.darwinConfig =
              if system == "aarch64-darwin" || system == "x86_64-darwin" then {
                system = system;
                # Use newer SDK to avoid deprecation warnings
                sdkVersion = "14.0";
              } else { };
          };

          # Import development shell
          devShell = import ./devshells/default.nix { inherit pkgs; };

          # Get system-specific packages with error handling
          systemPackagesResult = getSystemPackages system pkgs;
          systemPackages = if systemPackagesResult.success then systemPackagesResult.value else { };

          # Helper functions
          helpers = {
            readScript = path: builtins.readFile (self + "/${path}");
            isLinux = system: builtins.elem system [ "x86_64-linux" "aarch64-linux" ];
          };
        in
        {
          # Development shells with platform-specific availability
          devShells = createDevShells system pkgs devShell;

          # Code formatter
          formatter = pkgs.nixpkgs-fmt;

          # Packages with architecture checking
          packages = createPackages system pkgs systemPackages;

          # Test suite with platform-specific tests
          checks = createChecks system pkgs;
        }
      ) // (
      # Only include NixOS configs if explicitly requested or if not in CI
      if builtins.getEnv "INCLUDE_NIXOS_CONFIGS" == "1" || (builtins.getEnv "CI" != "true" && builtins.getEnv "CI" != "1") then
        { nixosConfigurations = import ./config { inherit inputs self; }; }
      else { }
    );
}
