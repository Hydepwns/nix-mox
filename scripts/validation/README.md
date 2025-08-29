# Validation Scripts

This directory contains scripts for validating various configurations and setups, with a focus on preventing system issues after NixOS rebuilds.

## Core Validation Scripts

### Session Management & Reboot Safety
- **`nixos-config-validator.nu`** - Validates NixOS configuration for session management issues
- **`post-rebuild-validation.nu`** - Comprehensive post-rebuild system validation
- **`pre-rebuild-comprehensive-check.nu`** - Complete pre-rebuild safety validation

### System Testing
- **`../testing/system/reboot-diagnostics.nu`** - Diagnoses reboot/shutdown capability issues

### Legacy Validation
- **`validate-gaming-config.nu`** - Validates gaming configuration and provides recommendations for optimal gaming setup
- **`validate-display-config.nu`** - Validates display configurations and tests graphics capabilities
- **`pre-rebuild-safety-check.nu`** - Mandatory safety validation before system changes
- **`safe-flake-test.nu`** - Comprehensive flake testing with backup capabilities

## Storage Safety (Critical for Boot Reliability)

- **`nix run .#storage-guard`** - Validates storage configuration before reboot
- **`nix run .#fix-storage`** - Auto-fixes storage configuration issues

## Usage

### Rebuild Safety System (Recommended)

```bash
# Pre-rebuild validation (prevents session management issues)
make rebuild-check
# or directly:
nu scripts/validation/nixos-config-validator.nu

# Safe rebuild with comprehensive validation
make safe-rebuild

# Post-rebuild validation
nu scripts/validation/post-rebuild-validation.nu --verbose

# Diagnose reboot issues
nu scripts/testing/system/reboot-diagnostics.nu
```

### Legacy Validation

```bash
# Validate gaming configuration
nu scripts/validation/validate-gaming-config.nu

# Validate display configuration
nu scripts/validation/validate-display-config.nu

# Storage safety (CRITICAL)
nix run .#storage-guard
nix run .#fix-storage
```

## Features

### Session Management & Rebuild Safety
- **PolicyKit Configuration Validation** - Ensures GUI reboot/shutdown works
- **Service Restart Prevention** - Prevents systemd-logind/polkit restart during rebuilds
- **Session Management Module Integration** - Validates proper module imports
- **Post-Rebuild System Validation** - Comprehensive health checks after rebuilds
- **Reboot Capability Diagnostics** - Tests all reboot methods and identifies issues
- **Automatic Fix Suggestions** - Provides configuration fixes for common issues

### Pre-commit Integration
- **Configuration Validation** - Runs on every commit to prevent configuration issues
- **Syntax Validation** - Validates Nushell and Nix syntax
- **Security Scanning** - Prevents committing secrets and sensitive data
- **Function Naming Consistency** - Ensures consistent snake_case naming

### Legacy Features
- System requirements validation
- Graphics and audio configuration checks
- Performance benchmarking
- Hardware detection and compatibility
- Safety backups and rollback capabilities
- Storage configuration validation and auto-fixing

## Configuration Integration

To prevent session management issues, add this to your `configuration.nix`:

```nix
{
  # Import the session management module
  imports = [
    # ... other imports ...
    ../../modules/session-management.nix
  ];

  # Enable session management with safety features
  services.sessionManagement = {
    enable = true;
    ensureRebootCapability = true;
    preventServiceRestartIssues = true;
  };
}
``` 
