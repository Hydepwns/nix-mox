# Nix-Mox Modules

This directory contains all the modules used by nix-mox. Each module is organized by its functionality and purpose.

## Directory Structure

```bash
modules/
├── core/                 # Core functionality and base modules
├── system/              # System-level configurations
├── services/            # Service-specific modules
├── storage/             # Storage-related modules
├── templates/           # Template-related modules
├── security/            # Security-related modules
├── monitoring/          # Monitoring and observability
├── packages/            # Package-specific modules
│   ├── linux/          # Linux-specific packages and scripts
│   └── darwin/         # macOS-specific packages and scripts
└── scripts/            # Platform-specific scripts
    ├── linux/          # Linux-specific scripts
    └── windows/         # Windows-specific scripts
```

## Using Modules

Each directory contains an `index.nix` file that exposes its modules. To use a module in your configuration:

1. Import the module through the flake:

```nix
{
  imports = [
    nix-mox.nixosModules.core
    nix-mox.nixosModules.services
    # etc...
  ];
}
```

1. Or import specific modules directly:

```nix
{
  imports = [
    ./modules/services/infisical.nix
    ./modules/storage/zfs/auto-snapshot.nix
  ];
}
```

## Adding New Modules

To add a new module:

1. Create your module file in the appropriate directory
2. Add it to that directory's `index.nix`
3. The module will be automatically available through the main flake

Example of adding a new service module:

```nix
# modules/services/my-service.nix
{ config, pkgs, ... }:
{
  # Your module configuration
}

# modules/services/index.nix
{
  infisical = import ./infisical.nix;
  tailscale = import ./tailscale.nix;
  my-service = import ./my-service.nix;  # Add your new module here
}
```

## Module Categories

- **core/**: Fundamental modules that provide base functionality
- **system/**: System-level configurations for hardware and networking
- **services/**: Service-specific modules for various applications
- **storage/**: Storage-related modules including ZFS and backup
- **templates/**: Template configurations for different systems
- **security/**: Security-related modules for encryption and access control
- **monitoring/**: Monitoring and observability modules
- **gaming/**: Gaming-specific modules for Steam, Wine, and performance tuning
- **packages/**: Platform-specific package modules
  - **linux/**: Linux-specific packages and scripts
  - **darwin/**: macOS-specific packages and scripts
- **scripts/**: Platform-specific scripts
  - **linux/**: Linux-specific scripts (e.g., backup, update, and maintenance scripts)
  - **darwin/**: macOS-specific scripts

Each category has its own README.md with more specific information about its contents and usage.

## Gaming Modules

### Using Gaming Modules

To use gaming modules in your configuration:

```nix
{
  imports = [
    nix-mox.nixosModules.gaming
  ];
}
```

### Available Gaming Modules

- **steam.nix**: Configuration for Steam installation and updates
- **wine.nix**: Configuration for Wine and Windows compatibility
- **performance.nix**: Performance tuning for gaming VMs

## Platform-Specific Scripts

The `scripts/` directory contains platform-specific automation scripts. The main entrypoint is now a bash wrapper for robust CLI usage:

```bash
# Main CLI entrypoint (robust argument passing)
./modules/scripts/nix-mox --script install --dry-run
```

- **linux/**: Linux scripts (backup, update, ZFS, install, etc.)
- **windows/**: Windows scripts
- **nix-mox**: Bash wrapper (recommended for all CLI usage)
- **nix-mox.nu**: Nushell automation logic (called by the wrapper)

> The wrapper ensures all arguments are passed correctly to the automation logic, regardless of Nushell version or platform.
