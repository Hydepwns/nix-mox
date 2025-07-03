# nix-mox Scripts

This directory contains all platform-specific and automation scripts for the nix-mox toolkit, featuring enhanced error handling, logging, configuration management, and security validation.

## 🚀 Enhanced Features

### **New Architecture**

- **Modular Design**: Separated core, platform, and tools scripts
- **Enhanced Error Handling**: Structured error handling with recovery suggestions
- **Advanced Logging**: Multi-format logging with rotation and context tracking
- **Configuration Management**: Hierarchical configuration with validation
- **Security Validation**: Script security scanning and threat detection
- **Performance Monitoring**: Execution time and resource usage tracking
- **Script Discovery**: Automatic script discovery with metadata extraction

### **Key Improvements**

#### **1. Enhanced Error Handling (`lib/error-handling.nu`)**

- Structured error types with recovery strategies
- Unique error IDs for tracking
- Context-aware error reporting
- Automatic error logging and statistics
- Recovery suggestions based on error type

```nushell
# Example usage
use lib/error-handling.nu *
handle_script_error "Command failed" "COMMAND_NOT_FOUND" { command: "nix" }
```

#### **2. Advanced Configuration Management (`lib/config.nu`)**

- Multi-source configuration loading (file, env, defaults)
- Configuration validation and schema checking
- Environment variable overrides
- Hierarchical configuration merging

```nushell
# Example usage
use lib/config.nu *
let config = load_config
show_config_summary $config
```

#### **3. Enhanced Logging (`lib/logging.nu`)**

- Multiple output formats (text, JSON, structured)
- Automatic log rotation
- Context-aware logging
- Performance and security event logging

```nushell
# Example usage
use lib/logging.nu *
setup_logging $config
info "Operation started" { operation: "install", user: (whoami) }
```

#### **4. Security Validation (`lib/security.nu`)**

- Dangerous pattern detection
- File permission validation
- Dependency security checking
- Network access monitoring
- Security threat classification

```nushell
# Example usage
use lib/security.nu *
let security_result = validate_script_security "scripts/install.nu"
if not $security_result.secure {
    warn "Security issues detected" { threats: $security_result.threats }
}
```

#### **5. Performance Monitoring (`lib/performance.nu`)**

- Execution time tracking
- Resource usage monitoring
- Performance threshold alerts
- Performance reporting and recommendations

```nushell
# Example usage
use lib/performance.nu *
let monitor_id = start_performance_monitor "installation"
# ... perform operation ...
let metrics = end_performance_monitor $monitor_id
```

#### **6. Script Discovery (`lib/discovery.nu`)**

- Automatic script discovery
- Metadata extraction
- Dependency analysis
- Documentation generation

```nushell
# Example usage
use lib/discovery.nu *
let scripts = discover_scripts
let core_scripts = get_scripts_by_category "core"
```

## Main Entrypoint

The primary entrypoint for automation is the bash wrapper script:

```bash
./scripts/common/nix-mox
```

### Usage

Run the script with:

```bash
./scripts/common/nix-mox --script install --dry-run
```

> **Note:** The wrapper script ensures robust argument passing for all Nushell versions and platforms. You no longer need to worry about double-dash (`--`) or Nushell quirks.

### Options

- `-h, --help`           Show help message
- `--dry-run`           Show what would be done without making changes
- `--debug`             Enable debug output
- `--platform <os>`     Specify platform (auto, linux, darwin, nixos)
- `--script <name>`     Run specific script (install, update, zfs-snapshot)
- `--log <file>`        Log output to file

### Platform & OS Info

- When running a script, nix-mox prints detailed OS info (distro, version, kernel) for Linux/NixOS, macOS, or Windows.
- NixOS is fully supported and detected as a Linux platform.

### Error Handling & Logging

- All error handling and logging is robust and platform-aware.
- Errors are clearly reported with recovery suggestions.
- Logs can be written to a file with `--log <file>`.
- Structured error tracking with unique error IDs.

## Directory Structure

### **Core Scripts (`core/`)**

- `setup.nu`            — Main setup script with component selection (`--help` available)
- `cleanup.nu`          — Core cleanup operations (`--help` available)
- `health-check.nu`     — System health diagnostics
- `integrate-modules.nu` — Module integration script
- `install.nu`          — Unified installation script
- `setup-cachix.nu`     — Cachix setup script
- `setup-remote-builder.sh` — Remote builder setup
- `test-remote-builder.sh` — Remote builder testing
- `test-ci-local.sh`    — Local CI testing
- `ci-test.sh`          — CI test script
- `summarize-tests.sh`  — Test summarization

### **Tools (`tools/`)**

- `cleanup.nu`          — Comprehensive project cleanup (`--help` available)
- `project-dashboard.nu` — Project dashboard and metrics
- `generate-docs.nu`    — Automatic documentation generation
- `analyze-sizes.nu`    — Repository size analysis
- `size-dashboard.nu`   — Size analysis dashboard
- `advanced-cache.nu`   — Advanced caching utilities
- `generate-coverage.nu` — Code coverage generation
- `analyze-sizes.sh`    — Shell-based size analysis (`--help` available)

### **Archived Scripts (`archive/`)**

