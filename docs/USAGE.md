# Usage & Deployment Guide

## Quick Start

1. Clone repository:

   ```bash
   git clone https://github.com/hydepwns/nix-mox.git
   cd nix-mox
   ```

2. Using Nix Flake:

   ```bash
   # Run scripts
   nix run .#proxmox-update
   nix run .#zfs-snapshot
   nix run .#nixos-flake-update

   # Install scripts
   nix profile install .#proxmox-update
   ```

3. Manual Install:

   ```bash
   sudo nu scripts/linux/install.nu
   ```

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

- **Scripts**: proxmox-update, vzdump-backup, zfs-snapshot, nixos-flake-update
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
# Enter environment
nix develop

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
