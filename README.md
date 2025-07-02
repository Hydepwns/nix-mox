# nix-mox

> Production-grade NixOS configuration framework with templates and personal data separation.

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
- **Nix** (`.nix`) - `nixpkgs-fmt`
- **Shell scripts** (`.sh`, `.bash`, `.zsh`) - `shfmt` + `shellcheck`
- **Markdown** (`.md`, `.mdx`) - `prettier`
- **JSON/YAML** (`.json`, `.yml`, `.yaml`) - `prettier`
- **JavaScript/TypeScript** (`.js`, `.ts`, `.jsx`, `.tsx`) - `prettier`
- **CSS/SCSS** (`.css`, `.scss`, `.sass`) - `prettier`
- **HTML** (`.html`, `.htm`) - `prettier`
- **Python** (`.py`) - `black`
- **Rust** (`.rs`) - `rustfmt`
- **Go** (`.go`) - `gofmt`

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

- **Personal data separation** - Personal settings in `config/personal/`
- **Template system** - Ready-to-use configurations
- **Module integration** - Advanced features via modules
- **Security hardening** - Built-in security profiles
- **Environment-based config** - Different settings for different environments
- **Comprehensive testing** - 97% test pass rate with CI/CD pipeline
- **Cross-platform support** - Linux, macOS, and Windows compatibility
- **Multi-language formatting** - Consistent code style across all file types
- **Development apps** - Quick commands for common development tasks

## Status

- ✅ **CI Pipeline**: Fully functional with automated testing
- ✅ **Test Coverage**: 97% pass rate across 83 tests
- ✅ **Cross-platform**: Linux, macOS, and Windows support
- ✅ **Production Ready**: Comprehensive validation and testing
- ✅ **Documentation**: Complete guides and examples
- ✅ **Code Formatting**: Multi-language support with treefmt
- ✅ **Development Tools**: Streamlined workflow with apps

## Support

- **Issues**: [GitHub Issues](https://github.com/Hydepwns/nix-mox/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Hydepwns/nix-mox/discussions)
- **Documentation**: `docs/`

---

**Note**: This is a production-grade framework. Personal data is properly separated and secured.

## License

MIT — see [LICENSE](LICENSE)
