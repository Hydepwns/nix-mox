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
└── monitoring/          # Monitoring and observability
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

2. Or import specific modules directly:

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

Each category has its own README.md with more specific information about its contents and usage.
