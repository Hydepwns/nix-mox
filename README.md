# nix-mox

> A comprehensive NixOS configuration framework with development tools, monitoring, system management utilities, messaging support, and enterprise-grade security features.

[![NixOS](https://img.shields.io/badge/NixOS-21.11-blue.svg)](https://nixos.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flake](https://img.shields.io/badge/Flake-Enabled-green.svg)](https://nixos.wiki/wiki/Flakes)
[![CI](https://github.com/Hydepwns/nix-mox/workflows/CI/badge.svg)](https://github.com/Hydepwns/nix-mox/actions/workflows/ci.yml)

## TL;DR

nix-mox = NixOS configuration framework with:

- 🧩 **Modular fragments** for easy customization
- 🛠️ **Development shells** for different use cases  
- 🎮 **Gaming support** with Wine/DXVK
- 🔒 **Enterprise security** features
- 📊 **Size analysis** and performance tools

**Get started in 5 minutes:**

```bash
git clone https://github.com/Hydepwns/nix-mox.git
cd nix-mox
./scripts/setup-wizard.nu
```

## 🚀 Quick Start

### Interactive Setup (Recommended)

```bash
# Clone and run the wizard
git clone https://github.com/Hydepwns/nix-mox.git
cd nix-mox
./scripts/setup-wizard.nu
```

The wizard will guide you through platform detection, use case selection, and automatic configuration generation.

### Manual Setup

```bash
# Use safe configuration template
cp -r modules/templates/nixos/safe-configuration/* config/
sudo nixos-generate-config --show-hardware-config > config/hardware/hardware-configuration-actual.nix
sudo nixos-rebuild switch --flake .#nixos
```

### Add to Existing Flake

```nix
inputs.nix-mox = {
  url = "github:Hydepwns/nix-mox";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

## 🎯 Core Features

### 🧩 Fragment System

Compose configurations from reusable fragments. Import complete base configurations or mix individual components.

### 🛠️ Development Shells

```bash
nix develop                    # Default development environment
nix develop .#development      # Full development tools
nix develop .#gaming           # Gaming tools (Linux x86_64)
nix develop .#monitoring       # Monitoring and observability
```

### 🎮 Gaming Support

Full gaming environment with Wine, DXVK, and performance optimization:

- **Game Launchers:** Steam, Lutris, Heroic
- **Windows Compatibility:** Wine & DXVK
- **Performance Tools:** MangoHud, GameMode, Vulkan Tools

### 🔒 Security Features

Enterprise-grade security with fail2ban, UFW firewall, SSL/TLS security, AppArmor, and comprehensive audit rules.

### 💬 Messaging & Communication

Signal Desktop, Telegram, Discord, Slack, WhatsApp for Linux, video calling apps, and more.

### 📊 Size Analysis & Performance

Interactive dashboard for analyzing package sizes and performance tradeoffs:

```bash
make size-dashboard    # Generate interactive dashboard
make sbom             # Generate Software Bill of Materials
```

## 🛠️ Management Tools

### Main Entrypoint

```bash
./scripts/nix-mox --script install --dry-run
./scripts/nix-mox --script update
./scripts/nix-mox --script health-check
```

### Configuration Wizard

Interactive setup with platform detection, use case selection, and automatic file generation.

### Health Check System

```bash
./scripts/health-check.nu                    # Full system check
./scripts/health-check.nu --check nix-store  # Specific components
```

### Makefile Targets

```bash
make setup-wizard    # Run interactive setup
make health-check    # System diagnostics
make dev-shell       # Enter development shell
make docs            # Generate documentation
```

## 📁 Project Structure

```
nix-mox/
├── config/                    # User configurations
├── modules/                   # Modular configuration system
│   ├── templates/            # Reusable templates
│   ├── packages/             # Package collections
│   ├── security/             # Security configurations
│   └── services/             # Service definitions
├── devshells/                # Development environments
├── scripts/                  # Utility scripts
│   ├── setup-wizard.nu       # Interactive configuration
│   ├── health-check.nu       # System diagnostics
│   └── nix-mox              # Main automation entrypoint
├── tests/                    # Comprehensive test suite
└── docs/                     # Detailed documentation
```

## 📚 Documentation

- **[📖 Usage Guide](docs/USAGE.md)** - Comprehensive usage instructions and examples
- **[🔧 Guides](docs/guides/)** - Feature-specific guides (gaming, drivers, proxmox, etc.)
- **[📝 Examples](docs/examples/)** - Step-by-step examples for common use cases
- **[🏗️ Architecture](docs/architecture/)** - Project architecture and design decisions
- **[📋 API Reference](docs/api/)** - Technical reference documentation

<details>
<summary><b>📋 Requirements</b></summary>

### System Requirements

- **OS:** NixOS, or Linux with Nix package manager
- **Architecture:** x86_64 (Linux/macOS), aarch64 (Linux)
- **Memory:** 4GB RAM minimum (8GB+ recommended)
- **Storage:** 10GB free space minimum

### Prerequisites

- **Nix Package Manager:** Version 2.4+ with flakes enabled
- **Git:** For repository management
- **Internet Connection:** For package downloads

</details>

<details>
<summary><b>🚀 Cachix Cache (Recommended)</b></summary>

For faster builds, use our Cachix cache:

```bash
nix-env -iA cachix -f https://cachix.org/api/v1/install
cachix use nix-mox
```

Or add to your NixOS configuration:

```nix
nix.settings.substituters = [ "https://nix-mox.cachix.org" ];
nix.settings.trusted-public-keys = [ "nix-mox.cachix.org-1:8SitoywBaXeFjuQ98Dox4Fq1g48fVVAf8jQjA=1" ];
```

</details>

## 🤝 Contributing

```bash
# Setup development environment
nix develop .#development
pre-commit install
make test
```

See [Contributing Guide](docs/CONTRIBUTING.md) for detailed guidelines.

## 📄 License & Links

**License:** MIT License - see [LICENSE](LICENSE)

**Links:**

- [GitHub](https://github.com/Hydepwns/nix-mox)
- [Issues](https://github.com/Hydepwns/nix-mox/issues)
- [Discussions](https://github.com/Hydepwns/nix-mox/discussions)
