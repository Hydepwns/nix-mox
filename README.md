# nix-mox

> Proxmox templates + NixOS workstation + Windows gaming automation

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Installation](#installation)
  - [Prerequisites](#prerequisites)
  - [Optional Dependencies](#optional-dependencies)
  - [Installation Methods](#installation-methods)
- [Usage](#usage)
  - [Command Line Interface](#command-line-interface)
  - [Scripts](#scripts)
  - [Logging](#logging)
- [Development](#development)
  - [Development Shells](#development-shells)
  - [Script Development](#script-development)
  - [Testing](#testing)
  - [Architecture](#architecture)
- [Hardware & Driver Support](#hardware-and-driver-support)

## Overview

nix-mox is a comprehensive toolkit for managing Proxmox environments, NixOS workstations, and Windows gaming setups. It provides automation scripts, templates, and configurations to streamline your infrastructure management.

## Features

- 🖥️ **Proxmox Management**
  - Automated VM and container templates
  - Backup and snapshot management
  - Network configuration tools

- 🎮 **Windows Gaming**
  - Automated Steam and Rust installation
  - Performance optimization scripts
  - Gaming VM templates

- 🔧 **NixOS Integration**
  - System configuration modules
  - Development environment setup
  - Package management tools

- 📝 **Enhanced Scripting**
  - Platform-specific automation
  - Comprehensive logging
  - Error handling
  - Testing framework

## Installation

### Prerequisites

Before installing nix-mox, ensure you have the following:

- **Nix Package Manager**: Required for all nix-mox functionality

  ```bash
  sh <(curl -L https://nixos.org/nix/install) --daemon
  ```

  > **macOS Troubleshooting:**
  >
  > - If you have previously installed Nix, you may need to clean up remnants before reinstalling. Follow the official [Nix uninstall guide](https://nixos.org/manual/nix/stable/installation/uninstall.html) to remove old files and users. For example, run:
  >
  > ```bash
  > # Remove old Nix files
  > sudo rm -rf /nix
  > sudo rm -rf /etc/nix
  > sudo rm -rf /var/root/.nix-profile
  > ```
  >
  > - After installation, you must **restart your terminal** (or run `source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh`) to make Nix commands available.
  > - If you see errors like `command not found: nix-shell` after install, your shell may not be loading the Nix profile. Ensure your shell config (e.g., `.zshrc`, `.bashrc`) includes the Nix profile snippet added by the installer.
  > - For more help, see the [Nix on macOS troubleshooting page](https://nixos.org/manual/nix/stable/installation/#sect-macos-troubleshooting)

- **Nushell**: Required for running automation scripts and tests

  ```bash
  nix profile install nixpkgs#nushell
  ```

### Optional Dependencies

Depending on your use case, you may need:

- **Proxmox VE**: For VM and container management
- **NixOS**: For NixOS-specific features
- **Windows VM**: For Windows gaming automation
- **ZFS**: For snapshot management

### Installation Methods

#### For NixOS Systems

Add nix-mox to your system configuration by updating your `flake.nix`:

```nix
{
  inputs.nix-mox.url = "github:hydepwns/nix-mox";
  
  outputs = { self, nixpkgs, nix-mox, ... }: {
    nixosConfigurations.your-host = nixpkgs.lib.nixosSystem {
      modules = [
        nix-mox.nixosModules.nix-mox
      ];
    };
  };
}
```

#### For Other Systems

Install nix-mox directly using Nix:

```bash
nix profile install github:hydepwns/nix-mox
```

## Usage

### Development Shells

nix-mox provides specialized development shells for different purposes:

```bash
# Default shell with basic tools
nix develop

# Enhanced development environment
nix develop .#development

# Testing environment with Elixir and test tools
nix develop .#testing

# Service development and management
nix develop .#services

# Monitoring and observability
nix develop .#monitoring

# ZFS development and testing (Linux only)
nix develop .#zfs

# Gaming environment with Steam, Wine, and more (Linux only)
nix develop .#gaming

# macOS development environment (macOS only)
nix develop .#macos
```

Each shell comes with its own set of tools and helpful documentation. For example:

- The testing shell includes Elixir, Erlang, and test tools
- The gaming shell includes Steam, Wine, and gaming utilities
- The development and macOS shells include:
  - Core development tools (git, nix, nixpkgs-fmt)
  - code-cursor editor for AI-powered code navigation and editing
  - macOS-specific frameworks (macOS shell)
  - Common development tools (vscode, jq, yq, curl)
  - Terminal tools (tmux, zsh, oh-my-zsh)
  - System monitoring tools (htop)

### Command Line Interface

nix-mox provides a powerful command-line interface. The main entrypoint is now a bash wrapper script (`modules/scripts/nix-mox`) that ensures robust argument passing to the Nushell automation script.

**Usage:**

```bash
# Recommended (works on all systems)
./modules/scripts/nix-mox --script install --dry-run
```

> **Note:** The wrapper script sets up argument passing for all Nushell versions and platforms. You no longer need to worry about double-dash (`--`) or Nushell quirks.

Options:
  -h, --help           Show help message
  --dry-run           Show what would be done without making changes
  --debug             Enable debug output
  --platform <os>     Specify platform (auto, linux, darwin, nixos)
  --script <name>     Run specific script (install, update, zfs-snapshot)
  --log <file>        Log output to file

### Platform & OS Info
- When running a script, nix-mox now prints detailed OS info (distro, version, kernel) for Linux/NixOS, macOS, or Windows.
- NixOS is now fully supported and detected as a Linux platform.

### Error Handling & Logging
- All error handling and logging is robust and platform-aware.
- Errors are clearly reported, and logs can be written to a file with `--log <file>`.

### Scripts

#### Package Installation

```bash
# Basic installation
./modules/scripts/nix-mox --script install

# Platform-specific package installation
./modules/scripts/nix-mox --script install --platform linux

# Package installation with logging
./modules/scripts/nix-mox --script install --log install.log
```

#### Package Updates

```bash
# Update all packages
./modules/scripts/nix-mox --script update

# Update with debug output
./modules/scripts/nix-mox --script update --debug
```

#### ZFS Snapshot Management

```bash
# Create snapshots
./modules/scripts/nix-mox --script zfs-snapshot

# Dry run snapshot creation (no changes made)
./modules/scripts/nix-mox --script zfs-snapshot --dry-run
```

### Logging

nix-mox provides comprehensive logging capabilities:

```bash
# Log to file
./modules/scripts/nix-mox --script install --log install.log

# Enable debug output (more verbose output)
./modules/scripts/nix-mox --script update --debug
```

### Gaming Shell & Windows Games

nix-mox now includes a dedicated gaming shell for Linux gaming and Windows games (like League of Legends) via Wine and Lutris:

```bash
# Enter the gaming shell
nix develop .#gaming
```

- Includes Steam, Wine, Lutris, MangoHud, GameMode, DXVK, VKD3D, and more
- Helper scripts for Wine and League of Legends setup:
  - `nix run .#configure-wine` (general Wine gaming config)
  - `bash devshells/gaming/scripts/configure-league.sh` (League-specific setup)
- See [Gaming Setup Guide](./docs/gaming/README.md) for full instructions, troubleshooting, and optimization tips

## Development

### devshells

nix-mox provides several specialized development shells:

- **default**: Basic development environment with essential tools
- **development**: Enhanced development environment with additional tools
- **testing**: Testing environment with Elixir and test tools
- **services**: Service development and management tools
- **monitoring**: Monitoring and observability tools
- **zfs**: ZFS development and testing tools

Each shell includes:

- Platform-specific tools
- Development utilities
- Documentation and examples
- Helpful shell hooks

### Script Development

See [Script Development Guide](./docs/guides/scripting.md) for detailed information about:

- Script structure
- Common utilities
- Platform support
- Best practices

### Testing

The testing environment includes:

- Nushell Tests (unit, integration, performance)
- NixOS Module Tests
- Build Verification
- Code Quality Checks

To run tests:

```bash
# Enter the testing shell
nix develop .#testing

# Run tests with summarization
./modules/scripts/testing/summarize-tests.sh
```

See [Testing Guide](./docs/guides/testing.md) for more information.

### Architecture

See [Script Architecture](./docs/architecture/scripts.md) for details about:

- Core components
- Script types
- Error handling
- Logging system

## Project Structure

```bash
nix-mox/
├── .github/           # GitHub workflows and templates
├── config/           # Configuration files
├── devshells/        # Development shells
│   ├── default.nix   # Default shell configuration
│   ├── development/  # Development environment
│   ├── testing/      # Testing environment
│   ├── services/     # Service development
│   ├── monitoring/   # Monitoring tools
│   └── storage/      # Storage tools
├── docs/             # Documentation
│   ├── guides/      # User guides
│   ├── api/         # API documentation
│   ├── examples/    # Example configurations
│   └── development/ # Development documentation
├── lib/              # Library code and utilities
├── modules/          # NixOS modules
│   ├── core/        # Core functionality
│   ├── services/    # Service-specific modules
│   ├── storage/     # Storage-related modules
│   └── scripts/     # Platform-specific scripts
│       ├── testing/ # Testing infrastructure
│       │   ├── fixtures/    # Test fixtures
│       │   ├── integration/ # Integration tests
│       │   ├── lib/        # Test utilities
│       │   ├── storage/    # Storage tests
│       │   └── unit/       # Unit tests
│       ├── linux/   # Linux scripts
│       └── windows/ # Windows scripts
├── packages/         # Package definitions
│   ├── linux/       # Linux packages
│   └── windows/     # Windows packages
└── templates/        # Templates
    ├── nixos/       # NixOS templates
    ├── windows/     # Windows templates
    └── common/      # Shared template components
```

## Quick Start

```bash
# Clone & enter
git clone https://github.com/hydepwns/nix-mox.git
cd nix-mox

# Explore available shells
nix flake show

# Enter development shell
nix develop .#development

# Run tests
nix develop .#testing
./modules/scripts/testing/summarize-tests.sh
```

## Documentation

- [**USAGE.md**](./docs/USAGE.md) - Installation & usage
- [**ARCHITECTURE.md**](./docs/ARCHITECTURE.md) - System design
- [**ROADMAP.md**](./docs/ROADMAP.md) - Future plans
- [**Script Development Guide**](./docs/guides/scripting.md) - Script development
- [**Testing Guide**](./docs/guides/testing.md) - Testing framework
- [**Script Architecture**](./docs/architecture/scripts.md) - Script system design
- [**Gaming Setup Guide**](./docs/gaming/README.md) - Linux & Windows gaming, League of Legends, Wine/Lutris
- [**Hardware Drivers Guide**](./docs/guides/drivers.md) - configuring NVIDIA, AMD, and Intel drivers
