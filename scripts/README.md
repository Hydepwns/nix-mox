# nix-mox Scripts

This directory contains all platform-specific and automation scripts for the nix-mox toolkit, organized by functionality for better maintainability and discoverability.

## 📁 Directory Structure

```
scripts/
├── storage/           # Storage safety and configuration tools
│   ├── storage-guard.nu          # Pre-reboot storage validation
│   └── fix-storage-config.nu     # Auto-fix storage issues
├── maintenance/       # System maintenance and health tools
│   ├── health-check.nu           # System health validation
│   ├── cleanup.nu                # Project cleanup
│   ├── safe-rebuild.nu           # Safe system rebuild
│   ├── integrate-modules.nu      # Module integration
│   └── ci/                       # CI/CD tools
├── analysis/          # Analysis and reporting tools
│   ├── analyze-sizes.nu          # Package size analysis
│   ├── analyze-sizes.sh          # Shell version of size analysis
│   ├── advanced-cache.nu         # Cache optimization
│   ├── generate-docs.nu          # Documentation generation
│   ├── generate-sbom.nu          # Software bill of materials
│   ├── dashboard.nu              # Main dashboard
│   ├── project-dashboard.nu      # Project-specific dashboard
│   ├── simple-dashboard.nu       # Simplified dashboard
│   ├── size-dashboard.nu         # Size analysis dashboard
│   ├── status-dashboard.nu       # Status dashboard
│   ├── quality/                  # Code quality tools
│   └── benchmarks/               # Performance benchmarks
├── setup/            # System setup and installation
│   ├── simple-install.nu         # Basic installation
│   ├── simple-setup.nu           # Basic configuration setup
│   ├── unified-setup.nu          # All-in-one setup
│   ├── install.nu                # Installation tools
│   ├── setup-cachix.nu           # Cachix configuration
│   ├── setup-remote-builder.nu   # Remote builder setup
│   ├── setup-remote-builder.sh   # Shell version
│   ├── test-remote-builder.nu    # Remote builder testing
│   └── test-remote-builder.sh    # Shell version
├── testing/          # Testing and validation tools
│   ├── run-tests.nu              # Main test runner
│   ├── setup-coverage.nu         # Coverage setup
│   ├── generate-codecov.nu       # Codecov integration
│   ├── generate-lcov.nu          # LCOV coverage
│   ├── test-coverage-debug.nu    # Coverage debugging
│   ├── unit/                     # Unit tests
│   ├── integration/              # Integration tests
│   ├── performance/              # Performance tests
│   ├── display/                  # Display tests
│   ├── storage/                  # Storage tests
│   ├── linux/                    # Linux-specific tests
│   ├── macos/                    # macOS-specific tests
│   ├── windows/                  # Windows-specific tests
│   └── lib/                      # Test libraries
├── validation/       # System validation tools
│   ├── pre-rebuild-safety-check.nu    # Pre-rebuild validation
│   ├── safe-flake-test.nu             # Flake testing
│   ├── validate-display-config.nu     # Display validation
│   └── validate-gaming-config.nu      # Gaming validation
├── platforms/        # Platform-specific tools
│   ├── linux/                    # Linux-specific scripts
│   ├── macos/                    # macOS-specific scripts
│   └── windows/                  # Windows-specific scripts
├── lib/              # Shared libraries and utilities
├── common/           # Common utilities and helpers
└── handlers/         # Event handlers and automation
```

## 🎯 Script Categories

### Storage Safety (Critical)
- **Purpose**: Prevent boot failures due to storage configuration issues
- **Location**: `scripts/storage/`
- **Key Tools**: `storage-guard.nu`, `fix-storage-config.nu`
- **Usage**: Run before every reboot

### Maintenance
- **Purpose**: System health, cleanup, and safe operations
- **Location**: `scripts/maintenance/`
- **Key Tools**: `health-check.nu`, `cleanup.nu`, `safe-rebuild.nu`
- **Usage**: Regular maintenance and before system changes

### Analysis
- **Purpose**: Performance analysis, reporting, and optimization
- **Location**: `scripts/analysis/`
- **Key Tools**: `analyze-sizes.nu`, `dashboard.nu`, `generate-docs.nu`
- **Usage**: Performance monitoring and optimization

### Setup
- **Purpose**: System installation and configuration
- **Location**: `scripts/setup/`
- **Key Tools**: `unified-setup.nu`, `simple-install.nu`
- **Usage**: Initial setup and configuration

