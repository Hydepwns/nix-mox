# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Essential Development Commands

### Quick Start Commands
- `make help` - Show all available commands
- `make dev` - Enter development shell with all tools
- `make test` - Run all tests (unit + integration)
- `make fmt` - Format all code using treefmt
- `make build` - Build default package

### Critical Safety Commands
- `make storage-guard` - **ALWAYS run before reboot** to validate storage config
- `make safety-check` - Run mandatory safety validation
- `make pre-rebuild` - Comprehensive pre-rebuild validation
- `make safe-rebuild` - Use safe nixos-rebuild wrapper (NEVER use direct `nixos-rebuild`)

### Editor Extensions & Themes
- **Zed Extension**: `extensions/zed/` - Enhanced Nushell development with nix-mox integration
- **Synthwave84 Zed Theme**: https://github.com/Hydepwns/synthwave84-zed (maintained separately)
- **VSCode Extension**: `extensions/vscode/` - Includes Synthwave84 theme and nix-mox snippets
- `make build-zed-extension` - Build the Zed extension
- `make install-synthwave84-zed` - Install/update Synthwave84 theme for Zed

### NixOS Build Commands
- `nix run .#fmt` - Format code with treefmt
- `nix run .#validate` - Validate flake configuration
- `nix run .#storage-guard` - Validate storage before reboot
- `nix run .#test` - Run comprehensive tests
- `sudo nixos-rebuild test --flake .#nixos` - Test configuration
- `sudo nixos-rebuild switch --flake .#nixos` - Apply configuration

### Testing Commands
- `make test` - Run all tests
- `make unit` - Unit tests only
- `make integration` - Integration tests only
- `make gaming-test` - Test gaming configuration
- `make display-test` - Test display configuration

### Chezmoi Integration (Consolidated)
- `make chezmoi-apply` - Apply user configuration (uses `scripts/chezmoi.nu apply`)
- `make chezmoi-diff` - Show configuration differences (uses `scripts/chezmoi.nu diff`)
- `make chezmoi-sync` - Sync with remote repository (uses `scripts/chezmoi.nu sync`)
- `nu scripts/chezmoi.nu help` - Show all chezmoi commands
- `nu scripts/chezmoi.nu status` - Check chezmoi status

## Architecture Overview

### Core Structure
This is an **enterprise-grade NixOS gaming workstation configuration** with comprehensive safety features:

- **Main Config**: `config/nixos/configuration.nix` - Core system configuration
- **Hardware**: `config/hardware/hardware-configuration.nix` - Hardware-specific settings
- **User Config**: `config/personal/hydepwns.nix` - User-specific configuration
- **Gaming**: `flakes/gaming/` - Gaming-specific modules (optional subflake)

### Script Architecture
All scripts now use **modern consolidated libraries** with functional patterns:

- **Consolidated Libraries (Active - DRY Functional Patterns)**:
  - `scripts/lib/logging.nu` - **Unified logging system** with 15+ helper functions
    - Replaces 3,078+ print statements across codebase
    - Functions: `banner()`, `progress()`, `step()`, `summary()`, `status_report()`, etc.
    - Consistent color-coded output with timestamps and contexts
  - `scripts/lib/command-wrapper.nu` - **Functional command execution** 
    - 8+ specialized wrappers: `nix_eval()`, `git_command()`, `apt_command()`, etc.
    - Retry/timeout patterns, cross-platform package management
  - `scripts/lib/validators.nu` - **Pipeline-based validation system**
    - Composable validators with functional composition
    - Platform detection (NixOS→Linux), command/file validation
  - `scripts/lib/platform.nu` - **Universal platform detection**
    - Cross-platform compatibility (Linux variants, macOS, Windows)
  - `scripts/lib/script-template.nu` - **Standard script patterns**
    - Eliminates boilerplate, consistent argument handling
  - `scripts/lib/analysis.nu` - **Consolidated analysis functions**
    - System reporting, performance metrics, size analysis

- **Consolidated Scripts (Functional Dispatchers)**:
  - `scripts/validate.nu` - **Unified validation system** (replaces 9 individual scripts)
  - `scripts/test.nu` - **Comprehensive test runner** with coverage integration
  - `scripts/setup.nu` - **Consolidated setup system** 
  - `scripts/dashboard.nu` - **Interactive system dashboard**
  - `scripts/chezmoi.nu` - **Consolidated chezmoi management** (replaces 4 individual scripts)
  - `scripts/storage.nu` - **Storage operations consolidation**
  - `scripts/coverage.nu` - **Testing coverage consolidation**

- **Script Categories**:
  - `scripts/setup/` - Installation and configuration
  - `scripts/maintenance/` - System health and cleanup  
  - `scripts/storage/` - Critical boot safety validation
  - `scripts/validation/` - System validation
  - `scripts/testing/` - Comprehensive test suites
  - `scripts/analysis/` - Performance monitoring and analysis

