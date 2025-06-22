# nix-mox

> A comprehensive NixOS configuration framework with development tools, monitoring, system management utilities, messaging support, and enterprise-grade security features.

[![NixOS](https://img.shields.io/badge/NixOS-21.11-blue.svg)](https://nixos.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flake](https://img.shields.io/badge/Flake-Enabled-green.svg)](https://nixos.wiki/wiki/Flakes)
[![CI](https://github.com/Hydepwns/nix-mox/workflows/CI/badge.svg)](https://github.com/Hydepwns/nix-mox/actions/workflows/ci.yml)
[![Tests](https://github.com/Hydepwns/nix-mox/workflows/Tests/badge.svg)](https://github.com/Hydepwns/nix-mox/actions/workflows/tests.yml)
[![Platforms](https://img.shields.io/badge/platforms-x86_64%20%7C%20aarch64%20%7C%20Linux%20%7C%20macOS-blue.svg)](https://github.com/Hydepwns/nix-mox/actions)
[![Nix Versions](https://img.shields.io/badge/nix%20versions-2.19.2%20%7C%202.20.1-green.svg)](https://github.com/Hydepwns/nix-mox/actions)

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

## 🆕 Recent Improvements

**🚀 CI/CD Enhancements (Latest)**
- **✅ Cachix Authentication:** Fixed private cache access with secure auth tokens
- **✅ Build Resilience:** Improved error handling and graceful failure recovery
- **✅ Extended Timeouts:** Optimized for heavy package builds (90min job timeout)
- **✅ Matrix Stability:** All platforms and Nix versions building successfully
- **✅ Test Reliability:** Comprehensive test suite with 100% success rate

**📦 Package Reliability**
- **All Packages Building:** proxmox-update, vzdump-backup, zfs-snapshot, nixos-flake-update
- **Cross-Platform Support:** x86_64-linux, aarch64-linux, macOS
- **Nix Version Compatibility:** 2.19.2 and 2.20.1 fully supported

## 🚀 Quick Start

**🎯 Interactive Setup (Recommended)**
```bash
git clone https://github.com/Hydepwns/nix-mox.git
cd nix-mox
./scripts/setup-wizard.nu
```

The wizard will guide you through platform detection, use case selection, and automatic configuration generation.

<details>
<summary><b>🔧 Alternative Setup Methods</b></summary>

**Manual Setup**
```bash
cp -r modules/templates/nixos/safe-configuration/* config/
sudo nixos-generate-config --show-hardware-config > config/hardware/hardware-configuration-actual.nix
sudo nixos-rebuild switch --flake .#nixos
```

**Add to Existing Flake**
```nix
inputs.nix-mox = {
  url = "github:Hydepwns/nix-mox";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

</details>

## 🎯 Core Features

**🧩 Fragment System** - Compose configurations from reusable fragments. Import complete base configurations or mix individual components.

**🛠️ Development Shells**
```bash
nix develop                    # Default development environment
nix develop .#development      # Full development tools
nix develop .#gaming           # Gaming tools (Linux x86_64)
nix develop .#monitoring       # Monitoring and observability
```

**🎮 Gaming Support** - Full gaming environment with Wine, DXVK, and performance optimization (Steam, Lutris, Heroic, MangoHud, GameMode, Vulkan Tools)

**🔒 Security Features** - Enterprise-grade security with fail2ban, UFW firewall, SSL/TLS security, AppArmor, and comprehensive audit rules.

**💬 Messaging & Communication** - Signal Desktop, Telegram, Discord, Slack, WhatsApp for Linux, video calling apps, and more.

**📊 Size Analysis & Performance**
```bash
make size-dashboard    # Generate interactive dashboard
make sbom             # Generate Software Bill of Materials
```

## 🛡️ Quality Assurance

**✅ Comprehensive Testing** - Unit tests, integration tests, performance tests, and cross-platform testing (Linux x86_64, aarch64, macOS)

**🔄 CI/CD Pipeline** - Automated builds, matrix testing, Cachix integration, error resilience, and artifact management

**📈 Reliability Metrics** - 100% build success rate, comprehensive test coverage, full platform support, optimized build times

## 🎯 Management Tools

**🚀 Main Entrypoint**
```bash
./scripts/nix-mox --script install --dry-run
./scripts/nix-mox --script update
./scripts/nix-mox --script health-check
```

**🔍 Health Check System**
```bash
./scripts/health-check.nu                    # Full system check
./scripts/health-check.nu --check nix-store  # Specific components
```

**🔨 Makefile Targets**
```bash
make setup-wizard    # Run interactive setup
make health-check    # System diagnostics
make dev-shell       # Enter development shell
make docs            # Generate documentation
```

<details>
<summary><b>📁 Project Structure & Documentation</b></summary>

**Project Structure**
```bash
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

**Documentation**
- **[📖 Usage Guide](docs/USAGE.md)** - Comprehensive usage instructions and examples
- **[🔧 Guides](docs/guides/)** - Feature-specific guides (gaming, drivers, proxmox, etc.)
- **[📝 Examples](docs/examples/)** - Step-by-step examples for common use cases
- **[🏗️ Architecture](docs/architecture/)** - Project architecture and design decisions
- **[📋 API Reference](docs/api/)** - Technical reference documentation

</details>

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
nix.settings.trusted-public-keys = [ "nix-mox.cachix.org-1:MVJZxC7ZyRFAxVsxDuq0nmMRxlTIt5nFFm4Ur10ZCI4=" ];
```

**Recent Improvements:**

- ✅ **Private Cache Authentication:** Secure access with auth tokens
- ✅ **Reliable Push/Pull:** Optimized CI/CD integration
- ✅ **Multi-Platform Support:** Cached builds for all supported architectures
- ✅ **Build Acceleration:** Significantly faster package installation

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

## 🏗️ Build Status

<details>
<summary><b>📊 CI/CD Pipeline Status</b></summary>

### ✅ **Recent Build Success**

- **All Platforms:** x86_64-linux, aarch64-linux ✅
- **All Nix Versions:** 2.19.2, 2.20.1 ✅
- **All Packages:** proxmox-update, vzdump-backup, zfs-snapshot, nixos-flake-update ✅
- **Test Coverage:** Comprehensive test suite passing ✅
- **Cachix Integration:** Private cache with authentication ✅

### 🚀 **Build Performance**

- **Build Time:** ~3 minutes average
- **Cache Hit Rate:** Optimized with Cachix
- **Parallel Builds:** Matrix strategy across platforms
- **Error Resilience:** Graceful failure handling

### 📦 **Package Status**

| Package | x86_64-linux | aarch64-linux | Status |
|---------|-------------|---------------|---------|
| proxmox-update | ✅ | ✅ | Stable |
| vzdump-backup | ✅ | ✅ | Stable |
| zfs-snapshot | ✅ | ✅ | Stable |
| nixos-flake-update | ✅ | ✅ | Stable |

</details>
