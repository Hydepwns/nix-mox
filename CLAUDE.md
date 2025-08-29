# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Essential Development Commands

### Quick Start
```bash
make help              # Show all commands
make dev               # Enter development environment (alias: nix develop)
make build test        # Build and test
make health-check      # System validation
```

### Build & Development
```bash
# Shells: dev (default), test-shell, gaming-shell (x64), zfs-shell (Linux)
make {shell-name}

# Format (required pre-commit): fmt, format | nix run .#fmt
make fmt

# Build: build, build-all, check | nix flake check  
make build-all check

# Dependencies: update, lock | nix run .#update
make update
```

### Testing & Coverage
```bash
# Tests: test (all), test-flake, ci-test, ci-local, unit, integration, display-test, gaming-test
make test ci-local

# EMI diagnostics: emi-check, emi-report, emi-monitor (5min), emi-stress, emi-watch
make emi-check

# Coverage: coverage (LCOV), coverage-all (all formats), coverage-html, coverage-watch
make coverage-all

# Cleanup: clean (test artifacts), clean-all (+ GC)
make clean-all
```

### System Operations (Linux Only)
```bash
# Validation (CRITICAL before changes): validate, validate-config, validate-storage, validate-pre-rebuild, safety-check, storage-guard
make storage-guard validate-pre-rebuild

# Safe rebuild (NEVER use nixos-rebuild directly)
make safe-rebuild
# Alt: nu scripts/maintenance/safe-rebuild.nu --backup --test-first

# Storage: fix-storage|storage-fix, storage-health | nix run .#fix-storage
make storage-health

# Display (KDE+NVIDIA): display-troubleshoot, display-fix, emergency-display-recovery
make display-fix
```

### Monitoring & Analysis
```bash
# Dashboards: dashboard (overview), dashboard-system, dashboard-performance, dashboard-gaming
make dashboard-system

# Analysis: health-check, analyze-sizes, performance-analyze, code-quality|quality
make health-check code-quality

# Security: security-check, sbom (SPDX/CycloneDX/CSV)
make security-check

# Optimization: cache-optimize
make cache-optimize
```

### Project Info
```bash
make packages shells   # Show available resources
nix flake show         # Full flake structure
```

## Architecture Overview

### Core Structure
This is a **NixOS gaming workstation configuration** with enterprise-grade safety features:

- **Main Configuration**: `config/nixos/configuration.nix` - Core NixOS system configuration
- **Hardware Configuration**: `config/hardware/hardware-configuration.nix` - Hardware-specific settings
- **User Configuration**: Managed via Chezmoi for cross-platform dotfiles
- **Gaming Configuration**: `flakes/gaming/` - Gaming-specific packages and optimizations
- **Build System**: Nix Flakes with Makefile convenience wrappers

### Script Architecture
**Nushell scripts** with functional patterns:

**Root Scripts** (`scripts/`): `validate.nu`, `test.nu`, `setup.nu`, `dashboard.nu`, `storage.nu`

**Libraries** (`scripts/lib/`): `logging.nu`, `validators.nu`, `platform.nu`, `command-wrapper.nu`, `secure-command.nu`, `privilege-manager.nu`

### Safety Features
**CRITICAL SYSTEMS** preventing boot failures:
1. **Storage Guard** - MANDATORY before reboot
2. **Safe Rebuild** - NEVER use `nixos-rebuild` directly  
3. **Auto-rollback** - 3 failed boots triggers rollback
4. **Pre-rebuild Validation** - Comprehensive pre-change checks

### Platform Support
- **Primary**: NixOS Linux (main gaming workstation)
- **Secondary**: macOS, Windows (via platform-specific scripts in `scripts/platforms/`)
- **Cross-platform**: User dotfiles via Chezmoi templates

## Development Workflow

### Making Changes
1. `nix develop` - Always use dev shell
2. `make fmt` - Format before commits  
3. `make validate` - Before system changes
4. `make test` - For script changes
5. `make storage-guard` - Before reboots