### Testing
- **Purpose**: Comprehensive testing and validation
- **Location**: `scripts/testing/`
- **Key Tools**: `run-tests.nu`, `setup-coverage.nu`
- **Usage**: Development and CI/CD

### Validation
- **Purpose**: System validation and safety checks
- **Location**: `scripts/validation/`
- **Key Tools**: `pre-rebuild-safety-check.nu`, `safe-flake-test.nu`
- **Usage**: Before system changes

## 🚀 Quick Reference

### Critical Commands (Run Before Reboot)
```bash
# Storage safety (CRITICAL)
nix run .#storage-guard
nix run .#fix-storage

# System validation
nix-shell -p nushell --run "nu scripts/validation/pre-rebuild-safety-check.nu"
```

### Setup Commands
```bash
# Unified setup (recommended)
nix-shell -p nushell --run "nu scripts/setup/unified-setup.nu"

# Basic setup
nix-shell -p nushell --run "nu scripts/setup/simple-setup.nu"
```

### Maintenance Commands
```bash
# Health check
nix-shell -p nushell --run "nu scripts/maintenance/health-check.nu"

# Cleanup
nix-shell -p nushell --run "nu scripts/maintenance/cleanup.nu"

# Safe rebuild
nix-shell -p nushell --run "nu scripts/maintenance/safe-rebuild.nu"
```

### Analysis Commands
```bash
# Size analysis
nix-shell -p nushell --run "nu scripts/analysis/analyze-sizes.nu"

# Dashboard
nix-shell -p nushell --run "nu scripts/analysis/dashboard.nu"
```

### Testing Commands
```bash
# Run all tests
nix-shell -p nushell --run "nu scripts/testing/run-tests.nu"

# Setup coverage
nix-shell -p nushell --run "nu scripts/testing/setup-coverage.nu"
```

## 🔧 Enhanced Features

### Error Handling
- Structured error types with recovery strategies
- Unique error IDs for tracking
- Context-aware error reporting
- Automatic error logging and statistics

### Configuration Management
- Multi-source configuration loading
- Configuration validation and schema checking
- Environment variable overrides
- Hierarchical configuration merging

### Logging
- Multiple output formats (text, JSON, structured)
- Automatic log rotation
- Context-aware logging
- Performance and security event logging

### Security Validation
- Dangerous pattern detection
- File permission validation
- Dependency security checking
- Network access monitoring

### Performance Monitoring
- Execution time tracking
- Resource usage monitoring
- Performance threshold alerts
- Performance reporting and recommendations

## 📋 Best Practices

### 1. Always Use Storage Safety
```bash
# Before any reboot
nix run .#storage-guard
```

### 2. Use Safe Rebuild Wrapper
```bash
# Instead of direct nixos-rebuild
nix-shell -p nushell --run "nu scripts/maintenance/safe-rebuild.nu"
```

### 3. Run Health Checks Regularly
```bash
# Regular maintenance
nix-shell -p nushell --run "nu scripts/maintenance/health-check.nu"
```

### 4. Use Appropriate Script Categories
- **Storage**: For storage-related operations
- **Maintenance**: For system maintenance
- **Analysis**: For performance and reporting
- **Setup**: For installation and configuration
- **Testing**: For validation and testing
- **Validation**: For safety checks

## 🔍 Finding Scripts

### By Function
- **Storage issues**: `scripts/storage/`
- **System health**: `scripts/maintenance/`
- **Performance**: `scripts/analysis/`
- **Installation**: `scripts/setup/`
- **Testing**: `scripts/testing/`
- **Validation**: `scripts/validation/`

### By Platform
- **Linux**: `scripts/platforms/linux/`
- **macOS**: `scripts/platforms/macos/`
- **Windows**: `scripts/platforms/windows/`

### By Type
- **Nushell scripts**: `.nu` extension
- **Shell scripts**: `.sh` extension
- **Libraries**: `scripts/lib/`
- **Common utilities**: `scripts/common/`

## 📚 Related Documentation

- [CLAUDE.md](../CLAUDE.md) - Development guidance
- [Storage Safety Guide](../docs/STORAGE_SAFETY.md) - Storage safety best practices
- [Quick Start Guide](../docs/QUICK_START.md) - Getting started
- [Troubleshooting](../docs/TROUBLESHOOTING.md) - Common issues
