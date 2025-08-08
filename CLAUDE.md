# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Bootstrap Requirements (Fresh NixOS Install)
- `./bootstrap-check.sh` - **REQUIRED FIRST** - Works with basic shell, no make needed
- Install missing: `nix-shell -p git nushell` (if bootstrap check shows failures)

### Safety-First Commands (Mandatory Before System Changes)
- `nix-shell -p nushell --run "nu scripts/validation/pre-rebuild-safety-check.nu"` - **REQUIRED** 
- `nix-shell -p nushell --run "nu scripts/validation/safe-flake-test.nu"` - Comprehensive testing
- `nix-shell -p nushell --run "nu scripts/core/safe-rebuild.nu"` - Safe rebuild wrapper
- **NEVER** run `nixos-rebuild` directly - use the safe wrapper

### Working Setup Scripts
- `nix-shell -p nushell --run "nu scripts/core/simple-install.nu --create-dirs"` - **WORKS** - Basic install
- `nix-shell -p nushell --run "nu scripts/core/unified-setup.nu"` - **WORKS** - Unified setup (RECOMMENDED)
- `nix-shell -p nushell --run "nu scripts/core/simple-setup.nu"` - **WORKS** - Simple configuration setup
- `nix-shell -p nushell --run "nu scripts/core/setup.nu"` - **PARTIAL** - May have input issues
- `scripts/core/interactive-setup.nu` - **BROKEN** - Nushell syntax errors (closure defaults)

### Alternative: Using Make (if available)
- `make safety-check` - Shorthand for safety validation 
- `make safe-test` - Shorthand for comprehensive testing
- `make safe-rebuild` - Shorthand for safe rebuild wrapper

### Essential Development Commands
- `nix develop` - Enter the default development shell
- `nix run .#fmt` - Format all code with treefmt (Nix, shell, JSON, YAML, etc.)
- `nix run .#test` - Run complete test suite
- `nix flake check` - Validate flake configuration
- `make help` - Show comprehensive command reference

### Testing
- `make test` - Run all tests (unit + integration)
- `make test-unit` - Run unit tests only
- `make test-integration` - Run integration tests only
- `nu scripts/tests/run-tests.nu` - Run tests with Nushell
- Platform-specific: `make test-gaming`, `make validate-display`

### Development Shells
- `nix develop .#development` - Full development tools
- `nix develop .#testing` - Testing environment
- `nix develop .#gaming` - Gaming setup tools (Linux only)
- `nix develop .#services` - Service management (Linux only)
- `nix develop .#monitoring` - Monitoring tools (Linux only)
- `nix develop .#macos` - macOS development (macOS only)

### Build and Maintenance
- `nix build .#default` - Build default package
- `make build-all` - Build all packages
- `nix run .#update` - Update flake inputs
- `make clean` - Clean test artifacts
- `make clean-all` - Deep clean including Nix store GC

## Architecture Overview

### Core Structure
This is a **NixOS configuration framework** with cross-platform development tools:

- **`flake.nix`** - Main flake defining outputs, packages, and development shells
- **`config/`** - NixOS configurations, templates, and user settings
- **`modules/`** - Reusable NixOS modules organized by category
- **`scripts/`** - Nushell scripts for automation and tooling
- **`devshells/`** - Development environment definitions
- **`docs/`** - Comprehensive documentation

### Module System
The framework uses a **fragment-based module system**:
- Base modules provide core functionality
- Fragments allow granular feature composition
- Templates combine fragments for common use cases
- Personal configs override defaults (gitignored)

### Key Patterns
- **Cross-platform support**: Linux, macOS, Windows (WSL) with platform detection
- **Template-based configuration**: Pre-built configs for gaming, development, server, minimal setups
- **Flake-first design**: All functionality exposed through flake outputs
- **Nushell-based tooling**: Scripts written in Nushell for consistency
- **Multi-host management**: Single flake manages multiple NixOS hosts

### Development Workflow
1. Use `nix develop` to enter development environment
2. Make changes to Nix files
3. Format with `nix run .#fmt` before committing
4. Test with `nix run .#test` or `make test`
5. Build/deploy with `nixos-rebuild switch --flake .#nixos`

## Important Locations

### Configuration Files
- `config/nixos/configuration.nix` - Main NixOS configuration
- `config/personal/` - User-specific settings (gitignored)
- `config/templates/` - Ready-to-use configuration templates
- `config/hardware/` - Hardware-specific configurations

### Scripts and Tools
- `scripts/core/setup.nu` - Interactive configuration wizard
- `scripts/core/health-check.nu` - System health validation
- `scripts/tests/` - Test suites organized by type
- `scripts/tools/` - Utility scripts for analysis and maintenance

### Module Categories
- `modules/core/` - Essential framework modules
- `modules/gaming/` - Gaming-specific configurations
- `modules/services/` - System services
- `modules/security/` - Security hardening
- `modules/storage/` - Storage and backup solutions
- `modules/templates/` - Template system implementation

## Platform-Specific Notes

### Linux/NixOS
- Primary target platform with full feature support
- Gaming tools, Proxmox integration, ZFS support
- Service management and monitoring capabilities

### macOS
- Development shell support with Homebrew integration
- macOS-specific packages and maintenance tools
- Limited to development and tooling features

### Windows (WSL)
- Basic Nix development environment support
- Cross-platform script compatibility
- Focus on development workflows

## Code Style and Conventions

### Nix Code
- Use `nixpkgs-fmt` for formatting
- Follow existing import patterns
- Prefer explicit attribute sets over `with` statements
- Comment complex configurations

### Nushell Scripts
- Use structured data and pipelines
- Include error handling with try-catch blocks
- Follow consistent naming conventions
- Add help text for user-facing scripts

### File Organization
- Group related functionality in modules
- Use fragments for composable features
- Keep personal configurations separate and gitignored
- Document complex configurations inline

## Testing Strategy

The project uses comprehensive testing:
- **Unit tests**: Test individual functions and modules
- **Integration tests**: Test module interactions and workflows
- **Platform tests**: Test platform-specific functionality
- **Display tests**: Test GUI and display configurations
- **Gaming tests**: Test gaming setup and performance

All tests run in isolated environments with proper cleanup.