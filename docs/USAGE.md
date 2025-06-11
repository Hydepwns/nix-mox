# Usage & Deployment Guide

Terse guide for deploying and using nix-mox automation scripts and infrastructure templates.

## Deployment Flow

```mermaid
flowchart TD
    A[Clone] --> B[Choose Method]
    B --> C{Nix Flake}
    B --> D[Manual Install]
    
    C --> E[Run Scripts]
    C --> F[Install Scripts]
    C --> G[Use Templates]
    
    D --> H[Install Scripts]
    D --> I[Use Templates]
    
    E --> J[System Ready]
    F --> J
    G --> J
    H --> J
    I --> J
```

## Quick Start

### 1. Clone

```bash
git clone https://github.com/hydepwns/nix-mox.git
cd nix-mox
```

### 2. Nix Flake (Recommended)

```bash
# Run scripts
nix run .#proxmox-update
nix run .#zfs-snapshot
nix run .#nixos-flake-update

# Install scripts
nix profile install .#proxmox-update
```

### 3. Manual Install (Legacy)

```bash
sudo nu scripts/linux/install.nu
```

## Module Integration

```mermaid
graph TD
    A[NixOS Config] --> B[Add Flake]
    B --> C[Import Modules]
    C --> D[Configure]
    
    D --> E[Common]
    D --> F[ZFS Snapshot]
    D --> G[Infisical]
    D --> H[Tailscale]
```

### Module Configuration

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

## Available Components

```mermaid
graph TD
    A[Components] --> B[Scripts]
    A --> C[Templates]
    A --> D[Modules]
    
    B --> B1[proxmox-update]
    B --> B2[vzdump-backup]
    B --> B3[zfs-snapshot]
    B --> B4[nixos-flake-update]
    
    C --> C1[Containers]
    C --> C2[VMs]
    C --> C3[Monitoring]
    C --> C4[Storage]
    
    D --> D1[Common]
    D --> D2[ZFS]
    D --> D3[Infisical]
    D --> D4[Tailscale]
```

## Template System

```mermaid
graph TD
    A[Template System] --> B[Enable]
    B --> C[Configure]
    C --> D[Use]
    
    C --> E[Options]
    C --> F[Variables]
    C --> G[Overrides]
    
    D --> H[Composition]
    D --> I[Inheritance]
```

### Template Configuration

```nix
services.nix-mox.templates = {
  enable = true;
  templates = [ "web-server" "database-management" ];
  customOptions = {
    web-server = {
      serverType = "nginx";
      enableSSL = true;
    };
  };
  templateVariables = {
    admin_user = "site-admin";
    domain = "example.com";
  };
};
```

## Development Flow

```mermaid
flowchart TD
    A[Development] --> B[Setup]
    B --> C[Test]
    C --> D[Contribute]
    
    B --> B1[Enter Env]
    B --> B2[Install Tools]
    
    C --> C1[Run Tests]
    C --> C2[Check Output]
    
    D --> D1[Fork]
    D --> D2[Branch]
    D --> D3[PR]
```

### Development Commands

```bash
# Enter environment
nix develop

# Run tests
nu scripts/run-tests.nu
nu scripts/run-tests.nu --verbose
nu scripts/run-tests.nu --module unit-tests

# Contribute
git checkout -b feature/your-feature
git commit -m "feat: your feature"
git push origin feature/your-feature
```

## Guides & References

```mermaid
graph TD
    A[Guides] --> B[NixOS on Proxmox]
    A --> C[Windows on Proxmox]
    A --> D[Windows Automation]
    A --> E[Advanced Config]
    
    B --> F[Deployment]
    C --> G[Setup]
    D --> H[Automation]
    E --> I[Networking]
    E --> J[Storage]
    E --> K[Security]
    E --> L[Monitoring]
```

## Examples

The `nixamples` directory contains comprehensive examples to help you get started:

```mermaid
graph TD
    A[Examples] --> B[Basic Usage]
    A --> C[Custom Options]
    A --> D[Composition]
    A --> E[Inheritance]
    A --> F[Variables]
    A --> G[Overrides]
    B --> H[Quick Start]
    C --> I[Configuration]
    D --> J[Stacks]
    E --> K[Security]
    F --> L[Dynamic]
    G --> M[Custom]
```

### Example Categories

1. **Basic Usage** (`01-basic-usage/`)
   - Simple template deployment
   - Basic configuration
   - Quick start guide

2. **Custom Options** (`02-custom-options/`)
   - Environment-specific settings
   - Multi-site configurations
   - Advanced features

3. **Template Composition** (`03-composition/`)
   - Web application stacks
   - Database configurations
   - Monitoring setups

4. **Template Inheritance** (`04-inheritance/`)
   - Security templates
   - Base configurations
   - Feature extensions

5. **Template Variables** (`05-variables/`)
   - Dynamic configurations
   - Environment variables
   - Secret management

6. **Template Overrides** (`06-overrides/`)
   - Custom configurations
   - File replacements
   - Conditional overrides

Each example includes:

- Visual diagrams
- Configuration snippets
- Practical use cases
- Verification steps
- Troubleshooting guides

## Development

```bash
# Enter development environment
nix develop

# Run tests
nu scripts/run-tests.nu

# Run specific test
nu scripts/run-tests.nu --test "test-name"
```

## Configuration

See [ARCHITECTURE.md](./ARCHITECTURE.md) for detailed configuration options.
