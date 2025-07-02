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
    # Add additional useful inputs
    nixpkgs-fmt.url = "github:nix-community/nixpkgs-fmt";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  nixConfig = {
    trusted-substituters = [
      "https://hydepwns.cachix.org"
      "https://nix-mox.cachix.org"
      "https://cache.nixos.org"
    ];
    trusted-public-keys = [
      "hydepwns.cachix.org-1:xg8huKdwzBkLdkq5eCKenadhCROHI3GI9H6y3simJU="
      "nix-mox.cachix.org-1:MVJZxC7ZyRFAxVsxDuq0nmMRxlTIt5nFFm4Ur10ZCI4="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };

  outputs = { self, nixpkgs, flake-utils, home-manager, nixpkgs-fmt, treefmt-nix, ... }@inputs:
    let
      # ============================================================================
      # CONSTANTS AND CONFIGURATION
      # ============================================================================

      # Supported systems with clear documentation
      supportedSystems = [
        "aarch64-darwin" # Apple Silicon Macs
        "x86_64-darwin" # Intel Macs
        "x86_64-linux" # Intel/AMD Linux
        "aarch64-linux" # ARM Linux (Raspberry Pi, etc.)
      ];

      # ============================================================================
      # HELPER FUNCTIONS
      # ============================================================================

      # Helper function to check if system is supported
      isSupported = system: builtins.elem system supportedSystems;

      # Helper function to check if system is Linux
      isLinux = system: builtins.elem system [ "x86_64-linux" "aarch64-linux" ];

      # Helper function to check if system is Darwin
      isDarwin = system: builtins.elem system [ "aarch64-darwin" "x86_64-darwin" ];

      # Helper function to safely import modules with error handling
      safeImport = path: args:
        let
          result = builtins.tryEval (import path args);
        in
        if result.success then result.value else { };

      # Helper function to get system-specific packages with better error handling
      getSystemPackages = system: pkgs:
        let
          baseArgs = {
            inherit pkgs;
            config = safeImport ./config/default.nix { inherit inputs; };
            helpers = {
              readScript = path: builtins.readFile (self + "/${path}");
              inherit isLinux;
            };
          };
        in
        if isLinux system then
          safeImport ./modules/packages/linux/default.nix baseArgs
        else if isDarwin system then
          safeImport ./modules/packages/macos/default.nix baseArgs
        else { };

      # Helper function to filter out null packages and ensure we have at least one package
      filterNullPackages = pkgs: attrs:
        let
          nullPackages = pkgs.lib.filterAttrs (name: value: value == null) attrs;
          nullNames = builtins.attrNames nullPackages;
          filtered = builtins.removeAttrs attrs nullNames;
        in
        # If all packages are null, provide a minimal fallback
        if builtins.length (builtins.attrNames filtered) == 0 then
          { default = pkgs.hello; }  # Fallback package
        else
          filtered;

      # ============================================================================
      # PACKAGE CREATION FUNCTIONS
      # ============================================================================

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
        if isLinux system then
        # Linux packages - only include essential ones
          filterNullPackages pkgs
            (commonPackages // {
              proxmox-update = systemPackages.proxmox-update or null;
              vzdump-backup = systemPackages.vzdump-backup or null;
              zfs-snapshot = systemPackages.zfs-snapshot or null;
              nixos-flake-update = systemPackages.nixos-flake-update or null;
            })
        else if isDarwin system then
        # macOS packages - only include essential ones
          filterNullPackages pkgs
            (commonPackages // {
              homebrew-setup = systemPackages.homebrew-setup or null;
              macos-maintenance = systemPackages.macos-maintenance or null;
              xcode-setup = systemPackages.xcode-setup or null;
              security-audit = systemPackages.security-audit or null;
            })
        else
        # Other platforms - only common packages
          filterNullPackages pkgs commonPackages;

      # ============================================================================
      # DEVELOPMENT SHELL CREATION FUNCTIONS
      # ============================================================================

      # Simplified helper function to create platform-specific devShells
      createDevShells = system: pkgs: devShell:
        let
          # Common shells available on all platforms
          commonShells = {
            default = devShell.default or null;
            development = devShell.development or null;
            testing = devShell.testing or null;
          };
        in
        if isLinux system then
        # Linux - add essential shells only
          filterNullPackages pkgs
            (commonShells // {
              services = devShell.services or null;
              monitoring = devShell.monitoring or null;
              gaming = devShell.gaming or null;
            })
        else if isDarwin system then
        # macOS - add macOS-specific shell
          filterNullPackages pkgs
            (commonShells // {
              macos = devShell.macos or null;
            })
        else
        # Other platforms - only common shells
          filterNullPackages pkgs commonShells;

      # ============================================================================
      # TEST CREATION FUNCTIONS
      # ============================================================================

      # Helper function to create test commands
      createTestCommand = name: testScript: pkgs:
        pkgs.runCommand "nix-mox-${name}"
          {
            buildInputs = [ pkgs.nushell ];
            src = ./.;
          } ''
          cp -r $src $TMPDIR/src
          cd $TMPDIR/src
          export TEST_TEMP_DIR=$TMPDIR/nix-mox-${name}
          nu -c "source ${testScript}" || exit 1
          touch $out
        '';

      # Simplified helper function to create platform-specific checks
      createChecks = system: pkgs:
        let
          baseChecks = {
            # Unit tests only
            unit = createTestCommand "unit-tests" "scripts/tests/unit/unit-tests.nu" pkgs;

            # Integration tests only
            integration = createTestCommand "integration-tests" "scripts/tests/integration/integration-tests.nu" pkgs;

            # Full test suite
            test-suite = createTestCommand "tests" "scripts/tests/run-tests.nu; run []" pkgs;
          };
        in
        if isLinux system then
        # Linux-specific checks
          baseChecks // {
            # Linux-specific tests
            linux-specific = createTestCommand "linux-tests" "scripts/tests/linux/linux-tests.nu" pkgs;
          }
        else if isDarwin system then
        # macOS-specific checks
          baseChecks // {
            # macOS-specific tests
            macos-specific = createTestCommand "macos-tests" "scripts/tests/macos/macos-tests.nu" pkgs;
          }
        else
        # Other platforms - only base checks
          baseChecks;

      # ============================================================================
      # FORMATTER CONFIGURATION
      # ============================================================================

      # Create formatter configuration
      createFormatter = system: pkgs: treefmt-nix:
        treefmt-nix.lib.mkWrapper pkgs {
          projectRootFile = "flake.nix";
          programs = {
            nixpkgs-fmt.enable = true;
            shellcheck.enable = true;
            shfmt.enable = true;
          };
        };

    in
    flake-utils.lib.eachSystem supportedSystems
      (system:
        let
          # Import nixpkgs with proper configuration
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
            config.darwinConfig =
              if isDarwin system then {
                system = system;
                # Use newer SDK to avoid deprecation warnings
                sdkVersion = "14.0";
              } else { };
          };

          # Import development shell
          devShell = safeImport ./devshells/default.nix { inherit pkgs; };

          # Get system-specific packages with error handling
          systemPackages = getSystemPackages system pkgs;

        in
        {
          # Development shells with platform-specific availability
          devShells = createDevShells system pkgs devShell;

          # Code formatter - use treefmt for better formatting
          formatter = pkgs.treefmt;

          # Packages with architecture checking
          packages = createPackages system pkgs systemPackages;

          # Test suite with platform-specific tests
          checks = createChecks system pkgs;

          # Add apps for common development tasks
          apps = {
            # Format code
            fmt = {
              type = "app";
              program = toString (pkgs.writeShellScript "fmt" ''
                export PATH="${pkgs.nixpkgs-fmt}/bin:${pkgs.nodePackages.prettier}/bin:${pkgs.shfmt}/bin:${pkgs.python3Packages.black}/bin:${pkgs.rustfmt}/bin:${pkgs.go}/bin:${pkgs.shellcheck}/bin:$PATH"
                ${pkgs.treefmt}/bin/treefmt "$@"
              '');
            };

            # Run tests
            test = {
              type = "app";
              program = toString (pkgs.writeShellScript "test" ''
                nix build .#checks.${system}.test-suite
              '');
            };

            # Update flake inputs
            update = {
              type = "app";
              program = toString (pkgs.writeShellScript "update" ''
                nix flake update
              '');
            };
          };
        }
      ) // (
      # Only include NixOS configs if explicitly requested or if not in CI
      if builtins.getEnv "INCLUDE_NIXOS_CONFIGS" == "1" || (builtins.getEnv "CI" != "true" && builtins.getEnv "CI" != "1") then
        { nixosConfigurations = safeImport ./config { inherit inputs self; }; }
      else { }
    );
}
