# nix-mox Usage Guide

> Production-grade NixOS configuration framework with templates and personal data separation.

## Quick Start

```bash
git clone https://github.com/your-org/nix-mox.git
cd nix-mox

# Setup personal configuration
nu scripts/setup.nu

# Choose template
cp config/templates/development.nix config/nixos/configuration.nix

# Build and switch
sudo nixos-rebuild switch --flake .#nixos
```

## Templates

| Template | Use Case | Description |
|----------|----------|-------------|
| `minimal` | Basic system | Essential tools only |
| `development` | Software development | IDEs, tools, containers |
| `gaming` | Gaming workstation | Steam, performance optimizations |
| `server` | Production server | Monitoring, management tools |
| `desktop` | Daily use | Full desktop environment |

## Configuration Structure

```
config/
├── personal/     # Your settings (gitignored)
├── templates/    # Ready-to-use configs
├── profiles/     # Shared components
└── nixos/        # Main config
```

## Personal Configuration

### Setup Personal Settings
```bash
# Interactive setup
nu scripts/setup.nu

# Manual setup
cp env.example .env
nano .env
```

### Customize Personal Settings
```nix
# config/personal/user.nix
environment.systemPackages = with pkgs; [
  # Your personal packages here
  my-favorite-app
  another-tool
];
```

### Hardware Configuration
```nix
# config/personal/hardware.nix
# Enable NVIDIA drivers
services.xserver.videoDrivers = [ "nvidia" ];
hardware.nvidia = {
  modesetting.enable = true;
  powerManagement.enable = true;
};
```

## Advanced Features

## Multi-Host Management

For managing multiple NixOS hosts from a single flake, see the comprehensive [Multi-Host Guide](MULTI_HOST.md).

Basic multi-host commands:

```bash
# Build host configurations
nix build .#nixosConfigurations.host1.config.system.build.toplevel
nix build .#nixosConfigurations.host2.config.system.build.toplevel

# Deploy to hosts
nixos-rebuild switch --flake .#host1
nixos-rebuild switch --flake .#host2

# Remote deployment
nixos-rebuild switch --flake .#host1 --target-host user@host1.example.com
```


### Using Modules
```bash
# Interactive module integration
nu scripts/integrate-modules.nu

# Manual integration
# Edit template to include modules:
imports = [
  ../profiles/base.nix
  ../profiles/development.nix
  ../../modules/services/infisical.nix  # Advanced features
];
```

### Available Modules
- **services/infisical** - Secrets management
- **services/tailscale** - VPN connectivity
- **gaming** - Advanced gaming support
- **monitoring** - System monitoring
- **storage** - Storage management
- **packages/development** - Development packages
- **packages/gaming** - Gaming packages
- **security** - Security features

## Development

### Quick Development Commands

```bash
# Format all code
nix run .#fmt

# Run tests
nix run .#test

# Update flake inputs
nix run .#update

# Enter development shell
nix develop
```

### Development Shells
```bash
nix develop                    # Default environment
nix develop .#development      # Development tools
nix develop .#testing          # Testing tools
nix develop .#services         # Service tools (Linux)
nix develop .#monitoring       # Monitoring tools (Linux)
nix develop .#gaming           # Gaming tools (Linux)
nix develop .#macos            # macOS tools (macOS)
```

### Code Formatting

The project uses `treefmt` for multi-language formatting:

```bash
# Format all files
nix run .#fmt

# Check formatting without changes
nix run .#formatter -- --check

# Format specific files
nix run .#formatter -- path/to/file.nix
```

**Supported formats:**
- **Nix** (`.nix`) - `nixpkgs-fmt`
- **Shell scripts** (`.sh`, `.bash`, `.zsh`) - `shfmt` + `shellcheck`
- **Markdown** (`.md`, `.mdx`) - `prettier`
- **JSON/YAML** (`.json`, `.yml`, `.yaml`) - `prettier`
- **JavaScript/TypeScript** (`.js`, `.ts`, `.jsx`, `.tsx`) - `prettier`
- **CSS/SCSS** (`.css`, `.scss`, `.sass`) - `prettier`
- **HTML** (`.html`, `.htm`) - `prettier`
- **Python** (`.py`) - `black`
- **Rust** (`.rs`) - `rustfmt`
- **Go** (`.go`) - `gofmt`

