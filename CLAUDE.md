# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Bootstrap Requirements (Fresh NixOS Install)
- `./bootstrap-check.sh` - **REQUIRED FIRST** - Works with basic shell, no make needed
- Install missing: `nix-shell -p git nushell` (if bootstrap check shows failures)

### Safety-First Commands (Mandatory Before System Changes)
- `nix-shell -p nushell --run "nu scripts/validation/pre-rebuild-safety-check.nu"` - **REQUIRED** 
- `nix-shell -p nushell --run "nu scripts/validation/safe-flake-test.nu"` - Comprehensive testing
- `nix-shell -p nushell --run "nu scripts/maintenance/safe-rebuild.nu"` - Safe rebuild wrapper
- **NEVER** run `nixos-rebuild` directly - use the safe wrapper

### Storage Safety Commands (Critical for Boot Reliability)
- `nix run .#storage-guard` - **REQUIRED BEFORE REBOOT** - Validates storage configuration
- `nix run .#fix-storage` - Auto-fix storage configuration issues
- **ALWAYS** run storage-guard before rebooting to prevent boot failures

### Working Setup Scripts
- `nix-shell -p nushell --run "nu scripts/setup/simple-install.nu --create-dirs"` - **WORKS** - Basic install
- `nix-shell -p nushell --run "nu scripts/setup/unified-setup.nu"` - **WORKS** - Unified setup (RECOMMENDED)
- `nix-shell -p nushell --run "nu scripts/setup/simple-setup.nu"` - **WORKS** - Simple configuration setup
- `nix-shell -p nushell --run "nu scripts/setup/setup.nu"` - **PARTIAL** - May have input issues
- `scripts/setup/interactive-setup.nu` - **BROKEN** - Nushell syntax errors (closure defaults)

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
- `nu scripts/testing/run-tests.nu` - Run tests with Nushell
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

## Storage Configuration Issues and Prevention

### Root Cause: PartUUID Instability
The system experienced boot failures due to partuuid changes in storage configuration. This occurs when:
- Partition table is modified (repair, resize, clone operations)
- Disk is moved between systems
- Backup/restore operations rewrite partition table
- Disk firmware updates or hardware changes

**Problem**: PartUUIDs can change while filesystem UUIDs remain constant, causing initrd to fail finding root partition.

### Defensive Tools Implemented

#### 1. Storage Guard (`nix run .#storage-guard`)
- **Purpose**: Pre-reboot validation of storage configuration
- **Checks**: Device resolution, UUID/partuuid consistency, initrd modules
- **Usage**: Run before every reboot to catch configuration drift
- **Output**: Clear error messages with suggested fixes

#### 2. Fix Storage Tool (`nix run .#fix-storage`)
- **Purpose**: Automatic detection and correction of storage issues
- **Features**: 
  - Detects mismatched partuuid/UUID
  - Offers choice between UUID (more stable) or partuuid
  - Creates backup before making changes
  - Provides detailed analysis of current vs configured state

#### 3. Enhanced Error Messages
- Storage guard now provides specific guidance when issues are detected
- Shows expected vs actual identifiers
- Suggests exact configuration changes needed

### Best Practices for Storage Configuration

#### 1. Identifier Stability (Most to Least Stable)
1. **Filesystem UUID** - Most stable, survives partition table changes
2. **PartUUID** - Stable unless partition table modified
3. **Device names** - Least stable, can change with hardware changes

#### 2. Configuration Recommendations
- **Prefer UUID over partuuid** for root filesystem
- **Use partuuid for boot partition** (EFI partition partuuid is more stable)
- **Avoid device names** like `/dev/nvme0n1p2` in configuration

#### 3. Maintenance Workflow
1. Run `nix run .#storage-guard` before any reboot
2. If issues detected, run `nix run .#fix-storage` to auto-correct
3. Verify fix with storage-guard again
4. Test configuration with `nix build` before rebooting

### Example Storage Configuration
```nix
# Recommended: Use UUID for root (most stable)
fileSystems."/" = {
  device = "/dev/disk/by-uuid/7938b5a4-ae4d-475c-acda-664f3d04f9f0";
  fsType = "ext4";
};

# Acceptable: Use partuuid for boot (EFI partuuid is stable)
fileSystems."/boot" = {
  device = "/dev/disk/by-partuuid/8021e6ba-3192-4507-b0aa-d5836e86a0b9";
  fsType = "vfat";
  options = [ "fmask=0077" "dmask=0077" ];
};
```

### Troubleshooting Storage Issues

#### Symptoms of Storage Configuration Problems
- System fails to boot after reboot
- Initrd can't find root partition
- "No such device" errors during boot
- Successful rebuild but boot failure

#### Diagnostic Commands
```bash
# Check current mount points and UUIDs
findmnt -no UUID,FSTYPE,SOURCE /

# Check partuuid vs UUID
sudo blkid /dev/nvme0n1p2

# List available identifiers
ls -la /dev/disk/by-uuid/
ls -la /dev/disk/by-partuuid/

# Run storage validation
nix run .#storage-guard
```

#### Recovery Steps
1. Boot into rescue mode or live USB
2. Mount the root filesystem
3. Run `nix run .#fix-storage` to auto-correct configuration
4. Verify with `nix run .#storage-guard`
5. Rebuild and reboot

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
5. **Run `nix run .#storage-guard` before rebooting**
6. Build/deploy with `nixos-rebuild switch --flake .#nixos`

## Important Locations

### Configuration Files
- `config/nixos/configuration.nix` - Main NixOS configuration
- `config/personal/` - User-specific settings (gitignored)
- `config/templates/` - Ready-to-use configuration templates
- `config/hardware/` - Hardware-specific configurations

### Scripts and Tools
- `scripts/setup/setup.nu` - Interactive configuration wizard
- `scripts/maintenance/health-check.nu` - System health validation
- `scripts/testing/` - Test suites organized by type
- `scripts/analysis/` - Analysis and reporting scripts
- `scripts/storage/storage-guard.nu` - Storage validation tool
- `scripts/storage/fix-storage-config.nu` - Storage configuration fixer

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
- **Storage safety tools available**

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
- **Storage tests**: Validate storage configuration stability

All tests run in isolated environments with proper cleanup.