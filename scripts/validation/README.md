# Validation Scripts

This directory contains scripts for validating various configurations and setups.

## Scripts

- **`validate-gaming-config.nu`** - Validates gaming configuration and provides recommendations for optimal gaming setup
- **`validate-display-config.nu`** - Validates display configurations and tests graphics capabilities
- **`pre-rebuild-safety-check.nu`** - Mandatory safety validation before system changes
- **`safe-flake-test.nu`** - Comprehensive flake testing with backup capabilities

## Storage Safety (Critical for Boot Reliability)

- **`nix run .#storage-guard`** - Validates storage configuration before reboot
- **`nix run .#fix-storage`** - Auto-fixes storage configuration issues

## Usage

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

- System requirements validation
- Graphics and audio configuration checks
- Performance benchmarking
- Hardware detection and compatibility
- Safety backups and rollback capabilities
- Comprehensive validation reports
- Storage configuration validation and auto-fixing 
