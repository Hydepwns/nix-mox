# Nushell Implementation

Guide for nix-mox's Nushell automation scripts.

## Features

- Type safety and validation
- Platform detection
- Structured logging
- Process management
- Error handling

## Package Scripts

The project includes the following Nushell scripts (Linux only):

- **proxmox-update.nu**: Updates Proxmox VE packages
- **vzdump-backup.nu**: Creates backups of Proxmox VMs and containers
- **zfs-snapshot.nu**: Manages ZFS snapshots with automatic pruning
- **steam-rust-update.nu**: Updates Steam and Rust games
- **optimize-game-performance.nu**: Optimizes game performance settings

## Usage

```nushell
# Basic
./scripts/nix-mox.nu
./scripts/nix-mox.nu --platform linux
./scripts/nix-mox.nu --verbose

# Advanced
./scripts/nix-mox.nu --timeout 30
./scripts/nix-mox.nu --retry 3 --retry-delay 5
./scripts/nix-mox.nu --log-file install.log
```

## Module Examples

### Argument Parsing

```nushell
let config = parse_args ["--platform", "linux", "--script", "install"]
```

### Platform Detection

```nushell
let platform = detect_platform
let script = get_platform_script $platform "install"
```

### Logging

```nushell
log "INFO" "Operation completed"
handle_error $env.ERROR_CODES.INVALID_ARGUMENT "Invalid input"
```

### Execution

```nushell
run_script "scripts/install.sh" --verbose
run_with_retry "scripts/install.sh" --force
```

## Script Organization

Scripts are organized by platform and functionality:

```nushell
scripts/
├── linux/
│   ├── proxmox-update.nu
│   ├── vzdump-backup.nu
│   └── zfs-snapshot.nu
├── windows/
│   └── ...
└── lib/
    ├── common.nu
    └── platform.nu
```

## Dependencies

- Nushell 0.80.0+
- Platform-specific tools
- Build tools

## Development

- Follow style guide
- Add type annotations
- Handle errors properly
- Write tests
- Update documentation
- Ensure platform-specific code is properly guarded
