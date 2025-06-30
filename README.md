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

## Advanced Usage

### Development Shells

```bash
nix develop                    # Default environment
nix develop .#development      # Development tools
nix develop .#gaming           # Gaming tools
nix develop .#testing          # Testing tools
```

### Testing

```bash
# Run all tests
make test

# Run specific test suites
make unit
make integration

# Run CI tests locally
bash scripts/core/ci-test.sh
```

### Module Integration

```bash
# Add modules
nu scripts/core/integrate-modules.nu

# Available modules: infisical, tailscale, gaming, monitoring, storage
```

## Documentation

- **[Quick Start](QUICK_START.md)** - Get started in minutes
- **[Usage Guide](docs/USAGE.md)** - Comprehensive usage documentation
- **[Gaming Guide](docs/guides/gaming.md)** - Gaming setup and optimization
- **[Examples](docs/examples/)** - Configuration examples

## Features

- **Personal data separation** - Personal settings in `config/personal/`
- **Template system** - Ready-to-use configurations
- **Module integration** - Advanced features via modules
- **Security hardening** - Built-in security profiles
- **Environment-based config** - Different settings for different environments
- **Comprehensive testing** - 97% test pass rate with CI/CD pipeline
- **Cross-platform support** - Linux, macOS, and Windows compatibility

## Status

- ✅ **CI Pipeline**: Fully functional with automated testing
- ✅ **Test Coverage**: 97% pass rate across 83 tests
- ✅ **Cross-platform**: Linux, macOS, and Windows support
- ✅ **Production Ready**: Comprehensive validation and testing
- ✅ **Documentation**: Complete guides and examples

## Support

- **Issues**: [GitHub Issues](https://github.com/Hydepwns/nix-mox/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Hydepwns/nix-mox/discussions)
- **Documentation**: `docs/`

---

**Note**: This is a production-grade framework. Personal data is properly separated and secured.

## License

MIT — see [LICENSE](LICENSE)