- **Legacy Migration Complete**: All deprecated libraries have been fully migrated to modern consolidated patterns

### Safety-First Design
This system has **multiple safety layers**:

1. **Storage Guard**: Validates storage configuration before reboot
2. **Safe Rebuild**: Wrapper around nixos-rebuild with validation
3. **Pre-rebuild Checks**: Comprehensive validation before system changes
4. **Auto-rollback**: Automatic rollback on failed boots
5. **Backup System**: Automated backups before changes

### Chezmoi Integration
User configurations are managed through **Chezmoi** for cross-platform compatibility:
- Dynamic configuration based on environment
- Git-based dotfile management
- Atomic, reversible configuration changes
- Works across Linux, macOS, and Windows

## Critical Safety Rules

1. **NEVER** run `nixos-rebuild` directly - always use `make safe-rebuild`
2. **ALWAYS** run `make storage-guard` before rebooting
3. **ALWAYS** run `make pre-rebuild` before system changes
4. **ALWAYS** run `./bootstrap-check.sh` first on fresh systems
5. Use `make safety-check` for mandatory validation

## Development Workflow

1. Enter development shell: `make dev` or `nix develop`
2. Make changes to configuration files
3. Validate changes: `make pre-rebuild`
4. Test configuration: `sudo nixos-rebuild test --flake .#nixos`
5. Run tests: `make test`
6. Format code: `make fmt`
7. Apply safely: `make safe-rebuild`

## Key Files to Understand

- `flake.nix` - Main flake with NixOS configurations and development tools
- `Makefile` - Comprehensive command interface (includes modular makefiles)
- `treefmt.nix` - Code formatting configuration for all file types
- **Consolidated Libraries**:
  - `scripts/lib/logging.nu` - Modern logging system with 15+ helper functions
  - `scripts/lib/validators.nu` - Pipeline-based validation with platform detection
  - `scripts/lib/command-wrapper.nu` - Functional command execution patterns
  - `scripts/lib/platform.nu` - Universal cross-platform detection
- **Main Consolidated Scripts**:
  - `scripts/validate.nu` - Unified validation system (5 test suites)
  - `scripts/chezmoi.nu` - Consolidated chezmoi management
  - `scripts/test.nu` - Comprehensive test runner with coverage
- `config/nixos/configuration.nix` - Main NixOS system configuration
- `extensions/zed/extension.json` - Zed editor extension configuration
- `extensions/vscode/themes/synthwave84-color-theme.json` - Synthwave84 theme for VSCode

## Testing Strategy

The project uses **comprehensive testing** with multiple layers:
- Unit tests for individual components
- Integration tests for system interactions  
- Gaming-specific tests for hardware compatibility
- Display manager safety tests
- Performance benchmarks
- Coverage reporting with LCOV

## Performance & Gaming Focus

Optimized for **Intel i7-13700K + NVIDIA RTX 4070**:
- Zen kernel for gaming performance
- CPU governor set to performance
- NVIDIA driver optimizations
- GameMode integration
- Steam and Lutris pre-configured
- Hardware auto-detection

## Consolidation Achievements (2024-2025)

**Major Deduplication & DRY Improvements:**
- ✅ **Eliminated 3,078+ duplicate print statements** → Unified `lib/logging.nu` system
- ✅ **Consolidated 4 chezmoi scripts** → Single `scripts/chezmoi.nu` dispatcher  
- ✅ **Created 15+ helper functions** → `banner()`, `progress()`, `step()`, `summary()`, etc.
- ✅ **Added 8+ command wrappers** → `nix_eval()`, `git_command()`, `apt_command()`, etc.
- ✅ **Fixed NixOS platform detection** → 5/5 validation tests now pass
- ✅ **Functional programming patterns** → Higher-order functions, pipeline composition
- ✅ **100% legacy library migration** → All deprecated `unified-*` libraries removed
- ✅ **Reduced ~70% code duplication** → From scattered patterns to consolidated libraries

**Migration Complete:**
- **Before:** 105+ scripts using deprecated `unified-*` libraries with massive duplication
- **After:** 134 scripts using modern `lib/*` libraries with functional patterns
- **Achievement:** 100% migration to consolidated architecture - zero deprecated libraries remain
- **Result:** Consistent error handling, logging, and command execution across entire codebase

## Common Patterns

- All scripts use **Nushell (`.nu` files)** for consistency and functional programming
- **Modern consolidated libraries** with functional composition patterns
- **Color-coded logging** with timestamps, contexts, and consistent formatting
- **Pipeline-based validation** with composable validators
- **Cross-platform command execution** with specialized wrappers
- **Safety-first approach** with multiple validation layers  
- **Modular architecture** with clear separation of concerns
- **Cross-platform compatibility** through Chezmoi integration