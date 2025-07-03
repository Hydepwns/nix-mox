# Nushell Implementation Guide

Comprehensive guide for nix-mox's Nushell automation scripts and development patterns.

## Overview

nix-mox uses Nushell as its primary scripting language for system automation, providing:

- Type safety and validation
- Platform detection and compatibility
- Structured logging and error handling
- Process management and monitoring
- Comprehensive testing infrastructure

## Available Scripts

### System Management Scripts (Linux Only)

#### Proxmox Update Script (`proxmox-update.nu`)

```bash
# Usage
nix run .#proxmox-update
sudo nu scripts/linux/proxmox-update.nu [--dry-run] [--help]

# Features
- Updates Proxmox VE packages safely
- Supports dry-run mode for testing
- Comprehensive logging to /var/log/proxmox-update.log
- Idempotent operations
```

#### VZDump Backup Script (`vzdump-backup.nu`)

```bash
# Usage
nix run .#vzdump-backup
sudo nu scripts/linux/vzdump-backup.nu

# Features
- Automatically backs up all VMs and containers
- Uses snapshot mode with ZSTD compression
- Configurable storage location
- Comprehensive logging
```

#### ZFS Snapshot Script (`zfs-snapshot.nu`)

```bash
# Usage
nix run .#zfs-snapshot
sudo nu scripts/linux/zfs-snapshot.nu

# Features
- Creates recursive snapshots for all pools
- Automatic pruning based on retention policy
- Configurable retention period (default: 7 days)
- Timestamped snapshot names
```

#### NixOS Flake Update Script (`nixos-flake-update.nu`)

```bash
# Usage
nix run .#nixos-flake-update
nu scripts/linux/nixos-flake-update.nu [--dry-run]

# Features
- Updates flake inputs
- Rebuilds NixOS configuration
- Supports dry-run mode
- Comprehensive logging
```

### Installation Scripts

#### Install Script (`install.nu`)

```bash
# Usage
nix run .#install
nu scripts/linux/install.nu

# Features
- Platform detection and validation
- Dependency installation
- Configuration setup
- Post-installation verification
```

#### Uninstall Script (`uninstall.nu`)

```bash
# Usage
nix run .#uninstall
nu scripts/linux/uninstall.nu

# Features
- Safe removal of nix-mox components
- Configuration cleanup
- Dependency cleanup (optional)
```

## Script Architecture

### Common Module (`lib/common.nu`)

```nushell
# Core utilities shared across all scripts
def log_info [message: string, logfile: string]
def log_error [message: string, logfile: string]
def log_success [message: string, logfile: string]
def log_dryrun [message: string, logfile: string]

def check_root []
def check_command [cmd: string]
def append-to-log [logfile: string]

def handle_error [error_msg: string, exit_code: int = 1]
```

### Script Structure Pattern

```nushell
#!/usr/bin/env nu

# Script metadata and environment setup
export-env {
    $env.SCRIPT_NAME = "script-name"
    $env.SCRIPT_VERSION = "1.0.0"
    $env.LOGFILE = "/var/log/script-name.log"
}

# Argument parsing and validation
def usage [] {
    print "Usage: nu script-name.nu [options]"
    print "Options:"
    print "  --dry-run    Show what would be done, but make no changes"
    print "  --help, -h   Show this help message"
    exit 0
}

def main [args: list] {
    # Parse arguments
    for arg in $args {
        match $arg {
            "--dry-run" => { $env.DRY_RUN = true }
            "--help" | "-h" => { usage }
            _ => {
                log_error $"Unknown option: ($arg)" $env.LOGFILE
                usage
            }
        }
    }

    try {
        # Script implementation
        log_info "Starting script execution..." $env.LOGFILE
        
        # Core logic here
        
        log_success "Script completed successfully" $env.LOGFILE
    } catch {
        handle_error $"Script failed: ($env.LAST_ERROR)"
    }
}

# Execute with arguments
main $in
```

## Development Patterns

### Error Handling

```nushell
# Comprehensive error handling pattern
def safe_operation [operation: string] {
    try {
        log_info $"Starting ($operation)..." $env.LOGFILE
        
        # Operation implementation
        let result = (perform_operation)
        
        log_success $"($operation) completed successfully" $env.LOGFILE
        $result
    } catch {
        log_error $"($operation) failed: ($env.LAST_ERROR)" $env.LOGFILE
        throw $env.LAST_ERROR
    }
}
```

### Command Validation

```nushell
# Validate required commands before execution
def validate_dependencies [commands: list] {
    for cmd in $commands {
        if not ((which $cmd | length | into int) > 0) {
            log_error $"Required command '($cmd)' not found." $env.LOGFILE
            exit 1
        }
    }
    log_info "All required commands are available" $env.LOGFILE
}
```

