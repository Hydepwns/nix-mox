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
./nix-mox
```

### Usage

Run the script with:

```bash
./nix-mox --script install --dry-run
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

- `install.nu`          — Unified installation script with component selection
- `update.nu`           — System update script
- `uninstall.nu`        — Clean removal script
- `validate.nu`         — Configuration validation

### **Platform Scripts (`platform/`)**

- `linux/`              — Linux-specific implementations
- `darwin/`             — macOS-specific implementations  
- `windows/`            — Windows-specific implementations

### **Tools (`tools/`)**

- `health-check.nu`     — Enhanced system health diagnostics
- `setup-wizard.nu`     — Interactive configuration wizard
- `generate-docs.nu`    — Automatic documentation generation
- `security-scan.nu`    — Security validation and reporting
- `performance-report.nu` — Performance analysis and recommendations

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

### **Legacy Scripts**

- `nix-mox`             — Main automation entrypoint (bash wrapper)
- `nix-mox.nu`          — Nushell automation logic
- `setup-wizard.nu`     — Interactive configuration wizard
- `health-check.nu`     — System health diagnostics
- `common/`             — Shared script utilities
- `linux/`              — Linux-specific scripts (install, update, zfs, etc.)
- `windows/`            — Windows-specific scripts
- `handlers/`           — Script handlers
- `tests/`              — Test suite

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

- Use the enhanced error handling for all error conditions
- Implement structured logging with context
- Validate configuration before use
- Perform security validation for critical operations
- Monitor performance for long-running operations
- Include comprehensive metadata in script headers

### **Script Metadata**

```nushell
export const SCRIPT_METADATA = {
    name: "script-name"
    description: "What this script does"
    platform: "all"  # or "linux", "darwin", "windows"
    requires_root: false
    category: "core"  # or "tools", "development", etc.
}
```

## Testing

### **Running Tests**

```bash
# Run all tests
./scripts/tests/run-tests.nu

# Run specific test categories
./scripts/tests/run-tests.nu --category unit
./scripts/tests/run-tests.nu --category integration

# Run with coverage
./scripts/tests/run-tests.nu --coverage
```

### **Test Structure**

- `tests/unit/` — Unit tests for individual functions
- `tests/integration/` — Integration tests for script workflows
- `tests/lib/` — Test utilities and helpers

## Troubleshooting

### **Common Issues**

#### **Error Handling**

- If you see structured error messages, follow the recovery suggestions
- Check error logs for detailed context
- Use error IDs for support requests

#### **Configuration Issues**

- Validate configuration with `validate.nu`
- Check configuration file syntax
- Verify environment variable overrides

#### **Security Validation**

- Review security warnings and recommendations
- Address critical and high-priority threats
- Use `--strict-security` for maximum security

#### **Performance Issues**

- Monitor script execution times
- Check resource usage patterns
- Review performance recommendations

### **Debug Mode**

```bash
# Enable debug logging
export NIXMOX_LOG_LEVEL=DEBUG
./nix-mox --script install

# Or use the debug flag
./nix-mox --script install --debug
```

### **Log Analysis**

```bash
# View recent logs
tail -f logs/nix-mox.log

# Analyze error patterns
./scripts/tools/analyze-logs.nu

# Generate performance report
./scripts/tools/performance-report.nu
```

## Example Invocations

```bash
# Install with enhanced features
./nix-mox --script install --core --tools --verbose

# Run health check with detailed reporting
./nix-mox --script health-check --check all --format json

# Generate documentation
./scripts/tools/generate-docs.nu --examples

# Security scan
./scripts/tools/security-scan.nu --strict

# Performance analysis
./scripts/tools/performance-report.nu

# Or use Makefile targets
make setup-wizard
make health-check
make generate-docs
```

## Benefits

### **For New Users**

- **Simplified Onboarding:** Interactive wizard guides through setup
- **Reduced Errors:** Enhanced error handling with recovery suggestions
- **Better Understanding:** Clear explanations and structured logging
- **Faster Setup:** Streamlined process with sensible defaults

### **For Existing Users**

- **System Validation:** Comprehensive health check with detailed reporting
- **Easy Troubleshooting:** Structured error handling and logging
- **Better Organization:** Modular script architecture
- **Enhanced Security:** Built-in security validation and threat detection

### **For Developers**

- **Consistent Interface:** Unified script architecture
- **Better Testing:** Comprehensive test suite with coverage
- **Modular Design:** Reusable components and libraries
- **Clear Documentation:** Auto-generated documentation with examples

### **For System Administrators**

- **Security Focus:** Built-in security validation and monitoring
- **Performance Insights:** Execution time and resource usage tracking
- **Audit Trail:** Comprehensive logging and error tracking
- **Configuration Management:** Hierarchical configuration with validation
