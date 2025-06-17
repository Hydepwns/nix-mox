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

# ZFS development and testing
nix develop .#zfs

# Gaming environment with Steam, Wine, and more
nix develop .#gaming
```

Each shell comes with its own set of tools and helpful documentation. For example, the testing shell includes:

- Elixir and Erlang for running tests
- Test summarization tools
- BATS for shell script testing
- Code quality tools

### Command Line Interface

nix-mox provides a powerful command-line interface:

```bash
nix-mox [options] [script]

Options:
  -h, --help           Show help message
  --dry-run           Show what would be done without making changes
  --debug             Enable debug output
  --platform <os>     Specify platform (auto, linux, darwin)
  --script <name>     Run specific script (install, update, zfs-snapshot)
  --log <file>        Log output to file
```

### Scripts

#### Package Installation

```bash
# Basic installation
nix-mox --script install

# Platform-specific package installation
nix-mox --script install --platform linux

# Package installation with logging
nix-mox --script install --log install.log
```

#### Package Updates

```bash
# Update all packages
nix-mox --script update

# Update with debug output
nix-mox --script update --debug
```

#### ZFS Snapshot Management

```bash
# Create snapshots
nix-mox --script zfs-snapshot

# Dry run snapshot creation (no changes made)
nix-mox --script zfs-snapshot --dry-run
```

### Logging

nix-mox provides comprehensive logging capabilities:

```bash
# Log to file
nix-mox --script install --log install.log

# Enable debug output (more verbose output)
nix-mox --script update --debug
```

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

- Elixir and Erlang for running tests
- Test summarization tools
- BATS for shell script testing
- Code quality tools

To run tests:

```bash
# Enter the testing shell
nix develop .#testing

# Run tests with summarization
./tests/summarize-tests.sh
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
│   └── storage/     # Storage-related modules
├── packages/         # Package definitions
│   ├── linux/       # Linux packages
│   └── windows/     # Windows packages
├── scripts/          # Scripts
│   ├── core/        # Core scripts
│   ├── handlers/    # Event handlers
│   ├── lib/         # Script utilities
│   ├── linux/       # Linux scripts
│   └── windows/     # Windows scripts
├── templates/        # Templates
│   ├── nixos/       # NixOS templates
│   ├── windows/     # Windows templates
│   └── common/      # Shared template components
└── tests/            # Tests
    ├── linux/       # Linux-specific tests
    ├── windows/     # Windows-specific tests
    ├── integration/ # Integration tests
    └── unit/        # Unit tests
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
./tests/summarize-tests.sh
```

## Documentation

- [**USAGE.md**](./docs/USAGE.md) - Installation & usage
- [**ARCHITECTURE.md**](./docs/ARCHITECTURE.md) - System design
- [**ROADMAP.md**](./docs/ROADMAP.md) - Future plans
- [**Script Development Guide**](./docs/guides/scripting.md) - Script development
- [**Testing Guide**](./docs/guides/testing.md) - Testing framework
- [**Script Architecture**](./docs/architecture/scripts.md) - Script system design