### Testing
```bash
# Run all tests
nix run .#test

# Run specific test suites
nix build .#checks.x86_64-linux.unit
nix build .#checks.x86_64-linux.integration
nix build .#checks.x86_64-linux.test-suite

# Platform-specific tests
nix build .#checks.x86_64-linux.linux-specific
nix build .#checks.x86_64-darwin.macos-specific

# Run tests with make (legacy)
make test
make unit
make integration
```

## Package Management

### Linux Packages
```bash
# System management
nix run .#proxmox-update      # Update Proxmox host
nix run .#vzdump-backup       # Backup VMs and containers
nix run .#zfs-snapshot        # Manage ZFS snapshots
nix run .#nixos-flake-update  # Update NixOS flake

# Build packages
nix build .#proxmox-update
nix build .#vzdump-backup
nix build .#zfs-snapshot
nix build .#nixos-flake-update
```

### macOS Packages
```bash
# macOS management
nix run .#homebrew-setup      # Setup Homebrew
nix run .#macos-maintenance   # macOS maintenance
nix run .#xcode-setup         # Setup Xcode
nix run .#security-audit      # Security audit

# Build packages
nix build .#homebrew-setup
nix build .#macos-maintenance
nix build .#xcode-setup
nix build .#security-audit
```

### Installation Packages
```bash
# Installation
nix run .#install             # Install nix-mox
nix run .#uninstall           # Uninstall nix-mox

# Build installation packages
nix build .#install
nix build .#uninstall
```

## Environment Configuration

Key environment variables:
- `NIXMOX_ENV` - Environment type (personal/development/production)
- `NIXMOX_USERNAME` - Your username
- `NIXMOX_EMAIL` - Your email
- `NIXMOX_TIMEZONE` - Your timezone
- `INITIAL_PASSWORD` - Initial user password

## Security Features

- **Personal data separation** - Personal settings in `config/personal/`
- **Secrets management** - Sensitive files are gitignored
- **Environment-based config** - Different settings for different environments
- **Security hardening** - Built-in security profiles

## Troubleshooting

### Configuration Issues
```bash
# Check configuration syntax
nixos-rebuild dry-activate --flake .#nixos

# View configuration errors
nixos-rebuild build --flake .#nixos 2>&1 | less
```

### Personal Configuration
```bash
# Regenerate personal configuration
nu scripts/setup.nu

# Check environment variables
cat .env
```

### Template Issues
```bash
# Switch to minimal template for testing
cp config/templates/minimal.nix config/nixos/configuration.nix
sudo nixos-rebuild switch --flake .#nixos
```

### Module Integration Issues
```bash
# Check module availability
nu scripts/integrate-modules.nu

# Reintegrate modules
nu scripts/integrate-modules.nu
```

## Examples

### Basic Development Setup
```nix
# config/nixos/configuration.nix
{ config, pkgs, ... }:
{
  imports = [
    ../profiles/base.nix
    ../profiles/security.nix
    ../profiles/development.nix
  ];
}
```

### Gaming Setup with Modules
```nix
# config/nixos/configuration.nix
{ config, pkgs, ... }:
{
  imports = [
    ../profiles/base.nix
    ../profiles/security.nix
    ../profiles/gaming.nix
    ../../modules/gaming/index.nix
  ];
}
```

### Server Setup with Monitoring
```nix
# config/nixos/configuration.nix
{ config, pkgs, ... }:
{
  imports = [
    ../profiles/base.nix
    ../profiles/security.nix
    ../profiles/server.nix
    ../../modules/monitoring/index.nix
  ];
}
```

## Next Steps

1. **Review templates** - Check `config/templates/` for available options
2. **Customize profiles** - Modify `config/profiles/` for shared settings
3. **Add personal packages** - Edit `config/personal/user.nix`
4. **Configure hardware** - Edit `config/personal/hardware.nix`
5. **Set up secrets** - Configure `config/personal/secrets.nix`
6. **Explore modules** - Use `nu scripts/integrate-modules.nu` for advanced features

## Support

- **Documentation** - Check `docs/` for detailed guides
- **Issues** - Report problems on GitHub
- **Discussions** - Ask questions in GitHub Discussions

---

**Note**: This is a production-grade framework. Personal data is properly separated and secured. Always review configuration files before committing to version control.
