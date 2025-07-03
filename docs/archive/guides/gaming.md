# Gaming Guide

> Gaming setup for nix-mox with Steam, Wine, and performance optimization.

## Quick Start

```bash
# Setup gaming workstation
nu scripts/setup.nu

# Choose gaming template
cp config/templates/gaming.nix config/nixos/configuration.nix

# Build and switch
sudo nixos-rebuild switch --flake .#nixos

# Enter gaming shell
nix develop .#gaming
```

## Gaming Template Features

The gaming template includes:

- **GPU Support**: NVIDIA, AMD, Intel drivers
- **Gaming Platforms**: Steam, Lutris, Heroic
- **Performance Tools**: GameMode, MangoHud, Feral GameMode
- **Audio**: PipeWire with low-latency gaming config
- **Wine Support**: Wine, DXVK, VKD3D
- **Gaming Packages**: Steam, lutris, heroic, gamemode

## Gaming Shell

```bash
# Enter gaming development environment
nix develop .#gaming

# Available tools
steam          # Steam client
lutris         # Game launcher
heroic         # Epic Games launcher
wine           # Windows compatibility
gamemode       # Performance optimization
mangohud       # Performance overlay
```

## Windows Games

### League of Legends

```bash
# Enter gaming shell
nix develop .#gaming

# Install via Lutris
lutris

# Or use Wine directly
wine /path/to/league-installer.exe
```

### General Windows Games

```bash
# Use Lutris for easy setup
lutris

# Or configure Wine manually
WINEPREFIX=~/.wine winecfg
```

## Performance Optimization

### GameMode

```bash
# Enable GameMode for a game
gamemoderun ./game-executable

# Or prefix with gamemoderun
gamemoderun steam
```

### MangoHud

```bash
# Show performance overlay
mangohud ./game-executable

# Or set environment variable
MANGOHUD=1 ./game-executable
```

### System Tuning

```bash
# Check GPU status
nvidia-smi  # NVIDIA
radeontop   # AMD

# Monitor performance
htop
```

## Troubleshooting

### Steam Issues

```bash
# Reset Steam
rm -rf ~/.steam
steam

# Check Steam logs
journalctl -u steam
```

### Wine Issues

```bash
# Reset Wine prefix
rm -rf ~/.wine
winecfg

# Check Wine version
wine --version
```

### Performance Issues

```bash
# Check GPU drivers
lspci -k | grep -A 2 -i vga

# Monitor system resources
htop
nvidia-smi  # NVIDIA
```

### Audio Issues

```bash
# Check audio devices
pactl list short sinks

# Restart PipeWire
systemctl --user restart pipewire
```

## Advanced Configuration

### Custom Wine Prefixes

```bash
# Create game-specific prefix
WINEPREFIX=~/.wine-games/game1 winecfg

# Install game in specific prefix
WINEPREFIX=~/.wine-games/game1 wine game-installer.exe
```

### DXVK Configuration

```bash
# Enable DXVK
DXVK=1 wine game.exe

# Disable DXVK
DXVK=0 wine game.exe
```

### Vulkan Support

```bash
# Check Vulkan support
vulkaninfo

# Test Vulkan
vkcube
```

## Gaming Platforms

### Steam

```bash
# Launch Steam
steam

# Steam command line
steam -applaunch 730  # Counter-Strike 2
```

### Lutris

```bash
# Launch Lutris
lutris

# Install from URL
lutris -i https://lutris.net/games/league-of-legends/
```

### Heroic Games

```bash
# Launch Heroic
heroic

# Command line
heroic --help
```

## Environment Variables

Key gaming environment variables:

```bash
# Performance
GAMEMODE=1
MANGOHUD=1
DXVK=1

# Wine
WINEPREFIX=~/.wine
WINEARCH=win64

# Steam
STEAM_RUNTIME=1
```

## Next Steps

1. **Choose gaming template** - `cp config/templates/gaming.nix config/nixos/configuration.nix`
2. **Configure personal settings** - Edit `config/personal/user.nix`
3. **Add gaming packages** - Customize gaming profile
4. **Set up Wine prefixes** - Configure for specific games
5. **Optimize performance** - Use GameMode and MangoHud

## Support

- **Steam**: [Steam Support](https://help.steampowered.com/)
- **Lutris**: [Lutris Documentation](https://github.com/lutris/lutris/wiki)
- **Wine**: [Wine Wiki](https://wiki.winehq.org/)
- **Issues**: Report problems on GitHub
