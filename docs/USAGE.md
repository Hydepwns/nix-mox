# Usage & Deployment Guide

## 📋 Table of Contents

- [Quick Start](#quick-start)
- [Core Features](#core-features)
  - [Fragment System](#-fragment-system)
  - [Messaging & Communication](#-messaging--communication)
  - [Gaming Support](#-gaming-support)
  - [Size Analysis & Performance](#-size-analysis--performance)
- [Usage Examples](#usage-examples)
- [Safe NixOS Configuration](#safe-nixos-configuration)
- [Available Packages](#available-packages)
- [Module Integration](#module-integration)
- [Components](#components)
- [Template Configuration](#template-configuration)
- [Development](#development)
  - [Development Workflow](#development-workflow)
- [macOS Development](#macos-development)
- [Examples](#examples)
- [Gaming and Windows Games](#gaming-and-windows-games)
- [Troubleshooting](#troubleshooting)
  - [Common Issues](#common-issues)
  - [Performance Optimization](#performance-optimization)
  - [Getting Help](#getting-help)
  - [Debug Mode](#debug-mode)
- [Frequently Asked Questions](#-frequently-asked-questions)
  - [General Questions](#general-questions)
  - [Installation & Setup](#installation--setup)
  - [Gaming Support](#-gaming-support)
  - [Development & Customization](#development--customization)
  - [Performance & Optimization](#performance--optimization)
  - [Troubleshooting](#troubleshooting)
  - [Advanced Usage](#advanced-usage)
- [Packages & Tools](#-packages--tools)
- [Templates](#-templates)
- [Testing](#-testing)
- [Documentation](#-documentation)
- [Contributing](#-contributing)

## Quick Start

1. Clone repository:

   ```bash
   git clone https://github.com/hydepwns/nix-mox.git
   cd nix-mox
   ```

2. Using Nix Flake:

   ```bash
   # Install the default package (proxmox-update)
   nix profile install .

   # Or install specific packages
   nix profile install .#proxmox-update
   nix profile install .#vzdump-backup
   nix profile install .#zfs-snapshot
   nix profile install .#nixos-flake-update

   # Run scripts directly
   nix run .#proxmox-update
   nix run .#vzdump-backup
   nix run .#zfs-snapshot
   nix run .#nixos-flake-update
   ```

3. Manual Install:

   ```bash
   sudo nu scripts/linux/install.nu
   ```

[⬆️ Return to Top](#-table-of-contents)

## Core Features

### 🧩 Fragment System

Compose configurations from reusable fragments for maximum flexibility:

#### Use Complete Base Configuration

```nix
# config/nixos/configuration.nix
{ config, pkgs, inputs, ... }:
{
  imports = [
    ../../modules/templates/base/common.nix
    ../hardware/hardware-configuration.nix
  ];
  networking.hostName = "myhost";
  time.timeZone = "America/New_York";
}
```

#### Compose Individual Fragments

```nix
# Server configuration
{ config, pkgs, inputs, ... }:
{
  imports = [
    ../../modules/templates/base/common/networking.nix
    ../../modules/templates/base/common/packages.nix
    ../../modules/templates/base/common/nix-settings.nix
    # Skip display.nix for headless server
  ];
  services.nginx.enable = true;
}
```

#### Add Messaging Support

```nix
# Desktop configuration with messaging
{ config, pkgs, inputs, ... }:
{
  imports = [
    ../../modules/templates/base/common/networking.nix
    ../../modules/templates/base/common/display.nix
    ../../modules/templates/base/common/messaging.nix  # Signal, Telegram, etc.
    ../../modules/templates/base/common/packages.nix
  ];
  networking.hostName = "desktop";
}
```

#### Create Custom Fragments

```nix
# modules/templates/base/common/development.nix
{ config, pkgs, inputs, ... }:
{
  environment.systemPackages = with pkgs; [
    vscode git docker nodejs python3 rustc cargo
  ];
}
```

### 🛠️ Development Shells

Specialized development environments for different use cases:

```bash
nix develop                    # Default development environment
nix develop .#development      # Full development tools
nix develop .#testing          # Testing and CI tools
nix develop .#services         # Service deployment tools
nix develop .#monitoring       # Monitoring and observability
nix develop .#gaming           # Gaming tools (Linux x86_64)
nix develop .#zfs              # ZFS management tools (Linux)
nix develop .#macos            # macOS development (macOS)
```

### 💬 Messaging & Communication

Comprehensive messaging and communication support with desktop notifications, deep linking, and enhanced audio/video capabilities:

#### Primary Messaging Apps

- **Signal Desktop**: Secure messaging with end-to-end encryption
- **Telegram Desktop**: Feature-rich messaging platform
- **Discord**: Gaming and community chat platform
- **Slack**: Team collaboration and communication

#### Additional Communication Tools

- **WhatsApp for Linux**: WhatsApp desktop client
- **Element Desktop**: Matrix protocol client
- **Thunderbird**: Email client
- **Evolution**: GNOME email and calendar client

#### Video Calling & Conferencing

- **Zoom**: Video conferencing platform
- **Microsoft Teams**: Team collaboration platform
- **Skype**: Voice and video calling

#### Voice & Chat

- **Mumble**: Low-latency voice chat
- **TeamSpeak**: Voice communication
- **HexChat**: IRC client
- **WeeChat**: Modular chat client

#### Features

- **Desktop Notifications**: D-Bus integration for all messaging apps
- **Deep Linking**: Support for `signal://` and `telegram://` protocols
- **Audio/Video Calls**: Enhanced PipeWire configuration with WebRTC support
- **Firewall Configuration**: Proper ports for STUN/TURN and WebRTC services

### 🎮 Gaming Support

nix-mox provides comprehensive gaming support with Wine, DXVK, and performance optimization tools. For detailed gaming setup, configuration, and troubleshooting, see the [Gaming Guide](guides/gaming.md).

**Quick Start:**

```bash
nix develop .#gaming  # Enter gaming shell
```

**Features:**

- **Game Launchers:** Steam, Lutris, Heroic
- **Windows Compatibility:** Wine & DXVK
- **Performance Tools:** MangoHud, GameMode, Vulkan Tools
- **Game Support:** League of Legends and other Windows games

[⬆️ Return to Top](#-table-of-contents)

### 📊 Size Analysis & Performance

Analyze the actual size and performance tradeoffs of different templates and shells:

#### Quick Analysis

```bash
# Analyze all components
make analyze-sizes

# Or run directly
./scripts/analyze-sizes.sh
```

#### What It Analyzes

- **📦 Packages**: Individual package sizes and dependencies
- **💻 DevShells**: Development environment sizes and build times
- **🏗️ Templates**: NixOS configuration sizes and complexity
- **📈 Performance**: Build times and optimization recommendations

#### Sample Output

```bash
📦 Package Analysis
------------------
  proxmox-update      |   45.2 MB total |   12.1 MB package |   33.1 MB deps | 15s
  vzdump-backup       |   38.7 MB total |    8.9 MB package |   29.8 MB deps | 12s
  zfs-snapshot        |   52.1 MB total |   15.3 MB package |   36.8 MB deps | 18s

💻 Development Shell Analysis
----------------------------
  gaming              | 2047.3 MB | 45s
  development         |  892.1 MB | 23s
  default             |  156.7 MB |  8s

📈 Summary Report
----------------
📊 Total Repository Size: 3.2 GB
    Packages: 136.0 MB
    DevShells: 3.1 GB
   ️ Templates: 0.0 MB
```

#### Performance Insights

- **Gaming shell** is typically the largest due to Wine, DXVK, and game tools
- **Development shell** includes comprehensive dev tools
- **Default shell** provides minimal overhead for basic tasks
- **Templates** show the actual system configuration complexity

This helps users make informed decisions about which components to use based on their storage constraints and performance requirements.

[⬆️ Return to Top](#-table-of-contents)

## Usage Examples

### Basic Desktop Setup

```bash
# Clone and setup
git clone https://github.com/Hydepwns/nix-mox.git
cd nix-mox
cp -r modules/templates/nixos/safe-configuration/* config/

# Generate hardware config
sudo nixos-generate-config --show-hardware-config > config/hardware/hardware-configuration.nix

# Deploy
sudo nixos-rebuild switch --flake .#nixos
```

### Development Environment

```bash
# Enter development shell
nix develop .#development

# Available tools: git, vscode, docker, nodejs, python3, rustc, cargo
```

### Gaming Setup

```bash
# Enter gaming shell
nix develop .#gaming
```

For detailed setup instructions, see the [Gaming Guide](guides/gaming.md).

[⬆️ Return to Top](#-table-of-contents)

## Safe NixOS Configuration

For users setting up NixOS for the first time, nix-mox provides a **Safe Configuration Template** that prevents common display issues and integrates seamlessly with nix-mox tools.

### Quick Setup

```bash
# Interactive setup (recommended)
./modules/templates/nixos/safe-configuration/setup.sh

# Or use the template directly
nix-mox-template-safe-configuration
```

### Key Features

- **Display Safety**: Explicitly enables display services to prevent CLI lock
- **nix-mox Integration**: Includes your nix-mox packages and development shells
- **Gaming Ready**: Steam enabled with proper graphics driver configuration
- **Development Friendly**: Includes common development tools and aliases
- **Messaging & Communication**: Signal Desktop, Telegram Desktop, Discord, Slack, and more

### Manual Configuration

1. **Create configuration directory:**

   ```bash
   mkdir -p ~/nixos-config
   cd ~/nixos-config
   ```

2. **Copy template files from:**

   ```bash
   cp -r modules/templates/nixos/safe-configuration/* .
   ```

3. **Generate hardware configuration:**

   ```bash
   sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix
   ```

4. **Update configuration and build:**

   ```bash
   sudo nixos-rebuild switch --flake .#your-hostname
   ```

### Using nix-mox After Setup

After setting up your NixOS system with the safe template:

```bash
# Your nix-mox packages are available system-wide
proxmox-update
vzdump-backup
zfs-snapshot
nixos-flake-update

# Access development shells via aliases
dev-default      # Opens default development shell
dev-development  # Opens development tools shell
dev-testing      # Opens testing shell
dev-services     # Opens services shell
dev-monitoring   # Opens monitoring shell
dev-gaming       # Opens gaming development shell (Linux x86_64 only)
dev-zfs          # Opens ZFS tools shell (Linux only)
dev-macos        # Opens macOS development shell (macOS only)

# Or directly
nix develop github:Hydepwns/nix-mox#default
nix develop github:Hydepwns/nix-mox#development
nix develop github:Hydepwns/nix-mox#testing
nix develop github:Hydepwns/nix-mox#services
nix develop github:Hydepwns/nix-mox#monitoring
nix develop github:Hydepwns/nix-mox#gaming
nix develop github:Hydepwns/nix-mox#zfs
nix develop github:Hydepwns/nix-mox#macos
```

For detailed information about the safe configuration template, see:

- [NixOS on Proxmox Guide](./guides/nixos-on-proxmox.md#safe-configuration-template)

[⬆️ Return to Top](#-table-of-contents)

## Available Packages

The following packages are available on Linux systems:

- **proxmox-update**: Update and upgrade Proxmox host packages safely
- **vzdump-backup**: Backup Proxmox VMs and containers using vzdump
- **zfs-snapshot**: Create and manage ZFS snapshots with automatic pruning
- **nixos-flake-update**: Update NixOS flake inputs and system automatically
- **steam-rust-update**: Update Steam and Rust games
- **optimize-game-performance**: Optimize game performance settings

[⬆️ Return to Top](#-table-of-contents)

## Module Integration

```nix
# flake.nix
{
  inputs.nix-mox.url = "github:hydepwns/nix-mox";
}

# configuration.nix
{
  imports = [
    nix-mox.nixosModules.nix-mox
    nix-mox.nixosModules.zfs-auto-snapshot
    nix-mox.nixosModules.infisical
    nix-mox.nixosModules.tailscale
  ];
}
```

[⬆️ Return to Top](#-table-of-contents)

## Components

- **Scripts**: proxmox-update, vzdump-backup, zfs-snapshot, nixos-flake-update
- **Templates**: Containers, VMs, Monitoring, Storage, Safe Configuration
- **Modules**: Common, ZFS, Infisical, Tailscale

[⬆️ Return to Top](#-table-of-contents)

## Template Configuration

```nix
services.nix-mox.templates = {
  enable = true;
  templates = [ "web-server" "database-management" "safe-configuration" ];
  customOptions = {
    web-server = {
      serverType = "nginx";
      enableSSL = true;
    };
    safe-configuration = {
      hostname = "my-nixos-system";
      username = "myuser";
      displayManager = "lightdm";
      desktopEnvironment = "gnome";
    };
  };
};
```

[⬆️ Return to Top](#-table-of-contents)

## Development

```bash
# Enter development environment
nix develop

# Enter specific development shells
nix develop .#default        # Basic development environment (all platforms)
nix develop .#development    # Enhanced development environment (all platforms)
nix develop .#testing        # Testing environment (all platforms)
nix develop .#services       # Service development and management (all platforms)
nix develop .#monitoring     # Monitoring and observability (all platforms)
nix develop .#gaming         # Gaming environment (Linux x86_64 only)
nix develop .#zfs            # ZFS development and testing (Linux only)
nix develop .#macos          # macOS development environment (macOS only)

# Run tests
make test              # All tests
make unit             # Unit tests only
make integration      # Integration tests only
make clean            # Clean test artifacts

# Run tests via Nix flake
nix flake check       # All checks
nix flake check .#unit        # Unit tests only
nix flake check .#integration # Integration tests only

# Build packages
make build            # Build default package
make build-all        # Build all packages

# Code quality
make format           # Format Nix files
make check            # Run flake checks

# CI/CD testing
make ci-test          # Quick CI test locally
make ci-local         # Comprehensive CI test locally

# Maintenance
make update           # Update flake inputs
make lock             # Update flake.lock
make clean-all        # Clean all artifacts

# Information
make packages         # Show available packages
make shells           # Show available shells
make help             # Show all available targets

# Contribute
git checkout -b feature/your-feature
git commit -m "feat: your feature"
git push origin feature/your-feature
```

### Development Workflow

For a complete development workflow guide, see [Development Workflow Guide](./guides/development-workflow.md).

**Quick Development Commands:**

```bash
make dev           # Enter development shell
make test          # Run all tests
make format        # Format code
make check         # Run flake checks
make build-all     # Build all packages
```

[⬆️ Return to Top](#-table-of-contents)

## macOS Development

For macOS users, a dedicated development shell is available with tools and configurations optimized for macOS development:

```bash
# Enter macOS development shell
nix develop .#macos
```

The macOS shell includes:

- Core development tools (git, nix, nixpkgs-fmt)
- macOS-specific frameworks (CoreServices, Foundation)
- Development tools (vscode, jq, yq, curl)
- Terminal tools (tmux, zsh, oh-my-zsh)
- System monitoring tools (htop)

For detailed information about the macOS development shell, see:

- [macOS Shell Guide](./guides/macos-shell.md)

[⬆️ Return to Top](#-table-of-contents)

## Examples

See `nixamples` directory for:

- Basic Usage
- Custom Options
- Template Composition
- Template Inheritance
- Template Variables
- Template Overrides

[⬆️ Return to Top](#-table-of-contents)

## Gaming and Windows Games

For comprehensive gaming setup, configuration, and troubleshooting, see the [Gaming Guide](guides/gaming.md).

This guide covers:

- Entering the gaming shell
- Installing and configuring Lutris, Wine, and dependencies
- League of Legends setup and troubleshooting
- Performance optimization tips
- Quick Wine and League of Legends setup scripts

[⬆️ Return to Top](#-table-of-contents)

## 🔧 Troubleshooting

### Common Issues

#### NixOS Configuration Issues

**Problem:** Flake evaluation errors

```bash
# Error: "undefined variable 'nix-mox'"
```

**Solution:**

```bash
# Ensure flake inputs are properly configured
nix flake update
nix flake lock
```

**Problem:** Hardware configuration missing

```bash
# Error: "hardware-configuration.nix not found"
```

**Solution:**

```bash
# Generate hardware configuration
sudo nixos-generate-config --show-hardware-config > config/hardware/hardware-configuration.nix
```

#### Development Shell Issues

**Problem:** Shell not found

```bash
# Error: "development shell 'gaming' not found"
```

**Solution:**

```bash
# Check available shells
nix flake show

# Ensure you're on the correct platform
# Gaming shell: Linux x86_64 only
# macOS shell: macOS only
# ZFS shell: Linux only
```

#### Package Build Issues

**Problem:** Package build failures

```bash
# Error: "build of '/nix/store/...' failed"
```

**Solution:**

```bash
# Clean and rebuild
nix store gc
nix build .#package-name --rebuild

# Check system requirements
nix flake check
```

### Performance Optimization

#### System Performance

```bash
# Check system resources
htop

# Monitor disk usage
df -h

# Check memory usage
free -h
```

### Getting Help

1. **Check existing issues:** [GitHub Issues](https://github.com/Hydepwns/nix-mox/issues)
2. **Search discussions:** [GitHub Discussions](https://github.com/Hydepwns/nix-mox/discussions)
3. **Review documentation:** [Usage Guide](docs/USAGE.md)
4. **Check examples:** [Examples](docs/examples/)

### Debug Mode

Enable debug output for troubleshooting:

```bash
# NixOS rebuild with debug
sudo nixos-rebuild switch --flake .#nixos --show-trace

# Flake check with verbose output
nix flake check --verbose

# Package build with debug
nix build .#package-name --verbose
```

[⬆️ Return to Top](#-table-of-contents)

## ❓ Frequently Asked Questions

### General Questions

**Q: What is nix-mox?**
A: nix-mox is a comprehensive NixOS configuration framework that provides modular, composable configurations with pre-built templates, development environments, and utility packages for developers, system administrators, and power users.

**Q: Do I need to be on NixOS to use nix-mox?**
A: No, you can use nix-mox on any Linux distribution with Nix package manager installed, though it's optimized for NixOS.

**Q: Is nix-mox production-ready?**
A: Yes, nix-mox is designed for production use with comprehensive testing, monitoring, and security features.

### Installation & Setup

**Q: How do I get started with nix-mox?**
A: Follow the [Quick Start](#quick-start) guide. For new users, clone the repo and use the safe configuration template.

**Q: Can I use nix-mox with my existing NixOS configuration?**
A: Yes, you can import nix-mox modules into your existing configuration or use it as a complete replacement.

**Q: What if I don't want all the features?**
A: Use the [Fragment System](#-fragment-system) to compose only the modules you need.

### Gaming Support

**Q: Does nix-mox support gaming on Linux?**
A: Yes, nix-mox includes comprehensive gaming support with Wine, DXVK, Steam, Lutris, and performance optimization tools. See the [Gaming Guide](guides/gaming.md) for detailed information.

**Q: Can I play Windows games like League of Legends?**
A: Yes, the gaming shell includes Wine configuration and tools specifically for Windows games. See the [Gaming Guide](guides/gaming.md) for setup instructions.

**Q: What gaming platforms are supported?**
A: Steam, Lutris, Heroic Games Launcher, and direct Wine applications are all supported.

### Development & Customization

**Q: How do I add my own modules?**
A: Create your module in the appropriate `modules/` directory and add it to the directory's `index.nix` file.

**Q: Can I contribute to nix-mox?**
A: Yes! See the [Contributing](#-contributing) section for guidelines and setup instructions.

**Q: How do I test my changes?**
A: Use the testing shell: `nix develop .#testing` and run the test suite with `make test`.

### Performance & Optimization

**Q: Will nix-mox slow down my system?**
A: No, nix-mox is designed for performance with minimal overhead. Gaming and development tools are optimized for speed.

**Q: How do I optimize gaming performance?**
A: See the [Gaming Guide](guides/gaming.md) for detailed performance optimization tips including GameMode and MangoHud usage.

**Q: Can I use nix-mox on low-end hardware?**
A: Yes, you can selectively import only the modules you need to minimize resource usage.

### Troubleshooting

**Q: What if something doesn't work?**
A: Check the [Troubleshooting](#-troubleshooting) section first, then search [GitHub Issues](https://github.com/Hydepwns/nix-mox/issues).

**Q: How do I report a bug?**
A: Create an issue on GitHub with detailed information about your system, error messages, and steps to reproduce.

**Q: Where can I get help?**
A: Use [GitHub Discussions](https://github.com/Hydepwns/nix-mox/discussions) for questions and community support.

### Advanced Usage

**Q: Can I use nix-mox for server deployments?**
A: Yes, nix-mox includes server templates and monitoring tools suitable for production deployments.

**Q: How do I manage multiple machines?**
A: Use the same configuration across machines with hardware-specific fragments for customization.

**Q: Can I use nix-mox with containers?**
A: Yes, nix-mox includes container templates and LXC support for containerized deployments.

[⬆️ Return to Top](#-table-of-contents)

## 📦 Packages & Tools

### System Management

```bash
nix run .#proxmox-update       # Update Proxmox VE
nix run .#vzdump-backup        # Backup VMs
nix run .#zfs-snapshot         # Manage ZFS snapshots
nix run .#nixos-flake-update   # Update flake inputs
```

### Installation

```bash
nix run .#install              # Install nix-mox
nix run .#uninstall            # Uninstall nix-mox
```

[⬆️ Return to Top](#-table-of-contents)

## 🏗️ Templates

Pre-built configurations for common use cases:

- **Safe Configuration**: Complete desktop setup with display safety and messaging support
- **CI Runner**: High-performance CI/CD environment
- **Web Server**: Production web server configuration
- **Database**: Database server setup
- **Monitoring**: Prometheus/Grafana stack
- **Load Balancer**: HAProxy configuration

[⬆️ Return to Top](#-table-of-contents)

## 🧪 Testing

```bash
nix flake check .#checks.x86_64-linux.unit
nix flake check .#checks.x86_64-linux.integration
nix flake check .#checks.x86_64-linux.test-suite
```

[⬆️ Return to Top](#-table-of-contents)

## 📚 Documentation

- [Usage Guide](docs/USAGE.md)
- [Examples](docs/examples/)
- [Guides](docs/guides/)
- [Architecture](docs/architecture/)
- [API Reference](docs/api/)

[⬆️ Return to Top](#-table-of-contents)

## 🤝 Contributing

```bash
# Setup development environment
nix develop .#development
pre-commit install
just test
```

[⬆️ Return to Top](#-table-of-contents)
