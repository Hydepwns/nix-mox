# nix-mox

> Enterprise-grade NixOS gaming workstation configuration with comprehensive safety features and automation.

[![CI](https://github.com/Hydepwns/nix-mox/workflows/CI%20(Simplified)/badge.svg)](https://github.com/Hydepwns/nix-mox/actions/workflows/ci.yml)
[![Platforms](https://img.shields.io/badge/platforms-linux%20%7C%20macos%20%7C%20windows-blue.svg)](https://github.com/Hydepwns/nix-mox/actions)
[![Tests](https://img.shields.io/badge/tests-100%25-brightgreen.svg)](https://github.com/Hydepwns/nix-mox/actions)

## Quick Start

### Prerequisites
- **NixOS** (fresh install with working display)  
- User account: `hydepwns` (primary user)
- Basic shell access (no additional packages required initially)

### Installation

```bash
# 1. Clone repository
git clone https://github.com/hydepwns/nix-mox.git
cd nix-mox

# 2. CRITICAL: Check bootstrap requirements first  
./bootstrap-check.sh

# 3. Run unified setup (RECOMMENDED - all-in-one solution)
nix-shell -p nushell --run "nu scripts/setup/unified-setup.nu"

# 4. Apply Chezmoi configuration
make chezmoi-apply

# 5. MANDATORY: Validate system safety before any changes  
nix-shell -p nushell --run "nu scripts/validation/pre-rebuild-safety-check.nu --verbose"

# 6. CRITICAL: Validate storage configuration before reboot
nix run .#storage-guard

# 7. Use SAFE rebuild wrapper (never direct nixos-rebuild!)
nix-shell -p nushell --run "nu scripts/maintenance/safe-rebuild.nu --backup --test-first"
```

> **CRITICAL**: 
>
> - ALWAYS run `./bootstrap-check.sh` first on fresh systems
> - NEVER run `nixos-rebuild` directly - use the safe wrapper 
> - ALWAYS run `nix run .#storage-guard` before rebooting
> - This prevents boot failures and display issues

## Architecture

### Consolidated Libraries
All scripts use modern consolidated libraries with functional patterns:
- **`scripts/lib/logging.nu`** - Unified logging system with 15+ helper functions
- **`scripts/lib/validators.nu`** - Pipeline-based validation with composable validators
- **`scripts/lib/command-wrapper.nu`** - Functional command execution patterns
- **`scripts/lib/platform.nu`** - Universal cross-platform detection

### Chezmoi Integration
User configurations are managed through Chezmoi for cross-platform compatibility:
- **Cross-Platform**: Works on Linux, macOS, and Windows
- **Template System**: Dynamic configuration based on environment
- **Version Control**: Git-based dotfile management
- **Atomic Updates**: Safe, reversible configuration changes

## Quick Start Commands

```bash
make help          # Show all available commands
make dev           # Enter development shell
make test          # Run all tests
make safe-rebuild  # Safe system rebuild
```

For comprehensive command documentation:
- **Development Commands**: See [CLAUDE.md](CLAUDE.md#essential-development-commands)
- **User Operations**: See [USER_GUIDE.md](USER_GUIDE.md#available-commands)
- **Script Details**: See [scripts/README.md](scripts/README.md)

## Features

| Category | Features |
|----------|----------|
| **Gaming** | ![Steam](https://img.shields.io/badge/Steam-Optimized-blue) ![Lutris](https://img.shields.io/badge/Lutris-Supported-orange) ![GameMode](https://img.shields.io/badge/GameMode-Enabled-green) ![Hardware Auto-Detect](https://img.shields.io/badge/Hardware-Auto--Detect-purple) |
| **Security** | ![Agenix](https://img.shields.io/badge/Secrets-Encrypted-red) ![Auto-Rollback](https://img.shields.io/badge/Auto--Rollback-3%20Attempts-orange) ![Backup](https://img.shields.io/badge/Backup-Automated-green) |
| **Performance** | ![CPU Governor](https://img.shields.io/badge/CPU-Performance-blue) ![Zram](https://img.shields.io/badge/Zram-Compressed-green) ![Network](https://img.shields.io/badge/Network-BBR-purple) ![SSD](https://img.shields.io/badge/SSD-Optimized-orange) |
| **Setup** | ![Wizard](https://img.shields.io/badge/Wizard-Interactive-blue) ![Auto-Detection](https://img.shields.io/badge/Auto--Detection-Smart-green) ![Defaults](https://img.shields.io/badge/Defaults-Platform--Adaptive-purple) |
| **DevEx** | ![Modular](https://img.shields.io/badge/Architecture-Modular-blue) ![Subflakes](https://img.shields.io/badge/Subflakes-Ready-green) ![Testing](https://img.shields.io/badge/Testing-Comprehensive-orange) |

## Documentation

- **[User Guide](USER_GUIDE.md)** - Comprehensive user guide with quick start, troubleshooting, and advanced usage

## Development

```bash
# Enter dev environment
nix develop

# Quick commands
nix run .#fmt           # Format code
nix run .#validate      # Validate configuration
nix run .#update        # Update flake inputs
nix run .#storage-guard # Validate storage before reboot

# New features
nixos-backup     # Run manual backup
nixos-restore    # Restore from backup
rollback-status  # Check auto-rollback status
secrets-init     # Initialize secrets management
secrets-edit     # Edit encrypted secrets
```

## Configuration Management

For detailed configuration documentation, see [USER_GUIDE.md](USER_GUIDE.md#configuration-management).

### NixOS Configuration
The main NixOS configuration is in `config/nixos/configuration.nix`. This file contains:
- System-level packages and services
- Hardware configuration
- Security settings
- Network configuration

### User Configuration (Chezmoi)
User-specific configurations are managed through Chezmoi templates:
- Shell configuration (zsh/bash)
- Git configuration
- Editor settings
- User packages
- Environment variables

### Gaming Configuration
Gaming-specific configurations are in `flakes/gaming/`:
- GPU drivers and settings
- Gaming tools (Steam, Lutris, etc.)
- Performance optimizations
- Controller support

## Architecture

For detailed architecture documentation:
- **Script Architecture**: See [scripts/README.md](scripts/README.md)
- **Development Setup**: See [CLAUDE.md](CLAUDE.md#architecture-overview)
- **System Components**: See [USER_GUIDE.md](USER_GUIDE.md#system-overview)
- **Platforms**: `scripts/platforms/` - Platform-specific tools

## Quick Reference

### Essential Commands
```bash
# Setup
nu scripts/setup/unified-setup.nu

# Apply configuration
make chezmoi-apply

# Validate system
nu scripts/validation/validate-config.nu

# Health check
nu scripts/maintenance/health-check.nu

# Dashboard
nu scripts/analysis/dashboard.nu
```

### File Locations
- **NixOS Config**: `config/nixos/configuration.nix`
- **User Config**: Managed by Chezmoi
- **Gaming Config**: `flakes/gaming/`
- **Scripts**: `scripts/`
- **Unified Libraries**: `scripts/lib/`

### Key Scripts
- **Setup**: `scripts/setup/unified-setup.nu`
- **Validation**: `scripts/validation/validate-config.nu`
- **Health Check**: `scripts/maintenance/health-check.nu`
- **Dashboard**: `scripts/analysis/dashboard.nu`
- **Storage Guard**: `scripts/storage/storage-guard.nu`
