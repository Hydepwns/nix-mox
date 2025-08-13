# Safe NixOS Configuration Template

A complete NixOS configuration using nix-mox's modular fragment system. Prevents common display issues while providing a solid foundation for desktop and development use.

## Key Features

- **Fragment System**: Uses modular, DRY configuration fragments
- **Display Safety**: Explicitly enables display services to prevent CLI lock
- **nix-mox Integration**: Includes nix-mox packages and development shells
- **Gaming Ready**: Steam enabled with proper graphics configuration
- **Development Friendly**: Common development tools and aliases included
- **Messaging & Communication**: Signal Desktop, Telegram Desktop, Discord, Slack, and more

## Quick Start

### Option 1: Use Setup Script (Recommended)

```bash
# Run the interactive setup script (modular)
./modules/templates/nixos/safe-configuration/setup.sh

# The setup script is now modular with components in scripts/:
# - utils.sh: Utility functions and helpers
# - config.sh: Configuration collection and validation
```

### Option 2: Manual Setup

1. **Copy template files:**

   ```bash
   cp -r modules/templates/nixos/safe-configuration/* config/
   ```

2. **Generate hardware configuration:**

   ```bash
   sudo nixos-generate-config --show-hardware-config > config/hardware/hardware-configuration.nix
   ```

3. **Customize configuration:**
   - Edit `config/nixos/configuration.nix` for hostname, timezone, user
   - Edit `config/home/home.nix` for user preferences
   - Update `flake.nix` if needed

4. **Deploy:**

   ```bash
   sudo nixos-rebuild switch --flake .#nixos
   ```

## Fragment System

This template uses nix-mox's modular fragment system:

```nix
# config/nixos/configuration.nix
{ config, pkgs, inputs, ... }:
{
  imports = [
    ../../modules/templates/base/common.nix  # Complete base config
    ../hardware/hardware-configuration.nix
  ];

  # Only override what you need
  networking.hostName = "myhost";
  time.timeZone = "America/New_York";
  users.users.myuser = { ... };
}
```

### Available Fragments

The base template includes:

- `networking.nix` - NetworkManager, firewall
- `display.nix` - X11, display manager, desktop environment
- `sound.nix` - PipeWire, ALSA, PulseAudio
- `graphics.nix` - OpenGL, hardware acceleration
- `packages.nix` - Essential tools, nix-mox packages
- `programs.nix` - Zsh, Git, Steam
- `services.nix` - SSH, Docker
- `nix-settings.nix` - Nix configuration, binary caches
- `system.nix` - System settings

## Configuration Options

### Display Managers

Override in `config/nixos/configuration.nix`:

```nix
services.xserver.displayManager = {
  lightdm.enable = false;  # Disable default
  sddm.enable = true;      # Enable KDE's display manager
  # gdm.enable = true;     # Enable GNOME's display manager
};
```

### Desktop Environments

```nix
services.xserver.desktopManager = {
  gnome.enable = false;    # Disable default
  plasma6.enable = true;   # Enable KDE Plasma 6
  # xfce.enable = true;    # Enable XFCE
};
```

### Window Managers

```nix
services.xserver.windowManager = {
  i3.enable = true;        # Enable i3
  # awesome.enable = true; # Enable Awesome
};
```

### Graphics Drivers

```nix
# NVIDIA
services.xserver.videoDrivers = [ "nvidia" ];
hardware.nvidia = {
  modesetting.enable = true;
  powerManagement.enable = true;
  open = false;
  nvidiaSettings = true;
  package = config.boot.kernelPackages.nvidiaPackages.stable;
};

# AMD
services.xserver.videoDrivers = [ "amdgpu" ];

# Intel
services.xserver.videoDrivers = [ "intel" ];
```

## Using nix-mox

### System Packages

Available system-wide:

```bash
proxmox-update       # Update Proxmox VE
vzdump-backup        # Backup VMs
zfs-snapshot         # Manage ZFS snapshots
nixos-flake-update   # Update flake inputs
```

### Development Shells

Via aliases:

```bash
dev-default      # Default development shell
dev-development  # Development tools
dev-testing      # Testing tools
dev-services     # Service management
dev-monitoring   # Monitoring tools
dev-gaming       # Gaming development (Linux x86_64)
dev-zfs          # ZFS tools (Linux)
```

Or directly:

```bash
nix develop github:Hydepwns/nix-mox#default
nix develop github:Hydepwns/nix-mox#development
```

## Customization

### Adding Packages

Extend the packages fragment or add to your config:

```nix
# config/nixos/configuration.nix
environment.systemPackages = with pkgs; [
  # Your packages here
  vim git docker
];
```

### Custom Services

```nix
# config/nixos/configuration.nix
services.nginx.enable = true;
services.postgresql.enable = true;
```

### Custom Fragments

Create your own fragments:

```nix
# modules/templates/base/common/development.nix
{ config, pkgs, inputs, ... }:
{
  environment.systemPackages = with pkgs; [
    vscode git docker nodejs python3 rustc cargo
  ];
}
```

Then import in your config:

```nix
imports = [
  ../../modules/templates/base/common.nix
  ../../modules/templates/base/common/development.nix
];
```

## Messaging Applications

This template includes comprehensive messaging and communication support:

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

## Configuration

The messaging applications are configured with:

- Proper firewall ports for WebRTC and STUN/TURN services
- Desktop notifications via D-Bus
- File associations for deep linking
- Audio/video hardware support via PipeWire
- Automatic startup and background services

## Usage

After deployment, messaging applications will be available in your application menu. They include:

- Desktop notifications for new messages
- Deep linking support (clicking signal:// or telegram:// links)
- Audio/video calling capabilities
- File sharing and media support

## Customization

You can customize the messaging setup by:

- Adding/removing specific applications from `environment.systemPackages`
- Modifying firewall ports in the networking configuration
- Adjusting notification settings in the home configuration
- Adding custom file associations for additional protocols

## Troubleshooting

### Display Issues

1. Check logs: `journalctl -b -u display-manager`
2. Try different display manager (sddm/gdm)
3. Verify graphics drivers match hardware
4. Try minimal window manager (i3) instead of full DE

### Rollback

```bash
sudo nixos-rebuild switch --rollback
```

## Security

- SSH: Password auth disabled, root login disabled
- Firewall: Enabled by default
- Binary caches: Only trusted sources configured

## Performance

- Uses nix-mox binary caches for faster builds
- Automatic garbage collection
- Auto-optimize store enabled
- Latest kernel packages
