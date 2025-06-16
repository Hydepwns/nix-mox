# Script Development Guide

## Script Structure

```nushell
#!/usr/bin/env nu

use lib/common.nu *

export-env {
    $env.SCRIPT_NAME = "script-name"
    $env.SCRIPT_VERSION = "1.0.0"
}

def main [] {
    try {
        # Script implementation
    } catch {
        handle_error $"Script failed: ($env.LAST_ERROR)"
    }
}

main
```

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

### Logging

```nushell
def log_info [message: string] {
    let timestamp = (date now | format date '%Y-%m-%d %H:%M:%S')
    print $"[INFO] ($timestamp) ($message)"
}

def log_error [message: string] {
    let timestamp = (date now | format date '%Y-%m-%d %H:%M:%S')
    print $"[ERROR] ($timestamp) ($message)"
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

## Platform Support

### Linux/macOS

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

### Windows

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

## Best Practices

1. Error Handling
   - Use try-catch blocks
   - Provide clear error messages
   - Log errors to file
   - Use appropriate exit codes

2. Logging
   - Use proper log levels
   - Include timestamps
   - Log to file for important ops
   - Enable debug mode when needed

3. Testing
   - Write unit tests
   - Include integration tests
   - Test platform-specific code
   - Use test fixtures

4. Code Organization
   - Keep functions focused
   - Use clear names
   - Include documentation
   - Follow consistent style

## Example Script

```nushell
#!/usr/bin/env nu

use lib/common.nu *

export-env {
    $env.SCRIPT_NAME = "platform-setup"
    $env.SCRIPT_VERSION = "1.0.0"
}

def check_prerequisites [] {
    let platform = detect_platform
    match $platform {
        "linux" | "darwin" => {
            check_command "nix-channel"
            check_command "nix-env"
        }
        "windows" => {
            check_command "steam"
        }
        _ => handle_error $"Unsupported platform: ($platform)"
    }
}

def platform_setup [] {
    let platform = detect_platform
    match $platform {
        "linux" | "darwin" => {
            try {
                nix-channel --update
                nix-env -u '*'
                log_success "Nix packages updated"
            } catch {
                handle_error $"Failed to update Nix packages: ($env.LAST_ERROR)"
            }
        }
        "windows" => {
            try {
                # Windows-specific setup
                log_success "Windows setup completed"
            } catch {
                handle_error $"Windows setup failed: ($env.LAST_ERROR)"
            }
        }
        _ => handle_error $"Unsupported platform: ($platform)"
    }
}

def main [] {
    try {
        log_info "Starting platform setup..."
        check_prerequisites
        platform_setup
        log_success "Platform setup completed"
    } catch {
        handle_error $"Platform setup failed: ($env.LAST_ERROR)"
    }
}

main
```

## Debugging

### Debug Mode

```nushell
# Enable debug mode
$env.DEBUG = true
# Or: nix-mox --script <script> --debug
```

### Script Logging

```nushell
# Set log file
$env.LOG_FILE = "script.log"
# Or: nix-mox --script <script> --log script.log
```

### Debug Techniques

1. Print variables: `print $"Value: ($variable)"`
2. Check output: `let output = (command | str trim)`
