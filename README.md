# nix-mox

> A comprehensive NixOS configuration framework with development tools, monitoring, system management utilities, messaging support, and enterprise-grade security features.

[![NixOS](https://img.shields.io/badge/NixOS-21.11-blue.svg)](https://nixos.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flake](https://img.shields.io/badge/Flake-Enabled-green.svg)](https://nixos.wiki/wiki/Flakes)
[![CI](https://github.com/Hydepwns/nix-mox/workflows/CI/badge.svg)](https://github.com/Hydepwns/nix-mox/actions/workflows/ci.yml)
[![Tests](https://github.com/Hydepwns/nix-mox/workflows/Tests/badge.svg)](https://github.com/Hydepwns/nix-mox/actions/workflows/tests.yml)
[![Cachix Cache](https://img.shields.io/badge/cachix-nix--mox-blue.svg)](https://nix-mox.cachix.org)

nix-mox provides a modular, composable approach to NixOS configuration with pre-built templates, development environments, utility packages, and comprehensive security features. Perfect for developers, system administrators, and power users who want a robust, reproducible, and secure system setup.

## 📋 Table of Contents

- [Requirements](#-requirements)
- [Quick Start](#-quick-start)
- [Core Features](#-core-features)
  - [Fragment System](#-fragment-system)
  - [Development Shells](#-development-shells)
  - [Messaging & Communication](#-messaging--communication)
  - [Gaming Support](#-gaming-support)
  - [System Management](#-system-management)
  - [Security Features](#-security-features)
  - [Size Analysis & Performance](#-size-analysis--performance)
- [Management Tools](#-management-tools)
  - [Main Automation Entrypoint](#main-automation-entrypoint)
  - [Configuration Wizard](#configuration-wizard)
  - [Health Check System](#health-check-system)
  - [Makefile Targets](#makefile-targets)
- [Project Structure](#-project-structure)
- [Documentation](#-documentation)
- [Contributing](#-contributing)
- [License & Links](#-license--links)

## 📋 Requirements

### System Requirements

- **Operating System:** NixOS, or any Linux distribution with Nix package manager
- **Architecture:** x86_64 (Linux), aarch64 (Linux), x86_64 (macOS)
- **Memory:** Minimum 4GB RAM (8GB+ recommended for gaming and development)
- **Storage:** At least 10GB free space for base installation
- **Graphics:** Any graphics card with OpenGL/Vulkan support (for gaming features)

### Prerequisites

- **Nix Package Manager:** Version 2.4+ with flakes enabled
- **Git:** For cloning and managing the repository
- **Internet Connection:** Required for downloading packages and updates

### Optional Requirements

- **Gaming:** Dedicated graphics card with Vulkan support for optimal performance
- **Development:** Additional storage for development tools and dependencies
- **Monitoring:** Network access for Prometheus/Grafana metrics collection

## 🚀 Quick Start

### Interactive Setup (Recommended)

Use our interactive configuration wizard for the easiest setup experience:

```bash
# Clone the repository
git clone https://github.com/Hydepwns/nix-mox.git
cd nix-mox

# Run the interactive setup wizard
./scripts/setup-wizard.nu

# The wizard will guide you through:
# - Platform detection
# - Use case selection (Desktop, Server, Development, Gaming, etc.)
# - Feature selection (Messaging, Gaming, Development, Monitoring, etc.)
# - Basic system configuration
# - Hardware configuration guidance
# - Automatic file generation
```

### Manual Setup

For advanced users who prefer manual configuration:

```bash
# Clone the repository
git clone https://github.com/Hydepwns/nix-mox.git
cd nix-mox

# Use safe configuration template with messaging support
cp -r modules/templates/nixos/safe-configuration/* config/
sudo nixos-generate-config --show-hardware-config > config/hardware/hardware-configuration-actual.nix

# Customize and deploy
sudo nixos-rebuild switch --flake .#nixos
```

### Existing Users

Add to your flake:

```nix
inputs.nix-mox = {
  url = "github:Hydepwns/nix-mox";
  inputs.nixpkgs.follows = "nixpkgs";
};

environment.systemPackages = with pkgs; [
  inputs.nix-mox.packages.${pkgs.system}.proxmox-update
  inputs.nix-mox.packages.${pkgs.system}.vzdump-backup
  inputs.nix-mox.packages.${pkgs.system}.zfs-snapshot
  inputs.nix-mox.packages.${pkgs.system}.nixos-flake-update
  inputs.nix-mox.packages.${pkgs.system}.install
  inputs.nix-mox.packages.${pkgs.system}.uninstall
];
```

### 🚀 Cachix Cache (Recommended)

For faster builds and to avoid rebuilding packages, use our Cachix cache:

```bash
# Add the nix-mox cache to your Nix configuration
nix-env -iA cachix -f https://cachix.org/api/v1/install
cachix use nix-mox

# Or add to your NixOS configuration
nix.settings.substituters = [ "https://nix-mox.cachix.org" ];
nix.settings.trusted-public-keys = [ "nix-mox.cachix.org-1:8SitoywBaXeFjuQ98Dox4Fq1g48fVVAf8jQjA=1" ];
```

This will significantly speed up your builds by downloading pre-built packages instead of building them locally.

## 🎯 Core Features

### 🧩 Fragment System

Compose configurations from reusable fragments for maximum flexibility. Import complete base configurations or mix and match individual components like networking, display, messaging, and packages.

### 🛠️ Development Shells

Specialized development environments for different use cases:

```bash
nix develop                    # Default development environment
nix develop .#development      # Full development tools (Python 3, testing, linting)
nix develop .#testing          # Testing and CI tools
nix develop .#services         # Service deployment tools
nix develop .#monitoring       # Monitoring and observability
nix develop .#gaming           # Gaming tools (Linux x86_64)
nix develop .#zfs              # ZFS management tools (Linux)
nix develop .#macos            # macOS development (macOS)
```

**Development Shell Features:**

- **Python 3.12**: Complete Python development environment with pip, pytest, black, flake8, mypy
- **Testing Tools**: Comprehensive testing frameworks and CI/CD utilities
- **Code Quality**: Linting, formatting, and type checking tools
- **Version Control**: Git integration with pre-commit hooks
- **Package Management**: Just, direnv, and dependency management tools

### 💬 Messaging & Communication

Comprehensive messaging and communication support with desktop notifications, deep linking, and enhanced audio/video capabilities:

- **Primary Apps:** Signal Desktop, Telegram Desktop, Discord, Slack
- **Communication Tools:** WhatsApp for Linux, Element Desktop, Thunderbird, Evolution
- **Video Calling:** Zoom, Microsoft Teams, Skype
- **Voice & Chat:** Mumble, TeamSpeak, HexChat, WeeChat

### 🎮 Gaming Support

Full gaming environment with Wine, DXVK, and performance optimization tools:

- **Game Launchers:** Steam, Lutris, Heroic
- **Windows Compatibility:** Wine & DXVK
- **Performance Tools:** MangoHud, GameMode, Vulkan Tools
- **Game Support:** League of Legends and other Windows games

### 🔧 System Management

Comprehensive system management tools and utilities:

- **Configuration Wizard:** Interactive setup script for easy configuration
- **Health Check:** System validation and diagnostics
- **Hardware Management:** Template-based hardware configuration system
- **Security:** Complete security module with firewall, encryption, and access control
- **Storage:** ZFS management, backup systems, and storage optimization

### 🔒 Security Features

Comprehensive security module with enterprise-grade protection:

- **Fail2ban**: Intrusion prevention with configurable jails and ban policies
- **UFW Firewall**: Uncomplicated firewall with rule management and port control
- **SSL/TLS Security**: Certificate management, modern ciphers, and security headers
- **AppArmor**: Mandatory access control for application security
- **System Auditing**: Comprehensive audit rules and log management
- **SELinux Support**: Advanced mandatory access control (optional)
- **Kernel Security**: Lockdown modes, YAMA, seccomp, and stack protection
- **Network Hardening**: IPv6 privacy, TCP hardening, ICMP rate limiting
- **File System Security**: Read-only mounts, noexec, nosuid options
- **User Security**: Password policies, account lockout, and complexity requirements

```bash
# Enable all security features
imports = [ modules.security.all ];

# Or enable individual components
imports = [
  modules.security.fail2ban
  modules.security.ufw
  modules.security.ssl
  modules.security.apparmor
];
```

### 📊 Size Analysis & Performance

Analyze the actual size and performance tradeoffs of different templates and shells to make informed decisions about which components to use.

#### Interactive Size Dashboard

Generate a web-based interactive dashboard for comprehensive size analysis:

```bash
# Generate and serve interactive dashboard
make size-dashboard

# Generate HTML dashboard only
make size-dashboard-html

# Generate JSON API data
make size-dashboard-api
```

The dashboard provides:

- **Visual Charts**: Interactive bar charts and pie charts
- **Package Details**: Comprehensive size breakdowns
- **Dependency Analysis**: Dependency count and size analysis
- **Build Type Classification**: Light vs heavy build identification
- **Real-time Data**: Live package analysis

#### Advanced Caching Strategy

Optimize build performance with intelligent caching:

```bash
# Run complete caching optimization
make cache-optimize

# Warm cache with common packages
make cache-warm

# Maintain and clean cache
make cache-maintain
```

Features:

- **Multi-layer Caching**: Primary, secondary, and specialized caches
- **Health Monitoring**: Cache availability and performance checks
- **Intelligent Warming**: Pre-load frequently used packages
- **Parallel Builds**: Optimized build scheduling with dependency analysis
- **Cache Maintenance**: Automatic cleanup and optimization

#### Software Bill of Materials (SBOM)

Generate compliance-ready Software Bill of Materials:

```bash
# Generate all SBOM formats
make sbom

# Generate specific formats
make sbom-spdx      # SPDX format
make sbom-cyclonedx # CycloneDX format
make sbom-csv       # CSV report
```

Compliance features:

- **Multiple Formats**: SPDX, CycloneDX, and CSV
- **Complete Metadata**: Licenses, versions, dependencies, hashes
- **Compliance Ready**: Industry-standard formats for audits
- **Automated Generation**: Integrated with build process
- **Detailed Reports**: Comprehensive dependency analysis

## 🛠️ Management Tools

### Main Automation Entrypoint

The primary entrypoint for all automation is the bash wrapper script:

```bash
./scripts/nix-mox
```

> **Note:** The wrapper script ensures robust argument passing for all shell versions and cross-platform compatibility.

**Usage:**

```bash
./scripts/nix-mox --script install --dry-run
./scripts/nix-mox --script update
./scripts/nix-mox --script zfs-snapshot
```

**Options:**

- `-h, --help`           Show help message
- `--dry-run`           Show what would be done without making changes
- `--debug`             Enable debug output
- `--platform <os>`     Specify platform (auto, linux, darwin, nixos)
- `--script <name>`     Run specific script (install, update, zfs-snapshot)
- `--log <file>`        Log output to file

> **Note:** The wrapper script ensures robust argument passing for all Nushell versions and platforms. You no longer need to worry about double-dash (`--`) or Nushell quirks.

### Configuration Wizard

The interactive setup wizard (`scripts/setup-wizard.nu`) guides you through:

- Platform detection and validation
- Use case selection (Desktop, Server, Development, Gaming, etc.)
- Feature selection with descriptions
- Basic system configuration (hostname, timezone, username)
- Hardware configuration guidance
- Automatic file generation

### Health Check System

Run comprehensive system diagnostics with `scripts/health-check.nu`:

```bash
# Run full health check
./scripts/health-check.nu

# Check specific components
./scripts/health-check.nu --check nix-store
./scripts/health-check.nu --check services
./scripts/health-check.nu --check security
```

**The health check validates:**

- nix-mox environment integrity
- Configuration file syntax
- Flake syntax and dependencies
- NixOS configuration validity
- System services status
- Disk and memory usage
- Network connectivity
- Nix store integrity
- Security settings

### Makefile Targets

Use the included Makefile for common operations:

```bash
# Setup and configuration
make setup-wizard          # Run interactive setup wizard
make health-check          # Run system health check
make install               # Install nix-mox packages
make update                # Update all packages
make test                  # Run test suite

# Development
make dev-shell             # Enter development shell
make docs                  # Generate documentation
make clean                 # Clean build artifacts
```

## 📁 Project Structure

```bash
nix-mox/
├── config/                    # User configurations
│   ├── default.nix           # Entrypoint
│   ├── nixos/configuration.nix
│   ├── home/home.nix
│   ├── hardware/
│   │   ├── hardware-configuration.nix          # Template
│   │   └── hardware-configuration-actual.nix   # Generated config
│   └── environments/         # Environment-specific configs
├── modules/                  # Modular configuration system
│   ├── templates/            # Reusable templates
│   │   ├── base/common.nix   # Complete base config
│   │   ├── base/common/      # Individual fragments
│   │   │   ├── networking.nix
│   │   │   ├── display.nix
│   │   │   ├── packages.nix
│   │   │   ├── messaging.nix # Signal, Telegram, Discord, etc.
│   │   │   └── ...
│   │   └── nixos/safe-configuration/
│   ├── packages/             # Package collections
│   │   ├── development/      # Development tools
│   │   ├── productivity/     # Productivity apps
│   │   ├── gaming/           # Gaming packages
│   │   ├── multimedia/       # Media tools
│   │   └── system/           # System utilities
│   ├── security/             # Security configurations
│   ├── services/             # Service definitions
│   ├── storage/              # Storage management
│   └── system/               # System configurations
├── devshells/                # Development environments
├── scripts/                  # Utility scripts
│   ├── nix-mox              # Main automation entrypoint (bash wrapper)
│   ├── nix-mox.nu           # Nushell automation logic
│   ├── setup-wizard.nu       # Interactive configuration wizard
│   ├── health-check.nu       # System health diagnostics
│   ├── common/               # Shared script utilities
│   ├── linux/                # Linux-specific scripts
│   └── windows/              # Windows-specific scripts
├── tests/                    # Comprehensive test suite
│   ├── unit/                 # Unit tests
│   ├── integration/          # Integration tests
│   └── lib/                  # Test utilities
├── docs/                     # Comprehensive documentation
│   ├── guides/               # Feature-specific guides
│   ├── examples/             # Usage examples
│   ├── architecture/         # System architecture
│   └── scripting/            # Script development guide
└── flake.nix                 # Main flake
```

## 📚 Documentation

- **[Usage Guide](docs/USAGE.md)** - Comprehensive usage instructions, examples, troubleshooting, and FAQ
- **[Guides](docs/guides/)** - Detailed guides for specific features (gaming, drivers, proxmox, etc.)
- **[Examples](docs/examples/)** - Step-by-step examples for common use cases
- **[Architecture](docs/architecture/)** - Project architecture and design decisions
- **[Scripting Guide](docs/scripting/)** - Script development and automation
- **[API Reference](docs/api/)** - Technical reference documentation

## 🤝 Contributing

```bash
# Setup development environment
nix develop .#development
pre-commit install
make test
```

For detailed contribution guidelines, see [Contributing Guide](docs/CONTRIBUTING.md).

## 📄 License & Links

**License:** MIT License - see [LICENSE](LICENSE)

**Links:**

- [GitHub](https://github.com/Hydepwns/nix-mox)
- [Issues](https://github.com/Hydepwns/nix-mox/issues)
- [Discussions](https://github.com/Hydepwns/nix-mox/discussions)
