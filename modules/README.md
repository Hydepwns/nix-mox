# Nix-Mox Modules

This directory contains all the modules used by nix-mox. Each module is organized by its functionality and purpose.

## Directory Structure

```bash
modules/
├── core/                 # Core functionality and base modules
├── system/              # System-level configurations
│   ├── networking/      # Network configuration modules
│   ├── hardware/        # Hardware-specific configurations
│   ├── boot/           # Bootloader and boot configuration
│   └── users/          # User management modules
├── services/            # Service-specific modules
├── storage/             # Storage-related modules
├── security/            # Security-related modules
├── monitoring/          # Monitoring and observability
├── gaming/              # Gaming-specific modules
├── packages/            # Package-specific modules
│   ├── development/     # Development tools
│   ├── multimedia/      # Media and entertainment
│   ├── productivity/    # Office and productivity tools
│   ├── system/         # System utilities
│   ├── linux/          # Linux-specific packages
│   └── windows/        # Windows-specific packages
└── templates/           # Template configurations
    ├── services/        # Service-specific templates
    ├── infrastructure/  # Infrastructure templates
    └── platforms/       # Platform-specific templates
```

## Using Modules

Each directory contains an `index.nix` file that exposes its modules. To use a module in your configuration:

1. Import the module through the flake:

```nix
{
  imports = [
    nix-mox.nixosModules.core
    nix-mox.nixosModules.services
    nix-mox.nixosModules.system
    # etc...
  ];
}
```

2. Or import specific modules directly:

```nix
{
  imports = [
    ./modules/services/infisical.nix
    ./modules/storage/zfs/auto-snapshot.nix
  ];
}
```

## Adding New Modules

To add a new module:

1. Create your module file in the appropriate directory
2. Add it to that directory's `index.nix`
3. The module will be automatically available through the main flake

Example of adding a new service module:

```nix
# modules/services/my-service.nix
{ config, pkgs, ... }:
{
  # Your module configuration
}

# modules/services/index.nix
{
  infisical = import ./infisical.nix;
  tailscale = import ./tailscale.nix;
  my-service = import ./my-service.nix;  # Add your new module here
}
```

## Module Categories

### Core Modules

