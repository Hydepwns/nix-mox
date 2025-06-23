{ pkgs }:

{
  # Import all shell configurations
  development = import ./development/default.nix { inherit pkgs; };
  testing = import ./testing/default.nix { inherit pkgs; };
  services = import ./services/default.nix { inherit pkgs; };
  monitoring = import ./monitoring/default.nix { inherit pkgs; };
  macos = import ./macos/default.nix { inherit pkgs; };

  # Default shell (inline mkShell definition)
  default = pkgs.mkShell {
    buildInputs = [
      pkgs.nushell
      pkgs.git
      pkgs.nix
      pkgs.nixpkgs-fmt
      pkgs.shellcheck
      pkgs.coreutils
      pkgs.fd
      pkgs.ripgrep
    ] ++ (
      # Platform-specific dependencies
      if pkgs.stdenv.isDarwin then [
        pkgs.darwin.apple_sdk.frameworks.CoreServices
        pkgs.darwin.apple_sdk.frameworks.Foundation
      ] else if pkgs.stdenv.isLinux then [
        pkgs.zlib
        pkgs.openssl
      ] else [ ]
    );

    # Platform-specific environment variables
    shellHook = ''
      # Set platform-specific environment variables
      export NIX_MOX_PLATFORM=${pkgs.system}
      export NIX_MOX_IS_LINUX=${if pkgs.stdenv.isLinux then "true" else "false"}
      export NIX_MOX_IS_DARWIN=${if pkgs.stdenv.isDarwin then "true" else "false"}
      export NIX_MOX_ARCH=${pkgs.stdenv.hostPlatform.parsed.cpu.name}

      # Platform-specific settings
      ${if pkgs.stdenv.isDarwin then ''
        export MACOSX_DEPLOYMENT_TARGET=11.0
        export SDKROOT=${pkgs.darwin.apple_sdk.MacOSX-SDK}/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk
      '' else ""}

      # Function to show help menu
      show_help() {
        echo "Welcome to the nix-mox default shell!"
        echo ""
        echo "🖥️  Platform Information"
        echo "----------------------"
        echo "System: ${pkgs.system}"
        echo "Architecture: ${pkgs.stdenv.hostPlatform.parsed.cpu.name}"
        echo "Platform: ${if pkgs.stdenv.isDarwin then "macOS" else if pkgs.stdenv.isLinux then "Linux" else "Other"}"
        echo ""
        echo "🔧 Base Tools"
        echo "-----------"
        echo "nu: (v${pkgs.nushell.version})"
        echo "    Commands:"
        echo "    - nu -c 'ls | where size > 1mb'    # List large files"
        echo "    - nu -c 'ps | where cpu > 50'      # Show high CPU processes"
        echo ""
        echo "git: (v${pkgs.git.version})"
        echo "    Commands:"
        echo "    - git status                       # Check repository status"
        echo "    - git log --oneline               # View commit history"
        echo ""
        echo "nix: (v${pkgs.nix.version})"
        echo "    Commands:"
        echo "    - nix develop                     # Enter development shell"
        echo "    - nix build                       # Build packages"
        echo ""
        echo "nixpkgs-fmt: (v${pkgs.nixpkgs-fmt.version})"
        echo "    Commands:"
        echo "    - nixpkgs-fmt .                   # Format all Nix files"
        echo "    - nix fmt                         # Format using flake"
        echo ""
        echo "shellcheck: (v${pkgs.shellcheck.version})"
        echo "    Commands:"
        echo "    - shellcheck scripts/*.sh         # Check shell scripts"
        echo "    - shellcheck -x scripts/*.sh      # Check with shell specified"
        echo ""
        echo "coreutils: (v${pkgs.coreutils.version})"
        echo "    Commands:"
        echo "    - ls -la                          # List files with details"
        echo "    - cp -r source dest              # Copy recursively"
        echo ""
        echo "fd: (v${pkgs.fd.version})"
        echo "    Commands:"
        echo "    - fd '\.rs$'                     # Find Rust files"
        echo "    - fd -e md                       # Find Markdown files"
        echo ""
        echo "ripgrep: (v${pkgs.ripgrep.version})"
        echo "    Commands:"
        echo "    - rg 'TODO'                      # Find TODOs"
        echo "    - rg -t py 'def '                # Find Python functions"
        echo ""
        echo "📝 Quick Start"
        echo "------------"
        echo "1. Enter specialized shells:"
        echo "   nix develop .#development         # Development tools"
        echo "   nix develop .#testing            # Testing tools"
        echo "   nix develop .#services           # Service tools"
        echo "   nix develop .#monitoring         # Monitoring tools"
        ${if pkgs.stdenv.isDarwin then ''
        echo "   nix develop .#macos              # macOS development (macOS only)"
        '' else ""}
        echo ""
        echo "2. Run packaged scripts:"
        ${if pkgs.stdenv.isLinux then ''
        echo "   nix run .#proxmox-update         # Update Proxmox (Linux only)"
        echo "   nix run .#vzdump-backup          # Backup VMs (Linux only)"
        echo "   nix run .#zfs-snapshot           # Manage ZFS snapshots (Linux only)"
        '' else ""}
        ${if pkgs.stdenv.isDarwin then ''
        echo "   nix run .#homebrew-setup         # Setup Homebrew (macOS only)"
        echo "   nix run .#macos-maintenance      # System maintenance (macOS only)"
        echo "   nix run .#xcode-setup            # Setup Xcode tools (macOS only)"
        echo "   nix run .#security-audit         # Security audit (macOS only)"
        '' else ""}
        echo ""
        echo "3. Format Nix code:"
        echo "   nix fmt"
        echo ""
        echo "For more information, see docs/."
      }

      # Show initial help menu
      show_help

      # Add help command to shell
      echo ""
      echo "💡 Tip: Type 'help' to show this menu again"
      echo "💡 Tip: Type 'which-shell' to see which shell you're in"
      echo "💡 Tip: Type 'platform-info' to see platform information"
      echo ""
      alias help='show_help'
      alias which-shell='echo "You are in the nix-mox default shell"'
      alias platform-info='echo "Platform: ${pkgs.system} | Architecture: ${pkgs.stdenv.hostPlatform.parsed.cpu.name} | OS: ${if pkgs.stdenv.isDarwin then "macOS" else if pkgs.stdenv.isLinux then "Linux" else "Other"}"'
    '';
  };
}
