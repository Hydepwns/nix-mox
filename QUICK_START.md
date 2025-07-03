# Quick Start Guide

> Get started with nix-mox in minutes.

## Prerequisites

- NixOS or Linux with Nix package manager
- Git
- Nushell (optional, for interactive setup)

## Quick Setup

```bash
# Clone repository
git clone https://github.com/Hydepwns/nix-mox.git
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

> **Note:** systemd-boot is now the default boot loader for UEFI systems. If you use legacy BIOS, adjust your hardware config accordingly.
> The default desktop environment is XFCE. Gaming support (Steam, Lutris, Heroic, MangoHud, GameMode, etc.) is integrated by default.

```bash
# Build and switch
sudo nixos-rebuild switch --flake .#nixos

# Or dry-run first
sudo nixos-rebuild dry-activate --flake .#nixos
```

## Development

### Quick Commands

```bash
# Format all code
nix run .#fmt

# Run tests
nix run .#test

# Update flake inputs
nix run .#update

# Enter development shell
nix develop
```

### Development Shells

```bash
# Enter development shell
nix develop

# Or specific shells
nix develop .#development
nix develop .#gaming
nix develop .#testing
nix develop .#services         # Service tools (Linux)
nix develop .#monitoring       # Monitoring tools (Linux)
```

## Testing

```bash
# Run all tests
nix run .#test

# Or run specific test suites
nix build .#checks.x86_64-linux.unit
nix build .#checks.x86_64-linux.integration
nix build .#checks.x86_64-linux.test-suite

# Run tests with make (legacy)
make test
make unit
make integration
```

## Next Steps

## Multi-Host Management

nix-mox supports managing multiple NixOS hosts from a single flake:

```bash
# Build specific host configurations
nix build .#nixosConfigurations.host1.config.system.build.toplevel
nix build .#nixosConfigurations.host2.config.system.build.toplevel

# Deploy to hosts
nixos-rebuild switch --flake .#host1
nixos-rebuild switch --flake .#host2

# See available hosts and outputs
nix run .#dev
```

For detailed multi-host configuration, see [Multi-Host Guide](docs/MULTI_HOST.md).


1. **Customize personal settings** - Edit `config/personal/user.nix`
2. **Configure hardware** - Edit `config/personal/hardware.nix`
3. **Add modules** - Use `nu scripts/core/integrate-modules.nu`
4. **Explore templates** - Check `config/templates/`
5. **Read documentation** - See `docs/` for detailed guides

## Troubleshooting

- **Boot loader issues:**
  - The file `config/hardware/hardware-configuration-actual.nix` is authoritative for boot loader settings. If you see a warning about bootability, ensure it contains the correct boot loader configuration for your system (e.g., `systemd-boot` for UEFI).
  - If you dual-boot or use legacy BIOS, you may need to adjust `boot.loader` options in your hardware config.
- **Display issues:**
  - XFCE is the default desktop environment. If you want to use another, edit your personal config or base config accordingly.
- **Gaming support:**
  - Gaming tools and optimizations are enabled by default. You can customize or disable them in `config/nixos/gaming.nix`.

```bash
# Check configuration
nixos-rebuild dry-activate --flake .#nixos

# Regenerate personal config
nu scripts/core/setup.nu

# Switch to minimal template
cp config/templates/minimal.nix config/nixos/configuration.nix

# Run local CI to verify setup
bash scripts/core/ci-test.sh
```

## Status

- ✅ **CI Pipeline**: Fully functional with 97% test pass rate
- ✅ **Cross-platform**: Supports Linux, macOS, and Windows
- ✅ **Production Ready**: Comprehensive testing and validation
- ✅ **Documentation**: Complete guides and examples