The following scripts have been archived due to infrequent use or consolidation:

- `gaming-benchmark.nu` — Gaming performance benchmarking
- `validate-gaming-config.nu` — Gaming configuration validation
- `code-quality.nu`     — Code quality analysis and linting
- `pre-commit.nu`       — Pre-commit hooks and checks
- `validate-display-config.nu` — Display configuration validation
- `performance-optimize.nu` — Performance optimization and analysis
- `generate-sbom.nu`    — Software Bill of Materials generation
- `advanced-cache.nu`   — Advanced caching utilities (archived version)

> **Note**: Archived scripts are still functional but may not be actively maintained. Use the main tools for current functionality.

### **Platform Scripts**

- `linux/`              — Linux-specific implementations
- `macos/`              — macOS-specific implementations  
- `windows/`            — Windows-specific implementations

### **Libraries (`lib/`)**

- `common.nu`           — Common utilities and constants
- `error-handling.nu`   — Enhanced error handling system
- `config.nu`           — Configuration management
- `logging.nu`          — Advanced logging system
- `security.nu`         — Security validation
- `performance.nu`      — Performance monitoring
- `discovery.nu`        — Script discovery and metadata
- `argparse.nu`         — Argument parsing utilities
- `exec.nu`             — Execution helpers
- `platform.nu`         — Platform detection

### **Common Scripts (`common/`)**

- `nix-mox.nu`          — Main Nushell automation logic
- `nix-mox`             — Bash wrapper script
- `install-nix.sh`      — Nix installation script
- `nix-mox-uninstall.sh` — Uninstallation script

### **Legacy Scripts**

- `tests/`              — Test suite
- `handlers/`           — Script handlers

## Configuration

### **Default Configuration (`nix-mox.json`)**

```json
{
  "logging": {
    "level": "INFO",
    "file": "logs/nix-mox.log",
    "format": "text"
  },
  "security": {
    "validate_scripts": true,
    "check_permissions": true
  },
  "performance": {
    "enable_monitoring": true,
    "log_performance": true
  }
}
```

### **Configuration Sources (in order of precedence)**

1. `./nix-mox.json`
2. `./config/nix-mox.json`
3. `~/.config/nix-mox/config.json`
4. `/etc/nix-mox/config.json`
5. Environment variables (`NIXMOX_*`)

## Script Development

### **Using Enhanced Modules**

```nushell
#!/usr/bin/env nu

use lib/error-handling.nu *
use lib/config.nu *
use lib/logging.nu *
use lib/security.nu *

# Load configuration
let config = load_config
setup_logging $config

# Main script logic
try {
    info "Starting operation"
    # ... script logic ...
    info "Operation completed"
} catch { |err|
    handle_script_error $"Operation failed: ($err)" "EXECUTION_FAILED"
}
```

### **Best Practices**

1. **Use the enhanced libraries** for error handling, logging, and configuration
2. **Follow the modular structure** - place scripts in appropriate directories
3. **Include comprehensive error handling** with recovery suggestions
4. **Use structured logging** for better debugging and monitoring
5. **Validate configurations** before execution
6. **Include security validation** for sensitive operations

## Quick Reference

### **Core Operations**

```bash
# Setup
nu scripts/core/setup.nu

# Health check
nu scripts/core/health-check.nu

# Module integration
nu scripts/core/integrate-modules.nu
```

### **Gaming Operations**

```bash
# Gaming benchmark
nu scripts/gaming/gaming-benchmark.nu

# Validate gaming config
nu scripts/gaming/validate-gaming-config.nu
```

### **Development Operations**

```bash
# Code quality
nu scripts/development/code-quality.nu

# Pre-commit checks
nu scripts/development/pre-commit.nu
```

### **Validation Operations**

```bash
# Display validation
nu scripts/validation/validate-display-config.nu

# Performance optimization
nu scripts/validation/performance-optimize.nu
```

### **Tool Operations**

```bash
# Generate documentation
nu scripts/tools/generate-docs.nu --examples

# Analyze sizes
nu scripts/tools/analyze-sizes.nu

# Generate SBOM
nu scripts/tools/generate-sbom.nu
```

## Migration Guide

### **From Old Structure**

If you have scripts referencing the old structure, update them as follows:

| Old Path | New Path |
|----------|----------|
| `scripts/setup.nu` | `scripts/core/setup.nu` |
| `scripts/health-check.nu` | `scripts/core/health-check.nu` |
| `scripts/code-quality.nu` | `scripts/development/code-quality.nu` |
| `scripts/gaming-benchmark.nu` | `scripts/gaming/gaming-benchmark.nu` |
| `scripts/validate-display-config.nu` | `scripts/validation/validate-display-config.nu` |
| `scripts/analyze-sizes.nu` | `scripts/tools/analyze-sizes.nu` |

### **Makefile Updates**

The Makefile has been updated with the new paths. All targets now use the reorganized structure.

### **CI/CD Updates**

GitHub Actions and other CI/CD configurations have been updated to use the new script paths.

## Support

- **Documentation**: See `docs/` for detailed guides
- **Issues**: Report problems on GitHub
- **Scripts**: All scripts include help text and examples
