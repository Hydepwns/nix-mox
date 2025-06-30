# Quick Start Guide

> Get started with nix-mox in minutes.

## Prerequisites

- NixOS or Linux with Nix package manager
- Git
- Nushell (optional, for interactive setup)

## Quick Setup

```bash
# Clone repository
git clone https://github.com/hydepwns/nix-mox.git
cd nix-mox

# Interactive setup (recommended)
nu scripts/core/setup.nu

# Or manual setup
cp env.example .env
nano .env
```

## Choose Your Template

```bash
# Development environment
cp config/templates/development.nix config/nixos/configuration.nix

# Gaming workstation
cp config/templates/gaming.nix config/nixos/configuration.nix

# Server setup
cp config/templates/server.nix config/nixos/configuration.nix

# Minimal system
cp config/templates/minimal.nix config/nixos/configuration.nix
```

## Build and Deploy

```bash
# Build and switch
sudo nixos-rebuild switch --flake .#nixos

# Or dry-run first
sudo nixos-rebuild dry-activate --flake .#nixos
```

## Development

```bash
# Enter development shell
nix develop

# Or specific shells
nix develop .#development
nix develop .#gaming
nix develop .#testing
```

## Next Steps

1. **Customize personal settings** - Edit `config/personal/user.nix`
2. **Configure hardware** - Edit `config/personal/hardware.nix`
3. **Add modules** - Use `nu scripts/core/integrate-modules.nu`
4. **Explore templates** - Check `config/templates/`
5. **Read documentation** - See `docs/` for detailed guides

## Troubleshooting

```bash
# Check configuration
nixos-rebuild dry-activate --flake .#nixos

# Regenerate personal config
nu scripts/core/setup.nu

# Switch to minimal template
cp config/templates/minimal.nix config/nixos/configuration.nix
```