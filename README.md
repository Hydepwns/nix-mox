# nix-mox

A comprehensive NixOS configuration framework with development tools, monitoring, and system management utilities.

## 🚀 Quick Start

### For New Users

1. **Clone the repository:**

   ```bash
   git clone https://github.com/Hydepwns/nix-mox.git
   cd nix-mox
   ```

2. **Use the Safe Configuration Template:**

   ```bash
   # Copy the safe configuration template to your config directory
   cp -r modules/templates/nixos/safe-configuration/* config/
   
   # Generate your hardware configuration
   sudo nixos-generate-config --show-hardware-config > config/hardware-configuration.nix
   ```

3. **Customize your configuration:**
   - Edit `config/configuration.nix` to set your hostname, timezone, and preferences
   - Edit `config/home.nix` to configure your user settings
   - Update `config/flake.nix` if needed

4. **Deploy your configuration:**

   ```bash
   sudo nixos-rebuild switch --flake .#nixos
   ```

### For Existing Users

If you already have a NixOS configuration, you can integrate nix-mox tools:

1. **Add nix-mox to your flake inputs:**

   ```nix
   inputs.nix-mox = {
     url = "github:Hydepwns/nix-mox";
     inputs.nixpkgs.follows = "nixpkgs";
   };
   ```

2. **Add nix-mox packages to your system:**

   ```nix
   environment.systemPackages = with pkgs; [
     inputs.nix-mox.packages.${pkgs.system}.proxmox-update
     inputs.nix-mox.packages.${pkgs.system}.vzdump-backup
     inputs.nix-mox.packages.${pkgs.system}.zfs-snapshot
     inputs.nix-mox.packages.${pkgs.system}.nixos-flake-update
   ];
   ```

## 📁 Project Structure

```
nix-mox/
├── config/                    # Configuration directory (recommended for user configs)
│   ├── default.nix           # Default configuration settings
│   ├── build/                # Build-specific configurations
│   ├── configuration.nix     # Your NixOS configuration (if using template)
│   ├── home.nix              # Your home-manager configuration (if using template)
│   └── hardware-configuration.nix # Your hardware config (if using template)
├── modules/                   # Reusable NixOS modules
│   ├── core/                 # Core functionality
│   ├── packages/             # Package definitions
│   ├── services/             # Service definitions
│   ├── storage/              # Storage management
│   └── templates/            # Configuration templates
├── devshells/                # Development shell definitions
├── scripts/                  # Utility scripts
├── docs/                     # Documentation
└── flake.nix                 # Main flake definition
```

## 🛠️ Development Shells

Access specialized development environments:

```bash
# Default shell with basic tools
nix develop

# Specialized shells
nix develop .#development    # Development tools (just, pre-commit, gh)
nix develop .#testing        # Testing tools
nix develop .#services       # Service management tools
nix develop .#monitoring     # Monitoring tools
nix develop .#gaming         # Gaming development (Linux x86_64 only)
nix develop .#zfs            # ZFS tools (Linux only)
nix develop .#macos          # macOS development (macOS only)
```

## 📦 Available Packages

### System Management

- `proxmox-update` - Update Proxmox VE systems
- `vzdump-backup` - Backup Proxmox VMs
- `zfs-snapshot` - Manage ZFS snapshots
- `nixos-flake-update` - Update NixOS flake inputs

### Usage

```bash
# Run packages directly
nix run .#proxmox-update
nix run .#vzdump-backup
nix run .#zfs-snapshot
nix run .#nixos-flake-update

# Or build and run
nix build .#proxmox-update
./result/bin/proxmox-update
```

## 🏗️ Configuration Templates

### Safe NixOS Configuration

The safe configuration template provides a complete NixOS setup that prevents common display issues:

**Features:**

- ✅ Display safety (prevents CLI lock)
- ✅ nix-mox integration
- ✅ Gaming ready (Steam enabled)
- ✅ Development friendly
- ✅ Multiple desktop environment options

**Quick Setup:**

```bash
# Copy the template
cp -r modules/templates/nixos/safe-configuration/* config/

# Generate hardware config
sudo nixos-generate-config --show-hardware-config > config/hardware-configuration.nix

# Customize and deploy
sudo nixos-rebuild switch --flake .#nixos
```

See `modules/templates/nixos/safe-configuration/README.md` for detailed instructions.

### Other Templates

- **CI Runner**: High-performance CI/CD setup
- **Web Server**: Production web server configuration
- **Database Management**: Database server setup
- **Monitoring**: Prometheus/Grafana monitoring stack
- **Load Balancer**: HAProxy load balancer configuration

## 🔧 Configuration Best Practices

### Keep Configurations in `/config`

We recommend keeping your personal configurations in the `/config` directory:

```bash
# Your personal configs go here
config/
├── configuration.nix          # Your NixOS configuration
├── home.nix                   # Your home-manager config
├── hardware-configuration.nix # Your hardware config
└── custom-modules/            # Your custom modules
```

### Benefits of Using `/config`

- ✅ Keeps your configs separate from nix-mox source
- ✅ Easy to backup and version control
- ✅ Clear separation between framework and personal config
- ✅ Follows nix-mox conventions

### Example Configuration Structure

```nix
# config/configuration.nix
{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./custom-modules/my-service.nix
  ];

  # Your system configuration here
  networking.hostName = "myhost";
  time.timeZone = "America/New_York";
  
  # Include nix-mox packages
  environment.systemPackages = with pkgs; [
    inputs.nix-mox.packages.${pkgs.system}.proxmox-update
    inputs.nix-mox.packages.${pkgs.system}.nixos-flake-update
  ];
}
```

## 🧪 Testing

Run the test suite:

```bash
# Unit tests
nix flake check .#checks.x86_64-linux.unit

# Integration tests
nix flake check .#checks.x86_64-linux.integration

# Full test suite
nix flake check .#checks.x86_64-linux.test-suite
```

## 📚 Documentation

- [Usage Guide](docs/USAGE.md) - Detailed usage instructions
- [Nixamples](docs/nixamples/) - Configuration examples
- [Guides](docs/guides/) - Step-by-step guides
- [API Reference](docs/api/) - Module and function documentation

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

### Development Setup

```bash
# Enter development shell
nix develop .#development

# Install pre-commit hooks
pre-commit install

# Run tests
just test
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built on top of [NixOS](https://nixos.org/)
- Uses [home-manager](https://github.com/nix-community/home-manager)
- Inspired by the NixOS community

## 🔗 Links

- [GitHub Repository](https://github.com/Hydepwns/nix-mox)
- [Issues](https://github.com/Hydepwns/nix-mox/issues)
- [Discussions](https://github.com/Hydepwns/nix-mox/discussions)
- [Releases](https://github.com/Hydepwns/nix-mox/releases)
