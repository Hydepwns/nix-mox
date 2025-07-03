# Script Architecture

Comprehensive overview of nix-mox's modular script architecture for platform-specific functionality and system automation.

## Architecture Overview

nix-mox implements a modular, platform-aware scripting framework that provides:

- Platform-specific script implementations
- Shared utilities and common functions
- Comprehensive testing infrastructure
- Nix package integration
- Cross-platform compatibility

## Core Components

### Main Script Entry Points

Each script follows a consistent pattern with proper error handling, logging, and argument parsing:

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

### Common Utilities (`scripts/linux/common.nu`)

Shared utilities used across all Linux scripts:

```nushell
# Logging functions
def log_info [message: string, logfile: string]
def log_error [message: string, logfile: string]
def log_success [message: string, logfile: string]
def log_dryrun [message: string, logfile: string]

# System utilities
def check_root []
def check_command [cmd: string]
def append-to-log [logfile: string]

# Error handling
def handle_error [error_msg: string, exit_code: int = 1]
```

## Script Categories

### System Management Scripts

#### Proxmox Update Script (`proxmox-update.nu`)

- **Purpose**: Safely updates Proxmox VE packages
- **Platform**: Linux only
- **Privileges**: Requires root access
- **Features**:
  - Updates package lists (`apt update`)
  - Performs distribution upgrade (`apt dist-upgrade`)
  - Removes unused packages (`apt autoremove`)
  - Runs Proxmox-specific updates (`pveupdate`, `pveupgrade`)
  - Supports dry-run mode
  - Comprehensive logging

#### VZDump Backup Script (`vzdump-backup.nu`)

- **Purpose**: Creates backups of Proxmox VMs and containers
- **Platform**: Linux only
- **Privileges**: Requires root access
- **Features**:
  - Automatically detects all VMs and containers
  - Uses snapshot mode with ZSTD compression
  - Configurable storage location
  - Comprehensive logging and error handling

#### ZFS Snapshot Script (`zfs-snapshot.nu`)

- **Purpose**: Manages ZFS snapshots with automatic pruning
- **Platform**: Linux only
- **Privileges**: Requires root access
- **Features**:
  - Creates recursive snapshots for all pools
  - Automatic pruning based on retention policy
  - Configurable retention period (default: 7 days)
  - Timestamped snapshot names

#### NixOS Flake Update Script (`nixos-flake-update.nu`)

- **Purpose**: Updates NixOS flake inputs and rebuilds system
- **Platform**: Linux only
- **Privileges**: User-level access
- **Features**:
  - Updates flake inputs
  - Rebuilds NixOS configuration
  - Supports dry-run mode
  - Comprehensive logging

### Installation Scripts

#### Install Script (`install.nu`)

- **Purpose**: Installs nix-mox and its dependencies
- **Platform**: Linux only
- **Privileges**: User-level access
- **Features**:
  - Platform detection and validation
  - Dependency installation
  - Configuration setup
  - Post-installation verification

#### Uninstall Script (`uninstall.nu`)

- **Purpose**: Removes nix-mox and cleans up
- **Platform**: Linux only
- **Privileges**: User-level access
- **Features**:
  - Safe removal of nix-mox components
  - Configuration cleanup
  - Dependency cleanup (optional)

## Script Organization

```bash
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

## Platform Support

### Linux Support

All current scripts are designed for Linux systems with specific focus on:

- Proxmox VE environments
- ZFS storage systems
- NixOS configurations
- System administration tasks

### Future Platform Support

#### Windows Support

- Planned gaming scripts
- Steam/Rust update automation
- Performance optimization tools
- Wine configuration scripts

#### macOS Support

- System administration scripts
- Development environment setup
- Performance optimization
- Backup automation

## Error Handling Architecture

### Error Types

1. **Command Errors**
   - Missing dependencies
   - Permission issues
   - Command execution failures

2. **Platform Errors**
   - Unsupported platforms
   - Missing platform-specific tools
   - Incompatible configurations

3. **File System Errors**
   - Missing files or directories
   - Permission issues
   - Disk space problems

4. **Network Errors**
   - Connection failures
   - Timeout issues
   - DNS resolution problems

### Error Recovery

```nushell
def handle_error [error_msg: string, exit_code: int = 1] {
    log_error $error_msg
    if ($env.LOG_FILE? | is-not-empty) {
        log_error "Check the log file for more details: ($env.LOG_FILE)"
    }
    exit $exit_code
}

