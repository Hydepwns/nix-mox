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

See the [Quick Start Guide](docs/USAGE.md) for more options.

## Features

- Modular NixOS fragments
- Dev shells for all platforms
- Gaming, security, messaging, and more
- [Full feature list →](docs/USAGE.md)

## Project Structure

```mermaid
graph TD
  A[config/] --> B[modules/]
  A --> C[devshells/]
  A --> D[scripts/]
  A --> E[docs/]
```

See [Architecture](docs/architecture/ARCHITECTURE.md) for details.

## Documentation

- [Usage Guide](docs/USAGE.md)
- [Contributing](docs/CONTRIBUTING.md)
- [Architecture](docs/architecture/ARCHITECTURE.md)
- [Cachix Cache](https://app.cachix.org/cache/nix-mox)
- [Local Test Workflow](https://github.com/Hydepwns/nix-mox/actions/workflows/test-local.yml) — manual/experimental

## CI/CD

- [CI Status](https://github.com/Hydepwns/nix-mox/actions/workflows/ci.yml)

## License

MIT — see [LICENSE](LICENSE)