### Script Development
All scripts follow this pattern:
```nushell
#!/usr/bin/env nu
use ../lib/logging.nu *
use ../lib/validators.nu *
use ../lib/platform.nu *

def main [] {
    banner "Script Name"
    let platform = (get_platform)
    
    # Script logic using unified libraries
    success "Operation completed"
}
```

### Testing Philosophy
- **Unit Tests**: `scripts/testing/unit/` - Test individual functions and utilities
- **Integration Tests**: `scripts/testing/integration/` - Test complete workflows
- **Safety Tests**: `scripts/testing/validation/` - Test safety and validation systems
- **Platform Tests**: `scripts/testing/[linux|macos|windows]/` - Platform-specific testing

## Common Tasks

### Common Tasks

**System Packages**: Edit `config/nixos/configuration.nix` → `make validate-config storage-guard safe-rebuild`

**Gaming**: `flakes/gaming/` → `make gaming-setup gaming-test`

**Dotfiles**: Chezmoi → `make chezmoi-apply chezmoi-diff chezmoi-sync`

**Troubleshooting**: `make health-check dashboard-system storage-guard validate-config` | `journalctl -xe`

## Critical Safety Rules

### 🛡️ SECURITY REQUIREMENTS (NEW):
- ✅ Use `secure_execute()` instead of `^sh -c` for command execution
- ✅ Use `secure_sudo()` for all privileged operations 
- ✅ Validate inputs with security module before execution
- ✅ Review security logs regularly: `logs/security.log`
- ✅ Run security audits: `make security-check`

### NEVER DO THESE:
- ❌ `nixos-rebuild` directly - ALWAYS use `make safe-rebuild` or `scripts/maintenance/safe-rebuild.nu`
- ❌ Direct shell execution with `^sh -c` - use `secure_system()` instead
- ❌ Raw sudo without privilege validation - use `secure_sudo()` 
- ❌ Reboot without running `make storage-guard` first
- ❌ Skip validation before system changes
- ❌ Modify hardware configuration without storage validation
- ❌ Use Wayland with NVIDIA - causes lock screen reset loops

### ALWAYS DO THESE:
- ✅ Use development shell: `nix develop`
- ✅ Format code: `make fmt` before commits
- ✅ **SECURITY**: Use secure command wrappers for all operations
- ✅ **SECURITY**: Validate security before commits: `make security-check`
- ✅ Run storage guard: `make storage-guard` before reboots
- ✅ Use safe rebuild: `make safe-rebuild` for system changes
- ✅ Validate first: `make validate` before changes
- ✅ **SECURITY**: Review audit logs: `logs/security.log`
- ✅ Have emergency recovery ready: Know how to use TTY (Ctrl+Alt+F2) and run `make emergency-display-recovery`

## Display Issues (KDE Plasma 6 + NVIDIA)

### Known Issue
This configuration includes **critical fixes** for KDE Plasma 6 + NVIDIA compatibility issues on NixOS 25.11:
- Lock screen reset loops after login
- Black screen issues with display manager
- Wayland session failures with NVIDIA proprietary drivers

### Emergency Recovery
If you can't get past the lock screen after rebuild:

1. **Switch to TTY**: Press `Ctrl+Alt+F2`
2. **Log in** as your user
3. **Navigate to repo**: `cd /path/to/nix-mox`
4. **Run recovery**: `nix develop --command nu scripts/emergency-display-recovery.nu --auto`
5. **Return to GUI**: Press `Ctrl+Alt+F1`

### Prevention
The configuration automatically:
- Forces X11 sessions (disables Wayland)
- Uses NVIDIA beta drivers for better Plasma 6 support  
- Configures SDDM with NVIDIA-specific settings
- Adds systemd services for display recovery

## Build System Details

### Nix Flake Structure
- `flake.nix` - Main flake with development shells, apps, and NixOS configurations
- `flake.lock` - Locked dependency versions
- `treefmt.nix` - Code formatting configuration
- `Makefile` + `Makefile.d/` - Convenience wrappers for common operations

### Apps & Shells
**Apps** (`nix run`): `.#fmt`, `.#validate`, `.#update`, `.#storage-guard`, `.#fix-storage`

**Shells**: `default`, `testing`, `gaming` (x64), `zfs` (Linux)