# Script Development Guide

## Overview

nix-mox provides a comprehensive scripting framework for system administration, development, and automation tasks. The framework is built around Nushell scripts with platform-specific implementations and a robust testing infrastructure.

## Script Structure

### Basic Script Template

```nushell
#!/usr/bin/env nu

use lib/common.nu *

export-env {
    $env.SCRIPT_NAME = "script-name"
    $env.SCRIPT_VERSION = "1.0.0"
    $env.LOGFILE = "/var/log/script-name.log"
}

def main [] {
    try {
        # Script implementation
        log_info "Starting script execution..."
        
        # Your logic here
        
        log_success "Script completed successfully"
    } catch {
        handle_error $"Script failed: ($env.LAST_ERROR)"
    }
}

main
```

### Advanced Script Template with Arguments

```nushell
#!/usr/bin/env nu

use lib/common.nu *

export-env {
    $env.SCRIPT_NAME = "advanced-script"
    $env.SCRIPT_VERSION = "1.0.0"
    $env.LOGFILE = "/var/log/advanced-script.log"
}

def usage [] {
    print "Usage: nu advanced-script.nu [--dry-run] [--help]"
    print ""
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
        log_info "Starting advanced script execution..." $env.LOGFILE
        
        if $env.DRY_RUN {
            log_dryrun "Dry-run mode enabled" $env.LOGFILE
        }
        
        # Your logic here
        
        log_success "Advanced script completed successfully" $env.LOGFILE
    } catch {
        handle_error $"Advanced script failed: ($env.LAST_ERROR)"
    }
}

main $in
```

## Available Package Scripts

nix-mox includes the following Nushell scripts (Linux only):

### System Management Scripts

#### Proxmox Update Script (`proxmox-update.nu`)
- **Purpose**: Updates Proxmox VE packages safely
- **Usage**: `nix run .#proxmox-update` or `sudo nu scripts/linux/proxmox-update.nu`
- **Features**:
  - Updates package lists and performs distribution upgrade
  - Removes unused packages
  - Runs Proxmox-specific updates (`pveupdate`, `pveupgrade`)
  - Supports dry-run mode
  - Comprehensive logging to `/var/log/proxmox-update.log`
  - Idempotent and safe to re-run

#### VZDump Backup Script (`vzdump-backup.nu`)
- **Purpose**: Creates backups of Proxmox VMs and containers
- **Usage**: `nix run .#vzdump-backup` or `sudo nu scripts/linux/vzdump-backup.nu`
- **Features**:
  - Automatically detects and backs up all VMs and containers
  - Uses snapshot mode with ZSTD compression
  - Configurable storage location
  - Comprehensive logging

#### ZFS Snapshot Script (`zfs-snapshot.nu`)
- **Purpose**: Manages ZFS snapshots with automatic pruning
- **Usage**: `nix run .#zfs-snapshot` or `sudo nu scripts/linux/zfs-snapshot.nu`
- **Features**:
  - Creates recursive snapshots for all pools
  - Automatic pruning based on retention policy
  - Configurable retention period (default: 7 days)
  - Timestamped snapshot names

#### NixOS Flake Update Script (`nixos-flake-update.nu`)
- **Purpose**: Updates NixOS flake inputs and rebuilds system
- **Usage**: `nix run .#nixos-flake-update` or `nu scripts/linux/nixos-flake-update.nu`
- **Features**:
  - Updates flake inputs
  - Rebuilds NixOS configuration
  - Supports dry-run mode
  - Comprehensive logging

### Installation Scripts

#### Install Script (`install.nu`)
- **Purpose**: Installs nix-mox and its dependencies
- **Usage**: `nix run .#install` or `nu scripts/linux/install.nu`
- **Features**:
  - Platform detection and validation
  - Dependency installation
  - Configuration setup
  - Post-installation verification

#### Uninstall Script (`uninstall.nu`)
- **Purpose**: Removes nix-mox and cleans up
- **Usage**: `nix run .#uninstall` or `nu scripts/linux/uninstall.nu`
- **Features**:
  - Safe removal of nix-mox components
  - Configuration cleanup
  - Dependency cleanup (optional)

## Core Utilities

### Error Handling

```nushell
def handle_error [error_msg: string, exit_code: int = 1] {
    log_error $error_msg
    if ($env.LOG_FILE? | is-not-empty) {
        log_error "Check log file: ($env.LOG_FILE)"
    }
    exit $exit_code
}
```

### Logging Functions

```nushell
def log_info [message: string, logfile: string] {
    let timestamp = (date now | format date '%Y-%m-%d %H:%M:%S')
    let log_message = $"($timestamp) [INFO] ($message)"
    print $log_message
    try {
        $log_message | save --append $logfile
    } catch {
        print $"Failed to write to log file ($logfile)"
    }
}

def log_error [message: string, logfile: string] {
    let timestamp = (date now | format date '%Y-%m-%d %H:%M:%S')
    let log_message = $"($timestamp) [ERROR] ($message)"
    print $log_message
    try {
        $log_message | save --append $logfile
    } catch {
        print $"Failed to write to log file ($logfile)"
    }
}

def log_success [message: string, logfile: string] {
    let timestamp = (date now | format date '%Y-%m-%d %H:%M:%S')
    let log_message = $"($timestamp) [SUCCESS] ($message)"
    print $log_message
    try {
        $log_message | save --append $logfile
    } catch {
        print $"Failed to write to log file ($logfile)"
    }
}

def log_dryrun [message: string, logfile: string] {
    let timestamp = (date now | format date '%Y-%m-%d %H:%M:%S')
    let log_message = $"($timestamp) [DRYRUN] ($message)"
    print $log_message
    try {
        $log_message | save --append $logfile
    } catch {
        print $"Failed to write to log file ($logfile)"
    }
}
```

