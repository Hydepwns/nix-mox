{
  # ============================================================================
  # NIX-MOX FLAKE
  # ============================================================================
  # A comprehensive NixOS configuration framework with development tools,
  # monitoring, and system management utilities.
  #
  # QUICK START:
  #   nix run .#dev          - Show available commands
  #   nix develop            - Enter development shell
  #   nix run .#fmt          - Format code
  #   nix run .#test         - Run tests
  #
  # FLAKE OUTPUTS:
  #   devShells:
  #     - default: Development shell with common tools
  #     - development: Extended development tools
  #     - testing: Testing environment
  #     - services: Service management tools (Linux)
  #     - monitoring: Monitoring tools (Linux)
  #     - gaming: Gaming setup (Linux)
  #     - macos: macOS-specific tools (macOS)
  #
  #   packages:
  #     - install: Installation script (all platforms)
  #     - uninstall: Uninstallation script (all platforms)
  #     - proxmox-update: Proxmox update script (Linux only)
  #     - vzdump-backup: Proxmox backup script (Linux only)
  #     - zfs-snapshot: ZFS snapshot script (Linux only)
  #     - nixos-flake-update: NixOS flake update script (Linux only)
  #     - homebrew-setup: Homebrew setup script (macOS only)
  #     - macos-maintenance: macOS maintenance script (macOS only)
  #     - xcode-setup: Xcode setup script (macOS only)
  #     - security-audit: Security audit script (macOS only)
  #
  #   apps:
  #     - fmt: Format code using treefmt
  #     - test: Run test suite
  #     - update: Update flake inputs
  #     - dev: Show development help
  #
  #   formatter: Code formatter (treefmt with nixpkgs-fmt, shellcheck, shfmt)
  #   checks: Test suite with platform-specific tests
  #   nixosConfigurations: NixOS system configurations (when not in CI)
  # ============================================================================

  description = "A comprehensive NixOS configuration framework with development tools, monitoring, and system management utilities";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/9e83b64f727c88a7711a2c463a7b16eedb69a84c";
    flake-utils.url = "github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b";
    home-manager = {
      url = "github:nix-community/home-manager/863842639722dd12ae9e37ca83bcb61a63b36f6c";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Development environment tools
    devenv.url = "github:cachix/devenv";
    devenv.inputs.nixpkgs.follows = "nixpkgs";
    # Add additional useful inputs
    nixpkgs-fmt.url = "github:nix-community/nixpkgs-fmt/bdb15b4c7e0cb49ae091dd43113d0a938afae02c";
    treefmt-nix.url = "github:numtide/treefmt-nix/ac8e6f32e11e9c7f153823abc3ab007f2a65d3e1";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  nixConfig = {
    trusted-substituters = [
      "https://cache.nixos.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };

  outputs = { self, nixpkgs, flake-utils, home-manager, devenv, nixpkgs-fmt, treefmt-nix, ... }@inputs:
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
        if result.success then result.value else
        throw "Failed to import ${path}: ${result.error}";

      # Helper function to validate script paths exist
      validateScriptPath = path:
        if builtins.pathExists (self + "/${path}") then
          path
        else
          throw "Script path '${path}' does not exist in the flake";

      # Helper function to safely read scripts with validation
      safeReadScript = path: builtins.readFile (self + "/${validateScriptPath path}");

      # Helper function to get system-specific packages with better error handling
      getSystemPackages = system: pkgs:
        let
          baseArgs = {
            inherit pkgs;
            config = safeImport ./config/default.nix { inherit inputs; };
            helpers = {
              readScript = safeReadScript;
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
                export PATH="${pkgs.nixpkgs-fmt}/bin:${pkgs.nodePackages.prettier}/bin:${pkgs.shfmt}/bin:${pkgs.python3Packages.black}/bin:${pkgs.rustfmt}/bin:${pkgs.go}/bin:${pkgs.nufmt}/bin:${pkgs.shellcheck}/bin:$PATH"
                ${pkgs.treefmt}/bin/treefmt "$@"
              '');
              meta = {
                description = "Format code using treefmt";
                platforms = pkgs.lib.platforms.all;
              };
            };

            # Run tests
            test = {
              type = "app";
              program = toString (pkgs.writeShellScript "test" ''
                nix build .#checks.${system}.test-suite
              '');
              meta = {
                description = "Run test suite";
                platforms = pkgs.lib.platforms.all;
              };
            };

            # Update flake inputs
            update = {
              type = "app";
              program = toString (pkgs.writeShellScript "update" ''
                nix flake update
              '');
              meta = {
                description = "Update flake inputs";
                platforms = pkgs.lib.platforms.all;
              };
            };

            # Development tools helper
            dev = {
              type = "app";
              program = toString (pkgs.writeShellScript "dev" ''
                echo "Available development commands:"
                echo "  nix run .#fmt     - Format code"
                echo "  nix run .#test    - Run tests"
                echo "  nix run .#update  - Update flake inputs"
                echo "  nix develop       - Enter development shell"
                echo ""
                echo "Available outputs:"
                echo "  nixosConfigurations:"
                echo "    - nixos (main configuration with gaming support)"
                echo "    - host1, host2 (alternative configurations)"
                echo ""
                echo "  packages:"
                echo "    - install, uninstall (all platforms)"
                if [[ "$OSTYPE" == "linux-gnu"* ]]; then
                  echo "    - proxmox-update, vzdump-backup, zfs-snapshot, nixos-flake-update (Linux)"
                elif [[ "$OSTYPE" == "darwin"* ]]; then
                  echo "    - homebrew-setup, macos-maintenance, xcode-setup, security-audit (macOS)"
                fi
                echo ""
                echo "  devShells: default, development, testing, services, monitoring, gaming"
                echo "  apps: fmt, test, update, dev"
                echo ""
                echo "  Maintenance tools:"
                echo "    - nu scripts/tools/cleanup.nu     - Project cleanup"
                echo "    - nu scripts/core/health-check.nu - System health check"
                echo ""
                echo "For full details, run: nix flake show"
              '');
              meta = {
                description = "Show development help and available commands";
                platforms = pkgs.lib.platforms.all;
              };
            };
          };

          # Code formatter - per-system formatter
          formatter = createFormatter system pkgs treefmt-nix;
        }
      ) // (
      # Only include NixOS configs if explicitly requested or if not in CI
      if builtins.getEnv "INCLUDE_NIXOS_CONFIGS" == "1" || (builtins.getEnv "CI" != "true" && builtins.getEnv "CI" != "1") then
        let
          # Create a pkgs instance for the default system
          defaultPkgs = import nixpkgs { system = "x86_64-linux"; config.allowUnfree = true; };
        in
        {
          nixosConfigurations = {
            # Use the personal configuration system with gaming support
            nixos = inputs.nixpkgs.lib.nixosSystem {
              system = "x86_64-linux";
              specialArgs = { inherit inputs self; };
              modules = [
                ./config/nixos/configuration.nix
                ./config/hardware/hardware-configuration.nix
                # Import personal configuration (includes projects)
                ./config/personal/combined.nix
                # Import gaming configuration
                ./config/nixos/gaming.nix
                ./config/nixos/gaming-tools.nix
                inputs.home-manager.nixosModules.home-manager
                {
                  home-manager.useGlobalPkgs = true;
                  home-manager.useUserPackages = true;
                  # The hydepwns.nix file already configures home-manager.users.hydepwns
                }
                # Enable gaming services
                {
                  services.gaming = {
                    enable = true;
                    gpu.type = "auto";
                    performance.enable = true;
                    performance.gamemode = true;
                    performance.mangohud = true;
                    audio.enable = true;
                    audio.pipewire = true;
                    platforms.steam = true;
                    platforms.lutris = true;
                    platforms.heroic = true;
                  };
                }
              ];
            };

            # Additional host configurations can be added here as needed
            # Example:
            # host1 = inputs.nixpkgs.lib.nixosSystem { ... };
            # host2 = inputs.nixpkgs.lib.nixosSystem { ... };
          };
        }
      else { }
    );
}