### Data Processing

```nushell
# Process command output safely
def process_output [command: string] {
    try {
        let output = (do { nu -c $command } | complete | get stdout | str trim)
        if ($output | is-empty) {
            log_error "Command produced no output" $env.LOGFILE
            return []
        }
        $output | lines
    } catch {
        log_error $"Failed to execute command: ($command)" $env.LOGFILE
        return []
    }
}
```

### Configuration Management

```nushell
# Load and validate configuration
def load_config [config_path: string] {
    try {
        if not ($config_path | path exists) {
            log_error $"Configuration file not found: ($config_path)" $env.LOGFILE
            exit 1
        }
        
        let config = (open $config_path | from json)
        
        # Validate required fields
        if not ($config | get required_field? | is-not-empty) {
            log_error "Missing required configuration field" $env.LOGFILE
            exit 1
        }
        
        $config
    } catch {
        log_error $"Failed to load configuration: ($env.LAST_ERROR)" $env.LOGFILE
        exit 1
    }
}
```

## Testing Framework

### Test Structure

```nushell
#!/usr/bin/env nu

use ../lib/test-utils.nu *
use ../lib/test-coverage.nu *

def main [] {
    setup_test_env
    
    try {
        # Test implementation
        let result = (test_function "input")
        assert_equal $result "expected" "Test description"
        
        track_test "test_name" "unit" "passed" 0.1
        cleanup_test_env
    } catch {
        track_test "test_name" "unit" "failed" 0.1
        cleanup_test_env
        throw $env.LAST_ERROR
    }
}

main
```

### Test Utilities

```nushell
# Environment management
setup_test_env
cleanup_test_env

# Assertions
assert_equal $expected $actual "Message"
assert_true $condition "Message"
assert_false $condition "Message"

# Test tracking
track_test "test_name" "category" "status" $duration

# Coverage reporting
generate_coverage_report
export_coverage_report "json"
```

## Usage Examples

### Basic Script Execution

```bash
# Using Nix flake (recommended)
nix run .#proxmox-update
nix run .#vzdump-backup
nix run .#zfs-snapshot

# Using Nushell directly
sudo nu scripts/linux/proxmox-update.nu
sudo nu scripts/linux/vzdump-backup.nu
sudo nu scripts/linux/zfs-snapshot.nu
```

### Advanced Usage

```bash
# Dry-run mode
sudo nu scripts/linux/proxmox-update.nu --dry-run

# With custom logging
$env.LOGFILE = "/tmp/custom.log"
sudo nu scripts/linux/proxmox-update.nu

# Debug mode
$env.DEBUG = true
sudo nu scripts/linux/proxmox-update.nu
```

### Development Workflow

```bash
# Enter development shell
nix develop

# Run tests
make test
make unit
make integration

# Build packages
make build-all

# Format code
make format
```

## Best Practices

### 1. Script Organization

- Use consistent naming conventions
- Group related functionality
- Separate concerns (logging, validation, execution)
- Follow the established template pattern

### 2. Error Handling

- Always use try-catch blocks
- Provide meaningful error messages
- Log errors with context
- Implement proper cleanup

### 3. Logging

- Use consistent log levels
- Include timestamps
- Log to file for important operations
- Enable debug mode when needed

### 4. Testing

- Write unit tests for all functions
- Include integration tests
- Test error conditions
- Maintain high coverage

### 5. Security

- Validate all inputs
- Check permissions when needed
- Use secure file operations
- Avoid hardcoded credentials

## Dependencies

### Required Tools

- Nushell 0.80.0+
- Platform-specific tools (apt, zfs, vzdump, etc.)
- Nix package manager

### Development Tools

- nixpkgs-fmt for formatting
- shellcheck for shell script validation
- Test utilities for coverage reporting

## Development Guidelines

### Code Style

- Follow Nushell conventions
- Use descriptive variable names
- Include comprehensive comments
- Maintain consistent formatting

### Documentation

- Document all public functions
- Include usage examples
- Update README files
- Maintain changelog

### Testing

- Write tests for new features
- Ensure backward compatibility
- Test on multiple platforms
- Validate error conditions

### Performance

- Use efficient data structures
- Minimize external calls
- Implement proper cleanup
- Profile critical paths

## Future Enhancements

### Planned Features

- Windows script support
- macOS optimizations
- Enhanced monitoring
- Cloud integration
- Automated verification
- Performance benchmarking

### Contributing

- Follow established patterns
- Add comprehensive tests
- Update documentation
- Ensure cross-platform compatibility
- Maintain backward compatibility
