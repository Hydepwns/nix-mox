# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Critical Safety Commands

### Before ANY System Changes
```bash
# MANDATORY: Check system prerequisites first
./bootstrap-check.sh

# MANDATORY: Validate safety before changes
nix-shell -p nushell --run "nu scripts/validation/pre-rebuild-safety-check.nu --verbose"

# MANDATORY: Check storage configuration before reboot
nix run .#storage-guard

# NEVER run nixos-rebuild directly - use safe wrapper
nix-shell -p nushell --run "nu scripts/maintenance/safe-rebuild.nu --backup --test-first"
```

### If Storage Issues Detected
```bash
# Auto-fix storage configuration
nix run .#fix-storage

# Verify fix worked
nix run .#storage-guard
```

## Essential Development Commands

### Quick Development Access
```bash
# Enter development environment
nix develop

# Show all available commands
make help
./quick-commands.sh

# Format code (REQUIRED before commits)
nix run .#fmt
make fmt

# Run complete test suite  
nix run .#test
make test

# Run specific test categories
make test-unit           # Unit tests only
make test-integration    # Integration tests
make test-gaming        # Gaming setup tests
make test-display       # Display configuration tests
```

### Building and Validation
```bash
# Validate flake configuration
nix flake check

# Build default package
nix build .#default

# Build specific host configuration
nix build .#nixosConfigurations.nixos.config.system.build.toplevel

# Update flake inputs
nix run .#update
```

### Running Individual Tests
```bash
# Run specific test file
nu scripts/testing/unit/platform-tests.nu

# Run with verbose output
nu scripts/testing/run-tests.nu --verbose

# Run tests for specific component
nu scripts/testing/storage/storage-tests.nu
```

## High-Level Architecture

### Core Structure  
This is a **NixOS gaming workstation configuration** with robust safety features:

```
flake.nix                    # Simplified main flake (~220 lines)
├── config/
│   ├── nixos/
│   │   └── configuration.nix # Main config (all features enabled)
│   ├── home/
│   │   └── gamer.nix        # Home-manager config
│   └── hardware/
│       └── hardware-configuration.nix
├── flakes/
│   └── gaming/
│       ├── flake.nix        # Gaming subflake
│       └── module.nix       # Comprehensive gaming module
├── modules/
│   ├── hardware/
│   │   └── auto-detect.nix  # Hardware auto-detection
│   ├── security/
│   │   └── secrets.nix      # Agenix secrets management
│   ├── backup/
│   │   └── restic.nix       # Automated backups
│   └── recovery/
│       └── auto-rollback.nix # Boot failure recovery
└── scripts/                 # Nushell automation
    ├── setup/              # Setup wizards
    ├── validation/         # Safety checks
    └── testing/            # Test suites
```

### New Features Implemented

#### 🎮 Gaming Subflake
- Comprehensive gaming module with platforms (Steam, Lutris, Heroic)
- Performance optimizations (GameMode, CPU governor, network)
- Graphics enhancements (MangoHud, Gamescope, shader cache)
- Audio low-latency configuration

#### 🔧 Hardware Auto-Detection
- Automatic GPU configuration (NVIDIA/AMD/Intel)
- CPU optimization based on vendor
- Memory-aware zram and vm tuning
- Storage type detection and I/O scheduler selection

#### 🔐 Secrets Management (Agenix)
- Encrypted storage for passwords, SSH keys, API tokens
- Helper scripts: `secrets-init`, `secrets-edit`, `secrets-show`
- WiFi password management integration

#### 💾 Backup & Recovery
- Automated daily backups with restic
- Configurable retention policies
- Auto-rollback after 3 failed boots
- Emergency recovery shell

### Multi-Host Management
The flake supports multiple NixOS hosts through `config/hosts.nix`:
- Each host gets its own hardware configuration
- Hosts can share modules and templates
- Per-host specialArgs for customization

### Critical Scripts and Tools

#### Essential Scripts

**Setup & Configuration:**
- `scripts/setup/unified-setup.nu` - All-in-one setup wizard
- `scripts/maintenance/cleanup-codebase.nu` - Remove dead code
- `scripts/testing/test-new-structure.nu` - Validate new architecture

**Backup & Recovery:**
- `nixos-backup` - Manual backup trigger
- `nixos-restore <snapshot> <target>` - Restore from backup
- `rollback-status` - Check auto-rollback status
- `rollback-reset` - Reset boot counter

**Secrets Management:**
- `secrets-init` - Initialize secrets system
- `secrets-edit <name>` - Edit encrypted secret
- `secrets-show <name>` - Display decrypted secret

#### Safety Validation (scripts/validation/)
- `pre-rebuild-safety-check.nu` - **MANDATORY** before rebuilds
- `safe-flake-test.nu` - Comprehensive flake testing
- `validate-display-config.nu` - Display manager validation

#### Storage Safety (scripts/storage/)
- `storage-guard.nu` - **CRITICAL** pre-reboot storage validation
- `fix-storage-config.nu` - Auto-fix UUID/partuuid mismatches

### Testing Strategy
The project uses comprehensive multi-layer testing:
1. **Unit tests** - Test individual functions/modules
2. **Integration tests** - Test module interactions
3. **Platform tests** - Platform-specific functionality
4. **Display tests** - GUI/display configuration validation
5. **Gaming tests** - Gaming setup verification
6. **Storage tests** - Storage configuration safety

All tests run in isolated environments with proper cleanup.

## Platform Support

### Linux/NixOS (Primary)
- Full feature support with all modules
- Gaming configurations with Steam, Lutris, etc.
- ZFS storage, Proxmox integration
- Comprehensive monitoring stack

### macOS (Development)
- Development shells with Homebrew integration
- macOS-specific maintenance scripts
- Limited to development features

### Windows WSL (Basic)
- Nix development environment
- Cross-platform script compatibility
- Focus on development workflows

## Working Setup Scripts

### Verified Working
- `nu scripts/setup/unified-setup.nu` - **RECOMMENDED**
- `nu scripts/setup/simple-install.nu --create-dirs`
- `nu scripts/setup/simple-setup.nu`

### Known Issues
- `setup.nu` - Input handling problems in some environments
- `interactive-setup.nu` - **BROKEN** - Nushell syntax errors

## Storage Configuration Best Practices

### Identifier Hierarchy (Most → Least Stable)
1. **Filesystem UUID** - Survives partition table changes
2. **PartUUID** - Changes with partition table modifications  
3. **Device names** - Least stable, avoid

### Prevent Boot Failures
```bash
# ALWAYS run before reboot
nix run .#storage-guard

# If issues found
nix run .#fix-storage

# Verify fix
nix run .#storage-guard
```

## Code Conventions

### Nix Files
- Format with `nixpkgs-fmt` via `nix run .#fmt`
- Prefer explicit attribute sets over `with` statements
- Use the fragment system for modularity
- Document complex configurations inline

### Nushell Scripts
- Use structured data and pipelines
- Include error handling with try-catch
- Follow consistent naming: `kebab-case.nu`
- Add help text for user-facing scripts

### Testing
- Test files end with `-tests.nu`
- Use shared test utilities from `scripts/testing/lib/`
- Clean up test artifacts in finally blocks
- Include both positive and negative test cases