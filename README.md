# nix-mox

> A comprehensive NixOS configuration framework with development tools, monitoring, system management utilities, and messaging support.

[![NixOS](https://img.shields.io/badge/NixOS-21.11-blue.svg)](https://nixos.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flake](https://img.shields.io/badge/Flake-Enabled-green.svg)](https://nixos.wiki/wiki/Flakes)

nix-mox provides a modular, composable approach to NixOS configuration with pre-built templates, development environments, and utility packages. Perfect for developers, system administrators, and power users who want a robust, reproducible system setup.

## 📋 Table of Contents

- [Requirements](#-requirements)
- [Quick Start](#-quick-start)
- [Core Features](#-core-features)
  - [Fragment System](#-fragment-system)
  - [Development Shells](#-development-shells)
  - [Messaging & Communication](#-messaging--communication)
  - [Gaming Support](#-gaming-support)
  - [Size Analysis & Performance](#-size-analysis--performance)
- [Project Structure](#-project-structure)
- [Usage Examples](#-usage-examples)
- [Troubleshooting](#-troubleshooting)
- [Frequently Asked Questions](#-frequently-asked-questions)
- [Packages & Tools](#-packages--tools)
- [Testing](#-testing)
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

### New Users

```bash
# Clone the repository
git clone https://github.com/Hydepwns/nix-mox.git
cd nix-mox

# Use safe configuration template with messaging support
cp -r modules/templates/nixos/safe-configuration/* config/
sudo nixos-generate-config --show-hardware-config > config/hardware/hardware-configuration.nix

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

## 🎯 Core Features

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

Full gaming environment with Wine, DXVK, and performance optimization tools:

#### Gaming Tools Included

- **Steam, Lutris, Heroic**: Game launchers and platforms
- **Wine & DXVK**: Windows compatibility layer
- **MangoHud**: Performance monitoring overlay
- **GameMode**: CPU/GPU optimization
- **Vulkan Tools**: Graphics API support

#### League of Legends Setup

```bash
# Enter gaming shell
nix develop .#gaming

# Configure League of Legends
league-setup

# Launch with optimal settings
league-launch
```

#### Required Downloads

Some games require manual installer downloads due to licensing:

- **League of Legends**: [Download from Riot Games](https://signup.leagueoflegends.com/en-us/download/)
- **Windows ISOs**: [Windows 10](https://www.microsoft.com/software-download/windows10) / [Windows 11](https://www.microsoft.com/software-download/windows11)

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
```
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
   📦 Packages: 136.0 MB
   💻 DevShells: 3.1 GB
   🏗️ Templates: 0.0 MB
```

#### Performance Insights
- **Gaming shell** is typically the largest due to Wine, DXVK, and game tools
- **Development shell** includes comprehensive dev tools
- **Default shell** provides minimal overhead for basic tasks
- **Templates** show the actual system configuration complexity

This helps users make informed decisions about which components to use based on their storage constraints and performance requirements.

## 📁 Project Structure

```bash
nix-mox/
├── config/                    # User configurations
│   ├── default.nix           # Entrypoint
│   ├── nixos/configuration.nix
│   ├── home/home.nix
│   └── hardware/hardware-configuration.nix
├── modules/templates/         # Reusable templates
│   ├── base/common.nix       # Complete base config
│   ├── base/common/          # Individual fragments
│   │   ├── networking.nix
│   │   ├── display.nix
│   │   ├── packages.nix
│   │   ├── messaging.nix     # Signal, Telegram, Discord, etc.
│   │   └── ...
│   └── nixos/safe-configuration/
├── modules/packages/          # Package collections
│   └── productivity/
│       └── communication.nix # Messaging & communication apps
├── devshells/                # Development environments
├── scripts/                  # Utility scripts
└── flake.nix                 # Main flake
```

## 📖 Usage Examples

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

# Configure and launch games
league-setup
league-launch
```

## 🔧 Troubleshooting

### Common Issues

#### Wine/Gaming Issues

**Problem:** Wine prefix architecture mismatch

```bash
# Error: "64-bit installation, it cannot be used with a 32-bit wineserver"
```

**Solution:**

```bash
# Remove existing prefix and recreate as 32-bit
rm -rf ~/.wine-league
export WINEPREFIX=~/.wine-league
export WINEARCH=win32
wineboot -i
```

**Problem:** League of Legends installer not found

```bash
# Error: "failed to open LeagueInstaller.exe"
```

**Solution:**

1. Download from [Riot Games](https://signup.leagueoflegends.com/en-us/download/)
2. Place in `~/Downloads/` directory
3. Run: `wine ~/Downloads/LeagueInstaller.exe`

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

#### Gaming Performance

```bash
# Enable GameMode for CPU/GPU optimization
gamemoderun mangohud wine LeagueClient.exe

# Monitor performance
mangohud --dlsym

# Check Vulkan support
vulkaninfo
```

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

---

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
A: Follow the [Quick Start](#-quick-start) guide. For new users, clone the repo and use the safe configuration template.

**Q: Can I use nix-mox with my existing NixOS configuration?**
A: Yes, you can import nix-mox modules into your existing configuration or use it as a complete replacement.

**Q: What if I don't want all the features?**
A: Use the [Fragment System](#-fragment-system) to compose only the modules you need.

### Gaming Support

**Q: Does nix-mox support gaming on Linux?**
A: Yes, nix-mox includes comprehensive gaming support with Wine, DXVK, Steam, Lutris, and performance optimization tools.

**Q: Can I play Windows games like League of Legends?**
A: Yes, the gaming shell includes Wine configuration and tools specifically for Windows games.

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
A: Use GameMode and MangoHud as shown in the [Gaming Support](#-gaming-support) section.

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

---

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

## 🏗️ Templates

Pre-built configurations for common use cases:

- **Safe Configuration**: Complete desktop setup with display safety and messaging support
- **CI Runner**: High-performance CI/CD environment
- **Web Server**: Production web server configuration
- **Database**: Database server setup
- **Monitoring**: Prometheus/Grafana stack
- **Load Balancer**: HAProxy configuration

## 🧪 Testing

```bash
nix flake check .#checks.x86_64-linux.unit
nix flake check .#checks.x86_64-linux.integration
nix flake check .#checks.x86_64-linux.test-suite
```

## 📚 Documentation

- [Usage Guide](docs/USAGE.md)
- [Examples](docs/examples/)
- [Guides](docs/guides/)
- [Architecture](docs/architecture/)
- [API Reference](docs/api/)

## 🤝 Contributing

```bash
# Setup development environment
nix develop .#development
pre-commit install
just test
```

## 📄 License & Links

**License:** MIT License - see [LICENSE](LICENSE)

**Links:**

- [GitHub](https://github.com/Hydepwns/nix-mox)
- [Issues](https://github.com/Hydepwns/nix-mox/issues)
- [Discussions](https://github.com/Hydepwns/nix-mox/discussions)
