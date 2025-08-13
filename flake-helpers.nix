# Flake helper functions
# Common functions used across the flake

{ nixpkgs, flake-utils, home-manager, devenv, nixpkgs-fmt, treefmt-nix, ... }:

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

  # Helper function to check if system is Linux
  isLinux = system: builtins.elem system [ "x86_64-linux" "aarch64-linux" ];

  # Helper function to check if system is macOS
  isMacOS = system: builtins.elem system [ "aarch64-darwin" "x86_64-darwin" ];

  # Helper function to check if system is x86_64
  isX86_64 = system: builtins.elem system [ "x86_64-linux" "x86_64-darwin" ];

  # Create a formatter for a specific system
  createFormatter = system: pkgs: treefmt-nix.lib.mkFormatter pkgs {
    projectRootFile = "flake.nix";
    programs = {
      nixpkgs-fmt.enable = true;
      shfmt.enable = true;
      shellcheck.enable = true;
      prettier.enable = true;
      nufmt.enable = true;
    };
  };

  # Create a package for a specific system
  createPackage = system: pkgs: name: script: {
    inherit name;
    src = script;
    nativeBuildInputs = [ pkgs.makeWrapper ];
    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/${name}
      chmod +x $out/bin/${name}
      wrapProgram $out/bin/${name} \
        --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.nix pkgs.util-linux pkgs.coreutils ]}
    '';
  };

  # Create an app for a specific system
  createApp = system: pkgs: name: script: {
    type = "app";
    program = toString (pkgs.writeShellScript name script);
  };

  # Common package definitions
  commonPackages = system: pkgs: {
    # Installation script (all platforms)
    install = createPackage system pkgs "install" (pkgs.writeShellScript "install" ''
      export PATH="${pkgs.nix}/bin:${pkgs.util-linux}/bin:${pkgs.coreutils}/bin:$PATH"
      exec ${pkgs.nushell}/bin/nu ${./scripts/setup/install.nu} "$@"
    '');

    # Uninstallation script (all platforms)
    uninstall = createPackage system pkgs "uninstall" (pkgs.writeShellScript "uninstall" ''
      export PATH="${pkgs.nix}/bin:${pkgs.util-linux}/bin:${pkgs.coreutils}/bin:$PATH"
      exec ${pkgs.nushell}/bin/nu ${./scripts/setup/unified-setup.nu} --uninstall "$@"
    '');
  };

  # Linux-specific packages
  linuxPackages = system: pkgs: {
    # Proxmox update script (Linux only)
    proxmox-update = createPackage system pkgs "proxmox-update" (pkgs.writeShellScript "proxmox-update" ''
      export PATH="${pkgs.nix}/bin:${pkgs.util-linux}/bin:${pkgs.coreutils}/bin:$PATH"
      exec ${pkgs.nushell}/bin/nu ${./scripts/platforms/linux/proxmox-update.nu} "$@"
    '');

    # Proxmox backup script (Linux only)
    vzdump-backup = createPackage system pkgs "vzdump-backup" (pkgs.writeShellScript "vzdump-backup" ''
      export PATH="${pkgs.nix}/bin:${pkgs.util-linux}/bin:${pkgs.coreutils}/bin:$PATH"
      exec ${pkgs.nushell}/bin/nu ${./scripts/platforms/linux/vzdump-backup.nu} "$@"
    '');

    # ZFS snapshot script (Linux only)
    zfs-snapshot = createPackage system pkgs "zfs-snapshot" (pkgs.writeShellScript "zfs-snapshot" ''
      export PATH="${pkgs.nix}/bin:${pkgs.util-linux}/bin:${pkgs.coreutils}/bin:$PATH"
      exec ${pkgs.nushell}/bin/nu ${./scripts/platforms/linux/zfs-snapshot.nu} "$@"
    '');

    # NixOS flake update script (Linux only)
    nixos-flake-update = createPackage system pkgs "nixos-flake-update" (pkgs.writeShellScript "nixos-flake-update" ''
      export PATH="${pkgs.nix}/bin:${pkgs.util-linux}/bin:${pkgs.coreutils}/bin:$PATH"
      exec ${pkgs.nushell}/bin/nu ${./scripts/platforms/linux/nixos-flake-update.nu} "$@"
    '');
  };

  # macOS-specific packages
  macosPackages = system: pkgs: {
    # Homebrew setup script (macOS only)
    homebrew-setup = createPackage system pkgs "homebrew-setup" (pkgs.writeShellScript "homebrew-setup" ''
      export PATH="${pkgs.nix}/bin:${pkgs.util-linux}/bin:${pkgs.coreutils}/bin:$PATH"
      exec ${pkgs.nushell}/bin/nu ${./scripts/platforms/macos/homebrew-setup.nu} "$@"
    '');

    # macOS maintenance script (macOS only)
    macos-maintenance = createPackage system pkgs "macos-maintenance" (pkgs.writeShellScript "macos-maintenance" ''
      export PATH="${pkgs.nix}/bin:${pkgs.util-linux}/bin:${pkgs.coreutils}/bin:$PATH"
      exec ${pkgs.nushell}/bin/nu ${./scripts/platforms/macos/macos-maintenance.nu} "$@"
    '');

    # Xcode setup script (macOS only)
    xcode-setup = createPackage system pkgs "xcode-setup" (pkgs.writeShellScript "xcode-setup" ''
      export PATH="${pkgs.nix}/bin:${pkgs.util-linux}/bin:${pkgs.coreutils}/bin:$PATH"
      exec ${pkgs.nushell}/bin/nu ${./scripts/platforms/macos/xcode-setup.nu} "$@"
    '');

    # Security audit script (macOS only)
    security-audit = createPackage system pkgs "security-audit" (pkgs.writeShellScript "security-audit" ''
      export PATH="${pkgs.nix}/bin:${pkgs.util-linux}/bin:${pkgs.coreutils}/bin:$PATH"
      exec ${pkgs.nushell}/bin/nu ${./scripts/platforms/macos/security-audit.nu} "$@"
    '');
  };

  # Common app definitions
  commonApps = system: pkgs: {
    # Code formatter app
    fmt = {
      type = "app";
      program = toString (pkgs.writeShellScript "fmt" ''
        export PATH="${pkgs.nix}/bin:${pkgs.util-linux}/bin:${pkgs.coreutils}/bin:$PATH"
        exec ${pkgs.treefmt}/bin/treefmt "$@"
      '');
      meta = {
        description = "Format code using treefmt";
        platforms = pkgs.lib.platforms.all;
      };
    };

    # Test runner app
    test = {
      type = "app";
      program = toString (pkgs.writeShellScript "test" ''
        export PATH="${pkgs.nix}/bin:${pkgs.util-linux}/bin:${pkgs.coreutils}/bin:$PATH"
        exec ${pkgs.nushell}/bin/nu ${./scripts/testing/run-tests.nu} "$@"
      '');
      meta = {
        description = "Run test suite";
        platforms = pkgs.lib.platforms.all;
      };
    };

    # Update flake inputs app
    update = {
      type = "app";
      program = toString (pkgs.writeShellScript "update" ''
        export PATH="${pkgs.nix}/bin:${pkgs.util-linux}/bin:${pkgs.coreutils}/bin:$PATH"
        exec ${pkgs.nix}/bin/nix flake update "$@"
      '');
      meta = {
        description = "Update flake inputs";
        platforms = pkgs.lib.platforms.all;
      };
    };

    # Development help app
    dev = {
      type = "app";
      program = toString (pkgs.writeShellScript "dev" ''
        echo "nix-mox Development Commands"
        echo "============================"
        echo ""
        echo "🚀 Quick Start:"
        echo "  nix develop          - Enter development shell"
        echo "  nix build            - Build default package"
        echo "  nix run .#test       - Run test suite"
        echo "  nix run .#fmt        - Format code"
        echo ""
        echo "📦 Available Packages:"
        echo "  nix build .#install  - Build installation script"
        echo "  nix build .#uninstall - Build uninstallation script"
        echo ""
        echo "💻 Development Shells:"
        echo "  nix develop .#default - General development"
        echo "  nix develop .#testing - Testing environment"
        echo "  nix develop .#gaming  - Gaming tools (Linux x86_64 only)"
        echo "  nix develop .#macos   - macOS development (macOS only)"
        echo ""
        echo "🔧 Maintenance tools:"
        echo "  nu scripts/maintenance/cleanup.nu     - Project cleanup"
        echo "  nu scripts/maintenance/health-check.nu - System health check"
        echo "  nix run .#storage-guard         - Pre-reboot storage validation"
        echo "  nix run .#fix-storage           - Auto-fix storage configuration"
        echo ""
        echo "For full details, run: nix flake show"
      '');
      meta = {
        description = "Show development help and available commands";
        platforms = pkgs.lib.platforms.all;
      };
    };
  };

  # Linux-specific apps
  linuxApps = system: pkgs: {
    # Storage guard app: run defensive storage checks on the live system
    storage-guard = {
      type = "app";
      program = toString (pkgs.writeShellScript "storage-guard" ''
        export PATH="${pkgs.nix}/bin:${pkgs.util-linux}/bin:${pkgs.coreutils}/bin:$PATH"
        exec ${pkgs.nushell}/bin/nu ${./scripts/storage/storage-guard.nu}
      '');
      meta = {
        description = "Run defensive storage checks against the live system before reboot";
        platforms = pkgs.lib.platforms.linux;
      };
    };

    # Fix storage configuration app: automatically fix storage issues
    fix-storage = {
      type = "app";
      program = toString (pkgs.writeShellScript "fix-storage" ''
        export PATH="${pkgs.nix}/bin:${pkgs.util-linux}/bin:${pkgs.coreutils}/bin:$PATH"
        exec ${pkgs.nushell}/bin/nu ${./scripts/storage/fix-storage-config.nu}
      '');
      meta = {
        description = "Automatically detect and fix storage configuration issues";
        platforms = pkgs.lib.platforms.linux;
      };
    };
  };

in {
  inherit
    supportedSystems
    isSupported
    isLinux
    isMacOS
    isX86_64
    createFormatter
    createPackage
    createApp
    commonPackages
    linuxPackages
    macosPackages
    commonApps
    linuxApps;
} 