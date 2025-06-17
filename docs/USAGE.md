# Usage & Deployment Guide

## Quick Start

1. Clone repository:

   ```bash
   git clone https://github.com/hydepwns/nix-mox.git
   cd nix-mox
   ```

2. Using Nix Flake:

   ```bash
   # Install the default package (proxmox-update)
   nix profile install .

   # Or install specific packages
   nix profile install .#proxmox-update
   nix profile install .#vzdump-backup
   nix profile install .#zfs-snapshot

   # Run scripts directly
   nix run .#proxmox-update
   nix run .#vzdump-backup
   nix run .#zfs-snapshot
   ```

3. Manual Install:

   ```bash
   sudo nu scripts/linux/install.nu
   ```

## Available Packages

The following packages are available on Linux systems:

- **proxmox-update**: Update and upgrade Proxmox host packages safely
- **vzdump-backup**: Backup Proxmox VMs and containers using vzdump
- **zfs-snapshot**: Create and manage ZFS snapshots with automatic pruning
- **steam-rust-update**: Update Steam and Rust games
- **optimize-game-performance**: Optimize game performance settings

## Module Integration

```nix
# flake.nix
{
  inputs.nix-mox.url = "github:hydepwns/nix-mox";
}

# configuration.nix
{
  imports = [
    nix-mox.nixosModules.nix-mox
    nix-mox.nixosModules.zfs-auto-snapshot
    nix-mox.nixosModules.infisical
    nix-mox.nixosModules.tailscale
  ];
}
```

## Components

- **Scripts**: proxmox-update, vzdump-backup, zfs-snapshot
- **Templates**: Containers, VMs, Monitoring, Storage
- **Modules**: Common, ZFS, Infisical, Tailscale

## Template Configuration

```nix
services.nix-mox.templates = {
  enable = true;
  templates = [ "web-server" "database-management" ];
  customOptions = {
    web-server = {
      serverType = "nginx";
      enableSSL = true;
    };
  };
};
```

## Development

```bash
# Enter development environment
nix develop

# Enter specific development shells
nix develop .#development
nix develop .#testing
nix develop .#services
nix develop .#monitoring
nix develop .#zfs  # Linux only

# Run tests
nu scripts/run-tests.nu

# Contribute
git checkout -b feature/your-feature
git commit -m "feat: your feature"
git push origin feature/your-feature
```

## Examples

See `nixamples` directory for:

- Basic Usage
- Custom Options
- Template Composition
- Template Inheritance
- Template Variables
- Template Overrides
