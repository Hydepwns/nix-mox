# nix-mox

> Enterprise-grade NixOS gaming workstation configuration with comprehensive safety features and automation.

[![CI](https://github.com/Hydepwns/nix-mox/workflows/CI%20(Simplified)/badge.svg)](https://github.com/Hydepwns/nix-mox/actions/workflows/ci.yml)
[![Platforms](https://img.shields.io/badge/platforms-linux%20%7C%20macos%20%7C%20windows-blue.svg)](https://github.com/Hydepwns/nix-mox/actions)
[![Tests](https://img.shields.io/badge/tests-100%25-brightgreen.svg)](https://github.com/Hydepwns/nix-mox/actions)

## Quick Start

### Prerequisites
- **NixOS** (fresh install with working display)  
- User account: `hydepwns` (primary user)
- Basic shell access (no additional packages required initially)

### Safe Bootstrap Process

```bash
# 1. Clone repository
git clone https://github.com/hydepwns/nix-mox.git
cd nix-mox

# 2. CRITICAL: Check bootstrap requirements first  
./bootstrap-check.sh

# 2b. Optional: See all available commands
./quick-commands.sh

# 3. Install missing prerequisites if needed (from bootstrap-check.sh output)
nix-shell -p git nushell

# 4. MANDATORY: Validate system safety before any changes  
nix-shell -p nushell --run "nu scripts/validation/pre-rebuild-safety-check.nu --verbose"

# 5. Run working setup scripts:
# Option A: Unified setup (RECOMMENDED - all-in-one solution)
nix-shell -p nushell --run "nu scripts/setup/unified-setup.nu"

# Option B: Manual install + setup  
nix-shell -p nushell --run "nu scripts/setup/simple-install.nu --create-dirs"
nix-shell -p nushell --run "nu scripts/setup/simple-setup.nu"

# Note: Legacy setup scripts have been removed or fixed
# All setup scripts now work correctly

# 7. Before rebuilding system, run safety check again
nix-shell -p nushell --run "nu scripts/validation/pre-rebuild-safety-check.nu"

# 8. CRITICAL: Validate storage configuration before reboot
nix run .#storage-guard

# 9. Use SAFE rebuild wrapper (never direct nixos-rebuild!)
nix-shell -p nushell --run "nu scripts/maintenance/safe-rebuild.nu --backup --test-first"
```

**CRITICAL**: 
- ALWAYS run `./bootstrap-check.sh` first on fresh systems
- NEVER run `nixos-rebuild` directly - use the safe wrapper 
- ALWAYS run `nix run .#storage-guard` before rebooting
- This prevents boot failures and display issues

## Features

| Category | Features |
|----------|----------|
| **Gaming** | ![Steam](https://img.shields.io/badge/Steam-Optimized-blue) ![Lutris](https://img.shields.io/badge/Lutris-Supported-orange) ![GameMode](https://img.shields.io/badge/GameMode-Enabled-green) ![Hardware Auto-Detect](https://img.shields.io/badge/Hardware-Auto--Detect-purple) |
| **Security** | ![Agenix](https://img.shields.io/badge/Secrets-Encrypted-red) ![Auto-Rollback](https://img.shields.io/badge/Auto--Rollback-3%20Attempts-orange) ![Backup](https://img.shields.io/badge/Backup-Automated-green) |
| **Performance** | ![CPU Governor](https://img.shields.io/badge/CPU-Performance-blue) ![Zram](https://img.shields.io/badge/Zram-Compressed-green) ![Network](https://img.shields.io/badge/Network-BBR-purple) ![SSD](https://img.shields.io/badge/SSD-Optimized-orange) |
| **Setup** | ![Wizard](https://img.shields.io/badge/Wizard-Interactive-blue) ![Auto-Detection](https://img.shields.io/badge/Auto--Detection-Smart-green) ![Defaults](https://img.shields.io/badge/Defaults-Platform--Adaptive-purple) |
| **DevEx** | ![Modular](https://img.shields.io/badge/Architecture-Modular-blue) ![Subflakes](https://img.shields.io/badge/Subflakes-Ready-green) ![Testing](https://img.shields.io/badge/Testing-Comprehensive-orange) |

## Documentation

- **[Quick Start Guide](docs/QUICK_START.md)** - Get started in minutes
- **[Platform Guide](docs/PLATFORM.md)** - Platform-specific setup
- **[Templates Guide](docs/TEMPLATES.md)** - Available configurations
- **[Storage Safety Guide](docs/STORAGE_SAFETY.md)** - Prevent boot failures
- **[VS Code Extension](docs/VSCODE_EXTENSION.md)** - IDE integration
- **[Zed Extension](docs/ZED_EXTENSION.md)** - Zed editor integration
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Common issues and solutions

## Development

```bash
# Enter dev environment
nix develop

# Quick commands
nix run .#fmt           # Format code
nix run .#validate      # Validate configuration
nix run .#update        # Update flake inputs
nix run .#storage-guard # Validate storage before reboot

# New features
nixos-backup     # Run manual backup
nixos-restore    # Restore from backup
rollback-status  # Check auto-rollback status
secrets-init     # Initialize secrets management
secrets-edit     # Edit encrypted secrets

# Test new structure
nu scripts/testing/test-new-structure.nu
```

## Multi-Host Management

```bash
# Build configurations
nix build .#nixosConfigurations.host1.config.system.build.toplevel
nix build .#nixosConfigurations.host2.config.system.build.toplevel

# Deploy
nixos-rebuild switch --flake .#host1
nixos-rebuild switch --flake .#host2
```

### Host Configuration

```nix
# config/hosts.nix
{
  host1 = {
    system = "x86_64-linux";
    hardware = ./hardware/host1-hardware-configuration.nix;
    home = ./home/host1-home.nix;
    extraModules = [ ./modules/host1-extra.nix ];
    specialArgs = { hostType = "desktop"; };
  };
}
```

## Available Packages

### Linux

```bash
nix run .#proxmox-update      # Update Proxmox
nix run .#vzdump-backup       # Backup VMs
nix run .#zfs-snapshot        # ZFS snapshots
nix run .#nixos-flake-update  # Update flake
```

### macOS

```bash
nix run .#homebrew-setup      # Setup Homebrew
nix run .#macos-maintenance   # Maintenance
nix run .#xcode-setup         # Setup Xcode
nix run .#security-audit      # Security audit
```

## Maintenance

```bash
nu scripts/maintenance/cleanup.nu           # Project cleanup
nu scripts/maintenance/health-check.nu       # Health validation
nu scripts/analysis/analyze-sizes.nu     # Size analysis
```

## Templates

| Template | Use Case |
|----------|----------|
| ![Minimal](https://img.shields.io/badge/Minimal-Basic%20System-blue) | ![System](https://img.shields.io/badge/System-Essential%20Tools-lightgrey) |
| ![Development](https://img.shields.io/badge/Development-Software%20Dev-green) | ![Tools](https://img.shields.io/badge/Tools-IDEs%20%7C%20Containers-orange) |
| ![Gaming](https://img.shields.io/badge/Gaming-Workstation-purple) | ![Performance](https://img.shields.io/badge/Performance-Steam%20%7C%20Optimized-red) |
| ![Server](https://img.shields.io/badge/Server-Production-yellow) | ![Management](https://img.shields.io/badge/Management-Monitoring%20%7C%20Tools-blue) |
| ![CI Runner](https://img.shields.io/badge/CI%20Runner-Infrastructure-orange) | ![Parallel](https://img.shields.io/badge/Parallel-Jobs%20%7C%20Metrics-green) |

## Development Shells

```bash
nix develop                    # Default
nix develop .#development      # Dev tools
nix develop .#gaming           # Gaming tools
nix develop .#testing          # Testing tools
nix develop .#services         # Service tools
nix develop .#monitoring       # Monitoring tools
```

## Structure

```
config/
├── personal/     # Your settings (gitignored)
├── templates/    # Ready-to-use configs
├── profiles/     # Shared components
└── nixos/        # Main config
```

## Code Formatting

```bash
nix run .#fmt  # Format all files
```

**Supported:** ![Nix](https://img.shields.io/badge/Nix-5277C3?style=flat&logo=nixos&logoColor=white) ![Shell](https://img.shields.io/badge/Shell-Bash%20%7C%20Zsh%20%7C%20Fish-4EAA25?style=flat&logo=gnu-bash&logoColor=white) ![Markdown](https://img.shields.io/badge/Markdown-000000?style=flat&logo=markdown&logoColor=white) ![JSON](https://img.shields.io/badge/JSON-000000?style=flat&logo=json&logoColor=white) ![YAML](https://img.shields.io/badge/YAML-CB171E?style=flat&logo=yaml&logoColor=white) ![JavaScript](https://img.shields.io/badge/JavaScript-F7DF1E?style=flat&logo=javascript&logoColor=black) ![TypeScript](https://img.shields.io/badge/TypeScript-3178C6?style=flat&logo=typescript&logoColor=white) ![CSS](https://img.shields.io/badge/CSS-1572B6?style=flat&logo=css3&logoColor=white) ![HTML](https://img.shields.io/badge/HTML-E34F26?style=flat&logo=html5&logoColor=white) ![Python](https://img.shields.io/badge/Python-3776AB?style=flat&logo=python&logoColor=white) ![Rust](https://img.shields.io/badge/Rust-000000?style=flat&logo=rust&logoColor=white) ![Go](https://img.shields.io/badge/Go-00ADD8?style=flat&logo=go&logoColor=white)

## Testing

```bash
nix run .#test                    # All tests
nix build .#checks.x86_64-linux.unit
nix build .#checks.x86_64-linux.integration
```

## 📄 License

MIT — see [LICENSE](LICENSE)
