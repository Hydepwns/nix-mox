# nix-mox

> Production-grade NixOS configuration framework with devenv integration, Hydepwns dotfiles, Zed editor, and Blender support.

[![CI](https://github.com/Hydepwns/nix-mox/workflows/CI%20(Simplified)/badge.svg)](https://github.com/Hydepwns/nix-mox/actions/workflows/ci.yml)
[![Platforms](https://img.shields.io/badge/platforms-x86_64%20%7C%20aarch64%20%7C%20Linux%20%7C%20macOS-blue.svg)](https://github.com/Hydepwns/nix-mox/actions)
[![Tests](https://img.shields.io/badge/tests-97%25%20passing-brightgreen.svg)](https://github.com/Hydepwns/nix-mox/actions)
[![Devenv](https://img.shields.io/badge/devenv-ready-brightgreen.svg)](https://devenv.sh/)
[![Zed](https://img.shields.io/badge/zed-editor-blue.svg)](https://zed.dev/)

## Quick Start

```bash
git clone https://github.com/Hydepwns/nix-mox.git
cd nix-mox

# Setup devenv and direnv (automatic environment loading)
direnv allow

# Setup Hydepwns dotfiles integration
./scripts/setup-hydepwns-dotfiles.sh

# Quick setup
nu scripts/core/setup.nu

# Choose template
cp config/templates/development.nix config/nixos/configuration.nix

# Build and switch
sudo nixos-rebuild switch --flake .#nixos

# Quick functionality test
nix flake check
nix develop --command zsh -c "which zed && which blender && which rustc && which elixir"
```

## Documentation

- **[Platform Guide](docs/PLATFORM.md)** - Platform-specific setup and configuration
- **[Quick Start](docs/QUICK_START.md)** - Detailed quick start guide
- **[Templates](docs/TEMPLATES.md)** - Available configuration templates
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Common issues and solutions
- **[Archive](docs/archive/)** - Legacy documentation and detailed guides

## Development Environment

```bash
# Enter development environment
nix develop

# Or use direnv (automatic loading)
direnv allow

# Available tools
zed         # Open Zed editor (primary)
blender     # Open Blender 3D
kitty       # Open Kitty terminal
rustc       # Rust compiler
cargo       # Rust package manager
elixir      # Elixir runtime
elixir-ls   # Elixir language server

# Available commands
nix run .#fmt     # Format code
nix run .#test    # Run tests
nix run .#update  # Update flake inputs
nix run .#dev     # Show development help
```

### Hydepwns Dotfiles Integration

```bash
# Setup dotfiles integration
./scripts/setup-hydepwns-dotfiles.sh

# The dotfiles will be automatically loaded in your shell
# Customize configuration as needed

# Available tools from dotfiles:
# bat, eza, fzf, htop, tree, gh, curl, wget, nmap
```

## Maintenance Tools

- **Cleanup**: `nu scripts/tools/cleanup.nu` - Comprehensive project cleanup
- **Health Check**: `nu scripts/core/health-check.nu` - System health validation
- **Size Analysis**: `nu scripts/tools/analyze-sizes.nu` - Repository size analysis

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

### Host Configuration

Each host can have its own:

- **Hardware configuration** - CPU, GPU, storage, networking
- **Home configuration** - User environment, shell, applications
- **Extra modules** - Host-specific services and features
- **Special arguments** - Secrets, environment variables, host type

```nix
# config/hosts.nix
{
  host1 = {
    system = "x86_64-linux";
    hardware = ./hardware/host1-hardware-configuration.nix;
    home = ./home/host1-home.nix;
    extraModules = [ ./modules/host1-extra.nix ];
    specialArgs = { 
      hostType = "desktop";
      mySecret = "host1-secret";
    };
  };
  
  host2 = {
    system = "x86_64-linux";
    hardware = ./hardware/host2-hardware-configuration.nix;
    home = ./home/host2-home.nix;
    extraModules = [ ./modules/server-extra.nix ];
    specialArgs = { 
      hostType = "server";
      mySecret = "host2-secret";
    };
  };
}
```

| Template | Use Case | Description |
|----------|----------|-------------|
| `minimal` | Basic system | Essential tools only |
| `development` | Software development | IDEs, tools, containers |
| `gaming` | Gaming workstation | Steam, performance optimizations |
| `server` | Production server | Monitoring, management tools |
| `ci-runner` | CI/CD infrastructure | Parallel job execution, monitoring, metrics |

> **Note**: Templates are available in `config/templates/`. See [Templates](docs/TEMPLATES.md) for details.

## Structure

```bash
config/
├── personal/     # Your settings (gitignored)
├── templates/    # Ready-to-use configs
├── profiles/     # Shared components
└── nixos/        # Main config
```

## Development Workflow

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

# Project cleanup
nu scripts/tools/cleanup.nu

# Health check
nu scripts/core/health-check.nu
```

### Development Shells

```bash
nix develop                    # Default environment
nix develop .#development      # Development tools
nix develop .#gaming           # Gaming tools
nix develop .#testing          # Testing tools
nix develop .#services         # Service tools (Linux)
nix develop .#monitoring       # Monitoring tools (Linux)
```

### Code Formatting

The project uses `treefmt` for multi-language formatting:

```bash
# Format all files
nix run .#fmt

# Or use the formatter directly
nix run .#formatter
```

**Supported formats:**

| Language/Format | Extensions | Formatter |
|----------------|------------|-----------|
| **Nix** | `.nix` | `nixpkgs-fmt` |
| **Shell scripts** | `.sh`, `.bash`, `.zsh` | `shfmt` + `shellcheck` |
| **Markdown** | `.md`, `.mdx` | `prettier` |
| **JSON/YAML** | `.json`, `.yml`, `.yaml` | `prettier` |
| **JavaScript/TypeScript** | `.js`, `.ts`, `.jsx`, `.tsx` | `prettier` |
| **CSS/SCSS** | `.css`, `.scss`, `.sass` | `prettier` |
| **HTML** | `.html`, `.htm` | `prettier` |
| **Python** | `.py` | `black` |
| **Rust** | `.rs` | `rustfmt` |
| **Go** | `.go` | `gofmt` |

### Testing

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

### Module Integration

```bash
# Add modules
nu scripts/core/integrate-modules.nu

# Available modules: infisical, tailscale, gaming, monitoring, storage
```

## Available Packages

### Linux Packages

```bash
# System management
nix run .#proxmox-update      # Update Proxmox host
nix run .#vzdump-backup       # Backup VMs and containers
nix run .#zfs-snapshot        # Manage ZFS snapshots
nix run .#nixos-flake-update  # Update NixOS flake

# Installation
nix run .#install             # Install nix-mox
nix run .#uninstall           # Uninstall nix-mox
```

### macOS Packages

```bash
# macOS management
nix run .#homebrew-setup      # Setup Homebrew
nix run .#macos-maintenance   # macOS maintenance
nix run .#xcode-setup         # Setup Xcode
nix run .#security-audit      # Security audit

# Installation
nix run .#install             # Install nix-mox
nix run .#uninstall           # Uninstall nix-mox
```

## Features

[![Multi-Host](https://img.shields.io/badge/multi--host-management-blue.svg)](https://github.com/Hydepwns/nix-mox) [![Templates](https://img.shields.io/badge/template-system-green.svg)](https://github.com/Hydepwns/nix-mox) [![Modules](https://img.shields.io/badge/module-integration-orange.svg)](https://github.com/Hydepwns/nix-mox) [![Security](https://img.shields.io/badge/security-hardened-red.svg)](https://github.com/Hydepwns/nix-mox) [![Testing](https://img.shields.io/badge/tests-97%25-brightgreen.svg)](https://github.com/Hydepwns/nix-mox) [![Platforms](https://img.shields.io/badge/platforms-linux%20%7C%20macos%20%7C%20windows-blue.svg)](https://github.com/Hydepwns/nix-mox)

**Core**: Multi-host NixOS management • Template system • Module integration • Personal data separation  
**Security**: Built-in hardening • Environment-based config • Secrets management • Network security  
**Development**: Zed editor • Multi-language formatting • Development shells • Rust & Elixir support  
**Creative**: Blender • Kitty terminal • Hydepwns dotfiles integration  
**Platforms**: Linux (NixOS) • macOS (Homebrew) • Windows • Containers  
**Management**: Health monitoring • Backup automation • Performance tuning • ZFS integration  
**Advanced**: Proxmox integration • Service orchestration • Monitoring stack • Gaming optimization

## License

MIT — see [LICENSE](LICENSE)
