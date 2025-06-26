# nix-mox

> A comprehensive NixOS configuration framework for devs, sysadmins, and power users.

[![NixOS](https://img.shields.io/badge/NixOS-21.11-blue.svg)](https://nixos.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flake](https://img.shields.io/badge/Flake-Enabled-green.svg)](https://nixos.wiki/wiki/Flakes)
[![CI](https://github.com/Hydepwns/nix-mox/workflows/CI%20(Simplified)/badge.svg)](https://github.com/Hydepwns/nix-mox/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/Hydepwns/nix-mox/branch/main/graph/badge.svg?token=0Uuau6V5pl)](https://codecov.io/gh/Hydepwns/nix-mox)
[![Platforms](https://img.shields.io/badge/platforms-x86_64%20%7C%20aarch64%20%7C%20Linux%20%7C%20macOS-blue.svg)](https://github.com/Hydepwns/nix-mox/actions)
[![Nix Versions](https://img.shields.io/badge/nix%20versions-2.19.2%20%7C%202.20.1-green.svg)](https://github.com/Hydepwns/nix-mox/actions)

## Quick Start

```bash
git clone https://github.com/Hydepwns/nix-mox.git
cd nix-mox
./scripts/setup-wizard.nu
```

```bash
nix-mox/
├── config/ # <Your NixOS configuration>
├── modules/
├── devshells/ # Dev shells for different use cases (default includes Cursor IDE, Kitty terminal, Proxmox tools)
├── scripts/
├── docs/
```

## Quick Development

```bash
# Enter default shell with Cursor IDE and Kitty terminal
nix develop

# Open Cursor IDE
cursor .

# Open new terminal
kitty

# Proxmox management (Linux only)
virt-manager
nix run .#proxmox-update
```

## Testing & Coverage

### Quick Testing
```bash
# Run all tests
make test

# Run specific test suites
make unit
make integration

# Run tests with coverage
make test && make coverage
```

### Coverage System

nix-mox supports multiple coverage approaches for different needs:

```bash
# LCOV Coverage (Recommended for Codecov)
make coverage

# Rust-based coverage tools
make coverage-grcov    # Advanced line-by-line coverage
make coverage-tarpaulin # Simplified Rust coverage

# Custom test-based coverage
make coverage-custom

# CI and local development
make coverage-ci       # Optimized for CI environments
make coverage-local    # Local development with fallbacks
```

### Coverage Options

| Approach | Best For | Requirements | Codecov Compatible |
|----------|----------|--------------|-------------------|
| **LCOV** | Codecov integration | None | ✅ Yes |
| **grcov** | Advanced Rust projects | Rust toolchain | ✅ Yes |
| **tarpaulin** | Simplified Rust coverage | Rust toolchain | ✅ Yes |
| **Custom** | Test result tracking | None | ❌ No |

### Coverage Reports

- **LCOV Format**: `coverage-tmp/coverage.lcov` (for Codecov)
- **Summary**: `coverage-tmp/coverage-summary.json`
- **Test Results**: `coverage-tmp/nix-mox-tests/`

See [Coverage Documentation](docs/COVERAGE.md) for detailed information and troubleshooting.

## Documentation

- [Usage Guide](docs/USAGE.md)
- [Contributing](docs/CONTRIBUTING.md)
- [Architecture](docs/architecture/ARCHITECTURE.md)
- [Coverage Guide](docs/COVERAGE.md)
- [Cachix Cache](https://app.cachix.org/cache/nix-mox)
- [Local Test Workflow](https://github.com/Hydepwns/nix-mox/actions/workflows/test-local.yml) — manual/experimental

## CI/CD

- [CI Status](https://github.com/Hydepwns/nix-mox/actions/workflows/ci.yml)
- **Coverage**: Integrated with Codecov using LCOV format
- **Multi-platform**: Tests run on Linux and macOS
- **Caching**: Uses Cachix for faster builds
- **Coverage Tracking**: Real-time coverage reports on [Codecov](https://codecov.io/gh/Hydepwns/nix-mox)

### CI Features

- ✅ **Automated Testing**: Unit, integration, and performance tests
- ✅ **Coverage Generation**: LCOV format for Codecov integration
- ✅ **Multi-Platform**: Linux and macOS support
- ✅ **Package Building**: All packages built and cached
- ✅ **Security Checks**: Automated security validation
- ✅ **Performance Analysis**: Build time and resource optimization

## License

MIT — see [LICENSE](LICENSE)
