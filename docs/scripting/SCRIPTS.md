# Script Architecture

Overview of nix-mox's modular script architecture for platform-specific functionality.

## Core Components

### Main Script (`nix-mox.nu`)

```nushell
#!/usr/bin/env nu

use lib/common.nu *

def main [args: list] {
    try {
        let parsed_args = (parse_args $args)
        # Script execution logic
    } catch {
        handle_error $"Unexpected error: ($env.LAST_ERROR)"
    }
}
```

### Common Utilities (`lib/common.nu`)

```nushell
# Error handling
def handle_error [error_msg: string, exit_code: int = 1]

# Logging
def log_info [message: string]
def log_error [message: string]
def log_success [message: string]

# Platform detection
def detect_platform []

# Command validation
def check_command [cmd: string]
```

## Script Types

### Installation Scripts

```nushell
# Linux/macOS installation
def linux_install [] {
    check_command "nix-channel"
    check_command "nix-env"
    # Installation logic
}

# Windows installation
def windows_install [] {
    check_command "steam"
    # Installation logic
}
```

### Update Scripts

```nushell
# Nix package updates
def update_nix_packages [] {
    nix-channel --update
    nix-env -u '*'
}

# Steam/Rust updates
def update_steam_rust [] {
    # Update logic
}
```

### ZFS Scripts

```nushell
# Create snapshots
def create_snapshots [] {
    check_command "zfs"
    # Snapshot logic
}

# List snapshots
def list_snapshots [] {
    # Listing logic
}
```

## Gaming Scripts

```nushell
# Steam/Rust updates
def update_steam_rust [] {
    # Update logic
}

# Game performance optimization
def optimize_game_performance [] {
    # Optimization logic
}

# Wine and League of Legends setup
def configure_wine [] {
    # General Wine gaming configuration
    # Sets up a Wine prefix with optimal settings for gaming
}

def configure_league [] {
    # League of Legends-specific Wine prefix setup
    # Creates a dedicated Wine prefix for League of Legends with all required components
}
```

## Error Handling

### Error Types

- Command Errors (missing dependencies, permissions)
- Platform Errors (unsupported platforms, tools)
- File System Errors (missing files, permissions)

### Error Recovery

```nushell
def handle_error [error_msg: string, exit_code: int = 1] {
    log_error $error_msg
    if ($env.LOG_FILE? | is-not-empty) {
        log_error "Check the log file for more details: ($env.LOG_FILE)"
    }
    exit $exit_code
}
```

## Logging System

### Log Levels

- INFO: General information, progress
- ERROR: Error conditions, failures
- SUCCESS: Completion messages

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
```

## Platform Support

### Linux/macOS Support

```nushell
def linux_setup [] {
    check_command "nix-channel"
    check_command "nix-env"
    try {
        # Implementation
    } catch {
        handle_error $"Linux setup failed: ($env.LAST_ERROR)"
    }
}
```

### Windows Support

```nushell
def windows_setup [] {
    check_command "steam"
    try {
        # Implementation
    } catch {
        handle_error $"Windows setup failed: ($env.LAST_ERROR)"
    }
}
```

## Script Execution Flow

1. Argument Parsing
2. Platform Detection
3. Script Selection
4. Execution

For detailed implementation, see the source code in `scripts/`.