- **core/**: Fundamental modules that provide base functionality and essential system components

### System Modules

- **system/**: System-level configurations for hardware and networking
  - **networking/**: Network configuration modules with comprehensive network setup
  - **hardware/**: Hardware-specific configurations including CPU, GPU, storage, and input devices
  - **boot/**: Bootloader and boot configuration for various systems
  - **users/**: User management modules with authentication and access control

### Service Modules

- **services/**: Service-specific modules for various applications and infrastructure
  - **infisical.nix**: Secret management and configuration
  - **tailscale.nix**: VPN and secure networking
  - **fragments/**: Modular service configurations for easy composition

### Storage Modules

- **storage/**: Storage-related modules including ZFS, backup systems, and storage optimization
  - **backup/**: Automated backup solutions
  - **fragments/**: Modular storage configurations
  - **templates/**: Pre-configured storage setups

### Security Modules

- **security/**: Security-related modules for encryption, access control, and system hardening
  - **access/**: Access control and authentication systems
  - **encryption/**: Disk encryption and key management
  - Complete security framework with firewall, monitoring, and logging

### Monitoring Modules

- **monitoring/**: Monitoring and observability modules
  - **logging/**: Centralized logging solutions
  - **metrics/**: Performance and system metrics collection
  - Comprehensive monitoring stack with Prometheus, Grafana, and alerting

### Gaming Modules

- **gaming/**: Gaming-specific modules for Steam, Wine, and performance tuning
  - Complete gaming environment with Wine, DXVK, and performance optimization
  - Game launcher support (Steam, Lutris, Heroic)
  - Performance tools (MangoHud, GameMode, Vulkan Tools)

### Package Modules

- **packages/**: Package-specific modules organized by functionality
  - **development/**: Comprehensive development toolchain with IDEs, compilers, and debugging tools
  - **multimedia/**: Media and entertainment packages
  - **productivity/**: Office and productivity tools
  - **system/**: System utilities and management tools
  - **linux/**: Linux-specific packages
  - **windows/**: Windows-specific packages
  - **error-handling/**: Error handling and diagnostic tools

### Template Modules

- **templates/**: Template configurations organized by category
  - **base/**: Complete base configurations with common fragments
  - **services/**: Service-specific templates
  - **infrastructure/**: Infrastructure templates for various deployment scenarios
  - **platforms/**: Platform-specific templates (NixOS, Windows, macOS)

Each category has its own README.md with more specific information about its contents and usage.

## Complete Module Implementations

### Development Packages Module

Located at `modules/packages/development/index.nix`, this module provides:

- **IDEs and Editors**: VSCode, IntelliJ, Vim, Emacs
- **Programming Languages**: Comprehensive language support with compilers and interpreters
- **Debugging Tools**: Advanced debugging and profiling capabilities
- **Version Control**: Git and collaboration tools
- **Database Tools**: Database development and management utilities
- **API Development**: Tools for building and testing APIs

### Hardware System Module

Located at `modules/system/hardware/index.nix`, this module includes:

- **CPU Configuration**: Processor-specific optimizations and settings
- **GPU Management**: Graphics card configuration and driver setup
- **Storage Devices**: Disk management and optimization
- **Network Interfaces**: Network hardware configuration
- **Audio/Video**: Multimedia hardware support
- **Input Devices**: Keyboard, mouse, and other input device configuration
- **Power Management**: System power optimization settings

### Security Module

Located at `modules/security/index.nix`, this module provides:

- **Firewall Configuration**: Comprehensive network security
- **Access Control**: User authentication and authorization
- **Encryption**: Disk and file encryption capabilities
- **Security Monitoring**: Real-time security event monitoring
- **Network Security**: Advanced network security policies
- **System Hardening**: Security best practices and hardening measures

## Module Metadata

Each module should include consistent metadata in comments:

```nix
# modules/services/example.nix
{ config, pkgs, ... }:
{
  # Module: Example Service
  # Category: Services
  # Platform: Linux
  # Dependencies: None
  # Description: Example service configuration
  
  # ... module content
}
```

## Template-Based Hardware Configuration

The hardware configuration system uses a template-based approach:

- **Template**: `config/hardware/hardware-configuration.nix` - Single source of truth for hardware configuration
- **Generated**: `config/hardware/hardware-configuration-actual.nix` - Auto-generated from system detection
- **Benefits**: Eliminates duplication, provides clear separation, enables easy migration and updates

## Platform-Specific Scripts

The main automation entrypoint is the bash wrapper script for robust CLI usage:

```bash
# Main CLI entrypoint (robust argument passing)
./nix-mox --script install --dry-run
```

**Available Scripts:**

- **nix-mox**: Bash wrapper (recommended for all CLI usage)
- **nix-mox.nu**: Nushell automation logic (called by the wrapper)
- **setup-wizard.nu**: Interactive configuration wizard
- **health-check.nu**: System health diagnostics
- **linux/**: Linux-specific scripts (backup, update, ZFS, install, etc.)
- **windows/**: Windows-specific scripts

> The wrapper ensures all arguments are passed correctly to the automation logic, regardless of Nushell version or platform.

## Benefits

### For New Users

- **Simplified Setup**: Interactive wizard guides through configuration
- **Reduced Errors**: Template-based approach minimizes configuration mistakes
- **Complete Coverage**: All major use cases supported with comprehensive modules

### For Existing Users

- **System Validation**: Health check ensures configuration integrity
- **Easy Troubleshooting**: Comprehensive diagnostics and recommendations
- **Modular Design**: Mix and match components as needed

### For Developers

- **Consistent Interface**: Standardized module structure and metadata
- **Extensible Architecture**: Easy to add new modules and features
- **Comprehensive Documentation**: Detailed guides and examples for all components
