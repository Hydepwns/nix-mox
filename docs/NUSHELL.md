# Nushell Implementation

This document describes the Nushell implementation of nix-mox, which provides a more robust and type-safe alternative to the bash implementation.

## Modules

### argparse.nu

Handles command-line argument parsing with type safety and better error handling.

```nushell
# Example usage
let config = parse_args ["--platform", "linux", "--script", "install"]
```

### platform.nu

Provides platform detection and script management with improved data structures.

```nushell
# Example usage
let platform = detect_platform
let script = get_platform_script $platform "install"
```

### logging.nu

Implements logging with better formatting and error handling.

```nushell
# Example usage
log "INFO" "Operation completed successfully"
handle_error $env.ERROR_CODES.INVALID_ARGUMENT "Invalid input" "Details here"
```

### exec.nu

Manages script execution with timeout and retry capabilities.

```nushell
# Example usage
run_script "scripts/install.sh" --verbose
run_with_retry "scripts/install.sh" --force
```

### handlers.nu

Manages script handlers and dependency validation.

```nushell
# Example usage
handle_script "scripts/install.sh" --platform linux
run_platform_script "linux" "install"
```

## Features

### Type Safety

- Strong typing for function parameters
- Type checking for command-line arguments
- Better error messages for type mismatches

### Improved Data Structures

- Tables for structured data
- Records for configuration
- Lists for collections
- Better string manipulation

### Better Process Management

- Native support for parallel execution
- Improved timeout handling
- Better error capture and reporting

### Enhanced Logging

- Structured log messages
- Log levels (INFO, WARN, ERROR)
- Log file support
- Better formatting

### Platform Support

- Better platform detection
- Cross-platform compatibility
- Improved script handler selection

## Usage

### Basic Usage

```nushell
# Run with default settings
./scripts/nix-mox.nu

# Run with specific platform
./scripts/nix-mox.nu --platform linux

# Run with verbose output
./scripts/nix-mox.nu --verbose

# Run in dry-run mode
./scripts/nix-mox.nu --dry-run
```

### Advanced Usage

```nushell
# Run with timeout
./scripts/nix-mox.nu --timeout 30

# Run with retries
./scripts/nix-mox.nu --retry 3 --retry-delay 5

# Run in parallel (CI mode)
./scripts/nix-mox.nu --parallel

# Run with log file
./scripts/nix-mox.nu --log-file install.log
```

## Testing

Run the test suite:

```nushell
$env.NU_TEST = "true"
./scripts/tests/test.nu
```

## Error Codes

| Code | Name | Description |
|------|------|-------------|
| 0 | SUCCESS | Operation completed successfully |
| 1 | INVALID_ARGUMENT | Invalid command-line argument |
| 2 | FILE_NOT_FOUND | Required file not found |
| 3 | PERMISSION_DENIED | Insufficient permissions |
| 4 | HANDLER_NOT_FOUND | Script handler not found |
| 5 | DEPENDENCY_MISSING | Required dependency missing |
| 6 | EXECUTION_FAILED | Script execution failed |
| 7 | TIMEOUT | Script execution timed out |
| 8 | INVALID_STATE | System in invalid state |
| 9 | NETWORK_ERROR | Network operation failed |
| 10 | CONFIGURATION_ERROR | Configuration error |

## Contributing

1. Follow the Nushell style guide
2. Add tests for new features
3. Update documentation
4. Use type annotations
5. Handle errors appropriately

## Dependencies

- Nushell 0.80.0 or higher
- Required handlers (bash, python, etc.)
- Platform-specific tools
