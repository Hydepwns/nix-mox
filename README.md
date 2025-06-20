# nix-mox

A comprehensive NixOS configuration framework with development tools, monitoring, system management utilities, and messaging support.

## 🚀 Quick Start

### New Users

```bash
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

## 📁 Structure

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

## 🧩 Fragment System

Compose configurations from reusable fragments:

### Use Complete Base

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

### Compose Individual Fragments

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

### Add Messaging Support

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

### Create Custom Fragments

```nix
# modules/templates/base/common/development.nix
{ config, pkgs, inputs, ... }:
{
  environment.systemPackages = with pkgs; [
    vscode git docker nodejs python3 rustc cargo
  ];
}
```

## 💬 Messaging & Communication

nix-mox includes comprehensive messaging and communication support:

### Primary Messaging Apps

- **Signal Desktop**: Secure messaging with end-to-end encryption
- **Telegram Desktop**: Feature-rich messaging platform
- **Discord**: Gaming and community chat platform
- **Slack**: Team collaboration and communication

### Additional Communication Tools

- **WhatsApp for Linux**: WhatsApp desktop client
- **Element Desktop**: Matrix protocol client
- **Thunderbird**: Email client
- **Evolution**: GNOME email and calendar client

### Video Calling & Conferencing

- **Zoom**: Video conferencing platform
- **Microsoft Teams**: Team collaboration platform
- **Skype**: Voice and video calling

### Voice & Chat

- **Mumble**: Low-latency voice chat
- **TeamSpeak**: Voice communication
- **HexChat**: IRC client
- **WeeChat**: Modular chat client

### Features

- **Desktop Notifications**: D-Bus integration for all messaging apps
- **Deep Linking**: Support for `signal://` and `telegram://` protocols
- **Audio/Video Calls**: Enhanced PipeWire configuration with WebRTC support
- **Firewall Configuration**: Proper ports for STUN/TURN and WebRTC services

## 🛠️ Development Shells

```bash
nix develop                    # Default
nix develop .#development      # Dev tools
nix develop .#testing          # Testing
nix develop .#services         # Services
nix develop .#monitoring       # Monitoring
nix develop .#gaming           # Gaming (Linux x86_64)
nix develop .#zfs              # ZFS tools (Linux)
nix develop .#macos            # macOS dev (macOS)
```

## 📦 Packages

```bash
nix run .#proxmox-update       # Update Proxmox VE
nix run .#vzdump-backup        # Backup VMs
nix run .#zfs-snapshot         # Manage ZFS snapshots
nix run .#nixos-flake-update   # Update flake inputs
nix run .#install              # Install nix-mox
nix run .#uninstall            # Uninstall nix-mox
```

## 🏗️ Templates

- **Safe Configuration**: Complete desktop setup with display safety and messaging support
- **CI Runner**: High-performance CI/CD
- **Web Server**: Production web server
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
- [Examples](docs/nixamples/)
- [Guides](docs/guides/)
- [API Reference](docs/api/)

## 🤝 Contributing

```bash
nix develop .#development
pre-commit install
just test
```

## 📄 License

MIT License - see [LICENSE](LICENSE)

## 🔗 Links

- [GitHub](https://github.com/Hydepwns/nix-mox)
- [Issues](https://github.com/Hydepwns/nix-mox/issues)
- [Discussions](https://github.com/Hydepwns/nix-mox/discussions)
