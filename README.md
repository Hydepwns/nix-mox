# nix-mox

> Production-grade NixOS configuration framework with templates, personal data separation, and multi-host management.

[![CI](https://github.com/Hydepwns/nix-mox/workflows/CI%20(Simplified)/badge.svg)](https://github.com/Hydepwns/nix-mox/actions/workflows/ci.yml)
[![Platforms](https://img.shields.io/badge/platforms-x86_64%20%7C%20aarch64%20%7C%20Linux%20%7C%20macOS-blue.svg)](https://github.com/Hydepwns/nix-mox/actions)
[![Tests](https://img.shields.io/badge/tests-97%25%20passing-brightgreen.svg)](https://github.com/Hydepwns/nix-mox/actions)

## Quick Start

```bash
git clone https://github.com/Hydepwns/nix-mox.git
cd nix-mox

# Quick setup
nu scripts/core/setup.nu

# Choose template
cp config/templates/development.nix config/nixos/configuration.nix

# Build and switch
sudo nixos-rebuild switch --flake .#nixos
```

## Templates

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
| `desktop` | Daily use | Full desktop environment |

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

## Documentation

- **[Quick Start](QUICK_START.md)** - Get started in minutes
- **[Usage Guide](docs/USAGE.md)** - Comprehensive usage documentation
- **[Development Guide](docs/DEVELOPMENT.md)** - Development workflow and tools
- **[Formatting Guide](docs/FORMATTING.md)** - Code formatting guidelines
- **[Gaming Guide](docs/guides/gaming.md)** - Gaming setup and optimization
- **[Examples](docs/examples/)** - Configuration examples
- **[Contributing](docs/CONTRIBUTING.md)** - Development guidelines

## Features

### Core Infrastructure

- **Multi-host management** - Centralized configuration for multiple NixOS hosts
- **Template system** - Pre-built configurations for development, gaming, server, desktop
- **Module integration** - Extensible architecture with plug-and-play modules
- **Personal data separation** - Secure separation of personal settings in `config/personal/`

### Security & Hardening

- **Built-in security profiles** - Pre-configured security hardening
- **Environment-based configuration** - Different security levels per environment
- **Secrets management** - Secure handling of sensitive data
- **Network security** - Automated firewall and network configuration

### Development Tools

- **Multi-language formatting** - Consistent code style across all supported languages
- **Comprehensive testing** - 97% test pass rate with CI/CD pipeline
- **Development shells** - Isolated environments for different tasks
- **Quick commands** - Streamlined development workflows

### Platform Support

- **Linux** - Full NixOS support with optimized configurations
- **macOS** - Homebrew integration and macOS optimizations
- **Windows** - Gaming and development tools
- **Containers** - Docker and orchestration support

### System Management

- **Health monitoring** - System health checks and diagnostics
- **Backup automation** - Automated VM and container backups
- **Performance optimization** - Gaming and workstation tuning
- **Storage management** - ZFS integration with caching and snapshots

### Advanced Capabilities

- **Proxmox integration** - Automated host management and updates
- **Service orchestration** - Multi-service deployment
- **Monitoring stack** - Built-in monitoring and alerting
- **Gaming optimization** - Steam integration and performance tuning

## License

MIT — see [LICENSE](LICENSE)
