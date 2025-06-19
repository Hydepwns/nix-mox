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

## Safe NixOS Configuration

For users setting up NixOS for the first time, nix-mox provides a **Safe Configuration Template** that prevents common display issues and integrates seamlessly with nix-mox tools.

### Quick Setup

```bash
# Interactive setup (recommended)
./modules/templates/nixos/safe-configuration/setup.sh

# Or use the template directly
nix-mox-template-safe-configuration
```

### Key Features

- **Display Safety**: Explicitly enables display services to prevent CLI lock
- **nix-mox Integration**: Includes your nix-mox packages and development shells
- **Gaming Ready**: Steam enabled with proper graphics driver configuration
- **Development Friendly**: Includes common development tools and aliases

### Manual Configuration

1. **Create configuration directory:**

   ```bash
   mkdir -p ~/nixos-config
   cd ~/nixos-config
   ```

2. **Copy template files from:**

   ```bash
   cp -r modules/templates/nixos/safe-configuration/* .
   ```

3. **Generate hardware configuration:**

   ```bash
   sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix
   ```

4. **Update configuration and build:**

   ```bash
   sudo nixos-rebuild switch --flake .#your-hostname
   ```

### Using nix-mox After Setup

After setting up your NixOS system with the safe template:

```bash
# Your nix-mox packages are available system-wide
proxmox-update
vzdump-backup
zfs-snapshot

# Access development shells via aliases
dev-gaming  # Opens gaming development shell
dev-test    # Opens testing shell

# Or directly
nix develop github:Hydepwns/nix-mox#gaming
```

For detailed information about the safe configuration template, see:

- [NixOS on Proxmox Guide](./guides/nixos-on-proxmox.md#safe-configuration-template)

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
- **Templates**: Containers, VMs, Monitoring, Storage, Safe Configuration
- **Modules**: Common, ZFS, Infisical, Tailscale

## Template Configuration

```nix
services.nix-mox.templates = {
  enable = true;
  templates = [ "web-server" "database-management" "safe-configuration" ];
  customOptions = {
    web-server = {
      serverType = "nginx";
      enableSSL = true;
    };
    safe-configuration = {
      hostname = "my-nixos-system";
      username = "myuser";
      displayManager = "lightdm";
      desktopEnvironment = "gnome";
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
nix develop .#macos  # macOS only

# Run tests
make test              # All tests
make unit             # Unit tests only
make integration      # Integration tests only
make clean            # Clean test artifacts

# Run tests via Nix flake
nix flake check       # All checks
nix flake check .#unit        # Unit tests only
nix flake check .#integration # Integration tests only

# Contribute
git checkout -b feature/your-feature
git commit -m "feat: your feature"
git push origin feature/your-feature
```

## macOS Development

For macOS users, a dedicated development shell is available with tools and configurations optimized for macOS development:

```bash
# Enter macOS development shell
nix develop .#macos
```

The macOS shell includes:

- Core development tools (git, nix, nixpkgs-fmt)
- macOS-specific frameworks (CoreServices, Foundation)
- Development tools (vscode, jq, yq, curl)
- Terminal tools (tmux, zsh, oh-my-zsh)
- System monitoring tools (htop)

For detailed information about the macOS development shell, see:

- [macOS Shell Guide](./guides/macos-shell.md)

## Examples

See `nixamples` directory for:

- Basic Usage
- Custom Options
- Template Composition
- Template Inheritance
- Template Variables
- Template Overrides

## Gaming and Windows Games

For a full guide to gaming setup, including League of Legends and other Windows games, see:

- [Gaming Setup Guide](./gaming/README.md)

This guide covers:

- Entering the gaming shell
- Installing and configuring Lutris, Wine, and dependencies
- League of Legends setup and troubleshooting
- Performance optimization tips

### Quick Wine and League of Legends Setup Scripts

From the gaming shell (`nix develop .#gaming`), you can use these helper scripts:

```bash
# General Wine gaming configuration
nix run .#configure-wine

# League of Legends-specific Wine prefix setup
bash devshells/gaming/scripts/configure-league.sh
```

- `configure-wine` sets up a general Wine prefix with optimal settings for gaming.
- `configure-league.sh` creates a dedicated Wine prefix for League of Legends with all required components.