def safe_operation [operation: string, fallback: closure] {
    try {
        # Primary operation
        perform_operation
    } catch {
        log_error $"Primary operation failed: ($env.LAST_ERROR)"
        try {
            # Fallback operation
            do $fallback
        } catch {
            handle_error $"Both primary and fallback operations failed"
        }
    }
}
```

## Logging System

### Log Levels

- **INFO**: General information, progress updates
- **ERROR**: Error conditions, failures
- **SUCCESS**: Completion messages
- **DRYRUN**: Dry-run mode operations

### Logging Implementation

```nushell
def log_to_file [message: string, log_file: string] {
    try {
        $message | save --append $log_file
    } catch {
        print $"Failed to write to log file ($log_file): ($env.LAST_ERROR)"
        print $message
    }
}

def setup_logging [log_file: string] {
    try {
        # Create log directory if it doesn't exist
        let log_dir = ($log_file | path dirname)
        if not ($log_dir | path exists) {
            mkdir $log_dir
        }
        touch $log_file
    } catch {
        print $"Warning: Could not create log file ($log_file). Continuing without logging."
        $env.LOGFILE = "/tmp/fallback.log"
    }
}
```

## Script Execution Flow

### Standard Execution Pattern

1. **Argument Parsing**
   - Parse command-line arguments
   - Validate options
   - Set environment variables

2. **Environment Setup**
   - Initialize logging
   - Set up error handling
   - Configure script behavior

3. **Dependency Validation**
   - Check required commands
   - Validate permissions
   - Verify platform compatibility

4. **Script Execution**
   - Perform main operations
   - Handle errors gracefully
   - Log all activities

5. **Cleanup and Reporting**
   - Clean up temporary files
   - Generate reports
   - Exit with appropriate code

### Example Execution Flow

```nushell
def main [args: list] {
    # 1. Parse arguments
    let config = (parse_arguments $args)
    
    # 2. Setup environment
    setup_logging $config.log_file
    setup_error_handling
    
    # 3. Validate dependencies
    validate_dependencies $config.required_commands
    
    # 4. Execute script
    try {
        log_info "Starting script execution..." $config.log_file
        
        # Core operations
        perform_operations $config
        
        log_success "Script completed successfully" $config.log_file
    } catch {
        handle_error $"Script execution failed: ($env.LAST_ERROR)"
    }
}
```

## Testing Architecture

### Test Categories

1. **Unit Tests**
   - Individual function testing
   - Isolated component validation
   - Fast execution

2. **Integration Tests**
   - End-to-end workflow testing
   - Platform-specific validation
   - Real environment testing

3. **Performance Tests**
   - Execution time measurement
   - Resource usage monitoring
   - Scalability testing

### Test Organization

```bash
scripts/tests/
├── unit/           # Unit tests
├── integration/    # Integration tests
├── lib/           # Test utilities
│   ├── test-utils.nu    # Core test utilities
│   ├── test-coverage.nu # Coverage reporting
│   ├── coverage-core.nu # Coverage tracking
│   ├── shared.nu        # Shared test functions
│   └── test-common.nu   # Common test functions
└── run-tests.nu   # Main test runner
```

## Nix Integration

### Package Definitions

Each script is packaged as a Nix package in `flake.nix`:

```nix
packages = if pkgs.stdenv.isLinux then {
  proxmox-update = linuxPackages.proxmox-update;
  vzdump-backup = linuxPackages.vzdump-backup;
  zfs-snapshot = linuxPackages.zfs-snapshot;
  nixos-flake-update = linuxPackages.nixos-flake-update;
  install = linuxPackages.install;
  uninstall = linuxPackages.uninstall;
  default = linuxPackages.proxmox-update;
} else {};
```

### Usage Patterns

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

## Future Enhancements

### Planned Features

1. **Cross-Platform Support**
   - Windows script implementations
   - macOS optimizations
   - Platform-agnostic utilities

2. **Enhanced Monitoring**
   - Real-time monitoring scripts
   - Performance metrics collection
   - Alerting and notification systems

3. **Cloud Integration**
   - AWS/Azure/GCP automation
   - Cloud backup solutions
   - Infrastructure management

4. **Advanced Automation**
   - Scheduled task management
   - Event-driven scripting
   - Workflow orchestration

### Development Roadmap

1. **Short Term**
   - Complete Windows script support
   - Enhanced error handling
   - Performance optimizations

2. **Medium Term**
   - Cloud integration scripts
   - Advanced monitoring capabilities
   - Automated testing improvements

3. **Long Term**
   - AI-powered automation
   - Predictive maintenance
   - Self-healing systems

## Contributing Guidelines

### Development Standards

1. **Code Quality**
   - Follow established patterns
   - Maintain consistent style
   - Include comprehensive tests
   - Document all functions

2. **Testing Requirements**
   - Unit tests for all functions
   - Integration tests for workflows
   - Platform-specific testing
   - Performance benchmarking

3. **Documentation**
   - Update relevant documentation
   - Include usage examples
   - Maintain changelog
   - Provide migration guides

4. **Compatibility**
   - Ensure backward compatibility
   - Test on multiple platforms
   - Validate error conditions
   - Handle edge cases