### System Utilities

```nushell
def check_root [] {
    if (whoami | str trim) == 'root' {
        "Running as root."
    } else {
        print $"ERROR: This script must be run as root."
        exit 1
    }
}

def check_command [cmd: string] {
    if not ((which $cmd | length | into int) > 0) {
        log_error $"Required command '($cmd)' not found." $env.LOGFILE
        exit 1
    }
}

def append-to-log [logfile: string] {
    try {
        $in | save --append $logfile
    } catch {
        print $"Failed to append to log file ($logfile)"
    }
}
```

### Platform Detection

```nushell
def detect_platform [] {
    let os = (sys | get host.name)
    match $os {
        "Linux" => "linux",
        "Darwin" => "darwin",
        "Windows" => "windows",
        _ => {
            log_error $"Unsupported OS: ($os)"
            exit 1
        }
    }
}
```

## Script Organization

```
scripts/
├── linux/                    # Linux-specific scripts
│   ├── proxmox-update.nu     # Proxmox update script
│   ├── vzdump-backup.nu      # Backup script
│   ├── zfs-snapshot.nu       # ZFS management script
│   ├── nixos-flake-update.nu # NixOS flake update
│   ├── install.nu            # Installation script
│   ├── uninstall.nu          # Uninstallation script
│   ├── common.nu             # Linux common utilities
│   └── _common.sh            # Shell common utilities
├── windows/                  # Windows-specific scripts (future)
├── common/                   # Cross-platform utilities
├── handlers/                 # Event handlers
├── lib/                      # Library modules
└── tests/                    # Test suite
    ├── unit/                 # Unit tests
    ├── integration/          # Integration tests
    ├── lib/                  # Test utilities
    └── run-tests.nu          # Test runner
```

## Running Scripts

### Using Nix Flake (Recommended)

```bash
# Run packaged scripts
nix run .#proxmox-update
nix run .#vzdump-backup
nix run .#zfs-snapshot
nix run .#nixos-flake-update
nix run .#install
nix run .#uninstall
```

### Using Nushell Directly

```bash
# Enter development shell
nix develop

# Run scripts directly
sudo nu scripts/linux/proxmox-update.nu
sudo nu scripts/linux/vzdump-backup.nu
sudo nu scripts/linux/zfs-snapshot.nu
nu scripts/linux/nixos-flake-update.nu
nu scripts/linux/install.nu
nu scripts/linux/uninstall.nu
```

### Using Make

```bash
# Build all packages
make build-all

# Run tests
make test
make unit
make integration
```

## Best Practices

### 1. Error Handling
- Use try-catch blocks for all operations
- Provide clear, actionable error messages
- Log errors to file with timestamps
- Use appropriate exit codes
- Implement proper cleanup on failure

### 2. Logging
- Use consistent log levels (INFO, ERROR, SUCCESS, DRYRUN)
- Include timestamps in all log entries
- Log to file for important operations
- Enable debug mode when needed
- Use structured logging for complex operations

### 3. Testing
- Write unit tests for all functions
- Include integration tests for end-to-end workflows
- Test platform-specific code thoroughly
- Use test fixtures and mock data
- Maintain high test coverage (>90%)

### 4. Code Organization
- Keep functions focused and single-purpose
- Use clear, descriptive names
- Include comprehensive documentation
- Follow consistent style and formatting
- Guard platform-specific code appropriately

### 5. Security
- Always check for root privileges when needed
- Validate all inputs and arguments
- Use secure file permissions
- Avoid hardcoded credentials
- Implement proper error handling

### 6. Performance
- Use efficient data structures
- Minimize external command calls
- Implement proper cleanup
- Use streaming operations for large datasets
- Profile and optimize critical paths

## Debugging

### Debug Mode

```nushell
# Enable debug mode
$env.DEBUG = true

# Or use debug flag
nix run .#script-name -- --debug
```

### Script Logging

```nushell
# Set custom log file
$env.LOGFILE = "custom-script.log"

# Or use log flag
nix run .#script-name -- --log custom-script.log
```

### Debug Techniques

1. **Print Variables**: `print $"Value: ($variable)"`
2. **Check Command Output**: `let output = (command | str trim)`
3. **Validate Data**: `print ($data | to json)`
4. **Step-by-step Execution**: Add debug prints at key points
5. **Error Tracing**: Use `try-catch` with detailed error reporting

### Common Debugging Patterns

```nushell
# Debug function execution
def debug_function [func_name: string, args: any] {
    if $env.DEBUG {
        print $"DEBUG: Calling ($func_name) with args: ($args | to json)"
    }
    # Function implementation
}

# Debug data flow
def debug_data [stage: string, data: any] {
    if $env.DEBUG {
        print $"DEBUG: ($stage) - ($data | to json)"
    }
}
```

## Testing

### Running Tests

```bash
# Run all tests
make test

# Run specific test types
make unit          # Unit tests only
make integration   # Integration tests only

# Run tests directly
nix develop .#testing
nu -c "source scripts/tests/run-tests.nu; run []"
```

### Writing Tests

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

## Continuous Integration

### GitHub Actions

The project includes comprehensive CI/CD with:
- Automated testing on multiple platforms
- Coverage reporting
- Quality checks
- Automated builds

### Local Development

```bash
# Pre-commit checks
make test
make format
make check

# Build verification
make build-all
```

## Future Enhancements

### Planned Features
- Windows script support
- macOS script optimizations
- Additional gaming scripts
- Enhanced monitoring capabilities
- Cloud integration scripts
- Automated backup verification
- Performance benchmarking tools

### Contributing
- Follow the established patterns
- Add comprehensive tests
- Update documentation
- Ensure cross-platform compatibility
- Maintain backward compatibility
