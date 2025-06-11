# Nushell Implementation

Terse guide for nix-mox's Nushell implementation, providing robust and type-safe automation.

## Architecture

```mermaid
graph TD
    A[nix-mox.nu] --> B[Modules]
    B --> C[argparse.nu]
    B --> D[platform.nu]
    B --> E[logging.nu]
    B --> F[exec.nu]
    B --> G[handlers.nu]
    
    C --> H[Type Safety]
    D --> I[Platform Detection]
    E --> J[Logging]
    F --> K[Execution]
    G --> L[Handlers]
```

## Module Flow

```mermaid
flowchart TD
    A[Input] --> B[Parse Args]
    B --> C[Detect Platform]
    C --> D[Setup Logging]
    D --> E[Execute Script]
    E --> F[Handle Result]
    
    B --> G[Type Check]
    C --> H[Validate]
    D --> I[Format]
    E --> J[Timeout]
    F --> K[Report]
```

## Features

```mermaid
graph TD
    A[Features] --> B[Type Safety]
    A --> C[Data Structures]
    A --> D[Process Management]
    A --> E[Logging]
    A --> F[Platform Support]
    
    B --> B1[Strong Typing]
    B --> B2[Type Checking]
    
    C --> C1[Tables]
    C --> C2[Records]
    
    D --> D1[Parallel Exec]
    D --> D2[Timeout]
    
    E --> E1[Structured Logs]
    E --> E2[Levels]
    
    F --> F1[Detection]
    F --> F2[Compatibility]
```

## Usage Examples

```nushell
# Basic
./scripts/nix-mox.nu
./scripts/nix-mox.nu --platform linux
./scripts/nix-mox.nu --verbose

# Advanced
./scripts/nix-mox.nu --timeout 30
./scripts/nix-mox.nu --retry 3 --retry-delay 5
./scripts/nix-mox.nu --parallel
./scripts/nix-mox.nu --log-file install.log
```

## Error Handling

```mermaid
graph TD
    A[Error] --> B{Type}
    B -->|Invalid Arg| C[Code 1]
    B -->|File Missing| D[Code 2]
    B -->|Permission| E[Code 3]
    B -->|Handler| F[Code 4]
    B -->|Dependency| G[Code 5]
    B -->|Execution| H[Code 6]
    B -->|Timeout| I[Code 7]
    B -->|State| J[Code 8]
    B -->|Network| K[Code 9]
    B -->|Config| L[Code 10]
```

## Testing Flow

```mermaid
flowchart TD
    A[Test Suite] --> B[Unit Tests]
    A --> C[Integration Tests]
    A --> D[Performance Tests]
    
    B --> E[Module Tests]
    C --> F[System Tests]
    D --> G[Benchmarks]
    
    E --> H[Results]
    F --> H
    G --> H
```

## Module Examples

### Argument Parsing

```nushell
# argparse.nu
let config = parse_args ["--platform", "linux", "--script", "install"]
```

### Platform Detection

```nushell
# platform.nu
let platform = detect_platform
let script = get_platform_script $platform "install"
```

### Logging

```nushell
# logging.nu
log "INFO" "Operation completed"
handle_error $env.ERROR_CODES.INVALID_ARGUMENT "Invalid input"
```

### Execution

```nushell
# exec.nu
run_script "scripts/install.sh" --verbose
run_with_retry "scripts/install.sh" --force
```

### Handlers

```nushell
# handlers.nu
handle_script "scripts/install.sh" --platform linux
run_platform_script "linux" "install"
```

## Dependencies

```mermaid
graph TD
    A[Dependencies] --> B[Nushell]
    A --> C[Handlers]
    A --> D[Tools]
    
    B --> B1[0.80.0+]
    
    C --> C1[Bash]
    C --> C2[Python]
    
    D --> D1[Platform Specific]
    D --> D2[Build Tools]
```

## Development Flow

```mermaid
flowchart TD
    A[Development] --> B[Style Guide]
    A --> C[Testing]
    A --> D[Documentation]
    A --> E[Type Annotations]
    A --> F[Error Handling]
    
    B --> G[Review]
    C --> G
    D --> G
    E --> G
    F --> G
```
